// import 'package:analyzer/dart/element/element2.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/resource_processor.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('GlobalResourceProcessor', () {
    late LibraryElem libraryElement;

    setUpAll(() async {
      (libraryElement, _) =
          await analyzeTestFile('global_resource_processor_test_models.dart');
    });

    test('should process ClassWithEmptyIriStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass('ClassWithEmptyIriStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithEmptyIriStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri?.mapper, isNull);
      expect(annotation.iri?.template, '{+iri}');

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
    });
    test('should process ClassWithEmptyIriStrategyNoRegisterGlobally', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext,
          libraryElement
              .getClass('ClassWithEmptyIriStrategyNoRegisterGlobally')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code,
          'grptm.ClassWithEmptyIriStrategyNoRegisterGlobally');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isFalse);
      expect(annotation.iri?.mapper, isNull);
      expect(annotation.iri?.template, '{+iri}');
      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
    });
    test('should process ClassWithIriTemplateStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass('ClassWithIriTemplateStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriTemplateStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.iri?.mapper, isNull);
      expect(
          annotation.iri?.template, equals('http://example.org/persons/{id}'));
      expect(annotation.iri?.templateInfo, isNotNull);
      expect(annotation.iri?.templateInfo?.isValid, isTrue);
      expect(annotation.iri?.templateInfo?.variables, contains('id'));
      expect(
          annotation.iri?.templateInfo?.propertyVariables.map((pn) => pn.name),
          contains('id'));
      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
    });
    test('should process ClassWithIriNamedMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass('ClassWithIriNamedMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriNamedMapperStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.template, isNull);
      expect(annotation.iri!.mapper, isNotNull);
      expect(annotation.iri!.mapper!.name, equals('testMapper'));
      expect(annotation.iri!.mapper!.type, isNull);
      expect(annotation.iri!.mapper!.instance, isNull);
      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(0));
    });
    test('should process ClassWithIriMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass('ClassWithIriMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriMapperStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.template, isNull);
      expect(annotation.iri!.mapper, isNotNull);
      expect(annotation.iri!.mapper!.name, isNull);
      expect(annotation.iri!.mapper!.type, isNotNull);
      expect(annotation.iri!.mapper!.type!.codeWithoutAlias, 'TestIriMapper');
      expect(annotation.iri!.mapper!.instance, isNull);
      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(0));
    });
    test('should process ClassWithIriMapperInstanceStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass('ClassWithIriMapperInstanceStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(
          result!.className.code, 'grptm.ClassWithIriMapperInstanceStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.template, isNull);
      expect(annotation.iri!.mapper, isNotNull);
      expect(annotation.iri!.mapper!.name, isNull);
      expect(annotation.iri!.mapper!.type, isNull);
      expect(annotation.iri!.mapper!.instance, isNotNull);
      expect(annotation.iri!.mapper!.instance!.type!.getDisplayString(),
          'TestIriMapper2');
      expect(annotation.iri!.mapper!.instance!.hasKnownValue, isTrue);
      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
    });
    test('should process ClassWithMapperNamedMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass('ClassWithMapperNamedMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(
          result!.className.code, 'grptm.ClassWithMapperNamedMapperStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, equals('testGlobalResourceMapper'));
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(0));
    });
    test('should process ClassWithMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass('ClassWithMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithMapperStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNotNull);
      expect(annotation.mapper!.type!.codeWithoutAlias,
          'TestGlobalResourceMapper');
      expect(annotation.mapper!.instance, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(0));
    });
    test('should process ClassWithMapperInstanceStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass('ClassWithMapperInstanceStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithMapperInstanceStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri, isNull);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNotNull);
      expect(annotation.mapper!.instance!.type!.getDisplayString(),
          'TestGlobalResourceMapper2');
      expect(annotation.mapper!.instance!.hasKnownValue, isTrue);
      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(0));
    });

    test('should process class with RdfGlobalResource annotation', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass('Book')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.Book');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaBook.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.classIri!.value, isA<IriTerm>());
      expect(annotation.iri, isA<IriStrategyInfo>());
    });

    test('should return null for class without RdfGlobalResource annotation',
        () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass('NotAnnotated')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNull);
    });

    test('should extract constructors', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass('Book')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.constructors, isNotEmpty);

      // Check that we have at least one constructor
      final defaultConstructor = result.constructors.firstWhere(
        (c) => c.name == '' || c.name == 'Book',
        orElse: () => throw StateError('No default constructor found'),
      );

      expect(defaultConstructor, isNotNull);
      expect(defaultConstructor.isConst, isFalse);
      expect(defaultConstructor.isFactory, isFalse);
    });

    test('should extract fields', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass('Book')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.properties, isNotEmpty);

      // Check that we have the expected fields
      final titleField = result.properties.firstWhere(
        (f) => f.name == 'title',
      );

      expect(titleField, isNotNull);
      expect(titleField.type.codeWithoutAlias, 'String');
      expect(titleField.isFinal, isTrue);
    });
    test('should process ClassWithIriMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass('ClassWithIriMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriMapperStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.mapper, isNotNull);
      final mapperType = annotation.iri!.mapper!.type;
      expect(mapperType, isNotNull);
      expect(mapperType.toString(), contains('TestIriMapper'));
      expect(annotation.iri!.mapper!.name, isNull);
      expect(annotation.iri!.mapper!.instance, isNull);
    });

    test('should process ClassWithIriMapperInstanceStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass('ClassWithIriMapperInstanceStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(
          result!.className.code, 'grptm.ClassWithIriMapperInstanceStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.mapper, isNotNull);
      final instance = annotation.iri!.mapper!.instance;
      expect(instance, isNotNull);
      expect(instance.toString(), contains('TestIriMapper'));
      expect(annotation.iri!.mapper!.name, isNull);
      expect(annotation.iri!.mapper!.type, isNull);
    });

    test('should process ClassWithIriNamedMapperStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass('ClassWithIriNamedMapperStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithIriNamedMapperStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.mapper, isNotNull);
      expect(annotation.iri!.mapper!.name, 'testMapper');
      expect(annotation.iri!.mapper!.type, isNull);
      expect(annotation.iri!.mapper!.instance, isNull);
    });
    test('should process ClassWithNoRdfType', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext, libraryElement.getClass('ClassWithNoRdfType')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'grptm.ClassWithNoRdfType');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri, isNull);
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.iri?.mapper, isNull);
      expect(annotation.iri?.template, '{+iri}');

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(3)); // iri, name, age
    });

    test('should process ClassWithIriTemplateAndContextVariableStrategy', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext,
          libraryElement
              .getClass('ClassWithIriTemplateAndContextVariableStrategy')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code,
          'grptm.ClassWithIriTemplateAndContextVariableStrategy');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.iri?.mapper, isNull);
      expect(annotation.iri?.template, equals('{+baseUri}/persons/{thisId}'));
      expect(annotation.iri?.templateInfo, isNotNull);
      expect(annotation.iri?.templateInfo?.isValid, isTrue);
      expect(annotation.iri?.templateInfo?.variables, contains('thisId'));
      expect(annotation.iri?.templateInfo?.variables, contains('baseUri'));
      expect(
          annotation.iri?.templateInfo?.propertyVariables.map((pn) => pn.name),
          contains('thisId'));
      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
    });
    test('should process ClassWithIriNamedMapperStrategy1Part', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass('ClassWithIriNamedMapperStrategy1Part')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(
          result!.className.code, 'grptm.ClassWithIriNamedMapperStrategy1Part');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isFalse);
      expect(annotation.mapper, isNull);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.template, isNull);
      expect(annotation.iri!.mapper, isNotNull);
      expect(annotation.iri!.mapper!.name, equals('testMapper1Part'));
      expect(annotation.iri!.mapper!.type, isNull);
      expect(annotation.iri!.mapper!.instance, isNull);
      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
    });

    test('should process ClassWithIriNamedMapperStrategy2Parts', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(validationContext,
          libraryElement.getClass('ClassWithIriNamedMapperStrategy2Parts')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code,
          'grptm.ClassWithIriNamedMapperStrategy2Parts');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isFalse);
      expect(annotation.mapper, isNull);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.template, isNull);
      expect(annotation.iri!.mapper, isNotNull);
      expect(annotation.iri!.mapper!.name, equals('testMapper2Parts'));
      expect(annotation.iri!.mapper!.type, isNull);
      expect(annotation.iri!.mapper!.instance, isNull);
      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(2));
    });

    test('should process ClassWithIriNamedMapperStrategy2PartsSwapped', () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext,
          libraryElement
              .getClass('ClassWithIriNamedMapperStrategy2PartsSwapped')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code,
          'grptm.ClassWithIriNamedMapperStrategy2PartsSwapped');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isFalse);
      expect(annotation.mapper, isNull);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.template, isNull);
      expect(annotation.iri!.mapper, isNotNull);
      expect(annotation.iri!.mapper!.name, equals('testMapper2PartsSwapped'));
      expect(annotation.iri!.mapper!.type, isNull);
      expect(annotation.iri!.mapper!.instance, isNull);
      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(2));
    });
    test('should process ClassWithIriNamedMapperStrategy2PartsWithProperties',
        () {
      // Act
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
          validationContext,
          libraryElement.getClass(
              'ClassWithIriNamedMapperStrategy2PartsWithProperties')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code,
          'grptm.ClassWithIriNamedMapperStrategy2PartsWithProperties');
      var annotation = result.annotation as RdfGlobalResourceInfo;
      expect(annotation.classIri!.value, equals(SchemaPerson.classIri));
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.iri, isNotNull);
      expect(annotation.iri!.template, isNull);
      expect(annotation.iri!.mapper, isNotNull);
      expect(annotation.iri!.mapper!.name, equals('testMapper3'));
      expect(annotation.iri!.mapper!.type, isNull);
      expect(annotation.iri!.mapper!.instance, isNull);
      expect(result.constructors, hasLength(1));
      expect(result.properties,
          hasLength(5)); // id, version, givenName, surname, age
    });
  });
}
