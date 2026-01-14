import 'package:test/test.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/src/property/contextual_mapping.dart';

void main() {
  group('ContextualMapping', () {
    test('namedProvider constructor creates mapping with correct mapper name',
        () {
      final mapping = ContextualMapping.namedProvider('example');
      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, equals('example'));
      expect(mapping.mapper!.type, isNull);
      expect(mapping.mapper!.instance, isNull);
    });

    test('provider constructor creates mapping with type', () {
      final mapping = ContextualMapping.provider(SerializationProvider);
      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, isNull);
      expect(mapping.mapper!.type, equals(SerializationProvider));
      expect(mapping.mapper!.instance, isNull);
    });

    test('providerInstance constructor creates mapping with instance', () {
      final mockProvider = _MockSerializationProvider();
      final mapping = ContextualMapping.providerInstance(mockProvider);
      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, isNull);
      expect(mapping.mapper!.type, isNull);
      expect(mapping.mapper!.instance, equals(mockProvider));
    });

    test('named mappings with same name have same mapper reference', () {
      final mapping1 = ContextualMapping.namedProvider('test');
      final mapping2 = ContextualMapping.namedProvider('test');

      expect(mapping1.mapper!.name, equals(mapping2.mapper!.name));
    });

    test('named mappings with different names have different mapper references',
        () {
      final mapping1 = ContextualMapping.namedProvider('first');
      final mapping2 = ContextualMapping.namedProvider('second');

      expect(mapping1.mapper!.name, equals('first'));
      expect(mapping2.mapper!.name, equals('second'));
      expect(mapping1.mapper!.name, isNot(equals(mapping2.mapper!.name)));
    });

    test('different constructor types create different mapping configurations',
        () {
      final namedMapping = ContextualMapping.namedProvider('test');
      final typeMapping = ContextualMapping.provider(SerializationProvider);

      expect(namedMapping.mapper!.name, isNotNull);
      expect(namedMapping.mapper!.type, isNull);

      expect(typeMapping.mapper!.name, isNull);
      expect(typeMapping.mapper!.type, isNotNull);
    });
  });
}

// Mock class for testing instance mapping
class _MockSerializationProvider implements SerializationProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
