import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:test/test.dart';

class MockLiteralTermMapper implements LiteralTermMapper {
  const MockLiteralTermMapper();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  group('RdfLiteral', () {
    test('default constructor', () {
      final annotation = RdfLiteral();

      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);
      expect(annotation.mapper, isNull);
    });

    test('custom constructor with methods', () {
      const toMethod = 'toRdf';
      const fromMethod = 'fromRdf';
      final annotation = RdfLiteral.custom(
          toLiteralTermMethod: toMethod, fromLiteralTermMethod: fromMethod);

      expect(annotation.toLiteralTermMethod, equals(toMethod));
      expect(annotation.fromLiteralTermMethod, equals(fromMethod));
      expect(annotation.mapper, isNull);
    });

    test('namedMapper constructor sets mapper name', () {
      const mapperName = 'testMapper';
      final annotation = RdfLiteral.namedMapper(mapperName);

      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, equals(mapperName));
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNull);
    });

    test('mapper constructor sets mapper type', () {
      final annotation = RdfLiteral.mapper(MockLiteralTermMapper);

      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, equals(MockLiteralTermMapper));
      expect(annotation.mapper!.instance, isNull);
    });

    test('mapperInstance constructor sets mapper instance', () {
      const mapperInstance = MockLiteralTermMapper();
      final annotation = RdfLiteral.mapperInstance(mapperInstance);

      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, equals(mapperInstance));
    });
  });

  group('LiteralMapping', () {
    test('namedMapper constructor sets mapper name', () {
      const mapperName = 'testMapper';
      final mapping = LiteralMapping.namedMapper(mapperName);

      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, equals(mapperName));
      expect(mapping.mapper!.type, isNull);
      expect(mapping.mapper!.instance, isNull);
    });

    test('mapper constructor sets mapper type', () {
      final mapping = LiteralMapping.mapper(MockLiteralTermMapper);

      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, isNull);
      expect(mapping.mapper!.type, equals(MockLiteralTermMapper));
      expect(mapping.mapper!.instance, isNull);
    });

    test('mapperInstance constructor sets mapper instance', () {
      const mapperInstance = MockLiteralTermMapper();
      final mapping = LiteralMapping.mapperInstance(mapperInstance);

      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, isNull);
      expect(mapping.mapper!.type, isNull);
      expect(mapping.mapper!.instance, equals(mapperInstance));
    });

    test('withLanguage constructor sets language tag', () {
      const languageTag = 'en';
      final mapping = LiteralMapping.withLanguage(languageTag);

      expect(mapping.language, equals(languageTag));
      expect(mapping.datatype, isNull);
      expect(mapping.mapper, isNull);
    });

    test('withType constructor sets datatype', () {
      // Using example datatype from rdf_vocabularies package
      final datatype = IriTerm('http://example.org/customType');
      final mapping = LiteralMapping.withType(datatype);

      expect(mapping.datatype, equals(datatype));
      expect(mapping.language, isNull);
      expect(mapping.mapper, isNull);
    });
  });

  group('RdfValue', () {
    test('constructor without format', () {
      final annotation = RdfValue();

      expect(annotation, isA<RdfAnnotation>());
    });
  });

  group('RdfLanguageTag', () {
    test('default constructor', () {
      final annotation = RdfLanguageTag();

      expect(annotation, isA<RdfAnnotation>());
    });
  });
}
