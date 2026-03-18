import 'dart:io';

import 'package:locorda_rdf_canonicalization/canonicalization.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/vocab/rdf.dart';
import 'package:locorda_rdf_xml/xml.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// W3C official RDF/XML test suite.
///
/// Runs all tests from the W3C RDF 1.1 RDF/XML test suite manifest.
/// Test data is provided via the w3c/rdf-tests git submodule.
void main() {
  final manifestPath =
      '../../test_assets/w3c/rdf-tests/rdf/rdf11/rdf-xml/manifest.ttl';

  if (!File(manifestPath).existsSync()) {
    print('W3C test suite not found at $manifestPath');
    print('Run: git submodule update --init --recursive');
    return;
  }

  final testCases = _parseW3cRdfXmlManifest(manifestPath);

  group('W3C RDF/XML Test Suite', () {
    final evalTests = testCases.where((t) => t.type == _W3cXmlTestType.eval);
    final negativeSyntaxTests = testCases.where(
      (t) => t.type == _W3cXmlTestType.negativeSyntax,
    );

    group('Eval tests (${evalTests.length})', () {
      for (final tc in evalTests) {
        test(tc.name, () {
          final input = File(tc.actionPath).readAsStringSync();
          final expected = File(tc.resultPath!).readAsStringSync();

          final actualGraph = RdfXmlCodec.strict().decode(
            input,
            documentUrl: tc.baseUri,
          );
          final expectedGraph = NTriplesDecoder().convert(expected);

          expect(
            isIsomorphicGraphs(actualGraph, expectedGraph),
            isTrue,
            reason:
                'Graph mismatch for ${tc.name}\n'
                'Actual triples: ${actualGraph.triples.length}\n'
                'Expected triples: ${expectedGraph.triples.length}',
          );
        });
      }
    });

    group('Negative syntax tests (${negativeSyntaxTests.length})', () {
      for (final tc in negativeSyntaxTests) {
        test(tc.name, () {
          final input = File(tc.actionPath).readAsStringSync();
          expect(
            () => RdfXmlCodec.strict().decode(input, documentUrl: tc.baseUri),
            throwsA(isA<Exception>()),
            reason: 'Expected parse error for ${tc.name}',
          );
        });
      }
    });
  });
}

enum _W3cXmlTestType { eval, negativeSyntax }

class _W3cXmlTestCase {
  final String name;
  final _W3cXmlTestType type;
  final String actionPath;
  final String? resultPath;
  final String baseUri;

  const _W3cXmlTestCase({
    required this.name,
    required this.type,
    required this.actionPath,
    this.resultPath,
    required this.baseUri,
  });
}

const _mfEntries = IriTerm(
  'http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#entries',
);
const _mfName = IriTerm(
  'http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#name',
);
const _mfAction = IriTerm(
  'http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#action',
);
const _mfResult = IriTerm(
  'http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#result',
);
const _mfAssumedTestBase = IriTerm(
  'http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#assumedTestBase',
);

const _rdftTestXmlEval = IriTerm('http://www.w3.org/ns/rdftest#TestXMLEval');
const _rdftTestXmlNegativeSyntax = IriTerm(
  'http://www.w3.org/ns/rdftest#TestXMLNegativeSyntax',
);

List<_W3cXmlTestCase> _parseW3cRdfXmlManifest(String manifestPath) {
  final manifestFile = File(manifestPath);
  final manifestContent = manifestFile.readAsStringSync();
  final manifestDir = manifestFile.parent.path;
  final documentUrl = Uri.file(manifestFile.absolute.path).toString();

  final graph = TurtleDecoder(
    namespaceMappings: RdfNamespaceMappings(),
  ).convert(manifestContent, documentUrl: documentUrl);

  final assumedTestBase =
      _singleObject(graph, predicate: _mfAssumedTestBase) as IriTerm?;

  final entriesTriples = graph.findTriples(predicate: _mfEntries);
  if (entriesTriples.isEmpty) {
    throw StateError('No mf:entries found in manifest: $manifestPath');
  }

  final testIris = _traverseRdfList(graph, entriesTriples.first.object);
  final testCases = <_W3cXmlTestCase>[];

  for (final testIri in testIris) {
    if (testIri is! RdfSubject) continue;

    final typeObj = _singleObject(graph, subject: testIri, predicate: Rdf.type);
    final type = switch (typeObj) {
      _rdftTestXmlEval => _W3cXmlTestType.eval,
      _rdftTestXmlNegativeSyntax => _W3cXmlTestType.negativeSyntax,
      _ => null,
    };
    if (type == null) continue;

    final actionObj = _singleObject(
      graph,
      subject: testIri,
      predicate: _mfAction,
    );
    if (actionObj is! IriTerm) continue;

    final resultObj = _singleObject(
      graph,
      subject: testIri,
      predicate: _mfResult,
    );
    final nameObj = _singleObject(graph, subject: testIri, predicate: _mfName);

    final actionPath = _resolveToFilePath(actionObj.value, manifestDir);
    final resultPath =
        resultObj is IriTerm
            ? _resolveToFilePath(resultObj.value, manifestDir)
            : null;

    final baseUri =
        assumedTestBase != null
            ? Uri.parse(assumedTestBase.value)
                .resolve(
                  p
                      .relative(actionPath, from: manifestDir)
                      .replaceAll('\\', '/'),
                )
                .toString()
            : actionObj.value;

    testCases.add(
      _W3cXmlTestCase(
        name: nameObj is LiteralTerm ? nameObj.value : testIri.toString(),
        type: type,
        actionPath: actionPath,
        resultPath: resultPath,
        baseUri: baseUri,
      ),
    );
  }

  return testCases;
}

List<RdfObject> _traverseRdfList(RdfGraph graph, RdfObject head) {
  final items = <RdfObject>[];
  var current = head;

  while (current != Rdf.nil) {
    if (current is! RdfSubject) break;

    final first = graph.findTriples(subject: current, predicate: Rdf.first);
    if (first.isEmpty) break;
    items.add(first.first.object);

    final rest = graph.findTriples(subject: current, predicate: Rdf.rest);
    if (rest.isEmpty) break;
    current = rest.first.object;
  }

  return items;
}

RdfObject? _singleObject(
  RdfGraph graph, {
  RdfSubject? subject,
  required RdfPredicate predicate,
}) {
  final triples = graph.findTriples(subject: subject, predicate: predicate);
  return triples.isEmpty ? null : triples.first.object;
}

String _resolveToFilePath(String iri, String manifestDir) {
  final uri = Uri.parse(iri);
  if (uri.scheme == 'file') {
    return uri.toFilePath();
  }
  if (uri.isAbsolute && uri.scheme == 'file') {
    return uri.toFilePath();
  }
  return '$manifestDir/${uri.path}';
}
