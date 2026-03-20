/// Isolates protobuf object-creation cost from the rest of the Jelly encode
/// pipeline.
///
/// Phases:
///   1. Full encode (baseline)
///   2. Row emission only (encoder state + protobuf object creation, no serialization)
///   3. Pure protobuf object creation (same types & quantities as encode, no logic)
///   4. Pure serialization (pre-built frames → writeToBuffer + concat)
///   5. Encoder logic only (prepare + encode, but discard the result list)
///
/// This allows us to see definitively what fraction of time is spent in
/// GeneratedMessage allocation vs. encoder logic vs. protobuf serialization.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';
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

  stdout.writeln('Graph: ${graph.size} triples');
  stdout.writeln();

  const options = JellyEncoderOptions();
  const iters = 30;
  const warmup = 10;

  // ── Step 0: Instrumented encode to count object allocations ──────────────

  final counts = _countAllocations(graph, options);
  stdout.writeln('Object counts per encode:');
  stdout.writeln('  RdfStreamRow (total)    ${counts.streamRows}');
  stdout.writeln('  RdfTriple               ${counts.triples}');
  stdout.writeln('  RdfIri                  ${counts.iris}');
  stdout.writeln('  RdfLiteral              ${counts.literals}');
  stdout.writeln('  RdfNameEntry            ${counts.nameEntries}');
  stdout.writeln('  RdfPrefixEntry          ${counts.prefixEntries}');
  stdout.writeln('  RdfDatatypeEntry        ${counts.datatypeEntries}');
  stdout.writeln('  RdfStreamFrame          ${counts.frames}');
  stdout
      .writeln('  ──────────────────────────────────────────────────────────');
  stdout.writeln('  Total GeneratedMessage  ${counts.total}');
  stdout.writeln();

  // ── Warm up ──────────────────────────────────────────────────────────────

  for (var i = 0; i < warmup; i++) {
    jellyGraph.encode(graph);
    _createProtobufObjects(counts);
    _serializePrebuiltRows(graph, options);
  }

  // ── Phase 1: Full encode ─────────────────────────────────────────────────

  final phase1 = _benchmark(iters, () => jellyGraph.encode(graph));

  // ── Phase 2: Row emission only (state + proto objects, no serialization) ─

  final phase2 = _benchmark(iters, () {
    final state = JellyEncoderState(
      maxNameTableSize: options.maxNameTableSize,
      maxPrefixTableSize: options.maxPrefixTableSize,
      maxDatatypeTableSize: options.maxDatatypeTableSize,
    );
    final rows = <RdfStreamRow>[
      buildOptionsRow(options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES),
    ];
    for (final triple in graph.triples) {
      state.emitTriple(triple, rows);
    }
    return rows.length; // prevent dead-code elimination
  });

  // ── Phase 3: Pure protobuf object creation (no encoder logic) ────────────

  final phase3 = _benchmark(iters, () => _createProtobufObjects(counts));

  // ── Phase 4: Serialization only (pre-built rows → bytes) ─────────────────

  // Pre-build the rows once
  final prebuiltRows = _buildRows(graph, options);
  final phase4 = _benchmark(iters, () {
    final writer = JellyFrameWriter();
    final out = BytesBuilder(copy: false);
    for (var i = 0; i < prebuiltRows.length; i += options.maxRowsPerFrame) {
      final end = i + options.maxRowsPerFrame < prebuiltRows.length
          ? i + options.maxRowsPerFrame
          : prebuiltRows.length;
      final frame = RdfStreamFrame();
      for (var j = i; j < end; j++) {
        frame.rows.add(prebuiltRows[j]);
      }
      writer.writeFrame(frame);
      out.add(writer.toBytes());
    }
    return out.toBytes().length; // prevent DCE
  });

  // ── Phase 5: Serialization without frame re-assembly ─────────────────────
  // Pre-build frames, measure just writeToBuffer + concat

  final prebuiltFrames = <RdfStreamFrame>[];
  for (var i = 0; i < prebuiltRows.length; i += options.maxRowsPerFrame) {
    final end = i + options.maxRowsPerFrame < prebuiltRows.length
        ? i + options.maxRowsPerFrame
        : prebuiltRows.length;
    final frame = RdfStreamFrame();
    for (var j = i; j < end; j++) {
      frame.rows.add(prebuiltRows[j]);
    }
    prebuiltFrames.add(frame);
  }

  final phase5 = _benchmark(iters, () {
    final writer = JellyFrameWriter();
    final out = BytesBuilder(copy: false);
    for (final frame in prebuiltFrames) {
      writer.writeFrame(frame);
      out.add(writer.toBytes());
    }
    return out.toBytes().length; // prevent DCE
  });

  // ── Phase 6: Triple iteration + equality checks only ─────────────────────

  final phase6 = _benchmark(iters, () {
    RdfSubject? lastS;
    RdfPredicate? lastP;
    RdfObject? lastO;
    var changed = 0;
    for (final triple in graph.triples) {
      if (triple.subject != lastS) {
        lastS = triple.subject;
        changed++;
      }
      if (triple.predicate != lastP) {
        lastP = triple.predicate;
        changed++;
      }
      if (triple.object != lastO) {
        lastO = triple.object;
        changed++;
      }
    }
    return changed; // prevent DCE
  });

  // ── Results ──────────────────────────────────────────────────────────────

  stdout.writeln('Timing ($iters iterations, median):');
  stdout.writeln();
  _report('Phase 1: Full encode (baseline)', phase1);
  _report('Phase 2: Row emission only (state + proto)', phase2);
  _report('Phase 3: Pure protobuf object creation', phase3);
  _report('Phase 4: Serialization (re-add rows to frames)', phase4);
  _report('Phase 5: Serialization (pre-built frames)', phase5);
  _report('Phase 6: Triple iteration + equality only', phase6);
  stdout.writeln();
  stdout.writeln('Derived breakdown (as % of full encode):');
  final fullMs = phase1.inMicroseconds / 1000;
  _pct('  Proto object creation', phase3, fullMs);
  _pct('  Pure serialization (pre-built frames)', phase5, fullMs);
  _pct('  Row emission (state logic + proto)', phase2, fullMs);
  _pct('  Triple iteration + equality', phase6, fullMs);
  final logicMs = phase2.inMicroseconds / 1000 - phase3.inMicroseconds / 1000;
  stdout.writeln('  ${'Encoder state logic (row emit - proto)'.padRight(50)} '
      '${logicMs.toStringAsFixed(2).padLeft(8)} ms  '
      '(${(logicMs / fullMs * 100).toStringAsFixed(0)}%)');
  final serializationMs =
      phase1.inMicroseconds / 1000 - phase2.inMicroseconds / 1000;
  stdout.writeln('  ${'Serialization overhead (full - row emit)'.padRight(50)} '
      '${serializationMs.toStringAsFixed(2).padLeft(8)} ms  '
      '(${(serializationMs / fullMs * 100).toStringAsFixed(0)}%)');
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════════════════

