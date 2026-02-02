import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('TriGEncoder', () {
    late TriGEncoder encoder;

    setUp(() {
      encoder = TriGEncoder();
    });

    test('encodes dataset with only default graph', () {
      final dataset = RdfDataset.fromQuads([
        Quad(
          const IriTerm('http://example.org/subject'),
          const IriTerm('http://example.org/predicate'),
          LiteralTerm.string('object'),
        ),
      ]);

      final trig = encoder.convert(dataset);

      expect(trig, contains('@prefix'));
      expect(trig, contains('ex:subject'));
      expect(trig, contains('ex:predicate'));
      expect(trig, contains('"object"'));
      expect(trig, isNot(contains('GRAPH')));
    });

    test('encodes dataset with single named graph', () {
      final graphName = const IriTerm('http://example.org/graph1');
      final dataset = RdfDataset.fromQuads([
        Quad(
          const IriTerm('http://example.org/subject'),
          const IriTerm('http://example.org/predicate'),
          LiteralTerm.string('object'),
          graphName,
        ),
      ]);

      final trig = encoder.convert(dataset);

      expect(trig, contains('GRAPH'));
      expect(trig, contains('ex:graph1'));
      expect(trig, contains('ex:subject'));
      expect(trig, contains('ex:predicate'));
      expect(trig, contains('"object"'));
    });

    test('encodes dataset with multiple named graphs', () {
      final graph1 = const IriTerm('http://example.org/graph1');
      final graph2 = const IriTerm('http://example.org/graph2');

      final dataset = RdfDataset.fromQuads([
        Quad(
          const IriTerm('http://example.org/alice'),
          const IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('Alice'),
          graph1,
        ),
        Quad(
          const IriTerm('http://example.org/bob'),
          const IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('Bob'),
          graph2,
        ),
      ]);

      final trig = encoder.convert(dataset);

      expect(trig, contains('GRAPH'));
      expect(trig, contains('ex:graph1'));
      expect(trig, contains('ex:graph2'));
      expect(trig, contains('"Alice"'));
      expect(trig, contains('"Bob"'));
    });

    test('encodes dataset with both default and named graphs', () {
      final graphName = const IriTerm('http://example.org/namedGraph');

      final dataset = RdfDataset.fromQuads([
        // Default graph
        Quad(
          const IriTerm('http://example.org/alice'),
          const IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('Alice'),
        ),
        // Named graph
        Quad(
          const IriTerm('http://example.org/bob'),
          const IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('Bob'),
          graphName,
        ),
      ]);

      final trig = encoder.convert(dataset);

      // Should have both default graph triples and named graph
      expect(trig, contains('"Alice"'));
      expect(trig, contains('GRAPH'));
      expect(trig, contains('ex:namedGraph'));
      expect(trig, contains('"Bob"'));
    });

    test('encodes blank node graph names', () {
      final blankGraphName = BlankNodeTerm();

      final dataset = RdfDataset.fromQuads([
        Quad(
          const IriTerm('http://example.org/subject'),
          const IriTerm('http://example.org/predicate'),
          LiteralTerm.string('object'),
          blankGraphName,
        ),
      ]);

      final trig = encoder.convert(dataset);

      expect(trig, contains('GRAPH _:'));
      expect(trig, contains('ex:subject'));
    });

    test('skips empty named graphs', () {
      // Create a dataset with an empty named graph
      final emptyGraphName = const IriTerm('http://example.org/emptyGraph');
      final dataset = RdfDataset(
        defaultGraph: RdfGraph(triples: [
          Triple(
            const IriTerm('http://example.org/subject'),
            const IriTerm('http://example.org/predicate'),
            LiteralTerm.string('object'),
          ),
        ]),
        namedGraphs: {
          emptyGraphName: RdfGraph(),
        },
      );

      final trig = encoder.convert(dataset);

      // Should not contain the empty graph
      expect(trig, isNot(contains('emptyGraph')));
      expect(trig, contains('ex:subject'));
    });

    test('roundtrip encoding and decoding preserves data', () {
      final graphName = const IriTerm('http://example.org/graph1');
      final originalDataset = RdfDataset.fromQuads([
        // Default graph
        Quad(
          const IriTerm('http://example.org/alice'),
          const IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('Alice'),
        ),
        // Named graph
        Quad(
          const IriTerm('http://example.org/bob'),
          const IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('Bob'),
          graphName,
        ),
        Quad(
          const IriTerm('http://example.org/bob'),
          const IriTerm('http://xmlns.com/foaf/0.1/age'),
          LiteralTerm.integer(30),
          graphName,
        ),
      ]);

      // Encode
      final trig = encoder.convert(originalDataset);

      // Decode
      final decoder =
          TriGDecoder(namespaceMappings: const RdfNamespaceMappings());
      final decodedDataset = decoder.convert(trig);

      // Verify structure
      expect(decodedDataset.defaultGraph.triples.length, 1);
      expect(decodedDataset.namedGraphs.length, 1);
      expect(decodedDataset.namedGraphs.first.graph.triples.length, 2);

      // Verify content
      final defaultTriples = decodedDataset.defaultGraph.triples.toList();
      expect(defaultTriples[0].subject.toString(), contains('alice'));
      expect((defaultTriples[0].object as LiteralTerm).value, 'Alice');

      final namedGraphTriples =
          decodedDataset.namedGraphs.first.graph.triples.toList();
      expect(namedGraphTriples.length, 2);
    });

    test('uses shared prefixes across all graphs', () {
      final graph1 = const IriTerm('http://example.org/graph1');
      final graph2 = const IriTerm('http://example.org/graph2');

      final dataset = RdfDataset.fromQuads([
        Quad(
          const IriTerm('http://example.org/alice'),
          const IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('Alice'),
          graph1,
        ),
        Quad(
          const IriTerm('http://example.org/bob'),
          const IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('Bob'),
          graph2,
        ),
      ]);

      final trig = encoder.convert(dataset);

      // Prefixes should be declared once at the top
      final lines = trig.split('\n');
      final prefixLines =
          lines.where((line) => line.startsWith('@prefix')).toList();

      // Should have ex and foaf prefixes
      expect(prefixLines.any((line) => line.contains('ex:')), isTrue);
      expect(prefixLines.any((line) => line.contains('foaf:')), isTrue);

      // Prefixes should only appear at the beginning
      final firstGraphIndex =
          lines.indexWhere((line) => line.contains('GRAPH'));
      final prefixLinesAfterGraph = lines
          .skip(firstGraphIndex)
          .where((line) => line.startsWith('@prefix'));
      expect(prefixLinesAfterGraph, isEmpty);
    });

    test('properly indents named graph content', () {
      final graphName = const IriTerm('http://example.org/graph1');
      final dataset = RdfDataset.fromQuads([
        Quad(
          const IriTerm('http://example.org/subject'),
          const IriTerm('http://example.org/predicate'),
          LiteralTerm.string('object'),
          graphName,
        ),
      ]);

      final trig = encoder.convert(dataset);
      final lines = trig.split('\n');

      // Find the graph block
      final graphStartIndex =
          lines.indexWhere((line) => line.contains('GRAPH'));
      expect(graphStartIndex, greaterThanOrEqualTo(0));

      // Find the closing brace
      final graphEndIndex = lines.indexWhere(
        (line) => line.trim() == '}',
        graphStartIndex,
      );
      expect(graphEndIndex, greaterThan(graphStartIndex));

      // Content between should be indented
      for (var i = graphStartIndex + 1; i < graphEndIndex; i++) {
        final line = lines[i];
        if (line.isNotEmpty) {
          expect(line.startsWith('  '), isTrue,
              reason: 'Line should be indented: "$line"');
        }
      }
    });

    test('useGraphKeyword option controls GRAPH keyword rendering', () {
      final graphName = const IriTerm('http://example.org/graph1');
      final dataset = RdfDataset.fromQuads([
        Quad(
          const IriTerm('http://example.org/subject'),
          const IriTerm('http://example.org/predicate'),
          LiteralTerm.string('object'),
          graphName,
        ),
      ]);

      // Test with GRAPH keyword (default)
      final encoderWithKeyword = TriGEncoder(
        options: const TriGEncoderOptions(useGraphKeyword: true),
      );
      final trigWithKeyword = encoderWithKeyword.convert(dataset);
      expect(trigWithKeyword, contains('GRAPH ex:graph1 {'));
      expect(
          trigWithKeyword, isNot(matches(r'^<http://example.org/graph1> \{')));

      // Test without GRAPH keyword (shorthand)
      final encoderWithoutKeyword = TriGEncoder(
        options: const TriGEncoderOptions(useGraphKeyword: false),
      );
      final trigWithoutKeyword = encoderWithoutKeyword.convert(dataset);
      expect(trigWithoutKeyword, isNot(contains('GRAPH')));
      expect(trigWithoutKeyword, contains('ex:graph1 {'));
    });
  });
}
