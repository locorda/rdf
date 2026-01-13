import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/enum_test_models.dart';
// Import generated mappers
import '../fixtures/enum_test_models.rdf_mapper.g.dart';
import 'init_test_rdf_mapper_util.dart';

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

  group('Enum Mappers Test', () {
    group('RdfLiteral Enum Mappers', () {
      test('Priority enum - simple literal values', () {
        const mapper = PriorityMapper();
        final context = createSerializationContext();
        final deserContext = createDeserializationContext();

        // Test serialization
        final lowLiteral = mapper.toRdfTerm(Priority.low, context);
        expect(lowLiteral, isA<LiteralTerm>());
        expect(lowLiteral.value, equals('low'));

        final mediumLiteral = mapper.toRdfTerm(Priority.medium, context);
        expect(mediumLiteral, isA<LiteralTerm>());
        expect(mediumLiteral.value, equals('medium'));

        final highLiteral = mapper.toRdfTerm(Priority.high, context);
        expect(highLiteral, isA<LiteralTerm>());
        expect(highLiteral.value, equals('high'));

        // Test deserialization
        final lowDeserialized =
            mapper.fromRdfTerm(LiteralTerm('low'), deserContext);
        expect(lowDeserialized, equals(Priority.low));

        final mediumDeserialized =
            mapper.fromRdfTerm(LiteralTerm('medium'), deserContext);
        expect(mediumDeserialized, equals(Priority.medium));

        final highDeserialized =
            mapper.fromRdfTerm(LiteralTerm('high'), deserContext);
        expect(highDeserialized, equals(Priority.high));
      });

      test('Priority enum - round-trip consistency', () {
        const mapper = PriorityMapper();
        final context = createSerializationContext();
        final deserContext = createDeserializationContext();

        for (final priority in Priority.values) {
          final encoded = mapper.toRdfTerm(priority, context);
          final decoded = mapper.fromRdfTerm(encoded, deserContext);
          expect(decoded, equals(priority),
              reason: 'Round-trip should preserve value for $priority');
        }
      });

      test('Priority enum - invalid literal throws exception', () {
        const mapper = PriorityMapper();
        final deserContext = createDeserializationContext();

        expect(
          () => mapper.fromRdfTerm(LiteralTerm('invalid'), deserContext),
          throwsA(isA<DeserializationException>()),
        );
      });

      test('Status enum - custom literal values', () {
        const mapper = StatusMapper();
        final context = createSerializationContext();
        final deserContext = createDeserializationContext();

        // Test serialization with custom values
        final newLiteral = mapper.toRdfTerm(Status.newItem, context);
        expect(newLiteral, isA<LiteralTerm>());
        expect(newLiteral.value, equals('new'));

        final inProgressLiteral = mapper.toRdfTerm(Status.inProgress, context);
        expect(inProgressLiteral, isA<LiteralTerm>());
        expect(inProgressLiteral.value, equals('in-progress'));

        final completedLiteral = mapper.toRdfTerm(Status.completed, context);
        expect(completedLiteral, isA<LiteralTerm>());
        expect(completedLiteral.value, equals('completed'));

        // Test enum value without custom annotation (uses default name)
        final canceledLiteral = mapper.toRdfTerm(Status.canceled, context);
        expect(canceledLiteral, isA<LiteralTerm>());
        expect(canceledLiteral.value, equals('canceled'));

        // Test deserialization
        final newDeserialized =
            mapper.fromRdfTerm(LiteralTerm('new'), deserContext);
        expect(newDeserialized, equals(Status.newItem));

        final inProgressDeserialized =
            mapper.fromRdfTerm(LiteralTerm('in-progress'), deserContext);
        expect(inProgressDeserialized, equals(Status.inProgress));

        final completedDeserialized =
            mapper.fromRdfTerm(LiteralTerm('completed'), deserContext);
        expect(completedDeserialized, equals(Status.completed));

        final canceledDeserialized =
            mapper.fromRdfTerm(LiteralTerm('canceled'), deserContext);
        expect(canceledDeserialized, equals(Status.canceled));
      });

      test('Status enum - round-trip consistency', () {
        const mapper = StatusMapper();
        final context = createSerializationContext();
        final deserContext = createDeserializationContext();

        for (final status in Status.values) {
          final encoded = mapper.toRdfTerm(status, context);
          final decoded = mapper.fromRdfTerm(encoded, deserContext);
          expect(decoded, equals(status),
              reason: 'Round-trip should preserve value for $status');
        }
      });

      test('Status enum - invalid literal throws exception', () {
        const mapper = StatusMapper();
        final deserContext = createDeserializationContext();

        expect(
          () => mapper.fromRdfTerm(LiteralTerm('invalid'), deserContext),
          throwsA(isA<DeserializationException>()),
        );
      });
    });

    group('RdfIri Enum Mappers', () {
      test('DocumentType enum - direct IRI values (no template)', () {
        const mapper = DocumentTypeMapper();
        final context = createSerializationContext();
        final deserContext = createDeserializationContext();

        // Test serialization - should use direct IRI values
        final plainTextIri = mapper.toRdfTerm(DocumentType.plainText, context);
        expect(plainTextIri, isA<IriTerm>());
        expect(plainTextIri.value,
            equals('https://www.iana.org/assignments/media-types/text/plain'));

        final htmlIri = mapper.toRdfTerm(DocumentType.html, context);
        expect(htmlIri, isA<IriTerm>());
        expect(htmlIri.value,
            equals('https://www.iana.org/assignments/media-types/text/html'));

        final pdfIri = mapper.toRdfTerm(DocumentType.pdf, context);
        expect(pdfIri, isA<IriTerm>());
        expect(
            pdfIri.value,
            equals(
                'https://www.iana.org/assignments/media-types/application/pdf'));

        // Test deserialization
        final plainTextDeserialized = mapper.fromRdfTerm(
            const IriTerm(
                'https://www.iana.org/assignments/media-types/text/plain'),
            deserContext);
        expect(plainTextDeserialized, equals(DocumentType.plainText));

        final htmlDeserialized = mapper.fromRdfTerm(
            const IriTerm(
                'https://www.iana.org/assignments/media-types/text/html'),
            deserContext);
        expect(htmlDeserialized, equals(DocumentType.html));

        final pdfDeserialized = mapper.fromRdfTerm(
            const IriTerm(
                'https://www.iana.org/assignments/media-types/application/pdf'),
            deserContext);
        expect(pdfDeserialized, equals(DocumentType.pdf));
      });

      test('DocumentType enum - round-trip consistency', () {
        const mapper = DocumentTypeMapper();
        final context = createSerializationContext();
        final deserContext = createDeserializationContext();

        for (final docType in DocumentType.values) {
          final encoded = mapper.toRdfTerm(docType, context);
          final decoded = mapper.fromRdfTerm(encoded, deserContext);
          expect(decoded, equals(docType),
              reason: 'Round-trip should preserve value for $docType');
        }
      });

      test('CategoryType enum - IRI template with value placeholder', () {
        const mapper = CategoryTypeMapper();
        final context = createSerializationContext();
        final deserContext = createDeserializationContext();

        // Test serialization - should use template with value substitution
        final booksIri = mapper.toRdfTerm(CategoryType.books, context);
        expect(booksIri, isA<IriTerm>());
        expect(booksIri.value, equals('https://example.org/types/books'));

        final musicIri = mapper.toRdfTerm(CategoryType.music, context);
        expect(musicIri, isA<IriTerm>());
        expect(musicIri.value, equals('https://example.org/types/music'));

        final electronicsIri =
            mapper.toRdfTerm(CategoryType.electronics, context);
        expect(electronicsIri, isA<IriTerm>());
        expect(electronicsIri.value,
            equals('https://example.org/types/electronics'));

        // Test deserialization - should parse IRI template
        final booksDeserialized = mapper.fromRdfTerm(
            const IriTerm('https://example.org/types/books'), deserContext);
        expect(booksDeserialized, equals(CategoryType.books));

        final musicDeserialized = mapper.fromRdfTerm(
            const IriTerm('https://example.org/types/music'), deserContext);
        expect(musicDeserialized, equals(CategoryType.music));

        final electronicsDeserialized = mapper.fromRdfTerm(
            const IriTerm('https://example.org/types/electronics'),
            deserContext);
        expect(electronicsDeserialized, equals(CategoryType.electronics));
      });

      test('CategoryType enum - round-trip consistency', () {
        const mapper = CategoryTypeMapper();
        final context = createSerializationContext();
        final deserContext = createDeserializationContext();

        for (final category in CategoryType.values) {
          final encoded = mapper.toRdfTerm(category, context);
          final decoded = mapper.fromRdfTerm(encoded, deserContext);
          expect(decoded, equals(category),
              reason: 'Round-trip should preserve value for $category');
        }
      });

      test('CategoryType enum - invalid IRI throws exception', () {
        const mapper = CategoryTypeMapper();
        final deserContext = createDeserializationContext();

        expect(
          () => mapper.fromRdfTerm(
              const IriTerm('https://example.org/types/invalid'), deserContext),
          throwsA(isA<DeserializationException>()),
        );
      });

      test('CategoryType enum - malformed IRI throws exception', () {
        const mapper = CategoryTypeMapper();
        final deserContext = createDeserializationContext();

        expect(
          () => mapper.fromRdfTerm(
              const IriTerm('https://different.org/types/books'), deserContext),
          throwsA(isA<DeserializationException>()),
        );
      });
    });

    group('RdfIri Enum Mappers with Context Variables', () {
      test('FileFormat enum - IRI template with baseUri context variable', () {
        // FileFormat uses template: '{+baseUri}/formats/{value}'
        // The mapper requires a baseUri provider
        final mapper =
            FileFormatMapper(baseUriProvider: () => 'https://example.org');
        final context = createSerializationContext();
        final deserContext = createDeserializationContext();

        // Test serialization with baseUri provider
        final textIri = mapper.toRdfTerm(FileFormat.text, context);
        expect(textIri, isA<IriTerm>());
        expect(textIri.value, equals('https://example.org/formats/text'));

        final binaryIri = mapper.toRdfTerm(FileFormat.binary, context);
        expect(binaryIri, isA<IriTerm>());
        expect(binaryIri.value, equals('https://example.org/formats/binary'));

        final xmlIri = mapper.toRdfTerm(FileFormat.xml, context);
        expect(xmlIri, isA<IriTerm>());
        expect(xmlIri.value, equals('https://example.org/formats/xml'));

        // Test deserialization
        final textDeserialized = mapper.fromRdfTerm(
            const IriTerm('https://example.org/formats/text'), deserContext);
        expect(textDeserialized, equals(FileFormat.text));

        final binaryDeserialized = mapper.fromRdfTerm(
            const IriTerm('https://example.org/formats/binary'), deserContext);
        expect(binaryDeserialized, equals(FileFormat.binary));

        final xmlDeserialized = mapper.fromRdfTerm(
            const IriTerm('https://example.org/formats/xml'), deserContext);
        expect(xmlDeserialized, equals(FileFormat.xml));
      });

      test('FileFormat enum - round-trip consistency', () {
        final mapper =
            FileFormatMapper(baseUriProvider: () => 'https://example.org');
        final context = createSerializationContext();
        final deserContext = createDeserializationContext();

        for (final format in FileFormat.values) {
          final encoded = mapper.toRdfTerm(format, context);
          final decoded = mapper.fromRdfTerm(encoded, deserContext);
          expect(decoded, equals(format),
              reason: 'Round-trip should preserve value for $format');
        }
      });

      test('ItemType enum - IRI template with multiple context variables', () {
        // ItemType uses template: '{+baseUri}/types/{category}/{value}'
        // The mapper requires baseUri and category providers
        final mapper = ItemTypeMapper(
          baseUriProvider: () => 'https://example.org',
          categoryProvider: () => 'literature',
        );
        final context = createSerializationContext();
        final deserContext = createDeserializationContext();

        // Test serialization with multiple providers
        final bookIri = mapper.toRdfTerm(ItemType.book, context);
        expect(bookIri, isA<IriTerm>());
        expect(
            bookIri.value, equals('https://example.org/types/literature/book'));

        final magazineIri = mapper.toRdfTerm(ItemType.magazine, context);
        expect(magazineIri, isA<IriTerm>());
        expect(magazineIri.value,
            equals('https://example.org/types/literature/magazine'));

        final newspaperIri = mapper.toRdfTerm(ItemType.newspaper, context);
        expect(newspaperIri, isA<IriTerm>());
        expect(newspaperIri.value,
            equals('https://example.org/types/literature/newspaper'));

        // Test deserialization
        final bookDeserialized = mapper.fromRdfTerm(
            const IriTerm('https://example.org/types/literature/book'),
            deserContext);
        expect(bookDeserialized, equals(ItemType.book));

        final magazineDeserialized = mapper.fromRdfTerm(
            const IriTerm('https://example.org/types/literature/magazine'),
            deserContext);
        expect(magazineDeserialized, equals(ItemType.magazine));

        final newspaperDeserialized = mapper.fromRdfTerm(
            const IriTerm('https://example.org/types/literature/newspaper'),
            deserContext);
        expect(newspaperDeserialized, equals(ItemType.newspaper));
      });

      test('ItemType enum - round-trip consistency', () {
        final mapper = ItemTypeMapper(
          baseUriProvider: () => 'https://example.org',
          categoryProvider: () => 'literature',
        );
        final context = createSerializationContext();
        final deserContext = createDeserializationContext();

        for (final itemType in ItemType.values) {
          final encoded = mapper.toRdfTerm(itemType, context);
          final decoded = mapper.fromRdfTerm(encoded, deserContext);
          expect(decoded, equals(itemType),
              reason: 'Round-trip should preserve value for $itemType');
        }
      });
    });

    group('Enum Mappers Error Handling', () {
      test('should handle all enum values consistently', () {
        final allTests = [
          () {
            const mapper = PriorityMapper();
            final context = createSerializationContext();
            final deserContext = createDeserializationContext();
            for (final value in Priority.values) {
              final encoded = mapper.toRdfTerm(value, context);
              final decoded = mapper.fromRdfTerm(encoded, deserContext);
              expect(decoded, equals(value));
            }
          },
          () {
            const mapper = StatusMapper();
            final context = createSerializationContext();
            final deserContext = createDeserializationContext();
            for (final value in Status.values) {
              final encoded = mapper.toRdfTerm(value, context);
              final decoded = mapper.fromRdfTerm(encoded, deserContext);
              expect(decoded, equals(value));
            }
          },
          () {
            const mapper = DocumentTypeMapper();
            final context = createSerializationContext();
            final deserContext = createDeserializationContext();
            for (final value in DocumentType.values) {
              final encoded = mapper.toRdfTerm(value, context);
              final decoded = mapper.fromRdfTerm(encoded, deserContext);
              expect(decoded, equals(value));
            }
          },
          () {
            const mapper = CategoryTypeMapper();
            final context = createSerializationContext();
            final deserContext = createDeserializationContext();
            for (final value in CategoryType.values) {
              final encoded = mapper.toRdfTerm(value, context);
              final decoded = mapper.fromRdfTerm(encoded, deserContext);
              expect(decoded, equals(value));
            }
          },
          () {
            final mapper =
                FileFormatMapper(baseUriProvider: () => 'https://example.org');
            final context = createSerializationContext();
            final deserContext = createDeserializationContext();
            for (final value in FileFormat.values) {
              final encoded = mapper.toRdfTerm(value, context);
              final decoded = mapper.fromRdfTerm(encoded, deserContext);
              expect(decoded, equals(value));
            }
          },
          () {
            final mapper = ItemTypeMapper(
              baseUriProvider: () => 'https://example.org',
              categoryProvider: () => 'literature',
            );
            final context = createSerializationContext();
            final deserContext = createDeserializationContext();
            for (final value in ItemType.values) {
              final encoded = mapper.toRdfTerm(value, context);
              final decoded = mapper.fromRdfTerm(encoded, deserContext);
              expect(decoded, equals(value));
            }
          },
        ];

        for (final test in allTests) {
          test();
        }
      });
    });

    group('Generated Code Structure Verification', () {
      test('Priority and Status mappers should implement LiteralTermMapper',
          () {
        // Verify Priority mapper
        const priorityMapper = PriorityMapper();
        expect(priorityMapper, isA<LiteralTermMapper<Priority>>());

        // Verify Status mapper
        const statusMapper = StatusMapper();
        expect(statusMapper, isA<LiteralTermMapper<Status>>());
      });

      test(
          'DocumentType, CategoryType, FileFormat, and ItemType mappers should implement IriTermMapper',
          () {
        // Verify DocumentType mapper
        const docTypeMapper = DocumentTypeMapper();
        expect(docTypeMapper, isA<IriTermMapper<DocumentType>>());

        // Verify CategoryType mapper
        const categoryMapper = CategoryTypeMapper();
        expect(categoryMapper, isA<IriTermMapper<CategoryType>>());

        // Verify FileFormat mapper
        final fileFormatMapper =
            FileFormatMapper(baseUriProvider: () => 'https://example.org');
        expect(fileFormatMapper, isA<IriTermMapper<FileFormat>>());

        // Verify ItemType mapper
        final itemTypeMapper = ItemTypeMapper(
          baseUriProvider: () => 'https://example.org',
          categoryProvider: () => 'literature',
        );
        expect(itemTypeMapper, isA<IriTermMapper<ItemType>>());
      });

      test('DocumentType mapper should use direct IRI access (optimized)', () {
        const mapper = DocumentTypeMapper();
        final context = createSerializationContext();

        // DocumentType has no template, so should use direct IRI access
        final iri = mapper.toRdfTerm(DocumentType.plainText, context);
        expect(iri.value,
            equals('https://www.iana.org/assignments/media-types/text/plain'));

        // Verify the generated code structure through the _buildIri method behavior
        // This is tested indirectly through the round-trip tests
      });

      test('CategoryType mapper should use regex parsing (template-based)', () {
        const mapper = CategoryTypeMapper();
        final context = createSerializationContext();

        // CategoryType has template 'https://example.org/types/{value}'
        // So it should use template substitution for serialization
        final iri = mapper.toRdfTerm(CategoryType.books, context);
        expect(iri.value, equals('https://example.org/types/books'));

        // Verify the generated code uses regex for deserialization
        // This is tested indirectly through the round-trip tests
      });

      test('Context variable providers work correctly', () {
        // Test FileFormat with different baseUri values
        final mapper1 =
            FileFormatMapper(baseUriProvider: () => 'https://example.org');
        final mapper2 =
            FileFormatMapper(baseUriProvider: () => 'https://different.org');
        final context = createSerializationContext();

        final iri1 = mapper1.toRdfTerm(FileFormat.text, context);
        final iri2 = mapper2.toRdfTerm(FileFormat.text, context);

        expect(iri1.value, equals('https://example.org/formats/text'));
        expect(iri2.value, equals('https://different.org/formats/text'));
        expect(iri1.value, isNot(equals(iri2.value)));
      });
    });
  });
}
