/// Parses the Jelly conformance test manifest.ttl into structured test cases.
///
/// Uses the project's own TurtleDecoder (bootstrap approach, same as the W3C
/// test suites in locorda_rdf_core).
library;

import 'dart:io';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/vocab/rdf.dart';

/// Whether a Jelly test case expects success or failure.
enum JellyTestKind { positive, negative }

/// Physical stream type that a test requires.
enum JellyPhysicalType { triples, quads, graphs }

/// A single Jelly conformance test case parsed from the manifest.
class JellyTestCase {
  final String name;
  final JellyTestKind kind;
  final JellyPhysicalType physicalType;

  /// Absolute filesystem path to the input .jelly file.
  final String actionPath;

  /// Absolute filesystem paths to expected output files (.nt or .nq),
  /// one per frame. Empty for negative tests.
  final List<String> resultPaths;

  const JellyTestCase({
    required this.name,
    required this.kind,
    required this.physicalType,
    required this.actionPath,
    required this.resultPaths,
  });

  @override
  String toString() => 'JellyTestCase($name, $kind)';
}

// Jelly test vocabulary
const _jellytTestPositive =
    IriTerm('https://w3id.org/jelly/dev/tests/vocab#TestPositive');
const _jellytTestNegative =
    IriTerm('https://w3id.org/jelly/dev/tests/vocab#TestNegative');

const _jellytRequirementTriples = IriTerm(
    'https://w3id.org/jelly/dev/tests/vocab#requirementPhysicalTypeTriples');
const _jellytRequirementQuads = IriTerm(
    'https://w3id.org/jelly/dev/tests/vocab#requirementPhysicalTypeQuads');
const _jellytRequirementGraphs = IriTerm(
    'https://w3id.org/jelly/dev/tests/vocab#requirementPhysicalTypeGraphs');
const _jellytRequirementRdfStar =
    IriTerm('https://w3id.org/jelly/dev/tests/vocab#requirementRdfStar');
const _jellytRequirementGeneralizedRdf =
    IriTerm('https://w3id.org/jelly/dev/tests/vocab#requirementGeneralizedRdf');

// Standard manifest vocabulary
const _mfEntries =
    IriTerm('http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#entries');
const _mfName =
    IriTerm('http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#name');
const _mfAction =
    IriTerm('http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#action');
const _mfResult =
    IriTerm('http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#result');
const _mfRequires = IriTerm(
    'http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#requires');

/// Parses the Jelly from_jelly manifest.ttl and returns RDF 1.1 test cases.
///
/// Skips tests that require RDF-star or generalized RDF support.
List<JellyTestCase> parseJellyManifest(String manifestPath) {
  final manifestFile = File(manifestPath);
  final manifestContent = manifestFile.readAsStringSync();
  final manifestDir = manifestFile.parent.path;

  final documentUrl = Uri.file(manifestFile.absolute.path).toString();

  final decoder = TurtleDecoder(
    namespaceMappings: RdfNamespaceMappings(),
  );
  final graph = decoder.convert(manifestContent, documentUrl: documentUrl);

  // Traverse mf:entries list
  final entriesTriples = graph.findTriples(predicate: _mfEntries);
  if (entriesTriples.isEmpty) {
    throw StateError('No mf:entries found in manifest: $manifestPath');
  }
  final testIris = _traverseRdfList(graph, entriesTriples.first.object);

  final testCases = <JellyTestCase>[];
  for (final testIri in testIris) {
    if (testIri is! RdfSubject) continue;

    // Determine test kind (positive/negative)
    final typeTriples =
        graph.findTriples(subject: testIri, predicate: Rdf.type);
    final types = typeTriples.map((t) => t.object).toSet();

    JellyTestKind? kind;
    if (types.contains(_jellytTestPositive)) {
      kind = JellyTestKind.positive;
    } else if (types.contains(_jellytTestNegative)) {
      kind = JellyTestKind.negative;
    }
    if (kind == null) continue;

    // Check requirements — skip RDF-star and generalized RDF
    final requiresTriples =
        graph.findTriples(subject: testIri, predicate: _mfRequires);
    final requirements = requiresTriples.map((t) => t.object).toSet();
    if (requirements.contains(_jellytRequirementRdfStar)) continue;
    if (requirements.contains(_jellytRequirementGeneralizedRdf)) continue;

    // Determine physical type
    JellyPhysicalType? physicalType;
    if (requirements.contains(_jellytRequirementTriples)) {
      physicalType = JellyPhysicalType.triples;
    } else if (requirements.contains(_jellytRequirementQuads)) {
      physicalType = JellyPhysicalType.quads;
    } else if (requirements.contains(_jellytRequirementGraphs)) {
      physicalType = JellyPhysicalType.graphs;
    }
    if (physicalType == null) continue;

    // Test name
    final nameObj = _singleObject(graph, subject: testIri, predicate: _mfName);
    final name = nameObj is LiteralTerm ? nameObj.value : testIri.toString();

    // Action (input file)
    final actionObj =
        _singleObject(graph, subject: testIri, predicate: _mfAction);
    if (actionObj is! IriTerm) continue;
    final actionPath = _resolveToFilePath(actionObj.value, manifestDir);

    // Result (output files) — may be a single IRI or an RDF list
    final resultPaths = <String>[];
    if (kind == JellyTestKind.positive) {
      final resultObj =
          _singleObject(graph, subject: testIri, predicate: _mfResult);
      if (resultObj is IriTerm) {
        // Single output file
        resultPaths.add(_resolveToFilePath(resultObj.value, manifestDir));
      } else if (resultObj != null) {
        // RDF list of output files (multi-frame)
        final items = _traverseRdfList(graph, resultObj);
        for (final item in items) {
          if (item is IriTerm) {
            resultPaths.add(_resolveToFilePath(item.value, manifestDir));
          }
        }
      }
    }

    testCases.add(JellyTestCase(
      name: name,
      kind: kind,
      physicalType: physicalType,
      actionPath: actionPath,
      resultPaths: resultPaths,
    ));
  }

  return testCases;
}

