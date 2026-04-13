import 'dart:convert';
import 'dart:io';

import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_context_documents.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_expansion_processor.dart';
import 'package:test/test.dart';

/// W3C official JSON-LD expand test suite.
///
/// Runs all tests from the W3C JSON-LD API expand test suite manifest.
/// Test data is provided via the w3c/json-ld-api git submodule.
///
/// Pipeline: JSON-LD file → jsonDecode → JsonLdExpansionProcessor → JSON
/// Compare: JSON structural equality with expected .jsonld file
/// (order-insensitive node arrays, blank-node–isomorphic).
void main() {
  final testsDir = '../../test_assets/w3c/json-ld-api/tests';
  final manifestPath = '$testsDir/expand-manifest.jsonld';

  if (!File(manifestPath).existsSync()) {
    print('W3C JSON-LD test suite not found at $manifestPath');
    print('Run: git submodule update --init --recursive');
    return;
  }

  final testCases = _parseManifest(manifestPath);
  final baseIri = 'https://w3c.github.io/json-ld-api/tests/';
  final testsDirUri = Directory(testsDir).absolute.uri.toString();

  group('W3C JSON-LD Expand Test Suite', () {
    final positiveTests =
        testCases.where((t) => t.type == _TestType.positiveEval);
    final negativeTests =
        testCases.where((t) => t.type == _TestType.negativeEval);

    group('Positive eval tests (${positiveTests.length})', () {
      for (final tc in positiveTests) {
        test(tc.name, () {
          final inputContent = File('$testsDir/${tc.input}').readAsStringSync();
          final expectedJson =
              File('$testsDir/${tc.expect!}').readAsStringSync();

          final documentUrl = '$baseIri${tc.input}';
          final effectiveBase = tc.options.base ?? documentUrl;

          final processor = JsonLdExpansionProcessor(
            processingMode: tc.options.processingMode,
            contextDocumentProvider: MappedFileJsonLdContextDocumentProvider(
              iriPrefixMappings: {baseIri: testsDirUri},
            ),
            documentBaseUri: effectiveBase,
          );

          // Parse input JSON.
          final input = jsonDecode(inputContent);

          // Expand.
          Object? expandContext;
          if (tc.options.expandContext != null) {
            expandContext = jsonDecode(
                File('$testsDir/${tc.options.expandContext}')
                    .readAsStringSync());
          }

          final actual = processor.expand(
            input,
            documentUrl: effectiveBase,
            expandContext: expandContext,
          );

          // Parse expected.
          final expected = jsonDecode(expectedJson);

          final match = _jsonDeepEqualsWithBnodeIsomorphism(expected, actual);
          expect(
            match,
            isTrue,
            reason: 'JSON mismatch for ${tc.name}\n'
                'Expected:\n$expectedJson\n'
                'Actual:\n${jsonEncode(actual)}',
          );
        });
      }
    });

    group('Negative eval tests (${negativeTests.length})', () {
      for (final tc in negativeTests) {
        test(tc.name, () {
          final inputContent = File('$testsDir/${tc.input}').readAsStringSync();

          final documentUrl = '$baseIri${tc.input}';
          final effectiveBase = tc.options.base ?? documentUrl;

          final processor = JsonLdExpansionProcessor(
            processingMode: tc.options.processingMode,
            contextDocumentProvider: MappedFileJsonLdContextDocumentProvider(
              iriPrefixMappings: {baseIri: testsDirUri},
            ),
            documentBaseUri: effectiveBase,
          );

          final input = jsonDecode(inputContent);

          Object? expandContext;
          if (tc.options.expandContext != null) {
            expandContext = jsonDecode(
                File('$testsDir/${tc.options.expandContext}')
                    .readAsStringSync());
          }

          expect(
            () => processor.expand(
              input,
              documentUrl: effectiveBase,
              expandContext: expandContext,
            ),
            throwsA(isA<Exception>()),
            reason: 'Expected error for ${tc.name}: ${tc.expectErrorCode}',
          );
        });
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Manifest parsing
// ---------------------------------------------------------------------------

enum _TestType { positiveEval, negativeEval }

class _ExpandOptions {
  final String processingMode;
  final String? base;
  final String? expandContext;

  const _ExpandOptions({
    this.processingMode = 'json-ld-1.1',
    this.base,
    this.expandContext,
  });
}

class _ExpandTestCase {
  final String id;
  final String name;
  final _TestType type;
  final String input;
  final String? expect;
  final String? expectErrorCode;
  final _ExpandOptions options;

  const _ExpandTestCase({
    required this.id,
    required this.name,
    required this.type,
    required this.input,
    this.expect,
    this.expectErrorCode,
    required this.options,
  });
}

List<_ExpandTestCase> _parseManifest(String manifestPath) {
  final content = File(manifestPath).readAsStringSync();
  final manifest = jsonDecode(content) as Map<String, dynamic>;
  final sequence = manifest['sequence'] as List<dynamic>;

  final cases = <_ExpandTestCase>[];
  for (final item in sequence) {
    if (item is! Map<String, dynamic>) continue;

    final id = item['@id'] as String;
    final name = item['name'] as String;
    final types = item['@type'];
    final typeList = types is List ? types.cast<String>() : [types as String];

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

    final option = item['option'] as Map<String, dynamic>? ?? const {};
    final specVersion = option['specVersion'] as String? ?? 'json-ld-1.1';
    final processingMode = option['processingMode'] as String? ?? specVersion;

    cases.add(_ExpandTestCase(
      id: id,
      name: name,
      type: testType,
      input: input,
      expect: expect,
      expectErrorCode: expectErrorCode,
      options: _ExpandOptions(
        processingMode: processingMode,
        base: option['base'] as String?,
        expandContext: option['expandContext'] as String?,
      ),
    ));
  }

  return cases;
}

// ---------------------------------------------------------------------------
// JSON comparison with blank-node isomorphism
// ---------------------------------------------------------------------------

bool _jsonDeepEqualsWithBnodeIsomorphism(Object? expected, Object? actual) {
  final mapping = <String, String>{};
  final reverseMapping = <String, String>{};
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

    // Try ordered first.
    if (_listMatchesOrdered(expected, actual, mapping, reverseMapping)) {
      return true;
    }
    // Then unordered.
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
  final used = List<bool>.filled(actual.length, false);

  for (final exp in expected) {
    var found = false;
    for (var j = 0; j < actual.length; j++) {
      if (used[j]) continue;
      final savedMapping = Map<String, String>.from(mapping);
      final savedReverse = Map<String, String>.from(reverseMapping);
      if (_deepEquals(exp, actual[j], mapping, reverseMapping)) {
        used[j] = true;
        found = true;
        break;
      }
      mapping
        ..clear()
        ..addAll(savedMapping);
      reverseMapping
        ..clear()
        ..addAll(savedReverse);
    }
    if (!found) return false;
  }
  return true;
}
