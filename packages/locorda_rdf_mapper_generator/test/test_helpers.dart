import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;

/// Helper class for testing that requires analyzer functionality.
/// 
/// Creates a temporary directory with Dart files and provides access to
/// the analyzer's type system for testing type-related code generation.
class TestAnalyzerHelper {
  late final Directory _tempDir;
  late final AnalysisContextCollection _collection;
  late final AnalysisContext _context;
  late final String _testFilePath;
  
  String get libraryImportUri => 'package:test/test.dart';

  Future<void> initialize() async {
    // Create temporary directory
    _tempDir = await Directory.systemTemp.createTemp('rdf_mapper_test_');
    
    // Create a minimal pubspec.yaml
    final pubspecFile = File(p.join(_tempDir.path, 'pubspec.yaml'));
    await pubspecFile.writeAsString('''
name: test
environment:
  sdk: ^3.0.0
''');

    // Create lib directory
    final libDir = Directory(p.join(_tempDir.path, 'lib'));
    await libDir.create();

    _testFilePath = p.join(libDir.path, 'test.dart');

    // Initialize analysis context
    _collection = AnalysisContextCollection(
      includedPaths: [_tempDir.path],
    );
    _context = _collection.contextFor(_tempDir.path);
  }

  /// Resolves a Dart library from the given code string.
  Future<LibraryElement> resolveLibrary(String code) async {
    // Write code to test file
    final testFile = File(_testFilePath);
    await testFile.writeAsString(code);

    // Get the resolved library
    final result = await _context.currentSession.getResolvedLibrary(_testFilePath);
    
    if (result is! ResolvedLibraryResult) {
      throw Exception('Failed to resolve library: ${result.runtimeType}');
    }

    return result.element;
  }

  Future<void> dispose() async {
    // Clean up temporary directory
    if (await _tempDir.exists()) {
      await _tempDir.delete(recursive: true);
    }
  }
}
