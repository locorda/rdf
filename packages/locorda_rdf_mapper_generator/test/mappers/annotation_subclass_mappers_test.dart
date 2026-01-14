// Test that annotation subclassing works end-to-end with mapper generation
import 'package:test/test.dart';
import 'package:locorda_rdf_mapper/mapper.dart';

// Import the test models and their generated mappers
import '../fixtures/annotation_subclass_test_models.dart';
import '../fixtures/annotation_subclass_test_models.locorda_rdf_mapper.g.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
  group('Annotation Subclassing Mappers', () {
    late RdfMapper mapper;

    setUp(() {
      // Create a base mapper and add our custom annotation mappers
      mapper = defaultInitTestRdfMapper();
      mapper.registry.registerMapper(BookWithCustomAnnotationMapper());
      mapper.registry.registerMapper(PersonWithPodResourceMapper());
      mapper.registry.registerMapper(ArticleWithRegularAnnotationMapper());
    });

    test(
        'BookWithCustomAnnotation mapper works (custom annotation extends RdfGlobalResource)',
        () {
      // Create a test instance
      final book = BookWithCustomAnnotation(
        id: 'test-book-123',
        title: 'Test Book Title',
        author: 'Test Author',
      );

      // Test serialization
      final turtle = mapper.encodeObject(book);
      expect(turtle, isNotEmpty);
      expect(turtle, contains('Test Book Title'));
      expect(turtle, contains('Test Author'));
      expect(turtle, contains('test-book-123'));

      // Test deserialization
      final decoded = mapper.decodeObject<BookWithCustomAnnotation>(turtle);
      expect(decoded.id, equals('test-book-123'));
      expect(decoded.title, equals('Test Book Title'));
      expect(decoded.author, equals('Test Author'));
    });

    test('PersonWithPodResource mapper works (custom named constructor)', () {
      final person = PersonWithPodResource(
        id: 'person-456',
        name: 'Test Person',
      );

      // Test serialization
      final turtle = mapper.encodeObject(person);
      expect(turtle, isNotEmpty);
      expect(turtle, contains('Test Person'));
      expect(turtle, contains('person-456'));

      // Test deserialization
      final decoded = mapper.decodeObject<PersonWithPodResource>(turtle);
      expect(decoded.id, equals('person-456'));
      expect(decoded.name, equals('Test Person'));
    });

    test('ArticleWithRegularAnnotation mapper works (regular annotation)', () {
      final article = ArticleWithRegularAnnotation(
        id: 'article-789',
        title: 'Test Article',
      );

      // Test serialization
      final turtle = mapper.encodeObject(article);
      expect(turtle, isNotEmpty);
      expect(turtle, contains('Test Article'));
      expect(turtle, contains('article-789'));

      // Test deserialization
      final decoded = mapper.decodeObject<ArticleWithRegularAnnotation>(turtle);
      expect(decoded.id, equals('article-789'));
      expect(decoded.title, equals('Test Article'));
    });

    test('verify all mappers are properly registered', () {
      // Verify that all mappers were recognized and work correctly
      expect(
          mapper.registry
              .hasGlobalResourceDeserializerFor<BookWithCustomAnnotation>(),
          isTrue);
      expect(
          mapper.registry
              .hasGlobalResourceDeserializerFor<PersonWithPodResource>(),
          isTrue);
      expect(
          mapper.registry
              .hasGlobalResourceDeserializerFor<ArticleWithRegularAnnotation>(),
          isTrue);
    });
  });
}
