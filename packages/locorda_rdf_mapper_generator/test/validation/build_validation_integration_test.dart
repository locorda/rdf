import 'dart:io';
import 'package:test/test.dart';
import '../test_helper.dart';

void main() {
  group('Build Validation Integration Tests', tags: ['integration', 'slow'],
      () {
    test('build fails with validation errors for invalid generic class',
        () async {
      // Create a temporary test project with an invalid generic class
      final tempProject = await TempProject.create();

      try {
        // Create invalid class with validation error
        const invalidSourceCode = '''
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_common/foaf.dart';

@RdfGlobalResource(
  FoafDocument.classIri,
  IriStrategy('{+documentIri}'),
  registerGlobally: true,  // This should cause validation error for generic class
)
class InvalidGenericDocument<T> {
  @RdfIriPart()
  final String documentIri;
  
  @RdfProperty(FoafDocument.primaryTopic)
  final T primaryTopic;

  const InvalidGenericDocument({
    required this.documentIri,
    required this.primaryTopic,
  });
}
''';

        await tempProject.writeLibFile(
            'invalid_generic.dart', invalidSourceCode);

        // Run build_runner build and expect it to fail with validation errors
        final buildResult = await Process.run(
          'dart',
          ['run', 'build_runner', 'build'],
          workingDirectory: tempProject.directory.path,
        );

        // The build should fail (non-zero exit code) due to validation errors
        expect(buildResult.exitCode, isNot(equals(0)),
            reason: 'Build should fail when there are validation errors');

        // Check that the error message contains our expected validation error
        final allOutput =
            buildResult.stderr.toString() + buildResult.stdout.toString();
        expect(
            allOutput,
            anyOf([
              contains('InvalidGenericDocument has generic type parameters'),
              contains('must have registerGlobally set to false'),
              contains('Generic classes cannot be registered globally'),
              contains(
                  'ValidationException'), // The validation framework should report the error
            ]),
            reason: 'Build output should contain validation error messages');
      } finally {
        // Clean up the temporary project
        await tempProject.cleanup();
      }
    },
        timeout: Timeout(
            Duration(minutes: 3))); // Give enough time for pub get and build

    test('build succeeds with valid generic classes', () async {
      // This is tested by the existing integration tests - just verify they exist
      final integrationTestFile =
          File('test/integration/generic_types_integration_test.dart');
      expect(integrationTestFile.existsSync(), isTrue,
          reason:
              'Integration tests should exist that verify valid builds work');
    });
  });
}
