/// Jelly frame encoder — varint-delimited Jelly frame construction.
///
/// Provides [JellyRawFrameWriter] which writes protobuf wire format directly,
/// eliminating GeneratedMessage allocation overhead on the encode hot path.
/// Also provides shared protobuf wire-format constants and varint utilities.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'proto/rdf.pb.dart';

// ---------------------------------------------------------------------------
// Protobuf wire-format tag constants
// ---------------------------------------------------------------------------
// Each tag encodes (field_number << 3 | wire_type). For LEN fields (wire
// type 2): tag = field_number * 8 + 2. For VARINT fields (wire type 0):
// tag = field_number * 8. All Jelly fields use field numbers <= 15, so
// every tag fits in a single byte (< 0x80).

// RdfStreamRow field tags (field_number << 3 | 2 for LEN wire type).
/// Tag for options field (field 1) in RdfStreamRow.
const kRowOptionsTag = 0x0A;

/// Tag for triple field (field 2) in RdfStreamRow.
const kRowTripleTag = 0x12;

/// Tag for quad field (field 3) in RdfStreamRow.
const kRowQuadTag = 0x1A;

/// Tag for graph_start field (field 4) in RdfStreamRow.
const kRowGraphStartTag = 0x22;

/// Tag for graph_end field (field 5) in RdfStreamRow.
const kRowGraphEndTag = 0x2A;

/// Tag for name field (field 9) in RdfStreamRow.
const kRowNameTag = 0x4A;

/// Tag for prefix field (field 10) in RdfStreamRow.
const kRowPrefixTag = 0x52;

/// Tag for datatype field (field 11) in RdfStreamRow.
const kRowDatatypeTag = 0x5A;

// RdfTriple / RdfQuad term field tags.
/// Tag for s_iri field (field 1, LEN).
const kSIriTag = 0x0A;

/// Tag for s_bnode field (field 2, LEN).
const kSBnodeTag = 0x12;

/// Tag for p_iri field (field 5, LEN).
const kPIriTag = 0x2A;

/// Tag for o_iri field (field 9, LEN).
const kOIriTag = 0x4A;

/// Tag for o_bnode field (field 10, LEN).
const kOBnodeTag = 0x52;

/// Tag for o_literal field (field 11, LEN).
const kOLiteralTag = 0x5A;

/// Tag for g_iri field (field 13, LEN) in RdfQuad.
const kGIriTag = 0x6A;

/// Tag for g_bnode field (field 14, LEN) in RdfQuad.
const kGBnodeTag = 0x72;

/// Tag for g_default_graph field (field 15, LEN) in RdfQuad.
const kGDefaultTag = 0x7A;

// RdfGraphStart field tags.
/// Tag for g_iri field (field 1, LEN) in RdfGraphStart.
const kGraphStartIriTag = 0x0A;

/// Tag for g_bnode field (field 2, LEN) in RdfGraphStart.
const kGraphStartBnodeTag = 0x12;

/// Tag for g_default_graph field (field 3, LEN) in RdfGraphStart.
const kGraphStartDefaultTag = 0x1A;

// RdfIri sub-message field tags (VARINT wire type).
/// Tag for prefix_id field (field 1, VARINT) in RdfIri.
const kIriPrefixIdTag = 0x08;

/// Tag for name_id field (field 2, VARINT) in RdfIri.
const kIriNameIdTag = 0x10;

// RdfLiteral field tags.
/// Tag for lex field (field 1, LEN) in RdfLiteral.
const kLitLexTag = 0x0A;

/// Tag for langtag field (field 2, LEN) in RdfLiteral.
const kLitLangtagTag = 0x12;

/// Tag for datatype field (field 3, VARINT) in RdfLiteral.
const kLitDatatypeTag = 0x18;

// Table entry field tags (same structure for Name/Prefix/Datatype entries).
/// Tag for id field (field 1, VARINT) in table entries.
const kEntryIdTag = 0x08;

/// Tag for value field (field 2, LEN) in table entries.
const kEntryValueTag = 0x12;

// Frame repeated-field tag.
/// Tag for rows field (field 1, LEN) in RdfStreamFrame.
const kFrameRowsTag = 0x0A;

// ---------------------------------------------------------------------------
// Varint utilities
// ---------------------------------------------------------------------------

/// Returns the number of bytes needed to encode [value] as a protobuf varint.
int varintSize(int value) {
  if (value < 0x80) return 1;
  if (value < 0x4000) return 2;
  if (value < 0x200000) return 3;
  if (value < 0x10000000) return 4;
  return 5;
}

/// Writes a protobuf varint to [buf].
void writeVarintTo(BytesBuilder buf, int value) {
  while (value > 0x7F) {
    buf.addByte((value & 0x7F) | 0x80);
    value >>= 7;
  }
  buf.addByte(value & 0x7F);
}

/// Writes a protobuf varint to [array] at [offset], returns the new offset.
int writeVarintToArray(Uint8List array, int offset, int value) {
  while (value > 0x7F) {
    array[offset++] = (value & 0x7F) | 0x80;
    value >>= 7;
  }
  array[offset++] = value & 0x7F;
  return offset;
}

// ---------------------------------------------------------------------------
// Raw frame writer — zero-allocation protobuf frame construction
// ---------------------------------------------------------------------------

