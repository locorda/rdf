/// RDF Codec Performance Benchmark
///
/// Measures encode/decode throughput for every text and binary RDF codec in
/// the locorda_rdf suite across three dataset sizes (tiny / small / large).
/// Results are printed as Markdown tables with latency
/// (ms/op), exact output byte count, and size-relative columns using Turtle
/// (graphs) and TriG (datasets) as baselines.
///
/// Usage:
///
///   dart run bin/codec_benchmark.dart          # prints to stdout
///   dart run bin/codec_benchmark.dart --save   # also writes BENCHMARKS.md
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';
import 'package:locorda_rdf_xml/xml.dart';
import 'package:path/path.dart' as p;

// ─── Configuration ────────────────────────────────────────────────────────────

/// Uncounted warm-up iterations before each measurement phase.
const _warmup = 3;

/// Minimum timed iterations per phase.
const _minIter = 3;

/// Maximum timed iterations per phase (guards against runaway loops on tiny
/// payloads).
const _maxIter = 1000;

/// Target wall-clock time (ms) per measurement phase.
const _targetMs = 3000;

// ─── Result types ─────────────────────────────────────────────────────────────

final class _Timing {
  final double msPerIter;
  final int iterations;

  const _Timing(this.msPerIter, this.iterations);
}

final class _Result {
  final String format;
  final int count; // triples (graph) or quads (dataset)
  final int encodedBytes; // UTF-8 bytes for text; raw bytes for binary
  final _Timing encode;
  final _Timing decode;
  final String? error; // non-null on failure

  const _Result({
    required this.format,
    required this.count,
    required this.encodedBytes,
    required this.encode,
    required this.decode,
  }) : error = null;

  _Result.failed(this.format, String err)
      : count = 0,
        encodedBytes = 0,
        encode = const _Timing(0, 0),
        decode = const _Timing(0, 0),
        error = err;

  bool get failed => error != null;
}

// ─── Measurement helper ───────────────────────────────────────────────────────

/// Runs [fn] until approximately [_targetMs] have elapsed.
///
/// Performs [_warmup] uncounted iterations, probes once to estimate per-
/// iteration cost, then runs an iteration count in [[_minIter]..[_maxIter]].
_Timing _measure(void Function() fn) {
  for (var i = 0; i < _warmup; i++) {
    fn();
  }

  final probe = Stopwatch()..start();
  fn();
  probe.stop();
  final probeMs = probe.elapsedMicroseconds / 1000.0;

  final n = probeMs <= 0
      ? _maxIter
      : (_targetMs / probeMs).round().clamp(_minIter, _maxIter);

  final sw = Stopwatch()..start();
  for (var i = 0; i < n; i++) {
    fn();
  }
  sw.stop();

  return _Timing(sw.elapsedMicroseconds / 1000.0 / n, n);
}

// ─── Per-codec benchmark runners ──────────────────────────────────────────────

_Result _benchGraphText(String label, RdfGraphCodec codec, RdfGraph graph) {
  try {
    String? enc;
    final et = _measure(() => enc = codec.encode(graph));
    final encBytes = utf8.encode(enc!).length;
    final dt = _measure(() => codec.decode(enc!));
    return _Result(
        format: label,
        count: graph.size,
        encodedBytes: encBytes,
        encode: et,
        decode: dt);
  } catch (e, st) {
    stderr.writeln('[$label graph-text] $e\n$st');
    return _Result.failed(label, '$e');
  }
}

_Result _benchGraphBinary(
    String label, RdfBinaryGraphCodec codec, RdfGraph graph) {
  try {
    Uint8List? enc;
    final et = _measure(() => enc = codec.encode(graph));
    final dt = _measure(() => codec.decode(enc!));
    return _Result(
        format: label,
        count: graph.size,
        encodedBytes: enc!.lengthInBytes,
        encode: et,
        decode: dt);
  } catch (e, st) {
    stderr.writeln('[$label graph-binary] $e\n$st');
    return _Result.failed(label, '$e');
  }
}

_Result _benchDatasetText(
    String label, RdfDatasetCodec codec, RdfDataset dataset, int quadCount) {
  try {
    String? enc;
    final et = _measure(() => enc = codec.encode(dataset));
    final encBytes = utf8.encode(enc!).length;
    final dt = _measure(() => codec.decode(enc!));
    return _Result(
        format: label,
        count: quadCount,
        encodedBytes: encBytes,
        encode: et,
        decode: dt);
  } catch (e, st) {
    stderr.writeln('[$label dataset-text] $e\n$st');
    return _Result.failed(label, '$e');
  }
}

