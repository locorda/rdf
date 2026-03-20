/// Jelly encoder state — manages lookup tables, delta encoding, and
/// repeated-term compression for producing Jelly binary streams.
library;

import 'package:locorda_rdf_core/core.dart';

import 'proto/rdf.pb.dart';

/// Encoder-side lookup table that keeps IDs in [1, maxSize].
///
/// Dart's default [Map] is a [LinkedHashMap], which preserves insertion order.
/// Eviction therefore uses [Map.keys.first] (oldest entry) — O(1) instead of
/// the O(n) linear scan a sorted-order search would require.
/// Delta encoding tracks the last emitted ID per table: if the new ID
/// equals lastEmittedId + 1, a 0 is emitted instead.
class EncoderLookupTable {
  final int maxSize;
  // LinkedHashMap (Dart default): O(1) insertion-ordered eviction via keys.first.
  final Map<String, int> _entries = {};
  int _nextId = 1;

  /// Last ID emitted to the stream, used for delta encoding of table entries.
  int lastEmittedId = 0;

  EncoderLookupTable(this.maxSize);

  /// Returns the assigned ID for [value], or null if not present.
  int? operator [](String value) => _entries[value];

  /// Whether [value] is currently in the table.
  bool contains(String value) => _entries.containsKey(value);

  /// Ensures [value] is in the table. Returns the assigned ID if a new entry
  /// was created, or null if the value was already present.
  int? ensure(String value) {
    if (_entries.containsKey(value)) return null;

    int id;
    if (_entries.length >= maxSize) {
      // O(1): LinkedHashMap iteration order == insertion order.
      final oldestKey = _entries.keys.first;
      id = _entries.remove(oldestKey)!;
    } else {
      id = _nextId++;
    }

    _entries[value] = id;
    return id;
  }

  /// Delta-encodes [id] relative to [lastEmittedId]: returns 0 if
  /// id == lastEmittedId + 1, otherwise returns id. Updates lastEmittedId.
  int deltaEncode(int id) {
    final encoded = id == lastEmittedId + 1 ? 0 : id;
    lastEmittedId = id;
    return encoded;
  }
}

/// Mutable state for encoding a single Jelly stream.
///
/// Manages name/prefix/datatype lookup tables (assigning IDs), IRI delta
/// encoding, and repeated-term compression. A new instance should be created
/// for each stream.
class JellyEncoderState {
  final int maxNameTableSize;
  final int maxPrefixTableSize;
  final int maxDatatypeTableSize;

  late final EncoderLookupTable _nameTable;
  late final EncoderLookupTable _prefixTable;
  late final EncoderLookupTable _datatypeTable;

  /// Delta-encoded IRI state (for RdfIri in triples/quads, separate from
  /// the table-entry delta encoding tracked per-table).
  int _lastPrefixId = 0;
  int _lastNameId = 0;

  /// Repeated-term state for triples
  RdfSubject? _lastSubject;
  RdfPredicate? _lastPredicate;
  RdfObject? _lastObject;

  /// Repeated-term state for quad graph
  RdfGraphName? _lastGraphName;
  bool _lastGraphWasDefault = false;

  /// Blank node label counter
  final Map<BlankNodeTerm, String> _blankNodeLabels = {};
  int _nextBlankNodeId = 1;

  JellyEncoderState({
    required this.maxNameTableSize,
    required this.maxPrefixTableSize,
    required this.maxDatatypeTableSize,
  })  : _nameTable = EncoderLookupTable(maxNameTableSize),
        _prefixTable = EncoderLookupTable(maxPrefixTableSize),
        _datatypeTable = EncoderLookupTable(maxDatatypeTableSize);

  // ---------------------------------------------------------------------------
  // Lookup table management
  // ---------------------------------------------------------------------------

  /// Returns pending rows (name/prefix/datatype entries) that need to be
  /// emitted before the given term can be referenced, and clears them.
  ///
  /// This method registers the IRI/datatype in the lookup table if not already
  /// present and returns the necessary table update rows.
  List<RdfStreamRow> prepareTerm(RdfTerm term) {
    final rows = <RdfStreamRow>[];
    switch (term) {
      case IriTerm():
        _prepareIri(term.value, rows);
      case LiteralTerm():
        _prepareLiteral(term, rows);
      case BlankNodeTerm():
        _prepareBlankNode(term);
    }
    return rows;
  }

  /// Prepares all terms in a triple, returning lookup table rows needed.
  List<RdfStreamRow> prepareTriple(Triple triple) {
    final rows = <RdfStreamRow>[];
    _prepareSubject(triple.subject, rows);
    _preparePredicate(triple.predicate, rows);
    _prepareObject(triple.object, rows);
    return rows;
  }

