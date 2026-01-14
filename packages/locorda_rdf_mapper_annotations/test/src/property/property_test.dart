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
  });
}
