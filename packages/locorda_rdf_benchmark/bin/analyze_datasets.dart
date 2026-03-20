/// Analyzes the characteristics of each benchmark dataset to explain
/// performance differences between codecs at different scales.
library;

import 'dart:io';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';
import 'package:path/path.dart' as p;

void main() {
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final packagesRoot = p.normalize(p.join(scriptDir.path, '..', '..'));
  final coreAssets =
      p.join(packagesRoot, 'locorda_rdf_core', 'test', 'assets', 'realworld');

  final smallSrc = File(p.join(coreAssets, 'acl.ttl')).readAsStringSync();
  final largeSrc =
      File(p.join(coreAssets, 'schema.org.ttl')).readAsStringSync();
  final shardSrc = File(p.join(coreAssets, 'shard-mod-md5-1-0-v1_0_0.trig'))
      .readAsStringSync();

  final smallGraph =
      turtle.decode(smallSrc, documentUrl: 'https://www.w3.org/ns/auth/acl');
  final largeGraph = turtle.decode(largeSrc,
      documentUrl: 'https://schema.org/',
      options: TurtleDecoderOptions(
          parsingFlags: {TurtleParsingFlag.allowDigitInLocalName}));
  final shardDataset = trig.decode(shardSrc);

  print('=== Dataset characteristics ===\n');

  _analyzeGraph('schema.org.ttl (large graph)', largeGraph);
  print('');
  _analyzeDataset('shard.trig (large dataset)', shardDataset);
  print('');
  _analyzeGraph('acl.ttl (small graph)', smallGraph);

  // Timing breakdown: TriG prefix analysis vs actual writing
  print('\n=== TriG encoder phase timing ===\n');
  _profileTriG(
      'schema.org (as dataset)', RdfDataset.fromDefaultGraph(largeGraph));
  _profileTriG('shard.trig', shardDataset);
  _profileTriG('acl.ttl (as dataset)', RdfDataset.fromDefaultGraph(smallGraph));

  // Jelly: emitTriple vs emitQuad on same data
  print('\n=== Jelly graph vs dataset encoding (same data) ===\n');
  _profileJellyBoth('schema.org', largeGraph);
  _profileJellyBoth('acl.ttl', smallGraph);
}

void _analyzeGraph(String name, RdfGraph graph) {
  final triples = graph.triples;
  final subjects = <RdfSubject>{};
  final predicates = <RdfPredicate>{};
  final objects = <RdfObject>{};
  final allIris = <String>{};
  final prefixes = <String>{};

  for (final t in triples) {
    subjects.add(t.subject);
    predicates.add(t.predicate);
    objects.add(t.object);

    if (t.subject is IriTerm) {
      final iri = (t.subject as IriTerm).value;
      allIris.add(iri);
      prefixes.add(_prefix(iri));
    }
    if (t.predicate is IriTerm) {
      final iri = (t.predicate as IriTerm).value;
      allIris.add(iri);
      prefixes.add(_prefix(iri));
    }
    if (t.object is IriTerm) {
      final iri = (t.object as IriTerm).value;
      allIris.add(iri);
      prefixes.add(_prefix(iri));
    }
    if (t.object is LiteralTerm) {
      final dt = (t.object as LiteralTerm).datatype.value;
      allIris.add(dt);
      prefixes.add(_prefix(dt));
    }
  }

  final bnodeCount = subjects.whereType<BlankNodeTerm>().length +
      objects.whereType<BlankNodeTerm>().length;
  final literalCount = objects.whereType<LiteralTerm>().length;

  print('$name:');
  print('  Triples:            ${triples.length}');
  print('  Unique subjects:    ${subjects.length}');
  print('  Unique predicates:  ${predicates.length}');
  print('  Unique objects:     ${objects.length}');
  print('  Unique IRIs:        ${allIris.length}');
  print('  Unique prefixes:    ${prefixes.length}');
  print('  Blank nodes:        $bnodeCount');
  print('  Literals:           $literalCount');
  print(
      '  Triples/subject:    ${(triples.length / subjects.length).toStringAsFixed(1)}');
  print('  Top prefixes:');
  final prefixCount = <String, int>{};
  for (final iri in allIris) {
    prefixCount[_prefix(iri)] = (prefixCount[_prefix(iri)] ?? 0) + 1;
  }
  final sorted = prefixCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final e in sorted.take(5)) {
    print('    ${e.key.padRight(50)} ${e.value}');
  }
}

