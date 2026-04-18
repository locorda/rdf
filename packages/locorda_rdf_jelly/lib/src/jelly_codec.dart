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
import 'jelly_raw_frame_parser.dart';
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
  static final _defaultOptions = JellyEncoderOptions();
  final JellyEncoderOptions _options;

  JellyTripleFrameEncoder({JellyEncoderOptions? options})
      : _options = options ?? _defaultOptions;

  /// Encodes [input] as a self-contained Jelly stream with a fresh state.
  @override
  Uint8List convert(Iterable<Triple> input) {
    final state = JellyEncoderState(
      maxNameTableSize: _options.maxNameTableSize,
      maxPrefixTableSize: _options.maxPrefixTableSize,
      maxDatatypeTableSize: _options.maxDatatypeTableSize,
    );
    final writer = JellyRawFrameWriter(_options.maxRowsPerFrame);
    writer.addOptionsRow(buildStreamOptions(
        _options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES));
    for (final triple in input) {
      state.emitTriple(triple, writer);
    }
    return writer.finish();
  }

  /// Encodes a stream of batches sharing lookup-table state across all frames.
  @override
  Stream<Uint8List> bind(Stream<Iterable<Triple>> stream) async* {
    final state = JellyEncoderState(
      maxNameTableSize: _options.maxNameTableSize,
      maxPrefixTableSize: _options.maxPrefixTableSize,
      maxDatatypeTableSize: _options.maxDatatypeTableSize,
    );
    final writer = JellyRawFrameWriter(_options.maxRowsPerFrame);
    bool firstBatch = true;
    await for (final triples in stream) {
      if (firstBatch) {
        writer.addOptionsRow(buildStreamOptions(
            _options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES));
        firstBatch = false;
      }
      for (final triple in triples) {
        state.emitTriple(triple, writer);
      }
      for (final frameBytes in writer.drainFrames()) {
        yield frameBytes;
      }
    }
    // Flush remaining rows
    for (final frameBytes in writer.drainFrames()) {
      yield frameBytes;
    }
    final remaining = writer.finish();
    if (remaining.isNotEmpty) yield remaining;
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
  static final _defaultOptions = JellyEncoderOptions(
    physicalType: PhysicalStreamType.PHYSICAL_STREAM_TYPE_QUADS,
  );
  final JellyEncoderOptions _options;

  JellyQuadFrameEncoder({JellyEncoderOptions? options})
      : _options = options ?? _defaultOptions;

  /// Encodes [input] as a self-contained Jelly stream with a fresh state.
  @override
  Uint8List convert(Iterable<Quad> input) {
    final state = JellyEncoderState(
      maxNameTableSize: _options.maxNameTableSize,
      maxPrefixTableSize: _options.maxPrefixTableSize,
      maxDatatypeTableSize: _options.maxDatatypeTableSize,
    );
    final writer = JellyRawFrameWriter(_options.maxRowsPerFrame);
    writer.addOptionsRow(buildStreamOptions(_options, _options.physicalType));
    for (final quad in input) {
      state.emitQuad(quad, writer);
    }
    return writer.finish();
  }

  /// Encodes a stream of batches sharing lookup-table state across all frames.
  @override
  Stream<Uint8List> bind(Stream<Iterable<Quad>> stream) async* {
    final state = JellyEncoderState(
      maxNameTableSize: _options.maxNameTableSize,
      maxPrefixTableSize: _options.maxPrefixTableSize,
      maxDatatypeTableSize: _options.maxDatatypeTableSize,
    );
    final writer = JellyRawFrameWriter(_options.maxRowsPerFrame);
    bool firstBatch = true;
    await for (final quads in stream) {
      if (firstBatch) {
        writer
            .addOptionsRow(buildStreamOptions(_options, _options.physicalType));
        firstBatch = false;
      }
      for (final quad in quads) {
        state.emitQuad(quad, writer);
      }
      for (final frameBytes in writer.drainFrames()) {
        yield frameBytes;
      }
    }
    final remaining = writer.finish();
    if (remaining.isNotEmpty) yield remaining;
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
    return _decodeTriplesFromBytes(input);
  }

  /// Decodes a stream of byte chunks, yielding one [List<Triple>] per frame.
  @override
  Stream<List<Triple>> bind(Stream<Uint8List> stream) async* {
    final state = JellyDecoderState();
    await for (final chunk in stream) {
      final triples = <Triple>[];
      processRawDelimitedFrames(chunk, state, onTriple: triples.add);
      // Yield the whole chunk's triples — one list per bind() invocation.
      if (triples.isNotEmpty) yield triples;
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
    return _decodeQuadsFromBytes(input);
  }

  /// Decodes a stream of byte chunks, yielding one [List<Quad>] per frame.
  @override
  Stream<List<Quad>> bind(Stream<Uint8List> stream) async* {
    final state = JellyDecoderState();
    await for (final chunk in stream) {
      final quads = <Quad>[];
      processRawDelimitedFrames(chunk, state, onQuad: quads.add);
      if (quads.isNotEmpty) yield quads;
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
  static final _defaultOptions = JellyEncoderOptions();
  final JellyEncoderOptions _options;

  JellyGraphEncoder({JellyEncoderOptions? options})
      : _options = options ?? _defaultOptions;

  @override
  Uint8List convert(RdfGraph graph) {
    final state = JellyEncoderState(
      maxNameTableSize: _options.maxNameTableSize,
      maxPrefixTableSize: _options.maxPrefixTableSize,
      maxDatatypeTableSize: _options.maxDatatypeTableSize,
    );
    final writer = JellyRawFrameWriter(_options.maxRowsPerFrame);
    writer.addOptionsRow(buildStreamOptions(
        _options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES));
    for (final triple in graph.triples) {
      state.emitTriple(triple, writer);
    }
    return writer.finish();
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
  static final _defaultOptions = JellyEncoderOptions(
    physicalType: PhysicalStreamType.PHYSICAL_STREAM_TYPE_QUADS,
  );
  final JellyEncoderOptions _options;

  JellyDatasetEncoder({JellyEncoderOptions? options})
      : _options = options ?? _defaultOptions;

  @override
  Uint8List convert(RdfDataset dataset) {
    final state = JellyEncoderState(
      maxNameTableSize: _options.maxNameTableSize,
      maxPrefixTableSize: _options.maxPrefixTableSize,
      maxDatatypeTableSize: _options.maxDatatypeTableSize,
    );
    final writer = JellyRawFrameWriter(_options.maxRowsPerFrame);
    writer.addOptionsRow(buildStreamOptions(_options, _options.physicalType));
    if (_options.physicalType ==
        PhysicalStreamType.PHYSICAL_STREAM_TYPE_GRAPHS) {
      _encodeAsGraphs(dataset, state, writer);
    } else {
      _encodeAsQuads(dataset, state, writer);
    }
    return writer.finish();
  }

  void _encodeAsQuads(
      RdfDataset dataset, JellyEncoderState state, JellyRawFrameWriter writer) {
    for (final quad in dataset.quads) {
      state.emitQuad(quad, writer);
    }
  }

  void _encodeAsGraphs(
      RdfDataset dataset, JellyEncoderState state, JellyRawFrameWriter writer) {
    // Default graph
    if (dataset.defaultGraph.triples.isNotEmpty) {
      writer.addGraphStartRow(state.encodeGraphStart(null));
      for (final triple in dataset.defaultGraph.triples) {
        state.emitTriple(triple, writer);
      }
      writer.addGraphEndRow();
    }

    // Named graphs
    for (final namedGraph in dataset.namedGraphs) {
      state.emitTermEntries(namedGraph.name, writer);
      writer.addGraphStartRow(state.encodeGraphStart(namedGraph.name));
      for (final triple in namedGraph.graph.triples) {
        state.emitTriple(triple, writer);
      }
      writer.addGraphEndRow();
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

List<Triple> _decodeTriplesFromBytes(Uint8List input) {
  final state = JellyDecoderState();
  final triples = <Triple>[];
  try {
    processRawDelimitedFrames(input, state, onTriple: triples.add);
    return triples;
  } on RdfDecoderException {
    rethrow;
  } catch (_) {
    // Structural failure (e.g. RangeError): likely a non-delimited raw-proto
    // file. Reset state and try parsing the whole input as a single frame.
  }
  final state2 = JellyDecoderState();
  parseFrame(input, state2, onTriple: triples.add);
  return triples;
}

List<Quad> _decodeQuadsFromBytes(Uint8List input) {
  final state = JellyDecoderState();
  final quads = <Quad>[];
  try {
    processRawDelimitedFrames(input, state, onQuad: quads.add);
    return quads;
  } on RdfDecoderException {
    rethrow;
  } catch (_) {
    // Structural failure: likely a non-delimited raw-proto file.
  }
  final state2 = JellyDecoderState();
  parseFrame(input, state2, onQuad: quads.add);
  return quads;
}

/// Builds the stream options protobuf for a Jelly stream.
///
/// Only sets fields with non-default values to produce minimal protobuf output
/// (protobuf omits fields set to their default, e.g. 0 for integers).
RdfStreamOptions buildStreamOptions(
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
  return opts;
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

  static final _defaultEncoderOptions = JellyEncoderOptions();

  JellyGraphCodec({
    JellyDecoderOptions decoderOptions = const JellyDecoderOptions(),
    JellyEncoderOptions? encoderOptions,
  })  : _decoderOptions = decoderOptions,
        _encoderOptions = encoderOptions ?? _defaultEncoderOptions;

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

  static final _defaultEncoderOptions = JellyEncoderOptions(
    physicalType: PhysicalStreamType.PHYSICAL_STREAM_TYPE_QUADS,
  );

  JellyDatasetCodec({
    JellyDecoderOptions decoderOptions = const JellyDecoderOptions(),
    JellyEncoderOptions? encoderOptions,
  })  : _decoderOptions = decoderOptions,
        _encoderOptions = encoderOptions ?? _defaultEncoderOptions;

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
    final frames = readDelimitedFrames(content);
    final first = frames.first;
    return first.rows.isNotEmpty;
  } catch (_) {
    try {
      final frame = RdfStreamFrame.fromBuffer(content);
      return frame.rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
