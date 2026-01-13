import 'dart:convert';
import 'dart:io';

import 'package:rdf_core/rdf_core.dart';
import 'package:test/test.dart';
import 'package:rdf_canonicalization/src/canonical/canonical_util.dart';

import '../../test_util.dart';

/// Official RDF Canonicalization Test Suite
///
/// Tests based on the W3C RDF Dataset Canonicalization test suite
/// https://github.com/w3c/rdf-canon/tree/main/tests
void main() {
  setupTestLogging();
  group('Official RDF Canonicalization Test Suite', () {
    final testData = _loadTestData();

    for (final testCase in testData) {
      if (testCase.rdfc10) {
        test('${testCase.name} (${testCase.test})', () {
          _runCanonicalizationTest(testCase);
        });
      }

      if (testCase.rdfc10map) {
        test('${testCase.name} - identifier map (${testCase.test})', () {
          _runIdentifierMapTest(testCase);
        });
      }
    }
  });
}

/// Represents a test case from the manifest
class TestCase {
  final String test;
  final String name;
  final String comment;
  final int complexity;
  final String approval;
  final String hashAlgorithm;
  final bool rdfc10;
  final bool rdfc10map;

  TestCase({
    required this.test,
    required this.name,
    required this.comment,
    required this.complexity,
    required this.approval,
    required this.hashAlgorithm,
    required this.rdfc10,
    required this.rdfc10map,
  });

  factory TestCase.fromCsvRow(List<String> row) {
    return TestCase(
      test: row[0],
      name: row[1],
      comment: row[2],
      complexity: int.tryParse(row[3]) ?? 0,
      approval: row[4],
      hashAlgorithm: row[5],
      rdfc10: row[6].toLowerCase() == 'true',
      rdfc10map: row[7].toLowerCase() == 'true',
    );
  }
}

/// Load test data from the manifest.csv file
List<TestCase> _loadTestData() {
  final manifestFile = File('test/assets/rdf_canon_tests/manifest.csv');
  final lines = manifestFile.readAsLinesSync();

  // Skip header line
  return lines
      .skip(1)
      .where((line) => line.trim().isNotEmpty)
      .map((line) => _parseCsvLine(line))
      .map((row) => TestCase.fromCsvRow(row))
      .toList();
}

/// Simple CSV parser that handles the manifest format
List<String> _parseCsvLine(String line) {
  final result = <String>[];
  var current = '';
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final char = line[i];

    if (char == '"') {
      inQuotes = !inQuotes;
    } else if (char == ',' && !inQuotes) {
      result.add(current);
      current = '';
    } else {
      current += char;
    }
  }

  result.add(current);
  return result;
}

/// Run a canonicalization test that compares N-Quads output
void _runCanonicalizationTest(TestCase testCase) {
  final testDir = 'test/assets/rdf_canon_tests/rdfc10';

  // Load input
  final inputFile = File('$testDir/${testCase.test}-in.nq');
  final inputNQuads = inputFile.readAsStringSync();

  // Load expected output
  final expectedFile = File('$testDir/${testCase.test}-rdfc10.nq');
  final expectedNQuads = expectedFile.readAsStringSync().trim();

  // Parse input dataset
  final dataset = nquads.decode(inputNQuads);

  // Canonicalize
  final options = _getOptionsForTest(testCase);
  final result = canonicalize(dataset, options: options);

  // Compare results - normalize line endings and trim whitespace
  final normalizedResult = result.trim();
  final normalizedExpected = expectedNQuads.trim();

  if (normalizedResult != normalizedExpected) {
    print('Test ${testCase.test} failed:');
    print('Expected:');
    print(normalizedExpected);
    print('Got:');
    print(normalizedResult);
  }

  expect(normalizedResult, equals(normalizedExpected),
      reason:
          'Canonicalized N-Quads do not match expected output for ${testCase.test}');
}

/// Run an identifier map test that compares the issued identifier mapping
void _runIdentifierMapTest(TestCase testCase) {
  final testDir = 'test/assets/rdf_canon_tests/rdfc10';

  // Load input
  final inputFile = File('$testDir/${testCase.test}-in.nq');
  final inputNQuads = inputFile.readAsStringSync();

  // Load expected identifier map
  final mapFile = File('$testDir/${testCase.test}-rdfc10map.json');
  final expectedMapJson = mapFile.readAsStringSync();
  final expectedMap = json.decode(expectedMapJson) as Map<String, dynamic>;

  // Parse input dataset with input labels
  final NQuadsDecoder decoder = NQuadsDecoder();
  final (blankNodeLabels: inputLabels, dataset: inputDataset) =
      decoder.decode(inputNQuads);

  // Canonicalize
  final options = _getOptionsForTest(testCase);
  final canonicalized = toCanonicalizedRdfDataset(inputDataset,
      inputLabels: inputLabels, options: options);

  // Build actual identifier map from original input labels to canonical labels
  final actualMap = <String, String>{};

  for (final entry in canonicalized.issuedIdentifiers.entries) {
    final blankNode = entry.key;
    final canonicalId = entry.value;

    // Find the original input label for this blank node
    final originalLabel = inputLabels[blankNode];
    if (originalLabel != null) {
      // Remove the _: prefix from the original label to match expected format
      final cleanLabel = originalLabel.startsWith('_:')
          ? originalLabel.substring(2)
          : originalLabel;
      actualMap[cleanLabel] = canonicalId;
    }
  }

  // Compare maps
  expect(actualMap, equals(expectedMap),
      reason:
          'Issued identifier map does not match expected output for ${testCase.test}');
}

/// Get canonicalization options for a test case
CanonicalizationOptions _getOptionsForTest(TestCase testCase) {
  CanonicalHashAlgorithm algorithm = CanonicalHashAlgorithm.sha256;

  if (testCase.hashAlgorithm.isNotEmpty) {
    switch (testCase.hashAlgorithm.toLowerCase()) {
      case 'sha384':
        algorithm = CanonicalHashAlgorithm.sha384;
        break;
      case 'sha256':
      default:
        algorithm = CanonicalHashAlgorithm.sha256;
        break;
    }
  }

  return CanonicalizationOptions(
    hashAlgorithm: algorithm,
  );
}