void _analyzeDataset(String name, RdfDataset dataset) {
  print('$name:');
  print('  Default graph:      ${dataset.defaultGraph.triples.length} triples');
  print('  Named graphs:       ${dataset.namedGraphs.length}');
  var totalTriples = dataset.defaultGraph.triples.length;
  for (final ng in dataset.namedGraphs) {
    totalTriples += ng.graph.triples.length;
  }
  print('  Total triples:      $totalTriples');

  // Aggregate IRI stats from all graphs
  final allIris = <String>{};
  final subjects = <RdfSubject>{};
  final predicates = <RdfPredicate>{};
  final prefixes = <String>{};

  for (final graph in [
    dataset.defaultGraph,
    ...dataset.namedGraphs.map((ng) => ng.graph)
  ]) {
    for (final t in graph.triples) {
      subjects.add(t.subject);
      predicates.add(t.predicate);
      if (t.subject is IriTerm) {
        final iri = (t.subject as IriTerm).value;
        allIris.add(iri);
        prefixes.add(_prefix(iri));
      }
      if (t.predicate is IriTerm) {
        final iri = (t.predicate as IriTerm).value;
        allIris.add(iri);
        prefixes.add(_prefix(iri));
      }
      if (t.object is IriTerm) {
        final iri = (t.object as IriTerm).value;
        allIris.add(iri);
        prefixes.add(_prefix(iri));
      }
    }
  }

  print('  Unique subjects:    ${subjects.length}');
  print('  Unique predicates:  ${predicates.length}');
  print('  Unique IRIs:        ${allIris.length}');
  print('  Unique prefixes:    ${prefixes.length}');
  print(
      '  Triples/subject:    ${(totalTriples / subjects.length).toStringAsFixed(1)}');
  print('  Top prefixes:');
  final prefixCount = <String, int>{};
  for (final iri in allIris) {
    prefixCount[_prefix(iri)] = (prefixCount[_prefix(iri)] ?? 0) + 1;
  }
  final sorted = prefixCount.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final e in sorted.take(5)) {
    print('    ${e.key.padRight(50)} ${e.value}');
  }
}

String _prefix(String iri) {
  var idx = iri.lastIndexOf('#');
  if (idx >= 0) return iri.substring(0, idx + 1);
  idx = iri.lastIndexOf('/');
  if (idx >= 0) return iri.substring(0, idx + 1);
  return iri;
}

void _profileTriG(String label, RdfDataset dataset) {
  // Warm up
  for (var i = 0; i < 3; i++) {
    trig.encode(dataset);
  }

  const runs = 20;
  final times = <double>[];
  for (var i = 0; i < runs; i++) {
    final sw = Stopwatch()..start();
    trig.encode(dataset);
    sw.stop();
    times.add(sw.elapsedMicroseconds / 1000.0);
  }
  times.sort();
  final median = times[runs ~/ 2];
  print('  $label: ${median.toStringAsFixed(2)} ms (median of $runs)');
}

void _profileJellyBoth(String label, RdfGraph graph) {
  final dataset = RdfDataset.fromDefaultGraph(graph);

  // Warm up
  for (var i = 0; i < 3; i++) {
    jellyGraph.encode(graph);
    jelly.encode(dataset);
  }

  const runs = 20;

  final graphTimes = <double>[];
  for (var i = 0; i < runs; i++) {
    final sw = Stopwatch()..start();
    jellyGraph.encode(graph);
    sw.stop();
    graphTimes.add(sw.elapsedMicroseconds / 1000.0);
  }
  graphTimes.sort();

  final datasetTimes = <double>[];
  for (var i = 0; i < runs; i++) {
    final sw = Stopwatch()..start();
    jelly.encode(dataset);
    sw.stop();
    datasetTimes.add(sw.elapsedMicroseconds / 1000.0);
  }
  datasetTimes.sort();

  final gMedian = graphTimes[runs ~/ 2];
  final dMedian = datasetTimes[runs ~/ 2];
  print('  $label (${graph.size} triples):');
  print('    jellyGraph.encode (triples): ${gMedian.toStringAsFixed(2)} ms');
  print('    jelly.encode (quads):        ${dMedian.toStringAsFixed(2)} ms');
  print(
      '    overhead quad vs triple:      ${((dMedian / gMedian - 1) * 100).toStringAsFixed(1)}%');
}
