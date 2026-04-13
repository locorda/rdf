import 'dart:convert';
import 'dart:io';

import 'package:locorda_rdf_canonicalization/canonicalization.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';
import 'package:test/test.dart';

/// W3C official JSON-LD toRdf test suite.
///
/// Runs all tests from the W3C JSON-LD API toRdf test suite manifest.
/// Test data is provided via the w3c/json-ld-api git submodule.
///
/// The manifest is parsed using our own [JsonLdDecoder] with external context
/// loading via decoder options.
void main() {
  final manifestPath =
      '../../test_assets/w3c/json-ld-api/tests/toRdf-manifest.jsonld';
  final testsDir = '../../test_assets/w3c/json-ld-api/tests';

  if (!File(manifestPath).existsSync()) {
    print('W3C JSON-LD test suite not found at $manifestPath');
    print('Run: git submodule update --init --recursive');
    return;
  }

  final testCases = _parseManifestWithDecoder(manifestPath, testsDir);
  final baseIri = 'https://w3c.github.io/json-ld-api/tests/';
  final testsDirUri = Directory(testsDir).absolute.uri.toString();

  group('W3C JSON-LD toRdf Test Suite', () {
    // Skip tests requiring GeneralizedRdf — our RdfPredicate is sealed to
    // IriTerm only, so blank node predicates are not representable.
    const unsupportedRequires = {'GeneralizedRdf'};
    final supported = testCases
        .where((t) => !unsupportedRequires.contains(t.options.requires));
    final skipped = testCases
        .where((t) => unsupportedRequires.contains(t.options.requires));
    for (final tc in skipped) {
      test(tc.name, skip: 'Requires ${tc.options.requires}', () {});
    }

    final positiveTests =
        supported.where((t) => t.type == _JsonLdTestType.positiveEval);
    final negativeTests =
        supported.where((t) => t.type == _JsonLdTestType.negativeEval);
    final syntaxTests =
        supported.where((t) => t.type == _JsonLdTestType.positiveSyntax);

    group('Positive eval tests (${positiveTests.length})', () {
      for (final tc in positiveTests) {
        test(tc.name, () {
          final input = File(tc.inputPath).readAsStringSync();
          final expected = File(tc.expectPath!).readAsStringSync();

          final documentUrl = '$baseIri${tc.inputRelative}';

          final decoder = JsonLdDecoder(
            options: JsonLdDecoderOptions(
              contextDocumentProvider: MappedFileJsonLdContextDocumentProvider(
                iriPrefixMappings: {baseIri: testsDirUri},
              ),
              baseIri: tc.options.baseIri,
              expandContext: tc.options.expandContext,
              rdfDirection: tc.options.rdfDirection,
              processingMode: tc.options.processingMode,
              skipInvalidRdfTerms: true,
            ),
          );
          final nquadsDecoder = NQuadsDecoder();

          final actualDataset =
              decoder.convert(input, documentUrl: documentUrl);
          final expectedDataset = nquadsDecoder.convert(expected);

          expect(
            isIsomorphic(actualDataset, expectedDataset),
            isTrue,
            reason: 'Dataset mismatch for ${tc.name}\n'
                'Actual default graph triples: ${actualDataset.defaultGraph.triples.length}\n'
                'Expected default graph triples: ${expectedDataset.defaultGraph.triples.length}\n'
                'Actual named graphs: ${actualDataset.namedGraphs.length}\n'
                'Expected named graphs: ${expectedDataset.namedGraphs.length}',
          );
        });
      }
    });

    group('Negative eval tests (${negativeTests.length})', () {
      for (final tc in negativeTests) {
        test(tc.name, () {
          final input = File(tc.inputPath).readAsStringSync();
          final documentUrl = '$baseIri${tc.inputRelative}';
          final decoder = JsonLdDecoder(
            options: JsonLdDecoderOptions(
              contextDocumentProvider: MappedFileJsonLdContextDocumentProvider(
                iriPrefixMappings: {baseIri: testsDirUri},
              ),
              baseIri: tc.options.baseIri,
              expandContext: tc.options.expandContext,
              rdfDirection: tc.options.rdfDirection,
              processingMode: tc.options.processingMode,
              skipInvalidRdfTerms: true,
            ),
          );

          expect(
            () => decoder.convert(input, documentUrl: documentUrl),
            throwsA(isA<Exception>()),
            reason: 'Expected error for ${tc.name}: ${tc.expectErrorCode}',
          );
        });
      }
    });

    group('Positive syntax tests (${syntaxTests.length})', () {
      for (final tc in syntaxTests) {
        test(tc.name, () {
          final input = File(tc.inputPath).readAsStringSync();
          final documentUrl = '$baseIri${tc.inputRelative}';
          final decoder = JsonLdDecoder(
            options: JsonLdDecoderOptions(
              contextDocumentProvider: MappedFileJsonLdContextDocumentProvider(
                iriPrefixMappings: {baseIri: testsDirUri},
              ),
              baseIri: tc.options.baseIri,
              expandContext: tc.options.expandContext,
              rdfDirection: tc.options.rdfDirection,
              processingMode: tc.options.processingMode,
              skipInvalidRdfTerms: true,
            ),
          );

          // Should parse without throwing
          decoder.convert(input, documentUrl: documentUrl);
        });
      }
    });
  });
}

