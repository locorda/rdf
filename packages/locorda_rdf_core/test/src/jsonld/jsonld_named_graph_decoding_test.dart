import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('JSON-LD Named Graph Decoding', () {
    late JsonLdDecoder decoder;

    setUp(() {
      decoder = JsonLdDecoder();
    });

    test('decodes JSON-LD with single named graph', () {
      // Arrange
      final jsonld = '''
      {
        "@context": {
          "name": "http://xmlns.com/foaf/0.1/name"
        },
        "@id": "http://example.org/graph1",
        "@graph": [
          {
            "@id": "http://example.org/alice",
            "name": "Alice"
          }
        ]
      }
      ''';

      // Act
      final dataset = decoder.convert(jsonld);

      // Verify the dataset structure
      expect(dataset.graphNames.length, equals(1));
      final graphName = dataset.graphNames.first;
      expect((graphName as IriTerm).value, equals('http://example.org/graph1'));

      final graph = dataset.graph(graphName);
      expect(graph, isNotNull);
      expect(graph!.size, equals(1)); // Only one triple from the @graph array
      expect((graph.triples.first.subject as IriTerm).value,
          equals('http://example.org/alice'));

      // Verify quads extraction
      final quads = dataset.quads.toList();
      expect(quads.length, equals(1)); // Only one quad
      expect(quads.every((q) => q.graphName == graphName), isTrue);
    });

    test('decodes JSON-LD with multiple named graphs', () {
      // Arrange
      final jsonld = '''
      {
        "@context": {
          "name": "http://xmlns.com/foaf/0.1/name"
        },
        "@graph": [
          {
            "@id": "http://example.org/graph1",
            "@graph": [
              {
                "@id": "http://example.org/alice",
                "name": "Alice"
              }
            ]
          },
          {
            "@id": "http://example.org/graph2",
            "@graph": [
              {
                "@id": "http://example.org/bob",
                "name": "Bob"
              }
            ]
          }
        ]
      }
      ''';

      // Act
      final dataset = decoder.convert(jsonld);

      // Assert
      expect(dataset.graphNames.length, equals(2));
      expect(
          dataset.graphNames.map((g) => (g as IriTerm).value),
          containsAll(
              ['http://example.org/graph1', 'http://example.org/graph2']));
    });

    test('decodes JSON-LD with default graph and named graphs', () {
      // Arrange
      final jsonld = '''
      {
        "@context": {
          "name": "http://xmlns.com/foaf/0.1/name"
        },
        "@id": "http://example.org/alice",
        "name": "Alice",
        "@graph": [
          {
            "@id": "http://example.org/graph1",
            "@graph": [
              {
                "@id": "http://example.org/bob",
                "name": "Bob"
              }
            ]
          }
        ]
      }
      ''';

      // Act
      final dataset = decoder.convert(jsonld);

      // Assert
      expect(dataset.defaultGraph.triples.length, greaterThan(0));
      expect(dataset.graphNames.length, equals(1));
    });

    test('decodes JSON-LD with blank node graph names', () {
      // Arrange
      final jsonld = '''
      {
        "@context": {
          "name": "http://xmlns.com/foaf/0.1/name"
        },
        "@graph": [
          {
            "@id": "_:graph1",
            "@graph": [
              {
                "@id": "http://example.org/alice",
                "name": "Alice"
              }
            ]
          }
        ]
      }
      ''';

      // Act
      final dataset = decoder.convert(jsonld);

      // Assert
      expect(dataset.graphNames.length, equals(1));
      expect(dataset.graphNames.first, isA<BlankNodeTerm>());
    });

    test('extracts quads with correct graph names', () {
      // Arrange
      final jsonld = '''
      {
        "@context": {
          "name": "http://xmlns.com/foaf/0.1/name"
        },
        "@id": "http://example.org/graph1",
        "@graph": [
          {
            "@id": "http://example.org/alice",
            "name": "Alice"
          }
        ]
      }
      ''';

      // Act
      final dataset = decoder.convert(jsonld);
      final quads = dataset.quads.toList();

      // Assert
      final namedQuads = quads.where((q) => q.graphName != null).toList();
      expect(namedQuads.length, greaterThan(0));
      expect((namedQuads.first.graphName! as IriTerm).value,
          equals('http://example.org/graph1'));
    });

    test('default graph quads have no graph name', () {
      // Arrange
      final jsonld = '''
      {
        "@context": {
          "name": "http://xmlns.com/foaf/0.1/name"
        },
        "@id": "http://example.org/alice",
        "name": "Alice"
      }
      ''';

      // Act
      final dataset = decoder.convert(jsonld);
      final quads = dataset.quads.toList();

      // Assert
      expect(quads.every((q) => q.graphName == null), isTrue);
    });
  });
}
