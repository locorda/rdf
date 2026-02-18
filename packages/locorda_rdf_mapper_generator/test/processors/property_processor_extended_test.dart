// import 'package:analyzer/dart/element/element2.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/rdf_property_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

RdfPropertyInfo? processField(FieldElem field) =>
    PropertyProcessor.processField(ValidationContext(), field);
void main() {
  late LibraryElem libraryElement;

  setUpAll(() async {
    (libraryElement, _) =
        await analyzeTestFile('property_processor_test_models.dart');
  });

  test('should process complex default value', () {
    // Arrange
    final classElement = libraryElement.getClass('ComplexDefaultValueTest');
    if (classElement == null) {
      fail('Class ComplexDefaultValueTest not found in test models');
    }

    final field = classElement.getField('complexValue');
    if (field == null) {
      fail('Field "complexValue" not found in ComplexDefaultValueTest');
    }

    // Act
    final result = processField(field);

    // Assert
    expect(result, isNotNull);
    final propertyInfo = result!;
    // The defaultValue should be a Dart Map constant
    final defaultValue = propertyInfo.annotation.defaultValue;
    expect(defaultValue, isNotNull);

    // For now, just verify the default value is not null
    // The actual value inspection would require more complex Dart constant evaluation
    // which is beyond the scope of this test
    expect(defaultValue, isNotNull);
  });

  test('should process late properties', () {
    // Arrange
    final classElement = libraryElement.getClass('LatePropertyTest');
    if (classElement == null) {
      fail('Class LatePropertyTest not found in test models');
    }

    final nameField = classElement.getField('name');
    final descriptionField = classElement.getField('description');

    if (nameField == null) {
      fail('Field "name" not found in LatePropertyTest');
    }
    if (descriptionField == null) {
      fail('Field "description" not found in LatePropertyTest');
    }

    // Act
    final nameResult = processField(nameField);
    final descriptionResult = processField(descriptionField);

    // Assert
    expect(nameResult, isNotNull);
    expect(nameResult!.isLate, isTrue);
    expect(nameResult.isFinal, isFalse);
    expect(nameResult.isStatic, isFalse);
    expect(descriptionResult, isNotNull);
    expect(descriptionResult!.isLate, isTrue);
    expect(descriptionResult.isFinal, isFalse);
    expect(descriptionResult.isStatic, isFalse);

    expect(nameResult.annotation.predicate!.value, SchemaBook.name);
    expect(
        descriptionResult.annotation.predicate!.value, SchemaBook.description);
  });

  test('should process mutable properties with getters/setters', () {
    // Arrange
    final classElement = libraryElement.getClass('MutablePropertyTest');
    if (classElement == null) {
      fail('Class MutablePropertyTest not found in test models');
    }

    final nameField = classElement.getField('name');
    final descriptionField = classElement.getField('description');

    if (nameField == null) {
      fail('Field "name" not found in MutablePropertyTest');
    }
    if (descriptionField == null) {
      fail('Field "description" not found in MutablePropertyTest');
    }

    // Act
    final nameResult = processField(nameField);
    final descriptionResult = processField(descriptionField);

    // Assert
    expect(nameResult, isNotNull);
    expect(nameResult!.isFinal, isFalse);
    expect(nameResult.isLate, isFalse);
    expect(nameResult.isStatic, isFalse);

    expect(descriptionResult, isNotNull);
    expect(descriptionResult!.isFinal, isFalse);
    expect(descriptionResult.isLate, isFalse);
    expect(descriptionResult.isStatic, isFalse);

    expect(nameResult.annotation.predicate!.value, SchemaBook.name);
    expect(
        descriptionResult.annotation.predicate!.value, SchemaBook.description);
  });

  test('should process final properties', () {
    // Arrange
    final classElement = libraryElement.getClass('FinalPropertyTest');
    if (classElement == null) {
      fail('Class FinalPropertyTest not found in test models');
    }

    final nameField = classElement.getField('name');
    final descriptionField = classElement.getField('description');

    if (nameField == null) {
      fail('Field "name" not found in FinalPropertyTest');
    }
    if (descriptionField == null) {
      fail('Field "description" not found in FinalPropertyTest');
    }

    // Act
    final nameResult = processField(nameField);
    final descriptionResult = processField(descriptionField);

    // Assert
    expect(nameResult, isNotNull);
    expect(nameResult!.isLate, isFalse);
    expect(nameResult.isFinal, isTrue);
    expect(nameResult.isStatic, isFalse);
    expect(descriptionResult, isNotNull);
    expect(descriptionResult!.isLate, isFalse);
    expect(descriptionResult.isFinal, isTrue);
    expect(descriptionResult.isStatic, isFalse);

    expect(nameResult.annotation.predicate!.value, SchemaBook.name);
    expect(
        descriptionResult.annotation.predicate!.value, SchemaBook.description);
  });

  test('should process literal with language tag', () {
    // Arrange
    final classElement = libraryElement.getClass('LanguageTagTest');
    if (classElement == null) {
      fail('Class LanguageTagTest not found in test models');
    }

    final field = classElement.getField('description');
    if (field == null) {
      fail('Field "description" not found in LanguageTagTest');
    }

    // Act
    final result = processField(field);

    // Assert
    expect(result, isNotNull);
    final propertyInfo = result!;
    expect(propertyInfo.annotation.predicate!.value, SchemaBook.description);

    // Check for language tag
    final literal = propertyInfo.annotation.literal;
    expect(literal, isNotNull);
    expect(literal?.language, 'en');
  });

  test('should process literal with datatype', () {
    // Arrange
    final classElement = libraryElement.getClass('DatatypeTest');
    if (classElement == null) {
      fail('Class DatatypeTest not found in test models');
    }

    final field = classElement.getField('date');
    if (field == null) {
      fail('Field "date" not found in DatatypeTest');
    }

    // Act
    final result = processField(field);

    // Assert
    expect(result, isNotNull);
    final propertyInfo = result!;
    expect(propertyInfo.annotation.predicate!.value, SchemaBook.dateCreated);

    // Check for datatype
    final literal = propertyInfo.annotation.literal;
    expect(literal, isNotNull);

    expect(literal?.datatype?.value, Xsd.dateTime);
  });
}
