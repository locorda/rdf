import 'dart:async';
import 'dart:io';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
// import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
// import 'package:analyzer/dart/analysis/results.dart';
// import 'package:analyzer/dart/element/element2.dart';
import 'package:path/path.dart' as p;
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_service.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_service_factory.dart';
import 'package:locorda_rdf_mapper_generator/builder_helper.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/template_data.dart';
import 'package:build_test/build_test.dart';

final AnalyzerWrapperService _analyzerWrapperService =
    AnalyzerWrapperServiceFactory
        .create(); // Use the appropriate version for your tests
StreamSubscription<LogRecord>? _currentSubscription;

/// Class to manage a temporary project directory with proper dependency resolution
class TempProject {
  final Directory directory;
  final Directory libDirectory;

  TempProject._(this.directory, this.libDirectory);

  /// Creates a temporary project with proper pubspec.yaml, build.yaml, and dependency resolution
  static Future<TempProject> create() async {
    final tempDir =
        Directory.systemTemp.createTempSync('rdf_mapper_string_test_');

    // Create pubspec.yaml with proper dependencies
    final pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
    await pubspecFile.writeAsString('''
name: test_validation
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  locorda_rdf_mapper_annotations: 
    path: ${Directory.current.path}/../locorda_rdf_mapper_annotations
  locorda_rdf_terms_core: any
  build: any

dev_dependencies:
  locorda_rdf_mapper_generator:
    path: ${Directory.current.path}
  build_runner: any

dependency_overrides: 
  locorda_rdf_mapper:
    path: ${Directory.current.path}/../locorda_rdf_mapper
  locorda_rdf_mapper_annotations:
    path: ${Directory.current.path}/../locorda_rdf_mapper_annotations
''');

    // Create build.yaml
    final buildFile = File(p.join(tempDir.path, 'build.yaml'));
    await buildFile.writeAsString('''
targets:
  \$default:
    builders:
      locorda_rdf_mapper_generator:cache_builder:
        enabled: true
      locorda_rdf_mapper_generator:source_builder:
        enabled: true
      locorda_rdf_mapper_generator:init_file_builder:
        enabled: true
''');

    // Create lib directory
    final libDir = Directory(p.join(tempDir.path, 'lib'));
    await libDir.create(recursive: true);

    // Run pub get to install dependencies
    final pubGetResult = await Process.run(
      'dart',
      ['pub', 'get'],
      workingDirectory: tempDir.path,
    );

    if (pubGetResult.exitCode != 0) {
      // Clean up on failure
      try {
        await tempDir.delete(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
      throw Exception('pub get failed: ${pubGetResult.stderr}');
    }

    return TempProject._(tempDir, libDir);
  }

  /// Writes source code to a file in the lib directory
  Future<File> writeLibFile(String fileName, String sourceCode) async {
    final file = File(p.join(libDirectory.path, fileName));
    await file.writeAsString(sourceCode);
    return file;
  }

  /// Cleans up the temporary directory
  Future<void> cleanup() async {
    try {
      await directory.delete(recursive: true);
    } catch (e) {
      // Ignore cleanup errors in tests
    }
  }
}

void setupTestLogging({Level level = Level.WARNING}) {
  // Set up logging to show warnings and above
  Logger.root.level = level;
  if (_currentSubscription != null) {
    _currentSubscription!.cancel();
  }
  _currentSubscription = Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    if (record.error != null) {
      print('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('Stack trace: ${record.stackTrace}');
    }
  });
}

Future<(LibraryElem library, String path)> analyzeTestFile(
    String filename) async {
  // Get the path to the test file relative to the project root
  final testFilePath = p.normalize(p.absolute(
    p.join('test', 'fixtures', filename),
  ));

  // Ensure the file exists
  if (!File(testFilePath).existsSync()) {
    throw Exception(
        'Test file not found at $testFilePath. Current directory: ${Directory.current.path}');
  }

  // Set up analysis context - use the fixtures directory
  final fixturesDir = p.dirname(testFilePath);
  final libraryElem =
      await _analyzerWrapperService.loadLibrary(fixturesDir, testFilePath);

  // Get class elements
  return (libraryElem, testFilePath);
}

/// Analyzes source code from a string and returns LibraryElem for testing validation logic
/// without requiring physical files. Uses proper project setup with dependency resolution.
Future<LibraryElem> analyzeStringCode(String sourceCode,
    {String fileName = 'test.dart'}) async {
  final tempProject = await TempProject.create();

  try {
    // Write the source code to the lib directory
    final sourceFile = await tempProject.writeLibFile(fileName, sourceCode);

    // Use the existing loadLibrary method to analyze the file in the proper project context
    final libraryElem = await _analyzerWrapperService.loadLibrary(
        tempProject.directory.path, sourceFile.path);

    return libraryElem;
  } finally {
    // Clean up the temporary project
    await tempProject.cleanup();
  }
}

/// Builds template data from source code string, useful for testing validation logic
/// and template generation without requiring physical files.
///
/// This method will throw ValidationException if there are validation errors,
/// which is exactly what we want to test in validation tests.
Future<FileTemplateData?> buildTemplateDataFromString(String sourceCode,
    {String fileName = 'test.dart', String packageName = 'test'}) async {
  // Analyze the source code to get LibraryElem
  final library = await analyzeStringCode(sourceCode, fileName: fileName);

  // Extract classes and enums from the library
  final classes = library.classes;
  final enums = library.enums;

  // Create broader imports from the library
  final broaderImports = BroaderImports.create(library);

  // Use BuilderHelper to build template data
  // This will throw ValidationException if there are validation errors
  final builderHelper = BuilderHelper();
  final templateData = await builderHelper.buildTemplateData(
    fileName,
    packageName,
    classes,
    enums,
    broaderImports,
  );
  return templateData;
}

Future<AssetReader> createTestAssetReader() async {
  final readerWriter = TestReaderWriter();
  await readerWriter.testing.loadIsolateSources();
  return readerWriter;
}
