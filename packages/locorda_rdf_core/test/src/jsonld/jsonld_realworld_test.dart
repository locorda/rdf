import 'dart:io';
import 'package:locorda_rdf_core/core.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('JSON-LD Real-World File Tests', () {
    /// Returns the absolute path to a test asset file
    String getAssetPath(String fileName) {
      return path.join('test/assets/realworld', fileName);
    }

    /// Helper to read a file and return its content as a string
    String readAssetFile(String fileName) {
      final file = File(getAssetPath(fileName));
      return file.readAsStringSync();
    }

    test('should parse jsonld_named_graphs.jsonld', () {
      // Arrange
      final content = readAssetFile('jsonld_named_graphs.jsonld');
      final decoder = JsonLdDecoder();

      // Act
      final dataset = decoder.convert(content);

      // Assert
      expect(dataset.graphNames.length, equals(2));

      final graph1 = dataset.graph(IriTerm('http://example.org/graph1'));
      expect(graph1!.triples.length, greaterThan(0));

      final graph2 = dataset.graph(IriTerm('http://example.org/graph2'));
      expect(graph2!.triples.length, greaterThan(0));

      // Verify specific triples exist
      final aliceTriples = graph1.findTriples(
        subject: IriTerm('http://example.org/alice'),
      );
      expect(aliceTriples.length, greaterThan(0));
    });

    test('should parse jsonld_single_graph.jsonld', () {
      // Arrange
      final content = readAssetFile('jsonld_single_graph.jsonld');
      final decoder = JsonLdDecoder();

      // Act
      final dataset = decoder.convert(content);

      // Assert
      expect(dataset.graphNames.length, equals(1));
      expect((dataset.graphNames.first as IriTerm).value,
          equals('http://example.org/graph1'));

      final graph = dataset.graph(dataset.graphNames.first);
      expect(graph!.triples.length, greaterThan(0));
    });

    test('should parse jsonld_mixed.jsonld', () {
      // Arrange
      final content = readAssetFile('jsonld_mixed.jsonld');
      final decoder = JsonLdDecoder();

      // Act
      final dataset = decoder.convert(content);

      // Assert
      // Should have both default graph and named graph
      expect(dataset.defaultGraph.triples.length, greaterThan(0));
      expect(dataset.graphNames.length, greaterThan(0));
    });

    test('should roundtrip jsonld_named_graphs.jsonld', () {
      // Arrange
      final content = readAssetFile('jsonld_named_graphs.jsonld');
      final decoder = JsonLdDecoder();
      final encoder = JsonLdEncoder();

      // Act
      final dataset = decoder.convert(content);
      final encoded = encoder.convert(dataset);
      final decodedAgain = decoder.convert(encoded);

      // Assert
      expect(decodedAgain.graphNames.length, equals(dataset.graphNames.length));
      expect(decodedAgain.quads.length, equals(dataset.quads.length));
    });

    test('should preserve graph structure in roundtrip', () {
      // Arrange
      final content = readAssetFile('jsonld_single_graph.jsonld');
      final decoder = JsonLdDecoder();
      final encoder = JsonLdEncoder();

      // Act
      final originalDataset = decoder.convert(content);
      final encoded = encoder.convert(originalDataset);
      final roundtrippedDataset = decoder.convert(encoded);

      // Assert
      expect(
        roundtrippedDataset.graphNames.map((g) => (g as IriTerm).value).toSet(),
        equals(originalDataset.graphNames
            .map((g) => (g as IriTerm).value)
            .toSet()),
      );
    });

    test('should handle complex nested structures', () {
      // Arrange
      final content = readAssetFile('jsonld_named_graphs.jsonld');
      final decoder = JsonLdDecoder();

      // Act
      final dataset = decoder.convert(content);
      final quads = dataset.quads.toList();

      // Assert
      expect(quads.length, greaterThan(5));

      // Verify all quads have graph names
      final namedQuads = quads.where((q) => q.graphName != null).toList();
      expect(namedQuads.length, equals(quads.length));
    });
  });
}
