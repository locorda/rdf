/// Jelly frame decoder — processes [RdfStreamFrame] messages into RDF terms.
///
/// This is the shared frame-processing logic used by both streaming and batch
/// decoders. It delegates term reconstruction to [JellyDecoderState].
library;

import 'dart:typed_data';

import 'package:locorda_rdf_core/core.dart';

import 'jelly_decoder_state.dart';
import 'proto/rdf.pb.dart';

const _formatName = 'application/x-jelly-rdf';

/// Processes rows within a single [RdfStreamFrame], emitting triples or quads
/// via callbacks.
///
/// This function handles all row types: options, lookup table entries,
/// graph boundaries, and triple/quad statements. Validates physical stream
/// type constraints per the Jelly specification.
void processFrame(
  RdfStreamFrame frame,
  JellyDecoderState state, {
  void Function(Triple triple)? onTriple,
  void Function(Quad quad)? onQuad,
}) {
  for (final row in frame.rows) {
    switch (row.whichRow()) {
      case RdfStreamRow_Row.options:
        state.processOptions(row.options);

      case RdfStreamRow_Row.name:
        state.processNameEntry(row.name);

      case RdfStreamRow_Row.prefix:
        state.processPrefixEntry(row.prefix);

      case RdfStreamRow_Row.datatype:
        state.processDatatypeEntry(row.datatype);

      case RdfStreamRow_Row.triple:
        _rejectRowForPhysicalType(state, 'triple', const {
          PhysicalStreamType.PHYSICAL_STREAM_TYPE_QUADS,
        });
        if (onTriple != null) {
          onTriple(state.resolveTriple(row.triple));
        } else if (onQuad != null) {
          // GRAPHS physical type: wrap triple with current graph context
          final t = state.resolveTriple(row.triple);
          onQuad(Quad(
            t.subject,
            t.predicate,
            t.object,
            state.currentGraphName,
          ));
        }

      case RdfStreamRow_Row.quad:
        _rejectRowForPhysicalType(state, 'quad', const {
          PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES,
          PhysicalStreamType.PHYSICAL_STREAM_TYPE_GRAPHS,
        });
        if (onQuad != null) {
          onQuad(state.resolveQuad(row.quad));
        } else if (onTriple != null) {
          // Caller asked for triples but stream has quads — emit as triples
          // (discarding graph context)
          final q = state.resolveQuad(row.quad);
          onTriple(q.triple);
        }

      case RdfStreamRow_Row.graphStart:
        _rejectRowForPhysicalType(state, 'graph_start', const {
          PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES,
          PhysicalStreamType.PHYSICAL_STREAM_TYPE_QUADS,
        });
        state.processGraphStart(row.graphStart);

      case RdfStreamRow_Row.graphEnd:
        _rejectRowForPhysicalType(state, 'graph_end', const {
          PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES,
          PhysicalStreamType.PHYSICAL_STREAM_TYPE_QUADS,
        });
        state.processGraphEnd();

      case RdfStreamRow_Row.namespace:
        // Namespace declarations are cosmetic-only; ignore per plan.
        break;

      case RdfStreamRow_Row.notSet:
        throw RdfDecoderException(
          'Jelly stream error: encountered row with no field set',
          format: _formatName,
        );
    }
  }
}

/// Rejects a row type that is not allowed for the stream's physical type.
void _rejectRowForPhysicalType(
  JellyDecoderState state,
  String rowType,
  Set<PhysicalStreamType> forbidden,
) {
  final physicalType = state.options?.physicalType;
  if (physicalType != null && forbidden.contains(physicalType)) {
    throw RdfDecoderException(
      'Jelly stream error: $rowType row not allowed in '
      '${physicalType.name} stream',
      format: _formatName,
    );
  }
}

/// Reads a varint-delimited [RdfStreamFrame] sequence from raw bytes.
///
/// Jelly files use length-prefixed (varint) framing since protobuf messages
/// are not self-delimiting. Uses zero-copy sub-views to avoid allocating
/// copies of each frame's bytes.
Iterable<RdfStreamFrame> readDelimitedFrames(Uint8List bytes) sync* {
  var offset = 0;
  while (offset < bytes.length) {
    final (length, bytesRead) = _readVarint(bytes, offset);
    offset += bytesRead;

    if (offset + length > bytes.length) {
      throw RdfDecoderException(
        'Jelly stream error: truncated frame at offset $offset '
        '(expected $length bytes, have ${bytes.length - offset})',
        format: _formatName,
      );
    }

    yield RdfStreamFrame.fromBuffer(
        Uint8List.sublistView(bytes, offset, offset + length));
    offset += length;
  }
}

/// Reads a protobuf-style varint from [bytes] starting at [offset].
/// Returns the decoded value and the number of bytes consumed.
(int value, int bytesRead) _readVarint(Uint8List bytes, int offset) {
  var result = 0;
  var shift = 0;
  var bytesRead = 0;

  while (offset < bytes.length) {
    final byte = bytes[offset];
    result |= (byte & 0x7F) << shift;
    offset++;
    bytesRead++;
    if ((byte & 0x80) == 0) {
      return (result, bytesRead);
    }
    shift += 7;
    if (shift > 63) {
      throw RdfDecoderException(
        'Jelly stream error: varint too large at offset ${offset - bytesRead}',
        format: _formatName,
      );
    }
  }

  throw RdfDecoderException(
    'Jelly stream error: truncated varint at offset ${offset - bytesRead}',
    format: _formatName,
  );
}
