/// Real-world roundtrip tests for Jelly codec.
///
/// Verifies that encode→decode produces isomorphic output for realistic
/// datasets (schema.org, acl.ttl, shard.trig) that match the benchmark
/// inputs, ensuring measured decode times are for correct results.
library;

import 'dart:io';

import 'package:locorda_rdf_canonicalization/canonicalization.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final assetsDir = p.normalize(p.join(
    Directory.current.path,
    '..',
    'locorda_rdf_core',
    'test',
    'assets',
    'realworld',
  ));

  group('Graph roundtrip isomorphism', () {
    test('acl.ttl (93 triples)', () {
      final src = File(p.join(assetsDir, 'acl.ttl')).readAsStringSync();
      final graph =
          turtle.decode(src, documentUrl: 'https://www.w3.org/ns/auth/acl');
      final decoded = jellyGraph.decode(jellyGraph.encode(graph));

      expect(decoded.size, equals(graph.size));
      expect(isIsomorphicGraphs(graph, decoded), isTrue,
          reason: 'acl.ttl roundtrip not isomorphic');
    });

    test('schema.org.ttl (17k triples)', () {
      final src = File(p.join(assetsDir, 'schema.org.ttl')).readAsStringSync();
      final graph = turtle.decode(src,
          documentUrl: 'https://schema.org/',
          options: TurtleDecoderOptions(
              parsingFlags: {TurtleParsingFlag.allowDigitInLocalName}));
      final decoded = jellyGraph.decode(jellyGraph.encode(graph));

      expect(decoded.size, equals(graph.size));
      expect(isIsomorphicGraphs(graph, decoded), isTrue,
          reason: 'schema.org.ttl roundtrip not isomorphic');
    });
  });

  group('Dataset roundtrip isomorphism', () {
    test('acl.ttl as default-graph dataset (93 quads)', () {
      final src = File(p.join(assetsDir, 'acl.ttl')).readAsStringSync();
      final graph =
          turtle.decode(src, documentUrl: 'https://www.w3.org/ns/auth/acl');
      final dataset = RdfDataset.fromDefaultGraph(graph);
      final decoded = jelly.decode(jelly.encode(dataset));

      expect(decoded.quads.length, equals(dataset.quads.length));
      expect(isIsomorphic(dataset, decoded), isTrue,
          reason: 'acl.ttl dataset roundtrip not isomorphic');
    });

    test('shard.trig (34k quads, multi-named-graph)', () {
      final shardFile =
          File(p.join(assetsDir, 'shard-mod-md5-1-0-v1_0_0.trig'));
      if (!shardFile.existsSync()) {
        markTestSkipped('shard.trig not available');
        return;
      }
      final src = shardFile.readAsStringSync();
      final dataset = trig.decode(src);
      final decoded = jelly.decode(jelly.encode(dataset));

      expect(decoded.quads.length, equals(dataset.quads.length));
      expect(isIsomorphic(dataset, decoded), isTrue,
          reason: 'shard.trig roundtrip not isomorphic');
    });
  });
}
