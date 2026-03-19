/// Jelly from_jelly conformance test suite.
///
/// Runs the official Jelly-RDF conformance tests for decoding .jelly files
/// into RDF triples/quads and comparing against expected N-Triples/N-Quads.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:locorda_rdf_canonicalization/canonicalization.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';
import 'package:test/test.dart';

import '../jelly_manifest_parser.dart';

void main() {
  final manifestPath =
      '../../test_assets/jelly/jelly-protobuf/test/rdf/from_jelly/manifest.ttl';

  if (!File(manifestPath).existsSync()) {
    print('Jelly conformance test suite not found at $manifestPath');
    print('Run: git submodule update --init --recursive');
    return;
  }

  final testCases = parseJellyManifest(manifestPath);

  final tripleTests = testCases
      .where((t) => t.physicalType == JellyPhysicalType.triples)
      .toList();
  final quadTests = testCases
      .where((t) => t.physicalType == JellyPhysicalType.quads)
      .toList();
  final graphTests = testCases
      .where((t) => t.physicalType == JellyPhysicalType.graphs)
      .toList();

  group('Jelly from_jelly conformance: TRIPLES', () {
    final positive =
        tripleTests.where((t) => t.kind == JellyTestKind.positive);
    final negative =
        tripleTests.where((t) => t.kind == JellyTestKind.negative);

    group('positive (${positive.length})', () {
      for (final tc in positive) {
        test(tc.name, () {
          _runPositiveTripleTest(tc);
        });
      }
    });

    group('negative (${negative.length})', () {
      for (final tc in negative) {
        test(tc.name, () {
          _runNegativeTripleTest(tc);
        });
      }
    });
  });

  group('Jelly from_jelly conformance: QUADS', () {
    final positive =
        quadTests.where((t) => t.kind == JellyTestKind.positive);
    final negative =
        quadTests.where((t) => t.kind == JellyTestKind.negative);

    group('positive (${positive.length})', () {
      for (final tc in positive) {
        test(tc.name, () {
          _runPositiveQuadTest(tc);
        });
      }
    });

    group('negative (${negative.length})', () {
      for (final tc in negative) {
        test(tc.name, () {
          _runNegativeQuadTest(tc);
        });
      }
    });
  });

  group('Jelly from_jelly conformance: GRAPHS', () {
    final positive =
        graphTests.where((t) => t.kind == JellyTestKind.positive);
    final negative =
        graphTests.where((t) => t.kind == JellyTestKind.negative);

    group('positive (${positive.length})', () {
      for (final tc in positive) {
        test(tc.name, () {
          _runPositiveQuadTest(tc);
        });
      }
    });

    group('negative (${negative.length})', () {
      for (final tc in negative) {
        test(tc.name, () {
          _runNegativeQuadTest(tc);
        });
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Positive test helpers
// ---------------------------------------------------------------------------

void _runPositiveTripleTest(JellyTestCase tc) {
  final input = Uint8List.fromList(File(tc.actionPath).readAsBytesSync());
  final decoder = JellyGraphDecoder();
  final actualGraph = decoder.convert(input);

  // Concatenate all expected output files into one N-Triples string so that
  // blank nodes with the same label across frames share identity.
  final allNt = tc.resultPaths.map((p) => File(p).readAsStringSync()).join();
  final expectedGraph =
      allNt.trim().isEmpty ? RdfGraph() : NTriplesDecoder().convert(allNt);

  expect(
    isIsomorphicGraphs(actualGraph, expectedGraph),
    isTrue,
    reason: 'Graph mismatch for ${tc.name}\n'
        '  actual triples: ${actualGraph.triples.length}\n'
        '  expected triples: ${expectedGraph.triples.length}',
  );
}

void _runPositiveQuadTest(JellyTestCase tc) {
  final input = Uint8List.fromList(File(tc.actionPath).readAsBytesSync());
  final decoder = JellyDatasetDecoder();
  final actualDataset = decoder.convert(input);

  // Concatenate all expected output files into one N-Quads string so that
  // blank nodes with the same label across frames share identity.
  final allNq = tc.resultPaths.map((p) => File(p).readAsStringSync()).join();
  final expectedDataset = allNq.trim().isEmpty
      ? RdfDataset(defaultGraph: RdfGraph(), namedGraphs: {})
      : NQuadsDecoder().convert(allNq);

  expect(
    isIsomorphic(actualDataset, expectedDataset),
    isTrue,
    reason: 'Dataset mismatch for ${tc.name}\n'
        '  actual quads: ${actualDataset.quads.length}\n'
        '  expected quads: ${expectedDataset.quads.length}',
  );
}

// ---------------------------------------------------------------------------
// Negative test helpers
// ---------------------------------------------------------------------------

void _runNegativeTripleTest(JellyTestCase tc) {
  final input = Uint8List.fromList(File(tc.actionPath).readAsBytesSync());
  final decoder = JellyGraphDecoder();
  expect(
    () => decoder.convert(input),
    throwsA(isA<Exception>()),
    reason: 'Expected decoder error for ${tc.name}',
  );
}

void _runNegativeQuadTest(JellyTestCase tc) {
  final input = Uint8List.fromList(File(tc.actionPath).readAsBytesSync());
  final decoder = JellyDatasetDecoder();
  expect(
    () => decoder.convert(input),
    throwsA(isA<Exception>()),
    reason: 'Expected decoder error for ${tc.name}',
  );
}
