import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/global_resource_processor_test_models.dart';
import '../fixtures/global_resource_processor_test_models.locorda_rdf_mapper.g.dart';
import 'init_test_rdf_mapper_util.dart';

/// IRI mapper for single part tuple (String id)
class _TestMapper1Part implements IriTermMapper<(String,)> {
  const _TestMapper1Part();

  @override
  (String,) fromRdfTerm(IriTerm term, DeserializationContext context) {
    // Extract ID from IRI like http://example.org/1part/test-id
    final iri = term.value;
    final match = RegExp(r'http://example\.org/1part/(.+)$').firstMatch(iri);
    if (match == null) {
      throw ArgumentError('Invalid IRI format: $iri');
    }
    return (match.group(1)!,);
  }

  @override
  IriTerm toRdfTerm((String,) value, SerializationContext context) {
    return context.createIriTerm('http://example.org/1part/${value.$1}');
  }
}

/// IRI mapper for two part tuple (String id, int version)
class _TestMapper2Parts implements IriTermMapper<(String, int)> {
  const _TestMapper2Parts();

  @override
  (String, int) fromRdfTerm(IriTerm term, DeserializationContext context) {
    // Extract ID and version from IRI like http://example.org/2parts/test-id/42
    final iri = term.value;
    final match =
        RegExp(r'http://example\.org/2parts/([^/]+)/(\d+)$').firstMatch(iri);
    if (match == null) {
      throw ArgumentError('Invalid IRI format: $iri');
    }
    return (match.group(1)!, int.parse(match.group(2)!));
  }

  @override
  IriTerm toRdfTerm((String, int) value, SerializationContext context) {
    return context
        .createIriTerm('http://example.org/2parts/${value.$1}/${value.$2}');
  }
}

/// IRI mapper for swapped two part tuple (int version, String id)
class _TestMapper2PartsSwapped implements IriTermMapper<(int, String)> {
  const _TestMapper2PartsSwapped();

  @override
  (int, String) fromRdfTerm(IriTerm term, DeserializationContext context) {
    // Extract version and ID from IRI like http://example.org/swapped/99/test-id
    final iri = term.value;
    final match =
        RegExp(r'http://example\.org/swapped/(\d+)/([^/]+)$').firstMatch(iri);
    if (match == null) {
      throw ArgumentError('Invalid IRI format: $iri');
    }
    return (int.parse(match.group(1)!), match.group(2)!);
  }

  @override
  IriTerm toRdfTerm((int, String) value, SerializationContext context) {
    return context
        .createIriTerm('http://example.org/swapped/${value.$1}/${value.$2}');
  }
}

bool isRegisteredGlobalResourceMapper<T>(RdfMapper mapper) {
  return mapper.registry.hasGlobalResourceDeserializerFor<T>() &&
      mapper.registry.hasResourceSerializerFor<T>();
}

