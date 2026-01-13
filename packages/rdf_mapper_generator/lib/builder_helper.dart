// import 'package:analyzer/dart/element/Elem.dart';
import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:rdf_mapper_generator/src/mappers/mapper_model.dart';
import 'package:rdf_mapper_generator/src/mappers/mapper_model_builder.dart';
import 'package:rdf_mapper_generator/src/mappers/resolved_mapper_model.dart';
import 'package:rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:rdf_mapper_generator/src/processors/enum_processor.dart';
import 'package:rdf_mapper_generator/src/processors/iri_processor.dart';
import 'package:rdf_mapper_generator/src/processors/literal_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/resource_processor.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/templates/template_data_builder.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

final _log = Logger('BuilderHelper');

class BuilderHelper {
  static final _templateRenderer = TemplateRenderer();

  Future<String?> build(
      String sourcePath,
      Iterable<ClassElem> classElements,
      Iterable<EnumElem> enumElements,
      AssetReader reader,
      BroaderImports broaderImports,
      {String packageName = "test"}) async {
    final templateData = await buildTemplateData(
        sourcePath, packageName, classElements, enumElements, broaderImports);
    if (templateData != null) {
      // Use the file template approach which handles imports properly
      return await _templateRenderer.renderFileTemplate(
          templateData.mapperFileImportUri, templateData.toMap(), reader);
    }

    return null;
  }

  Future<FileTemplateData?> buildTemplateData(
      String sourcePath,
      String packageName,
      Iterable<ClassElem> classElements,
      Iterable<EnumElem> enumElements,
      BroaderImports broaderImports) async {
    final context = ValidationContext();
    // Collect all resource info and element pairs (class or enum)
    final (resourceInfosWithElements, nestedResourceInfos) =
        collectResourceInfos(classElements, context, enumElements);
    context.throwIfErrors();

    final fileModel = MapperModelBuilder.buildMapperModels(
        context, packageName, sourcePath, resourceInfosWithElements);
    final nestedMappers = MapperModelBuilder.buildExternalMapperModels(
        context, nestedResourceInfos);

    final toplevelMappers = fileModel.mappers.toSet();
    final mappersSortedByDependcy =
        topologicalSort({...toplevelMappers, ...nestedMappers}.toList());
    final resolvedMappers = <MapperRef, ResolvedMapperModel>{};
    final toplevelResolvedMappers = <MapperRef, ResolvedMapperModel>{};
    final resolveContext = context.withContext('resolve');
    // Resolve all mappers, but only keep the toplevel ones for output
    // The nested ones are needed internally to build up the correct dependencies
    // like instantiations of child mappers.
    for (var m in mappersSortedByDependcy) {
      final resolved =
          m.resolve(resolveContext.withContext(m.id.id), resolvedMappers);
      resolvedMappers[resolved.id] = resolved;
      if (toplevelMappers.contains(m)) {
        toplevelResolvedMappers[resolved.id] = resolved;
      }
    }

    final templateContext = context.withContext('template');
    final templateDatas = toplevelResolvedMappers.values
        .map((r) => r.toTemplateData(templateContext.withContext(r.id.id),
            fileModel.mapperFileImportUri))
        .toList();

    // Use the file template approach which handles imports properly
    final result = resourceInfosWithElements.isEmpty
        ? null
        : TemplateDataBuilder.buildFileTemplate(
            context.withContext(fileModel.originalSourcePath),
            fileModel.originalSourcePath,
            templateDatas,
            broaderImports,
            fileModel.importAliasByImportUri,
            fileModel.mapperFileImportUri);

    if (context.hasWarnings) {
      for (final warning in context.warnings) {
        _log.warning(warning);
      }
    }
    context.throwIfErrors();
    return result;
  }