// ---------------------------------------------------------------------------
// EARL conformance report support
// ---------------------------------------------------------------------------

/// A lightweight test entry for EARL reporting that includes ALL tests
/// (RDF-star and generalized included, unlike the filtered parsers above).
class ManifestTestEntry {
  /// Canonical test IRI from the manifest (w3id.org base).
  final String testIri;
  final String name;
  final bool requiresRdfStar;
  final bool requiresGeneralizedRdf;

  const ManifestTestEntry({
    required this.testIri,
    required this.name,
    required this.requiresRdfStar,
    required this.requiresGeneralizedRdf,
  });
}

/// Parses ALL test entries from a Jelly manifest without filtering.
///
/// Unlike [parseJellyManifest] and [parseJellyToJellyManifest], this
/// includes RDF-star and generalized RDF tests — needed for EARL reports
/// where unsupported tests must be listed as `earl:inapplicable`.
List<ManifestTestEntry> parseAllManifestTestEntries(String manifestPath) {
  final manifestFile = File(manifestPath);
  final manifestContent = manifestFile.readAsStringSync();

  final documentUrl = Uri.file(manifestFile.absolute.path).toString();

  final decoder = TurtleDecoder(
    namespaceMappings: RdfNamespaceMappings(),
  );
  final graph = decoder.convert(manifestContent, documentUrl: documentUrl);

  final entriesTriples = graph.findTriples(predicate: _mfEntries);
  if (entriesTriples.isEmpty) {
    throw StateError('No mf:entries found in manifest: $manifestPath');
  }
  final testIris = _traverseRdfList(graph, entriesTriples.first.object);

  final entries = <ManifestTestEntry>[];
  for (final testIri in testIris) {
    if (testIri is! RdfSubject) continue;

    // Determine test kind — skip entries that aren't positive or negative
    final typeTriples =
        graph.findTriples(subject: testIri, predicate: Rdf.type);
    final types = typeTriples.map((t) => t.object).toSet();
    if (!types.contains(_jellytTestPositive) &&
        !types.contains(_jellytTestNegative)) {
      continue;
    }

    // Check requirements
    final requiresTriples =
        graph.findTriples(subject: testIri, predicate: _mfRequires);
    final requirements = requiresTriples.map((t) => t.object).toSet();

    // Test name
    final nameObj = _singleObject(graph, subject: testIri, predicate: _mfName);
    final name = nameObj is LiteralTerm ? nameObj.value : testIri.toString();

    final iri = testIri is IriTerm ? testIri.value : testIri.toString();

    entries.add(ManifestTestEntry(
      testIri: iri,
      name: name,
      requiresRdfStar: requirements.contains(_jellytRequirementRdfStar),
      requiresGeneralizedRdf:
          requirements.contains(_jellytRequirementGeneralizedRdf),
    ));
  }

  return entries;
}

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

RdfObject? _singleObject(RdfGraph graph,
    {RdfSubject? subject, required RdfPredicate predicate}) {
  final triples = graph.findTriples(subject: subject, predicate: predicate);
  return triples.isEmpty ? null : triples.first.object;
}

/// The base URI prefix used in the Jelly manifests.
const _jellyTestBasePrefix = 'https://w3id.org/jelly/dev/tests/rdf/';

String _resolveToFilePath(String iri, String manifestDir) {
  final uri = Uri.parse(iri);
  if (uri.scheme == 'file') {
    return uri.toFilePath();
  }
  // Strip the Jelly test base prefix to get the relative path.
  // The manifest BASE resolves to e.g.
  //   https://w3id.org/jelly/dev/tests/rdf/from_jelly/triples_rdf_1_1/...
  // We strip up to and including from_jelly/ or to_jelly/ to get the
  // relative path from the manifest directory.
  if (iri.startsWith(_jellyTestBasePrefix)) {
    final afterPrefix = iri.substring(_jellyTestBasePrefix.length);
    // afterPrefix is e.g. "from_jelly/triples_rdf_1_1/pos_001/in.jelly"
    // The manifest dir is already the from_jelly/ or to_jelly/ directory,
    // so strip the first segment (from_jelly/ or to_jelly/).
    final slashIdx = afterPrefix.indexOf('/');
    if (slashIdx >= 0) {
      final relativePath = afterPrefix.substring(slashIdx + 1);
      return '$manifestDir/$relativePath';
    }
  }
  // Fallback: treat path component as relative
  return '$manifestDir/${uri.pathSegments.last}';
}

