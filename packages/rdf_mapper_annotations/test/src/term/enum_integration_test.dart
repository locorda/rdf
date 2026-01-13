import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:test/test.dart';

// Test enums with different annotation patterns
@RdfLiteral()
enum TestLiteralEnum {
  @RdfEnumValue('CUSTOM')
  customValue,
  defaultValue,
}

@RdfIri('http://example.org/{value}')
enum TestIriEnum {
  @RdfEnumValue('CustomIri')
  customIri,
  defaultIri,
}

@RdfLiteral()
enum SimpleEnum {
  one,
  two,
  three,
}

void main() {
  group('Enum annotation integration', () {
    test('RdfLiteral enum with RdfEnumValue annotations', () {
      // Verify that the annotations are applied correctly
      expect(TestLiteralEnum.customValue, isA<TestLiteralEnum>());
      expect(TestLiteralEnum.defaultValue, isA<TestLiteralEnum>());

      // The enum values should be accessible
      expect(TestLiteralEnum.values.length, equals(2));
      expect(TestLiteralEnum.values, contains(TestLiteralEnum.customValue));
      expect(TestLiteralEnum.values, contains(TestLiteralEnum.defaultValue));
    });

    test('RdfIri enum with RdfEnumValue annotations', () {
      // Verify that the annotations are applied correctly
      expect(TestIriEnum.customIri, isA<TestIriEnum>());
      expect(TestIriEnum.defaultIri, isA<TestIriEnum>());

      // The enum values should be accessible
      expect(TestIriEnum.values.length, equals(2));
      expect(TestIriEnum.values, contains(TestIriEnum.customIri));
      expect(TestIriEnum.values, contains(TestIriEnum.defaultIri));
    });

    test('Simple RdfLiteral enum without custom values', () {
      expect(SimpleEnum.values.length, equals(3));
      expect(SimpleEnum.values, contains(SimpleEnum.one));
      expect(SimpleEnum.values, contains(SimpleEnum.two));
      expect(SimpleEnum.values, contains(SimpleEnum.three));
    });

    test('Enum names are preserved', () {
      expect(TestLiteralEnum.customValue.name, equals('customValue'));
      expect(TestLiteralEnum.defaultValue.name, equals('defaultValue'));
      expect(TestIriEnum.customIri.name, equals('customIri'));
      expect(TestIriEnum.defaultIri.name, equals('defaultIri'));
    });

    test('Enum indices are correct', () {
      expect(TestLiteralEnum.customValue.index, equals(0));
      expect(TestLiteralEnum.defaultValue.index, equals(1));
      expect(TestIriEnum.customIri.index, equals(0));
      expect(TestIriEnum.defaultIri.index, equals(1));
    });

    test('Enums can be used in switch statements', () {
      String processLiteralEnum(TestLiteralEnum value) {
        switch (value) {
          case TestLiteralEnum.customValue:
            return 'custom';
          case TestLiteralEnum.defaultValue:
            return 'default';
        }
      }

      expect(processLiteralEnum(TestLiteralEnum.customValue), equals('custom'));
      expect(
          processLiteralEnum(TestLiteralEnum.defaultValue), equals('default'));
    });

    test('Enums support standard enum operations', () {
      // toString
      expect(TestLiteralEnum.customValue.toString(),
          equals('TestLiteralEnum.customValue'));

      // Comparison
      expect(
          TestLiteralEnum.customValue == TestLiteralEnum.customValue, isTrue);
      expect(
          TestLiteralEnum.customValue == TestLiteralEnum.defaultValue, isFalse);

      // Set operations
      final enumSet = {
        TestLiteralEnum.customValue,
        TestLiteralEnum.defaultValue
      };
      expect(enumSet.length, equals(2));
      expect(enumSet.contains(TestLiteralEnum.customValue), isTrue);
    });
  });

  group('Annotation metadata verification', () {
    test('RdfLiteral annotation exists', () {
      // We can't access annotation metadata at runtime without mirrors,
      // but we can verify the annotations are syntactically correct
      // by the fact that the test compiles and runs
      expect(TestLiteralEnum.customValue, isNotNull);
    });

    test('RdfIri annotation exists', () {
      expect(TestIriEnum.customIri, isNotNull);
    });

    test('RdfEnumValue annotations are syntactically valid', () {
      // The presence of custom enum values in the compiled code
      // confirms the annotations are syntactically correct
      expect(TestLiteralEnum.customValue, isNotNull);
      expect(TestIriEnum.customIri, isNotNull);
    });
  });

  group('Enum usage patterns', () {
    test('Enums can be used as Map keys', () {
      final enumMap = <TestLiteralEnum, String>{
        TestLiteralEnum.customValue: 'Custom Value',
        TestLiteralEnum.defaultValue: 'Default Value',
      };

      expect(enumMap[TestLiteralEnum.customValue], equals('Custom Value'));
      expect(enumMap[TestLiteralEnum.defaultValue], equals('Default Value'));
    });

    test('Enums can be used in collections', () {
      final enumList = [
        TestLiteralEnum.customValue,
        TestLiteralEnum.defaultValue,
        TestLiteralEnum.customValue,
      ];

      expect(enumList.length, equals(3));
      expect(enumList.where((e) => e == TestLiteralEnum.customValue).length,
          equals(2));
    });

    test('Enums support filtering and mapping', () {
      final allValues = TestLiteralEnum.values;

      // Filter
      final customValues =
          allValues.where((e) => e.name.contains('custom')).toList();
      expect(customValues.length, equals(1));
      expect(customValues.first, equals(TestLiteralEnum.customValue));

      // Map
      final names = allValues.map((e) => e.name).toList();
      expect(names, contains('customValue'));
      expect(names, contains('defaultValue'));
    });
  });
}
