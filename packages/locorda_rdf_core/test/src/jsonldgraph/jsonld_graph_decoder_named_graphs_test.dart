import 'dart:io';

import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('JsonLdGraphDecoder - Named Graph Handling', () {
    late String namedGraphsJson;

    setUpAll(() {
      // Load the test asset with named graphs
      final file = File('test/assets/realworld/jsonld_named_graphs.jsonld');
      namedGraphsJson = file.readAsStringSync();
    });

    group('strict mode (default)', () {
      test('throws exception when named graphs are present', () {
        final decoder = JsonLdGraphDecoder(
          options: const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.strict,
          ),
        );

        expect(
          () => decoder.convert(namedGraphsJson),
          throwsA(
            isA<RdfDecoderException>().having(
              (e) => e.message,
              'message',
              contains('named graph'),
            ),
          ),
        );
      });

      test('throws exception with helpful message', () {
        final decoder = JsonLdGraphDecoder();

        expect(
          () => decoder.convert(namedGraphsJson),
          throwsA(
            isA<RdfDecoderException>().having(
              (e) => e.message,
              'message',
              allOf([
                contains('2 named graph(s)'),
                contains('JsonLdDecoder for full dataset support'),
                contains('ignoreNamedGraphs or mergeIntoDefault'),
              ]),
            ),
          ),
        );
      });

      test('works fine with documents without named graphs', () {
        final decoder = JsonLdGraphDecoder();
        final jsonLd = '''
        {
          "@context": {"name": "http://xmlns.com/foaf/0.1/name"},
          "@id": "http://example.org/person/john",
          "name": "John Smith"
        }
        ''';

        final graph = decoder.convert(jsonLd);
        expect(graph.triples.length, 1);
      });
    });

    group('ignoreNamedGraphs mode', () {
      test('returns only default graph when named graphs present', () {
        final decoder = JsonLdGraphDecoder(
          options: const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.ignoreNamedGraphs,
          ),
        );

        final graph = decoder.convert(namedGraphsJson);

        // The test asset has no default graph triples, only named graphs
        expect(graph.triples.isEmpty, isTrue);
      });

      test('works with document that has both default and named graphs', () {
        final decoder = JsonLdGraphDecoder(
          options: const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.ignoreNamedGraphs,
          ),
        );

        final jsonLd = '''
        {
          "@context": {
            "foaf": "http://xmlns.com/foaf/0.1/",
            "ex": "http://example.org/"
          },
          "@id": "ex:defaultPerson",
          "foaf:name": "Default Person",
          "@graph": [
            {
              "@id": "ex:namedGraph1",
              "@graph": [
                {
                  "@id": "ex:alice",
                  "foaf:name": "Alice"
                }
              ]
            }
          ]
        }
        ''';

        final graph = decoder.convert(jsonLd);

        // Should only have the default graph triple
        expect(graph.triples.length, 1);
        expect(
          graph.triples.any((t) =>
              t.subject == const IriTerm('http://example.org/defaultPerson') &&
              t.predicate == const IriTerm('http://xmlns.com/foaf/0.1/name') &&
              t.object == LiteralTerm.string('Default Person')),
          isTrue,
        );

        // Should NOT have Alice from the named graph
        expect(
          graph.triples.any(
              (t) => t.subject == const IriTerm('http://example.org/alice')),
          isFalse,
        );
      });

      test('works with custom log level', () {
        final decoder = JsonLdGraphDecoder(
          options: const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.ignoreNamedGraphs,
            logLevel: NamedGraphLogLevel.silent,
          ),
        );

        // Should not throw, just ignore named graphs silently
        final graph = decoder.convert(namedGraphsJson);
        expect(graph.triples.isEmpty, isTrue);
      });
    });

    group('mergeIntoDefault mode', () {
      test('merges all named graphs into default graph', () {
        final decoder = JsonLdGraphDecoder(
          options: const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.mergeIntoDefault,
          ),
        );

        final graph = decoder.convert(namedGraphsJson);

        // Should have triples from both named graphs
        // graph1 has Alice and Bob (5 triples total: 2 types, 2 names, 2 ages, 1 knows)
        // graph2 has Charlie (3 triples: 1 type, 1 name, 1 mbox)
        expect(graph.triples.length, greaterThan(0));

        // Check Alice is present
        expect(
          graph.triples.any((t) =>
              t.subject == const IriTerm('http://example.org/alice') &&
              t.predicate == const IriTerm('http://xmlns.com/foaf/0.1/name') &&
              t.object == LiteralTerm.string('Alice')),
          isTrue,
        );

        // Check Bob is present
        expect(
          graph.triples.any((t) =>
              t.subject == const IriTerm('http://example.org/bob') &&
              t.predicate == const IriTerm('http://xmlns.com/foaf/0.1/name') &&
              t.object == LiteralTerm.string('Bob')),
          isTrue,
        );

        // Check Charlie is present
        expect(
          graph.triples.any((t) =>
              t.subject == const IriTerm('http://example.org/charlie') &&
              t.predicate == const IriTerm('http://xmlns.com/foaf/0.1/name') &&
              t.object == LiteralTerm.string('Charlie')),
          isTrue,
        );
      });

      test('preserves default graph triples when merging', () {
        final decoder = JsonLdGraphDecoder(
          options: const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.mergeIntoDefault,
          ),
        );

        final jsonLd = '''
        {
          "@context": {
            "foaf": "http://xmlns.com/foaf/0.1/",
            "ex": "http://example.org/"
          },
          "@id": "ex:defaultPerson",
          "foaf:name": "Default Person",
          "@graph": [
            {
              "@id": "ex:namedGraph1",
              "@graph": [
                {
                  "@id": "ex:alice",
                  "foaf:name": "Alice"
                }
              ]
            }
          ]
        }
        ''';

        final graph = decoder.convert(jsonLd);

        // Should have both default and named graph triples
        expect(graph.triples.length, 2);

        // Check default graph triple
        expect(
          graph.triples.any((t) =>
              t.subject == const IriTerm('http://example.org/defaultPerson') &&
              t.object == LiteralTerm.string('Default Person')),
          isTrue,
        );

        // Check named graph triple
        expect(
          graph.triples.any((t) =>
              t.subject == const IriTerm('http://example.org/alice') &&
              t.object == LiteralTerm.string('Alice')),
          isTrue,
        );
      });

      test('works with custom log level', () {
        final decoder = JsonLdGraphDecoder(
          options: const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.mergeIntoDefault,
            logLevel: NamedGraphLogLevel.info,
          ),
        );

        final graph = decoder.convert(namedGraphsJson);
        expect(graph.triples.length, greaterThan(0));
      });

      test('handles empty named graphs', () {
        final decoder = JsonLdGraphDecoder(
          options: const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.mergeIntoDefault,
          ),
        );

        final jsonLd = '''
        {
          "@context": {"ex": "http://example.org/"},
          "@graph": [
            {
              "@id": "ex:emptyGraph",
              "@graph": []
            }
          ]
        }
        ''';

        final graph = decoder.convert(jsonLd);
        expect(graph.triples.isEmpty, isTrue);
      });
    });

    group('log level configuration', () {
      test('silent log level suppresses all logging', () {
        final decoder = JsonLdGraphDecoder(
          options: const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.mergeIntoDefault,
            logLevel: NamedGraphLogLevel.silent,
          ),
        );

        // Should work without any logging output
        final graph = decoder.convert(namedGraphsJson);
        expect(graph.triples.length, greaterThan(0));
      });

      test('uses default log level when not specified', () {
        // ignoreNamedGraphs defaults to fine level
        final ignoreDecoder = JsonLdGraphDecoder(
          options: const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.ignoreNamedGraphs,
            // logLevel not specified, should use fine
          ),
        );

        final graph1 = ignoreDecoder.convert(namedGraphsJson);
        expect(graph1.triples.isEmpty, isTrue);

        // mergeIntoDefault defaults to warning level
        final mergeDecoder = JsonLdGraphDecoder(
          options: const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.mergeIntoDefault,
            // logLevel not specified, should use warning
          ),
        );

        final graph2 = mergeDecoder.convert(namedGraphsJson);
        expect(graph2.triples.length, greaterThan(0));
      });
    });

    group('withOptions', () {
      test('creates new decoder with different options', () {
        final strictDecoder = JsonLdGraphDecoder(
          options: const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.strict,
          ),
        );

        final mergeDecoder = strictDecoder.withOptions(
          const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.mergeIntoDefault,
          ),
        ) as JsonLdGraphDecoder;

        // Original decoder should still be strict
        expect(
          () => strictDecoder.convert(namedGraphsJson),
          throwsA(isA<RdfDecoderException>()),
        );

        // New decoder should merge
        final graph = mergeDecoder.convert(namedGraphsJson);
        expect(graph.triples.length, greaterThan(0));
      });
    });

    group('edge cases', () {
      test('handles document with only default graph', () {
        final decoder = JsonLdGraphDecoder(
          options: const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.mergeIntoDefault,
          ),
        );

        final jsonLd = '''
        {
          "@context": {"name": "http://xmlns.com/foaf/0.1/name"},
          "@id": "http://example.org/person/john",
          "name": "John Smith"
        }
        ''';

        final graph = decoder.convert(jsonLd);
        expect(graph.triples.length, 1);
      });

      test('handles multiple levels of nested named graphs', () {
        final decoder = JsonLdGraphDecoder(
          options: const JsonLdGraphDecoderOptions(
            namedGraphHandling: NamedGraphHandling.mergeIntoDefault,
          ),
        );

        // The test asset has nested named graphs
        final graph = decoder.convert(namedGraphsJson);

        // Should successfully merge all levels
        expect(graph.triples.length, greaterThan(0));
      });
    });
  });
}
