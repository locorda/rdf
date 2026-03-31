import 'dart:convert';
import 'dart:io';

import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

/// W3C official JSON-LD fromRdf test suite.
///
/// Runs all tests from the W3C JSON-LD API fromRdf test suite manifest.
/// Test data is provided via the w3c/json-ld-api git submodule.
///
/// Pipeline: NQuads file → NQuadsDecoder → RdfDataset → JsonLdExpandedSerializer → JSON
/// Compare: JSON structural equality with expected .jsonld file (blank-node–isomorphic).
void main() {
  final testsDir = '../../test_assets/w3c/json-ld-api/tests';
  final manifestPath = '$testsDir/fromRdf-manifest.jsonld';

  if (!File(manifestPath).existsSync()) {
    print('W3C JSON-LD test suite not found at $manifestPath');
    print('Run: git submodule update --init --recursive');
    return;
  }

  final testCases = _parseManifest(manifestPath);

  group('W3C JSON-LD fromRdf Test Suite', () {
    // Skip json-ld-1.0 tests — our implementation targets 1.1.
    final skippedTests =
        testCases.where((t) => t.specVersion == 'json-ld-1.0');
    for (final tc in skippedTests) {
      test(tc.name, skip: 'Requires json-ld-1.0 semantics', () {});
    }

    final supported =
        testCases.where((t) => t.specVersion != 'json-ld-1.0');
    final positiveTests =
        supported.where((t) => t.type == _TestType.positiveEval);
    final negativeTests =
        supported.where((t) => t.type == _TestType.negativeEval);

    group('Positive eval tests (${positiveTests.length})', () {
      for (final tc in positiveTests) {
        test(tc.name, () {
          final inputNq =
              File('$testsDir/${tc.input}').readAsStringSync();
          final expectedJson =
              File('$testsDir/${tc.expect!}').readAsStringSync();

          // Decode NQuads → RdfDataset
          final dataset = NQuadsDecoder().convert(inputNq);

          // Encode dataset → expanded JSON-LD string
          final encoder = JsonLdEncoder(
            options: JsonLdEncoderOptions(
              outputMode: JsonLdOutputMode.expanded,
              useNativeTypes: tc.useNativeTypes,
              useRdfType: tc.useRdfType,
              rdfDirection: tc.rdfDirection,
            ),
          );
          final actualJson = encoder.convert(dataset);

          // Parse both and compare structurally
          final expected = jsonDecode(expectedJson);
          final actual = jsonDecode(actualJson);

          final match = _jsonDeepEqualsWithBnodeIsomorphism(expected, actual);
          expect(match, isTrue,
              reason: 'JSON mismatch for ${tc.name}\n'
                  'Expected:\n$expectedJson\n'
                  'Actual:\n$actualJson');
        });
      }
    });

    group('Negative eval tests (${negativeTests.length})', () {
      for (final tc in negativeTests) {
        test(tc.name, () {
          final inputNq =
              File('$testsDir/${tc.input}').readAsStringSync();

          // Decode NQuads → RdfDataset
          final dataset = NQuadsDecoder().convert(inputNq);

          // Encoding should throw
          final encoder = JsonLdEncoder(
            options: JsonLdEncoderOptions(
              outputMode: JsonLdOutputMode.expanded,
              useNativeTypes: tc.useNativeTypes,
              useRdfType: tc.useRdfType,
              rdfDirection: tc.rdfDirection,
            ),
          );

          expect(
            () => encoder.convert(dataset),
            throwsA(isA<Exception>()),
            reason:
                'Expected error for ${tc.name}: ${tc.expectErrorCode}',
          );
        });
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Manifest parsing (simple JSON parse, no decoder needed for fromRdf)
// ---------------------------------------------------------------------------

enum _TestType { positiveEval, negativeEval }

class _FromRdfTestCase {
  final String id;
  final String name;
  final _TestType type;
  final String input;
  final String? expect;
  final String? expectErrorCode;
  final bool useNativeTypes;
  final bool useRdfType;
  final String? rdfDirection;
  final String specVersion;

  const _FromRdfTestCase({
    required this.id,
    required this.name,
    required this.type,
    required this.input,
    this.expect,
    this.expectErrorCode,
    this.useNativeTypes = false,
    this.useRdfType = false,
    this.rdfDirection,
    this.specVersion = 'json-ld-1.1',
  });
}

List<_FromRdfTestCase> _parseManifest(String manifestPath) {
  final content = File(manifestPath).readAsStringSync();
  final manifest = jsonDecode(content) as Map<String, dynamic>;
  final sequence = manifest['sequence'] as List<dynamic>;

  final cases = <_FromRdfTestCase>[];
  for (final item in sequence) {
    if (item is! Map<String, dynamic>) continue;

    final id = item['@id'] as String;
    final name = item['name'] as String;
    final types = item['@type'];
    final typeList =
        types is List ? types.cast<String>() : [types as String];

    _TestType? testType;
    if (typeList.contains('jld:PositiveEvaluationTest')) {
      testType = _TestType.positiveEval;
    } else if (typeList.contains('jld:NegativeEvaluationTest')) {
      testType = _TestType.negativeEval;
    }
    if (testType == null) continue;

    final input = item['input'] as String;
    final expect = item['expect'] as String?;
    final expectErrorCode = item['expectErrorCode'] as String?;

    final option =
        item['option'] as Map<String, dynamic>? ?? const {};
    final specVersion =
        option['specVersion'] as String? ?? 'json-ld-1.1';

    cases.add(_FromRdfTestCase(
      specVersion: specVersion,
      id: id,
      name: name,
      type: testType,
      input: input,
      expect: expect,
      expectErrorCode: expectErrorCode,
      useNativeTypes: option['useNativeTypes'] as bool? ?? false,
      useRdfType: option['useRdfType'] as bool? ?? false,
      rdfDirection: option['rdfDirection'] as String?,
    ));
  }

  return cases;
}

// ---------------------------------------------------------------------------
// JSON comparison with blank-node isomorphism
// ---------------------------------------------------------------------------

/// Compare two JSON values structurally, treating blank-node identifiers
/// (strings starting with `_:`) as isomorphic — i.e., the actual blank-node
/// labels can differ from expected as long as there's a consistent 1:1 mapping.
bool _jsonDeepEqualsWithBnodeIsomorphism(Object? expected, Object? actual) {
  final mapping = <String, String>{}; // expected bnode → actual bnode
  final reverseMapping = <String, String>{}; // actual bnode → expected bnode
  return _deepEquals(expected, actual, mapping, reverseMapping);
}

bool _deepEquals(
  Object? expected,
  Object? actual,
  Map<String, String> mapping,
  Map<String, String> reverseMapping,
) {
  if (expected is Map && actual is Map) {
    if (expected.length != actual.length) return false;
    for (final key in expected.keys) {
      if (!actual.containsKey(key)) return false;
      if (!_deepEquals(expected[key], actual[key], mapping, reverseMapping)) {
        return false;
      }
    }
    return true;
  }

  if (expected is List && actual is List) {
    if (expected.length != actual.length) return false;

    // Try order-sensitive match first (most common case).
    if (_listMatchesOrdered(expected, actual, mapping, reverseMapping)) {
      return true;
    }

    // For top-level arrays and @graph arrays, try order-insensitive match
    // (node objects may appear in different order).
    return _listMatchesUnordered(expected, actual, mapping, reverseMapping);
  }

  if (expected is String && actual is String) {
    return _matchStringsWithBnodes(expected, actual, mapping, reverseMapping);
  }

  if (expected is num && actual is num) {
    return expected == actual;
  }

  return expected == actual;
}

bool _matchStringsWithBnodes(
  String expected,
  String actual,
  Map<String, String> mapping,
  Map<String, String> reverseMapping,
) {
  final eBnode = expected.startsWith('_:');
  final aBnode = actual.startsWith('_:');

  if (eBnode && aBnode) {
    // Check/create mapping
    final existingActual = mapping[expected];
    final existingExpected = reverseMapping[actual];
    if (existingActual != null) return existingActual == actual;
    if (existingExpected != null) return existingExpected == expected;
    mapping[expected] = actual;
    reverseMapping[actual] = expected;
    return true;
  }

  return expected == actual;
}

bool _listMatchesOrdered(
  List expected,
  List actual,
  Map<String, String> mapping,
  Map<String, String> reverseMapping,
) {
  // Save mapping state so we can restore on failure
  final savedMapping = Map<String, String>.from(mapping);
  final savedReverse = Map<String, String>.from(reverseMapping);

  for (var i = 0; i < expected.length; i++) {
    if (!_deepEquals(expected[i], actual[i], mapping, reverseMapping)) {
      mapping
        ..clear()
        ..addAll(savedMapping);
      reverseMapping
        ..clear()
        ..addAll(savedReverse);
      return false;
    }
  }
  return true;
}

bool _listMatchesUnordered(
  List expected,
  List actual,
  Map<String, String> mapping,
  Map<String, String> reverseMapping,
) {
  // Save mapping state
  final savedMapping = Map<String, String>.from(mapping);
  final savedReverse = Map<String, String>.from(reverseMapping);

  final used = List.filled(actual.length, false);

  for (final expectedItem in expected) {
    var matched = false;
    for (var j = 0; j < actual.length; j++) {
      if (used[j]) continue;

      // Save before trying
      final tryMapping = Map<String, String>.from(mapping);
      final tryReverse = Map<String, String>.from(reverseMapping);

      if (_deepEquals(expectedItem, actual[j], mapping, reverseMapping)) {
        used[j] = true;
        matched = true;
        break;
      } else {
        // Restore mapping
        mapping
          ..clear()
          ..addAll(tryMapping);
        reverseMapping
          ..clear()
          ..addAll(tryReverse);
      }
    }
    if (!matched) {
      mapping
        ..clear()
        ..addAll(savedMapping);
      reverseMapping
        ..clear()
        ..addAll(savedReverse);
      return false;
    }
  }
  return true;
}
