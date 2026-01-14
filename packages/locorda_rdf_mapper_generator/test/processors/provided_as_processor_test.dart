import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/iri_strategy_processor.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/processor_utils.dart'
    hide isNull;
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('ProvidedAs Feature - Processor Tests', () {
    late ClassElem documentClass;
    late ClassElem sectionClass;

    setUpAll(() async {
      final (libraryElement, _) =
          await analyzeTestFile('provided_as_test_models.dart');
      documentClass = libraryElement.getClass('Document')!;
      sectionClass = libraryElement.getClass('Section')!;
    });

    group('IriStrategyInfo extraction', () {
      test('should extract providedAs from IriStrategy', () {
        final validationContext = ValidationContext();
        final annotation =
            getAnnotation(documentClass.annotations, 'RdfGlobalResource');

        expect(annotation, isNotNull);

        final iriValue = getField(annotation!, 'iri');
        expect(iriValue, isNotNull);

        final iriStrategyInfo = IriStrategyProcessor.processIriStrategy(
          validationContext,
          iriValue!,
          documentClass,
        );

        validationContext.throwIfErrors();

        expect(iriStrategyInfo, isNotNull);
        expect(iriStrategyInfo!.providedAs, equals('documentIri'));
        expect(
            iriStrategyInfo.template, equals('{+baseUri}/documents/{docId}'));
      });

      test('should handle IriStrategy without providedAs', () {
        final validationContext = ValidationContext();
        final annotation =
            getAnnotation(sectionClass.annotations, 'RdfGlobalResource');

        expect(annotation, isNotNull);

        final iriValue = getField(annotation!, 'iri');
        expect(iriValue, isNotNull);

        final iriStrategyInfo = IriStrategyProcessor.processIriStrategy(
          validationContext,
          iriValue!,
          sectionClass,
        );

        validationContext.throwIfErrors();

        expect(iriStrategyInfo, isNotNull);
        expect(iriStrategyInfo!.providedAs, isNull);
        expect(iriStrategyInfo.template,
            equals('{+documentIri}/sections/{sectionId}'));
      });

      test('should handle template with providedAs context variable', () {
        final validationContext = ValidationContext();
        final annotation =
            getAnnotation(sectionClass.annotations, 'RdfGlobalResource');

        expect(annotation, isNotNull);

        final iriValue = getField(annotation!, 'iri');
        final iriStrategyInfo = IriStrategyProcessor.processIriStrategy(
          validationContext,
          iriValue!,
          sectionClass,
        );

        validationContext.throwIfErrors();

        expect(iriStrategyInfo, isNotNull);
        expect(iriStrategyInfo!.templateInfo, isNotNull);
        expect(iriStrategyInfo.templateInfo!.contextVariables,
            contains('documentIri'));
        expect(iriStrategyInfo.templateInfo!.propertyVariables,
            hasLength(1)); // only sectionId
      });
    });

    group('Template processing with providedAs variables', () {
      test('should recognize providedAs variable as context variable', () {
        const template = '{+documentIri}/sections/{sectionId}';
        final validationContext = ValidationContext();
        final iriParts = IriStrategyProcessor.findIriPartFields(sectionClass);

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          template,
          iriParts,
        );

        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.contextVariables, contains('documentIri'));
        expect(
            result.propertyVariables.map((v) => v.name), contains('sectionId'));
        expect(result.isValid, isTrue);
      });

      test('should handle complex hierarchy with multiple providedAs levels',
          () {
        // Even though we only have two levels in our test models,
        // the template processor should handle the variables correctly
        const template = '{+documentIri}/subsections/{subId}';
        final validationContext = ValidationContext();
        final iriParts = IriStrategyProcessor.findIriPartFields(sectionClass);

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          template,
          iriParts,
        );

        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.contextVariables, contains('documentIri'));
        // subId is not in iriParts, so it should also be a context variable
        expect(result.contextVariables, contains('subId'));
      });
    });

    group('Validation', () {
      test('should accept valid providedAs identifier', () {
        final validationContext = ValidationContext();
        final annotation =
            getAnnotation(documentClass.annotations, 'RdfGlobalResource');

        final iriValue = getField(annotation!, 'iri');
        final iriStrategyInfo = IriStrategyProcessor.processIriStrategy(
          validationContext,
          iriValue!,
          documentClass,
        );

        expect(validationContext.errors, isEmpty);
        expect(iriStrategyInfo!.providedAs, equals('documentIri'));
      });
    });
  });
}
