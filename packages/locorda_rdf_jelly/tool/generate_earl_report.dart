/// Generates an EARL conformance report for the Jelly-RDF test suite.
///
/// Run from the `packages/locorda_rdf_jelly/` directory:
/// ```
/// dart tool/generate_earl_report.dart [output_file]
/// ```
///
/// Outputs Turtle-formatted EARL 1.0 conformance data suitable for submission
/// to the Jelly-RDF conformance reports repository.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:locorda_rdf_canonicalization/canonicalization.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';
import 'package:locorda_rdf_jelly/src/jelly_frame_decoder.dart';
import 'package:locorda_rdf_jelly/src/proto/rdf.pb.dart';

import '../test/jelly_manifest_parser.dart';

/// Maps w3id.org test IRIs to the GitHub URLs used in EARL reports.
const _w3idBase = 'https://w3id.org/jelly/dev/tests/rdf/';
const _githubBase =
    'https://github.com/Jelly-RDF/jelly-protobuf/tree/main/test/rdf/';

String _toGithubIri(String w3idIri) =>
    w3idIri.replaceFirst(_w3idBase, _githubBase);

/// Derives a Turtle fragment identifier from a test IRI.
///
/// E.g. `https://w3id.org/jelly/dev/tests/rdf/from_jelly/triples_rdf_1_1/pos_001`
/// → `rdf_from_jelly_triples_rdf_1_1_pos_001`
String _toFragmentId(String w3idIri) {
  final suffix = w3idIri.substring(_w3idBase.length); // from_jelly/cat/test_id
  return 'rdf_${suffix.replaceAll('/', '_')}';
}

// ---------------------------------------------------------------------------
// Configurable report metadata — review/update before submitting to the
// Jelly-RDF conformance reports repository.
// ---------------------------------------------------------------------------

// Developer / contributor group
const _kContributorName = 'Locorda RDF contributors';
const _kContributorHomepage = 'https://github.com/locorda/rdf';

// Assertor: the tool that runs the tests and generates this EARL report
const _kAssertorName = 'Locorda RDF Jelly EARL report generator';
const _kAssertorHomepage =
    'https://github.com/locorda/rdf/tree/main/packages/locorda_rdf_jelly/tool/generate_earl_report.dart';

// Implementation under test
const _kImplName = 'Locorda RDF Jelly';
const _kImplVersion = '0.12.0';
const _kImplHomepage = 'https://locorda.dev/rdf/jelly';
const _kImplDescription =
    'Locorda RDF Jelly – Jelly RDF binary serialization codec';

// ---------------------------------------------------------------------------
// Test runners (same logic as the conformance tests)
// ---------------------------------------------------------------------------

/// Outcome of a single test run.
enum _Outcome { passed, failed, inapplicable }

/// Runs a from_jelly test and returns whether it passed.
_Outcome _runFromJellyTest(JellyTestCase tc) {
  try {
    if (tc.kind == JellyTestKind.positive) {
      _runPositiveFromJellyTest(tc);
    } else {
      _runNegativeFromJellyTest(tc);
    }
    return _Outcome.passed;
  } catch (_) {
    return _Outcome.failed;
  }
}

void _runPositiveFromJellyTest(JellyTestCase tc) {
  final input = Uint8List.fromList(File(tc.actionPath).readAsBytesSync());

  if (tc.physicalType == JellyPhysicalType.triples) {
    final actual = JellyGraphDecoder().convert(input);
    final allNt = tc.resultPaths.map((p) => File(p).readAsStringSync()).join();
    final expected =
        allNt.trim().isEmpty ? RdfGraph() : NTriplesDecoder().convert(allNt);
    if (!isIsomorphicGraphs(actual, expected)) {
      throw StateError('Graph mismatch for ${tc.name}');
    }
  } else {
    final actual = JellyDatasetDecoder().convert(input);
    final allNq = tc.resultPaths.map((p) => File(p).readAsStringSync()).join();
    final expected = allNq.trim().isEmpty
        ? RdfDataset(defaultGraph: RdfGraph(), namedGraphs: {})
        : NQuadsDecoder().convert(allNq);
    if (!isIsomorphic(actual, expected)) {
      throw StateError('Dataset mismatch for ${tc.name}');
    }
  }
}

void _runNegativeFromJellyTest(JellyTestCase tc) {
  final input = Uint8List.fromList(File(tc.actionPath).readAsBytesSync());
  try {
    if (tc.physicalType == JellyPhysicalType.triples) {
      JellyGraphDecoder().convert(input);
    } else {
      JellyDatasetDecoder().convert(input);
    }
    // Should have thrown
    throw StateError('Expected exception for ${tc.name}');
  } on StateError {
    rethrow;
  } catch (_) {
    // Expected exception — test passes
  }
}

/// Runs a to_jelly test and returns whether it passed.
Future<_Outcome> _runToJellyTest(JellyToJellyTestCase tc) async {
  try {
    await _runPositiveToJellyTest(tc);
    return _Outcome.passed;
  } catch (_) {
    return _Outcome.failed;
  }
}

