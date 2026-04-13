import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Default Codec Behavior', () {
    late RdfCore rdf;

    setUp(() {
      rdf = RdfCore.withStandardCodecs();
    });

    test('default graph codec is Turtle', () {
      final graph = RdfGraph(triples: [
        Triple(
          const IriTerm('http://example.org/subject'),
          const IriTerm('http://example.org/predicate'),
          LiteralTerm.string('object'),
        ),
      ]);

      // Encode without specifying contentType - should use Turtle (default)
      final encoded = rdf.encode(graph);

      // Turtle characteristics: prefixes and compact notation
      expect(encoded, contains('@prefix'));
      expect(encoded, contains('ex:'));
      expect(
          encoded,
          isNot(
              contains('<http://example.org/subject>'))); // Should be compacted
    });

    test('default dataset codec is TriG', () {
      final dataset = RdfDataset.fromQuads([
        Quad(
          const IriTerm('http://example.org/subject'),
          const IriTerm('http://example.org/predicate'),
          LiteralTerm.string('object'),
          const IriTerm('http://example.org/graph1'),
        ),
      ]);

      // Encode without specifying contentType - should use TriG (default)
      final encoded = rdf.encodeDataset(dataset);

      // TriG characteristics: prefixes, GRAPH keyword, compact notation
      expect(encoded, contains('@prefix'));
      expect(encoded, contains('GRAPH'));
      expect(encoded, contains('ex:'));
      expect(
          encoded,
          isNot(
              contains('<http://example.org/subject>'))); // Should be compacted
      expect(
          encoded,
          isNot(contains(
              '<http://example.org/graph1>'))); // Graph name should be compacted
    });

    test('default dataset codec is NOT N-Quads', () {
      final dataset = RdfDataset.fromQuads([
        Quad(
          const IriTerm('http://example.org/subject'),
          const IriTerm('http://example.org/predicate'),
          LiteralTerm.string('object'),
          const IriTerm('http://example.org/graph1'),
        ),
      ]);

      // Encode without specifying contentType
      final encoded = rdf.encodeDataset(dataset);

      // Should NOT be N-Quads format (which has no prefixes and uses full IRIs)
      expect(
          encoded,
          isNot(contains(
              '<http://example.org/subject> <http://example.org/predicate>'))); // N-Quads format
    });

    test('can still explicitly use N-Quads', () {
      final dataset = RdfDataset.fromQuads([
        Quad(
          const IriTerm('http://example.org/subject'),
          const IriTerm('http://example.org/predicate'),
          LiteralTerm.string('object'),
          const IriTerm('http://example.org/graph1'),
        ),
      ]);

      // Explicitly request N-Quads
      final encoded =
          rdf.encodeDataset(dataset, contentType: 'application/n-quads');

      // N-Quads characteristics: no prefixes, full IRIs, quad format
      expect(encoded, isNot(contains('@prefix')));
      expect(encoded, isNot(contains('GRAPH')));
      expect(encoded, contains('<http://example.org/subject>'));
      expect(encoded, contains('<http://example.org/graph1>'));
    });

    test('roundtrip with default dataset codec preserves data', () {
      final originalDataset = RdfDataset.fromQuads([
        Quad(
          const IriTerm('http://example.org/alice'),
          const IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('Alice'),
        ),
        Quad(
          const IriTerm('http://example.org/bob'),
          const IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('Bob'),
          const IriTerm('http://example.org/graph1'),
        ),
      ]);

      // Encode with default codec (TriG)
      final encoded = rdf.encodeDataset(originalDataset);

      // Decode (should auto-detect TriG)
      final decoded = rdf.decodeDataset(encoded);

      // Verify structure preserved
      expect(decoded.defaultGraph.triples.length, 1);
      expect(decoded.namedGraphs.length, 1);
      expect(decoded.namedGraphs.first.graph.triples.length, 1);
    });
  });
}