/// Runs [fn] [iters] times, returns the median duration.
Duration _benchmark(int iters, Object? Function() fn) {
  final durations = <Duration>[];
  for (var i = 0; i < iters; i++) {
    final sw = Stopwatch()..start();
    fn();
    sw.stop();
    durations.add(sw.elapsed);
  }
  durations.sort();
  return durations[durations.length ~/ 2];
}

void _report(String label, Duration d) {
  final ms = d.inMicroseconds / 1000;
  stdout.writeln(
      '  ${label.padRight(50)} ${ms.toStringAsFixed(2).padLeft(8)} ms');
}

void _pct(String label, Duration d, double fullMs) {
  final ms = d.inMicroseconds / 1000;
  stdout.writeln(
      '  ${label.padRight(50)} ${ms.toStringAsFixed(2).padLeft(8)} ms  '
      '(${(ms / fullMs * 100).toStringAsFixed(0)}%)');
}

// ─ Allocation counting ─────────────────────────────────────────────────────

class _AllocationCounts {
  int streamRows = 0;
  int triples = 0;
  int iris = 0;
  int literals = 0;
  int nameEntries = 0;
  int prefixEntries = 0;
  int datatypeEntries = 0;
  int frames = 0;

  int get total =>
      streamRows +
      triples +
      iris +
      literals +
      nameEntries +
      prefixEntries +
      datatypeEntries +
      frames;
}