  /// Prepares all terms in a quad, returning lookup table rows needed.
  List<RdfStreamRow> prepareQuad(Quad quad) {
    final rows = <RdfStreamRow>[];
    _prepareSubject(quad.subject, rows);
    _preparePredicate(quad.predicate, rows);
    _prepareObject(quad.object, rows);
    if (quad.graphName != null) {
      switch (quad.graphName!) {
        case IriTerm(:final value):
          _prepareIri(value, rows);
        case BlankNodeTerm():
          _prepareBlankNode(quad.graphName! as BlankNodeTerm);
      }
    }
    return rows;
  }

  void _prepareSubject(RdfSubject subject, List<RdfStreamRow> rows) {
    switch (subject) {
      case IriTerm(:final value):
        _prepareIri(value, rows);
      case BlankNodeTerm():
        _prepareBlankNode(subject);
    }
  }

  void _preparePredicate(RdfPredicate predicate, List<RdfStreamRow> rows) {
    switch (predicate) {
      case IriTerm(:final value):
        _prepareIri(value, rows);
    }
  }

  void _prepareObject(RdfObject object, List<RdfStreamRow> rows) {
    switch (object) {
      case IriTerm(:final value):
        _prepareIri(value, rows);
      case LiteralTerm():
        _prepareLiteral(object, rows);
      case BlankNodeTerm():
        _prepareBlankNode(object);
    }
  }

  void _prepareIri(String iri, List<RdfStreamRow> rows) {
    if (maxPrefixTableSize > 0) {
      final (prefix, name) = _splitIri(iri);
      _ensurePrefix(prefix, rows);
      _ensureName(name, rows);
    } else {
      // No prefix table — entire IRI goes into name table
      _ensureName(iri, rows);
    }
  }

  void _prepareLiteral(LiteralTerm literal, List<RdfStreamRow> rows) {
    if (maxDatatypeTableSize > 0) {
      final dtIri = literal.datatype.value;
      // xsd:string and rdf:langString don't need explicit datatype entries
      if (dtIri != 'http://www.w3.org/2001/XMLSchema#string' &&
          literal.language == null) {
        _ensureDatatype(dtIri, rows);
      }
    }
  }

  void _prepareBlankNode(BlankNodeTerm bnode) {
    _blankNodeLabels.putIfAbsent(bnode, () => 'b${_nextBlankNodeId++}');
  }

  // ---------------------------------------------------------------------------
  // Lookup table entry emission
  // ---------------------------------------------------------------------------

  void _ensureName(String value, List<RdfStreamRow> rows) {
    final id = _nameTable.ensure(value);
    if (id != null) {
      final deltaId = _nameTable.deltaEncode(id);
      final entry = RdfNameEntry()..value = value;
      if (deltaId != 0) entry.id = deltaId;
      rows.add(RdfStreamRow()..name = entry);
    }
  }

  void _ensurePrefix(String value, List<RdfStreamRow> rows) {
    final id = _prefixTable.ensure(value);
    if (id != null) {
      final deltaId = _prefixTable.deltaEncode(id);
      final entry = RdfPrefixEntry()..value = value;
      if (deltaId != 0) entry.id = deltaId;
      rows.add(RdfStreamRow()..prefix = entry);
    }
  }

  void _ensureDatatype(String value, List<RdfStreamRow> rows) {
    final id = _datatypeTable.ensure(value);
    if (id != null) {
      final deltaId = _datatypeTable.deltaEncode(id);
      final entry = RdfDatatypeEntry()..value = value;
      if (deltaId != 0) entry.id = deltaId;
      rows.add(RdfStreamRow()..datatype = entry);
    }
  }

  // ---------------------------------------------------------------------------
  // IRI encoding
  // ---------------------------------------------------------------------------

  /// Encodes an IRI term into an [RdfIri] protobuf message with delta encoding.
  RdfIri encodeIri(String iri) {
    int prefixId;
    int nameId;

    if (maxPrefixTableSize > 0) {
      final (prefix, name) = _splitIri(iri);
      prefixId = _prefixTable[prefix]!;
      nameId = _nameTable[name]!;
    } else {
      prefixId = 0;
      nameId = _nameTable[iri]!;
    }

    // Delta encode: emit 0 if same as last
    final encodedPrefixId = prefixId == _lastPrefixId ? 0 : prefixId;
    final encodedNameId = nameId == _lastNameId + 1 ? 0 : nameId;

    if (encodedPrefixId != 0) _lastPrefixId = prefixId;
    _lastNameId = nameId;

    final result = RdfIri();
    if (encodedPrefixId != 0) result.prefixId = encodedPrefixId;
    if (encodedNameId != 0) result.nameId = encodedNameId;
    return result;
  }

