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

  /// Returns the accumulated bytes for the most-recently written frame and
  /// resets the buffer, ready for the next frame.
  ///
  /// Uses [BytesBuilder.takeBytes] so that subsequent [writeFrame] calls start
  /// with an empty buffer instead of appending to the previous frame's bytes.
  Uint8List toBytes() => _buffer.takeBytes();

  void _writeVarint(int value) {
    while (value > 0x7F) {
      _buffer.addByte((value & 0x7F) | 0x80);
      value >>= 7;
    }
    _buffer.addByte(value & 0x7F);
  }
}
