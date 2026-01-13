import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:rdf_mapper_generator/src/processors/resource_processor.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('ResourceProcessor Generic Type Tests', () {
    late LibraryElem libraryElement;

    setUpAll(() async {
      (libraryElement, _) =
          await analyzeTestFile('valid_generic_test_models.dart');
    });

    test('allows generic class with registerGlobally=false', () {
      final context = ValidationContext();
      final result = ResourceProcessor.processClass(
          context, libraryElement.getClass('GenericDocument')!);

      expect(result, isNotNull);
      expect(result!.typeParameters, equals(['T']));
      expect(result.annotation.registerGlobally, isFalse);
      expect(context.errors, isEmpty);
    });

    // Note: Validation tests for invalid generic classes (registerGlobally=true) are handled
    // through integration tests since string-based testing can't resolve external package imports
    // The validation logic is confirmed to work in resource_processor.dart:81-87

    test('handles multiple type parameters', () {
      final context = ValidationContext();
      final result = ResourceProcessor.processClass(
          context, libraryElement.getClass('MultiGenericDocument')!);

      expect(result, isNotNull);
      expect(result!.typeParameters, equals(['T', 'U', 'V']));
      expect(result.annotation.registerGlobally, isFalse);
      expect(context.errors, isEmpty);
    });

    test('allows non-generic class with registerGlobally=true', () {
      final context = ValidationContext();
      final result = ResourceProcessor.processClass(
          context, libraryElement.getClass('NonGenericPerson')!);

      expect(result, isNotNull);
      expect(result!.typeParameters, isEmpty);
      expect(result.annotation.registerGlobally, isTrue);
      expect(context.errors, isEmpty);
    });

    test('handles generic local resource class', () {
      final context = ValidationContext();
      final result = ResourceProcessor.processClass(
          context, libraryElement.getClass('GenericLocalResource')!);

      expect(result, isNotNull);
      expect(result!.typeParameters, equals(['T']));
      expect(result.annotation.registerGlobally, isFalse);
      expect(context.errors, isEmpty);
    });

    // Validation for invalid local resource classes is also handled through integration tests

    test('extracts type parameters correctly from classes', () {
      // Test single type parameter
      final singleGeneric = libraryElement.getClass('GenericDocument')!;
      expect(singleGeneric.hasTypeParameters, isTrue);
      expect(singleGeneric.typeParameterNames, equals(['T']));

      // Test multiple type parameters
      final multiGeneric = libraryElement.getClass('MultiGenericDocument')!;
      expect(multiGeneric.hasTypeParameters, isTrue);
      expect(multiGeneric.typeParameterNames, equals(['T', 'U', 'V']));

      // Test non-generic class
      final nonGeneric = libraryElement.getClass('NonGenericPerson')!;
      expect(nonGeneric.hasTypeParameters, isFalse);
      expect(nonGeneric.typeParameterNames, isEmpty);
    });
  });
}
