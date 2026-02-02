import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

void main() {
  late RdfCodecRegistry registry;
  late RdfCore rdf;

  setUp(() {
    // Create a fresh registry for each test
    registry = RdfCodecRegistry();
    final _namespaceMappings = const RdfNamespaceMappings();

    // Register standard formats
    registry.registerGraphCodec(
      TurtleCodec(namespaceMappings: _namespaceMappings),
    );
    registry.registerGraphCodec(
      JsonLdGraphCodec(namespaceMappings: _namespaceMappings),
    );
    registry.registerGraphCodec(const NTriplesCodec());

    rdf = RdfCore(registry: registry);
  });

  tearDown(() {
    // Clean up after each test
    registry.clear();
  });

  // Test the RdfCore functionality)

  group('RdfCore', () {
    test('withStandardCodecs registers standard codecs', () {
      // The factory constructor should pre-register standard codecs

      // Check that at least the standard codecs are registered (Turtle, JSON-LD)
      final codecs = registry.getAllGraphCodecs();
      expect(codecs.length, greaterThanOrEqualTo(2));

      // Verify we can get a decoder for Turtle
      final turtleDecoder = rdf.codec(contentType: 'text/turtle').decoder;
      expect(turtleDecoder, isNotNull);

      // Verify we can get a decoder for JSON-LD
      final jsonLdEncoder =
          rdf.codec(contentType: 'application/ld+json').encoder;
      expect(jsonLdEncoder, isNotNull);
    });

    test('registerCodec adds custom codec', () {
      final customCodec = _CustomRdfGraphCodec();

      // Register our custom codec
      registry.registerGraphCodec(customCodec);

      // Verify we can get a decoder for our custom codec
      final customDecoder =
          rdf.codec(contentType: 'application/x-custom-rdf').decoder;
      expect(customDecoder, isA<_CustomRdfDecoder>());

      // Verify we can get a encoder for our custom codec
      final customEncoder =
          rdf.codec(contentType: 'application/x-custom-rdf').encoder;
      expect(customEncoder, isA<_CustomRdfGraphEncoder>());
    });

    test('parse and encode with custom codec', () {
      final customCodec = _CustomRdfGraphCodec();
      registry.registerGraphCodec(customCodec);

      // Custom codec parsing should work
      final graph = rdf.decode(
        'custom content',
        contentType: 'application/x-custom-rdf',
      );
      expect(graph.size, equals(1));

      // Custom codec serialization should work
      final encoded = rdf.encode(
        graph,
        contentType: 'application/x-custom-rdf',
      );
      expect(encoded, equals('CUSTOM:1 triple(s)'));
    });

    test('auto-detection works with custom codec', () {
      // Register our custom codec that accepts any input
      registry.registerGraphCodec(_CustomRdfGraphCodec());

      // Custom codec should be detected
      final graph = rdf.decode('custom content');
      expect(graph.size, equals(1));
    });
  });

  group('RdfCore TriG Integration', () {
    late RdfCore rdf;

    setUp(() {
      rdf = RdfCore.withStandardCodecs();
    });

    test('decode dataset with TriG contentType', () {
      final trigData = '''
        @prefix ex: <http://example.org/> .
        @prefix foaf: <http://xmlns.com/foaf/0.1/> .
        
        ex:alice foaf:name "Alice" .
        
        GRAPH ex:peopleGraph {
          ex:bob foaf:name "Bob" .
        }
      ''';

      final dataset =
          rdf.decodeDataset(trigData, contentType: 'application/trig');

      expect(dataset.defaultGraph.triples.length, 1);
      expect(dataset.namedGraphs.length, 1);
    });

    test('encode dataset with TriG contentType', () {
      final dataset = RdfDataset.fromQuads([
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

      final trig = rdf.encodeDataset(dataset, contentType: 'application/trig');

      expect(trig, contains('@prefix'));
      expect(trig, contains('GRAPH'));
      expect(trig, contains('Alice'));
      expect(trig, contains('Bob'));
    });

    test('TriG codec is registered in standard codecs', () {
      final codec = rdf.datasetCodec(contentType: 'application/trig');
      expect(codec, isA<TriGCodec>());
    });

    test('roundtrip TriG encoding and decoding via RdfCore', () {
      final originalDataset = RdfDataset.fromQuads([
        Quad(
          const IriTerm('http://example.org/alice'),
          const IriTerm('http://xmlns.com/foaf/0.1/name'),
          LiteralTerm.string('Alice'),
        ),
        Quad(
          const IriTerm('http://example.org/bob'),
          const IriTerm('http://xmlns.com/foaf/0.1/age'),
          LiteralTerm.integer(30),
          const IriTerm('http://example.org/graph1'),
        ),
      ]);

      final trig =
          rdf.encodeDataset(originalDataset, contentType: 'application/trig');
      final decodedDataset =
          rdf.decodeDataset(trig, contentType: 'application/trig');

      expect(decodedDataset.defaultGraph.triples.length, 1);
      expect(decodedDataset.namedGraphs.length, 1);
      expect(decodedDataset.namedGraphs.first.graph.triples.length, 1);
    });

    test('additionalDatasetCodecs parameter works', () {
      final customDatasetCodec = _CustomDatasetCodec();
      final customRdf = RdfCore.withStandardCodecs(
        additionalDatasetCodecs: [customDatasetCodec],
      );

      final codec =
          customRdf.datasetCodec(contentType: 'application/x-custom-dataset');
      expect(codec, same(customDatasetCodec));
    });
  });
}

// Custom dataset codec for testing
class _CustomDatasetCodec extends RdfDatasetCodec {
  @override
  bool canParse(String content) => content.startsWith('CUSTOM_DATASET');

  @override
  RdfDatasetDecoder get decoder => _CustomDatasetDecoder();

  @override
  RdfDatasetEncoder get encoder => _CustomDatasetEncoder();

  @override
  String get primaryMimeType => 'application/x-custom-dataset';

  @override
  Set<String> get supportedMimeTypes => {'application/x-custom-dataset'};

  @override
  RdfDatasetCodec withOptions({
    RdfGraphEncoderOptions? encoder,
    RdfGraphDecoderOptions? decoder,
  }) =>
      this;
}

class _CustomDatasetDecoder extends RdfDatasetDecoder {
  @override
  RdfDataset convert(String input, {String? documentUrl}) {
    return RdfDataset.fromQuads([
      Quad(
        const IriTerm('http://example.org/subject'),
        const IriTerm('http://example.org/predicate'),
        LiteralTerm.string('Custom dataset'),
      ),
    ]);
  }

  @override
  RdfDatasetDecoder withOptions(RdfGraphDecoderOptions options) => this;
}

class _CustomDatasetEncoder extends RdfDatasetEncoder {
  @override
  String convert(
    RdfDataset dataset, {
    String? baseUri,
    Map<String, String> customPrefixes = const {},
  }) {
    return 'CUSTOM_DATASET:${dataset.defaultGraph.size} triples';
  }

  @override
  RdfDatasetEncoder withOptions(RdfGraphEncoderOptions options) => this;
}

// Example of a custom codec implementation

class _CustomRdfGraphCodec extends RdfGraphCodec {
  @override
  bool canParse(String content) => true; // Accept any content for testing

  @override
  RdfGraphDecoder get decoder => _CustomRdfDecoder();

  @override
  RdfGraphEncoder get encoder => _CustomRdfGraphEncoder();

  @override
  String get primaryMimeType => 'application/x-custom-rdf';

  @override
  Set<String> get supportedMimeTypes => {
        'application/x-custom-rdf',
        'text/x-custom',
      };

  @override
  RdfGraphCodec withOptions({
    RdfGraphEncoderOptions? encoder,
    RdfGraphDecoderOptions? decoder,
  }) =>
      this;
}

class _CustomRdfDecoder extends RdfGraphDecoder {
  @override
  RdfGraph convert(String input, {String? documentUrl}) {
    // For testing, always create a graph with one triple
    final subject = const IriTerm('http://example.org/subject');
    final predicate = const IriTerm('http://example.org/predicate');
    final object = LiteralTerm.string('Custom parsed content');

    return RdfGraph(triples: [Triple(subject, predicate, object)]);
  }

  @override
  RdfGraphDecoder withOptions(RdfGraphDecoderOptions options) => this;
}

class _CustomRdfGraphEncoder extends RdfGraphEncoder {
  @override
  String convert(
    RdfGraph graph, {
    String? baseUri,
    Map<String, String> customPrefixes = const {},
  }) {
    // For testing, just return a simple string with the triple count
    return 'CUSTOM:${graph.size} triple(s)';
  }

  @override
  RdfGraphEncoder withOptions(RdfGraphEncoderOptions options) => this;
}