_Result _benchDatasetBinary(String label, RdfBinaryDatasetCodec codec,
    RdfDataset dataset, int quadCount) {
  try {
    Uint8List? enc;
    final et = _measure(() => enc = codec.encode(dataset));
    final dt = _measure(() => codec.decode(enc!));
    return _Result(
        format: label,
        count: quadCount,
        encodedBytes: enc!.lengthInBytes,
        encode: et,
        decode: dt);
  } catch (e, st) {
    stderr.writeln('[$label dataset-binary] $e\n$st');
    return _Result.failed(label, '$e');
  }
}

// ─── Formatting helpers ───────────────────────────────────────────────────────

String _fmtMs(double ms) {
  if (ms >= 1000) return '${(ms / 1000).toStringAsFixed(2)} s';
  if (ms >= 10) return '${ms.toStringAsFixed(0)} ms';
  if (ms >= 1) return '${ms.toStringAsFixed(1)} ms';
  return '${(ms * 1000).toStringAsFixed(0)} µs';
}

String _fmtBytes(int bytes) {
  if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '$bytes B';
}

/// Human-readable + exact byte count, e.g. "7 KB (6 914 B)".
String _fmtBytesExact(int bytes) {
  if (bytes == 0) return '—';
  final human = _fmtBytes(bytes);
  if (bytes < 1024) return '$bytes B'; // already exact at B level
  // Format with thin-space thousands separator for readability.
  final s = bytes.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202f');
    buf.write(s[i]);
  }
  return '$human ($buf B)';
}

String _fmtPct(double value, double baseline) {
  if (baseline <= 0 || value <= 0) return '—';
  final pct = (value / baseline * 100).round();
  return '$pct%';
}

String _fmtSizePct(int bytes, int baseline) =>
    baseline <= 0 ? '—' : '${(bytes / baseline * 100).round()}%';

String _fmtCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

// ─── Table rendering ──────────────────────────────────────────────────────────

/// Renders one benchmark section as a GitHub-flavoured Markdown string.
///
/// The first non-failed row is used as the 100% baseline for the relative
/// columns (Size %, Enc %, Dec %).
String _renderTable(String heading, String sourceInfo, List<_Result> results) {
  final buf = StringBuffer();

  buf
    ..writeln()
    ..writeln('## $heading')
    ..writeln()
    ..writeln('Source: $sourceInfo')
    ..writeln();

  final baseline = results.firstWhere((r) => !r.failed,
      orElse: () => _Result.failed('—', ''));

  final blEncMs = baseline.encode.msPerIter;
  final blDecMs = baseline.decode.msPerIter;
  final blBytes = baseline.encodedBytes;

  const widths = [13, 22, 10, 10, 8, 7, 7];
  const headers = [
    'Format',
    'Out size (bytes)',
    'Enc time',
    'Dec time',
    'Size %',
    'Enc %',
    'Dec %',
  ];

  String rowLine(List<String> cells) {
    final padded =
        List.generate(cells.length, (i) => cells[i].padRight(widths[i]));
    return '| ${padded.join(' | ')} |';
  }

  final sep = '| ${widths.map((n) => ':${'-' * (n - 1)}').join(' | ')} |';

  buf
    ..writeln(rowLine(headers))
    ..writeln(sep);

  // Determine best (lowest) values for highlighting.
  final ok = results.where((r) => !r.failed).toList();
  final bestSize = ok.isEmpty
      ? -1
      : ok.map((r) => r.encodedBytes).reduce((a, b) => a < b ? a : b);
  final bestEnc = ok.isEmpty
      ? -1.0
      : ok.map((r) => r.encode.msPerIter).reduce((a, b) => a < b ? a : b);
  final bestDec = ok.isEmpty
      ? -1.0
      : ok.map((r) => r.decode.msPerIter).reduce((a, b) => a < b ? a : b);

  String bold(String s, bool isBest) => isBest ? '**$s**' : s;

  for (final r in results) {
    if (r.failed) {
      buf.writeln(rowLine([r.format, '—', 'ERROR', 'ERROR', '—', '—', '—']));
      final errHead = r.error?.split('\n').first ?? '';
      buf.writeln('> ⚠ **${r.format}**: `$errHead`');
    } else {
      buf.writeln(rowLine([
        r.format,
        bold(_fmtBytesExact(r.encodedBytes), r.encodedBytes == bestSize),
        bold(_fmtMs(r.encode.msPerIter), r.encode.msPerIter == bestEnc),
        bold(_fmtMs(r.decode.msPerIter), r.decode.msPerIter == bestDec),
        bold(_fmtSizePct(r.encodedBytes, blBytes), r.encodedBytes == bestSize),
        bold(_fmtPct(r.encode.msPerIter, blEncMs),
            r.encode.msPerIter == bestEnc),
        bold(_fmtPct(r.decode.msPerIter, blDecMs),
            r.decode.msPerIter == bestDec),
      ]));
    }
  }

  if (!baseline.failed) {
    buf
      ..writeln()
      ..writeln(
        '> Baseline: **${baseline.format}** — '
        'enc ${_fmtMs(blEncMs)}, dec ${_fmtMs(blDecMs)}. '
        'Enc/Dec % < 100% = faster, > 100% = slower.',
      );
  }

  return buf.toString();
}

