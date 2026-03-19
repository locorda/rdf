/// Jelly RDF codec implementation.
///
/// Provides batch and streaming decoders/encoders for the Jelly binary RDF
/// format, plus the codec classes that integrate with [RdfCore].
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:locorda_rdf_core/core.dart';

import 'jelly_decoder_state.dart';
import 'jelly_encoder_state.dart';
import 'jelly_frame_decoder.dart';
import 'jelly_frame_encoder.dart';
import 'jelly_options.dart';
import 'proto/rdf.pb.dart';

// ---------------------------------------------------------------------------
// Frame-level converters (also usable as StreamTransformers via .bind())
// ---------------------------------------------------------------------------

/// Encodes triple batches into varint-delimited Jelly frames.
///
/// **Single-batch** ([convert]): encodes the triples as a self-contained Jelly
/// stream (options row + data); each call creates a fresh lookup-table state.
///
/// **Streaming** ([bind]): lookup-table state is shared across the entire
/// input stream — only the first frame carries the options row, subsequent
/// frames reuse the accumulated tables for better compression.
///
/// Each input batch may span multiple physical frames when the encoded row
/// count exceeds [JellyEncoderOptions.maxRowsPerFrame].
///
/// Example:
/// ```dart
/// // single batch
/// final bytes = JellyTripleFrameEncoder(options: opts).convert(triples);
///
/// // streaming pipeline
/// final encoded = JellyTripleFrameEncoder(options: opts).bind(frameStream);
/// await encoded.pipe(file.openWrite());
/// ```
class JellyTripleFrameEncoder extends Converter<Iterable<Triple>, Uint8List> {
  final JellyEncoderOptions _options;

  const JellyTripleFrameEncoder({
    JellyEncoderOptions options = const JellyEncoderOptions(),
  }) : _options = options;

  /// Encodes [input] as a self-contained Jelly stream with a fresh state.
  @override
  Uint8List convert(Iterable<Triple> input) {
    final state = JellyEncoderState(
      maxNameTableSize: _options.maxNameTableSize,
      maxPrefixTableSize: _options.maxPrefixTableSize,
      maxDatatypeTableSize: _options.maxDatatypeTableSize,
    );
    final rows = <RdfStreamRow>[
      buildOptionsRow(
          _options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES),
    ];
    for (final triple in input) {
      rows.addAll(state.emitTriple(triple));
    }
    return _concatBytes(_splitIntoFrames(rows, _options.maxRowsPerFrame));
  }

  /// Encodes a stream of batches sharing lookup-table state across all frames.
  @override
  Stream<Uint8List> bind(Stream<Iterable<Triple>> stream) async* {
    final state = JellyEncoderState(
      maxNameTableSize: _options.maxNameTableSize,
      maxPrefixTableSize: _options.maxPrefixTableSize,
      maxDatatypeTableSize: _options.maxDatatypeTableSize,
    );
    bool firstBatch = true;
    await for (final triples in stream) {
      final rows = <RdfStreamRow>[];
      if (firstBatch) {
        rows.add(buildOptionsRow(
            _options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES));
        firstBatch = false;
      }
      for (final triple in triples) {
        rows.addAll(state.emitTriple(triple));
      }
      for (final frameBytes
          in _splitIntoFrames(rows, _options.maxRowsPerFrame)) {
        yield frameBytes;
      }
    }
  }
}

/// Encodes quad batches into varint-delimited Jelly frames using the QUADS
/// physical stream type.
///
/// **Single-batch** ([convert]): self-contained Jelly stream, fresh state.
/// **Streaming** ([bind]): shared lookup-table state across the stream for
/// better compression.
///
/// For GRAPHS physical type, use [JellyDatasetEncoder] directly.
///
/// Example:
/// ```dart
/// // single batch
/// final bytes = JellyQuadFrameEncoder(options: opts).convert(quads);
///
/// // streaming pipeline
/// final encoded = JellyQuadFrameEncoder(options: opts).bind(quadBatchStream);
/// ```
class JellyQuadFrameEncoder extends Converter<Iterable<Quad>, Uint8List> {
  final JellyEncoderOptions _options;

  const JellyQuadFrameEncoder({
    JellyEncoderOptions options = const JellyEncoderOptions(
      physicalType: PhysicalStreamType.PHYSICAL_STREAM_TYPE_QUADS,
    ),
  }) : _options = options;

