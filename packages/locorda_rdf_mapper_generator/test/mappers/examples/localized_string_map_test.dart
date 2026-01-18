import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:locorda_rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:test/test.dart';

// Import test models
import '../../fixtures/locorda_rdf_mapper_annotations/examples/localized_string_map.dart';
// Import generated mappers
import '../../fixtures/locorda_rdf_mapper_annotations/examples/localized_string_map.rdf_mapper.g.dart';
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

  group('Localized String Map Test', () {
    group('LocalizedEntryMapper', () {
      test('serializes MapEntry to localized literal', () {
        const mapper = LocalizedEntryMapper();
        final context = createSerializationContext();

        final entry = MapEntry('en', 'Hello World');
        final literalTerm = mapper.toRdfTerm(entry, context);

        expect(literalTerm.value, equals('Hello World'));
        expect(literalTerm.language, equals('en'));
      });

      test('deserializes localized literal to MapEntry', () {
        const mapper = LocalizedEntryMapper();
        final context = createDeserializationContext();

        final entry = mapper.fromRdfTerm(
          LiteralTerm.withLanguage('Bonjour le monde', 'fr'),
          context,
        );

        expect(entry.key, equals('fr'));
        expect(entry.value, equals('Bonjour le monde'));
      });

      test('handles missing language tag by defaulting to "en"', () {
        const mapper = LocalizedEntryMapper();
        final context = createDeserializationContext();

        final entry = mapper.fromRdfTerm(
          LiteralTerm('Default text'),
          context,
        );

        expect(entry.key, equals('en'));
        expect(entry.value, equals('Default text'));
      });

      test('handles various language codes', () {
        const mapper = LocalizedEntryMapper();
        final context = createSerializationContext();

        final languages = {
          'en': 'Hello',
          'fr': 'Bonjour',
          'de': 'Hallo',
          'es': 'Hola',
          'it': 'Ciao',
          'pt': 'Olá',
          'ja': 'こんにちは',
          'zh': '你好',
          'ko': '안녕하세요',
          'ru': 'Привет',
        };

        for (final entry in languages.entries) {
          final mapEntry = MapEntry(entry.key, entry.value);
          final literalTerm = mapper.toRdfTerm(mapEntry, context);

          expect(literalTerm.language, equals(entry.key));
          expect(literalTerm.value, equals(entry.value));
        }
      });

      test('handles regional language variants', () {
        const mapper = LocalizedEntryMapper();
        final context = createSerializationContext();

        final regionalVariants = {
          'en-US': 'Color',
          'en-GB': 'Colour',
          'de-DE': 'Deutsch',
          'de-CH': 'Schweizerdeutsch',
          'pt-BR': 'Português brasileiro',
          'pt-PT': 'Português europeu',
        };

        for (final entry in regionalVariants.entries) {
          final mapEntry = MapEntry(entry.key, entry.value);
          final literalTerm = mapper.toRdfTerm(mapEntry, context);

          expect(literalTerm.language, equals(entry.key));
          expect(literalTerm.value, equals(entry.value));
        }
      });

      test('handles empty and special text content', () {
        const mapper = LocalizedEntryMapper();
        final context = createSerializationContext();

        final specialTexts = {
          'en': '',
          'fr': 'Text with "quotes"',
          'de': 'Text with <brackets>',
          'es': 'Text with & ampersands',
          'it': 'Text\nwith\nnewlines',
          'pt': 'Text\twith\ttabs',
          'ja': 'テキスト with mixed scripts',
          'emoji': 'Text with 🎉 emojis 🚀',
        };

        for (final entry in specialTexts.entries) {
          final mapEntry = MapEntry(entry.key, entry.value);
          final literalTerm = mapper.toRdfTerm(mapEntry, context);

          expect(literalTerm.language, equals(entry.key));
          expect(literalTerm.value, equals(entry.value));

          // Test round-trip
          final deserContext = createDeserializationContext();
          final deserializedEntry =
              mapper.fromRdfTerm(literalTerm, deserContext);
          expect(deserializedEntry.key, equals(entry.key));
          expect(deserializedEntry.value, equals(entry.value));
        }
      });

      test('round-trip serialization maintains all data', () {
        const mapper = LocalizedEntryMapper();
        final serContext = createSerializationContext();
        final deserContext = createDeserializationContext();

        final testEntries = [
          MapEntry('en', 'English text'),
          MapEntry('fr', 'Texte français'),
          MapEntry('de', 'Deutscher Text'),
          MapEntry('zh-Hans', '简体中文'),
          MapEntry('zh-Hant', '繁體中文'),
          MapEntry('ar', 'النص العربي'),
          MapEntry('he', 'טקסט עברי'),
          MapEntry('custom', 'Custom language code'),
        ];

        for (final originalEntry in testEntries) {
          final literalTerm = mapper.toRdfTerm(originalEntry, serContext);
          final deserializedEntry =
              mapper.fromRdfTerm(literalTerm, deserContext);

          expect(deserializedEntry.key, equals(originalEntry.key));
          expect(deserializedEntry.value, equals(originalEntry.value));
        }
      });
    });

    group('Book class with localized translations', () {
      test('serializes book with multiple translations', () {
        const mapper = BookMapper();
        final context = createSerializationContext();

        final translations = {
          'en': 'The Hobbit',
          'fr': 'Bilbo le Hobbit',
          'de': 'Der Hobbit',
          'es': 'El Hobbit',
        };

        final book = Book(translations: translations);
        final (subject, triples) = mapper.toRdfResource(book, context);

        expect(subject, isA<BlankNodeTerm>());
        expect(triples.length, equals(translations.length));

        final titleProperty = const IriTerm('http://example.org/book/title');
        final titleTriples = triples.where((t) => t.predicate == titleProperty);
        expect(titleTriples.length, equals(translations.length));

        // Check that each language is represented
        final actualTranslations = <String, String>{};
        for (final triple in titleTriples) {
          final literal = triple.object as LiteralTerm;
          actualTranslations[literal.language!] = literal.value;
        }

        expect(actualTranslations, equals(translations));
      });

      test('deserializes book from multiple translation triples', () {
        final blankNode = BlankNodeTerm();
        final titleProperty = const IriTerm('http://example.org/book/title');

        final triples = [
          Triple(blankNode, titleProperty,
              LiteralTerm.withLanguage('The Hobbit', 'en')),
          Triple(blankNode, titleProperty,
              LiteralTerm.withLanguage('Bilbo le Hobbit', 'fr')),
          Triple(blankNode, titleProperty,
              LiteralTerm.withLanguage('Der Hobbit', 'de')),
          Triple(blankNode, titleProperty,
              LiteralTerm.withLanguage('El Hobbit', 'es')),
          Triple(blankNode, titleProperty,
              LiteralTerm.withLanguage('Lo Hobbit', 'it')),
        ];

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        const bookMapper = BookMapper();
        final book = bookMapper.fromRdfResource(blankNode, context);

        final expectedTranslations = {
          'en': 'The Hobbit',
          'fr': 'Bilbo le Hobbit',
          'de': 'Der Hobbit',
          'es': 'El Hobbit',
          'it': 'Lo Hobbit',
        };

        expect(book.translations, equals(expectedTranslations));
      });

      test('handles book with single translation', () {
        const mapper = BookMapper();
        final context = createSerializationContext();

        final book = Book(translations: {'en': 'Single Title'});
        final (subject, triples) = mapper.toRdfResource(book, context);

        expect(triples.length, equals(1));
        final triple = triples.first;
        final literal = triple.object as LiteralTerm;
        expect(literal.value, equals('Single Title'));
        expect(literal.language, equals('en'));
      });

      test('handles book with empty translations map', () {
        const mapper = BookMapper();
        final context = createSerializationContext();

        final book = Book(translations: {});
        final (subject, triples) = mapper.toRdfResource(book, context);

        expect(triples.length, equals(0));
      });

      test('handles translations with missing language tags', () {
        final blankNode = BlankNodeTerm();
        final titleProperty = const IriTerm('http://example.org/book/title');

        final triples = [
          Triple(blankNode, titleProperty,
              LiteralTerm.withLanguage('English Title', 'en')),
          Triple(blankNode, titleProperty,
              LiteralTerm('Default Title')), // No language tag
          Triple(blankNode, titleProperty,
              LiteralTerm.withLanguage('French Title', 'fr')),
        ];

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        const bookMapper = BookMapper();
        final book = bookMapper.fromRdfResource(blankNode, context);

        expect(book.translations['en'],
            anyOf(equals('English Title'), equals('Default Title')));
        expect(book.translations['fr'], equals('French Title'));
        expect(book.translations.length, greaterThanOrEqualTo(2));
      });

      test('handles translations with duplicate language codes', () {
        final blankNode = BlankNodeTerm();
        final titleProperty = const IriTerm('http://example.org/book/title');

        final triples = [
          Triple(blankNode, titleProperty,
              LiteralTerm.withLanguage('First English Title', 'en')),
          Triple(blankNode, titleProperty,
              LiteralTerm.withLanguage('Second English Title', 'en')),
          Triple(blankNode, titleProperty,
              LiteralTerm.withLanguage('French Title', 'fr')),
        ];

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        const bookMapper = BookMapper();
        final book = bookMapper.fromRdfResource(blankNode, context);

        // The map should contain one entry per language
        // The last value should override previous ones
        expect(book.translations['en'], equals('Second English Title'));
        expect(book.translations['fr'], equals('French Title'));
        expect(book.translations.length, equals(2));
      });

      test('round-trip serialization maintains all translations', () {
        const bookMapper = BookMapper();
        final serContext = createSerializationContext();

        final originalTranslations = {
          'en': 'The Lord of the Rings',
          'fr': 'Le Seigneur des anneaux',
          'de': 'Der Herr der Ringe',
          'es': 'El Señor de los Anillos',
          'it': 'Il Signore degli Anelli',
          'pt': 'O Senhor dos Anéis',
          'ru': 'Властелин колец',
          'ja': '指輪物語',
          'zh': '魔戒',
        };

        final originalBook = Book(translations: originalTranslations);
        final (subject, triples) =
            bookMapper.toRdfResource(originalBook, serContext);

        final graph = RdfGraph.fromTriples(triples);
        final deserContext = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        final deserializedBook =
            bookMapper.fromRdfResource(subject, deserContext);

        expect(deserializedBook.translations, equals(originalTranslations));
      });

      test('handles translations with Unicode content', () {
        const mapper = BookMapper();
        final context = createSerializationContext();

        final unicodeTranslations = {
          'ar': 'كتاب الهوبيت',
          'he': 'ההוביט',
          'th': 'เดอะ ฮอบบิท',
          'hi': 'द हॉबिट',
          'emoji': '📚 The Book 📖',
          'mixed': 'Book with العربية and עברית',
        };

        final book = Book(translations: unicodeTranslations);
        final (subject, triples) = mapper.toRdfResource(book, context);

        final titleProperty = const IriTerm('http://example.org/book/title');
        final titleTriples = triples.where((t) => t.predicate == titleProperty);

        final actualTranslations = <String, String>{};
        for (final triple in titleTriples) {
          final literal = triple.object as LiteralTerm;
          actualTranslations[literal.language!] = literal.value;
        }

        expect(actualTranslations, equals(unicodeTranslations));
      });
    });

    group('Edge cases and validation', () {
      test('mapper handles extremely long text values', () {
        const entryMapper = LocalizedEntryMapper();
        final context = createSerializationContext();

        final longText = 'A' * 10000; // Very long string
        final entry = MapEntry('en', longText);
        final literalTerm = entryMapper.toRdfTerm(entry, context);

        expect(literalTerm.value, equals(longText));
        expect(literalTerm.language, equals('en'));
      });

      test('mapper handles special language codes', () {
        const entryMapper = LocalizedEntryMapper();
        final context = createSerializationContext();

        final specialLanguageCodes = [
          'x-custom',
          'i-enochian',
          'und', // undefined
          'mul', // multiple languages
          'zxx', // no linguistic content
        ];

        for (final langCode in specialLanguageCodes) {
          final entry = MapEntry(langCode, 'Test text');
          final literalTerm = entryMapper.toRdfTerm(entry, context);
          expect(literalTerm.language, equals(langCode));
        }
      });

      test('custom mapper instance usage', () {
        final customMapper = BookMapper(
          translationsMapper: const LocalizedEntryMapper(),
        );
        final context = createSerializationContext();

        final book = Book(translations: {'custom': 'Custom mapped text'});
        final (subject, triples) = customMapper.toRdfResource(book, context);

        expect(triples.length, equals(1));
        final literal = triples.first.object as LiteralTerm;
        expect(literal.value, equals('Custom mapped text'));
        expect(literal.language, equals('custom'));
      });
    });
  });
}