/// Writes varint-delimited Jelly frames using direct protobuf wire-format
/// encoding, eliminating [GeneratedMessage] allocation overhead on the hot
/// path.
///
/// ## Why raw encoding?
///
/// Each [GeneratedMessage] allocation costs ~200-400ns due to internal field
/// arrays, type checking, and [BuilderInfo] setup. For 17k triples with 3-5
/// proto objects per triple, that's 34-60k allocations adding ~10ms of pure
/// overhead. By writing the wire format directly to a [BytesBuilder], we
/// eliminate all of this while producing byte-identical output.
///
/// ## Wire format contract
///
/// The output MUST be byte-for-byte identical to what the [GeneratedMessage]-
/// based serialization would produce for the same logical content. This is
/// enforced by `raw_wire_format_equivalence_test.dart` which compares raw
/// output against proto [writeToBuffer] at every level (sub-message, row
/// wrapping, and full frame).
///
/// ## Usage
///
/// Rows are serialized eagerly as they are added. Frames are flushed
/// automatically when [maxRowsPerFrame] is reached. Call [finish] to get
/// all accumulated frame bytes, or [drainFrames] for incremental streaming.
class JellyRawFrameWriter {
  /// Maximum rows per frame before automatic flush.
  final int maxRowsPerFrame;
  final BytesBuilder _frameRows = BytesBuilder(copy: false);
  final List<Uint8List> _flushedFrames = [];
  int _rowCount = 0;

  JellyRawFrameWriter(this.maxRowsPerFrame);

  /// Writes a pre-serialized options row (field 1 in RdfStreamRow).
  ///
  /// Uses proto serialization since this is called once per stream.
  void addOptionsRow(RdfStreamOptions options) {
    _addRow(kRowOptionsTag, options.writeToBuffer());
  }

  /// Writes a name entry row: RdfNameEntry { id, value }.
  void addNameEntry(int deltaId, String value) {
    _addRow(kRowNameTag, _encodeTableEntry(deltaId, value));
  }

  /// Writes a prefix entry row: RdfPrefixEntry { id, value }.
  void addPrefixEntry(int deltaId, String value) {
    _addRow(kRowPrefixTag, _encodeTableEntry(deltaId, value));
  }

  /// Writes a datatype entry row: RdfDatatypeEntry { id, value }.
  void addDatatypeEntry(int deltaId, String value) {
    _addRow(kRowDatatypeTag, _encodeTableEntry(deltaId, value));
  }

  /// Writes a triple row with pre-serialized content bytes.
  void addTripleRow(Uint8List tripleBytes) {
    _addRow(kRowTripleTag, tripleBytes);
  }

  /// Writes a quad row with pre-serialized content bytes.
  void addQuadRow(Uint8List quadBytes) {
    _addRow(kRowQuadTag, quadBytes);
  }

  /// Writes a graph start row with pre-serialized content bytes.
  void addGraphStartRow(Uint8List graphStartBytes) {
    _addRow(kRowGraphStartTag, graphStartBytes);
  }

  /// Writes a graph end row (empty RdfGraphEnd message).
  void addGraphEndRow() {
    _addRow(kRowGraphEndTag, const <int>[]);
  }

  /// Flushes any remaining rows and returns all accumulated frame bytes.
  Uint8List finish() {
    if (_rowCount > 0) _flushFrame();
    if (_flushedFrames.isEmpty) return Uint8List(0);
    if (_flushedFrames.length == 1) return _flushedFrames.single;
    final out = BytesBuilder(copy: false);
    for (final frame in _flushedFrames) {
      out.add(frame);
    }
    return out.toBytes();
  }

  /// Drains completed frames for streaming consumption.
  List<Uint8List> drainFrames() {
    if (_flushedFrames.isEmpty) return const [];
    final result = List<Uint8List>.of(_flushedFrames);
    _flushedFrames.clear();
    return result;
  }

  // --- Internal ---

  /// Encodes a table entry: { id (varint), value (string) }.
  static Uint8List _encodeTableEntry(int deltaId, String value) {
    final utf8Value = utf8.encode(value);
    int size = 0;
    if (deltaId != 0) size += 1 + varintSize(deltaId);
    size += 1 + varintSize(utf8Value.length) + utf8Value.length;

    final bytes = Uint8List(size);
    int offset = 0;
    if (deltaId != 0) {
      bytes[offset++] = kEntryIdTag;
      offset = writeVarintToArray(bytes, offset, deltaId);
    }
    bytes[offset++] = kEntryValueTag;
    offset = writeVarintToArray(bytes, offset, utf8Value.length);
    bytes.setRange(offset, offset + utf8Value.length, utf8Value);
    return bytes;
  }

  /// Wraps [contentBytes] as a row entry within the current frame.
  ///
  /// Wire format per row inside the frame's repeated field 1:
  ///   tag(1, LEN) + rowSize + tag(rowFieldTag) + contentLen + contentBytes
  void _addRow(int rowFieldTag, List<int> contentBytes) {
    final contentLen = contentBytes.length;
    final rowWrapperSize = 1 + varintSize(contentLen) + contentLen;
    _frameRows.addByte(kFrameRowsTag);
    writeVarintTo(_frameRows, rowWrapperSize);
    _frameRows.addByte(rowFieldTag);
    writeVarintTo(_frameRows, contentLen);
    if (contentLen > 0) _frameRows.add(contentBytes);
    _rowCount++;
    if (_rowCount >= maxRowsPerFrame) _flushFrame();
  }

  void _flushFrame() {
    final frameContent = _frameRows.takeBytes();
    final headerSize = varintSize(frameContent.length);
    final frame = Uint8List(headerSize + frameContent.length);
    writeVarintToArray(frame, 0, frameContent.length);
    frame.setRange(headerSize, frame.length, frameContent);
    _flushedFrames.add(frame);
    _rowCount = 0;
  }
}
