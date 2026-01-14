import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/rdf_property_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/resource_processor.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';
import 'package:test/test.dart';

import '../fixtures/locorda_rdf_mapper_annotations/examples/collection_examples.dart'
    as ce;
import '../test_helper.dart';

void main() {
  group('CollectionExamplesProcessor', () {
    late LibraryElem libraryElement;

    setUpAll(() async {
      (libraryElement, _) = await analyzeTestFile(
          'locorda_rdf_mapper_annotations/examples/collection_examples.dart');
    });

    /// Helper method to process a field and validate the property
    RdfPropertyInfo? processField(FieldElem field) {
      final validationContext = ValidationContext();
      final result = PropertyProcessor.processField(validationContext, field);
      validationContext.throwIfErrors();
      return result;
    }

    test('should process Library global resource', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass('Library')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'ce.Library');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(ce.CollectionVocab.Library));
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.template, equals('{+baseUri}/library/{id}'));

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(3));

      // Verify field names
      final fieldNames = result.properties.map((f) => f.name).toList();
      expect(fieldNames, containsAll(['id', 'books', 'collaborators']));
    });

    test('should process Library books field with default collection mapping',
        () {
      // Arrange
      final field = libraryElement.getClass('Library')!.getField('books');
      expect(field, isNotNull, reason: 'Field "books" not found in Library');

      // Act
      final result = processField(field!);

      // Assert - Basic field info
      expect(result, isNotNull);
      expect(result!.name, equals('books'));
      expect(
          result.annotation.predicate.value, equals(ce.CollectionVocab.books));

      // Assert - Collection mapping info
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection!.isAuto, isTrue);
      expect(result.annotation.collection!.factory, isNull,
          reason: 'Default collections should not have explicit factory');
      expect(result.annotation.collection!.mapper, isNull,
          reason: 'Default collection should use auto-detected mapper');

      // Assert - Collection type analysis
      expect(result.collectionInfo, isNotNull);
      expect(result.collectionInfo.isCoreList, isTrue);
      expect(result.collectionInfo.isCoreMap, isFalse);
      expect(result.collectionInfo.isCoreSet, isFalse);
      expect(result.collectionInfo.isCoreCollection, isTrue);
      expect(result.collectionInfo.type, equals(CollectionType.list));
      expect(result.collectionInfo.elementTypeCode?.code, equals('ce.Book'));
    });

    test(
        'should process Library collaborators field with default collection mapping',
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
          equals(ce.CollectionVocab.collaborators));

      // Assert - Collection mapping info
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection!.isAuto, isTrue);
      expect(result.annotation.collection!.factory, isNull,
          reason: 'Default collections should not have explicit factory');
      expect(result.annotation.collection!.mapper, isNull,
          reason: 'Default collection should use auto-detected mapper');

      // Assert - Collection type analysis (Iterable instead of List)
      expect(result.collectionInfo, isNotNull);
      expect(result.collectionInfo.isCoreList, isFalse);
      expect(result.collectionInfo.isCoreMap, isFalse);
      expect(result.collectionInfo.isCoreSet, isFalse);
      expect(result.collectionInfo.isCoreCollection, isTrue);
      expect(result.collectionInfo.type, equals(CollectionType.iterable));
      expect(result.collectionInfo.elementTypeCode?.code, equals('String'));
    });

    test('should process Playlist global resource with RDF List', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass('Playlist')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'ce.Playlist');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(ce.CollectionVocab.Playlist));
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.template, equals('{+baseUri}/playlist/{id}'));

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(2));

      // Verify field names
      final fieldNames = result.properties.map((f) => f.name).toList();
      expect(fieldNames, containsAll(['id', 'orderedTracks']));
    });

    test(
        'should process Playlist orderedTracks field with RDF List collection mapping',
        () {
      // Arrange
      final field =
          libraryElement.getClass('Playlist')!.getField('orderedTracks');
      expect(field, isNotNull,
          reason: 'Field "orderedTracks" not found in Playlist');

      // Act
      final result = processField(field!);

      // Assert - Basic field info
      expect(result, isNotNull);
      expect(result!.name, equals('orderedTracks'));
      expect(result.annotation.predicate.value,
          equals(ce.CollectionVocab.orderedTracks));

      // Assert - Collection mapping info (RDF List)
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection!.isAuto, isFalse);
      expect(result.annotation.collection!.factory, isNotNull,
          reason: 'RDF List should have explicit factory');
      expect(result.annotation.collection!.factory?.codeWithoutAlias,
          equals('RdfListMapper'),
          reason: 'Should use rdfList factory');
      expect(result.annotation.collection!.mapper, isNull,
          reason: 'Factory-based collections should not have separate mapper');

      // Assert - Collection type analysis
      expect(result.collectionInfo, isNotNull);
      expect(result.collectionInfo.isCoreList, isTrue);
      expect(result.collectionInfo.isCoreMap, isFalse);
      expect(result.collectionInfo.isCoreSet, isFalse);
      expect(result.collectionInfo.isCoreCollection, isTrue);
      expect(result.collectionInfo.type, equals(CollectionType.list));
      expect(result.collectionInfo.elementTypeCode?.code, equals('ce.Track'));
    });

    test('should process Course global resource with multiple collection types',
        () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass('Course')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'ce.Course');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(ce.CollectionVocab.Course));
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.template, equals('{+baseUri}/course/{id}'));

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(4));

      // Verify field names
      final fieldNames = result.properties.map((f) => f.name).toList();
      expect(fieldNames,
          containsAll(['id', 'modules', 'prerequisites', 'alternatives']));
    });

    test('should process Course modules field with RDF Seq collection mapping',
        () {
      // Arrange
      final field = libraryElement.getClass('Course')!.getField('modules');
      expect(field, isNotNull, reason: 'Field "modules" not found in Course');

      // Act
      final result = processField(field!);

      // Assert - Basic field info
      expect(result, isNotNull);
      expect(result!.name, equals('modules'));
      expect(result.annotation.predicate.value,
          equals(ce.CollectionVocab.modules));

      // Assert - Collection mapping info (RDF Seq)
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection!.isAuto, isFalse);
      expect(result.annotation.collection!.factory, isNotNull,
          reason: 'RDF Seq should have explicit factory');
      expect(result.annotation.collection!.factory!.codeWithoutAlias,
          equals('RdfSeqMapper'),
          reason: 'Should use rdfSeq factory');
      expect(result.annotation.collection!.mapper, isNull,
          reason: 'Factory-based collections should not have separate mapper');

      // Assert - Collection type analysis
      expect(result.collectionInfo, isNotNull);
      expect(result.collectionInfo.isCoreList, isTrue);
      expect(result.collectionInfo.type, equals(CollectionType.list));
      expect(result.collectionInfo.elementTypeCode?.code, equals('ce.Module'));
    });

    test(
        'should process Course prerequisites field with RDF Bag collection mapping',
        () {
      // Arrange
      final field =
          libraryElement.getClass('Course')!.getField('prerequisites');
      expect(field, isNotNull,
          reason: 'Field "prerequisites" not found in Course');

      // Act
      final result = processField(field!);

      // Assert - Basic field info
      expect(result, isNotNull);
      expect(result!.name, equals('prerequisites'));
      expect(result.annotation.predicate.value,
          equals(ce.CollectionVocab.prerequisites));

      // Assert - Collection mapping info (RDF Bag)
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection!.isAuto, isFalse);
      expect(result.annotation.collection!.factory, isNotNull,
          reason: 'RDF Bag should have explicit factory');
      expect(result.annotation.collection!.factory!.codeWithoutAlias,
          equals('RdfBagMapper'),
          reason: 'Should use rdfBag factory');
      expect(result.annotation.collection!.mapper, isNull,
          reason: 'Factory-based collections should not have separate mapper');

      // Assert - Collection type analysis
      expect(result.collectionInfo, isNotNull);
      expect(result.collectionInfo.isCoreList, isTrue);
      expect(result.collectionInfo.type, equals(CollectionType.list));
      expect(result.collectionInfo.elementTypeCode?.code, equals('String'));
    });

    test(
        'should process Course alternatives field with RDF Alt collection mapping',
        () {
      // Arrange
      final field = libraryElement.getClass('Course')!.getField('alternatives');
      expect(field, isNotNull,
          reason: 'Field "alternatives" not found in Course');

      // Act
      final result = processField(field!);

      // Assert - Basic field info
      expect(result, isNotNull);
      expect(result!.name, equals('alternatives'));
      expect(result.annotation.predicate.value,
          equals(ce.CollectionVocab.alternatives));

      // Assert - Collection mapping info (RDF Alt)
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection!.isAuto, isFalse);
      expect(result.annotation.collection!.factory, isNotNull,
          reason: 'RDF Alt should have explicit factory');
      expect(result.annotation.collection!.factory!.codeWithoutAlias,
          equals('RdfAltMapper'),
          reason: 'Should use rdfAlt factory');
      expect(result.annotation.collection!.mapper, isNull,
          reason: 'Factory-based collections should not have separate mapper');

      // Assert - Collection type analysis
      expect(result.collectionInfo, isNotNull);
      expect(result.collectionInfo.isCoreList, isTrue);
      expect(result.collectionInfo.type, equals(CollectionType.list));
      expect(result.collectionInfo.elementTypeCode?.code, equals('String'));
    });

    test('should process BookCollection local resource', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass('BookCollection')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'ce.BookCollection');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri, isNull); // No explicit class IRI
      expect(annotation.registerGlobally, isTrue); // Default behavior

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(3));

      // Verify field names
      final fieldNames = result.properties.map((f) => f.name).toList();
      expect(fieldNames,
          containsAll(['authorIds', 'keywords', 'publicationDates']));
    });

    test('should process BookCollection authorIds field with IRI item mapping',
        () {
      // Arrange
      final field =
          libraryElement.getClass('BookCollection')!.getField('authorIds');
      expect(field, isNotNull,
          reason: 'Field "authorIds" not found in BookCollection');

      // Act
      final result = processField(field!);

      // Assert - Basic field info
      expect(result, isNotNull);
      expect(result!.name, equals('authorIds'));
      expect(result.annotation.predicate.value, equals(SchemaBook.author));

      // Assert - Default collection with IRI item mapping
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection!.isAuto, isTrue);
      expect(result.annotation.collection!.factory, isNull,
          reason: 'Default collections should not have explicit factory');

      // Assert - IRI mapping for collection items
      expect(result.annotation.iri, isNotNull,
          reason: 'authorIds should have IRI mapping for items');
      expect(result.annotation.iri!.template?.template,
          equals('{+baseUri}/author/{authorIds}'));

      // Assert - Collection type analysis
      expect(result.collectionInfo, isNotNull);
      expect(result.collectionInfo.isCoreList, isTrue);
      expect(result.collectionInfo.type, equals(CollectionType.list));
      expect(result.collectionInfo.elementTypeCode?.code, equals('String'));
    });

    test(
        'should process BookCollection keywords field with literal item mapping',
        () {
      // Arrange
      final field =
          libraryElement.getClass('BookCollection')!.getField('keywords');
      expect(field, isNotNull,
          reason: 'Field "keywords" not found in BookCollection');

      // Act
      final result = processField(field!);

      // Assert - Basic field info
      expect(result, isNotNull);
      expect(result!.name, equals('keywords'));
      expect(result.annotation.predicate.value.value,
          contains('schema.org/keywords'));

      // Assert - Default collection with literal item mapping
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection!.isAuto, isTrue);
      expect(result.annotation.collection!.factory, isNull,
          reason: 'Default collections should not have explicit factory');

      // Assert - Literal mapping for collection items
      expect(result.annotation.literal, isNotNull,
          reason: 'keywords should have literal mapping for items');
      expect(result.annotation.literal!.datatype, isNull);
      expect(result.annotation.literal!.language, equals('en'));

      // Assert - Collection type analysis
      expect(result.collectionInfo, isNotNull);
      expect(result.collectionInfo.isCoreList, isTrue);
      expect(result.collectionInfo.type, equals(CollectionType.list));
      expect(result.collectionInfo.elementTypeCode?.code, equals('String'));
    });

    test(
        'should process BookCollection publicationDates field with RDF List and literal item mapping',
        () {
      // Arrange
      final field = libraryElement
          .getClass('BookCollection')!
          .getField('publicationDates');
      expect(field, isNotNull,
          reason: 'Field "publicationDates" not found in BookCollection');

      // Act
      final result = processField(field!);

      // Assert - Basic field info
      expect(result, isNotNull);
      expect(result!.name, equals('publicationDates'));
      expect(result.annotation.predicate.value.value,
          contains('schema.org/datePublished'));

      // Assert - RDF List collection with literal item mapping
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection!.isAuto, isFalse);
      expect(result.annotation.collection!.factory, isNotNull,
          reason: 'RDF List should have explicit factory');
      expect(result.annotation.collection!.factory!.codeWithoutAlias,
          equals('RdfListMapper'),
          reason: 'Should use rdfList factory');

      // Assert - Literal mapping for collection items (xsd:date)
      expect(result.annotation.literal, isNotNull,
          reason: 'publicationDates should have literal mapping for items');
      expect(result.annotation.literal!.datatype, isNotNull);
      expect(result.annotation.literal!.datatype!.value, equals(Xsd.date));
      expect(result.annotation.literal!.language, isNull);

      // Assert - Collection type analysis
      expect(result.collectionInfo, isNotNull);
      expect(result.collectionInfo.isCoreList, isTrue);
      expect(result.collectionInfo.type, equals(CollectionType.list));
      expect(result.collectionInfo.elementTypeCode?.code, equals('DateTime'));
    });

    test('should process Book local resource', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass('Book')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'ce.Book');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri, isNull);
      expect(annotation.registerGlobally, isTrue);

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(2));

      // Verify field names
      final fieldNames = result.properties.map((f) => f.name).toList();
      expect(fieldNames, containsAll(['title', 'author']));
    });

    test('should process Track local resource', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass('Track')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'ce.Track');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri, isNull);
      expect(annotation.registerGlobally, isTrue);

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(2));

      // Verify field names
      final fieldNames = result.properties.map((f) => f.name).toList();
      expect(fieldNames, containsAll(['title', 'duration']));
    });

    test('should process Module local resource', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass('Module')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'ce.Module');
      var annotation = result.annotation as RdfLocalResourceInfo;
      expect(annotation.classIri, isNull);
      expect(annotation.registerGlobally, isTrue);

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(2));

      // Verify field names
      final fieldNames = result.properties.map((f) => f.name).toList();
      expect(fieldNames, containsAll(['name', 'position']));
    });
  });
}
