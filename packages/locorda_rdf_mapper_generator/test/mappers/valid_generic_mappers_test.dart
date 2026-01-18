import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:test/test.dart';
import 'package:locorda_rdf_core/core.dart';

// Import test models
import '../fixtures/valid_generic_test_models.dart';
import '../fixtures/valid_generic_test_models.rdf_mapper.g.dart';
import 'init_test_rdf_mapper_util.dart';

/// Simple literal mapper for `Map<String, int>` for testing purposes
class SimpleMapMapper implements LiteralTermMapper<Map<String, int>> {
  const SimpleMapMapper();

  @override
  IriTerm? get datatype => null;

  @override
  Map<String, int> fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    // Parse JSON-like format: {"key1":42,"key2":100}
    final value = term.value.trim();
    if (value.isEmpty || value == '{}') return <String, int>{};

    try {
      // Simple JSON-like parsing for Map<String, int>
      final map = <String, int>{};
      final content = value.substring(1, value.length - 1); // Remove { and }
      if (content.isNotEmpty) {
        final pairs = content.split(',');
        for (final pair in pairs) {
          final colonIndex = pair.indexOf(':');
          if (colonIndex > 0) {
            final key =
                pair.substring(0, colonIndex).trim().replaceAll('"', '');
            final valueStr = pair.substring(colonIndex + 1).trim();
            final intValue = int.parse(valueStr);
            map[key] = intValue;
          }
        }
      }
      return map;
    } catch (e) {
      throw FormatException('Invalid map format: $value');
    }
  }

  @override
  LiteralTerm toRdfTerm(Map<String, int> value, SerializationContext context) {
    if (value.isEmpty) return LiteralTerm('{}');
    final entries = value.entries.map((e) => '"${e.key}":${e.value}').join(',');
    return LiteralTerm('{$entries}');
  }
}

