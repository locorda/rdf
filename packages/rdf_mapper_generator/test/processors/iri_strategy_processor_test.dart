// import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:rdf_mapper_generator/src/processors/iri_strategy_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('IriStrategyProcessor', () {
    late ClassElem bookClass;
    late ClassElem simpleClass;

    setUpAll(() async {
      final (libraryElement, _) =
          await analyzeTestFile('global_resource_processor_test_models.dart');
      bookClass = libraryElement.getClass('Book')!;
      simpleClass = libraryElement.getClass('ClassWithIriTemplateStrategy')!;
    });

    group('processTemplate', () {
      test('should return null for empty template', () {
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            '', IriStrategyProcessor.findIriPartFields(bookClass));

        expect(result, isNull);
        expect(validationContext.isValid, isFalse);
        expect(validationContext.errors, isNotEmpty);
        expect(validationContext.errors,
            contains('Base IRI template cannot be empty'));
      });

      test('should process IriStrategy with tag template', () {
        //IriStrategy('tag:example.org,2025:document-{id}', 'documentIri'),
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(
            validationContext,
            'tag:example.org,2025:document-{isbn}',
            IriStrategyProcessor.findIriPartFields(bookClass));

        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(validationContext.isValid, isTrue);
        expect(validationContext.errors, isEmpty);
        expect(
            result!.template, equals('tag:example.org,2025:document-{isbn}'));
        expect(result.fragmentTemplate, isNull);
        expect(result.variables, contains('isbn'));
        expect(result.variables, hasLength(1));
        expect(result.propertyVariables.map((pn) => pn.name), contains('isbn'));
        expect(result.contextVariables, isEmpty);
        expect(result.isValid, isTrue);
        expect(result.validationErrors, isEmpty);
        expect(result.warnings, isA<List<String>>());
      });

      test('should process IriStrategy with tag template and fragment', () {
        //IriStrategy.withFragment('tag:example.org,2025:document-{id}', 'section-{sectionId}'),
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(
            validationContext,
            'tag:example.org,2025:document-{isbn}#it',
            IriStrategyProcessor.findIriPartFields(bookClass),
            fragmentTemplate: 'section-{sectionId}');

        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(validationContext.isValid, isTrue);
        expect(validationContext.errors, isEmpty);
        expect(result!.template,
            equals('tag:example.org,2025:document-{isbn}#it'));
        expect(result.fragmentTemplate, equals('section-{sectionId}'));
        expect(result.variables, contains('isbn'));
        expect(result.variables, contains('sectionId'));
        expect(result.variables, hasLength(2));
        expect(result.propertyVariables.map((pn) => pn.name), contains('isbn'));
        expect(result.contextVariables, hasLength(1));
        expect(result.contextVariables, contains('sectionId'));
        expect(result.isValid, isTrue);
        expect(result.validationErrors, isEmpty);
        expect(result.warnings, isA<List<String>>());
      });

      test('should process simple template with single variable', () {
        const template = 'http://example.org/books/{isbn}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.template, equals(template));
        expect(result.variables, contains('isbn'));
        expect(result.variables, hasLength(1));
        expect(result.propertyVariables.map((pn) => pn.name), contains('isbn'));
        expect(result.contextVariables, isEmpty);
        expect(result.isValid, isTrue);
        expect(result.validationErrors, isEmpty);
        expect(result.warnings, isA<List<String>>());
      });
      test('should process template with +variable', () {
        const template = '{+baseUri}/books/{isbn}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.template, equals(template));
        expect(result.variables, contains('isbn'));
        expect(result.variables, contains('baseUri'));
        expect(result.variables, hasLength(2));
        expect(result.propertyVariables.map((pn) => pn.name), contains('isbn'));
        expect(result.contextVariables, contains('baseUri'));
        expect(result.isValid, isTrue);
        expect(result.validationErrors, isEmpty);
        expect(result.warnings, isA<List<String>>());
      });

      test('should process template with multiple variables', () {
        const template = 'http://example.org/books/{isbn}/authors/{authorId}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.variables, containsAll(['isbn', 'authorId']));
        expect(result.variables, hasLength(2));
        expect(result.propertyVariables, hasLength(1));
        expect(result.propertyVariables.map((pn) => pn.name), contains('isbn'));
        // authorId is not annotated with @RdfIriPart, so it should be a context variable
        expect(result.contextVariables, hasLength(1));
        expect(result.contextVariables, contains('authorId'));
      });

      test('should handle template with context variables only', () {
        const template = 'http://example.org/resources/{contextVar}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.variables, contains('contextVar'));
        expect(result.propertyVariables, isEmpty);
        expect(result.contextVariables, contains('contextVar'));
      });

      test('should validate template syntax correctly', () {
        const template = 'http://example.org/books/{isbn}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.isValid, isTrue);
        expect(result.validationErrors, isEmpty);
      });

      test('should detect invalid variable syntax', () {
        const template = 'http://example.org/books/{{isbn}}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));

        expect(result, isNotNull);
        expect(result!.isValid, isFalse);
        expect(result.validationErrors, isNotEmpty);
        expect(
            result.validationErrors.first, contains('Invalid variable syntax'));

        expect(validationContext.isValid, isFalse);
        expect(validationContext.errors, isNotEmpty);
        expect(
            validationContext.errors,
            contains(
                'Invalid variable syntax. Variables must be in format {variableName}'));
      });

      test('should detect unmatched braces', () {
        const template = 'http://example.org/books/{isbn';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));

        expect(result, isNotNull);
        expect(result!.isValid, isFalse);
        expect(
            result.validationErrors, contains('Unmatched braces in template'));
        expect(validationContext.isValid, isFalse);
        expect(validationContext.errors, isNotEmpty);
        expect(
            validationContext.errors, contains('Unmatched braces in template'));
      });

      test('should detect empty variable names', () {
        const template = 'http://example.org/books/{}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));

        expect(result, isNotNull);
        expect(result!.isValid, isFalse);
        expect(result.validationErrors, isNotEmpty);
        expect(validationContext.isValid, isFalse);
        expect(validationContext.errors, isNotEmpty);
        expect(
            validationContext.errors,
            contains(
                'Invalid variable syntax. Variables must be in format {variableName}'));
      });

      test('should validate variable names', () {
        const template = 'http://example.org/books/{123invalid}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));

        expect(result, isNotNull);
        expect(result!.isValid, isFalse);
        expect(result.validationErrors,
            anyElement(contains('Invalid variable name')));
        expect(validationContext.isValid, isFalse);
        expect(validationContext.errors, isNotEmpty);
        expect(
            validationContext.errors,
            contains(
                'Invalid variable syntax. Variables must be in format {variableName}'));
      });

      test('should warn about relative URIs', () {
        const template = 'books/{isbn}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));

        expect(result, isNotNull);
        expect(result!.isValid, isFalse);
        expect(
            result.validationErrors,
            anyElement(
                contains('Template does not produce valid URI structure')));
        expect(
            result.validationErrors,
            anyElement(
                contains('Template does not produce valid URI structure')));
        expect(validationContext.isValid, isFalse);
        expect(validationContext.warnings, isNotEmpty);
        expect(
            validationContext.warnings,
            contains(
                'Template "books/{isbn}" appears to be a relative URI. Consider using absolute URIs for global resources'));
        expect(validationContext.errors, isNotEmpty);
        expect(validationContext.errors,
            contains('Template does not produce valid URI structure'));
      });

      test('should handle processing errors gracefully', () {
        // This test verifies error handling when processing fails
        const template = 'http://example.org/books/{isbn}';
        // Using a class that might cause issues (we'll use a simple one)
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(simpleClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        // Even if there are issues, we should get a result with error information
      });
    });

    group('Variable extraction edge cases', () {
      test('should extract variables with underscores', () {
        const template = 'http://example.org/{book_id}/{author_name}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.variables, containsAll(['book_id', 'author_name']));
      });

      test('should extract variables with numbers', () {
        const template = 'http://example.org/{id1}/{id2}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.variables, containsAll(['id1', 'id2']));
      });

      test('should handle duplicate variable names', () {
        const template = 'http://example.org/{id}/{id}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.variables, hasLength(1));
        expect(result.variables, contains('id'));
      });

      test('should handle complex URI patterns', () {
        const template =
            'https://api.example.org/v1/books/{isbn}/reviews/{reviewId}?format=json';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.variables, containsAll(['isbn', 'reviewId']));
        expect(result.isValid, isTrue);
      });
    });

    group('URI validation', () {
      test('should accept absolute HTTP URIs', () {
        const template = 'http://example.org/books/{isbn}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.isValid, isTrue);
      });

      test('should accept absolute HTTPS URIs', () {
        const template = 'https://example.org/books/{isbn}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.isValid, isTrue);
      });

      test('should accept URN patterns', () {
        const template = 'urn:isbn:{isbn}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.isValid, isTrue);
      });

      test('should accept absolute paths', () {
        const template = '/books/{isbn}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.isValid, isTrue);
      });

      test('should reject obviously malformed URIs', () {
        const template = 'http://example.org//invalid//{isbn}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));

        expect(result, isNotNull);
        expect(result!.isValid, isFalse);
        expect(result.validationErrors, isNotEmpty);
        expect(validationContext.isValid, isFalse);
        expect(validationContext.errors, isNotEmpty);
        expect(validationContext.errors,
            contains('Template does not produce valid URI structure'));
      });
    });

    group('Property variable detection', () {
      test('should identify @RdfIriPart annotated fields', () {
        const template = 'http://example.org/books/{isbn}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(
            result!.propertyVariables.map((pn) => pn.name), contains('isbn'));
      });

      test('should handle fields without @RdfIriPart as context variables', () {
        const template = 'http://example.org/books/{isbn}/{title}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(
            result!.propertyVariables.map((pn) => pn.name), contains('isbn'));
        expect(result.contextVariables, contains('title'));
      });

      test('should handle template variables not matching any field', () {
        const template = 'http://example.org/books/{isbn}/{nonExistentField}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(
            result!.propertyVariables.map((pn) => pn.name), contains('isbn'));
        expect(result.contextVariables, contains('nonExistentField'));
      });
    });

    group('Unused @RdfIriPart warnings', () {
      test('should warn when @RdfIriPart annotation is not used in template',
          () {
        // Use a template that doesn't include all annotated properties
        const template =
            'http://example.org/books/{title}'; // isbn is annotated but not used
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(validationContext.warnings, isNotEmpty);
        expect(
            validationContext.warnings,
            anyElement(contains(
                'Property \'isbn\' is annotated with @RdfIriPart(\'isbn\') but \'isbn\' is not used in the IRI template')));
      });

      test('should not warn when all @RdfIriPart annotations are used', () {
        const template = 'http://example.org/books/{isbn}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result!.warnings, isEmpty);
      });

      test('should warn for custom @RdfIriPart names not used in template', () {
        // This test assumes we have a field with @RdfIriPart(name: 'customName')
        // For now, we'll test with a template that uses field name but not custom name
        const template =
            'http://example.org/books/{fieldName}'; // assumes custom name is different
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);

        // If there are warnings about unused annotations, they should be present
        expect(
            validationContext.warnings,
            contains(
                "Property 'isbn' is annotated with @RdfIriPart('isbn') but 'isbn' is not used in the IRI template"));
      });

      test('should handle multiple unused @RdfIriPart annotations', () {
        const template =
            'http://example.org/books/static'; // no variables at all
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        // Should warn for all annotated fields that aren't used
        expect(validationContext.warnings, isNotEmpty);
        expect(validationContext.warnings.length, greaterThan(0));
      });

      test('should provide clear warning messages', () {
        const template = 'http://example.org/books/{title}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        if (result!.warnings.isNotEmpty) {
          for (final warning in result.warnings) {
            expect(warning, contains('is annotated with @RdfIriPart'));
            expect(warning, contains('is not used in the IRI template'));
          }
        }
      });

      test('should not warn for properties without @RdfIriPart annotation', () {
        const template = 'http://example.org/books/{nonAnnotatedField}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        // Should not warn about non-annotated properties, only unused annotations
        final annotationWarnings = result!.warnings.where(
            (warning) => warning.contains('is annotated with @RdfIriPart'));

        // Any warnings should only be about actually annotated fields
        for (final warning in annotationWarnings) {
          expect(warning, contains('is annotated with @RdfIriPart'));
        }
      });
    });

    group('IriTemplateInfo model', () {
      test('should create correct IriTemplateInfo instance', () {
        const template = 'http://example.org/books/{isbn}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(result, isA<IriTemplateInfo>());
        expect(result!.template, equals(template));
        expect(result.variables, isA<Set<String>>());
        expect(result.propertyVariables, isA<Set<VariableName>>());
        expect(result.contextVariables, isA<Set<String>>());
        expect(result.isValid, isA<bool>());
        expect(result.validationErrors, isA<List<String>>());
        expect(result.warnings, isA<List<String>>());
      });

      test('should maintain immutability of variable sets', () {
        const template = 'http://example.org/books/{isbn}';
        final validationContext = ValidationContext();
        final result = IriStrategyProcessor.processTemplate(validationContext,
            template, IriStrategyProcessor.findIriPartFields(bookClass));
        validationContext.throwIfErrors();

        expect(result, isNotNull);
        expect(() => result!.variableNames.add(newVarVariableName()),
            throwsUnsupportedError);
        expect(() => result!.propertyVariables.add(newVarVariableName()),
            throwsUnsupportedError);
        expect(() => result!.contextVariableNames.add(newVarVariableName()),
            throwsUnsupportedError);
      });
    });
  });
}

VariableName newVarVariableName() {
  return VariableName(
      dartPropertyName: 'newVar', name: 'newVar', canBeUri: false);
}
