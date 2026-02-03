import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('JSON-LD Dataset Roundtrip', () {
    late JsonLdEncoder encoder;
    late JsonLdDecoder decoder;

    setUp(() {
      encoder = JsonLdEncoder();
      decoder = JsonLdDecoder();
    });

    test('roundtrip dataset with single named graph', () {
      // Arrange
      final graph1 = IriTerm('http://example.org/graph1');
      final alice = IriTerm('http://example.org/alice');
      final foafName = IriTerm('http://xmlns.com/foaf/0.1/name');

      final originalQuads = [
        Quad(alice, foafName, LiteralTerm.string('Alice'), graph1),
      ];

      final originalDataset = RdfDataset.fromQuads(originalQuads);

      // Act
      final jsonld = encoder.convert(originalDataset);
      final decodedDataset = decoder.convert(jsonld);

      // Assert
      expect(decodedDataset.graphNames.length,
          equals(originalDataset.graphNames.length));
      expect(decodedDataset.quads.length, equals(originalDataset.quads.length));
    });

    test('roundtrip dataset with multiple named graphs', () {
      // Arrange
      final graph1 = IriTerm('http://example.org/graph1');
      final graph2 = IriTerm('http://example.org/graph2');
      final alice = IriTerm('http://example.org/alice');
      final bob = IriTerm('http://example.org/bob');
      final foafName = IriTerm('http://xmlns.com/foaf/0.1/name');

      final originalQuads = [
        Quad(alice, foafName, LiteralTerm.string('Alice'), graph1),
        Quad(bob, foafName, LiteralTerm.string('Bob'), graph2),
      ];

      final originalDataset = RdfDataset.fromQuads(originalQuads);

      // Act
      final jsonld = encoder.convert(originalDataset);
      final decodedDataset = decoder.convert(jsonld);

      // Assert
      expect(decodedDataset.graphNames.length, equals(2));
      expect(decodedDataset.quads.length, equals(2));
    });

    test('roundtrip dataset with default and named graphs', () {
      // Arrange
      final graph1 = IriTerm('http://example.org/graph1');
      final alice = IriTerm('http://example.org/alice');
      final bob = IriTerm('http://example.org/bob');
      final foafName = IriTerm('http://xmlns.com/foaf/0.1/name');

      final originalQuads = [
        Quad(alice, foafName, LiteralTerm.string('Alice')), // default graph
        Quad(bob, foafName, LiteralTerm.string('Bob'), graph1), // named graph
      ];

      final originalDataset = RdfDataset.fromQuads(originalQuads);

      // Act
      final jsonld = encoder.convert(originalDataset);
      final decodedDataset = decoder.convert(jsonld);

      // Assert
      expect(decodedDataset.defaultGraph.triples.length, equals(1));
      expect(decodedDataset.graphNames.length, equals(1));
    });

    test('roundtrip preserves blank node graph names', () {
      // Arrange
      final blankGraph = BlankNodeTerm();
      final alice = IriTerm('http://example.org/alice');
      final foafName = IriTerm('http://xmlns.com/foaf/0.1/name');

      final originalQuads = [
        Quad(alice, foafName, LiteralTerm.string('Alice'), blankGraph),
      ];

      final originalDataset = RdfDataset.fromQuads(originalQuads);

      // Act
      final jsonld = encoder.convert(originalDataset);
      final decodedDataset = decoder.convert(jsonld);

      // Assert
      expect(decodedDataset.graphNames.length, equals(1));
      expect(decodedDataset.graphNames.first, isA<BlankNodeTerm>());
    });

    test('roundtrip preserves all triple data', () {
      // Arrange
      final graph1 = IriTerm('http://example.org/graph1');
      final alice = IriTerm('http://example.org/alice');
      final foafName = IriTerm('http://xmlns.com/foaf/0.1/name');
      final foafAge = IriTerm('http://xmlns.com/foaf/0.1/age');

      final originalQuads = [
        Quad(alice, foafName, LiteralTerm.string('Alice'), graph1),
        Quad(alice, foafAge, LiteralTerm.typed('30', 'integer'), graph1),
      ];

      final originalDataset = RdfDataset.fromQuads(originalQuads);

      // Act
      final jsonld = encoder.convert(originalDataset);
      final decodedDataset = decoder.convert(jsonld);

      // Assert
      final graph = decodedDataset.graph(graph1);
      expect(graph!.triples.length, equals(2));

      final nameTriples = graph.findTriples(predicate: foafName);
      expect(nameTriples.length, equals(1));
      expect((nameTriples.first.object as LiteralTerm).value, equals('Alice'));

      final ageTriples = graph.findTriples(predicate: foafAge);
      expect(ageTriples.length, equals(1));
      expect((ageTriples.first.object as LiteralTerm).value, equals('30'));
    });
  });
}