  /// Encodes a blank node term, returning its label string.
  String encodeBlankNode(BlankNodeTerm bnode) {
    return _blankNodeLabels[bnode]!;
  }

  /// Encodes a literal term into an [RdfLiteral] protobuf message.
  RdfLiteral encodeLiteral(LiteralTerm literal) {
    final proto = RdfLiteral()..lex = literal.value;

    if (literal.language != null) {
      proto.langtag = literal.language!;
    } else {
      final dtIri = literal.datatype.value;
      if (dtIri != 'http://www.w3.org/2001/XMLSchema#string') {
        if (maxDatatypeTableSize > 0 && _datatypeTable.contains(dtIri)) {
          proto.datatype = _datatypeTable[dtIri]!;
        }
      }
    }

    return proto;
  }

  // ---------------------------------------------------------------------------
  // Triple encoding with repeated-term compression
  // ---------------------------------------------------------------------------

  /// Encodes a [Triple] into an [RdfTriple] protobuf message with
  /// repeated-term compression.
  RdfTriple encodeTriple(Triple triple) {
    final proto = RdfTriple();

    // Subject
    if (triple.subject != _lastSubject) {
      _lastSubject = triple.subject;
      switch (triple.subject) {
        case IriTerm(:final value):
          proto.sIri = encodeIri(value);
        case BlankNodeTerm():
          proto.sBnode = encodeBlankNode(triple.subject as BlankNodeTerm);
      }
    }

    // Predicate
    if (triple.predicate != _lastPredicate) {
      _lastPredicate = triple.predicate;
      switch (triple.predicate) {
        case IriTerm(:final value):
          proto.pIri = encodeIri(value);
      }
    }

    // Object
    if (triple.object != _lastObject) {
      _lastObject = triple.object;
      switch (triple.object) {
        case IriTerm(:final value):
          proto.oIri = encodeIri(value);
        case BlankNodeTerm():
          proto.oBnode = encodeBlankNode(triple.object as BlankNodeTerm);
        case LiteralTerm():
          proto.oLiteral = encodeLiteral(triple.object as LiteralTerm);
      }
    }

    return proto;
  }

  /// Encodes a [Quad] into an [RdfQuad] protobuf message with repeated-term
  /// compression.
  RdfQuad encodeQuad(Quad quad) {
    final proto = RdfQuad();

    // Subject
    if (quad.subject != _lastSubject) {
      _lastSubject = quad.subject;
      switch (quad.subject) {
        case IriTerm(:final value):
          proto.sIri = encodeIri(value);
        case BlankNodeTerm():
          proto.sBnode = encodeBlankNode(quad.subject as BlankNodeTerm);
      }
    }

    // Predicate
    if (quad.predicate != _lastPredicate) {
      _lastPredicate = quad.predicate;
      switch (quad.predicate) {
        case IriTerm(:final value):
          proto.pIri = encodeIri(value);
      }
    }

    // Object
    if (quad.object != _lastObject) {
      _lastObject = quad.object;
      switch (quad.object) {
        case IriTerm(:final value):
          proto.oIri = encodeIri(value);
        case BlankNodeTerm():
          proto.oBnode = encodeBlankNode(quad.object as BlankNodeTerm);
        case LiteralTerm():
          proto.oLiteral = encodeLiteral(quad.object as LiteralTerm);
      }
    }

    // Graph
    final isDefault = quad.graphName == null;
    if (isDefault && !_lastGraphWasDefault) {
      _lastGraphWasDefault = true;
      _lastGraphName = null;
      proto.gDefaultGraph = RdfDefaultGraph();
    } else if (!isDefault && quad.graphName != _lastGraphName) {
      _lastGraphName = quad.graphName;
      _lastGraphWasDefault = false;
      switch (quad.graphName!) {
        case IriTerm(:final value):
          proto.gIri = encodeIri(value);
        case BlankNodeTerm():
          proto.gBnode = encodeBlankNode(quad.graphName! as BlankNodeTerm);
      }
    }

    return proto;
  }

  // ---------------------------------------------------------------------------
  // Combined prepare+encode (atomic per-term, avoids eviction between
  // prepare and encode for the same term)
  // ---------------------------------------------------------------------------

