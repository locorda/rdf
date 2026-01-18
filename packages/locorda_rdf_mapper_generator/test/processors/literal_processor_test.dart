// import 'package:analyzer/dart/element/element2.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/literal_processor.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('LiteralProcessor', () {
    late LibraryElem libraryElement;

    setUpAll(() async {
      (libraryElement, _) =
          await analyzeTestFile('literal_processor_test_models.dart');
    });

    test('should process LiteralString', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass('LiteralString')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.LiteralString');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].isRdfValue, isTrue);
      expect(result.constructors[0].parameters[0].isRdfLanguageTag, isFalse);
      expect(result.constructors[0].parameters[0].isIriPart, isFalse);
      expect(result.constructors[0].parameters[0].name, 'foo');
    });

    test('should process Rating', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass('Rating')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.Rating');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.datatype, isNull);
      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].isRdfValue, isTrue);
      expect(result.constructors[0].parameters[0].isRdfLanguageTag, isFalse);
      expect(result.constructors[0].parameters[0].name, 'stars');
    });

    test('should process LocalizedText with language tag', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass('LocalizedText')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.LocalizedText');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.datatype, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(2));
      expect(result.constructors[0].parameters, hasLength(2));

      // Check for RdfValue parameter
      final valueParam =
          result.constructors[0].parameters.firstWhere((p) => p.isRdfValue);
      expect(valueParam.name, 'text');
      expect(valueParam.isRdfLanguageTag, isFalse);

      // Check for RdfLanguageTag parameter
      final languageParam = result.constructors[0].parameters
          .firstWhere((p) => p.isRdfLanguageTag);
      expect(languageParam.name, 'language');
      expect(languageParam.isRdfValue, isFalse);
    });

    test('should process LiteralDouble with XSD datatype', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass('LiteralDouble')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.LiteralDouble');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.datatype, isNotNull);
      expect(
          annotation.datatype!.code.resolveAliases(knownImports: {
            'package:locorda_rdf_terms_core/src/vocab/generated/xsd.dart': ''
          }).$1,
          'Xsd.double');
      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].isRdfValue, isTrue);
      expect(result.constructors[0].parameters[0].name, 'foo');
    });

    test('should process LiteralInteger with XSD datatype', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass('LiteralInteger')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.LiteralInteger');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.datatype, isNotNull);
      expect(
          annotation.datatype!.code.resolveAliases(knownImports: {
            'package:locorda_rdf_terms_core/src/vocab/generated/xsd.dart': ''
          }).$1,
          'Xsd.integer');
      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].isRdfValue, isTrue);
      expect(result.constructors[0].parameters[0].name, 'value');
    });

    test('should process Temperature with custom methods', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass('Temperature')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.Temperature');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.datatype, isNull);
      expect(annotation.toLiteralTermMethod, 'formatCelsius');
      expect(annotation.fromLiteralTermMethod, 'parse');

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].name, 'celsius');
    });

    test('should process CustomLocalizedText with custom methods', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass('CustomLocalizedText')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.CustomLocalizedText');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.datatype, isNull);
      expect(annotation.toLiteralTermMethod, 'toRdf');
      expect(annotation.fromLiteralTermMethod, 'fromRdf');

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(2));
      expect(result.constructors[0].parameters, hasLength(2));
      expect(result.constructors[0].parameters[0].name, 'text');
      expect(result.constructors[0].parameters[1].name, 'language');
    });

    test('should process DoubleAsMilliunit with custom methods', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass('DoubleAsMilliunit')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.DoubleAsMilliunit');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNull);
      expect(annotation.datatype?.value, Xsd.int);
      expect(annotation.toLiteralTermMethod, 'toMilliunit');
      expect(annotation.fromLiteralTermMethod, 'fromMilliunit');

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].name, 'value');
    });

    test('should process LiteralWithNamedMapper', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(validationContext,
          libraryElement.getClass('LiteralWithNamedMapper')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.LiteralWithNamedMapper');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, 'testLiteralMapper');
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNull);
      expect(annotation.datatype, isNull);
      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].name, 'value');
    });

    test('should process LiteralWithMapper', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(
          validationContext, libraryElement.getClass('LiteralWithMapper')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.LiteralWithMapper');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNotNull);
      expect(annotation.mapper!.type!.codeWithoutAlias, 'TestLiteralMapper');
      expect(annotation.mapper!.instance, isNull);
      expect(annotation.datatype, isNull);
      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].name, 'value');
    });

    test('should process LiteralWithMapperInstance', () {
      // Act
      final validationContext = ValidationContext();
      final result = LiteralProcessor.processClass(validationContext,
          libraryElement.getClass('LiteralWithMapperInstance')!);
      validationContext.throwIfErrors();

      // Assert
      expect(result, isNotNull);
      expect(result!.className.code, 'lptm.LiteralWithMapperInstance');
      var annotation = result.annotation;
      expect(annotation.registerGlobally, isTrue);
      expect(annotation.mapper, isNotNull);
      expect(annotation.mapper!.name, isNull);
      expect(annotation.mapper!.type, isNull);
      expect(annotation.mapper!.instance, isNotNull);
      expect(annotation.mapper!.instance!.type!.getDisplayString(),
          'TestLiteralMapper2');
      expect(annotation.mapper!.instance!.hasKnownValue, isTrue);
      expect(annotation.datatype, isNull);
      expect(annotation.toLiteralTermMethod, isNull);
      expect(annotation.fromLiteralTermMethod, isNull);

      expect(result.constructors, hasLength(1));
      expect(result.properties, hasLength(1));
      expect(result.constructors[0].parameters, hasLength(1));
      expect(result.constructors[0].parameters[0].name, 'value');
    });
  });
}