// --- Manifest parsing using our own JsonLdDecoder ---

enum _JsonLdTestType { positiveEval, negativeEval, positiveSyntax }

class _JsonLdTestCase {
  final String id;
  final String name;
  final _JsonLdTestType type;
  final String inputPath;
  final String inputRelative;
  final String? expectPath;
  final String? expectErrorCode;
  final _JsonLdTestOptions options;

  const _JsonLdTestCase({
    required this.id,
    required this.name,
    required this.type,
    required this.inputPath,
    required this.inputRelative,
    this.expectPath,
    this.expectErrorCode,
    this.options = const _JsonLdTestOptions(),
  });
}

class _JsonLdTestOptions {
  final String? baseIri;
  final String? expandContext;
  final String? rdfDirection;
  final String processingMode;
  final String? requires;

  const _JsonLdTestOptions({
    this.baseIri,
    this.expandContext,
    this.rdfDirection,
    this.processingMode = 'json-ld-1.1',
    this.requires,
  });
}

const _mf = 'http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#';
const _vocab = 'https://w3c.github.io/json-ld-api/tests/vocab#';
const _rdfType = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';
const _rdfFirst = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#first';
const _rdfRest = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#rest';
const _rdfNil = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#nil';

/// Parses the W3C manifest using our [JsonLdDecoder].
List<_JsonLdTestCase> _parseManifestWithDecoder(
    String manifestPath, String testsDir) {
  final baseIri = 'https://w3c.github.io/json-ld-api/tests/';
  final testsDirUri = Directory(testsDir).absolute.uri.toString();
  final manifestStr = File(manifestPath).readAsStringSync();
  final documentUrl = '${baseIri}toRdf-manifest.jsonld';
  final manifestOptionsById =
      _extractManifestOptionsById(manifestStr, documentUrl);
  final dataset = JsonLdDecoder(
    options: JsonLdDecoderOptions(
      contextDocumentProvider: MappedFileJsonLdContextDocumentProvider(
        iriPrefixMappings: {baseIri: testsDirUri},
      ),
    ),
  ).convert(manifestStr, documentUrl: documentUrl);
  final graph = dataset.defaultGraph;

  // Walk the RDF list at mf:entries
  final entriesTriples = graph.findTriples(
    predicate: IriTerm('${_mf}entries'),
  );
  if (entriesTriples.isEmpty) return [];

  final listHead = entriesTriples.first.object;
  final testEntries = _walkRdfList(graph, listHead);

  final testCases = <_JsonLdTestCase>[];
  for (final entry in testEntries) {
    if (entry is! IriTerm) continue;
    final entryIri = entry.value;

    // Get types
    final types = graph
        .findTriples(subject: entry, predicate: IriTerm(_rdfType))
        .map((t) => t.object)
        .whereType<IriTerm>()
        .map((iri) => iri.value)
        .toSet();

    _JsonLdTestType? testType;
    if (types.contains('${_vocab}PositiveEvaluationTest')) {
      testType = _JsonLdTestType.positiveEval;
    } else if (types.contains('${_vocab}NegativeEvaluationTest')) {
      testType = _JsonLdTestType.negativeEval;
    } else if (types.contains('${_vocab}PositiveSyntaxTest')) {
      testType = _JsonLdTestType.positiveSyntax;
    }
    if (testType == null) continue;

    // Get name
    final nameTriples =
        graph.findTriples(subject: entry, predicate: IriTerm('${_mf}name'));
    final name = nameTriples.isNotEmpty
        ? (nameTriples.first.object as LiteralTerm).value
        : entryIri;

    // Get input (mf:action, coerced to IRI)
    final inputTriples =
        graph.findTriples(subject: entry, predicate: IriTerm('${_mf}action'));
    if (inputTriples.isEmpty) continue;
    final inputIri = (inputTriples.first.object as IriTerm).value;
    final inputRelative = inputIri.startsWith(baseIri)
        ? inputIri.substring(baseIri.length)
        : inputIri;
    final inputPath = '$testsDir/$inputRelative';
    if (!File(inputPath).existsSync()) continue;

    // Get expected result (mf:result, coerced to IRI)
    String? expectPath;
    final expectTriples =
        graph.findTriples(subject: entry, predicate: IriTerm('${_mf}result'));
    if (expectTriples.isNotEmpty) {
      final obj = expectTriples.first.object;
      if (obj is IriTerm) {
        final expectIri = obj.value;
        final expectRelative = expectIri.startsWith(baseIri)
            ? expectIri.substring(baseIri.length)
            : expectIri;
        expectPath = '$testsDir/$expectRelative';
      } else if (obj is LiteralTerm) {
        // Negative eval: expectErrorCode is stored as literal
      }
    }

    // Get expectErrorCode (for negative eval, mf:result is a literal)
    String? expectErrorCode;
    if (testType == _JsonLdTestType.negativeEval && expectTriples.isNotEmpty) {
      final obj = expectTriples.first.object;
      if (obj is LiteralTerm) {
        expectErrorCode = obj.value;
      }
    }

    testCases.add(_JsonLdTestCase(
      id: entryIri,
      name: name,
      type: testType,
      inputPath: inputPath,
      inputRelative: inputRelative,
      expectPath: expectPath,
      expectErrorCode: expectErrorCode,
      options: manifestOptionsById[inputRelative] ??
          manifestOptionsById[entryIri] ??
          manifestOptionsById[name] ??
          const _JsonLdTestOptions(),
    ));
  }

  return testCases;
}