  /// Encodes [input] as a self-contained Jelly stream with a fresh state.
  @override
  Uint8List convert(Iterable<Quad> input) {
    final state = JellyEncoderState(
      maxNameTableSize: _options.maxNameTableSize,
      maxPrefixTableSize: _options.maxPrefixTableSize,
      maxDatatypeTableSize: _options.maxDatatypeTableSize,
    );
    final rows = <RdfStreamRow>[
      buildOptionsRow(_options, _options.physicalType),
    ];
    for (final quad in input) {
      rows.addAll(state.emitQuad(quad));
    }
    return _concatBytes(_splitIntoFrames(rows, _options.maxRowsPerFrame));
  }

  /// Encodes a stream of batches sharing lookup-table state across all frames.
  @override
  Stream<Uint8List> bind(Stream<Iterable<Quad>> stream) async* {
    final state = JellyEncoderState(
      maxNameTableSize: _options.maxNameTableSize,
      maxPrefixTableSize: _options.maxPrefixTableSize,
      maxDatatypeTableSize: _options.maxDatatypeTableSize,
    );
    bool firstBatch = true;
    await for (final quads in stream) {
      final rows = <RdfStreamRow>[];
      if (firstBatch) {
        rows.add(buildOptionsRow(_options, _options.physicalType));
        firstBatch = false;
      }
      for (final quad in quads) {
        rows.addAll(state.emitQuad(quad));
      }
      for (final frameBytes
          in _splitIntoFrames(rows, _options.maxRowsPerFrame)) {
        yield frameBytes;
      }
    }
  }
}

/// Decodes varint-delimited Jelly binary into triple batches, one
/// [List<Triple>] per physical frame.
///
/// **Single-buffer** ([convert]): decodes all frames in the given [Uint8List]
/// with a fresh state; returns all triples merged across frames.
/// **Streaming** ([bind]): decoder state (lookup tables) persists across
/// incoming chunks, yielding one list per frame. Use [Stream.expand] to
/// flatten:
/// ```dart
/// Stream<Triple> triples =
///     JellyTripleFrameDecoder().bind(byteStream).expand((f) => f);
/// ```
class JellyTripleFrameDecoder extends Converter<Uint8List, List<Triple>> {
  const JellyTripleFrameDecoder();

  /// Decodes all frames in [input], returning every triple across all frames.
  @override
  List<Triple> convert(Uint8List input) {
    return _decodeTriplesFromFrames(_parseFrames(input));
  }

  /// Decodes a stream of byte chunks, yielding one [List<Triple>] per frame.
  @override
  Stream<List<Triple>> bind(Stream<Uint8List> stream) async* {
    final state = JellyDecoderState();
    await for (final chunk in stream) {
      for (final frame in readDelimitedFrames(chunk)) {
        final triples = <Triple>[];
        processFrame(frame, state, onTriple: triples.add);
        yield triples;
      }
    }
  }
}

/// Decodes varint-delimited Jelly binary into quad batches, one [List<Quad>]
/// per physical frame.
///
/// Handles QUADS and GRAPHS physical stream types.
///
/// **Single-buffer** ([convert]): fresh state, all quads merged across frames.
/// **Streaming** ([bind]): shared state across the stream, one list per frame.
/// Use [Stream.expand] to flatten:
/// ```dart
/// Stream<Quad> quads =
///     JellyQuadFrameDecoder().bind(byteStream).expand((f) => f);
/// ```
class JellyQuadFrameDecoder extends Converter<Uint8List, List<Quad>> {
  const JellyQuadFrameDecoder();

  /// Decodes all frames in [input], returning every quad across all frames.
  @override
  List<Quad> convert(Uint8List input) {
    return _decodeQuadsFromFrames(_parseFrames(input));
  }