JellyEncoderOptions _readEncoderOptions(String path) {
  final bytes = File(path).readAsBytesSync();
  final frames = readDelimitedFrames(bytes).toList();
  for (final row in frames.first.rows) {
    if (row.whichRow() == RdfStreamRow_Row.options) {
      final opts = row.options;
      return JellyEncoderOptions(
        maxNameTableSize:
            opts.maxNameTableSize > 0 ? opts.maxNameTableSize : 128,
        maxPrefixTableSize: opts.maxPrefixTableSize,
        maxDatatypeTableSize: opts.maxDatatypeTableSize,
        physicalType: opts.physicalType,
        logicalType: opts.logicalType,
      );
    }
  }
  return const JellyEncoderOptions();
}

Future<void> _runPositiveToJellyTest(JellyToJellyTestCase tc) async {
  final encOpts = _readEncoderOptions(tc.streamOptionsPath);

  final Uint8List actualBytes;
  if (tc.physicalType == JellyPhysicalType.triples) {
    if (tc.inputPaths.length == 1) {
      final nt = File(tc.inputPaths.first).readAsStringSync().trim();
      final graph = nt.isEmpty ? RdfGraph() : NTriplesDecoder().convert(nt);
      actualBytes = JellyGraphEncoder(options: encOpts).convert(graph);
    } else {
      actualBytes = await _encodeTripleFrames(encOpts, tc.inputPaths);
    }
    final actual = JellyGraphDecoder().convert(actualBytes);
    final expected =
        JellyGraphDecoder().convert(File(tc.resultPath).readAsBytesSync());
    if (!isIsomorphicGraphs(actual, expected)) {
      throw StateError('Graph mismatch for ${tc.name}');
    }
  } else {
    if (tc.physicalType == JellyPhysicalType.quads &&
        tc.inputPaths.length > 1) {
      actualBytes = await _encodeQuadFrames(encOpts, tc.inputPaths);
    } else {
      final allNq =
          tc.inputPaths.map((p) => File(p).readAsStringSync()).join('\n');
      final dataset = allNq.trim().isEmpty
          ? RdfDataset(defaultGraph: RdfGraph(), namedGraphs: {})
          : NQuadsDecoder().convert(allNq);
      actualBytes = JellyDatasetEncoder(options: encOpts).convert(dataset);
    }
    final actual = JellyDatasetDecoder().convert(actualBytes);
    final expected =
        JellyDatasetDecoder().convert(File(tc.resultPath).readAsBytesSync());
    if (!isIsomorphic(actual, expected)) {
      throw StateError('Dataset mismatch for ${tc.name}');
    }
  }
}

Future<Uint8List> _encodeTripleFrames(
    JellyEncoderOptions opts, List<String> inputPaths) async {
  final frames = JellyTripleFrameEncoder(options: opts)
      .bind(NTriplesToTriplesDecoder().bind(_streamFiles(inputPaths)));
  final builder = BytesBuilder(copy: false);
  await for (final chunk in frames) {
    builder.add(chunk);
  }
  return builder.toBytes();
}

Future<Uint8List> _encodeQuadFrames(
    JellyEncoderOptions opts, List<String> inputPaths) async {
  final frames = JellyQuadFrameEncoder(options: opts)
      .bind(NQuadsToQuadsDecoder().bind(_streamFiles(inputPaths)));
  final builder = BytesBuilder(copy: false);
  await for (final chunk in frames) {
    builder.add(chunk);
  }
  return builder.toBytes();
}

Stream<String> _streamFiles(List<String> inputPaths) =>
    Stream.fromIterable(inputPaths).asyncMap((p) => File(p).readAsString());

// ---------------------------------------------------------------------------
// EARL report generation
// ---------------------------------------------------------------------------