  (
    List<(MappableClassInfo, Elem?)> toplevel,
    List<(MappableClassInfo, Elem?)> nested
  ) collectResourceInfos(Iterable<ClassElem> classElements,
      ValidationContext context, Iterable<EnumElem> enumElements,
      {Set<Elem>? visited, bool toplevel = true}) {
    visited ??= <Elem>{};
    // Collect all resource info and element pairs (class or enum)
    final resourceInfosWithElements = <(MappableClassInfo, Elem?)>[];
    final allFieldTypes = <DartType>{};
    for (final classElement in classElements) {
      visited.add(classElement);
      final MappableClassInfo? resourceInfo =
          processClass(context, classElement);
      if (resourceInfo != null) {
        allFieldTypes.addAll(resourceInfo.properties
            .map((p) => p.propertyInfo?.annotation.itemType)
            .nonNulls);
        resourceInfosWithElements.add((resourceInfo, classElement));
      }
    }

    // Process enums
    for (final enumElement in enumElements) {
      visited.add(enumElement);
      final enumInfo = EnumProcessor.processEnum(
        context.withContext(enumElement.name),
        enumElement,
      );

      if (enumInfo != null) {
        allFieldTypes.addAll(enumInfo.properties
            .map((p) => p.propertyInfo?.annotation.itemType)
            .nonNulls);
        resourceInfosWithElements.add((enumInfo, enumElement));
      }
    }

    final classesToProcess = allFieldTypes
        .where((t) => t.isElementClass)
        .map((t) => t.element)
        .whereType<ClassElem>()
        .where((elem) => !visited!.contains(elem))
        .toSet();
    final enumsToProcess = allFieldTypes
        .where((t) => t.isElementEnum)
        .map((t) => t.element)
        .whereType<EnumElem>()
        .where((elem) => !visited!.contains(elem))
        .toSet();
    final toplevelList =
        toplevel ? resourceInfosWithElements : <(MappableClassInfo, Elem?)>[];
    final nestedList =
        toplevel ? <(MappableClassInfo, Elem?)>[] : resourceInfosWithElements;
    if (classesToProcess.isNotEmpty || enumsToProcess.isNotEmpty) {
      final (extraToplevel, extraNested) = collectResourceInfos(
          classesToProcess, context, enumsToProcess,
          visited: visited, toplevel: false);
      toplevelList.addAll(extraToplevel);
      nestedList.addAll(extraNested);
    }
    return (toplevelList, nestedList);
  }

  static MappableClassInfo<BaseMappingAnnotationInfo<dynamic>>? processClass(
      ValidationContext context, ClassElem classElement) {
    return ResourceProcessor.processClass(
          context.withContext(classElement.name),
          classElement,
        ) ??
        IriProcessor.processClass(
          context.withContext(classElement.name),
          classElement,
        ) ??
        LiteralProcessor.processClass(
          context.withContext(classElement.name),
          classElement,
        );
  }

  /// Performs a topological sort on mappers to ensure dependencies are processed first.
  ///
  /// Returns a list where each mapper either has no dependencies or depends only on
  /// mappers that appear earlier in the list. External dependencies (not in the
  /// mapper list) are ignored for sorting purposes.
  ///
  /// Throws [StateError] if circular dependencies are detected within the mapper set.
  static List<MapperModel> topologicalSort(List<MapperModel> mappers) {
    final mapperById = <MapperRef, MapperModel>{
      for (final mapper in mappers) mapper.id: mapper
    };
    final visited = <MapperRef>{};
    final visiting = <MapperRef>{};
    final result = <MapperModel>[];

    void visit(MapperModel mapper) {
      final mapperId = mapper.id;

      if (visited.contains(mapperId)) {
        return; // Already processed
      }

      if (visiting.contains(mapperId)) {
        throw StateError(
            'Circular dependency detected involving mapper ${mapperId.id}. '
            'Dependency chain: ${visiting.map((id) => id.id).join(' -> ')} -> ${mapperId.id}');
      }

      visiting.add(mapperId);

      // Process dependencies that are also in our mapper set
      for (final dependency in mapper.dependencies) {
        if (dependency is MapperDependency) {
          final dependentMapperId = dependency.mapperRef;
          final dependentMapper = mapperById[dependentMapperId];

          // Only process if the dependency is in our mapper set
          if (dependentMapper != null) {
            visit(dependentMapper);
          }
          // If dependency is not in our set, it's external - ignore for sorting
        }
        // External dependencies (non-MapperDependency) are ignored for sorting
      }

      visiting.remove(mapperId);
      visited.add(mapperId);
      result.add(mapper);
    }

    // Visit all mappers to ensure we process all connected components
    for (final mapper in mappers) {
      if (!visited.contains(mapper.id)) {
        visit(mapper);
      }
    }

    return result;
  }
}