void main() {
  late RdfMapper mapper;

  setUp(() {
    mapper = defaultInitTestRdfMapper(
      testMapper: TestMapper(),
    );
  });

  group('All Mappers Test', () {
    test('Book mapping', () {
      // Verify global resource registration
      final isRegistered =
          mapper.registry.hasGlobalResourceDeserializerFor<Book>();
      expect(isRegistered, isTrue,
          reason: 'Book should be registered as a global resource');
      final isRegisteredAsLocal =
          mapper.registry.hasLocalResourceDeserializerFor<Book>();
      expect(isRegisteredAsLocal, isFalse,
          reason: 'Book should not be registered as a local resource');

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

    test('ClassWithIriTemplateStrategy mapping', () {
      final instance = ClassWithIriTemplateStrategy(id: 'template-strategy');

      // Test serialization
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized =
          mapper.decodeObject<ClassWithIriTemplateStrategy>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(instance.id));
    });

    test('ClassWithIriTemplateAndContextVariableStrategy mapping', () {
      final instance =
          ClassWithIriTemplateAndContextVariableStrategy(id: 'context-var');

      // Test serialization
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized = mapper
          .decodeObject<ClassWithIriTemplateAndContextVariableStrategy>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(instance.id));
    });

    test('ClassWithOtherBaseUriNonGlobal mapping', () {
      expect(isRegisteredGlobalResourceMapper(mapper), isFalse);
      final instance = ClassWithOtherBaseUriNonGlobal(id: 'context-var');

      // Test serialization
      final graph = mapper.encodeObject(instance,
          register: (registry) =>
              registry.registerMapper(ClassWithOtherBaseUriNonGlobalMapper(
                otherBaseUriProvider: () => 'https://other.example.org',
              )));
      expect(graph, isNotNull);
      expect(graph,
          contains('@prefix persons: <https://other.example.org/persons/> .'));
      expect(graph, contains('persons:context-var a schema:Person .'));
      // Test deserialization
      final deserialized = mapper.decodeObject<ClassWithOtherBaseUriNonGlobal>(
          graph,
          register: (registry) =>
              registry.registerMapper(ClassWithOtherBaseUriNonGlobalMapper(
                otherBaseUriProvider: () => 'https://other.example.org',
              )));
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(instance.id));
    });

    test('ClassWithEmptyIriStrategy mapping', () {
      final instance = ClassWithEmptyIriStrategy(iri: "http://example.org/");
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);
      final decoded = mapper.decodeObject<ClassWithEmptyIriStrategy>(graph);
      expect(decoded, isNotNull);
    });

    test('ClassWithIriNamedMapperStrategy mapping', () {
      final instance = ClassWithIriNamedMapperStrategy();
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);
      final decoded =
          mapper.decodeObject<ClassWithIriNamedMapperStrategy>(graph);
      expect(decoded, isNotNull);
    });

    test('ClassWithIriMapperStrategy mapping', () {
      final instance = ClassWithIriMapperStrategy();
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);
      final decoded = mapper.decodeObject<ClassWithIriMapperStrategy>(graph);
      expect(decoded, isNotNull);
    });

    test('ClassWithIriMapperInstanceStrategy mapping', () {
      final instance =
          ClassWithIriMapperInstanceStrategy(name: 'Test Instance');
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);
      final decoded =
          mapper.decodeObject<ClassWithIriMapperInstanceStrategy>(graph);
      expect(decoded, isNotNull);
    });

    test('ClassNoRegisterGlobally mapping', () {
      final isRegistered = mapper.registry.hasLocalResourceDeserializerFor<
          ClassWithEmptyIriStrategyNoRegisterGlobally>();
      expect(isRegistered, isFalse,
          reason: 'ClassNoRegisterGlobally should not be registered globally');

      // Create an instance of ClassNoRegisterGlobally
      final instance = ClassWithEmptyIriStrategyNoRegisterGlobally(
          iri: 'https://example.org/no-register');

      // Test serialization - should fail with SerializerNotFoundException
      expect(() => mapper.encodeObject(instance),
          throwsA(isA<SerializerNotFoundException>()));
      final graph = """
@prefix ex: <https://example.org/> .
@prefix schema: <https://schema.org/> .

ex:no-register a schema:Person .
""";
      // Test deserialization - should fail with DeserializerNotFoundException
      expect(
          () => mapper
              .decodeObject<ClassWithEmptyIriStrategyNoRegisterGlobally>(graph),
          throwsA(isA<DeserializerNotFoundException>()));
    });

    test('ClassNoRegisterGlobally mapping explicitly registered', () {
      expect(
          mapper.registry.hasLocalResourceDeserializerFor<
              ClassWithEmptyIriStrategyNoRegisterGlobally>(),
          isFalse,
          reason: 'ClassNoRegisterGlobally should not be registered globally');

      // Create an instance of ClassNoRegisterGlobally
      final instance = ClassWithEmptyIriStrategyNoRegisterGlobally(
          iri: 'https://example.org/no-register');

      // Test serialization
      final graph = mapper.encodeObject(instance,
          register: (registry) => registry.registerMapper(
              ClassWithEmptyIriStrategyNoRegisterGloballyMapper()));
      expect(graph, isNotNull);
      expect(
          mapper.registry.hasLocalResourceDeserializerFor<
              ClassWithEmptyIriStrategyNoRegisterGlobally>(),
          isFalse,
          reason:
              'ClassNoRegisterGlobally should still not be registered globally, even after local registration');

      // Test deserialization
      final deserialized = mapper
          .decodeObject<ClassWithEmptyIriStrategyNoRegisterGlobally>(graph,
              register: (registry) => registry.registerMapper(
                  ClassWithEmptyIriStrategyNoRegisterGloballyMapper()));
      expect(deserialized, isNotNull);
      expect(deserialized.iri, equals(instance.iri));
      expect(
          mapper.registry.hasLocalResourceDeserializerFor<
              ClassWithEmptyIriStrategyNoRegisterGlobally>(),
          isFalse,
          reason:
              'ClassNoRegisterGlobally should still not be registered globally, even after local registration');
    });

    test('ClassWithNoRdfType mapping', () {
      // Verify global resource registration
      final isRegistered = mapper.registry
          .hasGlobalResourceDeserializerFor<ClassWithNoRdfType>();
      expect(isRegistered, isTrue,
          reason:
              'ClassWithNoRdfType should be registered as a global resource');

      // Create a ClassWithNoRdfType instance
      final instance = ClassWithNoRdfType('John Doe', age: 30);
      instance.iri = 'http://example.org/persons/john';

      // Test serialization
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);

      // Test deserialization
      final deserialized = mapper.decodeObject<ClassWithNoRdfType>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.iri, equals(instance.iri));
      expect(deserialized.name, equals(instance.name));
      expect(deserialized.age, equals(instance.age));
    });

    test('ClassWithIriNamedMapperStrategy1Part mapping', () {
      expect(
          mapper.registry.hasGlobalResourceDeserializerFor<
              ClassWithIriNamedMapperStrategy1Part>(),
          isFalse,
          reason:
              'ClassWithIriNamedMapperStrategy1Part should not be registered globally');

      final instance = ClassWithIriNamedMapperStrategy1Part(id: 'test-id');

      // Create IRI mapper for single part tuple
      final iriMapper = _TestMapper1Part();

      // Test serialization with explicit registration
      final graph = mapper.encodeObject(instance,
          register: (r) => r.registerMapper(
              ClassWithIriNamedMapperStrategy1PartMapper(
                  testMapper1Part: iriMapper)));
      expect(graph, isNotNull);
      expect(graph, contains('ex:test-id'));
      expect(graph, contains('<http://example.org/1part/>'));

      // Test deserialization
      final deserialized =
          mapper.decodeObject<ClassWithIriNamedMapperStrategy1Part>(graph,
              register: (r) => r.registerMapper(
                  ClassWithIriNamedMapperStrategy1PartMapper(
                      testMapper1Part: iriMapper)));
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(instance.id));
    });

    test('ClassWithIriNamedMapperStrategy2Parts mapping', () {
      expect(
          mapper.registry.hasGlobalResourceDeserializerFor<
              ClassWithIriNamedMapperStrategy2Parts>(),
          isFalse,
          reason:
              'ClassWithIriNamedMapperStrategy2Parts should not be registered globally');

      final instance =
          ClassWithIriNamedMapperStrategy2Parts(id: 'test-id', version: 42);

      // Create IRI mapper for two part tuple
      final iriMapper = _TestMapper2Parts();

      // Test serialization with explicit registration
      final graph = mapper.encodeObject(instance,
          register: (r) => r.registerMapper(
              ClassWithIriNamedMapperStrategy2PartsMapper(
                  testMapper2Parts: iriMapper)));
      expect(graph, isNotNull);
      expect(graph, contains('http://example.org/2parts/test-id/42'));

      // Test deserialization
      final deserialized =
          mapper.decodeObject<ClassWithIriNamedMapperStrategy2Parts>(graph,
              register: (r) => r.registerMapper(
                  ClassWithIriNamedMapperStrategy2PartsMapper(
                      testMapper2Parts: iriMapper)));
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(instance.id));
      expect(deserialized.version, equals(instance.version));
    });

    test('ClassWithIriNamedMapperStrategy2PartsSwapped mapping', () {
      expect(
          mapper.registry.hasGlobalResourceDeserializerFor<
              ClassWithIriNamedMapperStrategy2PartsSwapped>(),
          isFalse,
          reason:
              'ClassWithIriNamedMapperStrategy2PartsSwapped should not be registered globally');

      final instance = ClassWithIriNamedMapperStrategy2PartsSwapped(
          id: 'test-id', version: 99);

      // Create IRI mapper for swapped two part tuple (version, id)
      final iriMapper = _TestMapper2PartsSwapped();

      // Test serialization with explicit registration
      final graph = mapper.encodeObject(instance,
          register: (r) => r.registerMapper(
              ClassWithIriNamedMapperStrategy2PartsSwappedMapper(
                  testMapper2PartsSwapped: iriMapper)));
      expect(graph, isNotNull);
      expect(graph, contains('swapped:test-id'));
      expect(graph, contains('<http://example.org/swapped/99/>'));

      // Test deserialization
      final deserialized = mapper
          .decodeObject<ClassWithIriNamedMapperStrategy2PartsSwapped>(graph,
              register: (r) => r.registerMapper(
                  ClassWithIriNamedMapperStrategy2PartsSwappedMapper(
                      testMapper2PartsSwapped: iriMapper)));
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(instance.id));
      expect(deserialized.version, equals(instance.version));
    });

    test('ClassWithMapperNamedMapperStrategy mapping', () {
      // Note: This class uses a named mapper strategy that requires external setup.
      // The class should be globally registered, but the actual mapper implementation
      // should fail because testGlobalResourceMapper is not properly implemented.
      final instance = ClassWithMapperNamedMapperStrategy();

      final turtle = mapper.encodeObject(instance);
      expect(
          turtle.trim(),
          '''
@prefix g: <http://example.org/g/> .
@prefix instance: <http://example.org/instance/> .

instance:ClassWithMapperNamedMapperStrategy a g:ClassWithMapperNamedMapperStrategy .
'''
              .trim());
      final deserialized =
          mapper.decodeObject<ClassWithMapperNamedMapperStrategy>(turtle);
      expect(deserialized, isA<ClassWithMapperNamedMapperStrategy>());
    });

    test('ClassWithMapperStrategy mapping', () {
      expect(
          mapper.registry
              .hasGlobalResourceDeserializerFor<ClassWithMapperStrategy>(),
          isTrue,
          reason: 'ClassWithMapperStrategy should be registered globally');

      final instance = ClassWithMapperStrategy();

      final turtle = mapper.encodeObject(instance);
      expect(
          turtle.trim(),
          '''
@prefix g: <http://example.org/g/> .
@prefix instance: <http://example.org/instance/> .

instance:ClassWithMapperStrategy a g:ClassWithMapperStrategy .
'''
              .trim());
      final deserialized = mapper.decodeObject<ClassWithMapperStrategy>(turtle);
      expect(deserialized, isA<ClassWithMapperStrategy>());
    });

    test('ClassWithMapperInstanceStrategy mapping', () {
      expect(
          mapper.registry.hasGlobalResourceDeserializerFor<
              ClassWithMapperInstanceStrategy>(),
          isTrue,
          reason:
              'ClassWithMapperInstanceStrategy should be registered globally');

      final instance = ClassWithMapperInstanceStrategy();

      final turtle = mapper.encodeObject(instance);
      expect(
          turtle.trim(),
          '''
@prefix g: <http://example.org/g/> .
@prefix instance: <http://example.org/instance/> .

instance:ClassWithMapperInstanceStrategy a g:ClassWithMapperInstanceStrategy .
'''
              .trim());
      final deserialized =
          mapper.decodeObject<ClassWithMapperInstanceStrategy>(turtle);
      expect(deserialized, isA<ClassWithMapperInstanceStrategy>());
    });

    test('ClassWithIriNamedMapperStrategy2PartsWithProperties mapping', () {
      expect(
          mapper.registry.hasGlobalResourceDeserializerFor<
              ClassWithIriNamedMapperStrategy2PartsWithProperties>(),
          isTrue);

      final instance = ClassWithIriNamedMapperStrategy2PartsWithProperties();
      instance.id = 'test-id';
      instance.surname = 'smith';
      instance.version = 42;
      instance.givenName = 'John';
      instance.age = 30;

      // Test serialization with explicit registration
      final graph = mapper.encodeObject(instance);
      expect(graph, isNotNull);
      expect(graph, contains('http://example.org/3parts/test-id/smith/42'));
      expect(graph, contains('John')); // givenName
      expect(graph, contains('smith')); // surname
      expect(graph, contains('30')); // age

      // Test deserialization
      final deserialized = mapper.decodeObject<
          ClassWithIriNamedMapperStrategy2PartsWithProperties>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(instance.id));
      expect(deserialized.surname, equals(instance.surname));
      expect(deserialized.version, equals(instance.version));
      expect(deserialized.givenName, equals(instance.givenName));
      expect(deserialized.age, equals(instance.age));
    });
  });
}
