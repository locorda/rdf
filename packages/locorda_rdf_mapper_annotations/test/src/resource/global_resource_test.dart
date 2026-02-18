import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_core/owl.dart';
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

    test('define constructor with vocab and iriStrategy', () {
      const vocab = AppVocab(appBaseUri: 'https://my.app.de');
      final iriStrategy = IriStrategy('https://my.app.de/books/{id}');

      final annotation = RdfGlobalResource.define(vocab, iriStrategy);

      expect(annotation.vocab, equals(vocab));
      expect(annotation.iri, equals(iriStrategy));
      expect(annotation.classIri, isNull);
      expect(annotation.subClassOf, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
    });

    test('define constructor with subClassOf', () {
      const vocab = AppVocab(appBaseUri: 'https://my.app.de');
      final iriStrategy = IriStrategy('https://my.app.de/books/{id}');
      final subClassOf = const IriTerm('https://schema.org/Book');

      final annotation = RdfGlobalResource.define(
        vocab,
        iriStrategy,
        subClassOf: subClassOf,
      );

      expect(annotation.vocab, equals(vocab));
      expect(annotation.iri, equals(iriStrategy));
      expect(annotation.classIri, isNull);
      expect(annotation.subClassOf, equals(subClassOf));
      expect(annotation.registerGlobally, isTrue);
    });

    test('define constructor with registerGlobally false', () {
      const vocab = AppVocab(appBaseUri: 'https://my.app.de');
      final iriStrategy = IriStrategy('https://my.app.de/books/{id}');

      final annotation = RdfGlobalResource.define(
        vocab,
        iriStrategy,
        registerGlobally: false,
      );

      expect(annotation.vocab, equals(vocab));
      expect(annotation.iri, equals(iriStrategy));
      expect(annotation.registerGlobally, isFalse);
    });

    test('define constructor with class metadata', () {
      const vocab = AppVocab(appBaseUri: 'https://my.app.de');
      final iriStrategy = IriStrategy('https://my.app.de/books/{id}');
      final metadata = [
        (Owl.versionInfo, LiteralTerm('1.0.0')),
        (
          const IriTerm('http://purl.org/dc/terms/creator'),
          const IriTerm('https://example.org/team')
        ),
      ];

      final annotation = RdfGlobalResource.define(
        vocab,
        iriStrategy,
        metadata: metadata,
      );

      expect(annotation.metadata, equals(metadata));
    });

    test('define constructor with class label and comment', () {
      const vocab = AppVocab(appBaseUri: 'https://my.app.de');
      final iriStrategy = IriStrategy('https://my.app.de/books/{id}');

      final annotation = RdfGlobalResource.define(
        vocab,
        iriStrategy,
        label: 'Book',
        comment: 'A generated vocabulary class for books',
      );

      expect(annotation.label, equals('Book'));
      expect(
          annotation.comment, equals('A generated vocabulary class for books'));
    });

    test('define constructor with custom vocabPath', () {
      const vocab = AppVocab(
        appBaseUri: 'https://example.org',
        vocabPath: '/custom',
      );
      final iriStrategy = IriStrategy('https://example.org/items/{id}');

      final annotation = RdfGlobalResource.define(vocab, iriStrategy);

      expect(annotation.vocab, equals(vocab));
      expect(annotation.vocab!.vocabPath, equals('/custom'));
    });

    test('standard constructor has null vocab and subClassOf', () {
      final classIri = const IriTerm('http://example.org/classIri');
      final iriStrategy = IriStrategy('http://example.org/resource/{id}');

      final annotation = RdfGlobalResource(classIri, iriStrategy);

      expect(annotation.vocab, isNull);
      expect(annotation.subClassOf, isNull);
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
