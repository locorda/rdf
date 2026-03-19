/// Jelly to_jelly conformance test suite.
///
/// Runs the official Jelly-RDF conformance tests for encoding RDF data
/// into .jelly binary format and comparing against expected output.
///
/// For single-input test cases the batch encoder ([JellyGraphEncoder] /
/// [JellyDatasetEncoder]) is used. For multi-input test cases each input file
/// is treated as one logical frame and fed through the frame-level streaming
/// encoder ([JellyTripleFrameEncoder] / [JellyQuadFrameEncoder]) so that
/// cross-frame lookup-table sharing is exercised. Comparison is always
/// holistic (RDF isomorphism), since frame boundaries need not match exactly.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:locorda_rdf_canonicalization/canonicalization.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';
import 'package:locorda_rdf_jelly/src/jelly_frame_decoder.dart';
import 'package:locorda_rdf_jelly/src/proto/rdf.pb.dart';
import 'package:test/test.dart';

import '../jelly_manifest_parser.dart';

void main() {
  final manifestPath =
      '../../test_assets/jelly/jelly-protobuf/test/rdf/to_jelly/manifest.ttl';

  if (!File(manifestPath).existsSync()) {
    print('Jelly conformance test suite not found at $manifestPath');
    print('Run: git submodule update --init --recursive');
    return;
  }

  final testCases = parseJellyToJellyManifest(manifestPath);

  final tripleTests = testCases
      .where((t) => t.physicalType == JellyPhysicalType.triples)
      .toList();
  final quadTests = testCases
      .where((t) => t.physicalType == JellyPhysicalType.quads)
      .toList();
  final graphTests = testCases
      .where((t) => t.physicalType == JellyPhysicalType.graphs)
      .toList();

  group('Jelly to_jelly conformance: TRIPLES', () {
    final positive = tripleTests.where((t) => t.kind == JellyTestKind.positive);

    group('positive (${positive.length})', () {
      for (final tc in positive) {
        test(tc.name, () async {
          await _runPositiveTripleEncoderTest(tc);
        });
      }
    });
  });

  group('Jelly to_jelly conformance: QUADS', () {
    final positive = quadTests.where((t) => t.kind == JellyTestKind.positive);

    group('positive (${positive.length})', () {
      for (final tc in positive) {
        test(tc.name, () async {
          await _runPositiveDatasetEncoderTest(tc);
        });
      }
    });
  });

  group('Jelly to_jelly conformance: GRAPHS', () {
    final positive = graphTests.where((t) => t.kind == JellyTestKind.positive);

    group('positive (${positive.length})', () {
      for (final tc in positive) {
        test(tc.name, () async {
          await _runPositiveDatasetEncoderTest(tc);
        });
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Reads encoder options from the stream_options.jelly file.
///
/// Requires internal proto access since the public API has no way to extract
/// stream options from a jelly binary blob.
JellyEncoderOptions _readEncoderOptions(String path) {
  final bytes = File(path).readAsBytesSync();
  final frames = readDelimitedFrames(bytes).toList();
  for (final row in frames.first.rows) {
    if (row.whichRow() == RdfStreamRow_Row.options) {
      final opts = row.options;
      return JellyEncoderOptions(
        maxNameTableSize:
            opts.maxNameTableSize > 0 ? opts.maxNameTableSize : 128,
        maxPrefixTableSize: opts.maxPrefixTableSize,
        maxDatatypeTableSize: opts.maxDatatypeTableSize,
        physicalType: opts.physicalType,
        logicalType: opts.logicalType,
      );
    }
  }
  return const JellyEncoderOptions();
}

/// Encodes each input file as one logical frame via [JellyTripleFrameEncoder],
/// sharing lookup-table state across files.
Future<Uint8List> _encodeTripleFrames(
    JellyEncoderOptions opts, List<String> inputPaths) async {
  final frames = JellyTripleFrameEncoder(options: opts)
      .bind(NTriplesToTriplesDecoder().bind(_streamFiles(inputPaths)));

  final builder = BytesBuilder(copy: false);
  await for (final chunk in frames) {
    builder.add(chunk);
  }
  return builder.toBytes();
}

Stream<String> _streamFiles(List<String> inputPaths) =>
    Stream.fromIterable(inputPaths).asyncMap((p) => File(p).readAsString());

/// Encodes each input file as one logical frame via [JellyQuadFrameEncoder],
/// sharing lookup-table state across files.
Future<Uint8List> _encodeQuadFrames(
    JellyEncoderOptions opts, List<String> inputPaths) async {
  final frames = JellyQuadFrameEncoder(options: opts)
      .bind(NQuadsToQuadsDecoder().bind(_streamFiles(inputPaths)));
  final builder = BytesBuilder(copy: false);
  await for (final chunk in frames) {
    builder.add(chunk);
  }
  return builder.toBytes();
}

Future<void> _runPositiveTripleEncoderTest(JellyToJellyTestCase tc) async {
  final encOpts = _readEncoderOptions(tc.streamOptionsPath);

  // Single input: use batch encoder; multi-input: stream one frame per file
  // so that cross-frame lookup-table sharing is exercised.
  final Uint8List actualBytes;
  if (tc.inputPaths.length == 1) {
    final nt = File(tc.inputPaths.first).readAsStringSync().trim();
    final graph = nt.isEmpty ? RdfGraph() : NTriplesDecoder().convert(nt);
    actualBytes = JellyGraphEncoder(options: encOpts).convert(graph);
  } else {
    actualBytes = await _encodeTripleFrames(encOpts, tc.inputPaths);
  }

  final expectedBytes = File(tc.resultPath).readAsBytesSync();
  final actualGraph = JellyGraphDecoder().convert(actualBytes);
  final expectedGraph = JellyGraphDecoder().convert(expectedBytes);

  expect(
    isIsomorphicGraphs(actualGraph, expectedGraph),
    isTrue,
    reason: 'Graph mismatch for ${tc.name}\n'
        '  actual triples:   ${actualGraph.triples.length}\n'
        '  expected triples: ${expectedGraph.triples.length}',
  );
}

Future<void> _runPositiveDatasetEncoderTest(JellyToJellyTestCase tc) async {
  final encOpts = _readEncoderOptions(tc.streamOptionsPath);

  final Uint8List actualBytes;
  if (tc.physicalType == JellyPhysicalType.quads && tc.inputPaths.length > 1) {
    // Multi-input QUADS: stream one frame per file to exercise cross-frame
    // lookup-table sharing.
    actualBytes = await _encodeQuadFrames(encOpts, tc.inputPaths);
  } else {
    // GRAPHS physical type: JellyDatasetEncoder handles graph boundary rows
    // internally; combining all inputs is correct here.
    // Single-input cases also use the batch path.
    final allNq =
        tc.inputPaths.map((p) => File(p).readAsStringSync()).join('\n');
    final dataset = allNq.trim().isEmpty
        ? RdfDataset(defaultGraph: RdfGraph(), namedGraphs: {})
        : NQuadsDecoder().convert(allNq);
    actualBytes = JellyDatasetEncoder(options: encOpts).convert(dataset);
  }

  final expectedBytes = File(tc.resultPath).readAsBytesSync();
  final actualDataset = JellyDatasetDecoder().convert(actualBytes);
  final expectedDataset = JellyDatasetDecoder().convert(expectedBytes);

  expect(
    isIsomorphic(actualDataset, expectedDataset),
    isTrue,
    reason: 'Dataset mismatch for ${tc.name}\n'
        '  actual quads:   ${actualDataset.quads.length}\n'
        '  expected quads: ${expectedDataset.quads.length}',
  );
}
