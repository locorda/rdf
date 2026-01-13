import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

void main() {
  group('ValidationException Tests', () {
    test('constructor creates exception with errors only', () {
      final exception = ValidationException(errors: ['Error 1', 'Error 2']);

      expect(exception.errors, equals(['Error 1', 'Error 2']));
      expect(exception.warnings, isEmpty);
    });

    test('constructor creates exception with errors and warnings', () {
      final exception = ValidationException(
        errors: ['Error 1'],
        warnings: ['Warning 1', 'Warning 2'],
      );

      expect(exception.errors, equals(['Error 1']));
      expect(exception.warnings, equals(['Warning 1', 'Warning 2']));
    });

    test('toString formats errors only correctly', () {
      final exception = ValidationException(errors: ['Error 1', 'Error 2']);
      final output = exception.toString();

      expect(output, contains('Validation Errors:'));
      expect(output, contains('• Error 1'));
      expect(output, contains('• Error 2'));
      expect(output, isNot(contains('Validation Warnings:')));
    });

    test('toString formats errors and warnings correctly', () {
      final exception = ValidationException(
        errors: ['Error 1'],
        warnings: ['Warning 1', 'Warning 2'],
      );
      final output = exception.toString();

      expect(output, contains('Validation Warnings:'));
      expect(output, contains('• Warning 1'));
      expect(output, contains('• Warning 2'));
      expect(output, contains('Validation Errors:'));
      expect(output, contains('• Error 1'));
    });

    test('toString handles empty warnings list', () {
      final exception = ValidationException(
        errors: ['Error 1'],
        warnings: [],
      );
      final output = exception.toString();

      expect(output, isNot(contains('Validation Warnings:')));
      expect(output, contains('Validation Errors:'));
      expect(output, contains('• Error 1'));
    });
  });

  group('ValidationContext Tests', () {
    test('constructor creates context without context string', () {
      final context = ValidationContext();

      expect(context.isValid, isTrue);
      expect(context.hasWarnings, isFalse);
      expect(context.errors, isEmpty);
      expect(context.warnings, isEmpty);
    });

    test('constructor creates context with context string', () {
      final context = ValidationContext('Test Context');

      expect(context.isValid, isTrue);
      expect(context.hasWarnings, isFalse);
      expect(context.errors, isEmpty);
      expect(context.warnings, isEmpty);
    });

    test('addError adds formatted error message', () {
      final context = ValidationContext('Test Context');
      context.addError('Test error');

      expect(context.isValid, isFalse);
      expect(context.errors, hasLength(1));
      expect(context.errors.first, equals('[Test Context] Test error'));
    });

    test('addError adds unformatted error when no context', () {
      final context = ValidationContext();
      context.addError('Test error');

      expect(context.isValid, isFalse);
      expect(context.errors, hasLength(1));
      expect(context.errors.first, equals('Test error'));
    });

    test('addWarning adds formatted warning message', () {
      final context = ValidationContext('Test Context');
      context.addWarning('Test warning');

      expect(context.isValid, isTrue);
      expect(context.hasWarnings, isTrue);
      expect(context.warnings, hasLength(1));
      expect(context.warnings.first, equals('[Test Context] Test warning'));
    });

    test('addWarning adds unformatted warning when no context', () {
      final context = ValidationContext();
      context.addWarning('Test warning');

      expect(context.isValid, isTrue);
      expect(context.hasWarnings, isTrue);
      expect(context.warnings, hasLength(1));
      expect(context.warnings.first, equals('Test warning'));
    });

    test('withContext creates child context with combined context', () {
      final parent = ValidationContext('Parent');
      final child = parent.withContext('Child');

      child.addError('Child error');

      expect(child.errors.first, equals('[Parent > Child] Child error'));
      expect(parent.errors.first, equals('[Parent > Child] Child error'));
    });

    test('withContext creates child context from root context', () {
      final parent = ValidationContext();
      final child = parent.withContext('Child');

      child.addError('Child error');

      expect(child.errors.first, equals('[Child] Child error'));
      expect(parent.errors.first, equals('[Child] Child error'));
    });

    test('withContext creates nested child contexts', () {
      final root = ValidationContext('Root');
      final child1 = root.withContext('Child1');
      final child2 = child1.withContext('Child2');

      child2.addError('Nested error');

      expect(
          child2.errors.first, equals('[Root > Child1 > Child2] Nested error'));
      expect(
          root.errors.first, equals('[Root > Child1 > Child2] Nested error'));
    });

    test('check with true condition does nothing', () {
      final context = ValidationContext();
      context.check(true, errorMessage: 'Should not appear');

      expect(context.isValid, isTrue);
      expect(context.hasWarnings, isFalse);
      expect(context.errors, isEmpty);
      expect(context.warnings, isEmpty);
    });

    test('check with false condition adds error', () {
      final context = ValidationContext();
      context.check(false, errorMessage: 'Test error');

      expect(context.isValid, isFalse);
      expect(context.errors, hasLength(1));
      expect(context.errors.first, equals('Test error'));
    });

    test('check with false condition and warning message adds warning', () {
      final context = ValidationContext();
      context.check(false,
          errorMessage: 'Test error', warningMessage: 'Test warning');

      expect(context.isValid, isTrue);
      expect(context.hasWarnings, isTrue);
      expect(context.warnings, hasLength(1));
      expect(context.warnings.first, equals('Test warning'));
      expect(context.errors, isEmpty);
    });

    test('isValid returns false when errors exist', () {
      final context = ValidationContext();
      context.addError('Test error');

      expect(context.isValid, isFalse);
    });

    test('isValid returns false when child has errors', () {
      final parent = ValidationContext();
      final child = parent.withContext('Child');
      child.addError('Child error');

      expect(parent.isValid, isFalse);
      expect(child.isValid, isFalse);
    });

    test('isValid returns true when only warnings exist', () {
      final context = ValidationContext();
      context.addWarning('Test warning');

      expect(context.isValid, isTrue);
    });

    test('hasWarnings returns true when warnings exist', () {
      final context = ValidationContext();
      context.addWarning('Test warning');

      expect(context.hasWarnings, isTrue);
    });

    test('hasWarnings returns true when child has warnings', () {
      final parent = ValidationContext();
      final child = parent.withContext('Child');
      child.addWarning('Child warning');

      expect(parent.hasWarnings, isTrue);
      expect(child.hasWarnings, isTrue);
    });

    test('hasWarnings returns false when no warnings exist', () {
      final context = ValidationContext();
      context.addError('Test error');

      expect(context.hasWarnings, isFalse);
    });

    test('errors aggregates errors from children', () {
      final parent = ValidationContext();
      parent.addError('Parent error');

      final child1 = parent.withContext('Child1');
      child1.addError('Child1 error');

      final child2 = parent.withContext('Child2');
      child2.addError('Child2 error');

      expect(parent.errors, hasLength(3));
      expect(parent.errors, contains('Parent error'));
      expect(parent.errors.any((e) => e.contains('Child1 error')), isTrue);
      expect(parent.errors.any((e) => e.contains('Child2 error')), isTrue);
    });

    test('warnings aggregates warnings from children', () {
      final parent = ValidationContext();
      parent.addWarning('Parent warning');

      final child1 = parent.withContext('Child1');
      child1.addWarning('Child1 warning');

      final child2 = parent.withContext('Child2');
      child2.addWarning('Child2 warning');

      expect(parent.warnings, hasLength(3));
      expect(parent.warnings, contains('Parent warning'));
      expect(parent.warnings.any((w) => w.contains('Child1 warning')), isTrue);
      expect(parent.warnings.any((w) => w.contains('Child2 warning')), isTrue);
    });

    test('throwIfErrors does nothing when valid', () {
      final context = ValidationContext();
      context.addWarning('Just a warning');

      expect(() => context.throwIfErrors(), returnsNormally);
    });

    test('throwIfErrors throws ValidationException when errors exist', () {
      final context = ValidationContext();
      context.addError('Test error');
      context.addWarning('Test warning');

      expect(
        () => context.throwIfErrors(),
        throwsA(isA<ValidationException>()
            .having((e) => e.errors, 'errors', contains('Test error'))
            .having((e) => e.warnings, 'warnings', contains('Test warning'))),
      );
    });

    test('throwIfErrors throws when child has errors', () {
      final parent = ValidationContext();
      final child = parent.withContext('Child');
      child.addError('Child error');

      expect(
        () => parent.throwIfErrors(),
        throwsA(isA<ValidationException>().having(
            (e) => e.errors.any((error) => error.contains('Child error')),
            'has child error',
            isTrue)),
      );
    });

    test('multiple operations work together correctly', () {
      final context = ValidationContext('Main');

      context.addError('Main error');
      context.addWarning('Main warning');

      final child1 = context.withContext('Child1');
      child1.check(false, errorMessage: 'Child1 check failed');
      child1.check(true, errorMessage: 'Should not appear');

      final child2 = context.withContext('Child2');
      child2.check(false,
          errorMessage: 'Child2 error', warningMessage: 'Child2 warning');

      expect(context.isValid, isFalse);
      expect(context.hasWarnings, isTrue);
      expect(context.errors, hasLength(2));
      expect(context.warnings, hasLength(2));

      expect(
        () => context.throwIfErrors(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('errors and warnings return unmodifiable lists', () {
      final context = ValidationContext();
      context.addError('Test error');
      context.addWarning('Test warning');

      final errors = context.errors;
      final warnings = context.warnings;

      expect(() => errors.add('New error'), throwsUnsupportedError);
      expect(() => warnings.add('New warning'), throwsUnsupportedError);
    });
  });
}
