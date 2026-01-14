// import 'package:analyzer/dart/element/element2.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/mappers/iri_model_builder_support.dart';
import 'package:locorda_rdf_mapper_generator/src/mappers/mapped_model_builder.dart';
import 'package:locorda_rdf_mapper_generator/src/mappers/resource_model_builder_support.dart';
import 'package:locorda_rdf_mapper_generator/src/mappers/util.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/util.dart';

import '../processors/models/mapper_info.dart';
import '../validation/validation_context.dart';
import 'mapper_model.dart';

/// Builds mapper models from info objects (conversion from Info layer to Model layer)
///
class MapperModelBuilder {
  static String getMapperImportUri(String packageName, String sourcePath) =>
      'asset:$packageName/${sourcePath}';

  static Map<String, String> _indexImportAliasByIdentifier(
    List<(MappableClassInfo, Elem?)> classInfosWithElement,
  ) {
    final allLibraryImports = classInfosWithElement
        .where((e) => e.$2 != null)
        .expand<LibraryImport>((e) => e.$2!.libraryImports);
    return {
      for (final import in allLibraryImports)
        if (import.libraryIdentifier != null)
          import.libraryIdentifier!: import.prefix ?? '',
    };
  }

  static MapperFileModel buildMapperModels(
    ValidationContext context,
    String packageName,
    String sourcePath,
    List<(MappableClassInfo, Elem?)> classInfosWithElement,
  ) {
    String mapperImportUri = getMapperImportUri(packageName,
        sourcePath.replaceAll('.dart', '.locorda_rdf_mapper.g.dart'));

    final importAliasByIdentifier =
        _indexImportAliasByIdentifier(classInfosWithElement);
    final mapperModels = _buildModels(
        context, mapperImportUri, classInfosWithElement.map((e) => e.$1));
    return MapperFileModel(
      packageName: packageName,
      originalSourcePath: sourcePath,
      mappers: mapperModels,
      importAliasByImportUri: importAliasByIdentifier,
      mapperFileImportUri: mapperImportUri,
    );
  }

  static List<MapperModel> buildExternalMapperModels(
    ValidationContext context,
    List<(MappableClassInfo, Elem?)> classInfosWithElement,
  ) {
    return classInfosWithElement.map((e) => e.$1).expand<MapperModel>((m) {
      final import = m.className.imports.single;
      return buildModel(
          context, import.replaceAll('.dart', '.locorda_rdf_mapper.g.dart'), m);
    }).toList();
  }

  static List<MapperModel> _buildModels(
    ValidationContext context,
    String mapperImportUri,
    Iterable<MappableClassInfo> classInfos,
  ) {
    return classInfos
        .expand<MapperModel>((m) => buildModel(context, mapperImportUri, m))
        .toList();
  }

  static List<MapperModel> buildModel(ValidationContext context,
          String mapperImportUri, MappableClassInfo classInfo) =>
      switch (classInfo) {
        ResourceInfo _ => classInfo.annotation.mapper != null
            ? buildCustomMapper(
                context, classInfo.className, classInfo.annotation)
            : // generate custom mapper if specified
            ResourceModelBuilderSupport.buildResourceMapper(
                context, classInfo, mapperImportUri),
        IriInfo iriInfo => iriInfo.annotation.mapper != null
            ? buildCustomMapper(context, iriInfo.className, iriInfo.annotation)
            : IriModelBuilderSupport.buildIriMapperFromIriInfo(
                context, iriInfo, mapperImportUri),
        LiteralInfo literalInfo => literalInfo.annotation.mapper != null
            ? buildCustomMapper(
                context, literalInfo.className, literalInfo.annotation)
            : buildLiteralMapper(context, literalInfo, mapperImportUri),
      };

  static List<MapperModel> buildCustomMapper(ValidationContext context,
      Code className, BaseMappingAnnotationInfo annotation) {
    assert(annotation.mapper != null);
    final mapper = annotation.mapper!;
    final type = switch (annotation) {
      RdfGlobalResourceInfo _ => MapperType.globalResource,
      RdfLocalResourceInfo _ => MapperType.localResource,
      RdfIriInfo _ => MapperType.iri,
      RdfLiteralInfo _ => MapperType.literal,
    };

    if (mapper.type == null && mapper.instance == null && mapper.name == null) {
      context.addError(
        'Custom mapper must have either a name, type or instance defined in the annotation.',
      );
      return [];
    }
    final id = mapper.type != null
        ? MapperRef.fromImplementationClass(mapper.type!, mapper.rawType)
        : (mapper.instance != null
            ? MapperRef.fromInstantiationCode(toCode(mapper.instance!))
            : MapperRef.fromInstanceName(mapper.name!));

    var instanceName = mapper.name;
    var implementationClass = mapper.type;
    var customMapperInstance =
        mapper.instance == null ? null : toCode(mapper.instance);
    return [
      CustomMapperModel(
        id: id,
        type: type,
        mappedClass: className,
        instanceName: instanceName,
        instanceInstantiationCode: customMapperInstance,
        implementationClass: implementationClass,
        registerGlobally: annotation.registerGlobally,
      )
    ];
  }

