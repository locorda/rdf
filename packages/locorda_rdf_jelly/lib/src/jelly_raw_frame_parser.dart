/// Low-allocation Jelly frame parser.
///
/// Parses [RdfStreamFrame] protobuf bytes directly from a [Uint8List] without
/// materialising any [GeneratedMessage] objects on the hot path (triple/quad
/// rows and lookup-table entries). The only cold-path exceptions are:
///   - [RdfStreamOptions] (appears once per stream, not performance-critical)
///
/// All protobuf wire-format decoding is done inline in [_FrameParser], which
/// maintains a single position cursor into the frame buffer and handles
/// sub-message limits via explicit end-offset tracking rather than creating
/// nested reader objects.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:locorda_rdf_core/core.dart';

import 'jelly_decoder_state.dart';
import 'proto/rdf.pb.dart';

const _formatName = 'application/x-jelly-rdf';

// Protobuf wire types
const _wtVarint = 0;
const _wtLengthDelimited = 2;

/// Parses a single [RdfStreamFrame] from raw [frameBytes] without
/// materialising any protobuf objects on the triple/quad hot path.
///
/// Emits decoded statements via [onTriple] and/or [onQuad]. The caller
/// supplies exactly one of them for normal stream types; both may be supplied
/// for streams that mix physical types, though the Jelly spec does not
/// currently permit that.
void parseFrame(
  Uint8List frameBytes,
  JellyDecoderState state, {
  void Function(Triple triple)? onTriple,
  void Function(Quad quad)? onQuad,
}) {
  _FrameParser(frameBytes, state, onTriple: onTriple, onQuad: onQuad).parse();
}

/// Iterates varint-delimited [RdfStreamFrame] byte buffers and processes each
/// frame via [parseFrame] without materialising [RdfStreamFrame] objects.
///
/// This is the hot-path counterpart to [readDelimitedFrames]:
/// whereas [readDelimitedFrames] yields fully-deserialised [RdfStreamFrame]
/// objects (needed for inspecting frame structure), this function drives the
/// raw parser directly, eliminating all [GeneratedMessage] allocations.
void processRawDelimitedFrames(
  Uint8List bytes,
  JellyDecoderState state, {
  void Function(Triple triple)? onTriple,
  void Function(Quad quad)? onQuad,
}) {
  var offset = 0;
  while (offset < bytes.length) {
    final (length, bytesRead) = _readFramingVarint(bytes, offset);
    offset += bytesRead;

    if (offset + length > bytes.length) {
      throw RdfDecoderException(
        'Jelly stream error: truncated frame at offset $offset '
        '(expected $length bytes, have ${bytes.length - offset})',
        format: _formatName,
      );
    }

    parseFrame(
      Uint8List.sublistView(bytes, offset, offset + length),
      state,
      onTriple: onTriple,
      onQuad: onQuad,
    );
    offset += length;
  }
}

// ---------------------------------------------------------------------------
// Internal: raw parser
// ---------------------------------------------------------------------------

class _FrameParser {
  final Uint8List _buf;
  int _pos = 0;
  final JellyDecoderState _state;
  final void Function(Triple triple)? _onTriple;
  final void Function(Quad quad)? _onQuad;

  _FrameParser(
    this._buf,
    this._state, {
    void Function(Triple triple)? onTriple,
    void Function(Quad quad)? onQuad,
  })  : _onTriple = onTriple,
        _onQuad = onQuad;

  // -- Frame-level parse ------------------------------------------------------

  void parse() {
    final bufLen = _buf.length;
    while (_pos < bufLen) {
      final tag = _readVarint();
      switch (tag >> 3) {
        case 1: // rows: repeated RdfStreamRow
          if (tag & 0x7 != _wtLengthDelimited) {
            _skipByWireType(tag & 0x7);
            break;
          }
          final rowLen = _readVarint();
          final rowEnd = _pos + rowLen;
          _parseRow(rowEnd);
          _pos = rowEnd; // consume any trailing unknown fields in the row
        default:
          _skipByWireType(tag & 0x7);
      }
    }
  }

