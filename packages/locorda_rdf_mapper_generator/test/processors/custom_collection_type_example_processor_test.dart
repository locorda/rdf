import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/rdf_property_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/resource_processor.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

import '../fixtures/locorda_rdf_mapper_annotations/examples/custom_collection_type_example.dart'
    as ccte;
import '../test_helper.dart';

void main() {
  group('CustomCollectionTypeExampleProcessor', () {
    late LibraryElem libraryElement;

    setUpAll(() async {
      (libraryElement, _) = await analyzeTestFile(
          'locorda_rdf_mapper_annotations/examples/custom_collection_type_example.dart');
    });

    /// Helper method to process a field and validate the property
    RdfPropertyInfo? processField(FieldElem field) {
      final validationContext = ValidationContext();
      final result = PropertyProcessor.processField(validationContext, field);
      validationContext.throwIfErrors();
      return result;
    }

    test(
        'should process Library global resource with custom collection mappers',
        () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass('Library')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'ccte.Library');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(ccte.CollectionVocab.Library));
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.template, equals('{+baseUri}/library/{id}'));

      expect(result.constructors, hasLength(1));
      expect(
          result.properties, hasLength(4)); // id, collaborators, tags, members

      // Verify field names
      final fieldNames = result.properties.map((f) => f.name).toList();
      expect(
          fieldNames, containsAll(['id', 'collaborators', 'tags', 'members']));
    });

    test(
        'should process Library collaborators field with custom RDF List collection mapping',
        () {
      // Arrange
      final field =
          libraryElement.getClass('Library')!.getField('collaborators');
      expect(field, isNotNull,
          reason: 'Field "collaborators" not found in Library');

      // Act
      final result = processField(field!);

      // Assert - Basic field info
      expect(result, isNotNull);
      expect(result!.name, equals('collaborators'));
      expect(result.annotation.predicate.value,
          equals(ccte.CollectionVocab.collaborators));

      // Assert - Custom collection mapping info with explicit factory (not mapper!)
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection!.isAuto, isFalse);
      expect(result.annotation.collection!.factory, isNotNull,
          reason: 'CollectionMapping.withItemMappers() sets factory');
      expect(result.annotation.collection!.factory!.codeWithoutAlias,
          equals('ImmutableListMapperRdfList'));
      expect(result.annotation.collection!.mapper, isNull,
          reason: 'Factory-based collections should not have separate mapper');

      // Assert - Collection type analysis (ImmutableList is a custom type, not standard Dart collection)
      expect(result.collectionInfo, isNotNull);
      // ImmutableList is not a standard Dart collection, so analyzer may not recognize it as such
      // The important part is that it has collection mapping configured
      expect(result.collectionInfo.elementTypeCode?.code, equals('String'));
    });

    test(
        'should process Library tags field with custom RDF Seq collection mapping',
        () {
      // Arrange
      final field = libraryElement.getClass('Library')!.getField('tags');
      expect(field, isNotNull, reason: 'Field "tags" not found in Library');

      // Act
      final result = processField(field!);

      // Assert - Basic field info
      expect(result, isNotNull);
      expect(result!.name, equals('tags'));
      expect(
          result.annotation.predicate.value, equals(ccte.CollectionVocab.tags));

      // Assert - Custom collection mapping info with explicit factory (RDF Seq)
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection!.isAuto, isFalse);
      expect(result.annotation.collection!.factory, isNotNull,
          reason: 'CollectionMapping.withItemMappers() sets factory');
      expect(result.annotation.collection!.factory!.codeWithoutAlias,
          equals('ImmutableListMapperRdfSeq'));
      expect(result.annotation.collection!.mapper, isNull,
          reason: 'Factory-based collections should not have separate mapper');

      // Assert - Collection type analysis
      expect(result.collectionInfo, isNotNull);
      expect(result.collectionInfo.isCoreList, isFalse);
      expect(result.collectionInfo.isCoreCollection, isFalse,
          reason: 'ImmutableList is not a dart collection');
      expect(result.collectionInfo.type, isNull);
      expect(result.collectionInfo.elementTypeCode?.code, equals('String'));
    });

    test(
        'should process Library members field with custom unordered collection mapping',
        () {
      // Arrange
      final field = libraryElement.getClass('Library')!.getField('members');
      expect(field, isNotNull, reason: 'Field "members" not found in Library');

      // Act
      final result = processField(field!);

      // Assert - Basic field info
      expect(result, isNotNull);
      expect(result!.name, equals('members'));
      expect(result.annotation.predicate.value,
          equals(ccte.CollectionVocab.members));

      // Assert - Custom collection mapping info with explicit factory (Unordered)
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection!.isAuto, isFalse);
      expect(result.annotation.collection!.factory, isNotNull,
          reason: 'CollectionMapping.withItemMappers() sets factory');
      expect(result.annotation.collection!.factory!.codeWithoutAlias,
          equals('ImmutableListMapperUnorderedItems'));
      expect(result.annotation.collection!.mapper, isNull,
          reason: 'Factory-based collections should not have separate mapper');

      // Assert - Collection type analysis
      expect(result.collectionInfo, isNotNull);
      expect(result.collectionInfo.isCoreList, isFalse);
      expect(result.collectionInfo.isCoreCollection, isFalse,
          reason: 'ImmutableList is not a dart collection');
      expect(result.collectionInfo.type, isNull);
      expect(result.collectionInfo.elementTypeCode?.code, equals('String'));
    });

    test('should not process ImmutableList as RDF resource', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass('ImmutableList')!);

      // Assert - ImmutableList is not annotated as RDF resource, so should return null
      expect(result, isNull,
          reason:
              'ImmutableList is a custom collection type, not an RDF resource');
      // No validation errors expected since it's simply not an RDF resource
    });

    test(
        'should validate collection mapping transformation for different strategies',
        () {
      // Test that different collection mapping strategies are correctly processed

      // Test RDF List mapping (collaborators)
      final collaboratorsField =
          libraryElement.getClass('Library')!.getField('collaborators');
      final collaboratorsResult = processField(collaboratorsField!);
      expect(
          collaboratorsResult!.annotation.collection!.factory!.codeWithoutAlias,
          equals('ImmutableListMapperRdfList'));

      // Test RDF Seq mapping (tags)
      final tagsField = libraryElement.getClass('Library')!.getField('tags');
      final tagsResult = processField(tagsField!);
      expect(tagsResult!.annotation.collection!.factory!.codeWithoutAlias,
          equals('ImmutableListMapperRdfSeq'));

      // Test Unordered mapping (members)
      final membersField =
          libraryElement.getClass('Library')!.getField('members');
      final membersResult = processField(membersField!);
      expect(membersResult!.annotation.collection!.factory!.codeWithoutAlias,
          equals('ImmutableListMapperUnorderedItems'));

      // All should use the same custom collection type but different mappers
      expect(collaboratorsResult.collectionInfo.type,
          equals(tagsResult.collectionInfo.type));
      expect(tagsResult.collectionInfo.type,
          equals(membersResult.collectionInfo.type));
      expect(collaboratorsResult.collectionInfo.elementTypeCode?.code,
          contains('String'));
      expect(
          tagsResult.collectionInfo.elementTypeCode?.code, contains('String'));
      expect(membersResult.collectionInfo.elementTypeCode?.code,
          contains('String'));
    });

    test('should validate that custom collection mappers preserve item mappers',
        () {
      // Verify that the CollectionMapping.withItemMappers() pattern is correctly processed

      // All three fields should have the same basic structure but different collection strategies
      final fields = ['collaborators', 'tags', 'members'];
      final expectedMappers = [
        'ImmutableListMapperRdfList',
        'ImmutableListMapperRdfSeq',
        'ImmutableListMapperUnorderedItems'
      ];

      for (int i = 0; i < fields.length; i++) {
        final field = libraryElement.getClass('Library')!.getField(fields[i]);
        final result = processField(field!);

        // Should have collection mapping but no item-specific mappings (pure collection strategy)
        expect(result!.annotation.collection, isNotNull);
        expect(result.annotation.collection!.factory!.codeWithoutAlias,
            equals(expectedMappers[i]));

        // Should not have conflicting item mappings
        expect(result.annotation.iri, isNull,
            reason: 'Custom collection mappers handle items internally');
        expect(result.annotation.literal, isNull,
            reason: 'Custom collection mappers handle items internally');
        expect(result.annotation.localResource, isNull,
            reason: 'Custom collection mappers handle items internally');
        expect(result.annotation.globalResource, isNull,
            reason: 'Custom collection mappers handle items internally');
        expect(result.annotation.contextual, isNull,
            reason: 'Custom collection mappers handle items internally');
      }
    });
  });
}
