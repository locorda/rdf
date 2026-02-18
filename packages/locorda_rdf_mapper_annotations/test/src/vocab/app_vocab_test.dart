import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

/// Custom subclass of AppVocab to verify subclassability.
class CustomContracts extends AppVocab {
  const CustomContracts({
    required super.appBaseUri,
    super.vocabPath,
  });
}

void main() {
  group('AppVocab', () {
    test('constructor with required appBaseUri and default vocabPath', () {
      const vocab = AppVocab(
        appBaseUri: 'https://my.app.de',
      );

      expect(vocab.appBaseUri, equals('https://my.app.de'));
      expect(vocab.vocabPath, equals('/vocab'));
      expect(
        vocab.defaultBaseClass,
        equals(const IriTerm('http://www.w3.org/2002/07/owl#Thing')),
      );
      expect(vocab.wellKnownProperties, isNotEmpty);
      expect(vocab.wellKnownProperties['title'],
          equals(const IriTerm('http://purl.org/dc/terms/title')));
    });

    test('constructor with custom vocabPath', () {
      const vocab = AppVocab(
        appBaseUri: 'https://example.org',
        vocabPath: '/custom/vocab',
        defaultBaseClass:
            IriTerm('http://www.w3.org/2000/01/rdf-schema#Resource'),
        wellKnownProperties: {
          'name': IriTerm('http://xmlns.com/foaf/0.1/name'),
        },
      );

      expect(vocab.appBaseUri, equals('https://example.org'));
      expect(vocab.vocabPath, equals('/custom/vocab'));
      expect(
          vocab.defaultBaseClass,
          equals(
              const IriTerm('http://www.w3.org/2000/01/rdf-schema#Resource')));
      expect(vocab.wellKnownProperties.length, equals(1));
      expect(vocab.wellKnownProperties['name'],
          equals(const IriTerm('http://xmlns.com/foaf/0.1/name')));
    });

    test('constructor with empty vocabPath', () {
      const vocab = AppVocab(
        appBaseUri: 'https://example.org',
        vocabPath: '',
      );

      expect(vocab.appBaseUri, equals('https://example.org'));
      expect(vocab.vocabPath, equals(''));
    });

    test('is const constructor', () {
      const vocab1 = AppVocab(appBaseUri: 'https://my.app.de');
      const vocab2 = AppVocab(appBaseUri: 'https://my.app.de');

      // Verify that identical const instances are the same object
      expect(identical(vocab1, vocab2), isTrue);
    });

    test('can be subclassed', () {
      const customVocab = CustomContracts(
        appBaseUri: 'https://custom.app.de',
        vocabPath: '/contracts',
      );

      expect(customVocab, isA<AppVocab>());
      expect(customVocab.appBaseUri, equals('https://custom.app.de'));
      expect(customVocab.vocabPath, equals('/contracts'));
    });

    test('subclass with default vocabPath', () {
      const customVocab = CustomContracts(
        appBaseUri: 'https://custom.app.de',
      );

      expect(customVocab, isA<AppVocab>());
      expect(customVocab.appBaseUri, equals('https://custom.app.de'));
      expect(customVocab.vocabPath, equals('/vocab'));
    });

    test('fields are accessible directly', () {
      const vocab = AppVocab(
        appBaseUri: 'https://test.org',
        vocabPath: '/test',
      );

      // Verify fields can be accessed (no getters required)
      final String baseUri = vocab.appBaseUri;
      final String path = vocab.vocabPath;

      expect(baseUri, equals('https://test.org'));
      expect(path, equals('/test'));
    });

    test('supports metadata with IriTerm and LiteralTerm values', () {
      const creator = IriTerm('https://example.org/team');
      final vocab = AppVocab(
        appBaseUri: 'https://my.app.de',
        metadata: [
          (const IriTerm('http://purl.org/dc/terms/creator'), creator),
          (
            const IriTerm('http://www.w3.org/2002/07/owl#versionInfo'),
            LiteralTerm('1.0.0')
          ),
        ],
      );

      expect(vocab.metadata.length, equals(2));
      expect(
          vocab.metadata,
          contains((
            const IriTerm('http://purl.org/dc/terms/creator'),
            creator,
          )));
    });
  });
}
