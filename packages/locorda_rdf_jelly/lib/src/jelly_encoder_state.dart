/// Jelly encoder state — manages lookup tables, delta encoding, and
/// repeated-term compression for producing Jelly binary streams.
///
/// Uses direct protobuf wire-format writing (via [JellyRawFrameWriter]) to
/// avoid GeneratedMessage allocation overhead on the encode hot path.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:locorda_rdf_core/core.dart';

import 'jelly_frame_encoder.dart';

const _xsdString = 'http://www.w3.org/2001/XMLSchema#string';

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
/// rows); phase 2 writes raw protobuf bytes for each term. A reensure pass
/// runs only when cross-term eviction is detected (uncommon with typical
/// table sizes).
///
/// Phase 2 writes protobuf wire format directly into a reusable
/// [BytesBuilder], completely bypassing [GeneratedMessage] allocation
/// overhead. The resulting bytes are passed to [JellyRawFrameWriter] which
/// assembles varint-delimited frames.
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

  /// Reusable builder for serializing triple/quad message bytes.
  final BytesBuilder _msgBuilder = BytesBuilder(copy: false);

  /// Reusable builder for serializing nested sub-messages (literals, graph
  /// starts) that need to be length-prefixed inside the outer message.
  final BytesBuilder _subMsgBuilder = BytesBuilder(copy: false);

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

  /// Appends all rows for [triple] into [writer]: lookup table entries
  /// followed by the triple row.
  ///
  /// Phase 1 ensures all terms are in tables (writing table-entry rows).
  /// If any eviction happened, a reensure pass guarantees all entries are
  /// still present. Phase 2 then writes raw protobuf bytes for the triple.
  void emitTriple(Triple triple, JellyRawFrameWriter writer) {
    // Phase 1: ensure all terms in tables
    final epoch = _nameTable.evictionCount + _prefixTable.evictionCount;
    _ensureTripleTerms(triple, writer);
    if (_nameTable.evictionCount + _prefixTable.evictionCount != epoch) {
      _ensureTripleIris(triple, writer);
    }

    // Phase 2: write raw protobuf bytes for the triple
    final buf = _msgBuilder;

    if (triple.subject != _lastSubject) {
      _lastSubject = triple.subject;
      switch (triple.subject) {
        case IriTerm(:final value):
          _writeIriField(buf, kSIriTag, value);
        case BlankNodeTerm():
          _writeStringField(
              buf, kSBnodeTag, _emitBlankNode(triple.subject as BlankNodeTerm));
      }
    }

    if (triple.predicate != _lastPredicate) {
      _lastPredicate = triple.predicate;
      switch (triple.predicate) {
        case IriTerm(:final value):
          _writeIriField(buf, kPIriTag, value);
      }
    }

    if (triple.object != _lastObject) {
      _lastObject = triple.object;
      switch (triple.object) {
        case IriTerm(:final value):
          _writeIriField(buf, kOIriTag, value);
        case BlankNodeTerm():
          _writeStringField(
              buf, kOBnodeTag, _emitBlankNode(triple.object as BlankNodeTerm));
        case LiteralTerm():
          _writeLiteralField(buf, kOLiteralTag, triple.object as LiteralTerm);
      }
    }

    writer.addTripleRow(buf.takeBytes());
  }

  /// Appends all rows for [quad] into [writer]: lookup table entries followed
  /// by the quad row.
  void emitQuad(Quad quad, JellyRawFrameWriter writer) {
    // Phase 1: ensure all terms in tables
    final epoch = _nameTable.evictionCount + _prefixTable.evictionCount;
    _ensureQuadTerms(quad, writer);
    if (_nameTable.evictionCount + _prefixTable.evictionCount != epoch) {
      _ensureQuadIris(quad, writer);
    }

    // Phase 2: write raw protobuf bytes for the quad
    final buf = _msgBuilder;

    if (quad.subject != _lastSubject) {
      _lastSubject = quad.subject;
      switch (quad.subject) {
        case IriTerm(:final value):
          _writeIriField(buf, kSIriTag, value);
        case BlankNodeTerm():
          _writeStringField(
              buf, kSBnodeTag, _emitBlankNode(quad.subject as BlankNodeTerm));
      }
    }

    if (quad.predicate != _lastPredicate) {
      _lastPredicate = quad.predicate;
      switch (quad.predicate) {
        case IriTerm(:final value):
          _writeIriField(buf, kPIriTag, value);
      }
    }

    if (quad.object != _lastObject) {
      _lastObject = quad.object;
      switch (quad.object) {
        case IriTerm(:final value):
          _writeIriField(buf, kOIriTag, value);
        case BlankNodeTerm():
          _writeStringField(
              buf, kOBnodeTag, _emitBlankNode(quad.object as BlankNodeTerm));
        case LiteralTerm():
          _writeLiteralField(buf, kOLiteralTag, quad.object as LiteralTerm);
      }
    }

    final isDefault = quad.graphName == null;
    if (isDefault && !_lastGraphWasDefault) {
      _lastGraphWasDefault = true;
      _lastGraphName = null;
      buf.addByte(kGDefaultTag);
      buf.addByte(0x00); // empty sub-message
    } else if (!isDefault && quad.graphName != _lastGraphName) {
      _lastGraphName = quad.graphName;
      _lastGraphWasDefault = false;
      switch (quad.graphName!) {
        case IriTerm(:final value):
          _writeIriField(buf, kGIriTag, value);
        case BlankNodeTerm():
          _writeStringField(buf, kGBnodeTag,
              _emitBlankNode(quad.graphName! as BlankNodeTerm));
      }
    }

    writer.addQuadRow(buf.takeBytes());
  }

  /// Ensures [term] is in the lookup tables and writes any needed table-entry
  /// rows. Used by the GRAPHS encoder for graph-start markers.
  void emitTermEntries(RdfTerm term, JellyRawFrameWriter writer) {
    switch (term) {
      case IriTerm(:final value):
        _ensureIriTableEntries(value, writer);
      case LiteralTerm():
        _ensureLiteralEntries(term, writer);
      case BlankNodeTerm():
        _emitBlankNode(term);
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 1 helpers: ensure table entries for all terms
  // ---------------------------------------------------------------------------

  void _ensureTripleTerms(Triple triple, JellyRawFrameWriter writer) {
    _ensureSubjectEntries(triple.subject, writer);
    _ensurePredicateEntries(triple.predicate, writer);
    _ensureObjectEntries(triple.object, writer);
  }

  void _ensureQuadTerms(Quad quad, JellyRawFrameWriter writer) {
    _ensureSubjectEntries(quad.subject, writer);
    _ensurePredicateEntries(quad.predicate, writer);
    _ensureObjectEntries(quad.object, writer);
    if (quad.graphName != null) {
      switch (quad.graphName!) {
        case IriTerm(:final value):
          _ensureIriTableEntries(value, writer);
        case BlankNodeTerm():
          _emitBlankNode(quad.graphName! as BlankNodeTerm);
      }
    }
  }

  /// Re-ensures only IRI terms of a triple are still in tables after eviction.
  void _ensureTripleIris(Triple triple, JellyRawFrameWriter writer) {
    if (triple.subject is IriTerm) {
      _ensureIriTableEntries((triple.subject as IriTerm).value, writer);
    }
    if (triple.predicate is IriTerm) {
      _ensureIriTableEntries((triple.predicate as IriTerm).value, writer);
    }
    if (triple.object is IriTerm) {
      _ensureIriTableEntries((triple.object as IriTerm).value, writer);
    }
  }

  /// Re-ensures only IRI terms of a quad are still in tables after eviction.
  void _ensureQuadIris(Quad quad, JellyRawFrameWriter writer) {
    if (quad.subject is IriTerm) {
      _ensureIriTableEntries((quad.subject as IriTerm).value, writer);
    }
    if (quad.predicate is IriTerm) {
      _ensureIriTableEntries((quad.predicate as IriTerm).value, writer);
    }
    if (quad.object is IriTerm) {
      _ensureIriTableEntries((quad.object as IriTerm).value, writer);
    }
    if (quad.graphName is IriTerm) {
      _ensureIriTableEntries((quad.graphName! as IriTerm).value, writer);
    }
  }

  void _ensureSubjectEntries(RdfSubject subject, JellyRawFrameWriter writer) {
    switch (subject) {
      case IriTerm(:final value):
        _ensureIriTableEntries(value, writer);
      case BlankNodeTerm():
        _emitBlankNode(subject);
    }
  }

  void _ensurePredicateEntries(
      RdfPredicate predicate, JellyRawFrameWriter writer) {
    switch (predicate) {
      case IriTerm(:final value):
        _ensureIriTableEntries(value, writer);
    }
  }

  void _ensureObjectEntries(RdfObject object, JellyRawFrameWriter writer) {
    switch (object) {
      case IriTerm(:final value):
        _ensureIriTableEntries(value, writer);
      case LiteralTerm():
        _ensureLiteralEntries(object, writer);
      case BlankNodeTerm():
        _emitBlankNode(object);
    }
  }

  void _ensureLiteralEntries(LiteralTerm literal, JellyRawFrameWriter writer) {
    if (literal.language == null) {
      final dtIri = literal.datatype.value;
      if (dtIri != _xsdString) {
        if (maxDatatypeTableSize == 0) {
          throw RdfEncoderException(
            'Jelly encode error: typed literal with datatype <$dtIri> cannot '
            'be encoded when maxDatatypeTableSize is 0',
            format: 'Jelly',
          );
        }
        final (dtId, dtIsNew) = _datatypeTable.ensureAndGetId(dtIri);
        if (dtIsNew) {
          final deltaId = _datatypeTable.deltaEncode(dtId);
          writer.addDatatypeEntry(deltaId, dtIri);
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Phase 2 helpers: write raw protobuf bytes for terms
  // ---------------------------------------------------------------------------

  /// Writes an IRI term as a length-delimited sub-message to [buf].
  ///
  /// Wire format: tag(fieldTag, LEN) + varint(iriSize) + iri_bytes
  /// where iri_bytes may contain prefix_id and/or name_id varints.
  /// Updates the IRI delta state ([_lastPrefixId] / [_lastNameId]).
  void _writeIriField(BytesBuilder buf, int fieldTag, String iri) {
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

    // Compute IRI sub-message size
    int iriSize = 0;
    if (encodedPrefixId != 0) iriSize += 1 + varintSize(encodedPrefixId);
    if (encodedNameId != 0) iriSize += 1 + varintSize(encodedNameId);

    // Write: field tag + varint(iriSize) + iri content
    buf.addByte(fieldTag);
    writeVarintTo(buf, iriSize);
    if (encodedPrefixId != 0) {
      buf.addByte(kIriPrefixIdTag);
      writeVarintTo(buf, encodedPrefixId);
    }
    if (encodedNameId != 0) {
      buf.addByte(kIriNameIdTag);
      writeVarintTo(buf, encodedNameId);
    }
  }

  /// Writes a string field (bnode label) to [buf].
  void _writeStringField(BytesBuilder buf, int fieldTag, String value) {
    final utf8Bytes = utf8.encode(value);
    buf.addByte(fieldTag);
    writeVarintTo(buf, utf8Bytes.length);
    buf.add(utf8Bytes);
  }

  /// Writes a literal term as a length-delimited sub-message to [buf].
  ///
  /// Computes the exact sub-message size first, then writes in a single
  /// forward pass — no intermediate BytesBuilder needed for the content.
  void _writeLiteralField(BytesBuilder buf, int fieldTag, LiteralTerm literal) {
    final lexUtf8 = utf8.encode(literal.value);
    Uint8List? langUtf8;
    int? dtId;

    // Compute literal sub-message size
    int litSize = 1 + varintSize(lexUtf8.length) + lexUtf8.length;

    if (literal.language != null) {
      langUtf8 = utf8.encode(literal.language!);
      litSize += 1 + varintSize(langUtf8.length) + langUtf8.length;
    } else {
      final dtIri = literal.datatype.value;
      if (dtIri != _xsdString &&
          maxDatatypeTableSize > 0 &&
          _datatypeTable.contains(dtIri)) {
        dtId = _datatypeTable[dtIri]!;
        litSize += 1 + varintSize(dtId);
      }
    }

    // Write: field tag + varint(litSize) + literal content
    buf.addByte(fieldTag);
    writeVarintTo(buf, litSize);
    buf.addByte(kLitLexTag);
    writeVarintTo(buf, lexUtf8.length);
    buf.add(lexUtf8);

    if (langUtf8 != null) {
      buf.addByte(kLitLangtagTag);
      writeVarintTo(buf, langUtf8.length);
      buf.add(langUtf8);
    } else if (dtId != null) {
      buf.addByte(kLitDatatypeTag);
      writeVarintTo(buf, dtId);
    }
  }

  // ---------------------------------------------------------------------------
  // Graph stream support (GRAPHS physical type)
  // ---------------------------------------------------------------------------

  /// Encodes a graph start marker as raw protobuf bytes.
  Uint8List encodeGraphStart(RdfGraphName? graphName) {
    final buf = _subMsgBuilder;
    if (graphName == null) {
      buf.addByte(kGraphStartDefaultTag);
      buf.addByte(0x00); // empty sub-message
    } else {
      switch (graphName) {
        case IriTerm(:final value):
          _writeIriField(buf, kGraphStartIriTag, value);
        case BlankNodeTerm():
          _writeStringField(
              buf, kGraphStartBnodeTag, _emitBlankNode(graphName));
      }
    }
    return buf.takeBytes();
  }

  // ---------------------------------------------------------------------------
  // Combined ensure + encode for each term type (private)
  // ---------------------------------------------------------------------------

  /// Ensures the IRI's prefix and name are in the lookup tables and writes
  /// any needed table-entry rows to [writer].
  ///
  /// Does NOT update the IRI delta state (`_lastPrefixId`/`_lastNameId`) —
  /// that is handled by [_writeIriField] during phase 2.
  void _ensureIriTableEntries(String iri, JellyRawFrameWriter writer) {
    if (maxPrefixTableSize > 0) {
      final (prefix, name) = _splitIri(iri);

      final (pId, pIsNew) = _prefixTable.ensureAndGetId(prefix);
      if (pIsNew) {
        writer.addPrefixEntry(_prefixTable.deltaEncode(pId), prefix);
      }

      final (nId, nIsNew) = _nameTable.ensureAndGetId(name);
      if (nIsNew) {
        writer.addNameEntry(_nameTable.deltaEncode(nId), name);
      }
    } else {
      final (nId, nIsNew) = _nameTable.ensureAndGetId(iri);
      if (nIsNew) {
        writer.addNameEntry(_nameTable.deltaEncode(nId), iri);
      }
    }
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