/// Runs a full encode and counts how many protobuf objects of each type are
/// created by inspecting the row list.
_AllocationCounts _countAllocations(
    RdfGraph graph, JellyEncoderOptions options) {
  final state = JellyEncoderState(
    maxNameTableSize: options.maxNameTableSize,
    maxPrefixTableSize: options.maxPrefixTableSize,
    maxDatatypeTableSize: options.maxDatatypeTableSize,
  );
  final rows = <RdfStreamRow>[
    buildOptionsRow(options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES),
  ];
  for (final triple in graph.triples) {
    state.emitTriple(triple, rows);
  }

  final counts = _AllocationCounts();
  counts.streamRows = rows.length; // every row is an RdfStreamRow

  for (final row in rows) {
    switch (row.whichRow()) {
      case RdfStreamRow_Row.triple:
        counts.triples++;
        final t = row.triple;
        if (t.hasSIri()) counts.iris++;
        if (t.hasPIri()) counts.iris++;
        if (t.hasOIri()) counts.iris++;
        if (t.hasOLiteral()) counts.literals++;
      // sLiteral/sBnode/pBnode/oBnode don't create sub-messages we track
      case RdfStreamRow_Row.name:
        counts.nameEntries++;
      case RdfStreamRow_Row.prefix:
        counts.prefixEntries++;
      case RdfStreamRow_Row.datatype:
        counts.datatypeEntries++;
      case RdfStreamRow_Row.options:
        break; // one options row, minor
      default:
        break;
    }
  }

  // Count frames
  counts.frames =
      (rows.length + options.maxRowsPerFrame - 1) ~/ options.maxRowsPerFrame;

  return counts;
}

/// Creates exactly the same quantity & types of protobuf objects as a real
/// encode, but without any encoder logic. Measures pure GeneratedMessage
/// allocation cost.
int _createProtobufObjects(_AllocationCounts c) {
  var sink = 0; // prevent dead-code elimination

  // Simulate RdfStreamRow + RdfTriple + RdfIri/RdfLiteral for triple rows
  for (var i = 0; i < c.triples; i++) {
    final row = RdfStreamRow();
    final triple = RdfTriple();
    // Average case: ~1-2 IRIs per triple (due to repeated-term compression).
    // We create the exact measured count spread across triples.
    row.triple = triple;
    sink += row.hashCode;
  }

  // Create the measured number of RdfIri objects
  for (var i = 0; i < c.iris; i++) {
    final iri = RdfIri();
    sink += iri.hashCode;
  }

  // Create the measured number of RdfLiteral objects
  for (var i = 0; i < c.literals; i++) {
    final lit = RdfLiteral();
    sink += lit.hashCode;
  }

  // Table entry rows: RdfStreamRow + RdfNameEntry/RdfPrefixEntry/RdfDatatypeEntry
  for (var i = 0; i < c.nameEntries; i++) {
    final row = RdfStreamRow();
    final entry = RdfNameEntry();
    row.name = entry;
    sink += row.hashCode;
  }
  for (var i = 0; i < c.prefixEntries; i++) {
    final row = RdfStreamRow();
    final entry = RdfPrefixEntry();
    row.prefix = entry;
    sink += row.hashCode;
  }
  for (var i = 0; i < c.datatypeEntries; i++) {
    final row = RdfStreamRow();
    final entry = RdfDatatypeEntry();
    row.datatype = entry;
    sink += row.hashCode;
  }

  // Frame objects
  for (var i = 0; i < c.frames; i++) {
    final frame = RdfStreamFrame();
    sink += frame.hashCode;
  }

  return sink;
}

/// Pre-builds the full row list for serialization testing.
List<RdfStreamRow> _buildRows(RdfGraph graph, JellyEncoderOptions options) {
  final state = JellyEncoderState(
    maxNameTableSize: options.maxNameTableSize,
    maxPrefixTableSize: options.maxPrefixTableSize,
    maxDatatypeTableSize: options.maxDatatypeTableSize,
  );
  final rows = <RdfStreamRow>[
    buildOptionsRow(options, PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES),
  ];
  for (final triple in graph.triples) {
    state.emitTriple(triple, rows);
  }
  return rows;
}

/// Pre-builds rows and serializes them.
int _serializePrebuiltRows(RdfGraph graph, JellyEncoderOptions options) {
  final rows = _buildRows(graph, options);
  final writer = JellyFrameWriter();
  final out = BytesBuilder(copy: false);
  for (var i = 0; i < rows.length; i += options.maxRowsPerFrame) {
    final end = i + options.maxRowsPerFrame < rows.length
        ? i + options.maxRowsPerFrame
        : rows.length;
    final frame = RdfStreamFrame();
    for (var j = i; j < end; j++) {
      frame.rows.add(rows[j]);
    }
    writer.writeFrame(frame);
    out.add(writer.toBytes());
  }
  return out.toBytes().length;
}
