import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:locorda_rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:test/test.dart';

// Import test models
import '../../fixtures/locorda_rdf_mapper_annotations/examples/provides.dart';
// Import generated mappers
import '../../fixtures/locorda_rdf_mapper_annotations/examples/provides.locorda_rdf_mapper.g.dart';
import '../init_test_rdf_mapper_util.dart';

void main() {
  late RdfMapper mapper;

  /// Helper to create serialization context
  SerializationContext createSerializationContext() {
    return SerializationContextImpl(registry: mapper.registry);
  }

  /// Helper to create deserialization context
  DeserializationContext createDeserializationContext() {
    final graph = RdfGraph.fromTriples([]);
    return DeserializationContextImpl(graph: graph, registry: mapper.registry);
  }

  setUp(() {
    mapper = defaultInitTestRdfMapper();
  });

  group('Provides Example Test', () {
    group('ParentSiblingIdMapper (IRI with context variables)', () {
      test('serializes sibling ID to hierarchical IRI', () {
        final mapper = ParentSiblingIdMapper(
          baseUriProvider: () => 'http://example.org/vocab',
          parentIdProvider: () => 'parent123',
        );
        final context = createSerializationContext();

        final iriTerm = mapper.toRdfTerm('sibling456', context);

        expect(
          iriTerm.value,
          equals('http://example.org/vocab/parent123/sibling/sibling456.ttl'),
        );
      });

      test('deserializes sibling ID from hierarchical IRI', () {
        final mapper = ParentSiblingIdMapper(
          baseUriProvider: () => 'http://example.org/vocab',
          parentIdProvider: () => 'parent123', // Not used in deserialization
        );
        final context = createDeserializationContext();

        final siblingId = mapper.fromRdfTerm(
          const IriTerm(
              'http://example.org/vocab/parent789/sibling/siblingABC.ttl'),
          context,
        );

        expect(siblingId, equals('siblingABC'));
      });

      test('handles different base URIs', () {
        final mappers = [
          ParentSiblingIdMapper(
            baseUriProvider: () => 'https://api.example.com/v1',
            parentIdProvider: () => 'parent1',
          ),
          ParentSiblingIdMapper(
            baseUriProvider: () => 'http://localhost:8080/data',
            parentIdProvider: () => 'parent2',
          ),
          ParentSiblingIdMapper(
            baseUriProvider: () => 'urn:example:namespace',
            parentIdProvider: () => 'parent3',
          ),
        ];

        final context = createSerializationContext();

        final expectedIris = [
          'https://api.example.com/v1/parent1/sibling/test.ttl',
          'http://localhost:8080/data/parent2/sibling/test.ttl',
          'urn:example:namespace/parent3/sibling/test.ttl',
        ];

        for (int i = 0; i < mappers.length; i++) {
          final iriTerm = mappers[i].toRdfTerm('test', context);
          expect(iriTerm.value, equals(expectedIris[i]));
        }
      });

      test('handles special characters in IDs', () {
        final mapper = ParentSiblingIdMapper(
          baseUriProvider: () => 'http://example.org',
          parentIdProvider: () => 'parent-with-hyphens',
        );
        final context = createSerializationContext();

        final iriTerm = mapper.toRdfTerm('sibling_with_underscores', context);
        expect(
          iriTerm.value,
          equals(
              'http://example.org/parent-with-hyphens/sibling/sibling_with_underscores.ttl'),
        );

        final deserContext = createDeserializationContext();
        final siblingId = mapper.fromRdfTerm(iriTerm, deserContext);
        expect(siblingId, equals('sibling_with_underscores'));
      });

      test('round-trip serialization maintains sibling ID', () {
        final mapper = ParentSiblingIdMapper(
          baseUriProvider: () => 'http://test.org',
          parentIdProvider: () => 'parent123',
        );
        final serContext = createSerializationContext();
        final deserContext = createDeserializationContext();

        final testIds = [
          'sibling1',
          'complex-sibling-id-123',
          'sibling_with_underscores',
          'sibling.with.dots',
          'unicode日本語',
        ];

        for (final originalId in testIds) {
          final iriTerm = mapper.toRdfTerm(originalId, serContext);
          final deserializedId = mapper.fromRdfTerm(iriTerm, deserContext);
          expect(deserializedId, equals(originalId));
        }
      });
    });

    group('ChildMapper (hierarchical resource with context)', () {
      test('serializes child with hierarchical IRI', () {
        final mapper = ChildMapper(
          baseUriProvider: () => 'http://example.org/vocab',
          parentIdProvider: () => 'parent123',
        );
        final context = createSerializationContext();

        final child = Child()
          ..id = 'child456'
          ..name = 'Test Child';

        final (subject, triples) = mapper.toRdfResource(child, context);

        expect(
          subject.value,
          equals('http://example.org/vocab/parent123/child/child456.ttl'),
        );

        expect(triples.length, equals(1));
        final nameTriple = triples.first;
        expect(nameTriple.predicate, equals(ExampleVocab.childName));
        expect((nameTriple.object as LiteralTerm).value, equals('Test Child'));
      });

      test('deserializes child from hierarchical IRI', () {
        final triples = [
          Triple(
            const IriTerm(
                'http://example.org/vocab/parent789/child/childABC.ttl'),
            ExampleVocab.childName,
            LiteralTerm('Child Name'),
          ),
        ];

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        final childMapper = ChildMapper(
          baseUriProvider: () => 'http://example.org/vocab',
          parentIdProvider: () => 'parent789',
        );

        final child = childMapper.fromRdfResource(
          const IriTerm(
              'http://example.org/vocab/parent789/child/childABC.ttl'),
          context,
        );

        expect(child.id, equals('childABC'));
        expect(child.name, equals('Child Name'));
      });

      test('handles different parent-child relationships', () {
        final baseUri = 'http://example.org/test';
        final testCases = [
          ('parent1', 'child1', 'First Child'),
          ('parent2', 'child2', 'Second Child'),
          ('complex-parent-id', 'complex-child-id', 'Complex Child'),
        ];

        for (final (parentId, childId, childName) in testCases) {
          final mapper = ChildMapper(
            baseUriProvider: () => baseUri,
            parentIdProvider: () => parentId,
          );
          final context = createSerializationContext();

          final child = Child()
            ..id = childId
            ..name = childName;

          final (subject, triples) = mapper.toRdfResource(child, context);

          expect(
            subject.value,
            equals('$baseUri/$parentId/child/$childId.ttl'),
          );

          final nameTriple = triples.first;
          expect((nameTriple.object as LiteralTerm).value, equals(childName));
        }
      });

      test('round-trip serialization maintains child data', () {
        final childMapper = ChildMapper(
          baseUriProvider: () => 'http://test.org',
          parentIdProvider: () => 'testParent',
        );
        final serContext = createSerializationContext();

        final originalChild = Child()
          ..id = 'testChild'
          ..name = 'Test Child Name';

        final (subject, triples) =
            childMapper.toRdfResource(originalChild, serContext);

        final graph = RdfGraph.fromTriples(triples);
        final deserContext = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        final deserializedChild =
            childMapper.fromRdfResource(subject, deserContext);

        expect(deserializedChild.id, equals(originalChild.id));
        expect(deserializedChild.name, equals(originalChild.name));
      });
    });

    group('ParentMapper (with @RdfProvides)', () {
      test('serializes parent with child and sibling relationships', () {
        final mapper = ParentMapper(
          baseUriProvider: () => 'http://example.org/vocab',
        );
        final context = createSerializationContext();

        final child = Child()
          ..id = 'child123'
          ..name = 'Test Child';

        final parent = Parent()
          ..id = 'parent456'
          ..child = child
          ..siblingId = 'sibling789';

        final (subject, triples) = mapper.toRdfResource(parent, context);

        expect(
          subject.value,
          equals('http://example.org/vocab/parent456.ttl'),
        );

        expect(triples.length,
            greaterThanOrEqualTo(2)); // At least child and sibling

        // Check sibling IRI mapping
        final siblingTriple = triples.firstWhere(
          (t) => t.predicate == ExampleVocab.sibling,
        );
        expect(
          (siblingTriple.object as IriTerm).value,
          equals('http://example.org/vocab/parent456/sibling/sibling789.ttl'),
        );

        // Check child relationship
        final childTriple = triples.firstWhere(
          (t) => t.predicate == ExampleVocab.child,
        );
        expect(childTriple.object, isA<RdfSubject>()); // Child is a resource
      });

      test('deserializes parent with child and sibling relationships', () {
        final childBn = const IriTerm(
            'http://example.org/test/parentABC/child/child456.ttl');
        final triples = [
          // Parent properties
          Triple(
            const IriTerm('http://example.org/test/parentABC.ttl'),
            ExampleVocab.child,
            childBn,
          ),
          Triple(
            const IriTerm('http://example.org/test/parentABC.ttl'),
            ExampleVocab.sibling,
            const IriTerm(
                'http://example.org/test/parentABC/sibling/siblingXYZ.ttl'),
          ),
          // Child properties
          Triple(childBn, ExampleVocab.childName, LiteralTerm('Child Name')),
        ];

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        final parentMapper = ParentMapper(
          baseUriProvider: () => 'http://example.org/test',
        );

        final parent = parentMapper.fromRdfResource(
          const IriTerm('http://example.org/test/parentABC.ttl'),
          context,
        );

        expect(parent.id, equals('parentABC'));
        expect(parent.siblingId, equals('siblingXYZ'));
        expect(parent.child.name, equals('Child Name'));
      });

      test('handles complex hierarchical relationships', () {
        final mapper = ParentMapper(
          baseUriProvider: () => 'https://api.example.com/data',
        );
        final context = createSerializationContext();

        final child = Child()
          ..id = 'complex-child-id-123'
          ..name = 'Complex Child Name with Spaces';

        final parent = Parent()
          ..id = 'complex-parent-id-456'
          ..child = child
          ..siblingId = 'complex-sibling-id-789';

        final (subject, triples) = mapper.toRdfResource(parent, context);

        expect(
          subject.value,
          equals('https://api.example.com/data/complex-parent-id-456.ttl'),
        );

        final siblingTriple = triples.firstWhere(
          (t) => t.predicate == ExampleVocab.sibling,
        );
        expect(
          (siblingTriple.object as IriTerm).value,
          equals(
              'https://api.example.com/data/complex-parent-id-456/sibling/complex-sibling-id-789.ttl'),
        );
      });

      test('handles different base URI configurations', () {
        final baseUris = [
          'http://example.org/vocab',
          'https://api.mycompany.com/v1/data',
          'http://localhost:8080/test',
          'urn:example:namespace',
        ];

        for (final baseUri in baseUris) {
          final mapper = ParentMapper(
            baseUriProvider: () => baseUri,
          );
          final context = createSerializationContext();

          final child = Child()
            ..id = 'testChild'
            ..name = 'Test';

          final parent = Parent()
            ..id = 'testParent'
            ..child = child
            ..siblingId = 'testSibling';

          final (subject, triples) = mapper.toRdfResource(parent, context);

          expect(subject.value, equals('$baseUri/testParent.ttl'));

          final siblingTriple = triples.firstWhere(
            (t) => t.predicate == ExampleVocab.sibling,
          );
          expect(
            (siblingTriple.object as IriTerm).value,
            equals('$baseUri/testParent/sibling/testSibling.ttl'),
          );
        }
      });

      test('round-trip serialization maintains parent-child hierarchy', () {
        final parentMapper1 = ParentMapper(
          baseUriProvider: () => 'http://test.org/data',
        );
        final serContext = createSerializationContext();

        final originalChild = Child()
          ..id = 'originalChild'
          ..name = 'Original Child Name';

        final originalParent = Parent()
          ..id = 'originalParent'
          ..child = originalChild
          ..siblingId = 'originalSibling';

        final (subject, triples) =
            parentMapper1.toRdfResource(originalParent, serContext);

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        final parentMapper = ParentMapper(
          baseUriProvider: () => 'http://test.org/data',
        );
        final deserializedParent =
            parentMapper.fromRdfResource(subject, context);

        expect(deserializedParent.id, equals(originalParent.id));
        expect(deserializedParent.siblingId, equals(originalParent.siblingId));
        expect(deserializedParent.child.name, equals(originalChild.name));
      });
    });

    group('Integration and edge cases', () {
      test('handles empty and special character IDs', () {
        final mapper = ParentMapper(
          baseUriProvider: () => 'http://example.org',
        );
        final context = createSerializationContext();

        final testCases = [
          (
            'parent_with_underscores',
            'child_with_underscores',
            'sibling_with_underscores'
          ),
          ('parent-with-hyphens', 'child-with-hyphens', 'sibling-with-hyphens'),
          ('parent.with.dots', 'child.with.dots', 'sibling.with.dots'),
          ('parent123', 'child456', 'sibling789'),
        ];

        for (final (parentId, childId, siblingId) in testCases) {
          final child = Child()
            ..id = childId
            ..name = 'Test Child';

          final parent = Parent()
            ..id = parentId
            ..child = child
            ..siblingId = siblingId;

          final (subject, triples) = mapper.toRdfResource(parent, context);

          expect(subject.value, equals('http://example.org/$parentId.ttl'));

          final siblingTriple = triples.firstWhere(
            (t) => t.predicate == ExampleVocab.sibling,
          );
          expect(
            (siblingTriple.object as IriTerm).value,
            equals('http://example.org/$parentId/sibling/$siblingId.ttl'),
          );
        }
      });

      test('validates IRI template extraction', () {
        final mapper = ParentSiblingIdMapper(
          baseUriProvider: () => 'http://example.org',
          parentIdProvider: () => 'parent123',
        );
        final context = createDeserializationContext();

        // Valid IRI format
        final validId = mapper.fromRdfTerm(
          const IriTerm('http://example.org/parent456/sibling/sibling789.ttl'),
          context,
        );
        expect(validId, equals('sibling789'));

        // Test with different valid formats
        final validFormats = [
          ('http://api.example.com/parent1/sibling/sib1.ttl', 'sib1'),
          ('https://secure.example.org/parent2/sibling/sib2.ttl', 'sib2'),
          ('http://localhost:8080/parent3/sibling/sib3.ttl', 'sib3'),
        ];

        for (final (iri, expectedId) in validFormats) {
          final extractedId =
              mapper.fromRdfTerm(IriTerm.validated(iri), context);
          expect(extractedId, equals(expectedId));
        }
      });

      test('handles Unicode in IDs and names', () {
        final mapper = ParentMapper(
          baseUriProvider: () => 'http://example.org',
        );
        final context = createSerializationContext();

        final child = Child()
          ..id = 'child日本語'
          ..name = 'Child with 日本語 name';

        final parent = Parent()
          ..id = 'parent日本語'
          ..child = child
          ..siblingId = 'sibling日本語';

        final (subject, triples) = mapper.toRdfResource(parent, context);

        expect(subject.value, equals('http://example.org/parent日本語.ttl'));

        final siblingTriple = triples.firstWhere(
          (t) => t.predicate == ExampleVocab.sibling,
        );
        expect(
          (siblingTriple.object as IriTerm).value,
          equals('http://example.org/parent日本語/sibling/sibling日本語.ttl'),
        );
      });

      test('validates context variable usage', () {
        // Test that different context variables produce different results
        final baseUris = [
          'http://dev.example.org',
          'http://staging.example.org',
          'http://prod.example.org',
        ];

        for (final baseUri in baseUris) {
          final mapper = ParentSiblingIdMapper(
            baseUriProvider: () => baseUri,
            parentIdProvider: () => 'testParent',
          );
          final context = createSerializationContext();

          final iriTerm = mapper.toRdfTerm('testSibling', context);
          expect(iriTerm.value,
              equals('$baseUri/testParent/sibling/testSibling.ttl'));
        }
      });
    });
  });
}
