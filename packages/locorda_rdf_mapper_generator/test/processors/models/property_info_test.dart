import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/rdf_property_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/util.dart';
import 'package:test/test.dart';

/// Creates a minimal IriTemplateInfo instance for testing purposes.
///
/// This helper function creates a valid IriTemplateInfo with minimal required data,
/// suitable for testing equality, hashCode, and toString methods.
IriTemplateInfo createTestTemplateInfo(String template) {
  final variables = <VariableName>{};
  final propertyVariables = <VariableName>{};
  final contextVariables = <VariableName>{};

  return IriTemplateInfo(
    template: template,
    variables: variables,
    propertyVariables: propertyVariables,
    contextVariables: contextVariables,
    isValid: true,
    validationErrors: const [],
    warnings: const [],
  );
}

void main() {
  group('LocalResourceMappingInfo', () {
    test('equals and hashCode work correctly', () {
      final instance1 = LocalResourceMappingInfo(mapper: null);
      final instance2 = LocalResourceMappingInfo(mapper: null);

      expect(instance1, equals(instance2));
      expect(instance1.hashCode, equals(instance2.hashCode));
    });

    test('toString returns formatted string representation', () {
      final instance = LocalResourceMappingInfo(mapper: null);
      final result = instance.toString();
      expect(result, contains('LocalResourceMappingInfo{'));
      expect(result, contains('mapper: null'));
    });

    test('equals returns false for non-LocalResourceMappingInfo instances', () {
      final instance = LocalResourceMappingInfo(mapper: null);
      expect(instance, isNot(equals('not a LocalResourceMappingInfo')));
    });
  });

  group('LiteralMappingInfo', () {
    test('equals and hashCode work correctly', () {
      final instance1 = LiteralMappingInfo(
        language: 'en',
        datatype: null,
        mapper: null,
      );

      final instance2 = LiteralMappingInfo(
        language: 'en',
        datatype: null,
        mapper: null,
      );

      final differentInstance = LiteralMappingInfo(
        language: 'de',
        datatype: null,
        mapper: null,
      );

      expect(instance1, equals(instance2));
      expect(instance1.hashCode, equals(instance2.hashCode));
      expect(instance1, isNot(equals(differentInstance)));
    });

    test('toString returns formatted string representation', () {
      final instance = LiteralMappingInfo(
        language: 'en',
        datatype: null,
        mapper: null,
      );
      final result = instance.toString();
      expect(result, contains('LiteralMappingInfo{'));
      expect(result, contains('language: en'));
      expect(result, contains('datatype: null'));
    });

    test('equals returns false for non-LiteralMappingInfo instances', () {
      final instance = LiteralMappingInfo(
        language: 'en',
        datatype: null,
        mapper: null,
      );
      expect(instance, isNot(equals('not a LiteralMappingInfo')));
    });
  });

  group('GlobalResourceMappingInfo', () {
    test('equals and hashCode work correctly', () {
      final instance1 = GlobalResourceMappingInfo(mapper: null);
      final instance2 = GlobalResourceMappingInfo(mapper: null);

      expect(instance1, equals(instance2));
      expect(instance1.hashCode, equals(instance2.hashCode));
    });

    test('toString returns formatted string representation', () {
      final instance = GlobalResourceMappingInfo(mapper: null);
      final result = instance.toString();
      expect(result, contains('GlobalResourceMappingInfo{'));
      expect(result, contains('mapper: null'));
    });

    test('equals returns false for non-GlobalResourceMappingInfo instances',
        () {
      final instance = GlobalResourceMappingInfo(mapper: null);
      expect(instance, isNot(equals('not a GlobalResourceMappingInfo')));
    });
  });

  group('IriMappingInfo', () {
    test('equals and hashCode work correctly', () {
      final instance1 = IriMappingInfo(
        template: createTestTemplateInfo('template1'),
        mapper: null,
      );

      final instance2 = IriMappingInfo(
        template: createTestTemplateInfo('template1'),
        mapper: null,
      );

      final differentInstance = IriMappingInfo(
        template: createTestTemplateInfo('template2'),
        mapper: null,
      );

      expect(instance1, equals(instance2));
      expect(instance1.hashCode, equals(instance2.hashCode));
      expect(instance1, isNot(equals(differentInstance)));
    });

    test('toString returns formatted string representation', () {
      final instance = IriMappingInfo(
        template: createTestTemplateInfo('template1'),
        mapper: null,
      );
      final result = instance.toString();
      expect(result, contains('IriMappingInfo{'));
      expect(result, contains('template: template1'));
    });

    test('equals returns false for non-IriMappingInfo instances', () {
      final instance = IriMappingInfo(
        template: createTestTemplateInfo('template1'),
        mapper: null,
      );
      expect(instance, isNot(equals('not an IriMappingInfo')));
    });
  });

  group('RdfPropertyInfo', () {
    late RdfPropertyAnnotationInfo testInstance;
    late RdfPropertyAnnotationInfo identicalInstance;
    late RdfPropertyAnnotationInfo differentInstance;

    setUp(() {
      final predicate = IriTermInfo(
        code: Code.literal('http://example.com/predicate'),
        value: const IriTerm('http://example.com/predicate'),
      );

      testInstance = RdfPropertyAnnotationInfo(
        predicate,
        include: true,
        defaultValue: null,
        includeDefaultsInSerialization: false,
        iri: null,
        localResource: null,
        literal: null,
        globalResource: null,
        contextual: null,
        collection: null,
        itemType: null,
      );

      identicalInstance = RdfPropertyAnnotationInfo(
        predicate,
        include: true,
        defaultValue: null,
        includeDefaultsInSerialization: false,
        iri: null,
        localResource: null,
        literal: null,
        globalResource: null,
        contextual: null,
        collection: null,
        itemType: null,
      );

      differentInstance = RdfPropertyAnnotationInfo(
        predicate,
        include: false,
        defaultValue: null,
        includeDefaultsInSerialization: false,
        iri: null,
        localResource: null,
        literal: null,
        globalResource: null,
        contextual: null,
        collection: null,
        itemType: null,
      );
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-RdfPropertyInfo instances', () {
      expect(testInstance, isNot(equals('not an RdfPropertyInfo')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('RdfPropertyInfo{'));
      expect(result, contains('predicate:'));
      expect(result, contains('include: true'));
      expect(result, contains('collection: null'));
    });
  });

  group('PropertyInfo', () {
    late RdfPropertyInfo testInstance;
    late RdfPropertyInfo identicalInstance;
    late RdfPropertyInfo differentInstance;

    setUp(() {
      final predicate = IriTermInfo(
        code: Code.literal('http://example.com/predicate'),
        value: const IriTerm('http://example.com/predicate'),
      );
      final annotation = RdfPropertyAnnotationInfo(
        predicate,
        include: true,
        defaultValue: null,
        includeDefaultsInSerialization: false,
        iri: null,
        localResource: null,
        literal: null,
        globalResource: null,
        contextual: null,
        collection: null,
        itemType: null,
      );

      testInstance = RdfPropertyInfo(
        name: 'testProperty',
        type: stringType,
        annotation: annotation,
        isRequired: true,
        isFinal: true,
        isLate: false,
        isStatic: false,
        isSynthetic: false,
        collectionInfo: const CollectionInfo(),
      );

      identicalInstance = RdfPropertyInfo(
        name: 'testProperty',
        type: stringType,
        annotation: annotation,
        isRequired: true,
        isFinal: true,
        isLate: false,
        isStatic: false,
        isSynthetic: false,
        collectionInfo: const CollectionInfo(),
      );

      differentInstance = RdfPropertyInfo(
        name: 'differentProperty',
        type: stringType,
        annotation: annotation,
        isRequired: true,
        isFinal: true,
        isLate: false,
        isStatic: false,
        isSynthetic: false,
        collectionInfo: const CollectionInfo(),
      );
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-PropertyInfo instances', () {
      expect(testInstance, isNot(equals('not a PropertyInfo')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('PropertyInfo{'));
      expect(result, contains('name: testProperty'));
      expect(result, contains('type: String'));
      expect(result, contains('isRequired: true'));
      expect(result, contains('isFinal: true'));
      expect(result, contains('isLate: false'));
      expect(result, contains('isStatic: false'));
      expect(result, contains('isSynthetic: false'));
    });
  });
}
