import 'dart:convert';
import 'dart:io';

import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_context_documents.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_flatten_processor.dart';
import 'package:test/test.dart';

/// W3C official JSON-LD flatten test suite.
///
/// Runs all tests from the W3C JSON-LD API flatten test suite manifest.
/// Test data is provided via the w3c/json-ld-api git submodule.
///
/// Pipeline: JSON-LD input → expand → flatten → (optionally compact)
/// Compare: JSON structural equality with expected .jsonld file.
void main() {
  final testsDir = '../../test_assets/w3c/json-ld-api/tests';
  final manifestPath = '$testsDir/flatten-manifest.jsonld';

  if (!File(manifestPath).existsSync()) {
    print('W3C JSON-LD test suite not found at $manifestPath');
    print('Run: git submodule update --init --recursive');
    return;
  }

  final testCases = _parseManifest(manifestPath);
  final baseIri = 'https://w3c.github.io/json-ld-api/tests/';
  final testsDirUri = Directory(testsDir).absolute.uri.toString();

  group('W3C JSON-LD Flatten Test Suite', () {
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

          final processor = JsonLdFlattenProcessor(
            processingMode: tc.options.processingMode,
            contextDocumentProvider: MappedFileJsonLdContextDocumentProvider(
              iriPrefixMappings: {baseIri: testsDirUri},
            ),
            documentBaseUri: effectiveBase,
          );

          // Parse inputs.
          final input = jsonDecode(inputContent);

          // Load optional compaction context.
          Object? context;
          if (tc.context != null) {
            final contextContent =
                File('$testsDir/${tc.context!}').readAsStringSync();
            context = jsonDecode(contextContent);
          }

          // Flatten.
          final actual = processor.flatten(
            input,
            context: context,
            documentUrl: effectiveBase,
            compactArrays: tc.options.compactArrays,
          );

          // Parse expected.
          final expected = jsonDecode(expectedJson);

          // Compare with blank node relabeling tolerance.
          final match = _jsonDeepEqualsWithBnodes(expected, actual);
          expect(
            match,
            isTrue,
            reason: 'JSON mismatch for ${tc.name}\n'
                'Expected:\n${const JsonEncoder.withIndent('  ').convert(expected)}\n'
                'Actual:\n${const JsonEncoder.withIndent('  ').convert(actual)}',
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

          final processor = JsonLdFlattenProcessor(
            processingMode: tc.options.processingMode,
            contextDocumentProvider: MappedFileJsonLdContextDocumentProvider(
              iriPrefixMappings: {baseIri: testsDirUri},
            ),
            documentBaseUri: effectiveBase,
          );

          final input = jsonDecode(inputContent);

          Object? context;
          if (tc.context != null) {
            final contextContent =
                File('$testsDir/${tc.context!}').readAsStringSync();
            context = jsonDecode(contextContent);
          }

          expect(
            () => processor.flatten(
              input,
              context: context,
              documentUrl: effectiveBase,
              compactArrays: tc.options.compactArrays,
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

class _FlattenOptions {
  final String processingMode;
  final String? base;
  final bool compactArrays;

  const _FlattenOptions({
    this.processingMode = 'json-ld-1.1',
    this.base,
    this.compactArrays = true,
  });
}

class _FlattenTestCase {
  final String id;
  final String name;
  final _TestType type;
  final String input;
  final String? context;
  final String? expect;
  final String? expectErrorCode;
  final _FlattenOptions options;

  const _FlattenTestCase({
    required this.id,
    required this.name,
    required this.type,
    required this.input,
    this.context,
    this.expect,
    this.expectErrorCode,
    required this.options,
  });
}

List<_FlattenTestCase> _parseManifest(String manifestPath) {
  final content = File(manifestPath).readAsStringSync();
  final manifest = jsonDecode(content) as Map<String, dynamic>;
  final sequence = manifest['sequence'] as List<dynamic>;

  final cases = <_FlattenTestCase>[];
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
    final context = item['context'] as String?;
    final expect = item['expect'] as String?;
    final expectErrorCode = item['expectErrorCode'] as String?;

    final option = item['option'] as Map<String, dynamic>? ?? const {};
    final specVersion = option['specVersion'] as String? ?? 'json-ld-1.1';
    // Skip tests written for the JSON-LD 1.0 spec.
    if (specVersion == 'json-ld-1.0') continue;
    final processingMode = option['processingMode'] as String? ?? specVersion;

    cases.add(_FlattenTestCase(
      id: id,
      name: name,
      type: testType,
      input: input,
      context: context,
      expect: expect,
      expectErrorCode: expectErrorCode,
      options: _FlattenOptions(
        processingMode: processingMode,
        base: option['base'] as String?,
        compactArrays: option['compactArrays'] as bool? ?? true,
      ),
    ));
  }

  return cases;
}

// ---------------------------------------------------------------------------
// JSON comparison with blank node tolerance
// ---------------------------------------------------------------------------

/// Compares two JSON structures for equality, allowing blank node IDs to
/// differ as long as there is a consistent 1:1 mapping between them.
bool _jsonDeepEqualsWithBnodes(Object? expected, Object? actual) {
  final mapping = <String, String>{};
  final reverseMapping = <String, String>{};
  return _compareWithBnodeMapping(expected, actual, mapping, reverseMapping);
}

bool _compareWithBnodeMapping(Object? expected, Object? actual,
    Map<String, String> mapping, Map<String, String> reverseMapping) {
  if (expected is Map && actual is Map) {
    if (expected.length != actual.length) return false;
    for (final key in expected.keys) {
      if (!actual.containsKey(key)) return false;
      if (!_compareWithBnodeMapping(
          expected[key], actual[key], mapping, reverseMapping)) {
        return false;
      }
    }
    return true;
  }

  if (expected is List && actual is List) {
    if (expected.length != actual.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (!_compareWithBnodeMapping(
          expected[i], actual[i], mapping, reverseMapping)) {
        return false;
      }
    }
    return true;
  }

  if (expected is String && actual is String) {
    if (expected.startsWith('_:') && actual.startsWith('_:')) {
      // Check/create blank node mapping.
      if (mapping.containsKey(expected)) {
        return mapping[expected] == actual;
      }
      if (reverseMapping.containsKey(actual)) {
        return reverseMapping[actual] == expected;
      }
      mapping[expected] = actual;
      reverseMapping[actual] = expected;
      return true;
    }
    return expected == actual;
  }

  if (expected is num && actual is num) {
    return expected == actual;
  }

  return expected == actual;
}