Future<void> main(List<String> args) async {
  final outputPath = args.isNotEmpty ? args.first : 'locorda_rdf_jelly.ttl';

  const fromJellyManifest =
      '../../test_assets/jelly/jelly-protobuf/test/rdf/from_jelly/manifest.ttl';
  const toJellyManifest =
      '../../test_assets/jelly/jelly-protobuf/test/rdf/to_jelly/manifest.ttl';

  for (final path in [fromJellyManifest, toJellyManifest]) {
    if (!File(path).existsSync()) {
      stderr.writeln('Test suite not found at $path');
      stderr.writeln('Run: git submodule update --init --recursive');
      exitCode = 1;
      return;
    }
  }

  // Parse all test entries (including RDF-star/generalized)
  final allFromJelly = parseAllManifestTestEntries(fromJellyManifest);
  final allToJelly = parseAllManifestTestEntries(toJellyManifest);

  // Parse runnable RDF 1.1 test cases
  final runnableFromJelly = parseJellyManifest(fromJellyManifest);
  final runnableToJelly = parseJellyToJellyManifest(toJellyManifest);

  // Build name→test-case lookup for runnable tests
  final fromJellyByName = {for (final tc in runnableFromJelly) tc.name: tc};
  final toJellyByName = {for (final tc in runnableToJelly) tc.name: tc};

  // Run tests and collect outcomes keyed by test name
  final outcomes = <String, _Outcome>{};
  var passed = 0;
  var failed = 0;
  var inapplicable = 0;

  stdout.writeln('Running from_jelly conformance tests...');
  for (final tc in runnableFromJelly) {
    final result = _runFromJellyTest(tc);
    outcomes[tc.name] = result;
    if (result == _Outcome.passed) {
      passed++;
    } else {
      failed++;
      stderr.writeln('  FAILED: ${tc.name}');
    }
  }

  stdout.writeln('Running to_jelly conformance tests...');
  for (final tc in runnableToJelly) {
    final result = await _runToJellyTest(tc);
    outcomes[tc.name] = result;
    if (result == _Outcome.passed) {
      passed++;
    } else {
      failed++;
      stderr.writeln('  FAILED: ${tc.name}');
    }
  }

  // Determine outcomes for all entries (including unsupported ones)
  final allEntries = [...allFromJelly, ...allToJelly];
  final assertions = <_EarlAssertion>[];
  for (final entry in allEntries) {
    final _Outcome outcome;
    if (entry.requiresRdfStar || entry.requiresGeneralizedRdf) {
      outcome = _Outcome.inapplicable;
      inapplicable++;
    } else if (outcomes.containsKey(entry.name)) {
      outcome = outcomes[entry.name]!;
    } else {
      // Test wasn't runnable for some other reason
      outcome = _Outcome.inapplicable;
      inapplicable++;
    }
    assertions.add(_EarlAssertion(
      fragmentId: _toFragmentId(entry.testIri),
      testIri: _toGithubIri(entry.testIri),
      outcome: outcome,
    ));
  }

  // Generate and validate EARL Turtle
  final nowUtc = DateTime.now().toUtc();
  final now =
      '${nowUtc.toIso8601String().substring(0, 19)}Z'; // seconds, no ms
  final trtl = _generateEarlTurtle(assertions, now);
  // Validate: throws RdfSyntaxException / RdfInvalidIriException on malformed output.
  // documentUrl is required because the report uses relative IRIs (<>, <#assertor>, …).
  turtle.decode(trtl, documentUrl: File(outputPath).absolute.uri.toString());

  File(outputPath).writeAsStringSync(trtl);
  stdout.writeln('EARL report written to $outputPath '
      '($passed passed, $failed failed, $inapplicable inapplicable, '
      '${allEntries.length} total)');

  if (failed > 0) {
    exitCode = 1;
  }
}

class _EarlAssertion {
  final String fragmentId;
  final String testIri;
  final _Outcome outcome;

  const _EarlAssertion({
    required this.fragmentId,
    required this.testIri,
    required this.outcome,
  });
}

String _outcomeIri(_Outcome outcome) => switch (outcome) {
      _Outcome.passed => 'earl:passed',
      _Outcome.failed => 'earl:failed',
      _Outcome.inapplicable => 'earl:inapplicable',
    };

String _generateEarlTurtle(List<_EarlAssertion> assertions, String dateTime) {
  final releaseDate = dateTime.split('T').first;
  final buf = StringBuffer();

  // Prefixes and document metadata
  buf.write('''
@prefix dc: <http://purl.org/dc/terms/> .
@prefix doap: <http://usefulinc.com/ns/doap#> .
@prefix earl: <http://www.w3.org/ns/earl#> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

<>
    dc:issued "$dateTime"^^xsd:dateTime ;
    foaf:maker <#assertor> ;
    foaf:primaryTopic <#impl> .

''');

  // Assertor and implementation (test subject)
  buf.write('''
<#developer> a foaf:Group ;
    foaf:homepage <$_kContributorHomepage> ;
    foaf:name "$_kContributorName" .

<#assertor> a earl:Assertor,
        earl:Software ;
    foaf:homepage <$_kAssertorHomepage> ;
    foaf:name "$_kAssertorName" .

<#impl> a doap:Project,
        doap:Software,
        doap:TestSubject ;
    doap:description "$_kImplDescription"@en ;
    doap:developer <#developer> ;
    doap:homepage <$_kImplHomepage> ;
    doap:name "$_kImplName" ;
    doap:programming-language "Dart" ;
    doap:release [ dc:created "$releaseDate"^^xsd:date ;
            doap:name "$_kImplName" ;
            doap:revision "$_kImplVersion" ] .

''');

  // Individual test assertions
  for (final a in assertions) {
    buf.write('''
<#${a.fragmentId}> a earl:Assertion ;
    earl:assertedBy <#assertor> ;
    earl:mode earl:automatic ;
    earl:result [ a earl:TestResult ;
            dc:date "$dateTime"^^xsd:dateTime ;
            earl:outcome ${_outcomeIri(a.outcome)} ] ;
    earl:subject <#impl> ;
    earl:test <${a.testIri}> .

''');
  }
  return buf.toString();
}
