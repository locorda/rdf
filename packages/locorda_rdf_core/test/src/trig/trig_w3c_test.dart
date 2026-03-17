import 'dart:io';

import 'package:locorda_rdf_canonicalization/canonicalization.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

import '../../w3c_manifest_parser.dart';

/// W3C official TriG test suite.
///
/// Runs all tests from the W3C RDF 1.1 TriG test suite manifest.
/// Test data is provided via the w3c/rdf-tests git submodule.
void main() {
  final manifestPath =
      'test_assets/w3c/rdf-tests/rdf/rdf11/rdf-trig/manifest.ttl';

  if (!File(manifestPath).existsSync()) {
    print('W3C test suite not found at $manifestPath');
    print('Run: git submodule update --init --recursive');
    return;
  }

  final testCases = parseW3cManifest(manifestPath);

  group('W3C TriG Test Suite', () {
    final evalTests =
        testCases.where((t) => t.type == W3cTestType.trigEval);
    final positiveSyntaxTests =
        testCases.where((t) => t.type == W3cTestType.trigPositiveSyntax);
    final negativeSyntaxTests =
        testCases.where((t) => t.type == W3cTestType.trigNegativeSyntax);
    final negativeEvalTests =
        testCases.where((t) => t.type == W3cTestType.trigNegativeEval);

    group('Eval tests (${evalTests.length})', () {
      for (final tc in evalTests) {
        test(tc.name, () {
          final input = File(tc.actionPath).readAsStringSync();
          final expected = File(tc.resultPath!).readAsStringSync();

          final trigDecoder = TriGDecoder(
            namespaceMappings: RdfNamespaceMappings(),
          );
          final nquadsDecoder = NQuadsDecoder();

          final actualDataset =
              trigDecoder.convert(input, documentUrl: tc.baseUri);
          final expectedDataset = nquadsDecoder.convert(expected);

          expect(
            isIsomorphic(actualDataset, expectedDataset),
            isTrue,
            reason:
                'Dataset mismatch for ${tc.name}\n'
                'Actual default graph triples: ${actualDataset.defaultGraph.triples.length}\n'
                'Expected default graph triples: ${expectedDataset.defaultGraph.triples.length}\n'
                'Actual named graphs: ${actualDataset.namedGraphs.length}\n'
                'Expected named graphs: ${expectedDataset.namedGraphs.length}',
          );
        });
      }
    });

    group('Positive syntax tests (${positiveSyntaxTests.length})', () {
      for (final tc in positiveSyntaxTests) {
        test(tc.name, () {
          final input = File(tc.actionPath).readAsStringSync();
          final decoder = TriGDecoder(
            namespaceMappings: RdfNamespaceMappings(),
          );
          // Should parse without throwing
          decoder.convert(input, documentUrl: tc.baseUri);
        });
      }
    });

    group('Negative syntax tests (${negativeSyntaxTests.length})', () {
      for (final tc in negativeSyntaxTests) {
        test(tc.name, () {
          final input = File(tc.actionPath).readAsStringSync();
          final decoder = TriGDecoder(
            namespaceMappings: RdfNamespaceMappings(),
          );
          expect(
            () => decoder.convert(input, documentUrl: tc.baseUri),
            throwsA(isA<Exception>()),
            reason: 'Expected parse error for ${tc.name}',
          );
        });
      }
    });

    group('Negative eval tests (${negativeEvalTests.length})', () {
      for (final tc in negativeEvalTests) {
        test(tc.name, () {
          final input = File(tc.actionPath).readAsStringSync();
          final decoder = TriGDecoder(
            namespaceMappings: RdfNamespaceMappings(),
          );
          expect(
            () => decoder.convert(input, documentUrl: tc.baseUri),
            throwsA(isA<Exception>()),
            reason: 'Expected eval error for ${tc.name}',
          );
        });
      }
    });
  });
}
