import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('JSON-LD MIME Type Registration', () {
    late RdfCore rdfCore;

    setUp(() {
      rdfCore = RdfCore.withStandardCodecs();
    });

    group('Graph Codec', () {
      test('decode() with application/ld+json returns RdfGraph', () {
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
        final graph =
            rdfCore.decode(jsonld, contentType: 'application/ld+json');

        // Assert
        expect(graph, isA<RdfGraph>());
        expect(graph.triples.length, greaterThan(0));
      });

      test('encode() with application/ld+json works', () {
        // Arrange
        final graph = RdfGraph(triples: [
          Triple(
            IriTerm('http://example.org/alice'),
            IriTerm('http://xmlns.com/foaf/0.1/name'),
            LiteralTerm.string('Alice'),
          ),
        ]);

        // Act
        final jsonld =
            rdfCore.encode(graph, contentType: 'application/ld+json');

        // Assert
        expect(jsonld, contains('@context'));
        expect(jsonld, contains('Alice'));
      });

      test('auto-detection works for graph JSON-LD', () {
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

        // Act - no contentType specified
        final graph = rdfCore.decode(jsonld);

        // Assert
        expect(graph, isA<RdfGraph>());
        expect(graph.triples.length, greaterThan(0));
      });
    });

    group('Dataset Codec', () {
      test('decodeDataset() with application/ld+json returns RdfDataset', () {
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
        final dataset =
            rdfCore.decodeDataset(jsonld, contentType: 'application/ld+json');

        // Assert
        expect(dataset, isA<RdfDataset>());
        expect(dataset.graphNames.length, greaterThan(0));
      });

      test('encodeDataset() with application/ld+json works', () {
        // Arrange
        final graph1 = IriTerm('http://example.org/graph1');
        final alice = IriTerm('http://example.org/alice');
        final foafName = IriTerm('http://xmlns.com/foaf/0.1/name');

        final quads = [
          Quad(alice, foafName, LiteralTerm.string('Alice'), graph1),
        ];

        final dataset = RdfDataset.fromQuads(quads);

        // Act
        final jsonld =
            rdfCore.encodeDataset(dataset, contentType: 'application/ld+json');

        // Assert
        expect(jsonld, contains('@context'));
        expect(jsonld, contains('@graph'));
        expect(jsonld, contains('Alice'));
      });
    });

    group('canParse()', () {
      test('JsonLdGraphCodec.canParse() detects JSON-LD', () {
        // Arrange
        final codec = JsonLdGraphCodec();
        final jsonld = '''
        {
          "@context": "http://schema.org/",
          "@id": "http://example.org/alice",
          "name": "Alice"
        }
        ''';

        // Act & Assert
        expect(codec.canParse(jsonld), isTrue);
      });

      test('JsonLdCodec.canParse() detects JSON-LD', () {
        // Arrange
        final codec = JsonLdCodec();
        final jsonld = '''
        {
          "@context": "http://schema.org/",
          "@graph": []
        }
        ''';

        // Act & Assert
        expect(codec.canParse(jsonld), isTrue);
      });

      test('canParse() rejects non-JSON-LD content', () {
        // Arrange
        final graphCodec = JsonLdGraphCodec();
        final datasetCodec = JsonLdCodec();
        final plainJson = '''
        {
          "name": "Alice",
          "age": 30
        }
        ''';

        // Act & Assert
        expect(graphCodec.canParse(plainJson), isFalse);
        expect(datasetCodec.canParse(plainJson), isFalse);
      });
    });
  });
}
