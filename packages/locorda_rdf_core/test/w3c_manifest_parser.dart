import 'dart:io';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/vocab/rdf.dart';

/// Types of W3C RDF test cases.
enum W3cTestType {
  turtleEval,
  turtlePositiveSyntax,
  turtleNegativeSyntax,
  turtleNegativeEval,
  trigEval,
  trigPositiveSyntax,
  trigNegativeSyntax,
  trigNegativeEval,
}

/// A single W3C test case parsed from a manifest.ttl file.
class W3cTestCase {
  final String name;
  final W3cTestType type;

  /// Absolute filesystem path to the input file (.ttl or .trig).
  final String actionPath;

  /// Absolute filesystem path to the expected output file (.nt or .nq).
  /// Null for syntax-only tests (positive/negative syntax).
  final String? resultPath;

  /// The base URI to use when parsing the input file, derived from
  /// `mf:assumedTestBase` + the action file name.
  final String baseUri;

  const W3cTestCase({
    required this.name,
    required this.type,
    required this.actionPath,
    this.resultPath,
    required this.baseUri,
  });

  @override
  String toString() => 'W3cTestCase($name, $type)';
}

// Manifest vocabulary IRIs
const _mfEntries =
    IriTerm('http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#entries');
const _mfName =
    IriTerm('http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#name');
const _mfAction =
    IriTerm('http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#action');
const _mfResult =
    IriTerm('http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#result');
const _mfAssumedTestBase = IriTerm(
    'http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#assumedTestBase');

const _rdftTestTurtleEval =
    IriTerm('http://www.w3.org/ns/rdftest#TestTurtleEval');
const _rdftTestTurtlePositiveSyntax =
    IriTerm('http://www.w3.org/ns/rdftest#TestTurtlePositiveSyntax');
const _rdftTestTurtleNegativeSyntax =
    IriTerm('http://www.w3.org/ns/rdftest#TestTurtleNegativeSyntax');
const _rdftTestTurtleNegativeEval =
    IriTerm('http://www.w3.org/ns/rdftest#TestTurtleNegativeEval');
const _rdftTestTrigEval =
    IriTerm('http://www.w3.org/ns/rdftest#TestTrigEval');
const _rdftTestTrigPositiveSyntax =
    IriTerm('http://www.w3.org/ns/rdftest#TestTrigPositiveSyntax');
const _rdftTestTrigNegativeSyntax =
    IriTerm('http://www.w3.org/ns/rdftest#TestTrigNegativeSyntax');
const _rdftTestTrigNegativeEval =
    IriTerm('http://www.w3.org/ns/rdftest#TestTrigNegativeEval');

final _testTypeMap = <IriTerm, W3cTestType>{
  _rdftTestTurtleEval: W3cTestType.turtleEval,
  _rdftTestTurtlePositiveSyntax: W3cTestType.turtlePositiveSyntax,
  _rdftTestTurtleNegativeSyntax: W3cTestType.turtleNegativeSyntax,
  _rdftTestTurtleNegativeEval: W3cTestType.turtleNegativeEval,
  _rdftTestTrigEval: W3cTestType.trigEval,
  _rdftTestTrigPositiveSyntax: W3cTestType.trigPositiveSyntax,
  _rdftTestTrigNegativeSyntax: W3cTestType.trigNegativeSyntax,
  _rdftTestTrigNegativeEval: W3cTestType.trigNegativeEval,
};

