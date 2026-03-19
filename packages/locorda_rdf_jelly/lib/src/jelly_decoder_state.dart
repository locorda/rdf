/// Jelly decoder state — shared logic for reconstructing RDF terms from
/// protobuf messages.
///
/// This class manages the lookup tables, blank node mapping, and
/// repeated-term state needed to decode a Jelly stream. It is used by both
/// the streaming and batch decoders.
library;

import 'package:locorda_rdf_core/core.dart';

import 'lookup_table.dart';
import 'proto/rdf.pb.dart';

/// XSD namespace IRI, used as the default datatype prefix.
const _xsdString = 'http://www.w3.org/2001/XMLSchema#string';
const _rdfLangString = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#langString';

const _formatName = 'application/x-jelly-rdf';

/// Mutable state for decoding a single Jelly stream.
///
/// Tracks lookup tables, blank node map, repeated-term state, stream options,
/// and the current graph (for GRAPHS streams). A new instance should be
/// created for each stream.
class JellyDecoderState {
  /// The stream options from the first options row.
  RdfStreamOptions? options;

  // Lookup tables
  late JellyLookupTable prefixTable;
  late JellyLookupTable nameTable;
  late JellyLookupTable datatypeTable;

  // Blank node label → identity map. Since BlankNodeTerm uses identity
  // equality, we must return the same instance for the same label within
  // a single stream.
  final Map<String, BlankNodeTerm> _blankNodeMap = {};

  // Delta-encoded IRI state: tracks the last prefix_id and name_id seen
  // across all IRI positions in the stream.
  int _lastPrefixId = 0;
  int _lastNameId = 0;

  // Repeated-term state for triples (subject, predicate, object positions)
  RdfSubject? _lastSubject;
  RdfPredicate? _lastPredicate;
  RdfObject? _lastObject;

  // Repeated-term state for quads (graph position)
  RdfGraphName? _lastGraphName;
  bool _lastGraphWasDefault = false;

  // Current graph name for GRAPHS physical type
  RdfGraphName? currentGraphName;
  bool currentGraphIsDefault = false;

  bool _optionsSeen = false;

  JellyDecoderState();

  /// Whether the stream options have been processed.
  bool get optionsSeen => _optionsSeen;

  /// Maximum allowed lookup table size. Streams requesting larger tables are
  /// rejected for security (DoS prevention). Follows Jelly-JVM conventions.
  static const int maxAllowedNameTableSize = 4096;
  static const int maxAllowedPrefixTableSize = 1024;
  static const int maxAllowedDatatypeTableSize = 256;

  /// Processes stream options from the first options row.
  ///
  /// Initializes lookup tables with the declared sizes. Rejects overly large
  /// table sizes for security.
  void processOptions(RdfStreamOptions opts) {
    if (_optionsSeen) {
      // Per spec, subsequent options rows must be identical.
      return;
    }
    _optionsSeen = true;
    options = opts;

    // Validate table sizes against security limits
    if (opts.maxNameTableSize > maxAllowedNameTableSize) {
      throw RdfDecoderException(
        'Jelly stream error: max_name_table_size ${opts.maxNameTableSize} '
        'exceeds allowed maximum $maxAllowedNameTableSize',
        format: _formatName,
      );
    }
    if (opts.maxPrefixTableSize > maxAllowedPrefixTableSize) {
      throw RdfDecoderException(
        'Jelly stream error: max_prefix_table_size ${opts.maxPrefixTableSize} '
        'exceeds allowed maximum $maxAllowedPrefixTableSize',
        format: _formatName,
      );
    }
    if (opts.maxDatatypeTableSize > maxAllowedDatatypeTableSize) {
      throw RdfDecoderException(
        'Jelly stream error: max_datatype_table_size ${opts.maxDatatypeTableSize} '
        'exceeds allowed maximum $maxAllowedDatatypeTableSize',
        format: _formatName,
      );
    }

    final nameSize = opts.maxNameTableSize > 0 ? opts.maxNameTableSize : 128;
    final prefixSize =
        opts.maxPrefixTableSize > 0 ? opts.maxPrefixTableSize : 32;
    final datatypeSize =
        opts.maxDatatypeTableSize > 0 ? opts.maxDatatypeTableSize : 16;

    nameTable = JellyLookupTable(nameSize);
    prefixTable = JellyLookupTable(prefixSize);
    datatypeTable = JellyLookupTable(datatypeSize);
  }

