import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/local_resource_processor_test_models.dart';
import '../fixtures/local_resource_processor_test_models.rdf_mapper.g.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
  late RdfMapper mapper;

  setUp(() {
    mapper = defaultInitTestRdfMapper();
  });

  group('All Mappers Test', () {
    test('Book mapping', () {
      // Verify local resource registration
      final isRegistered =
          mapper.registry.hasLocalResourceDeserializerFor<Book>();
      expect(isRegistered, isTrue,
          reason: 'Book should be registered as a local resource');
      final isRegisteredAsGlobal =
          mapper.registry.hasGlobalResourceDeserializerFor<Book>();
      expect(isRegisteredAsGlobal, isFalse,
          reason: 'Book should not be registered as a global resource');

      // Create a Book instance
      final book = Book(
        isbn: '1234567890',
        title: 'Test Book',
        authorId: 'author123',
      );

      // Test serialization
      final graph = mapper.encodeObject(book);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized = mapper.decodeObject<Book>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.isbn, equals(book.isbn));
      expect(deserialized.title, equals(book.title));
      expect(deserialized.authorId, equals(book.authorId));
    });

    test('ClassNoRegisterGlobally mapping', () {
      final isRegistered = mapper.registry
          .hasLocalResourceDeserializerFor<ClassNoRegisterGlobally>();
      expect(isRegistered, isFalse,
          reason: 'ClassNoRegisterGlobally should not be registered globally');

      // Create an instance of ClassNoRegisterGlobally
      final instance = ClassNoRegisterGlobally(name: 'no-register');

      // Test serialization - should fail with SerializerNotFoundException
      expect(() => mapper.encodeObject(instance),
          throwsA(isA<SerializerNotFoundException>()));
      final graph = """
@prefix schema: <https://schema.org/> .

_:b0 a schema:Person;
    schema:name "no-register" .
""";
      // Test deserialization - should fail with DeserializerNotFoundException
      expect(() => mapper.decodeObject<ClassNoRegisterGlobally>(graph),
          throwsA(isA<DeserializerNotFoundException>()));
    });

    test('ClassNoRegisterGlobally mapping explicitly registered', () {
      expect(
          mapper.registry
              .hasLocalResourceDeserializerFor<ClassNoRegisterGlobally>(),
          isFalse,
          reason: 'ClassNoRegisterGlobally should not be registered globally');

      // Create an instance of ClassNoRegisterGlobally
      final instance = ClassNoRegisterGlobally(name: 'no-register');

      // Test serialization
      final graph = mapper.encodeObject(instance,
          register: (registry) =>
              registry.registerMapper(ClassNoRegisterGloballyMapper()));
      expect(graph, isNotNull);
      expect(
          mapper.registry
              .hasLocalResourceDeserializerFor<ClassNoRegisterGlobally>(),
          isFalse,
          reason:
              'ClassNoRegisterGlobally should still not be registered globally, even after local registration');

      // Test deserialization
      final deserialized = mapper.decodeObject<ClassNoRegisterGlobally>(graph,
          register: (registry) =>
              registry.registerMapper(ClassNoRegisterGloballyMapper()));
      expect(deserialized, isNotNull);
      expect(deserialized.name, equals(instance.name));
      expect(
          mapper.registry
              .hasLocalResourceDeserializerFor<ClassNoRegisterGlobally>(),
          isFalse,
          reason:
              'ClassNoRegisterGlobally should still not be registered globally, even after local registration');
    });

    test('ClassWithPositionalProperty mapping', () {
      // Verify local resource registration
      final isRegistered = mapper.registry
          .hasLocalResourceDeserializerFor<ClassWithPositionalProperty>();
      expect(isRegistered, isTrue,
          reason:
              'ClassWithPositionalProperty should be registered as a local resource');
      final isRegisteredAsGlobal = mapper.registry
          .hasGlobalResourceDeserializerFor<ClassWithPositionalProperty>();
      expect(isRegisteredAsGlobal, isFalse,
          reason:
              'ClassWithPositionalProperty should not be registered as a global resource');

      // Create an instance
      final instance = ClassWithPositionalProperty('test-name');

      // Test serialization
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized =
          mapper.decodeObject<ClassWithPositionalProperty>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.name, equals(instance.name));
    });

    test('ClassWithNonFinalProperty mapping', () {
      // Verify local resource registration
      final isRegistered = mapper.registry
          .hasLocalResourceDeserializerFor<ClassWithNonFinalProperty>();
      expect(isRegistered, isTrue,
          reason:
              'ClassWithNonFinalProperty should be registered as a local resource');
      final isRegisteredAsGlobal = mapper.registry
          .hasGlobalResourceDeserializerFor<ClassWithNonFinalProperty>();
      expect(isRegisteredAsGlobal, isFalse,
          reason:
              'ClassWithNonFinalProperty should not be registered as a global resource');

      // Create an instance
      final instance = ClassWithNonFinalProperty(name: 'test-name');

      // Test serialization
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized =
          mapper.decodeObject<ClassWithNonFinalProperty>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.name, equals(instance.name));
    });

    test('ClassWithNonFinalPropertyWithDefault mapping', () {
      // Verify local resource registration
      final isRegistered = mapper.registry.hasLocalResourceDeserializerFor<
          ClassWithNonFinalPropertyWithDefault>();
      expect(isRegistered, isTrue,
          reason:
              'ClassWithNonFinalPropertyWithDefault should be registered as a local resource');
      final isRegisteredAsGlobal = mapper.registry
          .hasGlobalResourceDeserializerFor<
              ClassWithNonFinalPropertyWithDefault>();
      expect(isRegisteredAsGlobal, isFalse,
          reason:
              'ClassWithNonFinalPropertyWithDefault should not be registered as a global resource');

      // Create an instance using default value
      final instance = ClassWithNonFinalPropertyWithDefault();

      // Test serialization
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized =
          mapper.decodeObject<ClassWithNonFinalPropertyWithDefault>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.name, equals('me myself and I'));
    });

    test('ClassWithNonFinalOptionalProperty mapping', () {
      // Verify local resource registration
      final isRegistered = mapper.registry
          .hasLocalResourceDeserializerFor<ClassWithNonFinalOptionalProperty>();
      expect(isRegistered, isTrue,
          reason:
              'ClassWithNonFinalOptionalProperty should be registered as a local resource');
      final isRegisteredAsGlobal = mapper.registry
          .hasGlobalResourceDeserializerFor<
              ClassWithNonFinalOptionalProperty>();
      expect(isRegisteredAsGlobal, isFalse,
          reason:
              'ClassWithNonFinalOptionalProperty should not be registered as a global resource');

      // Create an instance with null value
      final instance = ClassWithNonFinalOptionalProperty();

      // Test serialization
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized =
          mapper.decodeObject<ClassWithNonFinalOptionalProperty>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.name, isNull);
    });

    test('ClassWithLateNonFinalProperty mapping', () {
      // Verify local resource registration
      final isRegistered = mapper.registry
          .hasLocalResourceDeserializerFor<ClassWithLateNonFinalProperty>();
      expect(isRegistered, isTrue,
          reason:
              'ClassWithLateNonFinalProperty should be registered as a local resource');
      final isRegisteredAsGlobal = mapper.registry
          .hasGlobalResourceDeserializerFor<ClassWithLateNonFinalProperty>();
      expect(isRegisteredAsGlobal, isFalse,
          reason:
              'ClassWithLateNonFinalProperty should not be registered as a global resource');

      // Create an instance and set the late property
      final instance = ClassWithLateNonFinalProperty();
      instance.name = 'late-property-name';

      // Test serialization
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized =
          mapper.decodeObject<ClassWithLateNonFinalProperty>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.name, equals('late-property-name'));
    });

    test('ClassWithLateFinalProperty mapping', () {
      // Verify local resource registration
      final isRegistered = mapper.registry
          .hasLocalResourceDeserializerFor<ClassWithLateFinalProperty>();
      expect(isRegistered, isTrue,
          reason:
              'ClassWithLateFinalProperty should be registered as a local resource');
      final isRegisteredAsGlobal = mapper.registry
          .hasGlobalResourceDeserializerFor<ClassWithLateFinalProperty>();
      expect(isRegisteredAsGlobal, isFalse,
          reason:
              'ClassWithLateFinalProperty should not be registered as a global resource');

      // Create an instance and set the late final property
      final instance = ClassWithLateFinalProperty();
      instance.name = 'late-final-property-name';

      // Test serialization
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized =
          mapper.decodeObject<ClassWithLateFinalProperty>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.name, equals('late-final-property-name'));
    });

    test('ClassWithMixedFinalAndLateFinalProperty mapping', () {
      // Verify local resource registration
      final isRegistered = mapper.registry.hasLocalResourceDeserializerFor<
          ClassWithMixedFinalAndLateFinalProperty>();
      expect(isRegistered, isTrue,
          reason:
              'ClassWithMixedFinalAndLateFinalProperty should be registered as a local resource');
      final isRegisteredAsGlobal = mapper.registry
          .hasGlobalResourceDeserializerFor<
              ClassWithMixedFinalAndLateFinalProperty>();
      expect(isRegisteredAsGlobal, isFalse,
          reason:
              'ClassWithMixedFinalAndLateFinalProperty should not be registered as a global resource');

      // Create an instance
      final instance =
          ClassWithMixedFinalAndLateFinalProperty(name: 'test-name');
      instance.age = 25;

      // Test serialization
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized =
          mapper.decodeObject<ClassWithMixedFinalAndLateFinalProperty>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.name, equals('test-name'));
      expect(deserialized.age, equals(25));
    });
  });
}
