import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';
import 'package:locorda_rdf_jsonld/src/jsonldgraph/jsonld_graph_decoder.dart';
import 'package:test/test.dart';

void main() {
  group('JsonLdDecoderOptions', () {
    test('from() creates instance from RdfGraphDecoderOptions', () {
      // Arrange
      final graphOptions = RdfGraphDecoderOptions();

      // Act
      final datasetOptions = JsonLdDecoderOptions.from(graphOptions);

      // Assert
      expect(datasetOptions, isA<JsonLdDecoderOptions>());
    });

    test('from() returns same instance if already JsonLdDecoderOptions', () {
      // Arrange
      final options = JsonLdDecoderOptions();

      // Act
      final result = JsonLdDecoderOptions.from(options);

      // Assert
      expect(identical(result, options), isTrue);
    });
  });

  group('toJsonLdDecoderOptions', () {
    test('converts JsonLdGraphDecoderOptions to JsonLdDecoderOptions', () {
      // Arrange
      final graphOptions = JsonLdGraphDecoderOptions();

      // Act
      final datasetOptions = toJsonLdDecoderOptions(graphOptions);

      // Assert
      expect(datasetOptions, isA<JsonLdDecoderOptions>());
    });
  });

  group('skipInvalidRdfTerms', () {
    test('is fail-fast by default for invalid object IRI', () {
      final input = '''
      {
        "@context": {
          "link": {"@id": "http://example.org/link", "@type": "@id"}
        },
        "@id": "http://example.org/s",
        "link": "http://example.org/invalid iri"
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfConstraintViolationException>()),
      );
    });

    test('skips invalid object IRI when enabled', () {
      final input = '''
      {
        "@context": {
          "link": {"@id": "http://example.org/link", "@type": "@id"}
        },
        "@id": "http://example.org/s",
        "link": "http://example.org/invalid iri"
      }
      ''';

      final dataset = JsonLdDecoder(
        options: const JsonLdDecoderOptions(skipInvalidRdfTerms: true),
      ).convert(input);

      expect(dataset.defaultGraph.triples, isEmpty);
    });

    test('skips invalid language tags when enabled', () {
      final input = '''
      {
        "@id": "http://example.org/s",
        "http://example.org/p": {"@value": "hello", "@language": "en_foo"}
      }
      ''';

      final dataset = JsonLdDecoder(
        options: const JsonLdDecoderOptions(skipInvalidRdfTerms: true),
      ).convert(input);

      expect(dataset.defaultGraph.triples, isEmpty);
    });
  });
}
