import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('JSON-LD Named Graph Encoding', () {
    late JsonLdEncoder encoder;
    late RdfNamespaceMappings namespaceMappings;

    setUp(() {
      namespaceMappings = RdfNamespaceMappings();
      encoder = JsonLdEncoder(namespaceMappings: namespaceMappings);
    });

    test('encodes dataset with single named graph', () {
      // Arrange
      final graph1 = IriTerm('http://example.org/graph1');
      final alice = IriTerm('http://example.org/alice');
      final foafName = IriTerm('http://xmlns.com/foaf/0.1/name');

      final quads = [
        Quad(alice, foafName, LiteralTerm.string('Alice'), graph1),
      ];

      final dataset = RdfDataset.fromQuads(quads);

      // Act
      final jsonld = encoder.convert(dataset);

      // Assert
      expect(jsonld, contains('"@graph"'));
      expect(jsonld, contains('"@id"'));
      expect(jsonld, contains('http://example.org/graph1'));
      expect(jsonld, contains('Alice'));
    });

    test('encodes dataset with multiple named graphs', () {
      // Arrange
      final graph1 = IriTerm('http://example.org/graph1');
      final graph2 = IriTerm('http://example.org/graph2');
      final alice = IriTerm('http://example.org/alice');
      final bob = IriTerm('http://example.org/bob');
      final foafName = IriTerm('http://xmlns.com/foaf/0.1/name');

      final quads = [
        Quad(alice, foafName, LiteralTerm.string('Alice'), graph1),
        Quad(bob, foafName, LiteralTerm.string('Bob'), graph2),
      ];

      final dataset = RdfDataset.fromQuads(quads);

      // Act
      final jsonld = encoder.convert(dataset);

      // Assert
      expect(jsonld, contains('http://example.org/graph1'));
      expect(jsonld, contains('http://example.org/graph2'));
      expect(jsonld, contains('Alice'));
      expect(jsonld, contains('Bob'));
    });

    test('encodes dataset with default graph and named graphs', () {
      // Arrange
      final graph1 = IriTerm('http://example.org/graph1');
      final alice = IriTerm('http://example.org/alice');
      final bob = IriTerm('http://example.org/bob');
      final foafName = IriTerm('http://xmlns.com/foaf/0.1/name');

      final quads = [
        Quad(alice, foafName, LiteralTerm.string('Alice')), // default graph
        Quad(bob, foafName, LiteralTerm.string('Bob'), graph1), // named graph
      ];

      final dataset = RdfDataset.fromQuads(quads);

      // Act
      final jsonld = encoder.convert(dataset);

      // Assert
      expect(jsonld, contains('Alice'));
      expect(jsonld, contains('Bob'));
      expect(jsonld, contains('http://example.org/graph1'));
    });

    test('encodes dataset with blank node graph names', () {
      // Arrange
      final blankGraph = BlankNodeTerm();
      final alice = IriTerm('http://example.org/alice');
      final foafName = IriTerm('http://xmlns.com/foaf/0.1/name');

      final quads = [
        Quad(alice, foafName, LiteralTerm.string('Alice'), blankGraph),
      ];

      final dataset = RdfDataset.fromQuads(quads);

      // Act
      final jsonld = encoder.convert(dataset);

      // Assert
      expect(jsonld, contains('"@graph"'));
      expect(jsonld, contains('_:'));
      expect(jsonld, contains('Alice'));
    });

    test('includes graph names in @context prefixes', () {
      // Arrange
      final graph1 = IriTerm('http://example.org/graphs/graph1');
      final alice = IriTerm('http://example.org/alice');
      final foafName = IriTerm('http://xmlns.com/foaf/0.1/name');

      final quads = [
        Quad(alice, foafName, LiteralTerm.string('Alice'), graph1),
      ];

      final dataset = RdfDataset.fromQuads(quads);

      // Act
      final jsonld = encoder.convert(dataset);

      // Assert
      expect(jsonld, contains('"@context"'));
      // Graph name should be compacted if possible
    });

    test('compacts graph names using prefixes', () {
      // Arrange
      final customMappings = RdfNamespaceMappings.custom(
        {'ex': 'http://example.org/'},
      );
      final encoderWithPrefixes =
          JsonLdEncoder(namespaceMappings: customMappings);

      final graph1 = IriTerm('http://example.org/graph1');
      final alice = IriTerm('http://example.org/alice');
      final foafName = IriTerm('http://xmlns.com/foaf/0.1/name');

      final quads = [
        Quad(alice, foafName, LiteralTerm.string('Alice'), graph1),
      ];

      final dataset = RdfDataset.fromQuads(quads);

      // Act
      final jsonld = encoderWithPrefixes.convert(dataset);

      // Assert
      expect(jsonld, contains('"ex"'));
      expect(jsonld, contains('http://example.org/'));
    });
  });
}