/// Parses a W3C manifest.ttl file and returns structured test cases.
///
/// Uses our own [TurtleDecoder] to parse the manifest (bootstrap approach).
/// Traverses `mf:entries` RDF lists via `rdf:first`/`rdf:rest`/`rdf:nil`.
///
/// [manifestPath] is the filesystem path to the manifest.ttl file.
/// The directory containing the manifest is used to resolve relative file
/// references in `mf:action` and `mf:result`.
List<W3cTestCase> parseW3cManifest(String manifestPath) {
  final manifestFile = File(manifestPath);
  final manifestContent = manifestFile.readAsStringSync();
  final manifestDir = manifestFile.parent.path;

  // The manifest document URL is its own location as a file URI,
  // so relative IRIs in the manifest resolve correctly.
  final documentUrl = Uri.file(manifestFile.absolute.path).toString();

  final decoder = TurtleDecoder(
    namespaceMappings: RdfNamespaceMappings(),
  );
  final graph = decoder.convert(manifestContent, documentUrl: documentUrl);

  // Extract the assumed test base URI (used as base URI when parsing test files).
  final assumedTestBase = _singleObject(graph, predicate: _mfAssumedTestBase);
  final testBaseUri =
      assumedTestBase is IriTerm ? assumedTestBase.value : null;

  // Find the mf:entries list head.
  final entriesTriples = graph.findTriples(predicate: _mfEntries);
  if (entriesTriples.isEmpty) {
    throw StateError('No mf:entries found in manifest: $manifestPath');
  }
  final listHead = entriesTriples.first.object;

  // Traverse the RDF list to collect test entry IRIs.
  final testIris = _traverseRdfList(graph, listHead);

  // Build W3cTestCase for each entry.
  final testCases = <W3cTestCase>[];
  for (final testIri in testIris) {
    if (testIri is! RdfSubject) continue;

    final typeTriples =
        graph.findTriples(subject: testIri, predicate: Rdf.type);
    if (typeTriples.isEmpty) continue;

    final testType = _testTypeMap[typeTriples.first.object];
    if (testType == null) continue; // Not a recognized test type

    final nameObj =
        _singleObject(graph, subject: testIri, predicate: _mfName);
    final name = nameObj is LiteralTerm ? nameObj.value : testIri.toString();

    final actionObj =
        _singleObject(graph, subject: testIri, predicate: _mfAction);
    if (actionObj is! IriTerm) continue; // Action is required

    final resultObj =
        _singleObject(graph, subject: testIri, predicate: _mfResult);

    // Resolve file:// URIs to filesystem paths.
    final actionPath = _resolveToFilePath(actionObj.value, manifestDir);
    final resultPath = resultObj is IriTerm
        ? _resolveToFilePath(resultObj.value, manifestDir)
        : null;

    // Build the test base URI: assumedTestBase + action filename
    final actionFileName = Uri.parse(actionObj.value).pathSegments.last;
    final baseUri = testBaseUri != null
        ? '$testBaseUri$actionFileName'
        : actionObj.value;

    testCases.add(W3cTestCase(
      name: name,
      type: testType,
      actionPath: actionPath,
      resultPath: resultPath,
      baseUri: baseUri,
    ));
  }

  return testCases;
}

/// Traverses an RDF list (rdf:first/rdf:rest chain) starting at [head],
/// collecting all rdf:first values.
List<RdfObject> _traverseRdfList(RdfGraph graph, RdfObject head) {
  final items = <RdfObject>[];
  var current = head;

  while (current != Rdf.nil) {
    if (current is! RdfSubject) break;

    final firstTriples =
        graph.findTriples(subject: current, predicate: Rdf.first);
    if (firstTriples.isEmpty) break;
    items.add(firstTriples.first.object);

    final restTriples =
        graph.findTriples(subject: current, predicate: Rdf.rest);
    if (restTriples.isEmpty) break;
    current = restTriples.first.object;
  }

  return items;
}

/// Returns the single object for a given subject+predicate, or null.
RdfObject? _singleObject(RdfGraph graph,
    {RdfSubject? subject, required RdfPredicate predicate}) {
  final triples = graph.findTriples(subject: subject, predicate: predicate);
  return triples.isEmpty ? null : triples.first.object;
}

/// Converts a file:// URI or relative URI to a filesystem path,
/// relative to the manifest directory.
String _resolveToFilePath(String iri, String manifestDir) {
  final uri = Uri.parse(iri);
  if (uri.scheme == 'file') {
    return uri.toFilePath();
  }
  // For relative IRIs that were resolved against the manifest's file:// URL,
  // the result is a file:// URI.
  if (uri.isAbsolute && uri.scheme == 'file') {
    return uri.toFilePath();
  }
  // Fallback: treat as relative path from manifest directory
  return '$manifestDir/${uri.path}';
}
