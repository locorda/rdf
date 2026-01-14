import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/annotation_test_models.dart';
// Import the generated init function
import '../fixtures/annotation_test_models.locorda_rdf_mapper.g.dart';
import '../fixtures/global_resource_processor_test_models.dart';
import 'init_test_rdf_mapper_util.dart';

class TestMapper implements IriTermMapper<ClassWithIriNamedMapperStrategy> {
  @override
  ClassWithIriNamedMapperStrategy fromRdfTerm(
      IriTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  IriTerm toRdfTerm(
      ClassWithIriNamedMapperStrategy value, SerializationContext context) {
    throw UnimplementedError();
  }
}

class TestIriTermRecordMapper implements IriTermMapper<(String id,)> {
  final String baseUri;

  TestIriTermRecordMapper(this.baseUri);

  @override
  (String,) fromRdfTerm(IriTerm term, DeserializationContext context) {
    final uri = term.value;
    final lastSlashIndex = uri.lastIndexOf('/');
    if (lastSlashIndex == -1 || lastSlashIndex == uri.length - 1) {
      throw ArgumentError('Invalid IRI format: cannot extract ID from $uri');
    }
    final id = uri.substring(lastSlashIndex + 1);
    return (id,);
  }

  @override
  IriTerm toRdfTerm((String,) value, SerializationContext context) {
    final id = value.$1;
    final uri = baseUri.endsWith('/') ? '$baseUri$id' : '$baseUri/$id';
    return context.createIriTerm(uri);
  }
}

void main() {
  late RdfMapper mapper;

  setUp(() {
    mapper = defaultInitTestRdfMapper();
  });

  group('All Mappers Test', () {
    test(
        'BookWithMapper mapping throws RdfConstraintViolationException for title with spaces',
        () {
      final book = BookWithMapper(
        id: '123',
        title: 'Test Book',
      );

      // Test serialization - should throw RdfConstraintViolationException due to spaces in title used for IRI
      expect(() => mapper.encodeObject(book),
          throwsA(isA<RdfConstraintViolationException>()));
    });

    test('BookWithMapperInstance mapping registered manually', () {
      final book = BookWithMapperInstance('456');
      final iriTermMapper = TestIriTermRecordMapper('http://example.org/book/');
      final globalResourceMapper =
          BookWithMapperInstanceMapper(iriMapper: iriTermMapper);

      // Test serialization
      final graph = mapper.encodeObject(book,
          register: (registry) =>
              registry.registerMapper(globalResourceMapper));
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized = mapper.decodeObject<BookWithMapperInstance>(graph,
          register: (registry) =>
              registry.registerMapper(globalResourceMapper));
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(book.id));
    });

    test(
        'BookWithMapperInstance mapping throws exception due to missing global registration',
        () {
      final book = BookWithMapperInstance('456');

      // Test serialization - should throw SerializerNotFoundException
      expect(() => mapper.encodeObject(book),
          throwsA(isA<SerializerNotFoundException>()));
    });

    test('BookWithTemplate mapping', () {
      final book = BookWithTemplate('789');

      // Test serialization
      final graph = mapper.encodeObject(book);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized = mapper.decodeObject<BookWithTemplate>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(book.id));
    });

    test('BookWithMapper successful mapping with valid title (no spaces)', () {
      final book = BookWithMapper(
        id: '123',
        title: 'TestBook',
      );

      // Test serialization
      final graph = mapper.graph.encodeObject(book);
      expect(graph, isNotNull);
      expect(graph.triples, isNotEmpty);

      // Verify the generated IRI follows the pattern
      final subject = graph.triples.first.subject as IriTerm;
      expect(subject.value, startsWith('https://example.org/books/'));
      expect(subject.value, contains('123'));

      // Verify type triple exists
      final typeTriples = graph.triples.where((t) =>
          t.predicate ==
          const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'));
      expect(typeTriples, isNotEmpty);
      expect((typeTriples.first.object as IriTerm).value,
          equals('https://schema.org/Book'));

      // Test deserialization
      final deserialized = mapper.graph.decodeObject<BookWithMapper>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(book.id));
      expect(deserialized.title, equals(book.title));
    });

    test('BookWithMapper with default title value when not included', () {
      final book = BookWithMapper(
        id: '456',
        title: 'Untitled', // This is the default value
      );

      // Test serialization - title should not be included due to default value
      final graph = mapper.graph.encodeObject(book);
      expect(graph, isNotNull);

      // Verify no title property is serialized when it equals default
      final titleTriples = graph.triples.where(
          (t) => t.predicate == const IriTerm('https://schema.org/name'));
      expect(titleTriples, isEmpty);

      // Test deserialization - should get default value
      final deserialized = mapper.graph.decodeObject<BookWithMapper>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(book.id));
      expect(deserialized.title, equals('Untitled'));
    });

