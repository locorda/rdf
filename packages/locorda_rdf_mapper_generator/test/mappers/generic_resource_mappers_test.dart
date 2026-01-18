import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:test/test.dart';

// Import test models and generated mappers
import '../fixtures/valid_generic_test_models.dart';
import '../fixtures/valid_generic_test_models.rdf_mapper.g.dart';

void main() {
  group('Generic Mapper Generation Tests', () {
    group('Mapper Class Generation', () {
      test('generates GenericDocumentMapper<T> with correct class name', () {
        const mapper = GenericDocumentMapper<String>();
        expect(mapper, isA<GenericDocumentMapper<String>>());
        expect(mapper, isA<GlobalResourceMapper<GenericDocument<String>>>());

        // Test with different type parameter
        const intMapper = GenericDocumentMapper<int>();
        expect(intMapper, isA<GenericDocumentMapper<int>>());
        expect(intMapper, isA<GlobalResourceMapper<GenericDocument<int>>>());
      });

      test('generates non-generic mapper correctly', () {
        const mapper = NonGenericPersonMapper();
        expect(mapper, isA<NonGenericPersonMapper>());
        expect(mapper, isA<GlobalResourceMapper<NonGenericPerson>>());
      });

      test('generates local resource mapper with generics', () {
        const mapper = GenericLocalResourceMapper<String>();
        expect(mapper, isA<GenericLocalResourceMapper<String>>());
        expect(
            mapper, isA<LocalResourceMapper<GenericLocalResource<String>>>());
      });

      test('generates mapper with multiple type parameters', () {
        const mapper = MultiGenericDocumentMapper<String, int, bool>();
        expect(mapper, isA<MultiGenericDocumentMapper<String, int, bool>>());
        expect(
            mapper,
            isA<
                GlobalResourceMapper<
                    MultiGenericDocument<String, int, bool>>>());
      });
    });

    group('Type Safety Tests', () {
      test('mapper type parameters are correctly inferred', () {
        // Test that we can use specific generic types
        const stringDoc = GenericDocument<String>(
          documentIri: 'test',
          primaryTopic: 'string',
          title: 'title',
        );

        const intDoc = GenericDocument<int>(
          documentIri: 'test',
          primaryTopic: 42,
          title: 'title',
        );

        // These should compile without issues
        expect(stringDoc.primaryTopic, isA<String>());
        expect(intDoc.primaryTopic, isA<int>());
      });

      test('mappers maintain type safety', () {
        const stringMapper = GenericDocumentMapper<String>();
        const intMapper = GenericDocumentMapper<int>();

        // Type parameters should be preserved in mapper interfaces
        expect(
            stringMapper, isA<GlobalResourceMapper<GenericDocument<String>>>());
        expect(intMapper, isA<GlobalResourceMapper<GenericDocument<int>>>());
      });

      test('different type parameters create distinct mapper types', () {
        const stringMapper = GenericDocumentMapper<String>();
        const intMapper = GenericDocumentMapper<int>();
        const boolMapper = GenericDocumentMapper<bool>();

        // Each should be correctly typed
        expect(stringMapper.runtimeType.toString(),
            contains('GenericDocumentMapper<String>'));
        expect(intMapper.runtimeType.toString(),
            contains('GenericDocumentMapper<int>'));
        expect(boolMapper.runtimeType.toString(),
            contains('GenericDocumentMapper<bool>'));
      });

      test('multi-generic mappers maintain type safety', () {
        const mapper = MultiGenericDocumentMapper<String, int, bool>();
        expect(
            mapper,
            isA<
                GlobalResourceMapper<
                    MultiGenericDocument<String, int, bool>>>());
        expect(mapper.runtimeType.toString(),
            contains('MultiGenericDocumentMapper<String, int, bool>'));

        // Test that we can create the document with correct types
        const document = MultiGenericDocument<String, int, bool>(
          documentIri: 'test',
          primaryTopic: 'topic',
          author: 42,
          metadata: true,
        );

        expect(document.primaryTopic, isA<String>());
        expect(document.author, isA<int>());
        expect(document.metadata, isA<bool>());
      });
    });

    group('Generated Code Structure Tests', () {
      test('generic mappers have const constructors', () {
        const mapper1 = GenericDocumentMapper<String>();
        const mapper2 = GenericLocalResourceMapper<int>();
        const mapper3 = NonGenericPersonMapper();

        // All should be const constructible
        expect(mapper1, isNotNull);
        expect(mapper2, isNotNull);
        expect(mapper3, isNotNull);
      });

      test('mappers implement correct interface hierarchies', () {
        const globalMapper = GenericDocumentMapper<String>();
        const localMapper = GenericLocalResourceMapper<String>();
        const nonGenericMapper = NonGenericPersonMapper();

        // Test interface implementations
        expect(
            globalMapper, isA<GlobalResourceMapper<GenericDocument<String>>>());
        expect(localMapper,
            isA<LocalResourceMapper<GenericLocalResource<String>>>());
        expect(nonGenericMapper, isA<GlobalResourceMapper<NonGenericPerson>>());

        // All should be instances of their respective mapper interfaces
        expect(globalMapper, isNotNull);
        expect(localMapper, isNotNull);
        expect(nonGenericMapper, isNotNull);
      });

      test('generic classes maintain type information correctly', () {
        // Test that the generated classes preserve generic type information
        const doc1 = GenericDocument<String>(
          documentIri: 'test1',
          primaryTopic: 'topic',
          title: 'title',
        );

        const doc2 = GenericDocument<int>(
          documentIri: 'test2',
          primaryTopic: 42,
          title: 'title',
        );

        // Type information should be preserved
        expect(doc1.primaryTopic, isA<String>());
        expect(doc2.primaryTopic, isA<int>());
        expect(
            doc1.runtimeType.toString(), contains('GenericDocument<String>'));
        expect(doc2.runtimeType.toString(), contains('GenericDocument<int>'));
      });
    });

    group('Mapper Instantiation Tests', () {
      test('can create mappers with various type parameters', () {
        // Primitive types
        const stringMapper = GenericDocumentMapper<String>();
        const intMapper = GenericDocumentMapper<int>();
        const boolMapper = GenericDocumentMapper<bool>();
        const doubleMapper = GenericDocumentMapper<double>();

        // Complex types
        const listMapper = GenericDocumentMapper<List<String>>();
        const mapMapper = GenericDocumentMapper<Map<String, int>>();

        // All should be instantiable
        expect(stringMapper, isNotNull);
        expect(intMapper, isNotNull);
        expect(boolMapper, isNotNull);
        expect(doubleMapper, isNotNull);
        expect(listMapper, isNotNull);
        expect(mapMapper, isNotNull);
      });

      test('local resource mappers work with type parameters', () {
        const stringLocalMapper = GenericLocalResourceMapper<String>();
        const intLocalMapper = GenericLocalResourceMapper<int>();

        expect(stringLocalMapper,
            isA<LocalResourceMapper<GenericLocalResource<String>>>());
        expect(intLocalMapper,
            isA<LocalResourceMapper<GenericLocalResource<int>>>());
      });
    });
  });
}
