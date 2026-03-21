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

  // IRI term cache: flat List indexed by nameId * _iriCacheStride + prefixId.
  // Stores fully-constructed IriTerm objects so that recurring (prefix, name)
  // ID pairs bypass table lookups, string concatenation, AND IriTerm allocation.
  // Null when the combined table size exceeds the allocation threshold (>64 K
  // slots), which only occurs when callers request near-maximum table sizes.
  List<IriTerm?>? _iriCache;
  int _iriCacheStride = 0;

  // Datatype IriTerm cache indexed by 1-based datatype ID.
  // With ≤256 possible datatype slots, this is always small enough to
  // allocate. Avoids repeated IriTerm allocation for typed literals.
  List<IriTerm?>? _datatypeIriTermCache;

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

    // Allocate IRI cache only when the combined size is reasonable.
    // At default table sizes (128 names × 32 prefixes) the cache is ~4 K slots.
    // At the security-capped maximums (4096 × 1024) it exceeds 4 M slots —
    // skip it to avoid pathological memory use.
    final iriCacheSize = (nameSize + 1) * (prefixSize + 1);
    if (iriCacheSize <= 65536) {
      _iriCacheStride = prefixSize + 1;
      _iriCache = List.filled(iriCacheSize, null);
    }

    _datatypeIriTermCache = List.filled(datatypeSize + 1, null);
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

  void processNameEntry(RdfNameEntry entry) =>
      processNameEntryRaw(entry.id, entry.value);

  void processPrefixEntry(RdfPrefixEntry entry) =>
      processPrefixEntryRaw(entry.id, entry.value);

  void processDatatypeEntry(RdfDatatypeEntry entry) =>
      processDatatypeEntryRaw(entry.id, entry.value);

  /// Raw variant of [processNameEntry] — accepts pre-decoded field values.
  void processNameEntryRaw(int rawId, String value) {
    _requireOptions();
    _validateTableEntryId('name', rawId, nameTable);
    final nameId = nameTable.set(rawId, value);
    _invalidateNameIriCache(nameId);
  }

  /// Raw variant of [processPrefixEntry] — accepts pre-decoded field values.
  void processPrefixEntryRaw(int rawId, String value) {
    _requireOptions();
    if (options!.maxPrefixTableSize == 0) {
      throw RdfDecoderException(
        'Jelly stream error: prefix entry in stream with disabled prefix table '
        '(max_prefix_table_size=0)',
        format: _formatName,
      );
    }
    _validateTableEntryId('prefix', rawId, prefixTable);
    final prefixId = prefixTable.set(rawId, value);
    _invalidatePrefixIriCache(prefixId);
  }

  /// Raw variant of [processDatatypeEntry] — accepts pre-decoded field values.
  void processDatatypeEntryRaw(int rawId, String value) {
    _requireOptions();
    _validateTableEntryId('datatype', rawId, datatypeTable);
    final id = datatypeTable.set(rawId, value);
    // Invalidate cached IriTerm for this slot — the datatype string changed.
    _datatypeIriTermCache?[id] = null;
  }

  // Clears IRI cache entries for [nameId] across all prefix slots.
  void _invalidateNameIriCache(int nameId) {
    final cache = _iriCache;
    if (cache == null) return;
    final base = nameId * _iriCacheStride;
    cache.fillRange(base, base + _iriCacheStride, null);
  }

  // Clears IRI cache entries for [prefixId] across all name slots.
  void _invalidatePrefixIriCache(int prefixId) {
    final cache = _iriCache;
    if (cache == null) return;
    final stride = _iriCacheStride;
    final maxNameId = nameTable.maxSize;
    for (var nameId = 1; nameId <= maxNameId; nameId++) {
      cache[nameId * stride + prefixId] = null;
    }
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

  /// Reconstructs an [IriTerm] from an [RdfIri] message using the lookup
  /// tables.
  ///
  /// Delegates to [resolveIriRaw] with pre-extracted field values.
  IriTerm resolveIri(RdfIri iri) => resolveIriRaw(iri.prefixId, iri.nameId);

  /// Reconstructs an [IriTerm] from raw pre-decoded IRI field values.
  ///
  /// Handles delta encoding: prefix_id=0 means "reuse last prefix",
  /// name_id=0 means "last name + 1". For recurring (prefix, name) ID pairs,
  /// returns the cached [IriTerm] without any table lookup, string
  /// concatenation, or object allocation.
  IriTerm resolveIriRaw(int rawPrefixId, int rawNameId) {
    final prefixId = rawPrefixId == 0 ? _lastPrefixId : rawPrefixId;
    if (rawPrefixId != 0) _lastPrefixId = rawPrefixId;

    final nameId = rawNameId == 0 ? _lastNameId + 1 : rawNameId;
    _lastNameId = nameId;

    // Fast path: return the cached IriTerm without any allocation.
    final cache = _iriCache;
    final cacheIdx = cache != null ? nameId * _iriCacheStride + prefixId : -1;
    if (cacheIdx >= 0) {
      final cached = cache![cacheIdx];
      if (cached != null) return cached;
    }

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

    final term = IriTerm('$prefix$name');
    if (cacheIdx >= 0) {
      cache![cacheIdx] = term;
    }
    return term;
  }

  // -- Term reconstruction ---------------------------------------------------

  /// Resolves a literal from an [RdfLiteral] message.
  ///
  /// Delegates to [resolveLiteralRaw] with pre-extracted field values.
  LiteralTerm resolveLiteral(RdfLiteral literal) => resolveLiteralRaw(
        literal.lex,
        literal.hasLangtag() ? literal.langtag : null,
        literal.hasDatatype() ? literal.datatype : 0,
      );

  /// Resolves a literal from raw pre-decoded field values.
  ///
  /// [langtag] non-null signals a language-tagged literal (rdf:langString).
  /// [datatypeId] non-zero selects the datatype from the lookup table.
  /// Neither set → plain xsd:string literal.
  LiteralTerm resolveLiteralRaw(String lex, String? langtag, int datatypeId) {
    if (langtag != null) {
      return LiteralTerm(lex,
          datatype: const IriTerm(_rdfLangString), language: langtag);
    }

    if (datatypeId != 0) {
      final datatypeId0 = datatypeId;
      // Fast path: reuse the cached IriTerm for this datatype ID.
      final dtCache = _datatypeIriTermCache;
      if (dtCache != null) {
        var term = dtCache[datatypeId0];
        if (term == null) {
          final datatypeIri = datatypeTable.get(datatypeId0);
          if (datatypeIri == null) {
            throw RdfDecoderException(
              'Jelly stream error: unknown datatype ID $datatypeId0',
              format: _formatName,
            );
          }
          term = IriTerm(datatypeIri);
          dtCache[datatypeId0] = term;
        }
        return LiteralTerm(lex, datatype: term);
      }
      final datatypeIri = datatypeTable.get(datatypeId0);
      if (datatypeIri == null) {
        throw RdfDecoderException(
          'Jelly stream error: unknown datatype ID $datatypeId0',
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
      final s = resolveIri(triple.sIri);
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
      final p = resolveIri(triple.pIri);
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
      final o = resolveIri(triple.oIri);
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
      final s = resolveIri(quad.sIri);
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
      final p = resolveIri(quad.pIri);
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
      final o = resolveIri(quad.oIri);
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
      final g = resolveIri(quad.gIri);
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

  // -- Raw subject/predicate/object/graph resolution -------------------------
  //
  // These methods mirror the private _resolveXxx helpers but operate on
  // pre-decoded field values from the raw byte parser, eliminating all
  // GeneratedMessage allocations on the hot path.
  //
  // [fieldNum] is the proto field number of the set oneof variant, 0 = repeated.

  /// Resolves a subject term from raw proto field data.
  ///
  /// Field numbers: 1=IRI, 2=BNode, 3=Literal (rejected), 4=RDFstar (rejected),
  /// 0=repeated (last subject reused).
  RdfSubject resolveSubjectRaw(
    int fieldNum, {
    int prefixId = 0,
    int nameId = 0,
    String bnode = '',
  }) {
    switch (fieldNum) {
      case 1:
        final s = resolveIriRaw(prefixId, nameId);
        _lastSubject = s;
        return s;
      case 2:
        final s = _resolveBlankNode(bnode);
        _lastSubject = s;
        return s;
      case 3:
        throw RdfDecoderException(
          'Jelly stream error: literal subjects are not supported in RDF 1.1',
          format: _formatName,
        );
      case 4:
        throw RdfDecoderException(
          'Jelly stream error: RDF-star quoted triples are not supported',
          format: _formatName,
        );
      default: // 0 = repeated
        if (_lastSubject == null) {
          throw RdfDecoderException(
            'Jelly stream error: repeated subject in first statement',
            format: _formatName,
          );
        }
        return _lastSubject!;
    }
  }

  /// Resolves a predicate term from raw proto field data.
  ///
  /// Field numbers: 5=IRI, 6=BNode (rejected), 7=Literal (rejected),
  /// 8=RDFstar (rejected), 0=repeated.
  RdfPredicate resolvePredicateRaw(
    int fieldNum, {
    int prefixId = 0,
    int nameId = 0,
  }) {
    switch (fieldNum) {
      case 5:
        final p = resolveIriRaw(prefixId, nameId);
        _lastPredicate = p;
        return p;
      case 6:
        throw RdfDecoderException(
          'Jelly stream error: blank node predicates are not supported in RDF 1.1',
          format: _formatName,
        );
      case 7:
        throw RdfDecoderException(
          'Jelly stream error: literal predicates are not supported in RDF 1.1',
          format: _formatName,
        );
      case 8:
        throw RdfDecoderException(
          'Jelly stream error: RDF-star quoted triples are not supported',
          format: _formatName,
        );
      default: // 0 = repeated
        if (_lastPredicate == null) {
          throw RdfDecoderException(
            'Jelly stream error: repeated predicate in first statement',
            format: _formatName,
          );
        }
        return _lastPredicate!;
    }
  }

  /// Resolves an object term from raw proto field data.
  ///
  /// Field numbers: 9=IRI, 10=BNode, 11=Literal, 12=RDFstar (rejected),
  /// 0=repeated. For Literal: [lex], [langtag], [datatypeId] carry the
  /// decoded literal fields.
  RdfObject resolveObjectRaw(
    int fieldNum, {
    int prefixId = 0,
    int nameId = 0,
    String bnode = '',
    String lex = '',
    String? langtag,
    int datatypeId = 0,
  }) {
    switch (fieldNum) {
      case 9:
        final o = resolveIriRaw(prefixId, nameId);
        _lastObject = o;
        return o;
      case 10:
        final o = _resolveBlankNode(bnode);
        _lastObject = o;
        return o;
      case 11:
        final o = resolveLiteralRaw(lex, langtag, datatypeId);
        _lastObject = o;
        return o;
      case 12:
        throw RdfDecoderException(
          'Jelly stream error: RDF-star quoted triples are not supported',
          format: _formatName,
        );
      default: // 0 = repeated
        if (_lastObject == null) {
          throw RdfDecoderException(
            'Jelly stream error: repeated object in first statement',
            format: _formatName,
          );
        }
        return _lastObject!;
    }
  }

  /// Resolves the graph field of a QUADS-stream quad from raw proto field data.
  ///
  /// Field numbers: 13=IRI, 14=BNode, 15=DefaultGraph, 16=Literal (rejected),
  /// 0=repeated.
  ({RdfGraphName? graphName, bool isDefault}) resolveQuadGraphRaw(
    int fieldNum, {
    int prefixId = 0,
    int nameId = 0,
    String bnode = '',
  }) {
    switch (fieldNum) {
      case 13:
        final g = resolveIriRaw(prefixId, nameId);
        _lastGraphName = g;
        _lastGraphWasDefault = false;
        return (graphName: g, isDefault: false);
      case 14:
        final g = _resolveBlankNode(bnode);
        _lastGraphName = g;
        _lastGraphWasDefault = false;
        return (graphName: g, isDefault: false);
      case 15:
        _lastGraphName = null;
        _lastGraphWasDefault = true;
        return (graphName: null, isDefault: true);
      case 16:
        throw RdfDecoderException(
          'Jelly stream error: literal graph names are not supported in RDF 1.1',
          format: _formatName,
        );
      default: // 0 = repeated
        return (graphName: _lastGraphName, isDefault: _lastGraphWasDefault);
    }
  }

  /// Processes a graph start marker from raw proto field data (GRAPHS stream).
  ///
  /// Field numbers: 1=IRI, 2=BNode, 3=DefaultGraph, 4=Literal (rejected),
  /// 0=no field set (error per spec).
  void processGraphStartRaw(
    int fieldNum, {
    int prefixId = 0,
    int nameId = 0,
    String bnode = '',
  }) {
    _requireOptions();
    switch (fieldNum) {
      case 1:
        currentGraphName = resolveIriRaw(prefixId, nameId);
        currentGraphIsDefault = false;
      case 2:
        currentGraphName = _resolveBlankNode(bnode);
        currentGraphIsDefault = false;
      case 3:
        currentGraphName = null;
        currentGraphIsDefault = true;
      case 4:
        throw RdfDecoderException(
          'Jelly stream error: literal graph names are not supported in RDF 1.1',
          format: _formatName,
        );
      default: // 0 = no field set
        throw RdfDecoderException(
          'Jelly stream error: graph_start must specify a graph',
          format: _formatName,
        );
    }
  }

  // -- Graph stream support --------------------------------------------------

  /// Processes a graph start marker (GRAPHS physical type).
  void processGraphStart(RdfGraphStart graphStart) {
    _requireOptions();
    if (graphStart.hasGIri()) {
      currentGraphName = resolveIri(graphStart.gIri);
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