    test('BookWithMapper with non-default title gets serialized', () {
      final book = BookWithMapper(
        id: '789',
        title: 'CustomTitle',
      );

      // Test serialization
      final graph = mapper.graph.encodeObject(book);
      expect(graph, isNotNull);

      // Verify title property is serialized
      final titleTriples = graph.triples.where(
          (t) => t.predicate == const IriTerm('https://schema.org/name'));
      expect(titleTriples, isNotEmpty);

      // Verify the IRI mapping for title property includes both id and title
      final titleTriple = titleTriples.first;
      final titleIri = (titleTriple.object as IriTerm).value;
      expect(titleIri, equals('https://example.org/books/789/CustomTitle'));

      // Test deserialization
      final deserialized = mapper.graph.decodeObject<BookWithMapper>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(book.id));
      expect(deserialized.title, equals(book.title));
    });

    test('BookWithMapper IRI mapping extraction during deserialization', () {
      // Create a manual graph with custom IRI structure
      final subject = const IriTerm('https://example.org/books/test-id');
      final titleIri =
          const IriTerm('https://example.org/books/test-id/MyTitle');

      final graph = RdfGraph.fromTriples([
        Triple(
          subject,
          const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
          const IriTerm('https://schema.org/Book'),
        ),
        Triple(
          subject,
          const IriTerm('https://schema.org/name'),
          titleIri,
        ),
      ]);

      // Test deserialization
      final deserialized = mapper.graph.decodeObject<BookWithMapper>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals('test-id'));
      expect(deserialized.title, equals('MyTitle'));
    });

    test('BookWithMapper handles special characters in ID correctly', () {
      final book = BookWithMapper(
        id: 'book-123_test',
        title: 'SpecialBook',
      );

      // Test serialization
      final graph = mapper.graph.encodeObject(book);
      expect(graph, isNotNull);

      // Verify IRI construction with special characters
      final subject = graph.triples.first.subject as IriTerm;
      expect(subject.value, contains('book-123_test'));

      // Test round-trip
      final deserialized = mapper.graph.decodeObject<BookWithMapper>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(book.id));
      expect(deserialized.title, equals(book.title));
    });

    test('BookWithMapper global registration allows automatic mapping', () {
      final book = BookWithMapper(
        id: 'global-test',
        title: 'GlobalBook',
      );

      // Since BookWithMapper has registerGlobally: true,
      // it should work without manual registration
      final graph = mapper.graph.encodeObject(book);
      expect(graph, isNotNull);

      final deserialized = mapper.graph.decodeObject<BookWithMapper>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(book.id));
      expect(deserialized.title, equals(book.title));
    });

    test('BookWithMapper with empty ID still works', () {
      final book = BookWithMapper(
        id: '',
        title: 'EmptyIdBook',
      );

      // Test serialization
      final graph = mapper.graph.encodeObject(book);
      expect(graph, isNotNull);

      // Test round-trip
      final deserialized = mapper.graph.decodeObject<BookWithMapper>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(''));
      expect(deserialized.title, equals(book.title));
    });

    test('BookWithMapper with numeric-only ID works correctly', () {
      final book = BookWithMapper(
        id: '12345',
        title: 'NumericIdBook',
      );

      // Test serialization
      final graph = mapper.graph.encodeObject(book);
      expect(graph, isNotNull);

      // Verify the numeric ID is properly encoded in the IRI
      final subject = graph.triples.first.subject as IriTerm;
      expect(subject.value, contains('12345'));

      // Test round-trip
      final deserialized = mapper.graph.decodeObject<BookWithMapper>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals('12345'));
      expect(deserialized.title, equals(book.title));
    });

    test(
        'BookWithMapper validates IRI constraint on title during serialization',
        () {
      final book = BookWithMapper(
        id: 'test',
        title: 'Title With Spaces', // This violates IRI constraints
      );

      // Should throw RdfConstraintViolationException due to spaces in title
      expect(() => mapper.graph.encodeObject(book),
          throwsA(isA<RdfConstraintViolationException>()));
    });
  });
}
