import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/plugin/rdf_codec_registry.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';
import 'package:test/test.dart';

// Tests for the AutoDetectingRdfCodec and AutoDetectingRdfDecoder classes
void main() {
  group('AutoDetectingRdfCodec Tests', () {
    late BaseRdfCodecRegistry registry;
    late RdfGraphCodec defaultCodec;
    late AutoDetectingRdfCodec codec;

    setUp(() {
      registry = BaseRdfCodecRegistry<RdfGraph>();
      defaultCodec = const TurtleCodec();
      registry.registerCodec(defaultCodec);
      codec = AutoDetectingRdfCodec(
        registry: registry,
        defaultCodec: defaultCodec,
      );
    });

    tearDown(() {
      registry.clear();
    });

    test('decode uses the first codec that can parse the content', () {
      // Arrange
      final turtleContent =
          '@prefix ex: <http://example.org/> .\nex:subject ex:predicate "object" .';
      final jsonLdContent =
          '{"@id": "http://example.org/subject", "http://example.org/predicate": "object"}';

      registry.registerCodec(const TurtleCodec());
      registry.registerCodec(const JsonLdGraphCodec());

      // Act & Assert - Turtle content should be parsed by the Turtle codec
      final graphFromTurtle = codec.decode(turtleContent);
      expect(graphFromTurtle.size, equals(1));
      expect(
        graphFromTurtle.triples.first.subject,
        equals(const IriTerm('http://example.org/subject')),
      );

      // Act & Assert - JSON-LD content should be parsed by the JSON-LD codec
      final graphFromJsonLd = codec.decode(jsonLdContent);
      expect(graphFromJsonLd.size, equals(1));
      expect(
        graphFromJsonLd.triples.first.subject,
        equals(const IriTerm('http://example.org/subject')),
      );
    });
  });
}
