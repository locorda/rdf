/// Quick profiling script to identify where time is spent in Jelly encoding.
///
/// Splits the JellyGraphEncoder.convert() flow into measured phases:
///   Phase 1: emitTriple loop (IRI splitting, lookup tables, raw proto encoding,
///            frame buffering — all now merged in [JellyRawFrameWriter])
///   Phase 2: writer.finish() (final frame flush + byte assembly)
library;

import 'dart:io';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';
import 'package:locorda_rdf_jelly/src/jelly_codec.dart';
import 'package:locorda_rdf_jelly/src/jelly_encoder_state.dart';
import 'package:locorda_rdf_jelly/src/jelly_frame_encoder.dart';
import 'package:locorda_rdf_jelly/src/proto/rdf.pbenum.dart';
import 'package:path/path.dart' as p;

void main() {
  // Load schema.org graph (same as benchmark)
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

  stdout.writeln('Graph: ${graph.size} triples');
  stdout.writeln();

  const options = JellyEncoderOptions();
  const iters = 20;
  const warmup = 5;

  // Warm up all code paths
  for (var i = 0; i < warmup; i++) {
    jellyGraph.encode(graph);
  }

  // ---------- Phase-by-phase timing ----------

  var totalEmit = Duration.zero;
  var totalFinish = Duration.zero;
  var totalFull = Duration.zero;

  for (var i = 0; i < iters; i++) {
    final fullStart = Stopwatch()..start();

    // Phase 1: emitTriple loop (IRI split, lookup, raw proto encoding, frame buffering)
    final writer = JellyRawFrameWriter(options.maxRowsPerFrame);
    writer.addOptionsRow(buildStreamOptions(
        options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES));
    final state = JellyEncoderState(
      maxNameTableSize: options.maxNameTableSize,
      maxPrefixTableSize: options.maxPrefixTableSize,
      maxDatatypeTableSize: options.maxDatatypeTableSize,
    );
    final sw1 = Stopwatch()..start();
    for (final triple in graph.triples) {
      state.emitTriple(triple, writer);
    }
    sw1.stop();
    totalEmit += sw1.elapsed;

    // Phase 2: Final frame flush + byte assembly
    final sw2 = Stopwatch()..start();
    writer.finish();
    sw2.stop();
    totalFinish += sw2.elapsed;

    fullStart.stop();
    totalFull += fullStart.elapsed;
  }

  stdout
      .writeln('Over $iters iterations (${graph.size} triples per iteration):');
  stdout.writeln();
  _report('Phase 1: emitTriple loop (IRI split, lookup, raw encode)', totalEmit,
      iters);
  _report('Phase 2: writer.finish() (final flush + byte assembly)', totalFinish,
      iters);
  stdout.writeln('  ─────────────────────────────────────────────');
  _report('Total (sum of phases)', totalEmit + totalFinish, iters);
  _report('Total (wall clock)', totalFull, iters);
  stdout.writeln();

  // Now measure sub-parts of Phase 1
  stdout.writeln('--- Phase 1 breakdown ---');
  stdout.writeln();

  // 1a: Just triple iteration (graph.triples overhead)
  var iterTime = Duration.zero;
  for (var i = 0; i < iters; i++) {
    final sw = Stopwatch()..start();
    for (final _ in graph.triples) {}
    sw.stop();
    iterTime += sw.elapsed;
  }
  _report('1a: graph.triples iteration only', iterTime, iters);

  // 1b: IRI splitting only (no table, no encoding)
  var splitTime = Duration.zero;
  for (var i = 0; i < iters; i++) {
    final sw = Stopwatch()..start();
    for (final triple in graph.triples) {
      if (triple.subject is IriTerm) {
        _splitIri((triple.subject as IriTerm).value);
      }
      if (triple.predicate is IriTerm) {
        _splitIri((triple.predicate as IriTerm).value);
      }
      if (triple.object is IriTerm) {
        _splitIri((triple.object as IriTerm).value);
      }
    }
    sw.stop();
    splitTime += sw.elapsed;
  }
  _report('1b: IRI splitting (_splitIri) per triple', splitTime, iters);

  // 1c: Full emitTriple with raw writer
  var emitTime = Duration.zero;
  for (var i = 0; i < iters; i++) {
    final state = JellyEncoderState(
      maxNameTableSize: options.maxNameTableSize,
      maxPrefixTableSize: options.maxPrefixTableSize,
      maxDatatypeTableSize: options.maxDatatypeTableSize,
    );
    final writer = JellyRawFrameWriter(options.maxRowsPerFrame);
    writer.addOptionsRow(buildStreamOptions(
        options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES));
    final sw = Stopwatch()..start();
    for (final triple in graph.triples) {
      state.emitTriple(triple, writer);
    }
    sw.stop();
    emitTime += sw.elapsed;
  }
  _report('1c: emitTriple (raw proto encode)', emitTime, iters);
  stdout.writeln();

  // Derived: table + encode overhead = 1c - 1b (approx)
  final tableOverhead = (emitTime - splitTime);
  _report(
      '    → table mgmt + raw encode overhead (1c - 1b)', tableOverhead, iters);

  stdout.writeln();

  // Measure Turtle encode for reference
  var turtleTime = Duration.zero;
  for (var i = 0; i < iters; i++) {
    final sw = Stopwatch()..start();
    turtle.encode(graph);
    sw.stop();
    turtleTime += sw.elapsed;
  }
  _report('Turtle encode (reference)', turtleTime, iters);
}

(String, String) _splitIri(String iri) {
  var splitIdx = iri.lastIndexOf('#');
  if (splitIdx >= 0) {
    return (iri.substring(0, splitIdx + 1), iri.substring(splitIdx + 1));
  }
  splitIdx = iri.lastIndexOf('/');
  if (splitIdx >= 0) {
    return (iri.substring(0, splitIdx + 1), iri.substring(splitIdx + 1));
  }
  return ('', iri);
}

void _report(String label, Duration total, int iters) {
  final avgMs = total.inMicroseconds / iters / 1000;
  stdout.writeln(
      '  ${label.padRight(52)} ${avgMs.toStringAsFixed(2).padLeft(8)} ms');
}
