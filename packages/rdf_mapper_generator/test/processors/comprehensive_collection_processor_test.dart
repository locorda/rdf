import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:rdf_mapper_generator/src/processors/models/rdf_property_info.dart';
import 'package:rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

/// Tests that verify the processor correctly handles all collection mapping scenarios.
void main() {
  group('Comprehensive Collection Mapping Processor Tests', () {
    late LibraryElem libraryElement;

    setUpAll(() async {
      (libraryElement, _) =
          await analyzeTestFile('comprehensive_collection_tests.dart');
    });

    /// Helper method to process a field and validate the property
    RdfPropertyInfo? processField(FieldElem field) {
      final validationContext = ValidationContext();
      final result = PropertyProcessor.processField(validationContext, field);
      validationContext.throwIfErrors();
      return result;
    }

    group('CollectionMapping.fromRegistry() Processing', () {
      test('should process fromRegistry collection mapping correctly', () {
        final classElem = libraryElement.getClass('RegistryCollectionTests')!;
        final field = classElem.getField('registryManagedCollection')!;

        final property = processField(field);
        expect(property, isNotNull);
        expect(property!.collectionInfo, isNotNull);
        expect(property.collectionInfo.type, equals(CollectionType.list));
        expect(property.collectionInfo.isCoreCollection, isTrue);
        expect(property.annotation.collection, isNotNull);
      });
    });

    group('CollectionMapping.namedMapper() Processing', () {
      test('should process namedMapper collection mapping correctly', () {
        final classElem =
            libraryElement.getClass('NamedMapperCollectionTests')!;
        final field = classElem.getField('namedManagedCollection')!;

        final property = processField(field);
        expect(property, isNotNull);
        expect(property!.collectionInfo, isNotNull);
        expect(property.collectionInfo.type, equals(CollectionType.list));
        expect(property.collectionInfo.isCoreCollection, isTrue);
        expect(property.annotation.collection, isNotNull);
      });
    });

    group('CollectionMapping.mapper() Processing', () {
      test('should process self-contained mapper correctly', () {
        final classElem = libraryElement.getClass('SelfContainedMapperTests')!;
        final field = classElem.getField('selfContainedCollection')!;

        final property = processField(field);
        expect(property, isNotNull);
        expect(property!.collectionInfo, isNotNull);
        expect(property.collectionInfo.type, equals(CollectionType.list));
        expect(property.collectionInfo.isCoreCollection, isTrue);
        expect(property.annotation.collection, isNotNull);
      });
    });

    group('CollectionMapping.withItemMappers() Processing', () {
      test('should process withItemMappers collection mapping correctly', () {
        final classElem = libraryElement.getClass('ItemTypeParameterTests')!;
        final field = classElem.getField('complexCollection')!;

        final property = processField(field);
        expect(property, isNotNull);

        // CustomCollection is not a core collection, so collectionInfo.type should be null
        expect(property!.collectionInfo, isNotNull);
        expect(property.collectionInfo.type, isNull);
        expect(property.collectionInfo.isCoreCollection, isFalse);
        expect(property.annotation.collection, isNotNull);
        // itemType should now be properly extracted from annotation
        expect(property.annotation.itemType, isNotNull);
        expect(
            property.annotation.itemType!.element.name, equals('ComplexItem'));
        expect(property.annotation.localResource, isNotNull);
      });
    });

    group('CollectionMapping.mapperInstance() Processing', () {
      test('should process mapperInstance collection mapping correctly', () {
        final classElem =
            libraryElement.getClass('InstanceManagedCollectionTests')!;
        final field = classElem.getField('instanceManagedCollection')!;

        final property = processField(field);
        expect(property, isNotNull);
        expect(property!.collectionInfo, isNotNull);
        expect(property.collectionInfo.type, equals(CollectionType.list));
        expect(property.collectionInfo.isCoreCollection, isTrue);
        expect(property.annotation.collection, isNotNull);
      });
    });

    group('Set<T> Collection Processing', () {
      test('should correctly identify Set collections', () {
        final classElem =
            libraryElement.getClass('SetAndIterableCollectionTests')!;

        // Test rdf:Bag with List (bags are conceptually sets)
        final bagCollectionField = classElem.getField('bagCollection')!;
        final bagProperty = processField(bagCollectionField);
        expect(bagProperty, isNotNull);
        expect(bagProperty!.collectionInfo, isNotNull);
        expect(bagProperty.collectionInfo.isCoreCollection, isTrue);
        expect(bagProperty.collectionInfo.type, equals(CollectionType.list));
        expect(bagProperty.collectionInfo.isCoreList, isTrue);

        // Test rdf:List with List (ordered)
        final orderedCollectionField = classElem.getField('orderedCollection')!;
        final listProperty = processField(orderedCollectionField);
        expect(listProperty, isNotNull);
        expect(listProperty!.collectionInfo, isNotNull);
        expect(listProperty.collectionInfo.isCoreCollection, isTrue);
        expect(listProperty.collectionInfo.type, equals(CollectionType.list));
        expect(listProperty.collectionInfo.isCoreList, isTrue);
      });
    });

    group('Iterable<T> Collection Processing', () {
      test('should correctly identify Iterable collections', () {
        final classElem =
            libraryElement.getClass('SetAndIterableCollectionTests')!;

        // Test default Iterable behavior
        final defaultIterableField = classElem.getField('defaultIterable')!;
        final defaultProperty = processField(defaultIterableField);
        expect(defaultProperty, isNotNull);
        expect(defaultProperty!.collectionInfo, isNotNull);
        expect(defaultProperty.collectionInfo.isCoreCollection, isTrue);
        expect(defaultProperty.collectionInfo.type,
            equals(CollectionType.iterable));

        // Test List with rdf:Seq (sequenceIterable is List<String>)
        final sequenceIterableField = classElem.getField('sequenceIterable')!;
        final seqProperty = processField(sequenceIterableField);
        expect(seqProperty, isNotNull);
        expect(seqProperty!.collectionInfo, isNotNull);
        expect(seqProperty.collectionInfo.isCoreCollection, isTrue);
        expect(seqProperty.collectionInfo.type, equals(CollectionType.list));
      });
    });

    group('itemType Parameter Processing', () {
      test('should process explicit itemType parameter correctly', () {
        final classElem = libraryElement.getClass('ItemTypeParameterTests')!;
        final field = classElem.getField('complexCollection')!;

        final property = processField(field);
        expect(property, isNotNull);
        // CustomCollection is not a core collection, so collectionInfo.type should be null
        expect(property!.collectionInfo, isNotNull);
        expect(property.collectionInfo.type, isNull);
        expect(property.collectionInfo.isCoreCollection, isFalse);
        expect(property.annotation.itemType, isNotNull);
        expect(
            property.annotation.itemType!.element.name, equals("ComplexItem"));
        expect(property.annotation.localResource, isNotNull); // Item mapping
      });
    });

    group('Combined Item Mapping Processing', () {
      test('should process collection with IRI item mapping', () {
        final classElem = libraryElement.getClass('CombinedItemMappingTests')!;
        final field = classElem.getField('iriItemsList')!;

        final property = processField(field);
        expect(property, isNotNull);
        expect(property!.collectionInfo, isNotNull);
        expect(property.collectionInfo.type, equals(CollectionType.list));
        expect(property.annotation.iri, isNotNull); // Item IRI mapping
        expect(property.annotation.iri!.template?.template,
            equals('{+baseUri}/item/{iriItemsList}'));
      });

      test('should process collection with literal item mapping', () {
        final classElem = libraryElement.getClass('CombinedItemMappingTests')!;
        final field = classElem.getField('languageTaggedBag')!;

        final property = processField(field);
        expect(property, isNotNull);
        expect(property!.collectionInfo, isNotNull);
        expect(property.collectionInfo.type, equals(CollectionType.list));
        expect(property.annotation.literal, isNotNull); // Item literal mapping
        expect(property.annotation.literal!.language, equals('en'));
      });
    });

    group('Edge Cases Processing', () {
      test('should process collections with default values', () {
        final classElem = libraryElement.getClass('DefaultSerializationTests')!;
        final field = classElem.getField('defaultHandledList')!;

        final property = processField(field);
        expect(property, isNotNull);
        expect(property!.collectionInfo, isNotNull);
        expect(property.collectionInfo.type, equals(CollectionType.list));
        expect(property.annotation.defaultValue, isNotNull);
        expect(property.annotation.includeDefaultsInSerialization, isTrue);
      });
    });

    group('Collection Type Detection', () {
      test('should correctly detect core vs custom collection types', () {
        // Test with SetAndIterableCollectionTests which has core collections
        final classElem =
            libraryElement.getClass('SetAndIterableCollectionTests')!;

        final bagCollectionField = classElem.getField('bagCollection')!;
        final bagCollectionProperty = processField(bagCollectionField);
        expect(bagCollectionProperty!.collectionInfo.isCoreCollection, isTrue);
        expect(bagCollectionProperty.collectionInfo.type,
            equals(CollectionType.list));

        final defaultIterableField = classElem.getField('defaultIterable')!;
        final iterableProperty = processField(defaultIterableField);
        expect(iterableProperty!.collectionInfo.isCoreCollection, isTrue);
        expect(iterableProperty.collectionInfo.type,
            equals(CollectionType.iterable));

        // Test custom collection - should have collectionInfo with type: null
        final customClassElem =
            libraryElement.getClass('ItemTypeParameterTests')!;
        final customField = customClassElem.getField('complexCollection')!;
        final customProperty = processField(customField);
        expect(customProperty!.collectionInfo, isNotNull);
        expect(customProperty.collectionInfo.type, isNull);
        expect(customProperty.collectionInfo.isCoreCollection, isFalse);
      });
    });

    group('Well-Known Collection Constants Processing', () {
      test('should correctly process rdf collection constants', () {
        final classElem =
            libraryElement.getClass('SetAndIterableCollectionTests')!;

        // Test rdfBag constant
        final bagCollectionField = classElem.getField('bagCollection')!;
        final bagProperty = processField(bagCollectionField);
        expect(bagProperty, isNotNull);
        expect(bagProperty!.collectionInfo, isNotNull);
        expect(bagProperty.annotation.collection, isNotNull);

        // Test rdfList constant
        final orderedCollectionField = classElem.getField('orderedCollection')!;
        final listProperty = processField(orderedCollectionField);
        expect(listProperty, isNotNull);
        expect(listProperty!.collectionInfo, isNotNull);
        expect(listProperty.annotation.collection, isNotNull);
      });
    });
  });
}
