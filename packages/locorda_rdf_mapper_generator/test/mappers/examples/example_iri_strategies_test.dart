import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:locorda_rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';
import 'package:test/test.dart';

// Import test models
import '../../fixtures/locorda_rdf_mapper_annotations/examples/example_iri_strategies.dart';
// Import generated mappers
import '../../fixtures/locorda_rdf_mapper_annotations/examples/example_iri_strategies.rdf_mapper.g.dart';
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

  group('IRI Strategies Test', () {
    group('StandardIsbn (IRI with template)', () {
      test('serializes to IRI with template pattern', () {
        const mapper = StandardIsbnMapper();
        final context = createSerializationContext();

        final isbn = StandardIsbn('9780261102217');
        final iriTerm = mapper.toRdfTerm(isbn, context);

        expect(iriTerm, isA<IriTerm>());
        expect(iriTerm.value, equals('urn:isbn:9780261102217'));
      });

      test('deserializes from IRI with template pattern', () {
        const mapper = StandardIsbnMapper();
        final context = createDeserializationContext();

        final isbn = mapper.fromRdfTerm(
          const IriTerm('urn:isbn:9780261102217'),
          context,
        );

        expect(isbn.value, equals('9780261102217'));
      });

      test('handles various ISBN formats', () {
        const mapper = StandardIsbnMapper();
        final context = createSerializationContext();

        final isbn13 = StandardIsbn('9780261102217');
        final isbn10 = StandardIsbn('0261102214');
        final isbnX = StandardIsbn('026110221X');

        expect(
          mapper.toRdfTerm(isbn13, context).value,
          equals('urn:isbn:9780261102217'),
        );
        expect(
          mapper.toRdfTerm(isbn10, context).value,
          equals('urn:isbn:0261102214'),
        );
        expect(
          mapper.toRdfTerm(isbnX, context).value,
          equals('urn:isbn:026110221X'),
        );
      });
    });

    group('AbsoluteUri (direct IRI usage)', () {
      test('serializes using URI value directly', () {
        const mapper = AbsoluteUriMapper();
        final context = createSerializationContext();

        final uri = AbsoluteUri('https://example.org/resources/123');
        final iriTerm = mapper.toRdfTerm(uri, context);

        expect(iriTerm.value, equals('https://example.org/resources/123'));
      });

      test('deserializes using IRI value directly', () {
        const mapper = AbsoluteUriMapper();
        final context = createDeserializationContext();

        final uri = mapper.fromRdfTerm(
          const IriTerm('https://example.org/resources/456'),
          context,
        );

        expect(uri.uri, equals('https://example.org/resources/456'));
      });

      test('validates absolute URI format in constructor', () {
        expect(
          () => AbsoluteUri('relative/path'),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => AbsoluteUri('https://valid.org/path'),
          returnsNormally,
        );
      });
    });

    group('UserReference (named mapper)', () {
      test('uses named mapper for custom IRI construction', () {
        final testMapper = TestUserReferenceMapper();
        final context = createSerializationContext();

        final userRef = UserReference('johndoe');
        final iriTerm = testMapper.toRdfTerm(userRef, context);

        expect(iriTerm.value, equals('http://example.org/users/johndoe'));
      });

      test('deserializes from custom IRI format', () {
        final testMapper = TestUserReferenceMapper();
        final context = createDeserializationContext();

        final userRef = testMapper.fromRdfTerm(
          const IriTerm('http://example.org/users/janedoe'),
          context,
        );

        expect(userRef.username, equals('janedoe'));
      });

      test('throws on invalid IRI format', () {
        final testMapper = TestUserReferenceMapper();
        final context = createDeserializationContext();

        expect(
          () => testMapper.fromRdfTerm(
            const IriTerm('http://invalid.org/profile/user'),
            context,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('handles usernames with special characters', () {
        final testMapper = TestUserReferenceMapper();
        final context = createSerializationContext();

        final userRef = UserReference('user-123_test');
        final iriTerm = testMapper.toRdfTerm(userRef, context);

        expect(iriTerm.value, equals('http://example.org/users/user-123_test'));

        final deserContext = createDeserializationContext();
        final deserializedUserRef =
            testMapper.fromRdfTerm(iriTerm, deserContext);
        expect(deserializedUserRef.username, equals('user-123_test'));
      });
    });

    group('SimpleBook (global resource with IRI template)', () {
      test('serializes global resource with IRI template', () {
        const mapper = SimpleBookMapper();
        final context = createSerializationContext();

        final book = SimpleBook('hobbit', 'The Hobbit');
        final (subject, triples) = mapper.toRdfResource(book, context);

        expect(
          subject.value,
          equals('https://library.example.org/books/hobbit.ttl'),
        );
        expect(triples.length, greaterThan(0));

        final titleTriple = triples.firstWhere(
          (t) => t.predicate == SchemaBook.name,
        );
        expect(
          (titleTriple.object as LiteralTerm).value,
          equals('The Hobbit'),
        );
      });

      test('deserializes global resource from IRI template', () {
        final triples = [
          Triple(
            const IriTerm('https://library.example.org/books/lotr.ttl'),
            SchemaBook.name,
            LiteralTerm('The Lord of the Rings'),
          ),
        ];

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        const bookMapper = SimpleBookMapper();
        final book = bookMapper.fromRdfResource(
          const IriTerm('https://library.example.org/books/lotr.ttl'),
          context,
        );

        expect(book.id, equals('lotr'));
        expect(book.title, equals('The Lord of the Rings'));
      });

      test('extracts ID from IRI template correctly', () {
        final triples = [
          Triple(
            const IriTerm(
                'https://library.example.org/books/complex-book-id-123.ttl'),
            SchemaBook.name,
            LiteralTerm('Complex Book'),
          ),
        ];

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        const bookMapper = SimpleBookMapper();
        final book = bookMapper.fromRdfResource(
          const IriTerm(
              'https://library.example.org/books/complex-book-id-123.ttl'),
          context,
        );

        expect(book.id, equals('complex-book-id-123'));
        expect(book.title, equals('Complex Book'));
      });
    });

    group('Person (global resource with direct IRI)', () {
      test('serializes global resource with direct IRI', () {
        const mapper = PersonMapper();
        final context = createSerializationContext();

        final person = Person(
          'https://example.org/person/43',
          'John',
        );
        final (subject, triples) = mapper.toRdfResource(person, context);

        expect(subject.value, equals('https://example.org/person/43'));

        final givenNameTriple = triples.firstWhere(
          (t) => t.predicate == SchemaPerson.givenName,
        );
        expect(
          (givenNameTriple.object as LiteralTerm).value,
          equals('John'),
        );
      });

      test('deserializes global resource from direct IRI', () {
        final triples = [
          Triple(
            const IriTerm('https://example.org/person/jane'),
            SchemaPerson.givenName,
            LiteralTerm('Jane'),
          ),
        ];

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        const personMapper = PersonMapper();
        final person = personMapper.fromRdfResource(
          const IriTerm('https://example.org/person/jane'),
          context,
        );

        expect(person.iri, equals('https://example.org/person/jane'));
        expect(person.givenName, equals('Jane'));
      });
    });

    group('Chapter (multi-field IRI mapping with named mapper)', () {
      test('uses named mapper for multi-field IRI construction', () {
        final testMapper = TestChapterIdMapper();
        final context = createSerializationContext();

        final chapterData = ('hobbit', 3);
        final iriTerm = testMapper.toRdfTerm(chapterData, context);

        expect(
          iriTerm.value,
          equals('http://example.org/books/hobbit/chapters/3'),
        );
      });

      test('deserializes multi-field IRI mapping', () {
        final testMapper = TestChapterIdMapper();
        final context = createDeserializationContext();

        final chapterData = testMapper.fromRdfTerm(
          const IriTerm('http://example.org/books/lotr/chapters/7'),
          context,
        );

        expect(chapterData.$1, equals('lotr'));
        expect(chapterData.$2, equals(7));
      });

      test('serializes and deserializes Chapter resource', () {
        final triples = [
          Triple(
            const IriTerm('http://example.org/books/hobbit/chapters/1'),
            SchemaChapter.name,
            LiteralTerm('An Unexpected Party'),
          ),
          Triple(
            const IriTerm('http://example.org/books/hobbit/chapters/1'),
            SchemaChapter.isPartOf,
            LiteralTerm('hobbit'),
          ),
          Triple(
            const IriTerm('http://example.org/books/hobbit/chapters/1'),
            SchemaChapter.position,
            LiteralTerm('1',
                datatype:
                    const IriTerm('http://www.w3.org/2001/XMLSchema#integer')),
          ),
        ];

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        final chapterMapper = ChapterMapper(
          chapterIdMapper: const TestChapterIdMapper(),
        );
        final chapter = chapterMapper.fromRdfResource(
          const IriTerm('http://example.org/books/hobbit/chapters/1'),
          context,
        );

        expect(chapter.bookId, equals('hobbit'));
        expect(chapter.chapterNumber, equals(1));
        expect(chapter.title, equals('An Unexpected Party'));
      });

      test('throws on invalid chapter IRI format', () {
        final testMapper = TestChapterIdMapper();
        final context = createDeserializationContext();

        expect(
          () => testMapper.fromRdfTerm(
            const IriTerm('http://invalid.org/wrong/format'),
            context,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('handles chapter numbers with leading zeros', () {
        final testMapper = TestChapterIdMapper();
        final context = createDeserializationContext();

        final chapterData = testMapper.fromRdfTerm(
          const IriTerm('http://example.org/books/test/chapters/007'),
          context,
        );

        expect(chapterData.$1, equals('test'));
        expect(chapterData.$2, equals(7));
      });
    });

    group('Integration tests', () {
      test('round-trip serialization maintains data integrity', () {
        const isbnMapper = StandardIsbnMapper();
        const uriMapper = AbsoluteUriMapper();
        final userMapper = TestUserReferenceMapper();
        final chapterMapper = TestChapterIdMapper();
        final context = createSerializationContext();

        // Test data
        final isbn = StandardIsbn('9781234567890');
        final uri = AbsoluteUri('https://test.org/resource');
        final user = UserReference('test_user');
        final chapterData = ('test-book', 42);

        // Serialize
        final isbnTerm = isbnMapper.toRdfTerm(isbn, context);
        final uriTerm = uriMapper.toRdfTerm(uri, context);
        final userTerm = userMapper.toRdfTerm(user, context);
        final chapterTerm = chapterMapper.toRdfTerm(chapterData, context);

        // Deserialize
        final deserContext = createDeserializationContext();
        final deserializedIsbn = isbnMapper.fromRdfTerm(isbnTerm, deserContext);
        final deserializedUri = uriMapper.fromRdfTerm(uriTerm, deserContext);
        final deserializedUser = userMapper.fromRdfTerm(userTerm, deserContext);
        final deserializedChapter =
            chapterMapper.fromRdfTerm(chapterTerm, deserContext);

        // Verify
        expect(deserializedIsbn.value, equals(isbn.value));
        expect(deserializedUri.uri, equals(uri.uri));
        expect(deserializedUser.username, equals(user.username));
        expect(deserializedChapter.$1, equals(chapterData.$1));
        expect(deserializedChapter.$2, equals(chapterData.$2));
      });

      test('handles complex IRI patterns with special characters', () {
        final testMapper = TestChapterIdMapper();
        final context = createSerializationContext();

        final complexBookId = 'book-with-hyphens_and_underscores';
        final chapterData = (complexBookId, 99);

        final iriTerm = testMapper.toRdfTerm(chapterData, context);
        expect(
          iriTerm.value,
          equals('http://example.org/books/$complexBookId/chapters/99'),
        );

        final deserContext = createDeserializationContext();
        final deserializedData = testMapper.fromRdfTerm(iriTerm, deserContext);
        expect(deserializedData.$1, equals(complexBookId));
        expect(deserializedData.$2, equals(99));
      });

      test('validates IRI template extraction edge cases', () {
        const isbnMapper = StandardIsbnMapper();
        final context = createDeserializationContext();

        // Test empty value
        final emptyIsbn = isbnMapper.fromRdfTerm(
          const IriTerm('urn:isbn:'),
          context,
        );
        expect(emptyIsbn.value, equals(''));

        // Test value with special characters
        final specialIsbn = isbnMapper.fromRdfTerm(
          const IriTerm('urn:isbn:123-456-789-X'),
          context,
        );
        expect(specialIsbn.value, equals('123-456-789-X'));
      });
    });
  });
}
