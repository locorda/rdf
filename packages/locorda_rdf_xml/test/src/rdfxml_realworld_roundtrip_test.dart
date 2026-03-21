/// Real-world roundtrip isomorphism tests for RDF/XML codec.
///
/// Verifies that Turtle→parse→RDF/XML encode→decode produces an isomorphic
/// graph for a variety of real-world ontologies and vocabularies.
library;

import 'dart:io';

import 'package:locorda_rdf_canonicalization/canonicalization.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_xml/xml.dart';
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

  group('Real-world roundtrip isomorphism', () {
    test('acl.ttl (93 triples)', () {
      final graph = _loadTurtle(assetsDir, 'acl.ttl');
      _expectIsomorphicRoundtrip(graph, 'acl.ttl');
    });

    test('vcard.ttl (870 triples)', () {
      final graph = _loadTurtle(assetsDir, 'vcard.ttl');
      _expectIsomorphicRoundtrip(graph, 'vcard.ttl');
    });

    test('solid.ttl (222 triples)', () {
      final graph = _loadTurtle(assetsDir, 'solid.ttl');
      _expectIsomorphicRoundtrip(graph, 'solid.ttl');
    });

    test('LegalCore.ttl (67 triples)', () {
      final graph = _loadTurtle(assetsDir, 'LegalCore.ttl');
      _expectIsomorphicRoundtrip(graph, 'LegalCore.ttl');
    });

    test('category-v1.ttl (36 triples)', () {
      final graph = _loadTurtle(assetsDir, 'category-v1.ttl');
      _expectIsomorphicRoundtrip(graph, 'category-v1.ttl');
    });

    test('schema.org.ttl (17k triples)', () {
      final graph = _loadTurtle(
        assetsDir,
        'schema.org.ttl',
        options: TurtleDecoderOptions(
          parsingFlags: {TurtleParsingFlag.allowDigitInLocalName},
        ),
      );
      _expectIsomorphicRoundtrip(graph, 'schema.org.ttl');
    });

    test(
      'gs1Voc.ttl (18k triples) — known failure: blank node collection reuse',
      () {
        final graph = _loadTurtle(assetsDir, 'gs1Voc.ttl');
        final decoded = rdfxml.decode(rdfxml.encode(graph));


        // Size must match even though blank node structure differs
        expect(decoded.size, equals(graph.size));

        // Known failure: OWL union class blank nodes get re-grouped
        // during serialization, causing non-isomorphic roundtrip.
        expect(
          isIsomorphicGraphs(graph, decoded),
          isFalse,
          reason: 'Expected to be non-isomorphic (known issue)',
        );
      },
    );
  });

  group('Whitespace preservation', () {
    test('multi-line literals survive roundtrip', () {
      final graph = _loadTurtle(assetsDir, 'acl.ttl');
      final xmlStr = rdfxml.encode(graph);
      final decoded = rdfxml.decode(xmlStr);

      // Pick a known multi-line literal from acl.ttl
      final originalComment = graph.triples
          .where(
            (t) =>
                (t.predicate as IriTerm).value ==
                    'http://www.w3.org/2000/01/rdf-schema#comment' &&
                (t.object as LiteralTerm).value.contains('\n'),
          )
          .toList();

      expect(
        originalComment,
        isNotEmpty,
        reason: 'acl.ttl should contain multi-line comments',
      );

      for (final orig in originalComment) {
        final origLit = orig.object as LiteralTerm;
        final match = decoded.triples.where(
          (t) =>
              t.subject == orig.subject &&
              (t.predicate as IriTerm).value ==
                  (orig.predicate as IriTerm).value &&
              t.object is LiteralTerm &&
              (t.object as LiteralTerm).value == origLit.value,
        );
        expect(
          match,
          isNotEmpty,
          reason:
              'Multi-line literal not preserved for ${orig.subject}: '
              '"${origLit.value.substring(0, 40.clamp(0, origLit.value.length))}..."',
        );
      }
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

void _expectIsomorphicRoundtrip(RdfGraph graph, String label) {
  final xmlStr = rdfxml.encode(graph);
  final decoded = rdfxml.decode(xmlStr);

  expect(decoded.size, equals(graph.size), reason: '$label triple count');
  expect(
    isIsomorphicGraphs(graph, decoded),
    isTrue,
    reason: '$label roundtrip not isomorphic',
  );
}