/// Writes a rendered table to stdout and optionally accumulates it into [out].
void _printTable(
  String heading,
  String sourceInfo,
  List<_Result> results,
  StringBuffer out,
) {
  final s = _renderTable(heading, sourceInfo, results);
  stdout.write(s);
  out.write(s);
}

// ─── Asset helpers ────────────────────────────────────────────────────────────

String _readAsset(String assetPath) {
  final f = File(assetPath);
  if (!f.existsSync()) {
    stderr.writeln('Asset not found: $assetPath');
    exit(1);
  }
  return f.readAsStringSync();
}

// ─── Synthetic tiny dataset ───────────────────────────────────────────────────

/// Builds a tiny synthetic graph with [n] triples using simple IRI terms.
///
/// Uses a fixed vocabulary so prefixes compress well in Turtle/TriG/Jelly,
/// but varied objects to avoid degenerate same-value optimisation.
RdfGraph _tinyGraph(int n) {
  final triples = <Triple>[];
  for (var i = 0; i < n; i++) {
    triples.add(Triple(
      IriTerm('https://example.org/resource/$i'),
      IriTerm('https://schema.org/name'),
      LiteralTerm.string('Item $i'),
    ));
  }
  return RdfGraph.fromTriples(triples);
}

// ─── Version helpers ──────────────────────────────────────────────────────────

/// Reads the `version:` field from a pubspec.yaml adjacent to [packageName].
String _packageVersion(String packageName, String packagesRoot) {
  final f = File(p.join(packagesRoot, packageName, 'pubspec.yaml'));
  if (!f.existsSync()) return '?';
  for (final line in f.readAsLinesSync()) {
    if (line.startsWith('version:')) {
      return line.split(':').last.trim();
    }
  }
  return '?';
}

// ─── Entry point ─────────────────────────────────────────────────────────────

