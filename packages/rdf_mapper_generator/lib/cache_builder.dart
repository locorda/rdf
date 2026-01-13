import 'dart:async';
import 'dart:convert';

// import 'package:analyzer/dart/analysis/utilities.dart';
// import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:rdf_mapper_generator/builder_helper.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_service.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_service_factory.dart';
import 'package:rdf_mapper_generator/src/processors/broader_imports.dart';

Builder rdfMapperCacheBuilder(BuilderOptions options) =>
    RdfMapperCacheBuilder();

/// First phase builder that generates cache files with template data.
/// This builder runs before the main builder and stores the template data in JSON format.
class RdfMapperCacheBuilder implements Builder {
  static final _builderHelper = BuilderHelper();
  static final AnalyzerWrapperService _analyzerWrapperService =
      AnalyzerWrapperServiceFactory.create();

  @override
  Future<void> build(BuildStep buildStep) => buildIt(
      buildStep.inputId,
      buildStep.readAsString,
      buildStep.writeAsString,
      (inputId, {bool allowSyntaxErrors = false}) async =>
          _analyzerWrapperService.libraryFor(buildStep, inputId,
              allowSyntaxErrors: allowSyntaxErrors));

  Future<void> buildIt(
      AssetId inputId,
      Future<String> Function(AssetId id, {Encoding encoding}) readAsString,
      Future<void> Function(AssetId id, FutureOr<String> contents,
              {Encoding encoding})
          writeAsString,
      Future<LibraryElem> Function(AssetId assetId, {bool allowSyntaxErrors})
          libraryFor) async {
    // Only process .dart files, skip generated files
    if (!inputId.path.endsWith('.dart') ||
        inputId.path.contains('.g.dart') ||
        inputId.path.contains('.rdf_mapper.g.dart')) {
      return;
    }

    try {
      final sourceContent = await readAsString(inputId);

      // Parse the source file using the analyzer
      final parseResult = _analyzerWrapperService.parseString(
        content: sourceContent,
        path: inputId.path,
      );

      if (parseResult.errors.isNotEmpty) {
        log.warning(
          'Parse errors in ${inputId.path}: ${parseResult.errors}',
        );
        return;
      }

      // Get the library element for the parsed file
      final library = await _resolveLibrary(libraryFor, inputId);
      if (library == null) {
        return;
      }

      final classes = library.classes;

      final enums = library.enums;

      final generatedTemplateData = (await _builderHelper.buildTemplateData(
              inputId.path,
              inputId.package,
              classes,
              enums,
              BroaderImports.create(library)))
          ?.toMap();

      // Only create output file if we generated code
      if (generatedTemplateData != null) {
        final outputId = inputId.changeExtension('.rdf_mapper.cache.json');
        await writeAsString(outputId, jsonEncode(generatedTemplateData));

        log.info('Generated RDF mapper cache for ${inputId.path}');
      }
    } catch (e, stackTrace) {
      log.severe(
        'Error processing ${inputId.path}: $e',
        e,
        stackTrace,
      );
      // Re-throw to ensure build fails on errors
      rethrow;
    }
  }

  /// Resolves the library for the current build step.
  Future<LibraryElem?> _resolveLibrary(
      Future<LibraryElem> Function(AssetId assetId, {bool allowSyntaxErrors})
          libraryFor,
      AssetId inputId) async {
    try {
      // For build system integration, we need to use the resolver
      return await libraryFor(inputId);
    } catch (e) {
      log.warning('Could not resolve library for ${inputId.path}: $e');
      return null;
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.rdf_mapper.cache.json']
      };
}
