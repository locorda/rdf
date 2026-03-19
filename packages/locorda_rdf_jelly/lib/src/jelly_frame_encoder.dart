/// Jelly frame encoder — builds [RdfStreamFrame] protobuf messages and
/// writes varint-delimited binary output.
library;

import 'dart:typed_data';

import 'proto/rdf.pb.dart';

/// Writes varint-delimited frames to a byte buffer.
///
/// Each frame is serialized as: varint(length) + frame_bytes.
class JellyFrameWriter {
  final BytesBuilder _buffer = BytesBuilder(copy: false);

  /// Writes a single [RdfStreamFrame] as a varint-delimited message.
  void writeFrame(RdfStreamFrame frame) {
    final frameBytes = frame.writeToBuffer();
    _writeVarint(frameBytes.length);
    _buffer.add(frameBytes);
  }

  /// Returns the accumulated bytes and resets the buffer.
  Uint8List toBytes() => _buffer.toBytes();

  void _writeVarint(int value) {
    while (value > 0x7F) {
      _buffer.addByte((value & 0x7F) | 0x80);
      value >>= 7;
    }
    _buffer.addByte(value & 0x7F);
  }
}
