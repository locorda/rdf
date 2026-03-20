/// Scaling profiler — measures per-triple encode cost at increasing dataset
/// sizes to isolate super-linear behaviour.
///
/// Splits measurement into:
///   Phase A: Row emission (emitTriple) only — no serialisation
///   Phase B: Frame serialisation only (re-serialise a pre-built rows list)
///   Phase C: Full encode (A+B combined)
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
import 'package:locorda_rdf_jelly/src/proto/rdf.pb.dart';
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
    _encodeRowsOnly(allTriples, options);
    _serializeRows(_buildRows(allTriples, options), options);
    _fullEncode(allTriples, options);
  }

  // ──────── Table 1: Phase breakdown ────────
  stdout.writeln('=== Phase Breakdown ===');
  stdout.writeln(
      '  Size │  Emit µs/t │  Ser µs/t │ Full µs/t │ Rows/t │ Emit ratio │  Ser ratio │ Full ratio');
  stdout.writeln(
      '───────┼────────────┼───────────┼───────────┼────────┼────────────┼────────────┼───────────');

  double? baseEmit, baseSer, baseFull;

  for (final size in sizes) {
    final subset = allTriples.sublist(0, size);

    // Phase A: Row emission only
    var emitTotal = Duration.zero;
    int rowCount = 0;
    for (var i = 0; i < measureIters; i++) {
      final sw = Stopwatch()..start();
      rowCount = _encodeRowsOnly(subset, options);
      sw.stop();
      emitTotal += sw.elapsed;
    }
    final emitUs = emitTotal.inMicroseconds / (measureIters * size);

    // Phase B: Serialisation only (from pre-built rows)
    final prebuiltRows = _buildRows(subset, options);
    var serTotal = Duration.zero;
    for (var i = 0; i < measureIters; i++) {
      final sw = Stopwatch()..start();
      _serializeRows(prebuiltRows, options);
      sw.stop();
      serTotal += sw.elapsed;
    }
    final serUs = serTotal.inMicroseconds / (measureIters * size);

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
    baseSer ??= serUs;
    baseFull ??= fullUs;

    final rowsPerTriple = rowCount / size;

    stdout.writeln(
        '${size.toString().padLeft(6)} '
        '│ ${emitUs.toStringAsFixed(3).padLeft(10)} '
        '│ ${serUs.toStringAsFixed(3).padLeft(9)} '
        '│ ${fullUs.toStringAsFixed(3).padLeft(9)} '
        '│ ${rowsPerTriple.toStringAsFixed(2).padLeft(6)} '
        '│ ${(emitUs / baseEmit!).toStringAsFixed(2).padLeft(10)}× '
        '│ ${(serUs / baseSer!).toStringAsFixed(2).padLeft(10)}× '
        '│ ${(fullUs / baseFull!).toStringAsFixed(2).padLeft(9)}×');
  }

  stdout.writeln();

  // ──────── Table 2: Emit sub-phases ────────
  stdout.writeln('=== Emit Phase Breakdown ===');
  stdout.writeln(
      '  Size │ Emit µs/t │ Emit+Inc µs/t │ Inc ratio │ Unique IRIs │ Unique BN │ Cache sz');
  stdout.writeln(
      '───────┼───────────┼───────────────┼───────────┼─────────────┼───────────┼─────────');

  double? baseInc;

  for (final size in sizes) {
    final subset = allTriples.sublist(0, size);

    // Measure standard emit
    var emitTotal = Duration.zero;
    for (var i = 0; i < measureIters; i++) {
      final sw = Stopwatch()..start();
      _encodeRowsOnly(subset, options);
      sw.stop();
      emitTotal += sw.elapsed;
    }
    final emitUs = emitTotal.inMicroseconds / (measureIters * size);

    // Measure emit with incremental frame flushing (bounded live set)
    var incTotal = Duration.zero;
    for (var i = 0; i < measureIters; i++) {
      final sw = Stopwatch()..start();
      _encodeIncremental(subset, options);
      sw.stop();
      incTotal += sw.elapsed;
    }
    final incUs = incTotal.inMicroseconds / (measureIters * size);
    baseInc ??= incUs;

    // Count unique IRIs and blank nodes to understand cache pressure
    final uniqueIris = <String>{};
    final uniqueBnodes = <BlankNodeTerm>{};
    for (final t in subset) {
      if (t.subject is IriTerm) uniqueIris.add((t.subject as IriTerm).value);
      if (t.subject is BlankNodeTerm) {
        uniqueBnodes.add(t.subject as BlankNodeTerm);
      }
      if (t.predicate is IriTerm) {
        uniqueIris.add((t.predicate as IriTerm).value);
      }
      if (t.object is IriTerm) uniqueIris.add((t.object as IriTerm).value);
      if (t.object is BlankNodeTerm) {
        uniqueBnodes.add(t.object as BlankNodeTerm);
      }
    }

    stdout.writeln(
        '${size.toString().padLeft(6)} '
        '│ ${emitUs.toStringAsFixed(3).padLeft(9)} '
        '│ ${incUs.toStringAsFixed(3).padLeft(13)} '
        '│ ${(incUs / baseInc!).toStringAsFixed(2).padLeft(9)}× '
        '│ ${uniqueIris.length.toString().padLeft(11)} '
        '│ ${uniqueBnodes.length.toString().padLeft(9)} '
        '│ ${uniqueIris.length.toString().padLeft(7)}');
  }
}

