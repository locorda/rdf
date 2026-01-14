import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/iri_strategy_processor.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('Fragment Template Processing', () {
    late ClassElem sectionReferenceClass;
    late ClassElem pageClass;

    setUpAll(() async {
      final (libraryElement, _) =
          await analyzeTestFile('with_fragment_test_models.dart');
      sectionReferenceClass = libraryElement.getClass('SectionReference')!;
      pageClass = libraryElement.getClass('Page')!;
    });

    group('processTemplate with fragmentTemplate', () {
      test('should process base template and fragment template separately', () {
        final validationContext = ValidationContext();
        final iriParts =
            IriStrategyProcessor.findIriPartFields(sectionReferenceClass);

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          '{+documentIri}',
          iriParts,
          fragmentTemplate: 'section-{sectionId}',
        );

        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(validationContext.isValid, isTrue);
        expect(validationContext.errors, isEmpty);

        // Check that both templates are stored
        expect(result!.template, equals('{+documentIri}'));
        expect(result.fragmentTemplate, equals('section-{sectionId}'));

        // Check that variables from both templates are combined
        expect(result.variableNames.length, equals(2));
        final variableNames = result.variableNames.map((v) => v.name).toSet();
        expect(variableNames, containsAll(['documentIri', 'sectionId']));

        // Check property variables (only sectionId should be a property)
        expect(result.propertyVariables.length, equals(1));
        expect(result.propertyVariables.first.name, equals('sectionId'));
        expect(result.propertyVariables.first.dartPropertyName,
            equals('sectionId'));

        // Check context variables (documentIri should be a context variable)
        expect(result.contextVariableNames.length, equals(1));
        expect(result.contextVariableNames.first.name, equals('documentIri'));
      });

      test('should validate base template with absolute URI requirement', () {
        final validationContext = ValidationContext();
        final iriParts =
            IriStrategyProcessor.findIriPartFields(sectionReferenceClass);

        // Relative URI in base template should produce warning
        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          'relative/path',
          iriParts,
          fragmentTemplate: 'section-{sectionId}',
        );

        expect(result, isNotNull);
        // Should have warnings about relative URI in base template
        expect(validationContext.warnings, isNotEmpty);
        expect(
            validationContext.warnings.any((w) =>
                w.contains('relative URI') || w.contains('relative/path')),
            isTrue);
      });

      test('should allow relative fragment template', () {
        final validationContext = ValidationContext();
        final iriParts =
            IriStrategyProcessor.findIriPartFields(sectionReferenceClass);

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          '{+documentIri}',
          iriParts,
          fragmentTemplate: 'relative-fragment',
        );

        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(validationContext.isValid, isTrue);
        // Fragment templates can be relative - no warnings expected
      });

      test('should reject empty fragment template', () {
        final validationContext = ValidationContext();
        final iriParts =
            IriStrategyProcessor.findIriPartFields(sectionReferenceClass);

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          '{+documentIri}',
          iriParts,
          fragmentTemplate: '',
        );

        expect(result, isNull);
        expect(validationContext.isValid, isFalse);
        expect(validationContext.errors,
            contains('Fragment template cannot be empty'));
      });

      test('should combine variables from both templates', () {
        final validationContext = ValidationContext();
        final iriParts =
            IriStrategyProcessor.findIriPartFields(sectionReferenceClass);

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          'http://example.org/docs/{docId}',
          iriParts,
          fragmentTemplate: 'section-{sectionId}',
        );

        validationContext.throwIfErrors();

        expect(result, isNotNull);

        // Both variables should be present
        final variableNames = result!.variableNames.map((v) => v.name).toSet();
        expect(variableNames, containsAll(['docId', 'sectionId']));
      });

      test(
          'should only warn about unused @RdfIriPart if unused in both templates',
          () {
        final validationContext = ValidationContext();
        // Create fake IRI parts including one that's not used
        final iriParts = [
          IriPartInfo(
            name: 'sectionId',
            dartPropertyName: 'sectionId',
            type: Code.coreType('String'),
            pos: 0,
            isMappedValue: false,
          ),
          IriPartInfo(
            name: 'unusedPart',
            dartPropertyName: 'unusedPart',
            type: Code.coreType('String'),
            pos: 1,
            isMappedValue: false,
          ),
        ];

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          '{+documentIri}',
          iriParts,
          fragmentTemplate: 'section-{sectionId}',
        );

        expect(result, isNotNull);

        // Should warn about unusedPart since it's not in either template
        expect(validationContext.warnings, isNotEmpty);
        expect(
            validationContext.warnings
                .any((w) => w.contains('unusedPart') && w.contains('not used')),
            isTrue);
      });

      test('should not warn if @RdfIriPart is used in fragment template', () {
        final validationContext = ValidationContext();
        final iriParts = [
          IriPartInfo(
            name: 'sectionId',
            dartPropertyName: 'sectionId',
            type: Code.coreType('String'),
            pos: 0,
            isMappedValue: false,
          ),
        ];

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          '{+documentIri}',
          iriParts,
          fragmentTemplate: 'section-{sectionId}',
        );

        expect(result, isNotNull);
        validationContext.throwIfErrors();

        // No warning about sectionId since it's used in fragment template
        expect(validationContext.warnings.any((w) => w.contains('sectionId')),
            isFalse);
      });

      test('should not warn if @RdfIriPart is used in base template', () {
        final validationContext = ValidationContext();
        final iriParts = [
          IriPartInfo(
            name: 'docId',
            dartPropertyName: 'docId',
            type: Code.coreType('String'),
            pos: 0,
            isMappedValue: false,
          ),
        ];

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          'http://example.org/docs/{docId}',
          iriParts,
          fragmentTemplate: 'section-default',
        );

        expect(result, isNotNull);
        validationContext.throwIfErrors();

        // No warning about docId since it's used in base template
        expect(validationContext.warnings.any((w) => w.contains('docId')),
            isFalse);
      });

      test('should process fragment template with multiple variables', () {
        final validationContext = ValidationContext();
        final iriParts = [
          IriPartInfo(
            name: 'chapterId',
            dartPropertyName: 'chapterId',
            type: Code.coreType('String'),
            pos: 0,
            isMappedValue: false,
          ),
          IriPartInfo(
            name: 'sectionId',
            dartPropertyName: 'sectionId',
            type: Code.coreType('String'),
            pos: 1,
            isMappedValue: false,
          ),
        ];

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          '{+documentIri}',
          iriParts,
          fragmentTemplate: 'chapter-{chapterId}-section-{sectionId}',
        );

        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.fragmentTemplate,
            equals('chapter-{chapterId}-section-{sectionId}'));

        // Both fragment variables should be present
        final variableNames = result.variableNames.map((v) => v.name).toSet();
        expect(variableNames, containsAll(['chapterId', 'sectionId']));
      });

      test('should handle reserved expansion {+var} in fragment template', () {
        final validationContext = ValidationContext();
        final iriParts = [
          IriPartInfo(
            name: 'fragmentPath',
            dartPropertyName: 'fragmentPath',
            type: Code.coreType('String'),
            pos: 0,
            isMappedValue: false,
          ),
        ];

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          '{+baseUri}',
          iriParts,
          fragmentTemplate: '{+fragmentPath}',
        );

        validationContext.throwIfErrors();

        expect(result, isNotNull);

        // Check that the reserved expansion variable is recognized
        final fragmentVar =
            result!.variableNames.firstWhere((v) => v.name == 'fragmentPath');
        expect(fragmentVar.canBeUri, isTrue);
      });
    });

    group('processTemplate without fragmentTemplate', () {
      test('should work as before for templates without fragments', () {
        final validationContext = ValidationContext();
        final iriParts = IriStrategyProcessor.findIriPartFields(pageClass);

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          'http://example.org/pages/{pageId}',
          iriParts,
        );

        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.fragmentTemplate, isNull);
      });

      test('should handle null fragmentTemplate parameter', () {
        final validationContext = ValidationContext();
        final iriParts = IriStrategyProcessor.findIriPartFields(pageClass);

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          'http://example.org/pages/{pageId}',
          iriParts,
          fragmentTemplate: null,
        );

        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.fragmentTemplate, isNull);
      });
    });

    group('Edge Cases', () {
      test('should handle fragment template with special characters', () {
        final validationContext = ValidationContext();
        final iriParts = [
          IriPartInfo(
            name: 'sectionId',
            dartPropertyName: 'sectionId',
            type: Code.coreType('String'),
            pos: 0,
            isMappedValue: false,
          ),
        ];

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          '{+baseUri}',
          iriParts,
          fragmentTemplate: 'section_{sectionId}_overview',
        );

        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(
            result!.fragmentTemplate, equals('section_{sectionId}_overview'));
      });

      test('should handle fragment template with URL-encoded characters', () {
        final validationContext = ValidationContext();
        final iriParts = [
          IriPartInfo(
            name: 'sectionId',
            dartPropertyName: 'sectionId',
            type: Code.coreType('String'),
            pos: 0,
            isMappedValue: false,
          ),
        ];

        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          '{+baseUri}',
          iriParts,
          fragmentTemplate: 'section%20{sectionId}',
        );

        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.fragmentTemplate, equals('section%20{sectionId}'));
      });

      test('should validate variable syntax in fragment template', () {
        final validationContext = ValidationContext();
        final iriParts = [
          IriPartInfo(
            name: 'sectionId',
            dartPropertyName: 'sectionId',
            type: Code.coreType('String'),
            pos: 0,
            isMappedValue: false,
          ),
        ];

        // Invalid syntax - unclosed brace
        final result = IriStrategyProcessor.processTemplate(
          validationContext,
          '{+baseUri}',
          iriParts,
          fragmentTemplate: 'section-{sectionId',
        );

        // Should have validation errors for invalid syntax
        expect(result, isNotNull);
        expect(result!.isValid, isFalse);
        expect(validationContext.errors, isNotEmpty);
      });
    });
  });
}