  static List<MapperModel> buildLiteralMapper(ValidationContext context,
      LiteralInfo literalInfo, String mapperImportUri) {
    final annotation = literalInfo.annotation;
    if (annotation.mapper != null) {
      throw Exception(
        'LiteralMapper cannot have a mapper defined in the annotation.',
      );
    }
    final mappedClass = literalInfo.className;
    final implementationClass =
        _toImplementationClass(mappedClass, mapperImportUri);

    final datatype = annotation.datatype?.code;
    final fromLiteralTermMethod = annotation.fromLiteralTermMethod;
    final toLiteralTermMethod = annotation.toLiteralTermMethod;

    if (literalInfo.enumValues.isNotEmpty) {
      return _buildLiteralEnumMapper(implementationClass, mappedClass, datatype,
          fromLiteralTermMethod, toLiteralTermMethod, literalInfo);
    }

    return _buildLiteralClassMapper(
        context,
        mappedClass,
        mapperImportUri,
        literalInfo,
        implementationClass,
        datatype,
        fromLiteralTermMethod,
        toLiteralTermMethod);
  }

  static List<MapperModel> _buildLiteralClassMapper(
      ValidationContext context,
      Code mappedClass,
      String mapperImportUri,
      LiteralInfo literalInfo,
      Code implementationClass,
      Code? datatype,
      String? fromLiteralTermMethod,
      String? toLiteralTermMethod) {
    final mappedClassModel = MappedClassModelBuilder.buildMappedClassModel(
      context,
      mappedClass,
      mapperImportUri,
      literalInfo.constructors,
      literalInfo.properties,
      literalInfo.annotations,
    );

    final isMethodBased =
        fromLiteralTermMethod != null && toLiteralTermMethod != null;

    final invalidParameters = mappedClassModel.properties.where(
        (p) => p.isNeedsToBeSet && !(p.isRdfLanguageTag || p.isRdfValue));
    if (!isMethodBased && invalidParameters.isNotEmpty) {
      context.addError(
        'LiteralMapper must only have Value or LanguagePart part constructor parameters, but found: ${invalidParameters.join(', ')}',
      );
      return [];
    }

    return [
      LiteralClassMapperModel(
        id: MapperRef.fromImplementationClass(implementationClass),
        mappedClass: mappedClass,
        implementationClass: implementationClass,
        dependencies: const [], // Generated Literal Mappers have no dependencies
        datatype: datatype,
        fromLiteralTermMethod: fromLiteralTermMethod,
        toLiteralTermMethod: toLiteralTermMethod,
        mappedClassModel: mappedClassModel,
        registerGlobally: literalInfo.annotation.registerGlobally,
        type: switch (literalInfo.annotation.direction) {
          SerializationDirection.serializeOnly => MapperType.literalSerializer,
          SerializationDirection.deserializeOnly =>
            MapperType.literalDeserializer,
          null => MapperType.literal,
        },
      )
    ];
  }

  static List<MapperModel> _buildLiteralEnumMapper(
      Code implementationClass,
      Code mappedClass,
      Code? datatype,
      String? fromLiteralTermMethod,
      String? toLiteralTermMethod,
      LiteralInfo literalInfo) {
    return [
      LiteralEnumMapperModel(
        id: MapperRef.fromImplementationClass(implementationClass),
        mappedClass: mappedClass,
        implementationClass: implementationClass,
        dependencies: const [], // Generated Literal Mappers have no dependencies
        datatype: datatype,
        fromLiteralTermMethod: fromLiteralTermMethod,
        toLiteralTermMethod: toLiteralTermMethod,
        enumValues: literalInfo.enumValues.map(toEnumValueModel).toList(),
        registerGlobally: literalInfo.annotation.registerGlobally,
        type: switch (literalInfo.annotation.direction) {
          SerializationDirection.serializeOnly => MapperType.literalSerializer,
          SerializationDirection.deserializeOnly =>
            MapperType.literalDeserializer,
          null => MapperType.literal,
        },
      )
    ];
  }

  static Code _toImplementationClass(Code mappedClass, String mapperImportUri) {
    return Code.type('${mappedClass.codeWithoutAlias}Mapper',
        importUri: mapperImportUri);
  }
}
