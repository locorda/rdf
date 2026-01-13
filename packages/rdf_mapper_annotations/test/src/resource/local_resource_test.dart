import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:test/test.dart';

class MockLocalResourceMapper implements LocalResourceMapper {
  const MockLocalResourceMapper();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  group('RdfLocalResource', () {
    test('standard constructor with classIri', () {
      final classIri = const IriTerm('http://example.org/classIri');

      final annotation = RdfLocalResource(classIri);

      expect(annotation.classIri, equals(classIri));
      expect(annotation.mapper, isNull);
    });

    test('standard constructor with null classIri', () {
      final annotation = RdfLocalResource(null);

      expect(annotation.classIri, isNull);
      expect(annotation.mapper, isNull);
    });

    test('namedMapper constructor sets mapper name', () {
      const mapperName = 'testMapper';
      final annotation = RdfLocalResource.namedMapper(mapperName);

      expect(annotation.classIri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, equals(mapperName));
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNull);
    });

    test('mapper constructor sets mapper type', () {
      final annotation = RdfLocalResource.mapper(MockLocalResourceMapper);

      expect(annotation.classIri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, equals(MockLocalResourceMapper));
      expect(annotation.mapper!.instance, isNull);
    });

    test('mapperInstance constructor sets mapper instance', () {
      const mapperInstance = MockLocalResourceMapper();
      final annotation = RdfLocalResource.mapperInstance(mapperInstance);

      expect(annotation.classIri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, equals(mapperInstance));
    });
  });

  group('LocalResourceMapping', () {
    test('namedMapper constructor sets mapper name', () {
      const mapperName = 'testMapper';
      final mapping = LocalResourceMapping.namedMapper(mapperName);

      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, equals(mapperName));
      expect(mapping.mapper!.type, isNull);
      expect(mapping.mapper!.instance, isNull);
    });

    test('mapper constructor sets mapper type', () {
      final mapping = LocalResourceMapping.mapper(MockLocalResourceMapper);

      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, isNull);
      expect(mapping.mapper!.type, equals(MockLocalResourceMapper));
      expect(mapping.mapper!.instance, isNull);
    });

    test('mapperInstance constructor sets mapper instance', () {
      const mapperInstance = MockLocalResourceMapper();
      final mapping = LocalResourceMapping.mapperInstance(mapperInstance);

      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, isNull);
      expect(mapping.mapper!.type, isNull);
      expect(mapping.mapper!.instance, equals(mapperInstance));
    });
  });
}
