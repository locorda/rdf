/// Scaling profiler — measures per-triple encode cost at increasing dataset
/// sizes to verify linear scaling behaviour.
///
/// Splits measurement into:
///   Phase A: emitTriple loop (IRI split, lookup, raw proto encoding — all merged
///            in [JellyRawFrameWriter])
///   Phase B: writer.finish() — final frame flush + byte assembly
///   Phase C: Full encode (A + B combined = what [jellyGraph.encode] calls)
///
/// Prints µs/triple for each phase at each size.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/src/jelly_codec.dart';
import 'package:locorda_rdf_jelly/src/jelly_encoder_state.dart';
import 'package:locorda_rdf_jelly/src/jelly_frame_encoder.dart';
import 'package:locorda_rdf_jelly/src/jelly_options.dart';
import 'package:locorda_rdf_jelly/src/proto/rdf.pbenum.dart';
import 'package:path/path.dart' as p;

void main() {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final coreAssets = p.normalize(p.join(
    scriptDir.path,
    '..',
    '..',
    'locorda_rdf_core',
    'test',
    'assets',
    'realworld',
  ));
  final src = File(p.join(coreAssets, 'schema.org.ttl')).readAsStringSync();
  final graph = turtle.decode(src,
      documentUrl: 'https://schema.org/',
      options: TurtleDecoderOptions(
          parsingFlags: {TurtleParsingFlag.allowDigitInLocalName}));

  final allTriples = graph.triples.toList();
  stdout.writeln('Total triples: ${allTriples.length}');
  stdout.writeln();

  const options = JellyEncoderOptions();
  const warmupIters = 3;
  const measureIters = 15;

  final sizes = [100, 500, 1000, 2000, 5000, 10000, allTriples.length];

  // Warm up
  for (var i = 0; i < warmupIters; i++) {
    _fullEncode(allTriples, options);
  }

  // ──────── Table 1: Phase breakdown ────────
  stdout.writeln('=== Phase Breakdown ===');
  stdout.writeln(
      '  Size │  Emit µs/t │ Finish µs/t │ Full µs/t │ Emit ratio │ Full ratio');
  stdout.writeln(
      '───────┼────────────┼─────────────┼───────────┼────────────┼───────────');

  double? baseEmit, baseFull;

  for (final size in sizes) {
    final subset = allTriples.sublist(0, size);

    // Phase A: emitTriple loop only (IRI split, lookup, raw proto encoding)
    var emitTotal = Duration.zero;
    for (var i = 0; i < measureIters; i++) {
      final writer = JellyRawFrameWriter(options.maxRowsPerFrame);
      writer.addOptionsRow(buildStreamOptions(
          options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES));
      final state = JellyEncoderState(
        maxNameTableSize: options.maxNameTableSize,
        maxPrefixTableSize: options.maxPrefixTableSize,
        maxDatatypeTableSize: options.maxDatatypeTableSize,
      );
      final sw = Stopwatch()..start();
      for (final triple in subset) {
        state.emitTriple(triple, writer);
      }
      sw.stop();
      emitTotal += sw.elapsed;
    }
    final emitUs = emitTotal.inMicroseconds / (measureIters * size);

    // Phase B: finish() only (final frame flush + byte assembly)
    // Measure on a pre-filled writer to isolate just the finish cost.
    var finishTotal = Duration.zero;
    for (var i = 0; i < measureIters; i++) {
      final writer = JellyRawFrameWriter(options.maxRowsPerFrame);
      writer.addOptionsRow(buildStreamOptions(
          options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES));
      final state = JellyEncoderState(
        maxNameTableSize: options.maxNameTableSize,
        maxPrefixTableSize: options.maxPrefixTableSize,
        maxDatatypeTableSize: options.maxDatatypeTableSize,
      );
      for (final triple in subset) {
        state.emitTriple(triple, writer);
      }
      final sw = Stopwatch()..start();
      writer.finish();
      sw.stop();
      finishTotal += sw.elapsed;
    }
    final finishUs = finishTotal.inMicroseconds / (measureIters * size);

    // Phase C: Full encode
    var fullTotal = Duration.zero;
    for (var i = 0; i < measureIters; i++) {
      final sw = Stopwatch()..start();
      _fullEncode(subset, options);
      sw.stop();
      fullTotal += sw.elapsed;
    }
    final fullUs = fullTotal.inMicroseconds / (measureIters * size);

    baseEmit ??= emitUs;
    baseFull ??= fullUs;

    stdout.writeln('${size.toString().padLeft(6)} '
        '│ ${emitUs.toStringAsFixed(3).padLeft(10)} '
        '│ ${finishUs.toStringAsFixed(3).padLeft(11)} '
        '│ ${fullUs.toStringAsFixed(3).padLeft(9)} '
        '│ ${(emitUs / baseEmit).toStringAsFixed(2).padLeft(10)}× '
        '│ ${(fullUs / baseFull).toStringAsFixed(2).padLeft(9)}×');
  }

  stdout.writeln();

  // ──────── Table 2: Frame size impact ────────
  stdout.writeln('=== Frame Size Impact ===');
  stdout.writeln('How maxRowsPerFrame affects µs/triple at the largest size.');
  stdout.writeln(
      '  Rows/frame │ Full µs/t │  Ratio');
  stdout.writeln(
      '─────────────┼───────────┼───────');

  const frameSizes = [16, 64, 256, 1024, 4096];
  final largest = allTriples;
  double? baseFrameFull;

  for (final frameSize in frameSizes) {
    final frameOptions = JellyEncoderOptions(maxRowsPerFrame: frameSize);
    var fullTotal = Duration.zero;
    for (var i = 0; i < measureIters; i++) {
      final sw = Stopwatch()..start();
      _fullEncode(largest, frameOptions);
      sw.stop();
      fullTotal += sw.elapsed;
    }
    final fullUs = fullTotal.inMicroseconds / (measureIters * largest.length);
    baseFrameFull ??= fullUs;

    final marker = frameSize == 256 ? ' ← default' : '';
    stdout.writeln('${frameSize.toString().padLeft(12)} '
        '│ ${fullUs.toStringAsFixed(3).padLeft(9)} '
        '│ ${(fullUs / baseFrameFull).toStringAsFixed(2).padLeft(6)}×'
        '$marker');
  }
}

/// Full encode: emitTriple loop + finish().
Uint8List _fullEncode(List<Triple> triples, JellyEncoderOptions options) {
  final writer = JellyRawFrameWriter(options.maxRowsPerFrame);
  writer.addOptionsRow(buildStreamOptions(
      options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES));
  final state = JellyEncoderState(
    maxNameTableSize: options.maxNameTableSize,
    maxPrefixTableSize: options.maxPrefixTableSize,
    maxDatatypeTableSize: options.maxDatatypeTableSize,
  );
  for (final triple in triples) {
    state.emitTriple(triple, writer);
  }
  return writer.finish();
}