void main() {
  late RdfMapper mapper;

  setUp(() {
    mapper = defaultInitTestRdfMapper(
      testMapper: TestMapper(),
      customCollectionMapper: TestCustomCollectionMapper(),
    );
    // Register the complex type mappers globally for generic class testing
    mapper.registry.registerMapper(SimpleMapMapper());
  });

  group('Valid Generic Mapper Tests', () {
    test('GenericDocument<String> mapping', () {
      // Verify it's NOT registered globally (registerGlobally: false)
      final isRegisteredGlobally = mapper.registry
          .hasGlobalResourceDeserializerFor<GenericDocument<String>>();
      expect(isRegisteredGlobally, isFalse,
          reason: 'GenericDocument should not be registered globally');

      // Create a GenericDocument<String> instance
      final document = GenericDocument<String>(
        documentIri: 'http://example.org/documents/test-doc',
        primaryTopic: 'Test Topic String',
        title: 'Test Document Title',
      );

      // Test serialization with explicit registration
      final graph = mapper.encodeObject(document,
          contentType: 'application/n-triples',
          register: (registry) =>
              registry.registerMapper(GenericDocumentMapper<String>()));
      expect(graph, isNotNull);
      expect(graph, contains('Test Topic String'));
      expect(graph, contains('Test Document Title'));
      expect(graph, contains('http://example.org/documents/test-doc'));

      // Test deserialization with explicit registration
      final deserialized = mapper.decodeObject<GenericDocument<String>>(graph,
          register: (registry) =>
              registry.registerMapper(GenericDocumentMapper<String>()));
      expect(deserialized, isNotNull);
      expect(deserialized.documentIri, equals(document.documentIri));
      expect(deserialized.primaryTopic, equals(document.primaryTopic));
      expect(deserialized.title, equals(document.title));
    });

    test('GenericDocument<int> mapping', () {
      // Create a GenericDocument<int> instance
      final document = GenericDocument<int>(
        documentIri: 'http://example.org/documents/numeric-doc',
        primaryTopic: 42,
        title: 'Numeric Document',
      );

      // Test serialization with explicit registration
      final graph = mapper.encodeObject(document,
          register: (registry) =>
              registry.registerMapper(GenericDocumentMapper<int>()));
      expect(graph, isNotNull);
      expect(graph, contains('42'));
      expect(graph, contains('Numeric Document'));

      // Test deserialization with explicit registration
      final deserialized = mapper.decodeObject<GenericDocument<int>>(graph,
          register: (registry) =>
              registry.registerMapper(GenericDocumentMapper<int>()));
      expect(deserialized, isNotNull);
      expect(deserialized.documentIri, equals(document.documentIri));
      expect(deserialized.primaryTopic, equals(document.primaryTopic));
      expect(deserialized.title, equals(document.title));
    });

    test('GenericDocument<List<String>> complex type mapping', () {
      // Test with complex generic type
      final document = GenericDocument<List<String>>(
        documentIri: 'http://example.org/documents/list-doc',
        primaryTopic: ['item1', 'item2', 'item3'],
        title: 'List Document',
      );

      // Test serialization with explicit registration of both the document mapper and the List<String> mapper
      final graph = mapper.encodeObject(document, register: (registry) {
        registry.registerMapper(GenericDocumentMapper<List<String>>());
        registry.registerMapper(TestCustomCollectionMapper());
      });
      expect(graph, isNotNull);
      expect(graph, contains('List Document'));

      // Test deserialization with explicit registration
      final deserialized = mapper.decodeObject<GenericDocument<List<String>>>(
          graph, register: (registry) {
        registry.registerMapper(GenericDocumentMapper<List<String>>());
        registry.registerMapper(TestCustomCollectionMapper());
      });
      expect(deserialized, isNotNull);
      expect(deserialized.documentIri, equals(document.documentIri));
      expect(deserialized.primaryTopic, equals(document.primaryTopic));
      expect(deserialized.title, equals(document.title));
    });

    test('MultiGenericDocument<String, int, bool> mapping', () {
      // Verify it's NOT registered globally
      final isRegisteredGlobally = mapper.registry
          .hasGlobalResourceDeserializerFor<
              MultiGenericDocument<String, int, bool>>();
      expect(isRegisteredGlobally, isFalse,
          reason: 'MultiGenericDocument should not be registered globally');

      // Create a MultiGenericDocument instance
      final document = MultiGenericDocument<String, int, bool>(
        documentIri: 'http://example.org/documents/multi-generic',
        primaryTopic: 'Multi Generic Topic',
        author: 123,
        metadata: true,
      );

      // Test serialization with explicit registration
      final graph = mapper.encodeObject(document,
          register: (registry) => registry
              .registerMapper(MultiGenericDocumentMapper<String, int, bool>()));
      expect(graph, isNotNull);
      expect(graph, contains('Multi Generic Topic'));
      expect(graph, contains('123'));

      // Test deserialization with explicit registration
      final deserialized =
          mapper.decodeObject<MultiGenericDocument<String, int, bool>>(graph,
              register: (registry) => registry.registerMapper(
                  MultiGenericDocumentMapper<String, int, bool>()));
      expect(deserialized, isNotNull);
      expect(deserialized.documentIri, equals(document.documentIri));
      expect(deserialized.primaryTopic, equals(document.primaryTopic));
      expect(deserialized.author, equals(document.author));
      expect(deserialized.metadata, equals(document.metadata));
    });

    test('NonGenericPerson mapping', () {
      // Verify it IS registered globally (registerGlobally: true)
      final isRegisteredGlobally =
          mapper.registry.hasGlobalResourceDeserializerFor<NonGenericPerson>();
      expect(isRegisteredGlobally, isTrue,
          reason: 'NonGenericPerson should be registered globally');

      // Create a NonGenericPerson instance
      final person = NonGenericPerson(
        id: 'john-doe',
        name: 'John Doe',
      );

      // Test serialization (no explicit registration needed)
      final graph =
          mapper.encodeObject(person, contentType: 'application/n-triples');
      expect(graph, isNotNull);
      expect(graph, contains('John Doe'));
      expect(graph, contains('http://example.org/persons/john-doe'));

      // Test deserialization (no explicit registration needed)
      final deserialized = mapper.decodeObject<NonGenericPerson>(graph);
      expect(deserialized, isNotNull);
      expect(deserialized.id, equals(person.id));
      expect(deserialized.name, equals(person.name));
    });

    test('GenericLocalResource<String> mapping', () {
      // Verify it's NOT registered globally (local resource)
      final isRegisteredGlobally = mapper.registry
          .hasGlobalResourceDeserializerFor<GenericLocalResource<String>>();
      expect(isRegisteredGlobally, isFalse,
          reason:
              'GenericLocalResource should not be registered as global resource');
      final isRegisteredLocally = mapper.registry
          .hasLocalResourceDeserializerFor<GenericLocalResource<String>>();
      expect(isRegisteredLocally, isFalse,
          reason:
              'GenericLocalResource should not be registered automatically');

      // Create a GenericLocalResource<String> instance
      final resource = GenericLocalResource<String>(
        value: 'Local Resource Value',
        label: 'Test Local Resource',
      );

      // Test serialization with explicit registration
      final graph = mapper.encodeObject(resource,
          register: (registry) =>
              registry.registerMapper(GenericLocalResourceMapper<String>()));
      expect(graph, isNotNull);
      expect(graph, contains('Local Resource Value'));
      expect(graph, contains('Test Local Resource'));

      // Test deserialization with explicit registration
      final deserialized = mapper.decodeObject<GenericLocalResource<String>>(
          graph,
          register: (registry) =>
              registry.registerMapper(GenericLocalResourceMapper<String>()));
      expect(deserialized, isNotNull);
      expect(deserialized.value, equals(resource.value));
      expect(deserialized.label, equals(resource.label));
    });

    test('GenericLocalResource<Map<String, int>> complex type mapping', () {
      // Test with complex generic type for local resource
      final resource = GenericLocalResource<Map<String, int>>(
        value: {'count': 42, 'total': 100},
        label: 'Map Resource',
      );

      // Test serialization with explicit registration of both mappers
      final graph = mapper.encodeObject(resource, register: (registry) {
        registry
          ..registerMapper(GenericLocalResourceMapper<Map<String, int>>())
          ..registerMapper<Map<String, int>>(SimpleMapMapper());
      });
      expect(graph, isNotNull);
      expect(graph, contains('Map Resource'));

      // Test deserialization with explicit registration
      final deserialized = mapper
          .decodeObject<GenericLocalResource<Map<String, int>>>(graph,
              register: (registry) {
        registry
          ..registerMapper(GenericLocalResourceMapper<Map<String, int>>())
          ..registerMapper<Map<String, int>>(SimpleMapMapper());
      });
      expect(deserialized, isNotNull);
      expect(deserialized.value, equals(resource.value));
      expect(deserialized.label, equals(resource.label));
    });

    test('Multiple generic document instances with different type parameters',
        () {
      // Test that different type parameters create distinct mappers
      final stringDoc = GenericDocument<String>(
        documentIri: 'http://example.org/documents/string-doc',
        primaryTopic: 'String Topic',
        title: 'String Document',
      );

      final intDoc = GenericDocument<int>(
        documentIri: 'http://example.org/documents/int-doc',
        primaryTopic: 999,
        title: 'Integer Document',
      );

      final boolDoc = GenericDocument<bool>(
        documentIri: 'http://example.org/documents/bool-doc',
        primaryTopic: true,
        title: 'Boolean Document',
      );

      // Test serialization with different mappers
      final stringGraph = mapper.encodeObject(stringDoc,
          register: (registry) =>
              registry.registerMapper(GenericDocumentMapper<String>()));
      final intGraph = mapper.encodeObject(intDoc,
          register: (registry) =>
              registry.registerMapper(GenericDocumentMapper<int>()));
      final boolGraph = mapper.encodeObject(boolDoc,
          register: (registry) =>
              registry.registerMapper(GenericDocumentMapper<bool>()));

      expect(stringGraph, isNotNull);
      expect(intGraph, isNotNull);
      expect(boolGraph, isNotNull);

      // Test deserialization with correct type preservation
      final deserializedString = mapper.decodeObject<GenericDocument<String>>(
          stringGraph,
          register: (registry) =>
              registry.registerMapper(GenericDocumentMapper<String>()));
      final deserializedInt = mapper.decodeObject<GenericDocument<int>>(
          intGraph,
          register: (registry) =>
              registry.registerMapper(GenericDocumentMapper<int>()));
      final deserializedBool = mapper.decodeObject<GenericDocument<bool>>(
          boolGraph,
          register: (registry) =>
              registry.registerMapper(GenericDocumentMapper<bool>()));

      // Verify type safety is maintained
      expect(deserializedString.primaryTopic, isA<String>());
      expect(deserializedInt.primaryTopic, isA<int>());
      expect(deserializedBool.primaryTopic, isA<bool>());

      expect(deserializedString.primaryTopic, equals('String Topic'));
      expect(deserializedInt.primaryTopic, equals(999));
      expect(deserializedBool.primaryTopic, equals(true));
    });

    test('Registration behavior verification', () {
      // Verify that registerGlobally=false classes are not auto-registered
      expect(
          mapper.registry
              .hasGlobalResourceDeserializerFor<GenericDocument<String>>(),
          isFalse);
      expect(
          mapper.registry.hasGlobalResourceDeserializerFor<
              MultiGenericDocument<String, int, bool>>(),
          isFalse);
      expect(
          mapper.registry
              .hasGlobalResourceDeserializerFor<GenericLocalResource<String>>(),
          isFalse);

      // Verify that registerGlobally=true classes are auto-registered
      expect(
          mapper.registry.hasGlobalResourceDeserializerFor<NonGenericPerson>(),
          isTrue);

      // Test serialization fails without explicit registration for generic classes
      final document = GenericDocument<String>(
        documentIri: 'http://example.org/test',
        primaryTopic: 'Test',
        title: 'Test',
      );

      expect(() => mapper.encodeObject(document),
          throwsA(isA<SerializerNotFoundException>()));

      // Test deserialization fails without explicit registration
      final graph = """
@prefix foaf: <http://xmlns.com/foaf/0.1/> .

<http://example.org/test> a foaf:Document ;
    foaf:primaryTopic "Test" ;
    foaf:title "Test" .
""";

      expect(() => mapper.decodeObject<GenericDocument<String>>(graph),
          throwsA(isA<DeserializerNotFoundException>()));
    });
  });
}
