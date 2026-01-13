import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:rdf_mapper_generator/src/mappers/mapper_model_builder.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';

Builder rdfMapperSourceBuilder(BuilderOptions options) =>
    RdfMapperSourceBuilder();

/// Second phase builder that generates source files from cached template data.
/// This builder runs after the cache builder and generates the final source files.
class RdfMapperSourceBuilder implements Builder {
  static final _templateRenderer = TemplateRenderer();

  @override
  Future<void> build(BuildStep buildStep) => buildIt(buildStep.inputId,
      buildStep.readAsString, buildStep.writeAsString, buildStep);

  Future<void> buildIt(
      AssetId inputId,
      Future<String> Function(AssetId id, {Encoding encoding}) readAsString,
      Future<void> Function(AssetId id, FutureOr<String> contents,
              {Encoding encoding})
          writeAsString,
      AssetReader reader) async {
    // Only process .cache.json files
    if (!inputId.path.endsWith('.rdf_mapper.cache.json')) {
      return;
    }

    try {
      // Read and parse the cache file
      final jsonString = await readAsString(inputId);
      final jsonData = jsonDecode(jsonString);
      // FIXME: isn't this already in jsonData? Do we need the fallback?
      String mapperImportUri = jsonData['mapperFileImportUri'] ??
          MapperModelBuilder.getMapperImportUri(inputId.package,
              inputId.path.replaceAll('.cache.json', '.g.dart'));

      // Render the template
      final generatedCode = await _templateRenderer.renderFileTemplate(
        mapperImportUri,
        jsonData,
        reader,
      );

      // Generate the output file path by replacing the cache extension
      final outputPath = inputId.path
          .replaceAll('.rdf_mapper.cache.json', '.rdf_mapper.g.dart');
      final outputId = AssetId(
        inputId.package,
        outputPath,
      );

      await writeAsString(outputId, generatedCode);
      log.fine('Generated RDF mapper source for ${inputId.path}');
    } catch (e, stackTrace) {
      log.severe(
        'Error processing cache file ${inputId.path}: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.rdf_mapper.cache.json': ['.rdf_mapper.g.dart']
      };
}