  void _requireOptions() {
    if (!_optionsSeen) {
      throw RdfDecoderException(
        'Jelly stream error: received data before stream options',
        format: _formatName,
      );
    }
  }

  // -- Lookup table updates --------------------------------------------------

  void processNameEntry(RdfNameEntry entry) {
    _requireOptions();
    _validateTableEntryId('name', entry.id, nameTable);
    nameTable.set(entry.id, entry.value);
  }

  void processPrefixEntry(RdfPrefixEntry entry) {
    _requireOptions();
    if (options!.maxPrefixTableSize == 0) {
      throw RdfDecoderException(
        'Jelly stream error: prefix entry in stream with disabled prefix table '
        '(max_prefix_table_size=0)',
        format: _formatName,
      );
    }
    _validateTableEntryId('prefix', entry.id, prefixTable);
    prefixTable.set(entry.id, entry.value);
  }

  void processDatatypeEntry(RdfDatatypeEntry entry) {
    _requireOptions();
    _validateTableEntryId('datatype', entry.id, datatypeTable);
    datatypeTable.set(entry.id, entry.value);
  }

  /// Rejects table entry IDs that exceed the declared table max size.
  ///
  /// For delta-encoded IDs (rawId == 0), resolves to (lastId + 1) before
  /// checking. This catches streams that overflow the table by continuously
  /// incrementing via delta encoding.
  void _validateTableEntryId(
      String tableName, int rawId, JellyLookupTable table) {
    final resolvedId = rawId == 0 ? table.lastId + 1 : rawId;
    if (resolvedId > table.maxSize) {
      throw RdfDecoderException(
        'Jelly stream error: $tableName table entry ID $resolvedId '
        'exceeds max table size ${table.maxSize}',
        format: _formatName,
      );
    }
  }

  // -- Blank node management -------------------------------------------------

  /// Returns a consistent [BlankNodeTerm] for the given label within this
  /// stream. The same label always maps to the same identity.
  BlankNodeTerm _resolveBlankNode(String label) {
    return _blankNodeMap.putIfAbsent(label, BlankNodeTerm.new);
  }

  // -- IRI reconstruction ----------------------------------------------------

  /// Reconstructs an IRI string from an [RdfIri] message using the lookup
  /// tables.
  ///
  /// Handles delta encoding: prefix_id=0 means "reuse last prefix",
  /// name_id=0 means "last name + 1".
  String resolveIri(RdfIri iri) {
    final rawPrefixId = iri.prefixId;
    final prefixId = rawPrefixId == 0 ? _lastPrefixId : rawPrefixId;
    if (rawPrefixId != 0) _lastPrefixId = rawPrefixId;

    final rawNameId = iri.nameId;
    final nameId = rawNameId == 0 ? _lastNameId + 1 : rawNameId;
    _lastNameId = nameId;

    String prefix;
    if (prefixId == 0) {
      prefix = '';
    } else {
      final p = prefixTable.get(prefixId);
      if (p == null) {
        throw RdfDecoderException(
          'Jelly stream error: prefix ID $prefixId not found in lookup table',
          format: _formatName,
        );
      }
      prefix = p;
    }
    final name = nameTable.get(nameId);
    if (name == null) {
      throw RdfDecoderException(
        'Jelly stream error: name ID $nameId not found in lookup table',
        format: _formatName,
      );
    }

    return '$prefix$name';
  }

  // -- Term reconstruction ---------------------------------------------------

  /// Resolves a literal from an [RdfLiteral] message.
  LiteralTerm resolveLiteral(RdfLiteral literal) {
    final lex = literal.lex;

    if (literal.hasLangtag()) {
      return LiteralTerm(lex,
          datatype: const IriTerm(_rdfLangString), language: literal.langtag);
    }

    if (literal.hasDatatype()) {
      final datatypeId = literal.datatype;
      if (datatypeId == 0) {
        throw RdfDecoderException(
          'Jelly stream error: datatype index 0 is invalid '
          '(datatype table uses 1-based IDs without delta encoding)',
          format: _formatName,
        );
      }
      final datatypeIri = datatypeTable.get(datatypeId);
      if (datatypeIri == null) {
        throw RdfDecoderException(
          'Jelly stream error: unknown datatype ID $datatypeId',
          format: _formatName,
        );
      }
      return LiteralTerm(lex, datatype: IriTerm(datatypeIri));
    }

    // Simple literal (xsd:string)
    return LiteralTerm(lex, datatype: const IriTerm(_xsdString));
  }