void main(List<String> args) {
  final saveToFile = args.contains('--save');

  // Resolve relative to this script so the benchmark runs from any cwd.
  // Layout: bin/codec_benchmark.dart -> locorda_rdf_benchmark/ -> packages/
  //         -> workspace root -> packages/locorda_rdf_core/test/assets/realworld
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final packagesRoot = p.normalize(p.join(scriptDir.path, '..', '..'));
  final coreAssets = p.normalize(p.join(
    packagesRoot,
    'locorda_rdf_core',
    'test',
    'assets',
    'realworld',
  ));

  final coreVer = _packageVersion('locorda_rdf_core', packagesRoot);
  final jellyVer = _packageVersion('locorda_rdf_jelly', packagesRoot);
  final xmlVer = _packageVersion('locorda_rdf_xml', packagesRoot);
  final dartVer = Platform.version.split(' ').first;

  // Buffer that accumulates the full Markdown output for optional file write.
  final out = StringBuffer();

  void emit(String s) {
    stdout.write(s);
    out.write(s);
  }

  void emitln([String s = '']) => emit('$s\n');

  // ── Header ────────────────────────────────────────────────────────────────

  emitln('# RDF Codec Performance Benchmark');
  emitln();
  emitln('Generated: ${DateTime.now().toIso8601String()}');
  emitln();
  emitln('## Versions');
  emitln();
  emitln('| Package | Version |');
  emitln('| :------ | :------ |');
  emitln('| locorda_rdf_core | $coreVer |');
  emitln('| locorda_rdf_jelly | $jellyVer |');
  emitln('| locorda_rdf_xml | $xmlVer |');
  emitln('| Dart SDK | $dartVer |');
  emitln(
      '| Platform | ${Platform.operatingSystem} (${Platform.operatingSystemVersion.split(' ').take(2).join(' ')}) |');
  emitln();
  emitln('## Column guide');
  emitln();
  emitln(
      '- **Out size (bytes)** — encoded output size: human-readable + exact byte count (UTF-8 bytes for text formats, raw bytes for Jelly binary)');
  emitln('- **Enc/Dec time** — average per-operation latency');
  emitln(
      '- **Size %** — output size relative to baseline format (100% = same size)');
  emitln(
      '- **Enc/Dec %** — encode/decode latency relative to baseline (< 100% = faster)');
  emitln();

  // ── Load & decode source files ────────────────────────────────────────────

  stdout.writeln('Loading test assets from: $coreAssets');
  stdout.writeln();

  final smallSrc = _readAsset(p.join(coreAssets, 'acl.ttl'));
  final largeSrc = _readAsset(p.join(coreAssets, 'schema.org.ttl'));
  final shardSrc =
      _readAsset(p.join(coreAssets, 'shard-mod-md5-1-0-v1_0_0.trig'));

  stdout.writeln('Decoding source assets…');

  final smallGraph =
      turtle.decode(smallSrc, documentUrl: 'https://www.w3.org/ns/auth/acl');
  // schema.org.ttl uses relative IRIs and digit-starting local names.
  final largeGraph = turtle.decode(largeSrc,
      documentUrl: 'https://schema.org/',
      options: TurtleDecoderOptions(
          parsingFlags: {TurtleParsingFlag.allowDigitInLocalName}));
  final largeDataset = trig.decode(shardSrc);
  final smallDataset = RdfDataset.fromDefaultGraph(smallGraph);

  // Synthetic tiny graph (5 triples) and dataset (5 quads).
  const tinyN = 5;
  final tinyGraph = _tinyGraph(tinyN);
  final tinyDataset = RdfDataset.fromDefaultGraph(tinyGraph);

  // Materialise quad counts from sync* generators before the hot loops.
  final tinyQuads = tinyDataset.quads.length;
  final smallQuads = smallDataset.quads.length;
  final largeQuads = largeDataset.quads.length;

  stdout
    ..writeln(
        '  tiny  graph  : ${_fmtCount(tinyGraph.size)} triples (synthetic)')
    ..writeln('  small graph  : ${_fmtCount(smallGraph.size)} triples'
        ' (${_fmtBytes(smallSrc.length)} source)')
    ..writeln('  large graph  : ${_fmtCount(largeGraph.size)} triples'
        ' (${_fmtBytes(largeSrc.length)} source)')
    ..writeln('  tiny  dataset: ${_fmtCount(tinyQuads)} quads (synthetic)')
    ..writeln('  small dataset: ${_fmtCount(smallQuads)} quads')
    ..writeln('  large dataset: ${_fmtCount(largeQuads)} quads'
        ' (${_fmtBytes(shardSrc.length)} source)')
    ..writeln();

  // ── Graph – tiny ──────────────────────────────────────────────────────────

  stdout.writeln('Benchmarking graph codecs (tiny: $tinyN triples)…');
  final tinyGraphResults = [
    _benchGraphText('Turtle', turtle, tinyGraph),
    _benchGraphText('N-Triples', ntriples, tinyGraph),
    _benchGraphText('JSON-LD', jsonldGraph, tinyGraph),
    _benchGraphText('RDF/XML', rdfxml, tinyGraph),
    _benchGraphBinary('Jelly', jellyGraph, tinyGraph),
  ];

  // ── Graph – small ─────────────────────────────────────────────────────────

  stdout.writeln('Benchmarking graph codecs (small: acl.ttl)…');
  final smallGraphResults = [
    _benchGraphText('Turtle', turtle, smallGraph),
    _benchGraphText('N-Triples', ntriples, smallGraph),
    _benchGraphText('JSON-LD', jsonldGraph, smallGraph),
    _benchGraphText('RDF/XML', rdfxml, smallGraph),
    _benchGraphBinary('Jelly', jellyGraph, smallGraph),
  ];

  // ── Graph – large ─────────────────────────────────────────────────────────

  stdout.writeln('Benchmarking graph codecs (large: schema.org.ttl)…');
  final largeGraphResults = [
    _benchGraphText('Turtle', turtle, largeGraph),
    _benchGraphText('N-Triples', ntriples, largeGraph),
    _benchGraphText('JSON-LD', jsonldGraph, largeGraph),
    _benchGraphText('RDF/XML', rdfxml, largeGraph),
    _benchGraphBinary('Jelly', jellyGraph, largeGraph),
  ];

  // ── Dataset – tiny ────────────────────────────────────────────────────────

  stdout.writeln('Benchmarking dataset codecs (tiny: $tinyN quads)…');
  final tinyDatasetResults = [
    _benchDatasetText('TriG', trig, tinyDataset, tinyQuads),
    _benchDatasetText('N-Quads', nquads, tinyDataset, tinyQuads),
    _benchDatasetText('JSON-LD', jsonld, tinyDataset, tinyQuads),
    _benchDatasetBinary('Jelly', jelly, tinyDataset, tinyQuads),
  ];

  // ── Dataset – small ───────────────────────────────────────────────────────

  stdout.writeln('Benchmarking dataset codecs (small: acl.ttl wrapped)…');
  final smallDatasetResults = [
    _benchDatasetText('TriG', trig, smallDataset, smallQuads),
    _benchDatasetText('N-Quads', nquads, smallDataset, smallQuads),
    _benchDatasetText('JSON-LD', jsonld, smallDataset, smallQuads),
    _benchDatasetBinary('Jelly', jelly, smallDataset, smallQuads),
  ];

  // ── Dataset – large ───────────────────────────────────────────────────────

  stdout.writeln('Benchmarking dataset codecs (large: shard.trig)…');
  final largeDatasetResults = [
    _benchDatasetText('TriG', trig, largeDataset, largeQuads),
    _benchDatasetText('N-Quads', nquads, largeDataset, largeQuads),
    _benchDatasetText('JSON-LD', jsonld, largeDataset, largeQuads),
    _benchDatasetBinary('Jelly', jelly, largeDataset, largeQuads),
  ];

  stdout.writeln();

  // ── Markdown tables ───────────────────────────────────────────────────────

  _printTable(
    'Graph Codecs — Tiny ($tinyN triples, synthetic)',
    '$tinyN synthetic triples (schema:name literals)',
    tinyGraphResults,
    out,
  );

  _printTable(
    'Graph Codecs — Small (acl.ttl)',
    'acl.ttl · ${_fmtCount(smallGraph.size)} triples'
        ' · ${_fmtBytes(smallSrc.length)} source',
    smallGraphResults,
    out,
  );

  _printTable(
    'Graph Codecs — Large (schema.org.ttl)',
    'schema.org.ttl · ${_fmtCount(largeGraph.size)} triples'
        ' · ${_fmtBytes(largeSrc.length)} source',
    largeGraphResults,
    out,
  );

  _printTable(
    'Dataset Codecs — Tiny ($tinyN quads, synthetic)',
    '$tinyN synthetic quads (default graph)',
    tinyDatasetResults,
    out,
  );

  _printTable(
    'Dataset Codecs — Small',
    'acl.ttl (wrapped in default graph) · ${_fmtCount(smallQuads)} quads',
    smallDatasetResults,
    out,
  );

  _printTable(
    'Dataset Codecs — Large (shard.trig)',
    'shard-mod-md5.trig · ${_fmtCount(largeQuads)} quads'
        ' · ${_fmtBytes(shardSrc.length)} source',
    largeDatasetResults,
    out,
  );

  emitln();
  emitln('---');
  emitln();
  emitln('*Benchmark run in JIT (dart run). '
      'Results reflect warm JIT throughput, not AOT-compiled production performance.*');

  // ── Optional file output ──────────────────────────────────────────────────

  if (saveToFile) {
    // Place BENCHMARKS.md at the workspace root (two levels above packages/).
    final workspaceRoot = p.normalize(p.join(packagesRoot, '..'));
    final outFile = File(p.join(workspaceRoot, 'BENCHMARKS.md'));
    outFile.writeAsStringSync(out.toString());
    stderr.writeln('\nSaved: ${outFile.path}');
  }
}
