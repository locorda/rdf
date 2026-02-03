import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/jsonldgraph/jsonld_graph_decoder.dart';
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
}
