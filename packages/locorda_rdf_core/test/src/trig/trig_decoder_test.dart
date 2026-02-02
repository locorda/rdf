import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('TriGDecoder', () {
    late TriGDecoder decoder;
    late RdfNamespaceMappings namespaceMappings;

    setUp(() {
      namespaceMappings = RdfNamespaceMappings.custom({
        'ex': 'http://example.org/',
        'foaf': 'http://xmlns.com/foaf/0.1/',
      });
      decoder = TriGDecoder(namespaceMappings: namespaceMappings);
    });

    group('Turtle Compatibility (Default Graph Only)', () {
      test('parses simple Turtle triple', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          ex:subject ex:predicate "object" .
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.defaultGraph.triples, hasLength(1));
        expect(dataset.namedGraphs, isEmpty);

        final triple = dataset.defaultGraph.triples.first;
        expect((triple.subject as IriTerm).value,
            equals('http://example.org/subject'));
        expect((triple.predicate as IriTerm).value,
            equals('http://example.org/predicate'));
        expect((triple.object as LiteralTerm).value, equals('object'));
      });

      test('parses multiple Turtle triples', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          ex:s1 ex:p1 "o1" .
          ex:s2 ex:p2 "o2" .
          ex:s3 ex:p3 "o3" .
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.defaultGraph.triples, hasLength(3));
        expect(dataset.namedGraphs, isEmpty);
      });

      test('parses Turtle with blank nodes', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          _:b1 ex:predicate "object" .
          ex:subject ex:knows _:b1 .
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.defaultGraph.triples, hasLength(2));
        expect(dataset.namedGraphs, isEmpty);

        // Verify blank node identity is maintained
        final triple1 = dataset.defaultGraph.triples.first;
        final triple2 = dataset.defaultGraph.triples.last;
        expect(triple1.subject, isA<BlankNodeTerm>());
        expect(triple2.object, isA<BlankNodeTerm>());
        expect(identical(triple1.subject, triple2.object), isTrue);
      });
    });

    group('Named Graphs with GRAPH Keyword', () {
      test('parses single named graph with GRAPH keyword', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          GRAPH ex:graph1 {
            ex:subject ex:predicate "object" .
          }
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.defaultGraph.triples, isEmpty);
        expect(dataset.namedGraphs, hasLength(1));

        final namedGraph = dataset.namedGraphs.first;
        expect(
            _graphName(namedGraph.name), equals('http://example.org/graph1'));
        expect(namedGraph.graph.triples, hasLength(1));

        final triple = namedGraph.graph.triples.first;
        expect((triple.subject as IriTerm).value,
            equals('http://example.org/subject'));
        expect((triple.predicate as IriTerm).value,
            equals('http://example.org/predicate'));
        expect((triple.object as LiteralTerm).value, equals('object'));
      });

      test('parses multiple triples in named graph', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          GRAPH ex:graph1 {
            ex:s1 ex:p1 "o1" .
            ex:s2 ex:p2 "o2" .
            ex:s3 ex:p3 "o3" .
          }
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.namedGraphs, hasLength(1));
        final namedGraph = dataset.namedGraphs.first;
        expect(namedGraph.graph.triples, hasLength(3));
      });

      test('parses multiple named graphs', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          GRAPH ex:graph1 {
            ex:s1 ex:p1 "o1" .
          }
          
          GRAPH ex:graph2 {
            ex:s2 ex:p2 "o2" .
          }
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.namedGraphs, hasLength(2));

        final graph1 = dataset.namedGraphs.firstWhere(
            (ng) => _graphName(ng.name) == 'http://example.org/graph1');
        expect(graph1.graph.triples, hasLength(1));

        final graph2 = dataset.namedGraphs.firstWhere(
            (ng) => _graphName(ng.name) == 'http://example.org/graph2');
        expect(graph2.graph.triples, hasLength(1));
      });

      test('parses GRAPH keyword case-insensitively', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          graph ex:graph1 {
            ex:s1 ex:p1 "o1" .
          }
          
          Graph ex:graph2 {
            ex:s2 ex:p2 "o2" .
          }
          
          GRAPH ex:graph3 {
            ex:s3 ex:p3 "o3" .
          }
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.namedGraphs, hasLength(3));
      });
    });

    group('Named Graphs with Shorthand Syntax', () {
      test('parses named graph with shorthand syntax', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          ex:graph1 {
            ex:subject ex:predicate "object" .
          }
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.defaultGraph.triples, isEmpty);
        expect(dataset.namedGraphs, hasLength(1));

        final namedGraph = dataset.namedGraphs.first;
        expect(
            _graphName(namedGraph.name), equals('http://example.org/graph1'));
        expect(namedGraph.graph.triples, hasLength(1));
      });

      test('parses named graph with full IRI', () {
        const trig = '''
          <http://example.org/graph1> {
            <http://example.org/subject> <http://example.org/predicate> "object" .
          }
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.namedGraphs, hasLength(1));
        final namedGraph = dataset.namedGraphs.first;
        expect(
            _graphName(namedGraph.name), equals('http://example.org/graph1'));
      });

      test('parses multiple named graphs with shorthand', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          ex:graph1 {
            ex:s1 ex:p1 "o1" .
          }
          
          ex:graph2 {
            ex:s2 ex:p2 "o2" .
          }
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.namedGraphs, hasLength(2));
      });
    });

    group('Mixed Default and Named Graphs', () {
      test('parses mixed default and named graph triples', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          ex:s1 ex:p1 "default graph" .
          
          GRAPH ex:graph1 {
            ex:s2 ex:p2 "named graph" .
          }
          
          ex:s3 ex:p3 "also default" .
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.defaultGraph.triples, hasLength(2));
        expect(dataset.namedGraphs, hasLength(1));

        final defaultTriples = dataset.defaultGraph.triples.toList();
        expect((defaultTriples[0].object as LiteralTerm).value,
            equals('default graph'));
        expect((defaultTriples[1].object as LiteralTerm).value,
            equals('also default'));

        final namedGraph = dataset.namedGraphs.first;
        expect((namedGraph.graph.triples.first.object as LiteralTerm).value,
            equals('named graph'));
      });

      test('parses complex mixed content', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          @prefix foaf: <http://xmlns.com/foaf/0.1/> .
          
          # Default graph
          ex:alice foaf:name "Alice" .
          ex:alice foaf:age "25"^^<http://www.w3.org/2001/XMLSchema#integer> .
          
          # Named graph 1
          GRAPH ex:peopleGraph {
            ex:bob foaf:name "Bob"@en .
            ex:bob foaf:knows ex:alice .
          }
          
          # Named graph 2
          ex:contactGraph {
            ex:alice foaf:mbox <mailto:alice@example.org> .
          }
          
          # More default graph
          ex:alice foaf:homepage <http://alice.example.org> .
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.defaultGraph.triples, hasLength(3));
        expect(dataset.namedGraphs, hasLength(2));
      });
    });

    group('Blank Node Graph Names', () {
      test('parses named graph with blank node name', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          GRAPH _:graph1 {
            ex:subject ex:predicate "object" .
          }
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.namedGraphs, hasLength(1));
        final namedGraph = dataset.namedGraphs.first;
        expect(namedGraph.name, isA<BlankNodeTerm>());
        expect(namedGraph.graph.triples, hasLength(1));
      });

      test('maintains blank node graph identity', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          GRAPH _:g1 {
            ex:s1 ex:p1 "o1" .
          }
          
          GRAPH _:g1 {
            ex:s2 ex:p2 "o2" .
          }
          
          GRAPH _:g2 {
            ex:s3 ex:p3 "o3" .
          }
        ''';

        final dataset = decoder.convert(trig);

        // Should have 2 named graphs (_:g1 and _:g2)
        expect(dataset.namedGraphs, hasLength(2));

        // Find the graph with 2 triples (should be _:g1)
        final g1 = dataset.namedGraphs
            .firstWhere((ng) => ng.graph.triples.length == 2);
        expect(g1.name, isA<BlankNodeTerm>());
        expect(g1.graph.triples, hasLength(2));

        // Find the graph with 1 triple (should be _:g2)
        final g2 = dataset.namedGraphs
            .firstWhere((ng) => ng.graph.triples.length == 1);
        expect(g2.name, isA<BlankNodeTerm>());
        expect(g2.graph.triples, hasLength(1));

        // Verify they're different blank nodes
        expect(identical(g1.name, g2.name), isFalse);
      });

      test('parses blank node graph with shorthand syntax', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          _:graph1 {
            ex:subject ex:predicate "object" .
          }
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.namedGraphs, hasLength(1));
        final namedGraph = dataset.namedGraphs.first;
        expect(namedGraph.name, isA<BlankNodeTerm>());
      });
    });

    group('Nested Structures in Named Graphs', () {
      test('parses blank node subjects in named graphs', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          GRAPH ex:graph1 {
            _:b1 ex:predicate "object" .
            ex:subject ex:knows _:b1 .
          }
        ''';

        final dataset = decoder.convert(trig);

        final namedGraph = dataset.namedGraphs.first;
        expect(namedGraph.graph.triples, hasLength(2));

        // Verify blank node identity is maintained within the graph
        final triple1 = namedGraph.graph.triples.first;
        final triple2 = namedGraph.graph.triples.last;
        expect(triple1.subject, isA<BlankNodeTerm>());
        expect(triple2.object, isA<BlankNodeTerm>());
        expect(identical(triple1.subject, triple2.object), isTrue);
      });

      test('parses blank node property lists in named graphs', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          @prefix foaf: <http://xmlns.com/foaf/0.1/> .
          
          GRAPH ex:graph1 {
            ex:alice foaf:knows [
              foaf:name "Bob" ;
              foaf:age 30
            ] .
          }
        ''';

        final dataset = decoder.convert(trig);

        final namedGraph = dataset.namedGraphs.first;
        // Should have 3 triples: alice knows _:b, _:b name "Bob", _:b age 30
        expect(namedGraph.graph.triples, hasLength(3));
      });

      test('parses RDF collections in named graphs', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          GRAPH ex:graph1 {
            ex:subject ex:list (1 2 3) .
          }
        ''';

        final dataset = decoder.convert(trig);

        final namedGraph = dataset.namedGraphs.first;
        // Should have multiple triples for the list structure
        expect(namedGraph.graph.triples.length, greaterThan(1));
      });
    });

    group('Prefix Declarations', () {
      test('uses prefix declared before graph blocks', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          GRAPH ex:graph1 {
            ex:subject ex:predicate "object" .
          }
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.namedGraphs, hasLength(1));
        final triple = dataset.namedGraphs.first.graph.triples.first;
        expect((triple.subject as IriTerm).value,
            equals('http://example.org/subject'));
      });

      test('uses prefix declared inside graph block', () {
        const trig = '''
          GRAPH <http://example.org/graph1> {
            @prefix ex: <http://example.org/> .
            ex:subject ex:predicate "object" .
          }
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.namedGraphs, hasLength(1));
        final triple = dataset.namedGraphs.first.graph.triples.first;
        expect((triple.subject as IriTerm).value,
            equals('http://example.org/subject'));
      });

      test('prefix declared in graph is available in subsequent graphs', () {
        const trig = '''
          GRAPH <http://example.org/graph1> {
            @prefix ex: <http://example.org/> .
            ex:s1 ex:p1 "o1" .
          }
          
          GRAPH <http://example.org/graph2> {
            ex:s2 ex:p2 "o2" .
          }
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.namedGraphs, hasLength(2));

        // Both graphs should have successfully parsed triples
        for (final ng in dataset.namedGraphs) {
          expect(ng.graph.triples, hasLength(1));
        }
      });
    });

    group('Error Handling', () {
      test('throws error for unclosed graph block', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          GRAPH ex:graph1 {
            ex:subject ex:predicate "object" .
        ''';

        expect(
          () => decoder.convert(trig),
          throwsA(isA<RdfSyntaxException>()),
        );
      });

      test('throws error for graph without name', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          GRAPH {
            ex:subject ex:predicate "object" .
          }
        ''';

        expect(
          () => decoder.convert(trig),
          throwsA(isA<RdfSyntaxException>()),
        );
      });

      test('throws error for nested graph blocks', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          GRAPH ex:graph1 {
            GRAPH ex:graph2 {
              ex:subject ex:predicate "object" .
            }
          }
        ''';

        expect(
          () => decoder.convert(trig),
          throwsA(isA<RdfSyntaxException>()),
        );
      });
    });

    group('Edge Cases', () {
      test('parses empty named graph', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          GRAPH ex:graph1 {
          }
        ''';

        final dataset = decoder.convert(trig);

        // RdfDataset.fromQuads doesn't create named graph entries for empty graphs
        // This is semantically correct - an empty graph and no graph are equivalent
        expect(dataset.namedGraphs, isEmpty);
        expect(dataset.defaultGraph.triples, isEmpty);
      });

      test('parses empty default graph with named graphs', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          GRAPH ex:graph1 {
            ex:subject ex:predicate "object" .
          }
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.defaultGraph.triples, isEmpty);
        expect(dataset.namedGraphs, hasLength(1));
      });

      test('handles whitespace and comments correctly', () {
        const trig = '''
          @prefix ex: <http://example.org/> .
          
          # This is a comment
          
          GRAPH ex:graph1 {
            # Comment inside graph
            ex:subject ex:predicate "object" .
          }
          
          # Another comment
        ''';

        final dataset = decoder.convert(trig);

        expect(dataset.namedGraphs, hasLength(1));
        expect(dataset.namedGraphs.first.graph.triples, hasLength(1));
      });
    });

    test('withOptions returns new decoder with same behavior', () {
      final options = TriGDecoderOptions();
      final newDecoder = decoder.withOptions(options);

      expect(newDecoder, isA<TriGDecoder>());
      expect(identical(newDecoder, decoder), isFalse);

      // Test that it still works the same way
      const trig = '''
        @prefix ex: <http://example.org/> .
        GRAPH ex:graph1 {
          ex:subject ex:predicate "object" .
        }
      ''';
      final dataset = newDecoder.convert(trig);
      expect(dataset.namedGraphs, hasLength(1));
    });
  });
}

String _graphName(RdfGraphName name) {
  return switch (name) {
    IriTerm iri => iri.value,
    BlankNodeTerm bnode => bnode.toString(),
  };
}