  /// Produces all rows for a triple: lookup table entries followed by
  /// the triple row. Ensures all referenced entries are in the table
  /// when the triple row is emitted (re-adding any evicted entries).
  /// Appends all rows for [triple] into [rows]: lookup table entries followed
  /// by the triple row. Avoids a transient list allocation per triple compared
  /// to the return-value form.
  void emitTriple(Triple triple, List<RdfStreamRow> rows) {
    // Prepare all terms — this adds needed entries but may evict others
    _prepareSubject(triple.subject, rows);
    _preparePredicate(triple.predicate, rows);
    _prepareObject(triple.object, rows);
    // Re-ensure all IRI terms are still in the tables (re-adds if evicted)
    _reensureTripleIris(triple, rows);
    // Now all referenced entries are present — encode the triple
    rows.add(RdfStreamRow()..triple = encodeTriple(triple));
  }

  /// Appends all rows for [quad] into [rows]: lookup table entries followed
  /// by the quad row.
  void emitQuad(Quad quad, List<RdfStreamRow> rows) {
    _prepareSubject(quad.subject, rows);
    _preparePredicate(quad.predicate, rows);
    _prepareObject(quad.object, rows);
    if (quad.graphName != null) {
      switch (quad.graphName!) {
        case IriTerm(:final value):
          _prepareIri(value, rows);
        case BlankNodeTerm():
          _prepareBlankNode(quad.graphName! as BlankNodeTerm);
      }
    }
    // Re-ensure all IRI terms are still in the tables
    _reensureQuadIris(quad, rows);
    rows.add(RdfStreamRow()..quad = encodeQuad(quad));
  }

  /// Re-ensures all IRI values referenced by a triple are in the tables.
  /// Calls _ensureName/_ensurePrefix again for each — these are no-ops
  /// if the entry is still present, and re-add (with new ID) if evicted.
  void _reensureTripleIris(Triple triple, List<RdfStreamRow> rows) {
    if (triple.subject != _lastSubject && triple.subject is IriTerm) {
      _prepareIri((triple.subject as IriTerm).value, rows);
    }
    if (triple.predicate != _lastPredicate && triple.predicate is IriTerm) {
      _prepareIri((triple.predicate as IriTerm).value, rows);
    }
    if (triple.object != _lastObject && triple.object is IriTerm) {
      _prepareIri((triple.object as IriTerm).value, rows);
    }
  }

  /// Re-ensures all IRI values referenced by a quad are in the tables.
  void _reensureQuadIris(Quad quad, List<RdfStreamRow> rows) {
    if (quad.subject != _lastSubject && quad.subject is IriTerm) {
      _prepareIri((quad.subject as IriTerm).value, rows);
    }
    if (quad.predicate != _lastPredicate && quad.predicate is IriTerm) {
      _prepareIri((quad.predicate as IriTerm).value, rows);
    }
    if (quad.object != _lastObject && quad.object is IriTerm) {
      _prepareIri((quad.object as IriTerm).value, rows);
    }
    if (quad.graphName != null &&
        quad.graphName != _lastGraphName &&
        quad.graphName is IriTerm) {
      _prepareIri((quad.graphName! as IriTerm).value, rows);
    }
  }

  // ---------------------------------------------------------------------------
  // Graph stream support (GRAPHS physical type)
  // ---------------------------------------------------------------------------

  /// Encodes a graph start marker for GRAPHS physical type.
  RdfGraphStart encodeGraphStart(RdfGraphName? graphName) {
    final proto = RdfGraphStart();
    if (graphName == null) {
      proto.gDefaultGraph = RdfDefaultGraph();
    } else {
      switch (graphName) {
        case IriTerm(:final value):
          proto.gIri = encodeIri(value);
        case BlankNodeTerm():
          proto.gBnode = encodeBlankNode(graphName);
      }
    }
    return proto;
  }

  // ---------------------------------------------------------------------------
  // IRI splitting
  // ---------------------------------------------------------------------------

  /// Splits an IRI into (prefix, name) at the last '#' or '/'.
  ///
  /// If no split point is found, the entire IRI is the name and prefix is
  /// empty.
  static (String prefix, String name) _splitIri(String iri) {
    // Split at last '#' or '/'
    var splitIdx = iri.lastIndexOf('#');
    if (splitIdx >= 0) {
      return (iri.substring(0, splitIdx + 1), iri.substring(splitIdx + 1));
    }
    splitIdx = iri.lastIndexOf('/');
    if (splitIdx >= 0) {
      return (iri.substring(0, splitIdx + 1), iri.substring(splitIdx + 1));
    }
    return ('', iri);
  }
}