  // -- Row-level parse --------------------------------------------------------

  void _parseRow(int rowEnd) {
    // RdfStreamRow is a oneof — exactly one field will be set per row.
    while (_pos < rowEnd) {
      final tag = _readVarint();
      final fieldNum = tag >> 3;
      if (tag & 0x7 != _wtLengthDelimited) {
        // All row fields are length-delimited sub-messages.
        _skipByWireType(tag & 0x7);
        continue;
      }
      final subLen = _readVarint();
      final subEnd = _pos + subLen;
      switch (fieldNum) {
        case 1: // options — cold path, use GeneratedMessage
          _state.processOptions(
            RdfStreamOptions.fromBuffer(
              Uint8List.sublistView(_buf, _pos, subEnd),
            ),
          );
          _pos = subEnd;
        case 2: // triple
          _validatePhysical('triple', {
            PhysicalStreamType.PHYSICAL_STREAM_TYPE_QUADS,
          });
          _parseTripleRow(subEnd);
          _pos = subEnd;
        case 3: // quad
          _validatePhysical('quad', {
            PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES,
            PhysicalStreamType.PHYSICAL_STREAM_TYPE_GRAPHS,
          });
          _parseQuadRow(subEnd);
          _pos = subEnd;
        case 4: // graphStart
          _validatePhysical('graph_start', {
            PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES,
            PhysicalStreamType.PHYSICAL_STREAM_TYPE_QUADS,
          });
          _parseGraphStartRow(subEnd);
          _pos = subEnd;
        case 5: // graphEnd — empty message payload, just advance
          _validatePhysical('graph_end', {
            PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES,
            PhysicalStreamType.PHYSICAL_STREAM_TYPE_QUADS,
          });
          _state.processGraphEnd();
          _pos = subEnd;
        case 6: // namespace (cosmetic, ignored per spec)
          _pos = subEnd;
        case 9: // name entry
          _parseNameEntry(subEnd);
          _pos = subEnd;
        case 10: // prefix entry
          _parsePrefixEntry(subEnd);
          _pos = subEnd;
        case 11: // datatype entry
          _parseDatatypeEntry(subEnd);
          _pos = subEnd;
        default:
          _pos = subEnd; // skip unknown row types
      }
    }
  }

  // -- Lookup table entry parsing ---------------------------------------------

  void _parseNameEntry(int end) {
    int rawId = 0;
    String value = '';
    while (_pos < end) {
      final tag = _readVarint();
      switch (tag >> 3) {
        case 1:
          rawId = _readVarint();
        case 2:
          value = _readString();
        default:
          _skipByWireType(tag & 0x7);
      }
    }
    _state.processNameEntryRaw(rawId, value);
  }

  void _parsePrefixEntry(int end) {
    int rawId = 0;
    String value = '';
    while (_pos < end) {
      final tag = _readVarint();
      switch (tag >> 3) {
        case 1:
          rawId = _readVarint();
        case 2:
          value = _readString();
        default:
          _skipByWireType(tag & 0x7);
      }
    }
    _state.processPrefixEntryRaw(rawId, value);
  }

  void _parseDatatypeEntry(int end) {
    int rawId = 0;
    String value = '';
    while (_pos < end) {
      final tag = _readVarint();
      switch (tag >> 3) {
        case 1:
          rawId = _readVarint();
        case 2:
          value = _readString();
        default:
          _skipByWireType(tag & 0x7);
      }
    }
    _state.processDatatypeEntryRaw(rawId, value);
  }

  // -- Triple row parsing -----------------------------------------------------

