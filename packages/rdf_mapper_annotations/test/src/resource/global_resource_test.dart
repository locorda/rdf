import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:test/test.dart';

class MockGlobalResourceMapper implements GlobalResourceMapper {
  const MockGlobalResourceMapper();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  group('RdfGlobalResource', () {
    test('standard constructor with classIri and iriStrategy', () {
      final classIri = const IriTerm('http://example.org/classIri');
      final iriStrategy = IriStrategy('http://example.org/resource/{id}');

      final annotation = RdfGlobalResource(classIri, iriStrategy);

      expect(annotation.classIri, equals(classIri));
      expect(annotation.iri, equals(iriStrategy));
      expect(annotation.mapper, isNull);
    });

    test('namedMapper constructor sets mapper name', () {
      const mapperName = 'testMapper';
      final annotation = RdfGlobalResource.namedMapper(mapperName);

      expect(annotation.classIri, isNull);
      expect(annotation.iri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, equals(mapperName));
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNull);
    });

    test('mapper constructor sets mapper type', () {
      final annotation = RdfGlobalResource.mapper(MockGlobalResourceMapper);

      expect(annotation.classIri, isNull);
      expect(annotation.iri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, equals(MockGlobalResourceMapper));
      expect(annotation.mapper!.instance, isNull);
    });

    test('mapperInstance constructor sets mapper instance', () {
      const mapperInstance = MockGlobalResourceMapper();
      final annotation = RdfGlobalResource.mapperInstance(mapperInstance);

      expect(annotation.classIri, isNull);
      expect(annotation.iri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, equals(mapperInstance));
    });

    test('deserializeOnly constructor with classIri', () {
      final classIri = const IriTerm('http://example.org/classIri');
      final annotation = RdfGlobalResource.deserializeOnly(classIri);

      expect(annotation.classIri, equals(classIri));
      expect(annotation.iri, isNull);
      expect(annotation.mapper, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.direction, equals(MapperDirection.deserializeOnly));
    });

    test('deserializeOnly constructor with registerGlobally false', () {
      final classIri = const IriTerm('http://example.org/classIri');
      final annotation =
          RdfGlobalResource.deserializeOnly(classIri, registerGlobally: false);

      expect(annotation.classIri, equals(classIri));
      expect(annotation.iri, isNull);
      expect(annotation.registerGlobally, isFalse);
      expect(annotation.direction, equals(MapperDirection.deserializeOnly));
    });

    test('serializeOnly constructor with classIri and iriStrategy', () {
      final classIri = const IriTerm('http://example.org/classIri');
      final iriStrategy = IriStrategy('http://example.org/resource/{id}');
      final annotation = RdfGlobalResource.serializeOnly(classIri, iriStrategy);

      expect(annotation.classIri, equals(classIri));
      expect(annotation.iri, equals(iriStrategy));
      expect(annotation.mapper, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.direction, equals(MapperDirection.serializeOnly));
    });

    test('namedMapper with direction parameter', () {
      const mapperName = 'testMapper';
      final annotation = RdfGlobalResource.namedMapper(
        mapperName,
        direction: MapperDirection.deserializeOnly,
      );

      expect(annotation.classIri, isNull);
      expect(annotation.iri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, equals(mapperName));
      expect(annotation.direction, equals(MapperDirection.deserializeOnly));
    });

    test('mapper with direction parameter', () {
      final annotation = RdfGlobalResource.mapper(
        MockGlobalResourceMapper,
        direction: MapperDirection.serializeOnly,
      );

      expect(annotation.classIri, isNull);
      expect(annotation.iri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.type, equals(MockGlobalResourceMapper));
      expect(annotation.direction, equals(MapperDirection.serializeOnly));
    });

    test('mapperInstance with direction parameter', () {
      const mapperInstance = MockGlobalResourceMapper();
      final annotation = RdfGlobalResource.mapperInstance(
        mapperInstance,
        direction: MapperDirection.deserializeOnly,
      );

      expect(annotation.classIri, isNull);
      expect(annotation.iri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.instance, equals(mapperInstance));
      expect(annotation.direction, equals(MapperDirection.deserializeOnly));
    });

    test('default direction is both for namedMapper', () {
      final annotation = RdfGlobalResource.namedMapper('testMapper');
      expect(annotation.direction, equals(MapperDirection.both));
    });

    test('default direction is both for mapper', () {
      final annotation = RdfGlobalResource.mapper(MockGlobalResourceMapper);
      expect(annotation.direction, equals(MapperDirection.both));
    });

    test('default direction is both for mapperInstance', () {
      const mapperInstance = MockGlobalResourceMapper();
      final annotation = RdfGlobalResource.mapperInstance(mapperInstance);
      expect(annotation.direction, equals(MapperDirection.both));
    });
  });

  group('GlobalResourceMapping', () {
    test('namedMapper constructor sets mapper name', () {
      const mapperName = 'testMapper';
      final mapping = GlobalResourceMapping.namedMapper(mapperName);

      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, equals(mapperName));
      expect(mapping.mapper!.type, isNull);
      expect(mapping.mapper!.instance, isNull);
    });

    test('mapper constructor sets mapper type', () {
      final mapping = GlobalResourceMapping.mapper(MockGlobalResourceMapper);

      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, isNull);
      expect(mapping.mapper!.type, equals(MockGlobalResourceMapper));
      expect(mapping.mapper!.instance, isNull);
    });

    test('mapperInstance constructor sets mapper instance', () {
      const mapperInstance = MockGlobalResourceMapper();
      final mapping = GlobalResourceMapping.mapperInstance(mapperInstance);

      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, isNull);
      expect(mapping.mapper!.type, isNull);
      expect(mapping.mapper!.instance, equals(mapperInstance));
    });
  });
}
