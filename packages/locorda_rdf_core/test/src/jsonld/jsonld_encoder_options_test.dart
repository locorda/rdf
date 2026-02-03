import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/jsonldgraph/jsonld_graph_encoder.dart';
import 'package:test/test.dart';

void main() {
  group('JsonLdEncoderOptions', () {
    test('from() creates instance from RdfGraphEncoderOptions', () {
      // Arrange
      final graphOptions = RdfGraphEncoderOptions(
        customPrefixes: {'ex': 'http://example.org/'},
        iriRelativization: IriRelativizationOptions.full(),
      );

      // Act
      final datasetOptions = JsonLdEncoderOptions.from(graphOptions);

      // Assert
      expect(datasetOptions, isA<JsonLdEncoderOptions>());
      expect(
          datasetOptions.customPrefixes, equals(graphOptions.customPrefixes));
      expect(datasetOptions.iriRelativization,
          equals(graphOptions.iriRelativization));
    });

    test('from() returns same instance if already JsonLdEncoderOptions', () {
      // Arrange
      final options = JsonLdEncoderOptions(
        customPrefixes: {'ex': 'http://example.org/'},
      );

      // Act
      final result = JsonLdEncoderOptions.from(options);

      // Assert
      expect(identical(result, options), isTrue);
    });

    test('copyWith() creates new instance with updated values', () {
      // Arrange
      final original = JsonLdEncoderOptions(
        customPrefixes: {'ex': 'http://example.org/'},
        generateMissingPrefixes: true,
      );

      // Act
      final updated = original.copyWith(
        generateMissingPrefixes: false,
      );

      // Assert
      expect(updated.customPrefixes, equals(original.customPrefixes));
      expect(updated.generateMissingPrefixes, isFalse);
      expect(original.generateMissingPrefixes, isTrue);
    });
  });

  group('toJsonLdEncoderOptions', () {
    test('converts JsonLdGraphEncoderOptions to JsonLdEncoderOptions', () {
      // Arrange
      final graphOptions = JsonLdGraphEncoderOptions(
        customPrefixes: {'ex': 'http://example.org/'},
        generateMissingPrefixes: false,
        includeBaseDeclaration: false,
      );

      // Act
      final datasetOptions = toJsonLdEncoderOptions(graphOptions);

      // Assert
      expect(datasetOptions, isA<JsonLdEncoderOptions>());
      expect(
          datasetOptions.customPrefixes, equals(graphOptions.customPrefixes));
      expect(datasetOptions.generateMissingPrefixes,
          equals(graphOptions.generateMissingPrefixes));
      expect(datasetOptions.includeBaseDeclaration,
          equals(graphOptions.includeBaseDeclaration));
    });

    test('preserves all common options during conversion', () {
      // Arrange
      final graphOptions = JsonLdGraphEncoderOptions(
        customPrefixes: {'foaf': 'http://xmlns.com/foaf/0.1/'},
        generateMissingPrefixes: true,
        includeBaseDeclaration: true,
        iriRelativization: IriRelativizationOptions.full(),
      );

      // Act
      final datasetOptions = toJsonLdEncoderOptions(graphOptions);

      // Assert
      expect(
          datasetOptions.customPrefixes, equals(graphOptions.customPrefixes));
      expect(datasetOptions.iriRelativization,
          equals(graphOptions.iriRelativization));
    });
  });
}
