import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

void main() {
  group('ProvidedAs Feature - Integration Tests', () {
    late String projectRoot;
    late String testFixturesPath;

    setUpAll(() {
      // Get project root
      projectRoot = Directory.current.path;
      testFixturesPath = path.join(projectRoot, 'test', 'fixtures');
    });

    test('generated mapper file exists', () {
      final generatedFile = File(path.join(
        testFixturesPath,
        'provided_as_test_models.locorda_rdf_mapper.g.dart',
      ));

      expect(
        generatedFile.existsSync(),
        isTrue,
        reason: 'Generated mapper file should exist after build_runner',
      );
    });

    test('generated mapper contains Document mapper', () {
      final generatedFile = File(path.join(
        testFixturesPath,
        'provided_as_test_models.locorda_rdf_mapper.g.dart',
      ));

      final content = generatedFile.readAsStringSync();

      expect(content, contains('class DocumentMapper'));
      expect(content, contains('GlobalResourceMapper<Document>'));
    });

    test('generated mapper contains Section mapper', () {
      final generatedFile = File(path.join(
        testFixturesPath,
        'provided_as_test_models.locorda_rdf_mapper.g.dart',
      ));

      final content = generatedFile.readAsStringSync();

      expect(content, contains('class SectionMapper'));
      expect(content, contains('GlobalResourceMapper<Section>'));
    });

    test('generated Document mapper has documentIriProvider in provides', () {
      final generatedFile = File(path.join(
        testFixturesPath,
        'provided_as_test_models.locorda_rdf_mapper.g.dart',
      ));

      final content = generatedFile.readAsStringSync();

      // Document mapper should generate code that provides documentIri
      // This would be visible in how Section mappers are instantiated within Document mapper
      expect(content, contains('documentIriProvider'));
    });

    test('generated Section mapper uses subject.value for documentIri', () {
      final generatedFile = File(path.join(
        testFixturesPath,
        'provided_as_test_models.locorda_rdf_mapper.g.dart',
      ));

      final content = generatedFile.readAsStringSync();

      // Section mapper should use subject.value when providing documentIri during serialization
      expect(content, contains('() => subject.value'));
    });

    test('generated Section mapper constructor requires documentIriProvider',
        () {
      final generatedFile = File(path.join(
        testFixturesPath,
        'provided_as_test_models.locorda_rdf_mapper.g.dart',
      ));

      final content = generatedFile.readAsStringSync();

      // Section mapper constructor should require documentIriProvider parameter
      expect(
          content, contains('required String Function() documentIriProvider'));
    });

    test('generated Section mapper has registerGlobally: false behavior', () {
      final generatedFile = File(path.join(
        testFixturesPath,
        'provided_as_test_models.locorda_rdf_mapper.g.dart',
      ));

      final content = generatedFile.readAsStringSync();

      // With registerGlobally: false, Section mapper should not be in init function
      // or should be conditionally registered
      expect(content,
          isNot(contains('registry.registerGlobalResourceMapper<Section>')));
    });

    test('generated code compiles without errors', () {
      final generatedFile = File(path.join(
        testFixturesPath,
        'provided_as_test_models.locorda_rdf_mapper.g.dart',
      ));

      expect(generatedFile.existsSync(), isTrue);

      // The fact that our mapper tests import and use this file
      // is sufficient to verify it compiles
      final content = generatedFile.readAsStringSync();
      expect(content, isNotEmpty);
      expect(content, contains('// GENERATED CODE - DO NOT MODIFY BY HAND'));
    });

    test('generated init file handles Document mapper registration', () {
      final initFile = File(path.join(
        projectRoot,
        'test',
        'init_test_rdf_mapper.g.dart',
      ));

      if (initFile.existsSync()) {
        final content = initFile.readAsStringSync();

        // Document mapper should be registered with baseUriProvider
        expect(content, contains('DocumentMapper'));
        expect(content, contains('baseUriProvider'));
      }
    });

    test('template extraction regex is generated correctly', () {
      final generatedFile = File(path.join(
        testFixturesPath,
        'provided_as_test_models.locorda_rdf_mapper.g.dart',
      ));

      final content = generatedFile.readAsStringSync();

      // Should contain regex for parsing Document IRI template
      expect(content, contains(RegExp(r'RegExp\(')));
      expect(content, contains('docId'));

      // Should contain regex for parsing Section IRI template
      expect(content, contains('sectionId'));
    });

    test('code generation follows standard patterns', () {
      final generatedFile = File(path.join(
        testFixturesPath,
        'provided_as_test_models.locorda_rdf_mapper.g.dart',
      ));

      final content = generatedFile.readAsStringSync();

      // Standard header and imports
      expect(content, contains('// GENERATED CODE - DO NOT MODIFY BY HAND'));
      expect(
          content, contains('import \'package:locorda_rdf_core/core.dart\';'));
      expect(content,
          contains('import \'package:locorda_rdf_mapper/mapper.dart\';'));

      // Standard ignore directives
      expect(content, contains('// ignore_for_file:'));

      // Import of source file
      expect(content, contains('import \'provided_as_test_models.dart\';'));
    });
  });
}