// ---------------------------------------------------------------------------
// to_jelly manifest parser
// ---------------------------------------------------------------------------

/// A single Jelly to_jelly conformance test case.
class JellyToJellyTestCase {
  final String name;
  final JellyTestKind kind;
  final JellyPhysicalType physicalType;

  /// Absolute filesystem path to the stream_options.jelly file.
  final String streamOptionsPath;

  /// Absolute filesystem paths to input files (.nt or .nq), one per frame.
  final List<String> inputPaths;

  /// Absolute filesystem path to the expected output .jelly file.
  /// `null` for negative tests, which have no expected output.
  final String? resultPath;

  const JellyToJellyTestCase({
    required this.name,
    required this.kind,
    required this.physicalType,
    required this.streamOptionsPath,
    required this.inputPaths,
    this.resultPath,
  });

  @override
  String toString() => 'JellyToJellyTestCase($name, $kind)';
}

/// Parses the Jelly to_jelly manifest.ttl and returns RDF 1.1 test cases.
List<JellyToJellyTestCase> parseJellyToJellyManifest(String manifestPath) {
  final manifestFile = File(manifestPath);
  final manifestContent = manifestFile.readAsStringSync();
  final manifestDir = manifestFile.parent.path;

  final documentUrl = Uri.file(manifestFile.absolute.path).toString();

  final decoder = TurtleDecoder(
    namespaceMappings: RdfNamespaceMappings(),
  );
  final graph = decoder.convert(manifestContent, documentUrl: documentUrl);

  final entriesTriples = graph.findTriples(predicate: _mfEntries);
  if (entriesTriples.isEmpty) {
    throw StateError('No mf:entries found in manifest: $manifestPath');
  }
  final testIris = _traverseRdfList(graph, entriesTriples.first.object);

  final testCases = <JellyToJellyTestCase>[];
  for (final testIri in testIris) {
    if (testIri is! RdfSubject) continue;

    // Determine test kind
    final typeTriples =
        graph.findTriples(subject: testIri, predicate: Rdf.type);
    final types = typeTriples.map((t) => t.object).toSet();

    JellyTestKind? kind;
    if (types.contains(_jellytTestPositive)) {
      kind = JellyTestKind.positive;
    } else if (types.contains(_jellytTestNegative)) {
      kind = JellyTestKind.negative;
    }
    if (kind == null) continue;

    // Check requirements — skip RDF-star and generalized RDF
    final requiresTriples =
        graph.findTriples(subject: testIri, predicate: _mfRequires);
    final requirements = requiresTriples.map((t) => t.object).toSet();
    if (requirements.contains(_jellytRequirementRdfStar)) continue;
    if (requirements.contains(_jellytRequirementGeneralizedRdf)) continue;

    // Determine physical type
    JellyPhysicalType? physicalType;
    if (requirements.contains(_jellytRequirementTriples)) {
      physicalType = JellyPhysicalType.triples;
    } else if (requirements.contains(_jellytRequirementQuads)) {
      physicalType = JellyPhysicalType.quads;
    } else if (requirements.contains(_jellytRequirementGraphs)) {
      physicalType = JellyPhysicalType.graphs;
    }
    if (physicalType == null) continue;

    // Test name
    final nameObj = _singleObject(graph, subject: testIri, predicate: _mfName);
    final name = nameObj is LiteralTerm ? nameObj.value : testIri.toString();

    // Action — list of (stream_options.jelly, in_000.nt, in_001.nt, ...)
    final actionObj =
        _singleObject(graph, subject: testIri, predicate: _mfAction);
    if (actionObj == null) continue;

    final actionItems = _traverseRdfList(graph, actionObj);
    if (actionItems.isEmpty) continue;

    final streamOptionsPath = actionItems.first is IriTerm
        ? _resolveToFilePath((actionItems.first as IriTerm).value, manifestDir)
        : '';
    final inputPaths = actionItems
        .skip(1)
        .whereType<IriTerm>()
        .map((iri) => _resolveToFilePath(iri.value, manifestDir))
        .toList();

    // Result — absent for negative tests (encoding must throw)
    final resultObj =
        _singleObject(graph, subject: testIri, predicate: _mfResult);
    final resultPath = resultObj is IriTerm
        ? _resolveToFilePath(resultObj.value, manifestDir)
        : null;
    if (resultPath == null && kind == JellyTestKind.positive) continue;

    testCases.add(JellyToJellyTestCase(
      name: name,
      kind: kind,
      physicalType: physicalType,
      streamOptionsPath: streamOptionsPath,
      inputPaths: inputPaths,
      resultPath: resultPath,
    ));
  }

  return testCases;
}