  // -- Triple term extraction ------------------------------------------------

  RdfSubject _resolveTripleSubject(RdfTriple triple) {
    if (triple.hasSIri()) {
      final s = IriTerm(resolveIri(triple.sIri));
      _lastSubject = s;
      return s;
    } else if (triple.hasSBnode()) {
      final s = _resolveBlankNode(triple.sBnode);
      _lastSubject = s;
      return s;
    } else if (triple.hasSLiteral()) {
      throw RdfDecoderException(
        'Jelly stream error: literal subjects are not supported in RDF 1.1',
        format: _formatName,
      );
    } else if (triple.hasSTripleTerm()) {
      throw RdfDecoderException(
        'Jelly stream error: RDF-star quoted triples are not supported',
        format: _formatName,
      );
    }
    // Repeated term
    if (_lastSubject == null) {
      throw RdfDecoderException(
        'Jelly stream error: repeated subject in first statement',
        format: _formatName,
      );
    }
    return _lastSubject!;
  }

  RdfPredicate _resolveTriplePredicate(RdfTriple triple) {
    if (triple.hasPIri()) {
      final p = IriTerm(resolveIri(triple.pIri));
      _lastPredicate = p;
      return p;
    } else if (triple.hasPBnode()) {
      throw RdfDecoderException(
        'Jelly stream error: blank node predicates are not supported in RDF 1.1',
        format: _formatName,
      );
    } else if (triple.hasPLiteral()) {
      throw RdfDecoderException(
        'Jelly stream error: literal predicates are not supported in RDF 1.1',
        format: _formatName,
      );
    } else if (triple.hasPTripleTerm()) {
      throw RdfDecoderException(
        'Jelly stream error: RDF-star quoted triples are not supported',
        format: _formatName,
      );
    }
    if (_lastPredicate == null) {
      throw RdfDecoderException(
        'Jelly stream error: repeated predicate in first statement',
        format: _formatName,
      );
    }
    return _lastPredicate!;
  }

  RdfObject _resolveTripleObject(RdfTriple triple) {
    if (triple.hasOIri()) {
      final o = IriTerm(resolveIri(triple.oIri));
      _lastObject = o;
      return o;
    } else if (triple.hasOBnode()) {
      final o = _resolveBlankNode(triple.oBnode);
      _lastObject = o;
      return o;
    } else if (triple.hasOLiteral()) {
      final o = resolveLiteral(triple.oLiteral);
      _lastObject = o;
      return o;
    } else if (triple.hasOTripleTerm()) {
      throw RdfDecoderException(
        'Jelly stream error: RDF-star quoted triples are not supported',
        format: _formatName,
      );
    }
    if (_lastObject == null) {
      throw RdfDecoderException(
        'Jelly stream error: repeated object in first statement',
        format: _formatName,
      );
    }
    return _lastObject!;
  }

  /// Resolves a full [Triple] from an [RdfTriple] protobuf message.
  Triple resolveTriple(RdfTriple protoTriple) {
    _requireOptions();
    return Triple(
      _resolveTripleSubject(protoTriple),
      _resolveTriplePredicate(protoTriple),
      _resolveTripleObject(protoTriple),
    );
  }

  // -- Quad term extraction --------------------------------------------------

  RdfSubject _resolveQuadSubject(RdfQuad quad) {
    if (quad.hasSIri()) {
      final s = IriTerm(resolveIri(quad.sIri));
      _lastSubject = s;
      return s;
    } else if (quad.hasSBnode()) {
      final s = _resolveBlankNode(quad.sBnode);
      _lastSubject = s;
      return s;
    } else if (quad.hasSLiteral()) {
      throw RdfDecoderException(
        'Jelly stream error: literal subjects are not supported in RDF 1.1',
        format: _formatName,
      );
    } else if (quad.hasSTripleTerm()) {
      throw RdfDecoderException(
        'Jelly stream error: RDF-star quoted triples are not supported',
        format: _formatName,
      );
    }
    if (_lastSubject == null) {
      throw RdfDecoderException(
        'Jelly stream error: repeated subject in first statement',
        format: _formatName,
      );
    }
    return _lastSubject!;
  }

