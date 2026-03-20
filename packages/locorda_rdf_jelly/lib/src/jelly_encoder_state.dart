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

  /// Monotonically increasing counter of evictions since creation.
  int evictionCount = 0;

  EncoderLookupTable(this.maxSize);

  /// Returns the assigned ID for [value], or null if not present.
  int? operator [](String value) => _entries[value];

  /// Whether [value] is currently in the table.
  bool contains(String value) => _entries.containsKey(value);

  /// Ensures [value] is in the table and returns the result in a single
  /// lookup.
  ///
  /// If the value was already present, returns `(id, false)`.
  /// If a new entry was created (possibly evicting the oldest), returns
  /// `(id, true)`.
  (int id, bool isNew) ensureAndGetId(String value) {
    final existing = _entries[value];
    if (existing != null) return (existing, false);

    int id;
    if (_entries.length >= maxSize) {
      // O(1): LinkedHashMap iteration order == insertion order.
      final oldestKey = _entries.keys.first;
      id = _entries.remove(oldestKey)!;
      evictionCount++;
    } else {
      id = _nextId++;
    }

    _entries[value] = id;
    return (id, true);
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
///
/// The core optimisation is a two-phase ensure+encode pattern using
/// [EncoderLookupTable.ensureAndGetId] which combines containment check and
/// ID retrieval in a single Map lookup instead of the old `containsKey` +
/// `[]` pair. Phase 1 ensures all terms are in tables (emitting table-entry
/// rows); phase 2 encodes the proto with IRI references. A reensure pass
/// runs only when cross-term eviction is detected (uncommon with typical
/// table sizes).
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

  /// Cache of IRI → (prefix, name) splits to avoid redundant `lastIndexOf`
  /// calls across different terms sharing the same IRI.
  final Map<String, (String, String)> _iriSplitCache = {};

  JellyEncoderState({
    required this.maxNameTableSize,
    required this.maxPrefixTableSize,
    required this.maxDatatypeTableSize,
  })  : _nameTable = EncoderLookupTable(maxNameTableSize),
        _prefixTable = EncoderLookupTable(maxPrefixTableSize),
        _datatypeTable = EncoderLookupTable(maxDatatypeTableSize);

  // ---------------------------------------------------------------------------
  // Public API — ensure entries, then encode
  // ---------------------------------------------------------------------------

  /// Appends all rows for [triple] into [rows]: lookup table entries followed
  /// by the triple row.
  ///
  /// Phase 1 ensures all terms are in tables (emitting table-entry rows).
  /// If any eviction happened, a reensure pass guarantees all entries are
  /// still present. Phase 2 then encodes the proto with IRI references.
  void emitTriple(Triple triple, List<RdfStreamRow> rows) {
    // Phase 1: ensure all terms in tables
    final epoch = _nameTable.evictionCount + _prefixTable.evictionCount;
    _ensureTripleTerms(triple, rows);
    if (_nameTable.evictionCount + _prefixTable.evictionCount != epoch) {
      _ensureTripleIris(triple, rows);
    }

    // Phase 2: encode the proto using IDs guaranteed to be in tables
    final proto = RdfTriple();

    if (triple.subject != _lastSubject) {
      _lastSubject = triple.subject;
      switch (triple.subject) {
        case IriTerm(:final value):
          proto.sIri = _encodeIriFromTable(value);
        case BlankNodeTerm():
          proto.sBnode = _emitBlankNode(triple.subject as BlankNodeTerm);
      }
    }

    if (triple.predicate != _lastPredicate) {
      _lastPredicate = triple.predicate;
      switch (triple.predicate) {
        case IriTerm(:final value):
          proto.pIri = _encodeIriFromTable(value);
      }
    }

    if (triple.object != _lastObject) {
      _lastObject = triple.object;
      switch (triple.object) {
        case IriTerm(:final value):
          proto.oIri = _encodeIriFromTable(value);
        case BlankNodeTerm():
          proto.oBnode = _emitBlankNode(triple.object as BlankNodeTerm);
        case LiteralTerm():
          proto.oLiteral =
              _encodeLiteralFromTable(triple.object as LiteralTerm);
      }
    }

    rows.add(RdfStreamRow()..triple = proto);
  }

  /// Appends all rows for [quad] into [rows]: lookup table entries followed
  /// by the quad row.
  void emitQuad(Quad quad, List<RdfStreamRow> rows) {
    // Phase 1: ensure all terms in tables
    final epoch = _nameTable.evictionCount + _prefixTable.evictionCount;
    _ensureQuadTerms(quad, rows);
    if (_nameTable.evictionCount + _prefixTable.evictionCount != epoch) {
      _ensureQuadIris(quad, rows);
    }

    // Phase 2: encode the proto using IDs guaranteed to be in tables
    final proto = RdfQuad();

    if (quad.subject != _lastSubject) {
      _lastSubject = quad.subject;
      switch (quad.subject) {
        case IriTerm(:final value):
          proto.sIri = _encodeIriFromTable(value);
        case BlankNodeTerm():
          proto.sBnode = _emitBlankNode(quad.subject as BlankNodeTerm);
      }
    }

    if (quad.predicate != _lastPredicate) {
      _lastPredicate = quad.predicate;
      switch (quad.predicate) {
        case IriTerm(:final value):
          proto.pIri = _encodeIriFromTable(value);
      }
    }

    if (quad.object != _lastObject) {
      _lastObject = quad.object;
      switch (quad.object) {
        case IriTerm(:final value):
          proto.oIri = _encodeIriFromTable(value);
        case BlankNodeTerm():
          proto.oBnode = _emitBlankNode(quad.object as BlankNodeTerm);
        case LiteralTerm():
          proto.oLiteral = _encodeLiteralFromTable(quad.object as LiteralTerm);
      }
    }

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
          proto.gIri = _encodeIriFromTable(value);
        case BlankNodeTerm():
          proto.gBnode = _emitBlankNode(quad.graphName! as BlankNodeTerm);
      }
    }

    rows.add(RdfStreamRow()..quad = proto);
  }

  /// Ensures [term] is in the lookup tables and emits any needed table-entry
  /// rows. Used by the GRAPHS encoder for graph-start markers.
  ///
  /// Unlike [_emitIri], this does NOT update the IRI delta state
  /// (`_lastPrefixId`/`_lastNameId`) — that is left to [encodeGraphStart]
  /// which encodes the actual IRI reference.
  void emitTermEntries(RdfTerm term, List<RdfStreamRow> rows) {
    switch (term) {
      case IriTerm(:final value):
        _ensureIriTableEntries(value, rows);
      case LiteralTerm():
        _ensureLiteralEntries(term, rows);
      case BlankNodeTerm():
        _emitBlankNode(term);
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 1 helpers: ensure table entries for all terms
  // ---------------------------------------------------------------------------

  void _ensureTripleTerms(Triple triple, List<RdfStreamRow> rows) {
    _ensureSubjectEntries(triple.subject, rows);
    _ensurePredicateEntries(triple.predicate, rows);
    _ensureObjectEntries(triple.object, rows);
  }

  void _ensureQuadTerms(Quad quad, List<RdfStreamRow> rows) {
    _ensureSubjectEntries(quad.subject, rows);
    _ensurePredicateEntries(quad.predicate, rows);
    _ensureObjectEntries(quad.object, rows);
    if (quad.graphName != null) {
      switch (quad.graphName!) {
        case IriTerm(:final value):
          _ensureIriTableEntries(value, rows);
        case BlankNodeTerm():
          _emitBlankNode(quad.graphName! as BlankNodeTerm);
      }
    }
  }

  /// Re-ensures only IRI terms of a triple are still in tables after eviction.
  void _ensureTripleIris(Triple triple, List<RdfStreamRow> rows) {
    if (triple.subject is IriTerm) {
      _ensureIriTableEntries((triple.subject as IriTerm).value, rows);
    }
    if (triple.predicate is IriTerm) {
      _ensureIriTableEntries((triple.predicate as IriTerm).value, rows);
    }
    if (triple.object is IriTerm) {
      _ensureIriTableEntries((triple.object as IriTerm).value, rows);
    }
  }

  /// Re-ensures only IRI terms of a quad are still in tables after eviction.
  void _ensureQuadIris(Quad quad, List<RdfStreamRow> rows) {
    if (quad.subject is IriTerm) {
      _ensureIriTableEntries((quad.subject as IriTerm).value, rows);
    }
    if (quad.predicate is IriTerm) {
      _ensureIriTableEntries((quad.predicate as IriTerm).value, rows);
    }
    if (quad.object is IriTerm) {
      _ensureIriTableEntries((quad.object as IriTerm).value, rows);
    }
    if (quad.graphName is IriTerm) {
      _ensureIriTableEntries((quad.graphName! as IriTerm).value, rows);
    }
  }

  void _ensureSubjectEntries(RdfSubject subject, List<RdfStreamRow> rows) {
    switch (subject) {
      case IriTerm(:final value):
        _ensureIriTableEntries(value, rows);
      case BlankNodeTerm():
        _emitBlankNode(subject);
    }
  }

  void _ensurePredicateEntries(
      RdfPredicate predicate, List<RdfStreamRow> rows) {
    switch (predicate) {
      case IriTerm(:final value):
        _ensureIriTableEntries(value, rows);
    }
  }

  void _ensureObjectEntries(RdfObject object, List<RdfStreamRow> rows) {
    switch (object) {
      case IriTerm(:final value):
        _ensureIriTableEntries(value, rows);
      case LiteralTerm():
        _ensureLiteralEntries(object, rows);
      case BlankNodeTerm():
        _emitBlankNode(object);
    }
  }

  void _ensureLiteralEntries(LiteralTerm literal, List<RdfStreamRow> rows) {
    if (literal.language == null && maxDatatypeTableSize > 0) {
      final dtIri = literal.datatype.value;
      if (dtIri != 'http://www.w3.org/2001/XMLSchema#string') {
        final (dtId, dtIsNew) = _datatypeTable.ensureAndGetId(dtIri);
        if (dtIsNew) {
          final deltaId = _datatypeTable.deltaEncode(dtId);
          final entry = RdfDatatypeEntry()..value = dtIri;
          if (deltaId != 0) entry.id = deltaId;
          rows.add(RdfStreamRow()..datatype = entry);
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 2 helpers: encode proto from guaranteed-in-table IDs
  // ---------------------------------------------------------------------------

  /// Encodes a literal using IDs from the (already-ensured) datatype table.
  RdfLiteral _encodeLiteralFromTable(LiteralTerm literal) {
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
          proto.gIri = _encodeIriFromTable(value);
        case BlankNodeTerm():
          proto.gBnode = _emitBlankNode(graphName);
      }
    }
    return proto;
  }

  // ---------------------------------------------------------------------------
  // Combined ensure + encode for each term type (private)
  // ---------------------------------------------------------------------------

  /// Ensures the IRI's prefix and name are in the lookup tables and emits
  /// any needed table-entry rows, but does NOT encode an IRI reference and
  /// does NOT update `_lastPrefixId`/`_lastNameId`.
  ///
  /// Used by the ensure phase of [emitTriple]/[emitQuad] and by
  /// [emitTermEntries]. The actual IRI reference encoding is done separately
  /// via [_encodeIriFromTable].
  void _ensureIriTableEntries(String iri, List<RdfStreamRow> rows) {
    if (maxPrefixTableSize > 0) {
      final (prefix, name) = _splitIri(iri);

      final (pId, pIsNew) = _prefixTable.ensureAndGetId(prefix);
      if (pIsNew) {
        final deltaId = _prefixTable.deltaEncode(pId);
        final entry = RdfPrefixEntry()..value = prefix;
        if (deltaId != 0) entry.id = deltaId;
        rows.add(RdfStreamRow()..prefix = entry);
      }

      final (nId, nIsNew) = _nameTable.ensureAndGetId(name);
      if (nIsNew) {
        final deltaId = _nameTable.deltaEncode(nId);
        final entry = RdfNameEntry()..value = name;
        if (deltaId != 0) entry.id = deltaId;
        rows.add(RdfStreamRow()..name = entry);
      }
    } else {
      final (nId, nIsNew) = _nameTable.ensureAndGetId(iri);
      if (nIsNew) {
        final deltaId = _nameTable.deltaEncode(nId);
        final entry = RdfNameEntry()..value = iri;
        if (deltaId != 0) entry.id = deltaId;
        rows.add(RdfStreamRow()..name = entry);
      }
    }
  }

  /// Encodes an IRI that is already guaranteed to be in the lookup tables
  /// (e.g. after the ensure phase or [emitTermEntries]).
  RdfIri _encodeIriFromTable(String iri) {
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

    final encodedPrefixId = prefixId == _lastPrefixId ? 0 : prefixId;
    final encodedNameId = nameId == _lastNameId + 1 ? 0 : nameId;

    if (encodedPrefixId != 0) _lastPrefixId = prefixId;
    _lastNameId = nameId;

    final result = RdfIri();
    if (encodedPrefixId != 0) result.prefixId = encodedPrefixId;
    if (encodedNameId != 0) result.nameId = encodedNameId;
    return result;
  }

  /// Ensures the blank node has a label assigned and returns it.
  String _emitBlankNode(BlankNodeTerm bnode) {
    return _blankNodeLabels.putIfAbsent(bnode, () => 'b${_nextBlankNodeId++}');
  }

  // ---------------------------------------------------------------------------
  // IRI splitting
  // ---------------------------------------------------------------------------

  /// Splits an IRI into (prefix, name) at the last '#' or '/'.
  ///
  /// Results are cached in [_iriSplitCache] so that repeated lookups for the
  /// same IRI avoid redundant string scanning.
  (String prefix, String name) _splitIri(String iri) {
    return _iriSplitCache.putIfAbsent(iri, () {
      var splitIdx = iri.lastIndexOf('#');
      if (splitIdx >= 0) {
        return (iri.substring(0, splitIdx + 1), iri.substring(splitIdx + 1));
      }
      splitIdx = iri.lastIndexOf('/');
      if (splitIdx >= 0) {
        return (iri.substring(0, splitIdx + 1), iri.substring(splitIdx + 1));
      }
      return ('', iri);
    });
  }
}
