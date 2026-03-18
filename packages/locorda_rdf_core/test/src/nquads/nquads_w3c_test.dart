import 'dart:io';

import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

import '../../w3c_manifest_parser.dart';

/// W3C official N-Quads test suite.
///
/// Runs all tests from the W3C RDF 1.1 N-Quads test suite manifest.
/// Test data is provided via the w3c/rdf-tests git submodule.
void main() {
  final manifestPath =
      '../../test_assets/w3c/rdf-tests/rdf/rdf11/rdf-n-quads/manifest.ttl';

  if (!File(manifestPath).existsSync()) {
    print('W3C test suite not found at $manifestPath');
    print('Run: git submodule update --init --recursive');
    return;
  }

  final testCases = parseW3cManifest(manifestPath);

  group('W3C N-Quads Test Suite', () {
    final positiveSyntaxTests =
        testCases.where((t) => t.type == W3cTestType.nquadsPositiveSyntax);
    final negativeSyntaxTests =
        testCases.where((t) => t.type == W3cTestType.nquadsNegativeSyntax);

    group('Positive syntax tests (${positiveSyntaxTests.length})', () {
      for (final tc in positiveSyntaxTests) {
        test(tc.name, () {
          final input = File(tc.actionPath).readAsStringSync();
          final decoder = NQuadsDecoder();
          decoder.convert(input, documentUrl: tc.baseUri);
        });
      }
    });

    group('Negative syntax tests (${negativeSyntaxTests.length})', () {
      for (final tc in negativeSyntaxTests) {
        test(tc.name, () {
          final input = File(tc.actionPath).readAsStringSync();
          final decoder = NQuadsDecoder();
          expect(
            () => decoder.convert(input, documentUrl: tc.baseUri),
            throwsA(isA<Exception>()),
            reason: 'Expected parse error for ${tc.name}',
          );
        });
      }
    });
  });
}
