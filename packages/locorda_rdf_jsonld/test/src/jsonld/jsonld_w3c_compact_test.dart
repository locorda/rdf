import 'dart:convert';
import 'dart:io';

import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_compaction_processor.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_context_documents.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_utils.dart';
import 'package:test/test.dart';

/// W3C official JSON-LD compact test suite.
///
/// Runs all tests from the W3C JSON-LD API compact test suite manifest.
/// Test data is provided via the w3c/json-ld-api git submodule.
///
/// Pipeline: expanded JSON-LD → JsonLdCompactionProcessor → compacted JSON-LD
/// Compare: JSON structural equality with expected .jsonld file.
void main() {
  final testsDir = '../../test_assets/w3c/json-ld-api/tests';
  final manifestPath = '$testsDir/compact-manifest.jsonld';

  if (!File(manifestPath).existsSync()) {
    print('W3C JSON-LD test suite not found at $manifestPath');
    print('Run: git submodule update --init --recursive');
    return;
  }

  final testCases = _parseManifest(manifestPath);
  final baseIri = 'https://w3c.github.io/json-ld-api/tests/';
  final testsDirUri = Directory(testsDir).absolute.uri.toString();

  group('W3C JSON-LD Compact Test Suite', () {
    final positiveTests =
        testCases.where((t) => t.type == _TestType.positiveEval);
    final negativeTests =
        testCases.where((t) => t.type == _TestType.negativeEval);

    group('Positive eval tests (${positiveTests.length})', () {
      for (final tc in positiveTests) {
        test(tc.name, () {
          final inputContent = File('$testsDir/${tc.input}').readAsStringSync();
          final contextContent =
              File('$testsDir/${tc.context!}').readAsStringSync();
          final expectedJson =
              File('$testsDir/${tc.expect!}').readAsStringSync();

          final documentUrl = '$baseIri${tc.input}';
          final effectiveBase = tc.options.base ?? documentUrl;

          final processor = JsonLdCompactionProcessor(
            processingMode: tc.options.processingMode,
            contextDocumentProvider: MappedFileJsonLdContextDocumentProvider(
              iriPrefixMappings: {baseIri: testsDirUri},
            ),
            documentBaseUri: effectiveBase,
          );

          // Parse inputs.
          final input = jsonDecode(inputContent);
          final context = jsonDecode(contextContent);

          // Compact.
          final actual = processor.compact(
            input,
            context: context,
            documentUrl: effectiveBase,
            compactArrays: tc.options.compactArrays,
          );

          // Parse expected.
          final expected = jsonDecode(expectedJson);

          final match = _jsonDeepEquals(expected, actual);
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
          final contextContent = tc.context != null
              ? File('$testsDir/${tc.context!}').readAsStringSync()
              : '{}';

          final documentUrl = '$baseIri${tc.input}';
          final effectiveBase = tc.options.base ?? documentUrl;

          final processor = JsonLdCompactionProcessor(
            processingMode: tc.options.processingMode,
            contextDocumentProvider: MappedFileJsonLdContextDocumentProvider(
              iriPrefixMappings: {baseIri: testsDirUri},
            ),
            documentBaseUri: effectiveBase,
          );

          final input = jsonDecode(inputContent);
          final context = jsonDecode(contextContent);

          expect(
            () => processor.compact(
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

class _CompactOptions {
  final JsonLdProcessingMode processingMode;
  final String? base;
  final bool compactArrays;

  const _CompactOptions({
    this.processingMode = JsonLdProcessingMode.jsonLd11,
    this.base,
    this.compactArrays = true,
  });
}

class _CompactTestCase {
  final String id;
  final String name;
  final _TestType type;
  final String input;
  final String? context;
  final String? expect;
  final String? expectErrorCode;
  final _CompactOptions options;

  const _CompactTestCase({
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

List<_CompactTestCase> _parseManifest(String manifestPath) {
  final content = File(manifestPath).readAsStringSync();
  final manifest = jsonDecode(content) as Map<String, dynamic>;
  final sequence = manifest['sequence'] as List<dynamic>;

  final cases = <_CompactTestCase>[];
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
    // Skip tests written for the JSON-LD 1.0 spec — they have 1.1
    // counterparts with updated expected output.
    if (specVersion == 'json-ld-1.0') continue;
    final processingMode = JsonLdProcessingMode.fromSpecString(
        option['processingMode'] as String? ?? specVersion);

    cases.add(_CompactTestCase(
      id: id,
      name: name,
      type: testType,
      input: input,
      context: context,
      expect: expect,
      expectErrorCode: expectErrorCode,
      options: _CompactOptions(
        processingMode: processingMode,
        base: option['base'] as String?,
        compactArrays: option['compactArrays'] as bool? ?? true,
      ),
    ));
  }

  return cases;
}

// ---------------------------------------------------------------------------
// JSON comparison
// ---------------------------------------------------------------------------

bool _jsonDeepEquals(Object? expected, Object? actual) {
  if (expected is Map && actual is Map) {
    if (expected.length != actual.length) return false;
    for (final key in expected.keys) {
      if (!actual.containsKey(key)) return false;
      if (!_jsonDeepEquals(expected[key], actual[key])) {
        return false;
      }
    }
    return true;
  }

  if (expected is List && actual is List) {
    if (expected.length != actual.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (!_jsonDeepEquals(expected[i], actual[i])) {
        return false;
      }
    }
    return true;
  }

  if (expected is num && actual is num) {
    return expected == actual;
  }

  return expected == actual;
}
