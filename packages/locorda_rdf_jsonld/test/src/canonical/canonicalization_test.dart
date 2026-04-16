import 'dart:io';

import 'package:locorda_rdf_canonicalization/src/canonical/canonical_util.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';
import 'package:test/test.dart';

void main() {
  group('RDF Canonicalization', () {
    RdfDataset loadShardNqDataset() {
      final shardNq =
          File('test/assets/realworld/custom/shard.nq').readAsStringSync();
      return nquads.decode(shardNq);
    }

    RdfDataset roundtripWithTrig(RdfDataset dataset) {
      return trig.decode(trig.encode(dataset));
    }

    RdfDataset roundtripWithJsonLd(RdfDataset dataset) {
      return jsonld.decode(jsonld.encode(dataset));
    }

    String canonicalizeNamedGraph(RdfDataset dataset, RdfGraphName name) {
      final graph = dataset.graph(name);
      if (graph == null) {
        throw StateError('Named graph not found: $name');
      }
      // return canonicalize(datasetFromNamedGraph(name, graph));
      return canonicalizeGraph(graph);
    }

    test('should roundtrip shard.nq with JSON-LD canonically', () {
      final datasetFromNquads = loadShardNqDataset();
      final jsonldRoundtrip = roundtripWithJsonLd(datasetFromNquads);

      final canonicalNquads = canonicalize(datasetFromNquads);
      final canonicalJsonld = canonicalize(jsonldRoundtrip);

      expect(canonicalJsonld, equals(canonicalNquads));
    });

    test('should keep TriG and JSON-LD roundtrips canonical', () {
      final datasetFromNquads = loadShardNqDataset();
      final trigRoundtrip = roundtripWithTrig(datasetFromNquads);
      final jsonldRoundtrip = roundtripWithJsonLd(datasetFromNquads);

      final canonicalTrig = canonicalize(trigRoundtrip);
      final canonicalJsonld = canonicalize(jsonldRoundtrip);

      expect(canonicalTrig, equals(canonicalJsonld));
    });

    test('default graph: should roundtrip shard.nq with JSON-LD canonically',
        () {
      final datasetFromNquads = loadShardNqDataset();
      final jsonldRoundtrip = roundtripWithJsonLd(datasetFromNquads);

      final canonicalNquads = canonicalizeGraph(datasetFromNquads.defaultGraph);
      final canonicalJsonld = canonicalizeGraph(jsonldRoundtrip.defaultGraph);

      expect(canonicalJsonld, equals(canonicalNquads));
    });

    test('default graph: should keep TriG and JSON-LD roundtrips canonical',
        () {
      final datasetFromNquads = loadShardNqDataset();
      final trigRoundtrip = roundtripWithTrig(datasetFromNquads);
      final jsonldRoundtrip = roundtripWithJsonLd(datasetFromNquads);

      final canonicalTrig = canonicalizeGraph(trigRoundtrip.defaultGraph);
      final canonicalJsonld = canonicalizeGraph(jsonldRoundtrip.defaultGraph);

      expect(canonicalTrig, equals(canonicalJsonld));
    });

    test('named graph names should match after JSON-LD roundtrip', () {
      final datasetFromNquads = loadShardNqDataset();
      final jsonldRoundtrip = roundtripWithJsonLd(datasetFromNquads);

      expect(jsonldRoundtrip.graphNames.length,
          equals(datasetFromNquads.graphNames.length));
      expect(jsonldRoundtrip.graphNames.toSet(),
          equals(datasetFromNquads.graphNames.toSet()));
    });

    test('named graphs should be canonical after JSON-LD roundtrip', () {
      final datasetFromNquads = loadShardNqDataset();
      final jsonldRoundtrip = roundtripWithJsonLd(datasetFromNquads);
      expect(datasetFromNquads.graphNames.toSet(),
          equals(jsonldRoundtrip.graphNames.toSet()));
      for (final graphName in datasetFromNquads.graphNames) {
        final baseCanonical =
            canonicalizeNamedGraph(datasetFromNquads, graphName);
        final roundtripCanonical =
            canonicalizeNamedGraph(jsonldRoundtrip, graphName);

        expect(
          roundtripCanonical,
          equals(baseCanonical),
          reason: 'Named graph canonicalization mismatch for $graphName',
        );
      }
    });
  });
}