  /// Decodes a stream of byte chunks, yielding one [List<Quad>] per frame.
  @override
  Stream<List<Quad>> bind(Stream<Uint8List> stream) async* {
    final state = JellyDecoderState();
    await for (final chunk in stream) {
      for (final frame in readDelimitedFrames(chunk)) {
        final quads = <Quad>[];
        processFrame(frame, state, onQuad: quads.add);
        yield quads;
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Batch decoders (built on top of frame processing)
// ---------------------------------------------------------------------------

/// Batch decoder that converts Jelly binary data into an [RdfGraph].
///
/// Supports both single-frame (raw protobuf) and multi-frame
/// (varint-delimited) input.
class JellyGraphDecoder extends RdfBinaryGraphDecoder {
  final JellyDecoderOptions _options;

  const JellyGraphDecoder({
    JellyDecoderOptions options = const JellyDecoderOptions(),
  }) : _options = options;

  @override
  RdfGraph convert(Uint8List input) {
    return RdfGraph.fromTriples(const JellyTripleFrameDecoder().convert(input));
  }

  @override
  JellyGraphDecoder withOptions(RdfBinaryDecoderOptions options) =>
      JellyGraphDecoder(
        options: options is JellyDecoderOptions ? options : _options,
      );
}

/// Batch decoder that converts Jelly binary data into an [RdfDataset].
///
/// Supports QUADS and GRAPHS physical stream types.
class JellyDatasetDecoder extends RdfBinaryDatasetDecoder {
  final JellyDecoderOptions _options;

  const JellyDatasetDecoder({
    JellyDecoderOptions options = const JellyDecoderOptions(),
  }) : _options = options;

  @override
  RdfDataset convert(Uint8List input) {
    return RdfDataset.fromQuads(const JellyQuadFrameDecoder().convert(input));
  }

  @override
  JellyDatasetDecoder withOptions(RdfBinaryDecoderOptions options) =>
      JellyDatasetDecoder(
        options: options is JellyDecoderOptions ? options : _options,
      );
}

// ---------------------------------------------------------------------------
// Batch encoders (stub — Phase 4)
// ---------------------------------------------------------------------------

/// Batch encoder that converts an [RdfGraph] to Jelly binary data.
///
/// Encodes all triples into a single varint-delimited frame with an options
/// row, lookup table entries, and triple rows using repeated-term compression.
class JellyGraphEncoder extends RdfBinaryGraphEncoder {
  final JellyEncoderOptions _options;

  const JellyGraphEncoder({
    JellyEncoderOptions options = const JellyEncoderOptions(),
  }) : _options = options;

  @override
  Uint8List convert(RdfGraph graph) {
    final state = JellyEncoderState(
      maxNameTableSize: _options.maxNameTableSize,
      maxPrefixTableSize: _options.maxPrefixTableSize,
      maxDatatypeTableSize: _options.maxDatatypeTableSize,
    );

    final rows = <RdfStreamRow>[
      buildOptionsRow(
          _options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES),
    ];
    for (final triple in graph.triples) {
      rows.addAll(state.emitTriple(triple));
    }

    return _concatBytes(_splitIntoFrames(rows, _options.maxRowsPerFrame));
  }

  @override
  JellyGraphEncoder withOptions(RdfBinaryEncoderOptions options) =>
      JellyGraphEncoder(
        options: options is JellyEncoderOptions ? options : _options,
      );
}

/// Batch encoder that converts an [RdfDataset] to Jelly binary data.
///
/// Encodes all quads into a single varint-delimited frame using the QUADS
/// physical stream type.
class JellyDatasetEncoder extends RdfBinaryDatasetEncoder {
  final JellyEncoderOptions _options;

  const JellyDatasetEncoder({
    JellyEncoderOptions options = const JellyEncoderOptions(),
  }) : _options = options;

  @override
  Uint8List convert(RdfDataset dataset) {
    final state = JellyEncoderState(
      maxNameTableSize: _options.maxNameTableSize,
      maxPrefixTableSize: _options.maxPrefixTableSize,
      maxDatatypeTableSize: _options.maxDatatypeTableSize,
    );

    final rows = <RdfStreamRow>[
      buildOptionsRow(_options, _options.physicalType),
    ];
    if (_options.physicalType ==
        PhysicalStreamType.PHYSICAL_STREAM_TYPE_GRAPHS) {
      _encodeAsGraphs(dataset, state, rows);
    } else {
      _encodeAsQuads(dataset, state, rows);
    }

    return _concatBytes(_splitIntoFrames(rows, _options.maxRowsPerFrame));
  }

  void _encodeAsQuads(
      RdfDataset dataset, JellyEncoderState state, List<RdfStreamRow> rows) {
    for (final quad in dataset.quads) {
      rows.addAll(state.emitQuad(quad));
    }
  }

  void _encodeAsGraphs(
      RdfDataset dataset, JellyEncoderState state, List<RdfStreamRow> rows) {
    // Default graph
    if (dataset.defaultGraph.triples.isNotEmpty) {
      rows.add(RdfStreamRow()..graphStart = state.encodeGraphStart(null));
      for (final triple in dataset.defaultGraph.triples) {
        rows.addAll(state.emitTriple(triple));
      }
      rows.add(RdfStreamRow()..graphEnd = RdfGraphEnd());
    }

    // Named graphs
    for (final namedGraph in dataset.namedGraphs) {
      rows.addAll(state.prepareTerm(namedGraph.name));
      rows.add(
          RdfStreamRow()..graphStart = state.encodeGraphStart(namedGraph.name));
      for (final triple in namedGraph.graph.triples) {
        rows.addAll(state.emitTriple(triple));
      }
      rows.add(RdfStreamRow()..graphEnd = RdfGraphEnd());
    }
  }

  @override
  JellyDatasetEncoder withOptions(RdfBinaryEncoderOptions options) =>
      JellyDatasetEncoder(
        options: options is JellyEncoderOptions ? options : _options,
      );
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Splits [rows] into chunks of at most [maxRowsPerFrame] and serializes each
/// chunk as a varint-delimited frame.
///
/// The options row (always the first element when present) stays in the first
/// frame; subsequent frames carry only data rows.
Iterable<Uint8List> _splitIntoFrames(
    List<RdfStreamRow> rows, int maxRowsPerFrame) sync* {
  final writer = JellyFrameWriter();
  for (var i = 0; i < rows.length; i += maxRowsPerFrame) {
    final end =
        i + maxRowsPerFrame < rows.length ? i + maxRowsPerFrame : rows.length;
    writer.writeFrame(RdfStreamFrame()..rows.addAll(rows.sublist(i, end)));
    yield writer.toBytes();
  }
}

/// Concatenates serialized frame byte chunks into a single [Uint8List].
///
/// Each chunk is already a complete varint-delimited frame; this just flattens
/// the iterable for callers that need a single contiguous buffer.
Uint8List _concatBytes(Iterable<Uint8List> chunks) {
  final out = BytesBuilder(copy: false);
  for (final f in chunks) {
    out.add(f);
  }
  return out.toBytes();
}

List<Triple> _decodeTriplesFromFrames(Iterable<RdfStreamFrame> frames) {
  final state = JellyDecoderState();
  final triples = <Triple>[];
  for (final frame in frames) {
    processFrame(frame, state, onTriple: triples.add);
  }
  return triples;
}

List<Quad> _decodeQuadsFromFrames(Iterable<RdfStreamFrame> frames) {
  final state = JellyDecoderState();
  final quads = <Quad>[];
  for (final frame in frames) {
    processFrame(frame, state, onQuad: quads.add);
  }
  return quads;
}

/// Builds the options row for a Jelly stream frame.
///
/// Only sets fields with non-default values to produce minimal protobuf output
/// (protobuf omits fields set to their default, e.g. 0 for integers).
RdfStreamRow buildOptionsRow(
    JellyEncoderOptions options, PhysicalStreamType physicalType) {
  final opts = RdfStreamOptions()..version = 1;
  if (physicalType != PhysicalStreamType.PHYSICAL_STREAM_TYPE_UNSPECIFIED) {
    opts.physicalType = physicalType;
  }
  if (options.logicalType !=
      LogicalStreamType.LOGICAL_STREAM_TYPE_UNSPECIFIED) {
    opts.logicalType = options.logicalType;
  }
  if (options.maxNameTableSize > 0) {
    opts.maxNameTableSize = options.maxNameTableSize;
  }
  if (options.maxPrefixTableSize > 0) {
    opts.maxPrefixTableSize = options.maxPrefixTableSize;
  }
  if (options.maxDatatypeTableSize > 0) {
    opts.maxDatatypeTableSize = options.maxDatatypeTableSize;
  }
  if (options.streamName != null && options.streamName!.isNotEmpty) {
    opts.streamName = options.streamName!;
  }
  return RdfStreamRow()..options = opts;
}

// ---------------------------------------------------------------------------
// Codec classes (integrate with RdfCore)
// ---------------------------------------------------------------------------

/// MIME type for Jelly RDF.
const jellyMimeType = 'application/x-jelly-rdf';

/// Binary graph codec for the Jelly RDF format.
///
/// Register with [RdfCore] to enable Jelly support:
/// ```dart
/// final rdfCore = RdfCore.withStandardCodecs(
///   additionalBinaryGraphCodecs: [JellyGraphCodec()],
/// );
/// ```
class JellyGraphCodec extends RdfBinaryGraphCodec {
  final JellyDecoderOptions _decoderOptions;
  final JellyEncoderOptions _encoderOptions;

  const JellyGraphCodec({
    JellyDecoderOptions decoderOptions = const JellyDecoderOptions(),
    JellyEncoderOptions encoderOptions = const JellyEncoderOptions(),
  })  : _decoderOptions = decoderOptions,
        _encoderOptions = encoderOptions;

  @override
  String get primaryMimeType => jellyMimeType;

  @override
  Set<String> get supportedMimeTypes => {jellyMimeType};

  @override
  JellyGraphDecoder get decoder => JellyGraphDecoder(options: _decoderOptions);

  @override
  JellyGraphEncoder get encoder => JellyGraphEncoder(options: _encoderOptions);

  @override
  bool canParseBytes(Uint8List content) => _looksLikeJelly(content);

  @override
  JellyGraphCodec withOptions({
    RdfBinaryEncoderOptions? encoder,
    RdfBinaryDecoderOptions? decoder,
  }) =>
      JellyGraphCodec(
        decoderOptions:
            decoder is JellyDecoderOptions ? decoder : _decoderOptions,
        encoderOptions:
            encoder is JellyEncoderOptions ? encoder : _encoderOptions,
      );
}

/// Binary dataset codec for the Jelly RDF format.
///
/// Register with [RdfCore] to enable Jelly dataset support:
/// ```dart
/// final rdfCore = RdfCore.withStandardCodecs(
///   additionalBinaryDatasetCodecs: [JellyDatasetCodec()],
/// );
/// ```
class JellyDatasetCodec extends RdfBinaryDatasetCodec {
  final JellyDecoderOptions _decoderOptions;
  final JellyEncoderOptions _encoderOptions;

  const JellyDatasetCodec({
    JellyDecoderOptions decoderOptions = const JellyDecoderOptions(),
    JellyEncoderOptions encoderOptions = const JellyEncoderOptions(),
  })  : _decoderOptions = decoderOptions,
        _encoderOptions = encoderOptions;

  @override
  String get primaryMimeType => jellyMimeType;

  @override
  Set<String> get supportedMimeTypes => {jellyMimeType};

  @override
  JellyDatasetDecoder get decoder =>
      JellyDatasetDecoder(options: _decoderOptions);

  @override
  JellyDatasetEncoder get encoder =>
      JellyDatasetEncoder(options: _encoderOptions);

  @override
  bool canParseBytes(Uint8List content) => _looksLikeJelly(content);

  @override
  JellyDatasetCodec withOptions({
    RdfBinaryEncoderOptions? encoder,
    RdfBinaryDecoderOptions? decoder,
  }) =>
      JellyDatasetCodec(
        decoderOptions:
            decoder is JellyDecoderOptions ? decoder : _decoderOptions,
        encoderOptions:
            encoder is JellyEncoderOptions ? encoder : _encoderOptions,
      );
}

// ---------------------------------------------------------------------------
// Global convenience instances
// ---------------------------------------------------------------------------

/// Global convenience codec for Jelly RDF graph encoding/decoding.
final jellyGraph = JellyGraphCodec();

/// Global convenience codec for Jelly RDF dataset encoding/decoding.
final jelly = JellyDatasetCodec();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Heuristic check: tries to parse the first few bytes as a varint-delimited
/// protobuf frame. If the varint + frame parse succeeds and the frame has at
/// least one row, we consider it Jelly.
bool _looksLikeJelly(Uint8List content) {
  if (content.isEmpty) return false;
  try {
    // Try reading the first frame
    final frames = readDelimitedFrames(content);
    final first = frames.first;
    return first.rows.isNotEmpty;
  } catch (_) {
    // If varint-delimited fails, try single frame
    try {
      final frame = RdfStreamFrame.fromBuffer(content);
      return frame.rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

/// Parses input bytes as either varint-delimited frames or a single frame.
List<RdfStreamFrame> _parseFrames(Uint8List input) {
  // Try varint-delimited first
  try {
    final frames = readDelimitedFrames(input).toList();
    if (frames.isNotEmpty) return frames;
  } catch (_) {
    // Fall through to single frame
  }

  // Try as a single bare protobuf frame
  try {
    final frame = RdfStreamFrame.fromBuffer(input);
    if (frame.rows.isNotEmpty) return [frame];
  } catch (_) {
    // Neither format worked
  }

  return [];
}