/// Phase A: row emission only — returns row count.
int _encodeRowsOnly(List<Triple> triples, JellyEncoderOptions options) {
  final state = JellyEncoderState(
    maxNameTableSize: options.maxNameTableSize,
    maxPrefixTableSize: options.maxPrefixTableSize,
    maxDatatypeTableSize: options.maxDatatypeTableSize,
  );
  final rows = <RdfStreamRow>[
    buildOptionsRow(options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES),
  ];
  for (final triple in triples) {
    state.emitTriple(triple, rows);
  }
  return rows.length;
}

/// Build rows for Phase B input.
List<RdfStreamRow> _buildRows(
    List<Triple> triples, JellyEncoderOptions options) {
  final state = JellyEncoderState(
    maxNameTableSize: options.maxNameTableSize,
    maxPrefixTableSize: options.maxPrefixTableSize,
    maxDatatypeTableSize: options.maxDatatypeTableSize,
  );
  final rows = <RdfStreamRow>[
    buildOptionsRow(options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES),
  ];
  for (final triple in triples) {
    state.emitTriple(triple, rows);
  }
  return rows;
}

/// Phase B: serialisation only (frame split + protobuf + concat).
Uint8List _serializeRows(
    List<RdfStreamRow> rows, JellyEncoderOptions options) {
  final writer = JellyFrameWriter();
  final out = BytesBuilder(copy: false);
  final maxRows = options.maxRowsPerFrame;
  for (var i = 0; i < rows.length; i += maxRows) {
    final end = i + maxRows < rows.length ? i + maxRows : rows.length;
    final frame = RdfStreamFrame();
    for (var j = i; j < end; j++) {
      frame.rows.add(rows[j]);
    }
    writer.writeFrame(frame);
    out.add(writer.toBytes());
  }
  return out.toBytes();
}

/// Phase C: full encode (identical to JellyGraphEncoder.convert).
Uint8List _fullEncode(List<Triple> triples, JellyEncoderOptions options) {
  final state = JellyEncoderState(
    maxNameTableSize: options.maxNameTableSize,
    maxPrefixTableSize: options.maxPrefixTableSize,
    maxDatatypeTableSize: options.maxDatatypeTableSize,
  );
  final rows = <RdfStreamRow>[
    buildOptionsRow(options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES),
  ];
  for (final triple in triples) {
    state.emitTriple(triple, rows);
  }
  final writer = JellyFrameWriter();
  final out = BytesBuilder(copy: false);
  final maxRows = options.maxRowsPerFrame;
  for (var i = 0; i < rows.length; i += maxRows) {
    final end = i + maxRows < rows.length ? i + maxRows : rows.length;
    final frame = RdfStreamFrame();
    for (var j = i; j < end; j++) {
      frame.rows.add(rows[j]);
    }
    writer.writeFrame(frame);
    out.add(writer.toBytes());
  }
  return out.toBytes();
}

/// Incremental encode — serialise each frame's worth of rows eagerly,
/// bounding protobuf live set to O(maxRowsPerFrame) instead of O(totalRows).
Uint8List _encodeIncremental(
    List<Triple> triples, JellyEncoderOptions options) {
  final state = JellyEncoderState(
    maxNameTableSize: options.maxNameTableSize,
    maxPrefixTableSize: options.maxPrefixTableSize,
    maxDatatypeTableSize: options.maxDatatypeTableSize,
  );
  final writer = JellyFrameWriter();
  final out = BytesBuilder(copy: false);
  final maxRows = options.maxRowsPerFrame;
  var rows = <RdfStreamRow>[
    buildOptionsRow(options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES),
  ];

  for (final triple in triples) {
    state.emitTriple(triple, rows);
    // Eagerly flush complete frames
    while (rows.length >= maxRows) {
      final frame = RdfStreamFrame();
      for (var j = 0; j < maxRows; j++) {
        frame.rows.add(rows[j]);
      }
      writer.writeFrame(frame);
      out.add(writer.toBytes());
      rows = rows.length > maxRows ? rows.sublist(maxRows) : <RdfStreamRow>[];
    }
  }

  // Final partial frame
  if (rows.isNotEmpty) {
    final frame = RdfStreamFrame();
    for (final row in rows) {
      frame.rows.add(row);
    }
    writer.writeFrame(frame);
    out.add(writer.toBytes());
  }

  return out.toBytes();
}
