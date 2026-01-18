import 'dart:async';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:locorda_rdf_mapper_generator/init_file_builder_helper.dart';

/// Builder that generates the init_rdf_mapper.g.dart file with all mappers registered.
Builder rdfInitFileBuilder(BuilderOptions options) => RdfInitFileBuilder();

class RdfInitFileBuilder implements Builder {
  static final _builderHelper = InitFileBuilderHelper();

  @override
  Future<void> build(BuildStep buildStep) async {
    // Only process pubspec.yaml
    if (!buildStep.inputId.path.endsWith('pubspec.yaml')) {
      return;
    }

    try {
      // Process lib/ files
      await _generateMapperFile(
        buildStep,
        'lib/**.rdf_mapper.cache.json',
        'lib/init_rdf_mapper.g.dart',
        isTest: false,
      );

      // Process test/ files
      await _generateMapperFile(
        buildStep,
        'test/**.rdf_mapper.cache.json',
        'test/init_test_rdf_mapper.g.dart',
        isTest: true,
      );
    } catch (e, stackTrace) {
      log.severe(
        'Error generating RDF mapper initialization files: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _generateMapperFile(
    BuildStep buildStep,
    String globPattern,
    String outputPath, {
    required bool isTest,
  }) async {
    try {
      // Find all generated cache files matching the pattern
      final cacheFiles = await buildStep.findAssets(Glob(globPattern)).toList();

      if (cacheFiles.isEmpty) {
        // No cache files found for this pattern, skip generation
        return;
      }

      // Read all cache files in parallel
      final jsonFiles = await Future.wait(cacheFiles.map((file) async => (
            file.path,
            file.package,
            await buildStep.readAsString(file),
          )));

      // Generate the code
      final generatedCode = await _builderHelper.build(
        jsonFiles,
        buildStep,
        isTest: isTest,
        outputPath: outputPath,
        currentPackage: buildStep.inputId.package,
      );

      // Write the output file
      await buildStep.writeAsString(
        AssetId(buildStep.inputId.package, outputPath),
        generatedCode,
      );
      log.fine('Generated $outputPath with ${jsonFiles.length} mappers');
    } catch (e, stackTrace) {
      log.severe(
        'Error generating $outputPath: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        'pubspec.yaml': [
          'lib/init_rdf_mapper.g.dart',
          'test/init_test_rdf_mapper.g.dart',
        ],
      };
}