  void _parseTripleRow(int end) {
    int subjectFieldNum = 0, predicateFieldNum = 0, objectFieldNum = 0;
    int sPrefixId = 0, sNameId = 0;
    String sBnode = '';
    int pPrefixId = 0, pNameId = 0;
    int oPrefixId = 0, oNameId = 0;
    String oBnode = '';
    String oLex = '';
    String? oLangtag;
    int oDatatypeId = 0;

    while (_pos < end) {
      final tag = _readVarint();
      final fieldNum = tag >> 3;
      switch (fieldNum) {
        case 1: // sIri
          subjectFieldNum = 1;
          final iLen = _readVarint();
          final iriEnd = _pos + iLen;
          (sPrefixId, sNameId) = _parseIri(iriEnd);
          _pos = iriEnd;
        case 2: // sBnode
          subjectFieldNum = 2;
          sBnode = _readString();
        case 3: // sLiteral (rejected by state, just parse past it)
          subjectFieldNum = 3;
          final sLen = _readVarint();
          _pos += sLen;
        case 4: // sTripleTerm (rejected by state, parse past)
          subjectFieldNum = 4;
          final sLen = _readVarint();
          _pos += sLen;
        case 5: // pIri
          predicateFieldNum = 5;
          final iLen = _readVarint();
          final iriEnd = _pos + iLen;
          (pPrefixId, pNameId) = _parseIri(iriEnd);
          _pos = iriEnd;
        case 6: // pBnode (rejected by state)
          predicateFieldNum = 6;
          _skipByWireType(tag & 0x7);
        case 7: // pLiteral (rejected by state)
          predicateFieldNum = 7;
          final pLen = _readVarint();
          _pos += pLen;
        case 8: // pTripleTerm (rejected by state)
          predicateFieldNum = 8;
          final pLen = _readVarint();
          _pos += pLen;
        case 9: // oIri
          objectFieldNum = 9;
          final iLen = _readVarint();
          final iriEnd = _pos + iLen;
          (oPrefixId, oNameId) = _parseIri(iriEnd);
          _pos = iriEnd;
        case 10: // oBnode
          objectFieldNum = 10;
          oBnode = _readString();
        case 11: // oLiteral
          objectFieldNum = 11;
          final lLen = _readVarint();
          final litEnd = _pos + lLen;
          (oLex, oLangtag, oDatatypeId) = _parseLiteral(litEnd);
          _pos = litEnd;
        case 12: // oTripleTerm (rejected by state)
          objectFieldNum = 12;
          final oLen = _readVarint();
          _pos += oLen;
        default:
          _skipByWireType(tag & 0x7);
      }
    }

    final s = _state.resolveSubjectRaw(subjectFieldNum,
        prefixId: sPrefixId, nameId: sNameId, bnode: sBnode);
    final p = _state.resolvePredicateRaw(predicateFieldNum,
        prefixId: pPrefixId, nameId: pNameId);
    final o = _state.resolveObjectRaw(objectFieldNum,
        prefixId: oPrefixId,
        nameId: oNameId,
        bnode: oBnode,
        lex: oLex,
        langtag: oLangtag,
        datatypeId: oDatatypeId);

    if (_onTriple != null) {
      _onTriple(Triple(s, p, o));
    } else if (_onQuad != null) {
      // GRAPHS physical type: wrap triple in current graph context.
      _onQuad(Quad(s, p, o, _state.currentGraphName));
    }
  }

  // -- Quad row parsing -------------------------------------------------------

