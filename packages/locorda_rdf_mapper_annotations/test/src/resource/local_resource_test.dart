import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
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

    test('define constructor with vocab', () {
      const vocab = AppVocab(appBaseUri: 'https://my.app.de');

      final annotation = RdfLocalResource.define(vocab);

      expect(annotation.vocab, equals(vocab));
      expect(annotation.classIri, isNull);
      expect(annotation.subClassOf, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
    });

    test('define constructor with subClassOf', () {
      const vocab = AppVocab(appBaseUri: 'https://my.app.de');
      final subClassOf = const IriTerm('https://schema.org/Chapter');

      final annotation = RdfLocalResource.define(
        vocab,
        subClassOf: subClassOf,
      );

      expect(annotation.vocab, equals(vocab));
      expect(annotation.classIri, isNull);
      expect(annotation.subClassOf, equals(subClassOf));
      expect(annotation.registerGlobally, isTrue);
    });

    test('define constructor with custom vocabPath', () {
      const vocab = AppVocab(
        appBaseUri: 'https://example.org',
        vocabPath: '/custom',
      );

      final annotation = RdfLocalResource.define(vocab);

      expect(annotation.vocab, equals(vocab));
      expect(annotation.vocab!.vocabPath, equals('/custom'));
    });

    test('define constructor with class metadata', () {
      const vocab = AppVocab(appBaseUri: 'https://my.app.de');
      final metadata = [
        (
          const IriTerm('http://www.w3.org/2000/01/rdf-schema#comment'),
          LiteralTerm('Generated class metadata')
        ),
      ];

      final annotation = RdfLocalResource.define(
        vocab,
        metadata: metadata,
      );

      expect(annotation.metadata, equals(metadata));
    });

    test('define constructor with class label and comment', () {
      const vocab = AppVocab(appBaseUri: 'https://my.app.de');

      final annotation = RdfLocalResource.define(
        vocab,
        label: 'Chapter',
        comment: 'A generated vocabulary class for chapters',
      );

      expect(annotation.label, equals('Chapter'));
      expect(annotation.comment,
          equals('A generated vocabulary class for chapters'));
    });

    test('standard constructor has null vocab and subClassOf', () {
      final classIri = const IriTerm('http://example.org/classIri');

      final annotation = RdfLocalResource(classIri);

      expect(annotation.vocab, isNull);
      expect(annotation.subClassOf, isNull);
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
