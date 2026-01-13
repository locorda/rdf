import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';
import 'package:rdf_mapper_generator/src/utils/dart_formatter.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('Template Formatting Integration', () {
    late TemplateRenderer renderer;

    setUp(() {
      renderer = TemplateRenderer();
    });

    test('should handle formatting errors gracefully', () {
      // Test with intentionally malformed template data that would generate invalid Dart
      const invalidCode = '''
class TestClass {
  String name
  // Missing semicolon should cause formatting to fail gracefully
}
''';

      final formatter = DartCodeFormatter();
      final result = formatter.formatCode(invalidCode);

      // Should return the original code when formatting fails
      expect(result, equals(invalidCode));
    });

    test('should preserve complex formatting in init files', () async {
      final templateData = {
        'generatedOn': '2024-01-01T00:00:00.000Z',
        'isTest': true,
        'mappers': [
          {
            'className': 'TestClass',
            'mapperClassName': 'TestClassMapper',
            'registerGlobally': true,
          }
        ],
        'providers': [
          {
            'parameterName': 'testProvider',
            'variableName': 'testVar',
            'privateFieldName': '_testField',
          }
        ],
        'hasProviders': true,
        'namedCustomMappers': [],
        'hasNamedCustomMappers': false,
      };

      final assetReader = await createTestAssetReader();
      final result =
          await renderer.renderInitFileTemplate(templateData, assetReader);

      // Verify the result is properly formatted
      expect(result, isNotEmpty);
      expect(result, contains('RdfMapper initTestRdfMapper'));

      // Check for consistent indentation
      final lines = result.split('\n');
      bool foundFunctionSignature = false;
      for (final line in lines) {
        if (line.contains('initTestRdfMapper')) {
          foundFunctionSignature = true;
        }
        if (foundFunctionSignature && line.trim().startsWith('required ')) {
          // Parameter lines should be properly indented
          expect(line, startsWith('  '),
              reason:
                  'Function parameters should be indented with 2 spaces: "$line"');
        }
      }
    });
  });
}
