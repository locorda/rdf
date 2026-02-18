import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:test/test.dart';

class MockGlobalResourceMapping implements GlobalResourceMapping {
  const MockGlobalResourceMapping();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockLocalResourceMapping implements LocalResourceMapping {
  const MockLocalResourceMapping();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockIriMapping implements IriMapping {
  const MockIriMapping();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockLiteralMapping implements LiteralMapping {
  const MockLiteralMapping();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  group('RdfProperty', () {
    test('basic constructor with predicate', () {
      final predicate = const IriTerm('http://example.org/predicate');
      final annotation = RdfProperty(predicate);

      expect(annotation.predicate, equals(predicate));
      expect(annotation.include, isTrue);
      expect(annotation.globalResource, isNull);
      expect(annotation.localResource, isNull);
      expect(annotation.iri, isNull);
      expect(annotation.literal, isNull);
    });

    test('constructor with all parameters', () {
      final predicate = const IriTerm('http://example.org/predicate');
      const mockGlobalResource = MockGlobalResourceMapping();
      const mockLocalResource = MockLocalResourceMapping();
      const mockIri = MockIriMapping();
      const mockLiteral = MockLiteralMapping();

      final annotation = RdfProperty(
        predicate,
        include: false,
        globalResource: mockGlobalResource,
        localResource: mockLocalResource,
        iri: mockIri,
        literal: mockLiteral,
      );

      expect(annotation.predicate, equals(predicate));

      expect(annotation.include, isFalse);
      expect(annotation.globalResource, equals(mockGlobalResource));
      expect(annotation.localResource, equals(mockLocalResource));
      expect(annotation.iri, equals(mockIri));
      expect(annotation.literal, equals(mockLiteral));
    });

    test('constructor with contextual parameter', () {
      final predicate = const IriTerm('http://example.org/predicate');
      final contextual = ContextualMapping.namedProvider('example');

      final annotation = RdfProperty(
        predicate,
        contextual: contextual,
      );

      expect(annotation.predicate, equals(predicate));
      expect(annotation.contextual, equals(contextual));
      expect(annotation.contextual?.mapper?.name, equals('example'));
      expect(annotation.include, isTrue);
      expect(annotation.globalResource, isNull);
      expect(annotation.localResource, isNull);
      expect(annotation.iri, isNull);
      expect(annotation.literal, isNull);
    });

    test('basic constructor has null contextual by default', () {
      final predicate = const IriTerm('http://example.org/predicate');
      final annotation = RdfProperty(predicate);

      expect(annotation.contextual, isNull);
    });

    test('basic constructor has null fragment', () {
      final predicate = const IriTerm('http://example.org/predicate');
      final annotation = RdfProperty(predicate);

      expect(annotation.fragment, isNull);
      expect(annotation.noDomain, isFalse);
    });

    test('define constructor without fragment', () {
      final annotation = RdfProperty.define();

      expect(annotation.predicate, isNull);
      expect(annotation.fragment, isNull);
      expect(annotation.include, isTrue);
      expect(annotation.globalResource, isNull);
      expect(annotation.localResource, isNull);
      expect(annotation.iri, isNull);
      expect(annotation.literal, isNull);
    });

    test('define constructor with fragment', () {
      final annotation = RdfProperty.define(fragment: 'customFragment');

      expect(annotation.predicate, isNull);
      expect(annotation.fragment, equals('customFragment'));
      expect(annotation.include, isTrue);
    });

    test('define constructor with include false', () {
      final annotation = RdfProperty.define(
        fragment: 'internal',
        include: false,
      );

      expect(annotation.predicate, isNull);
      expect(annotation.fragment, equals('internal'));
      expect(annotation.include, isFalse);
    });

    test('define constructor supports noDomain', () {
      final annotation = RdfProperty.define(
        fragment: 'identifier',
        noDomain: true,
      );

      expect(annotation.predicate, isNull);
      expect(annotation.fragment, equals('identifier'));
      expect(annotation.noDomain, isTrue);
    });

    test('define constructor with all named parameters', () {
      const mockGlobalResource = MockGlobalResourceMapping();
      const mockLocalResource = MockLocalResourceMapping();
      const mockIri = MockIriMapping();
      const mockLiteral = MockLiteralMapping();

      final annotation = RdfProperty.define(
        fragment: 'test',
        include: false,
        defaultValue: 'default',
        includeDefaultsInSerialization: true,
        globalResource: mockGlobalResource,
        localResource: mockLocalResource,
        iri: mockIri,
        literal: mockLiteral,
      );

      expect(annotation.predicate, isNull);
      expect(annotation.fragment, equals('test'));
      expect(annotation.include, isFalse);
      expect(annotation.defaultValue, equals('default'));
      expect(annotation.includeDefaultsInSerialization, isTrue);
      expect(annotation.globalResource, equals(mockGlobalResource));
      expect(annotation.localResource, equals(mockLocalResource));
      expect(annotation.iri, equals(mockIri));
      expect(annotation.literal, equals(mockLiteral));
    });

    test('define constructor with contextual parameter', () {
      final contextual = ContextualMapping.namedProvider('example');

      final annotation = RdfProperty.define(
        fragment: 'contextualProp',
        contextual: contextual,
      );

      expect(annotation.predicate, isNull);
      expect(annotation.fragment, equals('contextualProp'));
      expect(annotation.contextual, equals(contextual));
      expect(annotation.contextual?.mapper?.name, equals('example'));
    });

    test('define constructor with metadata', () {
      final annotation = RdfProperty.define(
        fragment: 'title',
        metadata: [
          (
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#comment'),
            LiteralTerm('Title property')
          ),
          (
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#seeAlso'),
            const IriTerm('https://example.org/docs/title')
          ),
        ],
      );

      expect(annotation.metadata, isNotNull);
      expect(annotation.metadata!.length, equals(2));
    });

    test('define constructor with label and comment', () {
      final annotation = RdfProperty.define(
        fragment: 'title',
        label: 'Title',
        comment: 'The title of the resource',
      );

      expect(annotation.label, equals('Title'));
      expect(annotation.comment, equals('The title of the resource'));
    });
  });
}