Map<String, _JsonLdTestOptions> _extractManifestOptionsById(
  String manifestStr,
  String documentUrl,
) {
  final manifest = jsonDecode(manifestStr);
  if (manifest is! Map<String, dynamic>) {
    return const {};
  }

  final sequence = manifest['sequence'];
  if (sequence is! List<dynamic>) {
    return const {};
  }

  final optionsById = <String, _JsonLdTestOptions>{};
  for (final item in sequence) {
    if (item is! Map<String, dynamic>) {
      continue;
    }

    final rawId = item['@id'];
    final rawName = item['name'];
    final rawInput = item['input'];
    final option = item['option'];
    final requires = item['requires'] as String?;
    if (rawId is! String || option is! Map<String, dynamic>) {
      continue;
    }

    final parsedOptions = _JsonLdTestOptions(
      baseIri: option['base'] as String?,
      expandContext: option['expandContext'] is String
          ? Uri.parse(documentUrl)
              .resolve(option['expandContext'] as String)
              .toString()
          : null,
      rdfDirection: option['rdfDirection'] as String?,
      processingMode: option['processingMode'] as String? ??
          option['specVersion'] as String? ??
          'json-ld-1.1',
      requires: requires,
    );
    final resolvedId = Uri.parse(documentUrl).resolve(rawId).toString();
    optionsById[resolvedId] = parsedOptions;
    if (rawInput is String) {
      optionsById[rawInput] = parsedOptions;
      final resolvedInput = Uri.parse(documentUrl).resolve(rawInput).toString();
      const baseIri = 'https://w3c.github.io/json-ld-api/tests/';
      if (resolvedInput.startsWith(baseIri)) {
        optionsById[resolvedInput.substring(baseIri.length)] = parsedOptions;
      }
    }
    if (rawName is String) {
      optionsById[rawName] = parsedOptions;
    }
  }

  return optionsById;
}

/// Walks an RDF list (rdf:first/rdf:rest chain) and returns the items.
List<RdfTerm> _walkRdfList(RdfGraph graph, RdfTerm head) {
  final items = <RdfTerm>[];
  var current = head;
  final visited = <RdfTerm>{};

  while (current is! IriTerm || current.value != _rdfNil) {
    if (visited.contains(current)) break; // cycle protection
    visited.add(current);

    final firstTriples = graph.findTriples(
        subject: current as RdfSubject, predicate: IriTerm(_rdfFirst));
    if (firstTriples.isEmpty) break;
    items.add(firstTriples.first.object);

    final restTriples =
        graph.findTriples(subject: current, predicate: IriTerm(_rdfRest));
    if (restTriples.isEmpty) break;
    current = restTriples.first.object;
  }

  return items;
}