  void _parseQuadRow(int end) {
    int subjectFieldNum = 0, predicateFieldNum = 0, objectFieldNum = 0;
    int graphFieldNum = 0;
    int sPrefixId = 0, sNameId = 0;
    String sBnode = '';
    int pPrefixId = 0, pNameId = 0;
    int oPrefixId = 0, oNameId = 0;
    String oBnode = '';
    String oLex = '';
    String? oLangtag;
    int oDatatypeId = 0;
    int gPrefixId = 0, gNameId = 0;
    String gBnode = '';

    while (_pos < end) {
      final tag = _readVarint();
      final fieldNum = tag >> 3;
      switch (fieldNum) {
        // Subject (fields 1–4, identical to RdfTriple)
        case 1:
          subjectFieldNum = 1;
          final iLen = _readVarint();
          final iriEnd = _pos + iLen;
          (sPrefixId, sNameId) = _parseIri(iriEnd);
          _pos = iriEnd;
        case 2:
          subjectFieldNum = 2;
          sBnode = _readString();
        case 3:
          subjectFieldNum = 3;
          final sLen = _readVarint();
          _pos += sLen;
        case 4:
          subjectFieldNum = 4;
          final sLen = _readVarint();
          _pos += sLen;
        // Predicate (fields 5–8)
        case 5:
          predicateFieldNum = 5;
          final iLen = _readVarint();
          final iriEnd = _pos + iLen;
          (pPrefixId, pNameId) = _parseIri(iriEnd);
          _pos = iriEnd;
        case 6:
          predicateFieldNum = 6;
          _skipByWireType(tag & 0x7);
        case 7:
          predicateFieldNum = 7;
          final pLen = _readVarint();
          _pos += pLen;
        case 8:
          predicateFieldNum = 8;
          final pLen = _readVarint();
          _pos += pLen;
        // Object (fields 9–12)
        case 9:
          objectFieldNum = 9;
          final iLen = _readVarint();
          final iriEnd = _pos + iLen;
          (oPrefixId, oNameId) = _parseIri(iriEnd);
          _pos = iriEnd;
        case 10:
          objectFieldNum = 10;
          oBnode = _readString();
        case 11:
          objectFieldNum = 11;
          final lLen = _readVarint();
          final litEnd = _pos + lLen;
          (oLex, oLangtag, oDatatypeId) = _parseLiteral(litEnd);
          _pos = litEnd;
        case 12:
          objectFieldNum = 12;
          final oLen = _readVarint();
          _pos += oLen;
        // Graph (fields 13–16)
        case 13: // gIri
          graphFieldNum = 13;
          final iLen = _readVarint();
          final iriEnd = _pos + iLen;
          (gPrefixId, gNameId) = _parseIri(iriEnd);
          _pos = iriEnd;
        case 14: // gBnode
          graphFieldNum = 14;
          gBnode = _readString();
        case 15: // gDefaultGraph (empty message)
          graphFieldNum = 15;
          final gLen = _readVarint();
          _pos += gLen; // empty payload (gLen == 0)
        case 16: // gLiteral (rejected by state)
          graphFieldNum = 16;
          final gLen = _readVarint();
          _pos += gLen;
        default:
          _skipByWireType(tag & 0x7);
      }
    }

    final s = _state.resolveSubjectRaw(subjectFieldNum,
        prefixId: sPrefixId, nameId: sNameId, bnode: sBnode);
    final p = _state.resolvePredicateRaw(predicateFieldNum,
        prefixId: pPrefixId, nameId: pNameId);
    final o = _state.resolveObjectRaw(objectFieldNum,
        prefixId: oPrefixId,
        nameId: oNameId,
        bnode: oBnode,
        lex: oLex,
        langtag: oLangtag,
        datatypeId: oDatatypeId);
    final graph = _state.resolveQuadGraphRaw(graphFieldNum,
        prefixId: gPrefixId, nameId: gNameId, bnode: gBnode);

    if (_onQuad != null) {
      _onQuad(Quad(s, p, o, graph.graphName));
    } else if (_onTriple != null) {
      // Caller requested triples but stream has quads — emit as triples
      // (discarding graph context, matching original processFrame behaviour).
      _onTriple(Triple(s, p, o));
    }
  }

  // -- Graph-start row parsing ------------------------------------------------

  void _parseGraphStartRow(int end) {
    int fieldNum = 0;
    int prefixId = 0, nameId = 0;
    String bnode = '';

    while (_pos < end) {
      final tag = _readVarint();
      switch (tag >> 3) {
        case 1: // gIri
          fieldNum = 1;
          final iLen = _readVarint();
          final iriEnd = _pos + iLen;
          (prefixId, nameId) = _parseIri(iriEnd);
          _pos = iriEnd;
        case 2: // gBnode
          fieldNum = 2;
          bnode = _readString();
        case 3: // gDefaultGraph (empty message)
          fieldNum = 3;
          final dLen = _readVarint();
          _pos += dLen;
        case 4: // gLiteral (rejected by state)
          fieldNum = 4;
          final lLen = _readVarint();
          _pos += lLen;
        default:
          _skipByWireType(tag & 0x7);
      }
    }

    _state.processGraphStartRaw(fieldNum,
        prefixId: prefixId, nameId: nameId, bnode: bnode);
  }

