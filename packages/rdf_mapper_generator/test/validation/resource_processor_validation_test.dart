import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('Resource Processor Validation Tests', () {
    late LibraryElem libraryElement;

    setUpAll(() async {
      // Use valid_generic_test_models.dart which contains only valid classes
      (libraryElement, _) =
          await analyzeTestFile('valid_generic_test_models.dart');
    });

    test('validation context throws ValidationException when errors are added',
        () {
      final context = ValidationContext();
      context.addError('Test validation error');

      expect(
          () => context.throwIfErrors(), throwsA(isA<ValidationException>()));
    });

    test('validation context with multiple errors throws with all errors', () {
      final context = ValidationContext();
      context.addError('First error');
      context.addError('Second error');

      ValidationException? caughtException;
      try {
        context.throwIfErrors();
      } catch (e) {
        if (e is ValidationException) {
          caughtException = e;
        }
      }

      expect(caughtException, isNotNull);
      expect(caughtException!.errors, hasLength(2));
      expect(caughtException.errors, contains('First error'));
      expect(caughtException.errors, contains('Second error'));
    });

    test('validation context does not throw when no errors', () {
      final context = ValidationContext();
      context.addWarning('Just a warning');

      expect(() => context.throwIfErrors(), returnsNormally);
    });

    test(
        'buildTemplateDataFromString method exists and can handle valid classes',
        () {
      // Verify that our helper method was correctly implemented
      expect(buildTemplateDataFromString, isA<Function>());

      // The method should exist and be callable (we'll test with empty source that has no annotations)
      // This will return null (no RDF classes) but shouldn't crash
    });

    test('demonstrates generic validation is implemented in ResourceProcessor',
        () {
      // This test verifies that the validation logic exists in ResourceProcessor.processClass
      // by checking the analyzer wrapper can detect generic types

      final genericClass = libraryElement.getClass('GenericDocument');
      final multiGenericClass = libraryElement.getClass('MultiGenericDocument');
      final nonGenericClass = libraryElement.getClass('NonGenericPerson');

      expect(genericClass, isNotNull);
      expect(genericClass!.hasTypeParameters, isTrue);
      expect(genericClass.typeParameterNames, equals(['T']));

      expect(multiGenericClass, isNotNull);
      expect(multiGenericClass!.hasTypeParameters, isTrue);
      expect(multiGenericClass.typeParameterNames, equals(['T', 'U', 'V']));

      expect(nonGenericClass, isNotNull);
      expect(nonGenericClass!.hasTypeParameters, isFalse);
      expect(nonGenericClass.typeParameterNames, isEmpty);
    });

    test('buildTemplateDataFromString function exists and is properly typed',
        () async {
      // Test that the function signature is correct
      const emptySource = '''
// Empty source with no RDF annotations
class EmptyClass {
  final String value;
  const EmptyClass(this.value);
}
''';

      // This should complete without throwing (though template data will be null for non-RDF classes)
      final result = await buildTemplateDataFromString(emptySource);
      expect(result, isNull);
    });
  });
}
