// import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:rdf_mapper_generator/src/processors/models/rdf_property_info.dart';
import 'package:rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:rdf_vocabularies_schema/schema.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

RdfPropertyInfo? processField(FieldElem field) =>
    PropertyProcessor.processField(ValidationContext(), field);

void main() {
  late final LibraryElem libraryElement;

  setUpAll(() async {
    (libraryElement, _) =
        await analyzeTestFile('property_processor_test_models.dart');
  });

  group('PropertyProcessor', () {
    test('should return null for field without RdfProperty annotation', () {
      // Arrange
      final field =
          libraryElement.getClass('NoAnnotationTest')!.getField('name');
      expect(field, isNotNull,
          reason: 'Field "name" not found in NoAnnotationTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNull);
    });

    test('should process simple property', () {
      // Arrange
      final field =
          libraryElement.getClass('SimplePropertyTest')!.getField('name');
      expect(field, isNotNull,
          reason: 'Field "name" not found in SimplePropertyTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'name');
      expect(result.annotation.predicate.value, equals(SchemaBook.name));
      expect(result.annotation.include, isTrue);
      expect(result.annotation.includeDefaultsInSerialization, isFalse);
      expect(result.isRequired, isTrue);
      expect(result.isFinal, isTrue);
    });

    test('should process property that is only deserialized, not serialized',
        () {
      // Arrange
      final field = libraryElement
          .getClass('DeserializationOnlyPropertyTest')!
          .getField('name');
      expect(field, isNotNull,
          reason: 'Field "name" not found in DeserializationOnlyPropertyTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.annotation.include, isFalse);
    });

    test('should process optional property', () {
      // Arrange
      final field =
          libraryElement.getClass('OptionalPropertyTest')!.getField('name');
      expect(field, isNotNull,
          reason: 'Field "name" not found in OptionalPropertyTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.isRequired, isFalse);
    });

    test('should process property with default value', () {
      // Arrange
      final field =
          libraryElement.getClass('DefaultValueTest')!.getField('isbn');
      expect(field, isNotNull,
          reason: 'Field "isbn" not found in DefaultValueTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      final defaultValue = annotation.defaultValue!;
      expect(defaultValue, isNotNull);
      expect(defaultValue.toStringValue(), 'default-isbn');
      expect(annotation.includeDefaultsInSerialization, isFalse);
    });

    test('should process property with includeDefaultsInSerialization', () {
      // Arrange
      final field =
          libraryElement.getClass('IncludeDefaultsTest')!.getField('rating');
      expect(field, isNotNull,
          reason: 'Field "rating" not found in IncludeDefaultsTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.includeDefaultsInSerialization, isTrue);
      final defaultValue = annotation.defaultValue!;
      expect(defaultValue, isNotNull);
      expect(defaultValue.toIntValue(), 5);
    });

    test('should process property with IRI mapping template', () {
      // Arrange
      final field =
          libraryElement.getClass('IriMappingTest')!.getField('authorId');
      expect(field, isNotNull,
          reason: 'Field "authorId" not found in IriMappingTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'authorId');
      expect(result.annotation.predicate.value, equals(SchemaBook.author));
      expect(result.annotation.include, isTrue);
      expect(result.isRequired, isTrue);
      expect(result.isFinal, isTrue);

      // Verify IRI mapping configuration
      final annotation = result.annotation;
      expect(annotation.iri, isNotNull,
          reason: 'IriMapping should be processed and available');
      expect(
        annotation.iri!.template!.template,
        'http://example.org/authors/{authorId}',
        reason: 'IRI template should match the annotation value',
      );
      expect(annotation.iri!.mapper, isNull,
          reason: 'Template-based IriMapping should not have a custom mapper');

      // Verify other mapping types are null for IRI mapping
      expect(annotation.literal, isNull);
      expect(annotation.localResource, isNull);
      expect(annotation.globalResource, isNull);
    });

    test('should process property with IRI mapping template using base URI',
        () {
      // Arrange
      final field = libraryElement
          .getClass('IriMappingWithBaseUriTest')!
          .getField('authorId');
      expect(field, isNotNull,
          reason: 'Field "authorId" not found in IriMappingWithBaseUriTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'authorId');
      expect(result.annotation.predicate.value, equals(SchemaBook.author));
      expect(result.annotation.include, isTrue);
      expect(result.isRequired, isTrue);
      expect(result.isFinal, isTrue);

      // Verify IRI mapping configuration with base URI template
      final annotation = result.annotation;
      expect(annotation.iri, isNotNull,
          reason: 'IriMapping should be processed and available');
      expect(
        annotation.iri!.template!.template,
        '{+baseUri}/authors/{authorId}',
        reason:
            'IRI template should match the annotation value with base URI expansion',
      );
      expect(annotation.iri!.mapper, isNull,
          reason: 'Template-based IriMapping should not have a custom mapper');

      // Verify other mapping types are null for IRI mapping
      expect(annotation.literal, isNull);
      expect(annotation.localResource, isNull);
      expect(annotation.globalResource, isNull);
    });

    test('should process property with IRI mapping (named)', () {
      // Arrange
      final field = libraryElement
          .getClass('IriMappingNamedMapperTest')!
          .getField('authorId');
      expect(field, isNotNull,
          reason: 'Field "authorId" not found in IriMappingNamedMapperTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      final iri = annotation.iri;
      expect(iri, isNotNull);
      expect(iri!.template, isNull);
      final mapper = iri.mapper;
      expect(mapper, isNotNull);
      expect(mapper!.name, 'iriMapper');
      expect(mapper.instance, isNull);
      expect(mapper.type, isNull);
    });

    test('should process property with IRI mapping (type)', () {
      // Arrange
      final field =
          libraryElement.getClass('IriMappingMapperTest')!.getField('authorId');
      expect(field, isNotNull,
          reason: 'Field "authorId" not found in IriMappingMapperTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      final iri = annotation.iri;
      expect(iri, isNotNull);
      expect(iri!.template, isNull);
      final mapper = iri.mapper;
      expect(mapper, isNotNull);
      expect(mapper!.name, isNull);
      expect(mapper.instance, isNull);
      expect(mapper.type, isNotNull);

      expect(mapper.type!.codeWithoutAlias, 'IriMapperImpl');
    });

    test('should process property with IRI mapping (instance)', () {
      // Arrange
      final field = libraryElement
          .getClass('IriMappingMapperInstanceTest')!
          .getField('authorId');
      expect(field, isNotNull,
          reason: 'Field "authorId" not found in IriMappingMapperInstanceTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      final iri = annotation.iri;
      expect(iri, isNotNull);
      expect(iri!.template, isNull);
      final mapper = iri.mapper;
      expect(mapper, isNotNull);
      expect(mapper!.name, isNull);
      expect(mapper.instance, isNotNull);
      expect(mapper.type, isNull);
      expect(mapper.instance!.type, isNotNull);
      expect(mapper.instance!.type!.getDisplayString(), 'IriMapperImpl');
      expect(mapper.instance!.toString(), 'IriMapperImpl ()');
      expect(mapper.instance!.hasKnownValue, isTrue);
    });

    test('should process property with local resource mapping', () {
      // Arrange
      final field = libraryElement
          .getClass('LocalResourceMappingTest')!
          .getField('author');
      expect(field, isNotNull,
          reason: 'Field "author" not found in LocalResourceMappingTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.localResource, isNotNull);
      expect(annotation.localResource!.mapper, isNotNull);
      expect(annotation.localResource!.mapper!.name, 'testLocalMapper');
    });

    test('should process property with global resource mapping', () {
      // Arrange
      final field = libraryElement
          .getClass('GlobalResourceMappingTest')!
          .getField('publisher');
      expect(field, isNotNull,
          reason: 'Field "publisher" not found in GlobalResourceMappingTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.globalResource, isNotNull);
      expect(annotation.globalResource!.mapper, isNotNull);
      expect(annotation.globalResource!.mapper!.name, 'testGlobalMapper');
    });

    test('should process property with literal mapping', () {
      // Arrange
      final field =
          libraryElement.getClass('LiteralMappingTest')!.getField('price');
      expect(field, isNotNull,
          reason: 'Field "price" not found in LiteralMappingTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.literal, isNotNull);
      expect(annotation.literal!.mapper, isNotNull);
      expect(annotation.literal!.mapper!.name, 'testLiteralPriceMapper');
    });

    test('should process collection properties (none)', () {
      // Test collection
      final field =
          libraryElement.getClass('CollectionNoneTest')!.getField('authors');
      expect(field, isNotNull,
          reason: 'Field "authors" not found in CollectionNoneTest');

      final result = processField(field!);
      expect(result, isNotNull);
      expect(result?.annotation.collection, isNotNull);
      expect(result?.annotation.collection!.factory, isNull);
      expect(result?.annotation.collection!.isAuto, isFalse);
      expect(result?.annotation.collection!.mapper, isNotNull);
    });

    test('should process collection properties (auto)', () {
      // Test collection
      final field =
          libraryElement.getClass('CollectionAutoTest')!.getField('authors');
      expect(field, isNotNull,
          reason: 'Field "authors" not found in CollectionAutoTest');

      final result = processField(field!);
      expect(result, isNotNull);
      expect(result?.annotation.collection, isNotNull);
      expect(result?.annotation.collection?.isAuto, isTrue);
    });

    test('should process collection properties (default)', () {
      // Test collection
      final field =
          libraryElement.getClass('CollectionTest')!.getField('authors');
      expect(field, isNotNull,
          reason: 'Field "authors" not found in CollectionTest');

      final result = processField(field!);
      expect(result, isNotNull);
      expect(result?.annotation.collection, isNotNull);
      expect(result?.annotation.collection?.isAuto, isFalse);
      expect(result?.annotation.collection?.factory, isNotNull);
      expect(result?.annotation.collection?.factory?.codeWithoutAlias,
          'UnorderedItemsListMapper');
      expect(result?.collectionInfo, isNotNull);

      expect(result?.collectionInfo.isCoreList, isTrue);
      expect(result?.collectionInfo.isCoreMap, isFalse);
      expect(result?.collectionInfo.isCoreSet, isFalse);
      expect(result?.collectionInfo.isCoreCollection, isTrue);
      expect(result?.collectionInfo.type, equals(CollectionType.list));
      expect(result?.collectionInfo.keyTypeCode, isNull);
      expect(result?.collectionInfo.valueTypeCode, isNull);
      expect(result?.collectionInfo.elementTypeCode, equals(stringType));
    });

    test('should process enum type property', () {
      // Arrange
      final field = libraryElement.getClass('EnumTypeTest')!.getField('format');
      expect(field, isNotNull,
          reason: 'Field "format" not found in EnumTypeTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.type.codeWithoutAlias, 'BookFormatType');
      expect(result.annotation.predicate.value, equals(SchemaBook.bookFormat));
      expect(result.annotation.literal, isNull);
      expect(result.annotation.iri, isNull);
      expect(result.annotation.localResource, isNull);
      expect(result.annotation.globalResource, isNull);
    });

    test('should process map type property (collection none)', () {
      // Arrange
      final field = libraryElement
          .getClass('MapNoCollectionNoMapperTest')!
          .getField('reviews');
      expect(field, isNotNull,
          reason: 'Field "reviews" not found in MapNoCollectionNoMapperTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.type.codeWithoutAlias, 'Map<String, String>');
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection?.factory, isNull);
      expect(result.annotation.collection?.isAuto, isFalse);
      expect(result.annotation.predicate.value, equals(SchemaBook.reviews));
    });

    test('should process map type property (collection auto)', () {
      // Arrange
      final field = libraryElement
          .getClass('MapLocalResourceMapperTest')!
          .getField('reviews');
      expect(field, isNotNull,
          reason: 'Field "reviews" not found in MapLocalResourceMapperTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.type.codeWithoutAlias, 'Map<String, String>');
      expect(result.annotation.collection, isNotNull);
      expect(result.annotation.collection?.factory, isNull);
      expect(result.annotation.collection?.isAuto, isTrue);
      expect(result.annotation.predicate.value, equals(SchemaBook.reviews));
      expect(result.annotation.localResource, isNotNull);
      expect(result.annotation.localResource!.mapper, isNotNull);
      expect(result.annotation.localResource!.mapper!.name, 'mapEntryMapper');
    });

    test('should process set type property', () {
      // Arrange
      final field = libraryElement.getClass('SetTest')!.getField('keywords');
      expect(field, isNotNull, reason: 'Field "keywords" not found in SetTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.type.codeWithoutAlias, 'Set<String>');
      expect(result.annotation.collection?.factory, isNull);
      expect(result.annotation.collection?.isAuto, isTrue);
      expect(result.annotation.predicate.value, equals(SchemaBook.keywords));
    });

    test('should process named mapper property', () {
      // Arrange
      final field = libraryElement
          .getClass('GlobalResourceNamedMapperTest')!
          .getField('publisher');
      expect(field, isNotNull,
          reason:
              'Field "publisher" not found in GlobalResourceNamedMapperTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.globalResource, isNotNull);
      expect(annotation.globalResource!.mapper, isNotNull);
      expect(annotation.globalResource!.mapper!.name, 'testNamedMapper');
      expect(annotation.predicate.value, equals(SchemaBook.publisher));
    });

    test('should process custom mapper with parameters', () {
      // Arrange
      final field =
          libraryElement.getClass('LiteralNamedMapperTest')!.getField('isbn');
      expect(field, isNotNull,
          reason: 'Field "isbn" not found in LiteralNamedMapperTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.literal, isNotNull);
      expect(annotation.literal!.mapper, isNotNull);
      expect(annotation.literal!.mapper!.name, 'testCustomMapper');
      expect(annotation.predicate.value, equals(SchemaBook.isbn));
    });

    test('should process LocalResourceInstanceMapperTest', () {
      // Arrange
      final field = libraryElement
          .getClass('LocalResourceInstanceMapperTest')!
          .getField('author');
      expect(field, isNotNull,
          reason:
              'Field "author" not found in LocalResourceInstanceMapperTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.localResource, isNotNull);
      expect(annotation.localResource!.mapper, isNotNull);
      expect(annotation.localResource!.mapper!.name, isNull);
      expect(annotation.localResource!.mapper!.type, isNull);
      expect(annotation.predicate.value, equals(SchemaBook.author));
      expect(annotation.localResource!.mapper!.instance, isNotNull);
      expect(
          annotation.localResource!.mapper!.instance!.type!.getDisplayString(),
          "LocalResourceAuthorMapperImpl");
    });

    test('should process LiteralTypeMapperTest', () {
      // Arrange
      final field =
          libraryElement.getClass('LiteralTypeMapperTest')!.getField('price');
      expect(field, isNotNull,
          reason: 'Field "price" not found in LiteralTypeMapperTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.literal, isNotNull);
      expect(annotation.literal!.mapper, isNotNull);
      expect(annotation.literal!.mapper!.name, isNull);
      expect(annotation.literal!.mapper!.instance, isNull);
      expect(annotation.literal!.mapper!.type, isNotNull);
      expect(annotation.literal!.mapper!.type!.codeWithoutAlias,
          'LiteralDoubleMapperImpl');

      expect(annotation.predicate.value, equals(SchemaBook.bookFormat));
    });

    test('should process type-based mapper using mapper() constructor', () {
      // Arrange
      final field = libraryElement
          .getClass('GlobalResourceTypeMapperTest')!
          .getField('publisher');
      expect(field, isNotNull,
          reason:
              'Field "publisher" not found in GlobalResourceTypeMapperTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.globalResource, isNotNull);
      expect(annotation.predicate.value, equals(SchemaBook.publisher));
    });

    test('should process global resource mapper using mapper() constructor',
        () {
      // Arrange
      final field = libraryElement
          .getClass('GlobalResourceMapperTest')!
          .getField('publisher');
      expect(field, isNotNull,
          reason: 'Field "publisher" not found in GlobalResourceMapperTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.globalResource, isNotNull);
      expect(annotation.predicate.value, equals(SchemaBook.publisher));
    });

    test(
        'should process global resource mapper using mapperInstance() constructor',
        () {
      // Arrange
      final field = libraryElement
          .getClass('GlobalResourceInstanceMapperTest')!
          .getField('publisher');
      expect(field, isNotNull,
          reason:
              'Field "publisher" not found in GlobalResourceInstanceMapperTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.globalResource, isNotNull);
      expect(annotation.predicate.value, equals(SchemaBook.publisher));
    });

    test('should process local resource mapper using mapper() constructor', () {
      // Arrange
      final field = libraryElement
          .getClass('LocalResourceMapperTest')!
          .getField('author');
      expect(field, isNotNull,
          reason: 'Field "author" not found in LocalResourceMapperTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.localResource, isNotNull);
      expect(annotation.predicate.value, equals(SchemaBook.author));
    });

    test('should process literal mapper using mapper() constructor', () {
      // Arrange
      final field =
          libraryElement.getClass('LiteralMapperTest')!.getField('pageCount');
      expect(field, isNotNull,
          reason: 'Field "pageCount" not found in LiteralMapperTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.literal, isNotNull);
      expect(annotation.predicate.value, equals(SchemaBook.numberOfPages));
    });

    test('should process literal mapper using mapperInstance() constructor',
        () {
      // Arrange
      final field = libraryElement
          .getClass('LiteralInstanceMapperTest')!
          .getField('isbn');
      expect(field, isNotNull,
          reason: 'Field "isbn" not found in LiteralInstanceMapperTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.literal, isNotNull);
      expect(annotation.literal!.mapper, isNotNull);
      expect(annotation.literal!.mapper!.name, isNull);
      expect(annotation.literal!.mapper!.type, isNull);
      expect(annotation.literal!.mapper!.instance, isNotNull);
      expect(annotation.literal!.mapper!.instance!.type!.getDisplayString(),
          'LiteralStringMapperImpl');
      expect(annotation.predicate.value, equals(SchemaBook.isbn));
    });

    test('should process literal mapping with custom datatype', () {
      // Arrange
      final field = libraryElement
          .getClass('LiteralMappingTestCustomDatatype')!
          .getField('price');
      expect(field, isNotNull,
          reason:
              'Field "price" not found in LiteralMappingTestCustomDatatype');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.literal, isNotNull);
      expect(annotation.literal!.mapper, isNotNull);
      expect(annotation.literal!.mapper!.instance, isNotNull);
      expect(annotation.literal!.mapper!.instance!.type!.getDisplayString(),
          'DoubleMapper');
      expect(annotation.predicate.value.value, 'http://example.org/book/price');
    });

    test('should process property with complex default value', () {
      // Arrange
      final field = libraryElement
          .getClass('ComplexDefaultValueTest')!
          .getField('complexValue');
      expect(field, isNotNull,
          reason: 'Field "complexValue" not found in ComplexDefaultValueTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      final defaultValue = annotation.defaultValue!;
      expect(defaultValue, isNotNull);

      expect(annotation.predicate.value,
          equals(const IriTerm('http://example.org/test/complexValue')));
    });

    test('should process final properties', () {
      // Arrange
      final field =
          libraryElement.getClass('FinalPropertyTest')!.getField('name');
      expect(field, isNotNull,
          reason: 'Field "name" not found in FinalPropertyTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.isFinal, isTrue);
      expect(result.isRequired, isTrue);
      expect(result.annotation.predicate.value, equals(SchemaBook.name));
    });

    test('should process final optional properties', () {
      // Arrange
      final field =
          libraryElement.getClass('FinalPropertyTest')!.getField('description');
      expect(field, isNotNull,
          reason: 'Field "description" not found in FinalPropertyTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.isFinal, isTrue);
      expect(result.isRequired, isFalse);
      expect(result.annotation.predicate.value, equals(SchemaBook.description));
    });

    test('should process late properties', () {
      // Arrange
      final field =
          libraryElement.getClass('LatePropertyTest')!.getField('name');
      expect(field, isNotNull,
          reason: 'Field "name" not found in LatePropertyTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.isFinal, isFalse);
      expect(result.isRequired, isTrue);
      expect(result.annotation.predicate.value, equals(SchemaBook.name));
    });

    test('should process late optional properties', () {
      // Arrange
      final field =
          libraryElement.getClass('LatePropertyTest')!.getField('description');
      expect(field, isNotNull,
          reason: 'Field "description" not found in LatePropertyTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.isFinal, isFalse);
      expect(result.isRequired, isFalse);
      expect(result.annotation.predicate.value, equals(SchemaBook.description));
    });

    test('should process mutable properties', () {
      // Arrange
      final field =
          libraryElement.getClass('MutablePropertyTest')!.getField('name');
      expect(field, isNotNull,
          reason: 'Field "name" not found in MutablePropertyTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.isFinal, isFalse);
      expect(result.isRequired, isTrue);
      expect(result.annotation.predicate.value, equals(SchemaBook.name));
    });

    test('should process mutable optional properties', () {
      // Arrange
      final field = libraryElement
          .getClass('MutablePropertyTest')!
          .getField('description');
      expect(field, isNotNull,
          reason: 'Field "description" not found in MutablePropertyTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.isFinal, isFalse);
      expect(result.isRequired, isFalse);
      expect(result.annotation.predicate.value, equals(SchemaBook.description));
    });

    test('should process property with language tag', () {
      // Arrange
      final field =
          libraryElement.getClass('LanguageTagTest')!.getField('description');
      expect(field, isNotNull,
          reason: 'Field "description" not found in LanguageTagTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.literal, isNotNull);
      expect(annotation.literal!.language, 'en');
      expect(annotation.predicate.value, equals(SchemaBook.description));
    });

    test('should process property with custom datatype', () {
      // Arrange
      final field = libraryElement.getClass('DatatypeTest')!.getField('count');
      expect(field, isNotNull,
          reason: 'Field "count" not found in DatatypeTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      final annotation = result!.annotation;
      expect(annotation.literal, isNotNull);
      expect(annotation.literal!.datatype, isNotNull);
      expect(annotation.literal!.datatype!.value.value,
          'http://www.w3.org/2001/XMLSchema#string');
      expect(annotation.predicate.value, equals(SchemaBook.description));
    });

    test('should process local resource mapper with Object property type', () {
      // Arrange
      final field = libraryElement
          .getClass('LocalResourceMapperObjectPropertyTest')!
          .getField('author');
      expect(field, isNotNull,
          reason:
              'Field "author" not found in LocalResourceMapperObjectPropertyTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.type.codeWithoutAlias, 'Object');
      final annotation = result.annotation;
      expect(annotation.localResource, isNotNull);
      expect(annotation.localResource!.mapper, isNotNull);
      expect(annotation.localResource!.mapper!.type, isNotNull);
      expect(annotation.localResource!.mapper!.type!.codeWithoutAlias,
          'LocalResourceAuthorMapperImpl');
      expect(annotation.predicate.value, equals(SchemaBook.author));
    });

    test(
        'should process local resource mapper instance with Object property type',
        () {
      // Arrange
      final field = libraryElement
          .getClass('LocalResourceInstanceMapperObjectPropertyTest')!
          .getField('author');
      expect(field, isNotNull,
          reason:
              'Field "author" not found in LocalResourceInstanceMapperObjectPropertyTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.type.codeWithoutAlias, 'Object');
      final annotation = result.annotation;
      expect(annotation.localResource, isNotNull);
      expect(annotation.localResource!.mapper, isNotNull);
      expect(annotation.localResource!.mapper!.instance, isNotNull);
      expect(
          annotation.localResource!.mapper!.instance!.type!.getDisplayString(),
          'LocalResourceAuthorMapperImpl');
      expect(annotation.predicate.value, equals(SchemaBook.author));
    });

    test(
        'should process property with IRI mapping for full IRI (explicit template)',
        () {
      // Arrange
      final field = libraryElement
          .getClass('IriMappingFullIriTest')!
          .getField('authorIri');
      expect(field, isNotNull,
          reason: 'Field "authorIri" not found in IriMappingFullIriTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'authorIri');
      expect(result.annotation.predicate.value, equals(SchemaBook.author));
      expect(result.annotation.include, isTrue);
      expect(result.annotation.includeDefaultsInSerialization, isFalse);
      expect(result.isRequired, isTrue);
      expect(result.isFinal, isTrue);

      // Verify IRI mapping annotation
      expect(result.annotation.iri, isNotNull);
      expect(result.annotation.iri!.template, isNotNull);
      expect(result.annotation.iri!.template!.template, '{+authorIri}');
      expect(result.annotation.iri!.template!.iriParts, hasLength(1));
      expect(
          result.annotation.iri!.template!.iriParts!.first.name, 'authorIri');
    });

    test(
        'should process property with IRI mapping for full IRI (simple syntax)',
        () {
      // Arrange
      final field = libraryElement
          .getClass('IriMappingFullIriSimpleTest')!
          .getField('authorIri');
      expect(field, isNotNull,
          reason: 'Field "authorIri" not found in IriMappingFullIriSimpleTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'authorIri');
      expect(result.annotation.predicate.value, equals(SchemaBook.author));
      expect(result.annotation.include, isTrue);
      expect(result.annotation.includeDefaultsInSerialization, isFalse);
      expect(result.isRequired, isTrue);
      expect(result.isFinal, isTrue);

      // Verify IRI mapping annotation - simple syntax should create default full IRI template
      expect(result.annotation.iri, isNotNull);
      expect(result.annotation.iri!.template, isNotNull);
      expect(result.annotation.iri!.template!.template, '{+authorIri}');
      expect(result.annotation.iri!.template!.iriParts, hasLength(1));
      expect(
          result.annotation.iri!.template!.iriParts!.first.name, 'authorIri');
    });

    test(
        'should process simple custom property with global resource and IRI part',
        () {
      // Arrange
      final field =
          libraryElement.getClass('SimpleCustomPropertyTest')!.getField('name');
      expect(field, isNotNull,
          reason: 'Field "name" not found in SimpleCustomPropertyTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'name');
      expect(result.annotation.predicate.value.value,
          equals('http://example.org/types/Book/name'));
      expect(result.annotation.include, isTrue);
      expect(result.annotation.includeDefaultsInSerialization, isFalse);
      expect(result.isRequired, isTrue);
      expect(result.isFinal, isTrue);
    });

    test('should process property with IRI mapping using provider', () {
      // Arrange
      final field = libraryElement
          .getClass('IriMappingWithProviderTest')!
          .getField('authorId');
      expect(field, isNotNull,
          reason: 'Field "authorId" not found in IriMappingWithProviderTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'authorId');
      expect(result.annotation.predicate.value, equals(SchemaBook.author));
      expect(result.annotation.include, isTrue);
      expect(result.isRequired, isTrue);
      expect(result.isFinal, isTrue);

      // Verify IRI mapping configuration with provider
      final annotation = result.annotation;
      expect(annotation.iri, isNotNull,
          reason: 'IriMapping should be processed and available');
      expect(
        annotation.iri!.template!.template,
        'http://example.org/{category}/{authorId}',
        reason:
            'IRI template should match the annotation value with provider variable',
      );
      expect(annotation.iri!.mapper, isNull,
          reason: 'Template-based IriMapping should not have a custom mapper');

      // Verify other mapping types are null for IRI mapping
      expect(annotation.literal, isNull);
      expect(annotation.localResource, isNull);
      expect(annotation.globalResource, isNull);
    });

    test('should process property with IRI mapping using base URI provider',
        () {
      // Arrange
      final field = libraryElement
          .getClass('IriMappingWithBaseUriProviderTest')!
          .getField('authorId');
      expect(field, isNotNull,
          reason:
              'Field "authorId" not found in IriMappingWithBaseUriProviderTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'authorId');
      expect(result.annotation.predicate.value, equals(SchemaBook.author));
      expect(result.annotation.include, isTrue);
      expect(result.isRequired, isTrue);
      expect(result.isFinal, isTrue);

      // Verify IRI mapping configuration with base URI provider
      final annotation = result.annotation;
      expect(annotation.iri, isNotNull,
          reason: 'IriMapping should be processed and available');
      expect(
        annotation.iri!.template!.template,
        '{+baseUri}/{authorId}',
        reason:
            'IRI template should match the annotation value with base URI provider',
      );
      expect(annotation.iri!.mapper, isNull,
          reason: 'Template-based IriMapping should not have a custom mapper');

      // Verify other mapping types are null for IRI mapping
      expect(annotation.literal, isNull);
      expect(annotation.localResource, isNull);
      expect(annotation.globalResource, isNull);
    });

    test('should process property with IRI mapping using property provider',
        () {
      // Arrange
      final field = libraryElement
          .getClass('IriMappingWithProviderPropertyTest')!
          .getField('authorId');
      expect(field, isNotNull,
          reason:
              'Field "authorId" not found in IriMappingWithProviderPropertyTest');

      // Act
      final result = processField(field!);

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'authorId');
      expect(result.annotation.predicate.value, equals(SchemaBook.author));
      expect(result.annotation.include, isTrue);
      expect(result.isRequired, isTrue);
      expect(result.isFinal, isTrue);

      // Verify IRI mapping configuration with property provider
      final annotation = result.annotation;
      expect(annotation.iri, isNotNull,
          reason: 'IriMapping should be processed and available');
      expect(
        annotation.iri!.template!.template,
        'http://example.org/{genre}/{authorId}',
        reason:
            'IRI template should match the annotation value with property provider variable',
      );
      expect(annotation.iri!.mapper, isNull,
          reason: 'Template-based IriMapping should not have a custom mapper');

      // Verify other mapping types are null for IRI mapping
      expect(annotation.literal, isNull);
      expect(annotation.localResource, isNull);
      expect(annotation.globalResource, isNull);
    });
  });
}
