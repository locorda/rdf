/// Real-world roundtrip isomorphism tests for JSON-LD codecs.
///
/// Verifies that JSON-LD encode→decode produces isomorphic output for
/// realistic graphs and datasets. Known failures are documented so
/// regressions are visible while these issues are being fixed.
library;

import 'dart:io';

import 'package:locorda_rdf_canonicalization/canonicalization.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final assetsDir = p.normalize(p.join(
    Directory.current.path,
    'test',
    'assets',
    'realworld',
  ));

  group('jsonldGraph roundtrip isomorphism', () {
    test('acl.ttl (93 triples)', () {
      final graph = _loadTurtle(assetsDir, 'acl.ttl');
      _expectIsomorphicGraphRoundtrip(graph, 'acl.ttl');
    });

    test('vcard.ttl (870 triples)', () {
      final graph = _loadTurtle(assetsDir, 'vcard.ttl');
      _expectIsomorphicGraphRoundtrip(graph, 'vcard.ttl');
    });

    test('solid.ttl (222 triples)', () {
      final graph = _loadTurtle(assetsDir, 'solid.ttl');
      _expectIsomorphicGraphRoundtrip(graph, 'solid.ttl');
    });

    test('LegalCore.ttl (67 triples)', () {
      final graph = _loadTurtle(assetsDir, 'LegalCore.ttl');
      _expectIsomorphicGraphRoundtrip(graph, 'LegalCore.ttl');
    });

    test('category-v1.ttl (36 triples)', () {
      final graph = _loadTurtle(assetsDir, 'category-v1.ttl');
      _expectIsomorphicGraphRoundtrip(graph, 'category-v1.ttl');
    });

    test('schema.org.ttl (17k triples)', () {
      final graph = _loadTurtle(
        assetsDir,
        'schema.org.ttl',
        options: TurtleDecoderOptions(
          parsingFlags: {TurtleParsingFlag.allowDigitInLocalName},
        ),
      );
      _expectIsomorphicGraphRoundtrip(graph, 'schema.org.ttl');
    });

    test('gs1Voc.ttl (18k triples) — known failure', () {
      final graph = _loadTurtle(assetsDir, 'gs1Voc.ttl');
      final decoded = jsonldGraph.decode(jsonldGraph.encode(graph));

      expect(decoded.size, equals(graph.size));
      // Known failure: blank node collection handling differs
      expect(
        isIsomorphicGraphs(graph, decoded),
        // FIXME: expect isomorphic, fix jsonld dataset codec issues
        isFalse,
        reason: 'Expected to be non-isomorphic (known issue)',
      );
    });
  });

  group('jsonld dataset roundtrip isomorphism', () {
    test('jsonld_single_graph.jsonld', () {
      final dataset = _loadJsonLd(assetsDir, 'jsonld_single_graph.jsonld');
      _expectIsomorphicDatasetRoundtrip(dataset, 'jsonld_single_graph');
    });

    test('jsonld_named_graphs.jsonld', () {
      final dataset = _loadJsonLd(assetsDir, 'jsonld_named_graphs.jsonld');
      _expectIsomorphicDatasetRoundtrip(dataset, 'jsonld_named_graphs');
    });

    test('jsonld_mixed.jsonld', () {
      final dataset = _loadJsonLd(assetsDir, 'jsonld_mixed.jsonld');
      _expectIsomorphicDatasetRoundtrip(dataset, 'jsonld_mixed');
    });

    test('shard.trig (34k quads) — known failure', () {
      final trigFile = File(p.join(assetsDir, 'shard-mod-md5-1-0-v1_0_0.trig'));
      if (!trigFile.existsSync()) {
        markTestSkipped('shard.trig not available');
        return;
      }
      final dataset = trig.decode(trigFile.readAsStringSync());
      final decoded = jsonld.decode(jsonld.encode(dataset));

      expect(decoded.quads.length, equals(dataset.quads.length));
      // Known failure: dataset roundtrip not isomorphic
      expect(
        isIsomorphic(dataset, decoded),
        // FIXME: expect isomorphic, fix jsonld dataset codec issues
        isFalse,
        reason: 'Expected to be non-isomorphic (known issue)',
      );
    });
  });

  group('native JSON-LD dataset roundtrip', () {
    test('jsonld_single_graph.jsonld via dataset codec', () {
      final src = File(p.join(assetsDir, 'jsonld_single_graph.jsonld'))
          .readAsStringSync();
      final dataset = jsonld.decode(src);
      _expectIsomorphicDatasetRoundtrip(dataset, 'jsonld_single_graph');
    });

    test('jsonld_named_graphs.jsonld via dataset codec', () {
      final src = File(p.join(assetsDir, 'jsonld_named_graphs.jsonld'))
          .readAsStringSync();
      final dataset = jsonld.decode(src);
      _expectIsomorphicDatasetRoundtrip(dataset, 'jsonld_named_graphs');
    });

    test('jsonld_mixed.jsonld via dataset codec', () {
      final src =
          File(p.join(assetsDir, 'jsonld_mixed.jsonld')).readAsStringSync();
      final dataset = jsonld.decode(src);
      _expectIsomorphicDatasetRoundtrip(dataset, 'jsonld_mixed');
    });
  });
}

RdfGraph _loadTurtle(
  String assetsDir,
  String fileName, {
  TurtleDecoderOptions? options,
}) {
  final file = File(p.join(assetsDir, fileName));
  if (!file.existsSync()) {
    fail('$fileName not found at ${file.path}');
  }
  return turtle.decode(
    file.readAsStringSync(),
    documentUrl: 'https://example.org/base',
    options: options,
  );
}

RdfDataset _loadJsonLd(String assetsDir, String fileName) {
  final file = File(p.join(assetsDir, fileName));
  if (!file.existsSync()) {
    fail('$fileName not found at ${file.path}');
  }
  return jsonld.decode(file.readAsStringSync());
}

void _expectIsomorphicGraphRoundtrip(RdfGraph graph, String label) {
  final encoded = jsonldGraph.encode(graph);
  final decoded = jsonldGraph.decode(encoded);

  expect(decoded.size, equals(graph.size), reason: '$label triple count');
  expect(
    isIsomorphicGraphs(graph, decoded),
    isTrue,
    reason: '$label roundtrip not isomorphic',
  );
}

void _expectIsomorphicDatasetRoundtrip(RdfDataset dataset, String label) {
  final encoded = jsonld.encode(dataset);
  final decoded = jsonld.decode(encoded);

  expect(
    decoded.quads.length,
    equals(dataset.quads.length),
    reason: '$label quad count',
  );
  expect(
    isIsomorphic(dataset, decoded),
    isTrue,
    reason: '$label roundtrip not isomorphic',
  );
}
