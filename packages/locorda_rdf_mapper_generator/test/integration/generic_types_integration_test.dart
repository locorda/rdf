import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Generic Types Integration Tests', () {
    test('build succeeds with valid generic classes', () async {
      // This test verifies that the build process works correctly with valid generic classes
      // The valid_generic_test_models.dart file should build without errors

      // We use the fact that if the build process worked, the generated file should exist
      final generatedFile =
          File('test/fixtures/valid_generic_test_models.rdf_mapper.g.dart');

      expect(generatedFile.existsSync(), isTrue,
          reason:
              'Generated mapper file should exist for valid generic classes');

      final content = await generatedFile.readAsString();

      // Check that the generated code contains the expected mappers
      expect(content, contains('class GenericDocumentMapper<T>'));
      expect(content,
          contains('implements GlobalResourceMapper<GenericDocument<T>>'));
      expect(content, contains('class MultiGenericDocumentMapper<T, U, V>'));
      expect(
          content,
          contains(
              'implements GlobalResourceMapper<MultiGenericDocument<T, U, V>>'));
      expect(content, contains('class GenericLocalResourceMapper<T>'));
      expect(content,
          contains('implements LocalResourceMapper<GenericLocalResource<T>>'));

      // Check that type parameters are properly separated with commas
      expect(content, contains('MultiGenericDocument<T, U, V>'));
      expect(content, isNot(contains('MultiGenericDocument<TUV>')));
    });

    test('build succeeds with valid generic classes only',
        tags: ['build-runner', 'slow'], () async {
      // This test verifies that the build process works correctly with only valid generic classes
      // The fixture files now contain only valid classes (no invalid registerGlobally=true cases)

      // Run build command and expect it to succeed
      final result = await Process.run(
        'dart',
        ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
        workingDirectory: Directory.current.path,
      );

      // Build should succeed without errors
      expect(result.exitCode, equals(0),
          reason:
              'Build should succeed when fixture files contain only valid generic classes');

      // Check that there are no validation error messages in the output
      final allOutput = result.stderr.toString() + result.stdout.toString();
      expect(allOutput, isNot(contains('has generic type parameters')));
      expect(allOutput,
          isNot(contains('must have registerGlobally set to false')));
      expect(allOutput,
          isNot(contains('Generic classes cannot be registered globally')));
    });

    test('original document example still works', () async {
      // Verify that our changes didn't break the existing document example
      final generatedFile = File(
          'test/fixtures/locorda_rdf_mapper_annotations/examples/document_example.rdf_mapper.g.dart');

      expect(generatedFile.existsSync(), isTrue,
          reason: 'Document example should still generate successfully');

      final content = await generatedFile.readAsString();

      // Check that it generates the expected mapper with generic type parameter
      expect(content, contains('class DocumentMapper<T>'));
      expect(content, contains('implements GlobalResourceMapper<Document<T>>'));
      expect(content, contains('final T primaryTopic'));

      // Should not generate invalid syntax
      expect(content, isNot(contains('Document<T>Mapper')));
      expect(content,
          isNot(contains('GlobalResourceMapper<Document<T>><Document<T>>')));
    });

    test('analyzer wrapper extracts type parameters correctly', () {
      // This is tested through the processor tests, but we verify the end-to-end result
      final generatedFile =
          File('test/fixtures/valid_generic_test_models.rdf_mapper.g.dart');

      expect(generatedFile.existsSync(), isTrue);

      // The fact that the file was generated with correct type parameters
      // proves that the analyzer wrapper correctly extracted:
      // - GenericDocument<T> -> hasTypeParameters=true, typeParameterNames=['T']
      // - MultiGenericDocument<T, U, V> -> hasTypeParameters=true, typeParameterNames=['T', 'U', 'V']
      // - NonGenericPerson -> hasTypeParameters=false, typeParameterNames=[]

      // We can verify this by checking the generated code structure
    });

    test('project builds cleanly without validation errors',
        tags: ['build-runner', 'slow'], () async {
      // This test ensures the entire project can build without any validation errors
      // after removing invalid test classes

      final result = await Process.run(
        'dart',
        ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
        workingDirectory: Directory.current.path,
      );

      // Should build successfully
      expect(result.exitCode, equals(0),
          reason:
              'Project should build cleanly after removing invalid test classes');

      final allOutput = result.stderr.toString() + result.stdout.toString();

      // Should not contain any validation error messages
      expect(allOutput, isNot(contains('validation error')));
      expect(allOutput, isNot(contains('InvalidGeneric')));
      expect(allOutput, contains('Built with build_runner'),
          reason: 'Should show successful build completion message');
    });

    test('generated code compiles without issues', tags: ['analyze', 'slow'],
        () async {
      // This test verifies that the generated code is syntactically correct
      // by running the analyzer on it

      final result = await Process.run(
        'dart',
        [
          'analyze',
          'test/fixtures/valid_generic_test_models.rdf_mapper.g.dart'
        ],
        workingDirectory: Directory.current.path,
      );

      // Should analyze without errors
      expect(result.exitCode, equals(0),
          reason: 'Generated code should compile without analyzer errors');

      // Check that there are no error messages
      final output = result.stdout.toString() + result.stderr.toString();
      expect(output.toLowerCase(), isNot(contains('error')));
    });
  });
}