  // -- Sub-message helpers ----------------------------------------------------

  /// Parses an [RdfIri] sub-message from [_pos] to [end].
  /// Returns (prefixId, nameId); caller advances [_pos] to [end] after.
  (int prefixId, int nameId) _parseIri(int end) {
    int prefixId = 0, nameId = 0;
    while (_pos < end) {
      final tag = _readVarint();
      switch (tag >> 3) {
        case 1:
          prefixId = _readVarint();
        case 2:
          nameId = _readVarint();
        default:
          _skipByWireType(tag & 0x7);
      }
    }
    return (prefixId, nameId);
  }

  /// Parses an [RdfLiteral] sub-message from [_pos] to [end].
  /// Returns (lex, langtag, datatypeId); caller advances [_pos] to [end].
  (String lex, String? langtag, int datatypeId) _parseLiteral(int end) {
    String lex = '';
    String? langtag;
    int datatypeId = 0;
    while (_pos < end) {
      final tag = _readVarint();
      switch (tag >> 3) {
        case 1:
          lex = _readString();
        case 2:
          langtag = _readString();
        case 3:
          datatypeId = _readVarint();
          if (datatypeId == 0) {
            throw RdfDecoderException(
              'Jelly stream error: datatype index 0 is invalid '
              '(datatype table uses 1-based IDs without delta encoding)',
              format: _formatName,
            );
          }
        default:
          _skipByWireType(tag & 0x7);
      }
    }
    return (lex, langtag, datatypeId);
  }

  // -- Wire-format primitives -------------------------------------------------

  @pragma('vm:prefer-inline')
  int _readVarint() {
    var result = 0;
    var shift = 0;
    while (true) {
      final byte = _buf[_pos++];
      result |= (byte & 0x7f) << shift;
      if ((byte & 0x80) == 0) return result;
      shift += 7;
    }
  }

  @pragma('vm:prefer-inline')
  String _readString() {
    final length = _readVarint();
    final start = _pos;
    _pos += length;
    return const Utf8Decoder(allowMalformed: true)
        .convert(_buf, start, start + length);
  }

  void _skipByWireType(int wireType) {
    switch (wireType) {
      case _wtVarint:
        // Read and discard varint bytes.
        while ((_buf[_pos++] & 0x80) != 0) {}
      case 1: // 64-bit
        _pos += 8;
      case _wtLengthDelimited:
        final len = _readVarint();
        _pos += len;
      case 5: // 32-bit
        _pos += 4;
      // Wire types 3 (start group) and 4 (end group) are not used in
      // Jelly streams; ignoring them is safe.
    }
  }

  // -- Validation helper ------------------------------------------------------

  void _validatePhysical(String rowType, Set<PhysicalStreamType> forbidden) {
    final physicalType = _state.options?.physicalType;
    if (physicalType != null && forbidden.contains(physicalType)) {
      throw RdfDecoderException(
        'Jelly stream error: $rowType row not allowed in '
        '${physicalType.name} stream',
        format: _formatName,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Framing varint reader (standalone, no _FrameParser allocation)
// ---------------------------------------------------------------------------

/// Reads a protobuf-style varint from [bytes] at [offset].
/// Returns (decoded value, bytes consumed).
(int value, int bytesRead) _readFramingVarint(Uint8List bytes, int offset) {
  var result = 0;
  var shift = 0;
  var bytesRead = 0;
  while (offset < bytes.length) {
    final byte = bytes[offset];
    result |= (byte & 0x7F) << shift;
    offset++;
    bytesRead++;
    if ((byte & 0x80) == 0) return (result, bytesRead);
    shift += 7;
    if (shift > 63) {
      throw RdfDecoderException(
        'Jelly stream error: varint too large near frame boundary',
        format: _formatName,
      );
    }
  }
  throw RdfDecoderException(
    'Jelly stream error: truncated varint at end of input',
    format: _formatName,
  );
}
