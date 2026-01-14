import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:test/test.dart';

class MockIriTermMapper implements IriTermMapper {
  const MockIriTermMapper();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  group('RdfIri', () {
    test('default constructor without template', () {
      final annotation = RdfIri();

      expect(annotation.template, isNull);
      expect(annotation.mapper, isNull);
    });

    test('default constructor with template', () {
      const template = 'http://example.org/resource/{id}';
      final annotation = RdfIri(template);

      expect(annotation.template, equals(template));
      expect(annotation.mapper, isNull);
    });

    test('namedMapper constructor sets mapper name', () {
      const mapperName = 'testMapper';
      final annotation = RdfIri.namedMapper(mapperName);

      expect(annotation.template, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, equals(mapperName));
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNull);
    });

    test('mapper constructor sets mapper type', () {
      final annotation = RdfIri.mapper(MockIriTermMapper);

      expect(annotation.template, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, equals(MockIriTermMapper));
      expect(annotation.mapper!.instance, isNull);
    });

    test('mapperInstance constructor sets mapper instance', () {
      const mapperInstance = MockIriTermMapper();
      final annotation = RdfIri.mapperInstance(mapperInstance);

      expect(annotation.template, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, equals(mapperInstance));
    });
  });

  group('IriMapping', () {
    test('constructor with template', () {
      const template = 'http://example.org/resource/{id}';
      final mapping = IriMapping(template);

      expect(mapping.template, equals(template));
      expect(mapping.mapper, isNull);
    });

    test('namedMapper constructor sets mapper name', () {
      const mapperName = 'testMapper';
      final mapping = IriMapping.namedMapper(mapperName);

      expect(mapping.template, isNull);
      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, equals(mapperName));
      expect(mapping.mapper!.type, isNull);
      expect(mapping.mapper!.instance, isNull);
    });

    test('mapper constructor sets mapper type', () {
      final mapping = IriMapping.mapper(MockIriTermMapper);

      expect(mapping.template, isNull);
      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, isNull);
      expect(mapping.mapper!.type, equals(MockIriTermMapper));
      expect(mapping.mapper!.instance, isNull);
    });

    test('mapperInstance constructor sets mapper instance', () {
      const mapperInstance = MockIriTermMapper();
      final mapping = IriMapping.mapperInstance(mapperInstance);

      expect(mapping.template, isNull);
      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, isNull);
      expect(mapping.mapper!.type, isNull);
      expect(mapping.mapper!.instance, equals(mapperInstance));
    });

    test('namedFactory constructor without config type', () {
      const factoryName = 'testFactory';
      final mapping = IriMapping.namedFactory(factoryName);

      expect(mapping.template, isNull);
      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, isNull);
      expect(mapping.mapper!.type, isNull);
      expect(mapping.mapper!.instance, isNull);
      expect(mapping.mapper!.factoryName, equals(factoryName));
      expect(mapping.mapper!.factoryConfigInstance, isNull);
    });

    test('namedFactory constructor with config instance', () {
      const factoryName = 'testFactory';
      const configInstance = 'testConfig';
      final mapping = IriMapping.namedFactory(factoryName, configInstance);

      expect(mapping.template, isNull);
      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, isNull);
      expect(mapping.mapper!.type, isNull);
      expect(mapping.mapper!.instance, isNull);
      expect(mapping.mapper!.factoryName, equals(factoryName));
      expect(mapping.mapper!.factoryConfigInstance, equals(configInstance));
    });
  });

  group('IriStrategy', () {
    test('constructor with template', () {
      const template = 'http://example.org/resource/{id}';
      final strategy = IriStrategy(template);

      expect(strategy.template, equals(template));
      expect(strategy.mapper, isNull);
    });

    test('namedMapper constructor sets mapper name', () {
      const mapperName = 'testStrategyMapper';
      final strategy = IriStrategy.namedMapper(mapperName);

      expect(strategy.template, isNull);
      expect(strategy.mapper, isNotNull);
      expect(strategy.mapper!.name, equals(mapperName));
      expect(strategy.mapper!.type, isNull);
      expect(strategy.mapper!.instance, isNull);
    });

    test('mapper constructor sets mapper type', () {
      final strategy = IriStrategy.mapper(MockIriTermMapper);

      expect(strategy.template, isNull);
      expect(strategy.mapper, isNotNull);
      expect(strategy.mapper!.name, isNull);
      expect(strategy.mapper!.type, equals(MockIriTermMapper));
      expect(strategy.mapper!.instance, isNull);
    });

    test('mapperInstance constructor sets mapper instance', () {
      const mapperInstance = MockIriTermMapper();
      final strategy = IriStrategy.mapperInstance(mapperInstance);

      expect(strategy.template, isNull);
      expect(strategy.mapper, isNotNull);
      expect(strategy.mapper!.name, isNull);
      expect(strategy.mapper!.type, isNull);
      expect(strategy.mapper!.instance, equals(mapperInstance));
    });

    test('namedFactory constructor without config type', () {
      const factoryName = 'testStrategyFactory';
      final strategy = IriStrategy.namedFactory(factoryName);

      expect(strategy.template, isNull);
      expect(strategy.mapper, isNotNull);
      expect(strategy.mapper!.name, isNull);
      expect(strategy.mapper!.type, isNull);
      expect(strategy.mapper!.instance, isNull);
      expect(strategy.mapper!.factoryName, equals(factoryName));
      expect(strategy.mapper!.factoryConfigInstance, isNull);
    });

    test('namedFactory constructor with type as config instance', () {
      const factoryName = 'testStrategyFactory';
      final strategy = IriStrategy.namedFactory(factoryName, String);

      expect(strategy.template, isNull);
      expect(strategy.mapper, isNotNull);
      expect(strategy.mapper!.name, isNull);
      expect(strategy.mapper!.type, isNull);
      expect(strategy.mapper!.instance, isNull);
      expect(strategy.mapper!.factoryName, equals(factoryName));
      expect(strategy.mapper!.factoryConfigInstance, equals(String));
    });
  });

  group('RdfIriPart', () {
    test('default constructor without name', () {
      final annotation = RdfIriPart();

      expect(annotation.name, isNull);
      expect(annotation.pos, isNull);
    });

    test('default constructor with name', () {
      const name = 'testName';
      final annotation = RdfIriPart(name);

      expect(annotation.name, equals(name));
      expect(annotation.pos, isNull);
    });

    test('position constructor', () {
      const position = 2;
      final annotation = RdfIriPart.position(position);

      expect(annotation.name, isNull);
      expect(annotation.pos, equals(position));
    });
  });
}
