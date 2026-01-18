import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:locorda_rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';
import 'package:test/test.dart';

// Import test models
import '../../fixtures/locorda_rdf_mapper_annotations/examples/example_full_book.dart';
// Import generated mappers
import '../../fixtures/locorda_rdf_mapper_annotations/examples/example_full_book.rdf_mapper.g.dart';
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

  group('Full Book Example Test', () {
    group('ISBN class (IRI-based)', () {
      test('serializes to URN ISBN format', () {
        const mapper = ISBNMapper();
        final context = createSerializationContext();

        final isbn = ISBN('9780261102217');
        final iriTerm = mapper.toRdfTerm(isbn, context);

        expect(iriTerm, isA<IriTerm>());
        expect(iriTerm.value, equals('urn:isbn:9780261102217'));
      });

      test('deserializes from URN ISBN format', () {
        const mapper = ISBNMapper();
        final context = createDeserializationContext();

        final isbn = mapper.fromRdfTerm(
          const IriTerm('urn:isbn:9780141184821'),
          context,
        );

        expect(isbn.value, equals('9780141184821'));
      });

      test('handles ISBN-10 format', () {
        const mapper = ISBNMapper();
        final context = createSerializationContext();

        final isbn = ISBN('0261102214');
        final iriTerm = mapper.toRdfTerm(isbn, context);

        expect(iriTerm.value, equals('urn:isbn:0261102214'));
      });

      test('handles ISBN with X check digit', () {
        const mapper = ISBNMapper();
        final context = createSerializationContext();

        final isbn = ISBN('026110221X');
        final iriTerm = mapper.toRdfTerm(isbn, context);

        expect(iriTerm.value, equals('urn:isbn:026110221X'));
      });
    });

    group('Rating class (literal-based)', () {
      test('serializes rating to literal', () {
        const mapper = RatingMapper();
        final context = createSerializationContext();

        final rating = Rating(5);
        final literalTerm = mapper.toRdfTerm(rating, context);

        expect(literalTerm, isA<LiteralTerm>());
        expect(literalTerm.value, equals('5'));
        expect(literalTerm.datatype.value, contains('XMLSchema'));
      });

      test('deserializes rating from literal', () {
        const mapper = RatingMapper();
        final context = createDeserializationContext();

        final rating = mapper.fromRdfTerm(
          LiteralTerm('4',
              datatype:
                  const IriTerm('http://www.w3.org/2001/XMLSchema#integer')),
          context,
        );

        expect(rating.stars, equals(4));
      });

      test('validates rating range in constructor', () {
        expect(() => Rating(5), returnsNormally);
        expect(() => Rating(0), returnsNormally);
        expect(() => Rating(-1), throwsA(isA<ArgumentError>()));
        expect(() => Rating(6), throwsA(isA<ArgumentError>()));
      });

      test('handles edge case ratings', () {
        const mapper = RatingMapper();
        final context = createSerializationContext();

        final minRating = Rating(0);
        final maxRating = Rating(5);

        final minTerm = mapper.toRdfTerm(minRating, context);
        final maxTerm = mapper.toRdfTerm(maxRating, context);

        expect(minTerm.value, equals('0'));
        expect(maxTerm.value, equals('5'));
      });
    });

    group('Chapter class (local resource)', () {
      test('serializes chapter as blank node', () {
        const mapper = ChapterMapper();
        final context = createSerializationContext();

        final chapter = Chapter('The Shire', 1);
        final (subject, triples) = mapper.toRdfResource(chapter, context);

        expect(subject, isA<BlankNodeTerm>());
        expect(triples.length, equals(2));

        final titleTriple = triples.firstWhere(
          (t) => t.predicate == SchemaChapter.name,
        );
        expect((titleTriple.object as LiteralTerm).value, equals('The Shire'));

        final positionTriple = triples.firstWhere(
          (t) => t.predicate == SchemaChapter.position,
        );
        expect((positionTriple.object as LiteralTerm).value, equals('1'));
      });

      test('deserializes chapter from blank node', () {
        final blankNode = BlankNodeTerm();
        final triples = [
          Triple(
            blankNode,
            SchemaChapter.name,
            LiteralTerm('Riddles in the Dark'),
          ),
          Triple(
            blankNode,
            SchemaChapter.position,
            LiteralTerm('5',
                datatype:
                    const IriTerm('http://www.w3.org/2001/XMLSchema#integer')),
          ),
        ];

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        const chapterMapper = ChapterMapper();
        final chapter = chapterMapper.fromRdfResource(blankNode, context);

        expect(chapter.title, equals('Riddles in the Dark'));
        expect(chapter.number, equals(5));
      });

      test('handles chapters with special characters in titles', () {
        const mapper = ChapterMapper();
        final context = createSerializationContext();

        final chapter = Chapter('Chapter with "Quotes" & Special chars', 42);
        final (subject, triples) = mapper.toRdfResource(chapter, context);

        final titleTriple = triples.firstWhere(
          (t) => t.predicate == SchemaChapter.name,
        );
        expect(
          (titleTriple.object as LiteralTerm).value,
          equals('Chapter with "Quotes" & Special chars'),
        );
      });
    });

    group('BookAuthorIdMapper (IRI mapping)', () {
      test('serializes author ID to IRI', () {
        const mapper = BookAuthorIdMapper();
        final context = createSerializationContext();

        final authorIri = mapper.toRdfTerm('tolkien', context);

        expect(authorIri.value, equals('http://example.org/author/tolkien'));
      });

      test('deserializes author ID from IRI', () {
        const mapper = BookAuthorIdMapper();
        final context = createDeserializationContext();

        final authorId = mapper.fromRdfTerm(
          const IriTerm('http://example.org/author/rowling'),
          context,
        );

        expect(authorId, equals('rowling'));
      });

      test('handles author IDs with special characters', () {
        const mapper = BookAuthorIdMapper();
        final context = createSerializationContext();

        final authorIri = mapper.toRdfTerm('martin-george-r-r', context);
        expect(authorIri.value,
            equals('http://example.org/author/martin-george-r-r'));

        final deserContext = createDeserializationContext();
        final authorId = mapper.fromRdfTerm(authorIri, deserContext);
        expect(authorId, equals('martin-george-r-r'));
      });
    });

    group('Book class (complete integration)', () {
      test('serializes complete book with all nested objects', () {
        const bookMapper = BookMapper();
        final context = createSerializationContext();

        final chapters = [
          Chapter('An Unexpected Party', 1),
          Chapter('Roast Mutton', 2),
          Chapter('A Short Rest', 3),
        ];

        final book = Book(
          id: 'hobbit',
          title: 'The Hobbit',
          authorId: 'tolkien',
          published: DateTime.utc(1937, 9, 21),
          isbn: ISBN('9780261102217'),
          rating: Rating(5),
          chapters: chapters,
          format: BookFormat.hardcover,
        );

        final (subject, triples) = bookMapper.toRdfResource(book, context);

        expect(subject.value, equals('http://example.org/book/hobbit'));
        expect(triples.length, greaterThan(5));

        // Check title
        final titleTriple = triples.firstWhere(
          (t) => t.predicate == SchemaBook.name,
        );
        expect((titleTriple.object as LiteralTerm).value, equals('The Hobbit'));

        // Check author IRI
        final authorTriple = triples.firstWhere(
          (t) => t.predicate == SchemaBook.author,
        );
        expect(
          (authorTriple.object as IriTerm).value,
          equals('http://example.org/author/tolkien'),
        );

        // Check publication date
        final pubTriple = triples.firstWhere(
          (t) => t.predicate == SchemaBook.datePublished,
        );
        expect(
          (pubTriple.object as LiteralTerm).value,
          equals('1937-09-21T00:00:00.000Z'),
        );

        // Check ISBN IRI
        final isbnTriple = triples.firstWhere(
          (t) => t.predicate == SchemaBook.isbn,
        );
        expect(
          (isbnTriple.object as IriTerm).value,
          equals('urn:isbn:9780261102217'),
        );

        // Check rating
        final ratingTriple = triples.firstWhere(
          (t) => t.predicate == SchemaBook.aggregateRating,
        );
        expect((ratingTriple.object as LiteralTerm).value, equals('5'));

        // Check chapters (should be blank nodes)
        final chapterTriples = triples.where(
          (t) => t.predicate == SchemaBook.hasPart,
        );
        expect(chapterTriples.length, equals(3));

        for (final chapterTriple in chapterTriples) {
          expect(chapterTriple.object, isA<BlankNodeTerm>());
        }
      });

      test('deserializes complete book from RDF graph', () {
        final chapterBn1 = BlankNodeTerm();
        final chapterBn2 = BlankNodeTerm();
        final chapterBn3 = BlankNodeTerm();

        final triples = [
          // Book properties
          Triple(
            const IriTerm('http://example.org/book/lotr'),
            SchemaBook.name,
            LiteralTerm('The Lord of the Rings'),
          ),
          Triple(
            const IriTerm('http://example.org/book/lotr'),
            SchemaBook.author,
            const IriTerm('http://example.org/author/tolkien'),
          ),
          Triple(
            const IriTerm('http://example.org/book/lotr'),
            SchemaBook.datePublished,
            LiteralTerm(
              '1954-07-29T00:00:00.000Z',
              datatype:
                  const IriTerm('http://www.w3.org/2001/XMLSchema#dateTime'),
            ),
          ),
          Triple(
            const IriTerm('http://example.org/book/lotr'),
            SchemaBook.isbn,
            const IriTerm('urn:isbn:9780261102385'),
          ),
          Triple(
            const IriTerm('http://example.org/book/lotr'),
            SchemaBook.aggregateRating,
            LiteralTerm('5',
                datatype:
                    const IriTerm('http://www.w3.org/2001/XMLSchema#int')),
          ),
          Triple(
            const IriTerm('http://example.org/book/lotr'),
            SchemaBook.hasPart,
            chapterBn1,
          ),
          Triple(
            const IriTerm('http://example.org/book/lotr'),
            SchemaBook.hasPart,
            chapterBn2,
          ),
          Triple(
            const IriTerm('http://example.org/book/lotr'),
            SchemaBook.hasPart,
            chapterBn3,
          ),
          // Chapter 1
          Triple(chapterBn1, SchemaChapter.name,
              LiteralTerm('A Long-expected Party')),
          Triple(
              chapterBn1,
              SchemaChapter.position,
              LiteralTerm('1',
                  datatype:
                      const IriTerm('http://www.w3.org/2001/XMLSchema#int'))),
          // Chapter 2
          Triple(chapterBn2, SchemaChapter.name,
              LiteralTerm('The Shadow of the Past')),
          Triple(
              chapterBn2,
              SchemaChapter.position,
              LiteralTerm('2',
                  datatype:
                      const IriTerm('http://www.w3.org/2001/XMLSchema#int'))),
          // Chapter 3
          Triple(
              chapterBn3, SchemaChapter.name, LiteralTerm('Three is Company')),
          Triple(
              chapterBn3,
              SchemaChapter.position,
              LiteralTerm('3',
                  datatype:
                      const IriTerm('http://www.w3.org/2001/XMLSchema#int'))),
        ];
        final myRegistry = mapper.registry.clone()
          ..registerMapper(IntMapper(Xsd.int));
        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: myRegistry,
        );

        const bookMapper = BookMapper();
        final book = bookMapper.fromRdfResource(
          const IriTerm('http://example.org/book/lotr'),
          context,
        );

        expect(book.id, equals('lotr'));
        expect(book.title, equals('The Lord of the Rings'));
        expect(book.authorId, equals('tolkien'));
        expect(book.published, equals(DateTime.utc(1954, 7, 29)));
        expect(book.isbn.value, equals('9780261102385'));
        expect(book.rating.stars, equals(5));
        expect(book.chapters.length, equals(3));

        final chapterList = book.chapters.toList();
        expect(chapterList[0].title, equals('A Long-expected Party'));
        expect(chapterList[0].number, equals(1));
        expect(chapterList[1].title, equals('The Shadow of the Past'));
        expect(chapterList[1].number, equals(2));
        expect(chapterList[2].title, equals('Three is Company'));
        expect(chapterList[2].number, equals(3));
      });

      test('handles book with empty chapters list', () {
        const bookMapper = BookMapper();
        final context = createSerializationContext();

        final book = Book(
            id: 'empty-book',
            title: 'Empty Book',
            authorId: 'unknown',
            published: DateTime(2023, 1, 1),
            isbn: ISBN('9780000000000'),
            rating: Rating(1),
            chapters: [],
            format: BookFormat.paperback);

        final (subject, triples) = bookMapper.toRdfResource(book, context);

        expect(subject.value, equals('http://example.org/book/empty-book'));

        final chapterTriples = triples.where(
          (t) => t.predicate == SchemaBook.hasPart,
        );
        expect(chapterTriples.length, equals(0));
      });

      test('round-trip serialization maintains data integrity', () {
        const bookMapper = BookMapper();
        final serContext = createSerializationContext();

        final originalBook = Book(
          id: 'test-book',
          title: 'Test Book Title',
          authorId: 'test-author',
          published: DateTime.utc(2023, 6, 15),
          isbn: ISBN('9781234567890'),
          rating: Rating(4),
          format: BookFormat.ebook,
          chapters: [
            Chapter('Chapter One', 1),
            Chapter('Chapter Two', 2),
          ],
        );

        // Serialize
        final (subject, triples) =
            bookMapper.toRdfResource(originalBook, serContext);

        // Create deserialization context with all triples
        final graph = RdfGraph.fromTriples(triples);
        final deserContext = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        // Deserialize
        final deserializedBook =
            bookMapper.fromRdfResource(subject, deserContext);

        // Verify
        expect(deserializedBook.id, equals(originalBook.id));
        expect(deserializedBook.title, equals(originalBook.title));
        expect(deserializedBook.authorId, equals(originalBook.authorId));
        expect(deserializedBook.published, equals(originalBook.published));
        expect(deserializedBook.isbn.value, equals(originalBook.isbn.value));
        expect(
            deserializedBook.rating.stars, equals(originalBook.rating.stars));
        expect(deserializedBook.chapters.length,
            equals(originalBook.chapters.length));

        final originalChapters = originalBook.chapters.toList();
        final deserializedChapters = deserializedBook.chapters.toList();

        for (int i = 0; i < originalChapters.length; i++) {
          expect(
              deserializedChapters[i].title, equals(originalChapters[i].title));
          expect(deserializedChapters[i].number,
              equals(originalChapters[i].number));
        }
      });
    });

    group('Edge cases and validation', () {
      test('handles special characters in book properties', () {
        const bookMapper = BookMapper();
        final context = createSerializationContext();

        final book = Book(
          id: 'special-book-123',
          title: 'Book with "Quotes" & Special < > Characters',
          authorId: 'author-with-hyphens',
          published: DateTime(2023, 12, 31, 23, 59, 59),
          isbn: ISBN('978-0-123-45678-9'),
          rating: Rating(3),
          format: BookFormat.graphicNovel,
          chapters: [
            Chapter('Chapter with Unicode: 日本語', 1),
            Chapter('Chapter with Emoji: 📚', 2),
          ],
        );

        final (subject, triples) = bookMapper.toRdfResource(book, context);

        final titleTriple = triples.firstWhere(
          (t) => t.predicate == SchemaBook.name,
        );
        expect(
          (titleTriple.object as LiteralTerm).value,
          equals('Book with "Quotes" & Special < > Characters'),
        );

        final authorTriple = triples.firstWhere(
          (t) => t.predicate == SchemaBook.author,
        );
        expect(
          (authorTriple.object as IriTerm).value,
          equals('http://example.org/author/author-with-hyphens'),
        );
      });

      test('handles malformed ISBN gracefully', () {
        const isbnMapper = ISBNMapper();
        final context = createDeserializationContext();

        // Should not throw - the regex will extract whatever is after 'urn:isbn:'
        final isbn = isbnMapper.fromRdfTerm(
          const IriTerm('urn:isbn:invalid-isbn'),
          context,
        );
        expect(isbn.value, equals('invalid-isbn'));
      });

      test('rating validation in edge cases', () {
        expect(() => Rating(0), returnsNormally);
        expect(() => Rating(5), returnsNormally);
        expect(() => Rating(-1), throwsA(isA<ArgumentError>()));
        expect(() => Rating(6), throwsA(isA<ArgumentError>()));
        expect(() => Rating(100), throwsA(isA<ArgumentError>()));
      });
    });
  });
}
