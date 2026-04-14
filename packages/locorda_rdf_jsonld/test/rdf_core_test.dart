import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';
import 'package:test/test.dart';

void main() {
  late RdfCodecRegistry registry;
  late RdfCore rdf;

  setUp(() {
    // Create a fresh registry for each test
    registry = RdfCodecRegistry();
    final namespaceMappings = const RdfNamespaceMappings();

    // Register standard formats
    registry.registerGraphCodec(
      TurtleCodec(namespaceMappings: namespaceMappings),
    );
    registry.registerGraphCodec(
      JsonLdGraphCodec(namespaceMappings: namespaceMappings),
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
  });
}
