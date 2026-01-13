import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:rdf_vocabularies_core/rdf.dart' as rdf;
import 'package:test/test.dart';

// Import test models
import '../../fixtures/rdf_mapper_annotations/examples/example_rdf_literal.dart';
// Import generated mappers
import '../../fixtures/rdf_mapper_annotations/examples/example_rdf_literal.rdf_mapper.g.dart';
import '../init_test_rdf_mapper_util.dart';

void main() {
  late RdfMapper mapper;

  /// Helper to create serialization context
  SerializationContext createSerializationContext() {
    return SerializationContextImpl(registry: mapper.registry);
  }

  /// Helper to create deserialization context
  DeserializationContext createDeserializationContext() {
    final graph = RdfGraph.fromTriples([]);
    return DeserializationContextImpl(graph: graph, registry: mapper.registry);
  }

  setUp(() {
    mapper = defaultInitTestRdfMapper();
  });

  group('RDF Literal Examples Test', () {
    group('EnhancedRating (@RdfValue)', () {
      test('serializes using @RdfValue property', () {
        const mapper = EnhancedRatingMapper();
        final context = createSerializationContext();

        final rating = EnhancedRating(4);
        final literalTerm = mapper.toRdfTerm(rating, context);

        expect(literalTerm, isA<LiteralTerm>());
        expect(literalTerm.value, equals('4'));
        expect(literalTerm.datatype.value, contains('XMLSchema#int'));
      });

      test('deserializes using @RdfValue property', () {
        const mapper = EnhancedRatingMapper();
        final context = createDeserializationContext();

        final rating = mapper.fromRdfTerm(
          LiteralTerm('5',
              datatype:
                  const IriTerm('http://www.w3.org/2001/XMLSchema#integer')),
          context,
        );

        expect(rating.stars, equals(5));
      });

      test('validates rating range in constructor', () {
        expect(() => EnhancedRating(0), returnsNormally);
        expect(() => EnhancedRating(5), returnsNormally);
        expect(() => EnhancedRating(-1), throwsA(isA<ArgumentError>()));
        expect(() => EnhancedRating(6), throwsA(isA<ArgumentError>()));
      });

      test('handles all valid rating values', () {
        const mapper = EnhancedRatingMapper();
        final context = createSerializationContext();

        for (int i = 0; i <= 5; i++) {
          final rating = EnhancedRating(i);
          final literalTerm = mapper.toRdfTerm(rating, context);
          expect(literalTerm.value, equals(i.toString()));
        }
      });

      test('round-trip serialization maintains value', () {
        const mapper = EnhancedRatingMapper();
        final serContext = createSerializationContext();
        final deserContext = createDeserializationContext();

        for (int i = 0; i <= 5; i++) {
          final originalRating = EnhancedRating(i);
          final literalTerm = mapper.toRdfTerm(originalRating, serContext);
          final deserializedRating =
              mapper.fromRdfTerm(literalTerm, deserContext);
          expect(deserializedRating.stars, equals(originalRating.stars));
        }
      });
    });

    group('Temperature (custom serialization methods)', () {
      test('uses custom formatCelsius method for serialization', () {
        const mapper = TemperatureMapper();
        final context = createSerializationContext();

        final temp = Temperature(25.5);
        final literalTerm = mapper.toRdfTerm(temp, context);

        expect(literalTerm.value, equals('25.5°C'));
        expect(literalTerm.datatype.value,
            equals('http://example.org/temperature'));
      });

      test('uses custom parse method for deserialization', () {
        const mapper = TemperatureMapper();
        final context = createDeserializationContext();

        final temp = mapper.fromRdfTerm(
          LiteralTerm(
            '20.0°C',
            datatype: const IriTerm('http://example.org/temperature'),
          ),
          context,
        );

        expect(temp.celsius, equals(20.0));
      });

      test('handles negative temperatures', () {
        const mapper = TemperatureMapper();
        final context = createSerializationContext();

        final temp = Temperature(-10.5);
        final literalTerm = mapper.toRdfTerm(temp, context);

        expect(literalTerm.value, equals('-10.5°C'));
      });

      test('handles zero temperature', () {
        const mapper = TemperatureMapper();
        final context = createSerializationContext();

        final temp = Temperature(0.0);
        final literalTerm = mapper.toRdfTerm(temp, context);

        expect(literalTerm.value, equals('0.0°C'));
      });

      test('handles fractional temperatures', () {
        const mapper = TemperatureMapper();
        final context = createSerializationContext();

        final temp = Temperature(98.6);
        final literalTerm = mapper.toRdfTerm(temp, context);

        expect(literalTerm.value, equals('98.6°C'));
      });

      test('round-trip serialization maintains precision', () {
        const mapper = TemperatureMapper();
        final serContext = createSerializationContext();
        final deserContext = createDeserializationContext();

        final temperatures = [0.0, -273.15, 100.0, 37.5, -40.0];

        for (final tempValue in temperatures) {
          final originalTemp = Temperature(tempValue);
          final literalTerm = mapper.toRdfTerm(originalTemp, serContext);
          final deserializedTemp =
              mapper.fromRdfTerm(literalTerm, deserContext);
          expect(deserializedTemp.celsius, equals(originalTemp.celsius));
        }
      });

      test('handles extreme temperature values', () {
        const mapper = TemperatureMapper();
        final context = createSerializationContext();

        final extremelyHot = Temperature(1000000.0);
        final extremelyCold = Temperature(-1000000.0);

        final hotTerm = mapper.toRdfTerm(extremelyHot, context);
        final coldTerm = mapper.toRdfTerm(extremelyCold, context);

        expect(hotTerm.value, equals('1000000.0°C'));
        expect(coldTerm.value, equals('-1000000.0°C'));
      });
    });

    group('LocalizedText (@RdfLanguageTag)', () {
      test('serializes with language tag', () {
        const mapper = LocalizedTextMapper();
        final context = createSerializationContext();

        final text = LocalizedText('Hello', 'en');
        final literalTerm = mapper.toRdfTerm(text, context);

        expect(literalTerm.value, equals('Hello'));
        expect(literalTerm.language, equals('en'));
        expect(literalTerm.datatype, equals(rdf.Rdf.langString));
      });

      test('deserializes with language tag', () {
        const mapper = LocalizedTextMapper();
        final context = createDeserializationContext();

        final text = mapper.fromRdfTerm(
          LiteralTerm.withLanguage('Bonjour', 'fr'),
          context,
        );

        expect(text.text, equals('Bonjour'));
        expect(text.languageTag, equals('fr'));
      });

      test('handles convenience constructors', () {
        const mapper = LocalizedTextMapper();
        final context = createSerializationContext();

        final englishText = LocalizedText.en('Hello World');
        final germanText = LocalizedText.de('Hallo Welt');
        final frenchText = LocalizedText.fr('Bonjour le monde');

        final enTerm = mapper.toRdfTerm(englishText, context);
        final deTerm = mapper.toRdfTerm(germanText, context);
        final frTerm = mapper.toRdfTerm(frenchText, context);

        expect(enTerm.language, equals('en'));
        expect(deTerm.language, equals('de'));
        expect(frTerm.language, equals('fr'));

        expect(enTerm.value, equals('Hello World'));
        expect(deTerm.value, equals('Hallo Welt'));
        expect(frTerm.value, equals('Bonjour le monde'));
      });

      test('handles various language codes', () {
        const mapper = LocalizedTextMapper();
        final context = createSerializationContext();

        final languages = [
          ('Hello', 'en'),
          ('Hola', 'es'),
          ('Ciao', 'it'),
          ('Olá', 'pt'),
          ('Привет', 'ru'),
          ('こんにちは', 'ja'),
          ('你好', 'zh'),
          ('안녕하세요', 'ko'),
        ];

        for (final (text, lang) in languages) {
          final localizedText = LocalizedText(text, lang);
          final literalTerm = mapper.toRdfTerm(localizedText, context);

          expect(literalTerm.value, equals(text));
          expect(literalTerm.language, equals(lang));
        }
      });

      test('handles regional language codes', () {
        const mapper = LocalizedTextMapper();
        final context = createSerializationContext();

        final regionalTexts = [
          LocalizedText('Color', 'en-US'),
          LocalizedText('Colour', 'en-GB'),
          LocalizedText('Deutsch', 'de-DE'),
          LocalizedText('Schweizerdeutsch', 'de-CH'),
        ];

        for (final text in regionalTexts) {
          final literalTerm = mapper.toRdfTerm(text, context);
          expect(literalTerm.language, equals(text.languageTag));
        }
      });

      test('handles empty and special characters', () {
        const mapper = LocalizedTextMapper();
        final context = createSerializationContext();

        final specialTexts = [
          LocalizedText('', 'en'), // Empty text
          LocalizedText('Text with "quotes"', 'en'),
          LocalizedText('Text with <tags>', 'en'),
          LocalizedText('Text with & symbols', 'en'),
          LocalizedText('Text\nwith\nnewlines', 'en'),
          LocalizedText('Text\twith\ttabs', 'en'),
        ];

        for (final text in specialTexts) {
          final literalTerm = mapper.toRdfTerm(text, context);
          expect(literalTerm.value, equals(text.text));
          expect(literalTerm.language, equals(text.languageTag));

          // Test round-trip
          final deserContext = createDeserializationContext();
          final deserializedText =
              mapper.fromRdfTerm(literalTerm, deserContext);
          expect(deserializedText.text, equals(text.text));
          expect(deserializedText.languageTag, equals(text.languageTag));
        }
      });

      test('validates language tag presence on deserialization', () {
        const mapper = LocalizedTextMapper();
        final context = createDeserializationContext();

        // Test with proper language tag
        final validText = mapper.fromRdfTerm(
          LiteralTerm.withLanguage('Valid text', 'en'),
          context,
        );
        expect(validText.text, equals('Valid text'));
        expect(validText.languageTag, equals('en'));
      });

      test('handles datatype validation', () {
        const mapper = LocalizedTextMapper();
        final context = createDeserializationContext();

        // Test with bypass datatype check
        final text = mapper.fromRdfTerm(
          LiteralTerm.withLanguage('Test', 'en'),
          context,
          bypassDatatypeCheck: true,
        );
        expect(text.text, equals('Test'));
        expect(text.languageTag, equals('en'));

        // Test datatype mismatch without bypass
        expect(
          () => mapper.fromRdfTerm(
            LiteralTerm('Test without language',
                datatype:
                    const IriTerm('http://www.w3.org/2001/XMLSchema#string')),
            context,
            bypassDatatypeCheck: false,
          ),
          throwsA(isA<DeserializerDatatypeMismatchException>()),
        );
      });

      test('round-trip serialization maintains all properties', () {
        const mapper = LocalizedTextMapper();
        final serContext = createSerializationContext();
        final deserContext = createDeserializationContext();

        final testTexts = [
          LocalizedText('Simple text', 'en'),
          LocalizedText('Text with émojis 🎉', 'fr'),
          LocalizedText('Текст на русском', 'ru'),
          LocalizedText('日本語のテキスト', 'ja'),
          LocalizedText('', 'empty'),
          LocalizedText('Regional variant', 'en-US'),
        ];

        for (final originalText in testTexts) {
          final literalTerm = mapper.toRdfTerm(originalText, serContext);
          final deserializedText =
              mapper.fromRdfTerm(literalTerm, deserContext);

          expect(deserializedText.text, equals(originalText.text));
          expect(
              deserializedText.languageTag, equals(originalText.languageTag));
        }
      });
    });

    group('Integration and edge cases', () {
      test('all mappers handle null-safe operations', () {
        const enhancedRatingMapper = EnhancedRatingMapper();
        const temperatureMapper = TemperatureMapper();
        const localizedTextMapper = LocalizedTextMapper();

        final context = createSerializationContext();

        // Test that serialization doesn't throw on valid inputs
        expect(
          () => enhancedRatingMapper.toRdfTerm(EnhancedRating(3), context),
          returnsNormally,
        );
        expect(
          () => temperatureMapper.toRdfTerm(Temperature(25.0), context),
          returnsNormally,
        );
        expect(
          () => localizedTextMapper.toRdfTerm(
              LocalizedText('test', 'en'), context),
          returnsNormally,
        );
      });

      test('custom datatype preservation in Temperature', () {
        const mapper = TemperatureMapper();
        final context = createSerializationContext();

        final temp = Temperature(100.0);
        final literalTerm = mapper.toRdfTerm(temp, context);

        expect(literalTerm.datatype.value,
            equals('http://example.org/temperature'));
        expect(literalTerm.value, equals('100.0°C'));
      });

      test('language tag validation edge cases', () {
        const mapper = LocalizedTextMapper();
        final context = createSerializationContext();

        // Test various language tag formats
        final validLanguageTags = [
          'en',
          'en-US',
          'zh-Hans',
          'zh-Hant-CN',
          'x-custom',
          'i-enochian',
        ];

        for (final tag in validLanguageTags) {
          final text = LocalizedText('Test', tag);
          final literalTerm = mapper.toRdfTerm(text, context);
          expect(literalTerm.language, equals(tag));
        }
      });

      test('numeric precision in Temperature parsing', () {
        const mapper = TemperatureMapper();
        final deserContext = createDeserializationContext();

        final precisionTests = [
          '0.0°C',
          '0.1°C',
          '0.01°C',
          '0.001°C',
          '123.456789°C',
          '-273.15°C',
        ];

        for (final tempStr in precisionTests) {
          final temp = mapper.fromRdfTerm(
            LiteralTerm(tempStr,
                datatype: const IriTerm('http://example.org/temperature')),
            deserContext,
          );

          final expectedValue = double.parse(tempStr.replaceAll('°C', ''));
          expect(temp.celsius, equals(expectedValue));
        }
      });

      test('error handling in Temperature.parse', () {
        const mapper = TemperatureMapper();
        final context = createDeserializationContext();

        expect(
          () => mapper.fromRdfTerm(
            LiteralTerm('invalid temperature format',
                datatype: const IriTerm('http://example.org/temperature')),
            context,
          ),
          throwsA(isA<FormatException>()),
        );
      });
    });
  });
}