  RdfPredicate _resolveQuadPredicate(RdfQuad quad) {
    if (quad.hasPIri()) {
      final p = IriTerm(resolveIri(quad.pIri));
      _lastPredicate = p;
      return p;
    } else if (quad.hasPBnode()) {
      throw RdfDecoderException(
        'Jelly stream error: blank node predicates are not supported in RDF 1.1',
        format: _formatName,
      );
    } else if (quad.hasPLiteral()) {
      throw RdfDecoderException(
        'Jelly stream error: literal predicates are not supported in RDF 1.1',
        format: _formatName,
      );
    } else if (quad.hasPTripleTerm()) {
      throw RdfDecoderException(
        'Jelly stream error: RDF-star quoted triples are not supported',
        format: _formatName,
      );
    }
    if (_lastPredicate == null) {
      throw RdfDecoderException(
        'Jelly stream error: repeated predicate in first statement',
        format: _formatName,
      );
    }
    return _lastPredicate!;
  }

  RdfObject _resolveQuadObject(RdfQuad quad) {
    if (quad.hasOIri()) {
      final o = IriTerm(resolveIri(quad.oIri));
      _lastObject = o;
      return o;
    } else if (quad.hasOBnode()) {
      final o = _resolveBlankNode(quad.oBnode);
      _lastObject = o;
      return o;
    } else if (quad.hasOLiteral()) {
      final o = resolveLiteral(quad.oLiteral);
      _lastObject = o;
      return o;
    } else if (quad.hasOTripleTerm()) {
      throw RdfDecoderException(
        'Jelly stream error: RDF-star quoted triples are not supported',
        format: _formatName,
      );
    }
    if (_lastObject == null) {
      throw RdfDecoderException(
        'Jelly stream error: repeated object in first statement',
        format: _formatName,
      );
    }
    return _lastObject!;
  }

  /// Resolves the graph component of an [RdfQuad], handling repeated terms.
  ({RdfGraphName? graphName, bool isDefault}) _resolveQuadGraph(RdfQuad quad) {
    if (quad.hasGIri()) {
      final g = IriTerm(resolveIri(quad.gIri));
      _lastGraphName = g;
      _lastGraphWasDefault = false;
      return (graphName: g, isDefault: false);
    } else if (quad.hasGBnode()) {
      final g = _resolveBlankNode(quad.gBnode);
      _lastGraphName = g;
      _lastGraphWasDefault = false;
      return (graphName: g, isDefault: false);
    } else if (quad.hasGDefaultGraph()) {
      _lastGraphName = null;
      _lastGraphWasDefault = true;
      return (graphName: null, isDefault: true);
    } else if (quad.hasGLiteral()) {
      throw RdfDecoderException(
        'Jelly stream error: literal graph names are not supported in RDF 1.1',
        format: _formatName,
      );
    }
    // Repeated graph
    return (graphName: _lastGraphName, isDefault: _lastGraphWasDefault);
  }

  /// Resolves a full [Quad] from an [RdfQuad] protobuf message.
  Quad resolveQuad(RdfQuad protoQuad) {
    _requireOptions();
    final subject = _resolveQuadSubject(protoQuad);
    final predicate = _resolveQuadPredicate(protoQuad);
    final object = _resolveQuadObject(protoQuad);
    final graph = _resolveQuadGraph(protoQuad);

    return Quad(subject, predicate, object, graph.graphName);
  }

  // -- Graph stream support --------------------------------------------------

  /// Processes a graph start marker (GRAPHS physical type).
  void processGraphStart(RdfGraphStart graphStart) {
    _requireOptions();
    if (graphStart.hasGIri()) {
      currentGraphName = IriTerm(resolveIri(graphStart.gIri));
      currentGraphIsDefault = false;
    } else if (graphStart.hasGBnode()) {
      currentGraphName = _resolveBlankNode(graphStart.gBnode);
      currentGraphIsDefault = false;
    } else if (graphStart.hasGDefaultGraph()) {
      currentGraphName = null;
      currentGraphIsDefault = true;
    } else if (graphStart.hasGLiteral()) {
      throw RdfDecoderException(
        'Jelly stream error: literal graph names are not supported in RDF 1.1',
        format: _formatName,
      );
    } else {
      throw RdfDecoderException(
        'Jelly stream error: graph_start must specify a graph',
        format: _formatName,
      );
    }
  }

  /// Processes a graph end marker (GRAPHS physical type).
  void processGraphEnd() {
    _requireOptions();
    currentGraphName = null;
    currentGraphIsDefault = false;
  }
}
