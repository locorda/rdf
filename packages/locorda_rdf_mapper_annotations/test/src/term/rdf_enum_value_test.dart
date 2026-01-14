import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:test/test.dart';

void main() {
  group('RdfEnumValue', () {
    test('constructor stores value correctly', () {
      const customValue = 'CUSTOM_VALUE';
      final annotation = RdfEnumValue(customValue);

      expect(annotation.value, equals(customValue));
    });

    test('annotation is an RdfAnnotation', () {
      final annotation = RdfEnumValue('test');

      expect(annotation, isA<RdfAnnotation>());
    });

    test('different instances with same value are equal', () {
      const value = 'SAME_VALUE';
      final annotation1 = RdfEnumValue(value);
      final annotation2 = RdfEnumValue(value);

      expect(annotation1.value, equals(annotation2.value));
    });

    test('supports various value formats', () {
      final testCases = [
        'H', // Single letter
        'HIGH', // Uppercase
        'high', // Lowercase
        'kebab-case', // Kebab case
        'snake_case', // Snake case
        'PascalCase', // Pascal case
        'camelCase', // Camel case
        '123', // Numeric
        'mixed-123_Value', // Mixed
        'http://example.org/value', // URI-like
      ];

      for (final value in testCases) {
        final annotation = RdfEnumValue(value);
        expect(annotation.value, equals(value));
      }
    });

    test('preserves whitespace in values', () {
      const valueWithSpaces = ' value with spaces ';
      final annotation = RdfEnumValue(valueWithSpaces);

      expect(annotation.value, equals(valueWithSpaces));
    });

    test('handles special characters', () {
      const specialChars = r'!@#$%^&*()[]{}|;:,.<>?';
      final annotation = RdfEnumValue(specialChars);

      expect(annotation.value, equals(specialChars));
    });

    test('handles Unicode characters', () {
      const unicodeValue = 'αβγδε-测试-🚀';
      final annotation = RdfEnumValue(unicodeValue);

      expect(annotation.value, equals(unicodeValue));
    });

    test('const constructor works in annotations', () {
      // This test verifies that the annotation can be used in const contexts
      // which is required for Dart annotations
      const annotation = RdfEnumValue('CONST_VALUE');

      expect(annotation.value, equals('CONST_VALUE'));
    });
  });

  group('RdfEnumValue usage patterns', () {
    test('typical enum annotation pattern', () {
      // While we can't test actual enum annotations here (requires code generation),
      // we can verify the annotation instances work as expected
      final highPriority = RdfEnumValue('H');
      final mediumPriority = RdfEnumValue('M');
      final lowPriority = RdfEnumValue('L');

      expect(highPriority.value, equals('H'));
      expect(mediumPriority.value, equals('M'));
      expect(lowPriority.value, equals('L'));
    });

    test('IRI segment values', () {
      // Test values that would be suitable for IRI templates
      final iriValues = [
        RdfEnumValue('NewCondition'),
        RdfEnumValue('UsedCondition'),
        RdfEnumValue('excellent-5-stars'),
        RdfEnumValue('in-progress'),
        RdfEnumValue('delivered-completed'),
      ];

      final expectedValues = [
        'NewCondition',
        'UsedCondition',
        'excellent-5-stars',
        'in-progress',
        'delivered-completed',
      ];

      for (int i = 0; i < iriValues.length; i++) {
        expect(iriValues[i].value, equals(expectedValues[i]));
      }
    });

    test('literal code values', () {
      // Test values that would be suitable for literal mappings
      final literalValues = [
        RdfEnumValue('USD'),
        RdfEnumValue('EUR'),
        RdfEnumValue('available'),
        RdfEnumValue('sold-out'),
        RdfEnumValue('HIGH'),
      ];

      final expectedValues = [
        'USD',
        'EUR',
        'available',
        'sold-out',
        'HIGH',
      ];

      for (int i = 0; i < literalValues.length; i++) {
        expect(literalValues[i].value, equals(expectedValues[i]));
      }
    });
  });

  group('RdfEnumValue validation scenarios', () {
    test('empty string is technically valid but not recommended', () {
      // The annotation itself doesn't validate - validation would happen
      // in the code generator
      final annotation = RdfEnumValue('');
      expect(annotation.value, equals(''));
    });

    test('null value would cause compile error', () {
      // This test documents that null is not allowed
      // In actual use, this would be a compile-time error
      expect(() => RdfEnumValue(null as dynamic), throwsA(isA<TypeError>()));
    });
  });

  group('RdfEnumValue integration expectations', () {
    test('works with RdfAnnotation interface', () {
      final annotation = RdfEnumValue('test');

      // Verify it implements the expected interface
      expect(annotation, isA<RdfAnnotation>());

      // The RdfAnnotation interface should be usable in annotation contexts
      final asInterface = annotation as RdfAnnotation;
      expect(asInterface, isNotNull);
    });

    test('annotation metadata is preserved', () {
      const testValue = 'TEST_ENUM_VALUE';
      const annotation = RdfEnumValue(testValue);

      // The const annotation should preserve its value
      expect(annotation.value, equals(testValue));

      // And should be identical when created as const
      const annotation2 = RdfEnumValue(testValue);
      expect(identical(annotation, annotation2), isTrue);
    });
  });
}
