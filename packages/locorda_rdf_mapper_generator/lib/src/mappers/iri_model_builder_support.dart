import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_generator/src/mappers/mapped_model_builder.dart';
import 'package:locorda_rdf_mapper_generator/src/mappers/mapper_model.dart';
import 'package:locorda_rdf_mapper_generator/src/mappers/util.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/util.dart';
import 'package:locorda_rdf_mapper_generator/src/utils/iri_parser.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';

class IriModelBuilderSupport {
  static IriModel? buildIriData(
      String referenceName,
      String? template,
      MapperRefInfo<IriTermMapper>? mapper,
      Code? type,
      List<IriPartInfo>? iriParts,
      IriTemplateInfo? templateInfo,
      List<PropertyInfo>? fields,
      Code mappedClassName,
      {String? providedAs}) {
    final mapperRef = mapper == null || type == null
        ? null
        : mapperRefInfoToDependency(
            type, referenceName, mapper, mappedClassName);

    final rdfPropertyFields = fields
        ?.where((f) => f.propertyInfo != null)
        .map((f) => f.propertyInfo!.name)
        .toSet();
    final iriMapperParts = iriParts
            ?.map((p) => IriPartModel(
                  name: p.name,
                  dartPropertyName: p.dartPropertyName,
                  isRdfProperty:
                      rdfPropertyFields?.contains(p.dartPropertyName) ?? false,
                ))
            .toList() ??
        [];
    return IriModel(
      template: template == null
          ? null
          : buildTemplateData(templateInfo!, fields ?? []),
      hasFullIriPartTemplate: hasFullIriPartTemplate(iriParts, template),
      mapper: mapperRef,
      iriMapperParts: iriMapperParts,
      providedAs: providedAs,
    );
  }

  static DependencyModel mapperRefInfoToDependency(
      Code type,
      String referenceName,
      MapperRefInfo<dynamic> mapper,
      Code mappedClassName) {
    return DependencyModel.mapper(
      type,
      referenceName,
      mapperRefInfoToMapperRef(mapper, mappedClassName),
    );
  }

  static MapperRef mapperRefInfoToMapperRef(
      MapperRefInfo<dynamic> mapper, Code mappedClassName) {
    if (mapper.factoryName != null) {
      final configCode =
          mapper.configInstance == null ? null : toCode(mapper.configInstance);
      return MapperRef.fromFactoryName(
          mapper.factoryName!, configCode, mapper.configType, mappedClassName);
    }
    if (mapper.name != null) {
      return MapperRef.fromInstanceName(mapper.name!);
    }
    if (mapper.type != null) {
      return MapperRef.fromImplementationClass(mapper.type!, mapper.rawType);
    }
    return MapperRef.fromInstantiationCode(toCode(mapper.instance));
  }

  static IriTemplateModel buildTemplateData(
      IriTemplateInfo iriTemplateInfo, List<PropertyInfo> fields) {
    final isStringByFieldName = {
      for (var field in fields) field.name: stringType == field.type,
    };
    VariableNameModel buildVariableNameData(VariableName variable) =>
        _buildVariableNameData(
            variable, isStringByFieldName[variable.dartPropertyName] ?? false);
    var propertyVariables =
        iriTemplateInfo.propertyVariables.map(buildVariableNameData).toSet();
    final tar = buildTemplatesAndRegex(iriTemplateInfo);
    return IriTemplateModel(
      template: iriTemplateInfo.template,
      propertyVariables: propertyVariables,
      contextVariables: iriTemplateInfo.contextVariableNames
          .map((vn) => DependencyUsingVariableModel(
              variableName: vn.name,
              dependency: DependencyModel.external(
                  Code.literal('String Function()'), '${vn.name}Provider',
                  isProvider: true)))
          .toSet(),
      variables:
          iriTemplateInfo.variableNames.map(buildVariableNameData).toSet(),
      regexPattern: tar.regexPattern,
      interpolatedTemplate: tar.interpolatedTemplate,
      interpolatedFragmentTemplate: tar.interpolatedFragmentTemplate,
    );
  }

  static ({
    String? interpolatedFragmentTemplate,
    String interpolatedTemplate,
    String regexPattern
  }) buildTemplatesAndRegex(IriTemplateInfo iriTemplateInfo) {
    final interpolatedTemplate = buildInterpolatedTemplate(
        iriTemplateInfo.template, iriTemplateInfo.variableNames);
    final interpolatedFragmentTemplate = iriTemplateInfo.fragmentTemplate ==
            null
        ? null
        : buildInterpolatedTemplate(
            iriTemplateInfo.fragmentTemplate!, iriTemplateInfo.variableNames);
    final regexPattern =
        '^${buildRegexPattern(iriTemplateInfo.template, iriTemplateInfo.fragmentTemplate, iriTemplateInfo.variableNames)}\$';
    return (
      interpolatedFragmentTemplate: interpolatedFragmentTemplate,
      interpolatedTemplate: interpolatedTemplate,
      regexPattern: regexPattern
    );
  }

  static Set<VariableNameModel> buildPropertyVariables(
      IriTemplateInfo iriTemplateInfo, List<PropertyInfo> fields) {
    final isStringByFieldName = {
      for (var field in fields) field.name: stringType == field.type,
    };
    VariableNameModel buildVariableNameData(VariableName variable) =>
        _buildVariableNameData(
            variable, isStringByFieldName[variable.dartPropertyName] ?? false);
    return iriTemplateInfo.propertyVariables.map(buildVariableNameData).toSet();
  }

  static VariableNameModel _buildVariableNameData(
      VariableName variable, bool isString) {
    return VariableNameModel(
      isString: isString,
      variableName: variable.dartPropertyName,
      isMappedValue: variable.isMappedValue,
      placeholder:
          variable.canBeUri ? '{+${variable.name}}' : '{${variable.name}}',
    );
  }

  static String buildInterpolatedTemplate(
      String interpolatedTemplate, Set<VariableName> variableNames) {
    // Replace variables with Dart string interpolation syntax
    for (final variable in variableNames) {
      final placeholder =
          variable.canBeUri ? '{+${variable.name}}' : '{${variable.name}}';
      interpolatedTemplate = interpolatedTemplate.replaceAll(
          placeholder, '\${${variable.dartPropertyName}}');
    }

    return interpolatedTemplate;
  }

  static bool hasFullIriPartTemplate(
          List<IriPartInfo>? iriParts, String? template) =>
      iriParts?.length == 1 && template == '{+${iriParts![0].name}}';

  static List<MapperModel> buildIriMapperFromIriInfo(
      ValidationContext context, IriInfo iriInfo, String mapperImportUri) {
    final annotation = iriInfo.annotation;
    if (annotation.mapper != null) {
      throw Exception(
        'IriMapper cannot have a mapper defined in the annotation.',
      );
    }
    if (annotation.templateInfo == null) {
      throw Exception(
        'IriMapper must have a template defined in the annotation.',
      );
    }
    return buildIriMapper(
        context: context,
        mappedClassName: iriInfo.className,
        templateInfo: annotation.templateInfo!,
        iriParts: annotation.iriParts,
        mapperClassName:
            _toImplementationClass(iriInfo.className, mapperImportUri),
        constructors: iriInfo.constructors,
        properties: iriInfo.properties,
        annotations: iriInfo.annotations,
        registerGlobally: annotation.registerGlobally,
        mapperImportUri: mapperImportUri,
        enumValues: iriInfo.enumValues,
        type: switch (iriInfo.annotation.direction) {
          SerializationDirection.serializeOnly => MapperType.iriSerializer,
          SerializationDirection.deserializeOnly => MapperType.iriDeserializer,
          null => MapperType.iri,
        });
  }

  static Code _toImplementationClass(Code mappedClass, String mapperImportUri) {
    return Code.type('${mappedClass.codeWithoutAlias}Mapper',
        importUri: mapperImportUri);
  }

  static List<MapperModel> buildIriMapper(
      {required ValidationContext context,
      required Code mappedClassName,
      required final IriTemplateInfo templateInfo,
      final List<IriPartInfo>? iriParts,
      required Code mapperClassName,
      List<ConstructorInfo> constructors = const [],
      List<PropertyInfo> properties = const [],
      List<AnnotationInfo> annotations = const [],
      bool registerGlobally = false,
      required String mapperImportUri,
      List<EnumValueInfo> enumValues = const [],
      required MapperType type}) {
    final singleMappedValue = templateInfo.propertyVariables
        .where((v) => v.isMappedValue)
        .map((v) => VariableNameModel(
            isMappedValue: v.isMappedValue,
            variableName: v.name,
            isString: mappedClassName == stringType,
            placeholder: '{${v.name}}'))
        .singleOrNull;

    final propertyVariables =
        IriModelBuilderSupport.buildPropertyVariables(templateInfo, properties);
    final tar = buildTemplatesAndRegex(templateInfo);
    final contextVariables = templateInfo.contextVariableNames.map((variable) {
      final dependency = DependencyModel.external(
          Code.literal('String Function()'), variable.name + 'Provider',
          isProvider: true);
      return DependencyUsingVariableModel(
        dependency: dependency,
        variableName: variable.name,
      );
    }).toSet();
    final dependencies = contextVariables.map((v) => v.dependency).toList();

    if (enumValues.isNotEmpty) {
      return buildIriEnumMapper(
        templateInfo,
        mappedClassName,
        mapperImportUri,
        constructors,
        properties,
        context,
        mapperClassName,
        registerGlobally,
        dependencies,
        tar.interpolatedTemplate,
        tar.interpolatedFragmentTemplate,
        propertyVariables,
        tar.regexPattern,
        contextVariables,
        singleMappedValue,
        enumValues,
        type,
      );
    }
    return buildIriClassMapper(
      mappedClassName,
      mapperImportUri,
      constructors,
      properties,
      annotations,
      context,
      mapperClassName,
      registerGlobally,
      dependencies,
      tar.interpolatedTemplate,
      tar.interpolatedFragmentTemplate,
      propertyVariables,
      tar.regexPattern,
      contextVariables,
      singleMappedValue,
      type,
    );
  }

  static List<MapperModel> buildIriEnumMapper(
    IriTemplateInfo templateInfo,
    Code mappedClassName,
    String mapperImportUri,
    List<ConstructorInfo> constructors,
    List<PropertyInfo> fields,
    ValidationContext context,
    Code mapperClassName,
    bool registerGlobally,
    List<DependencyModel> dependencies,
    String interpolatedTemplate,
    String? interpolatedFragmentTemplate,
    Set<VariableNameModel> propertyVariables,
    String regexPattern,
    Set<DependencyUsingVariableModel> contextVariables,
    VariableNameModel? singleMappedValue,
    List<EnumValueInfo> enumValues,
    MapperType mapperType,
  ) {
    return [
      IriEnumMapperModel(
        id: MapperRef.fromImplementationClass(mapperClassName),
        enumValues: enumValues.map(toEnumValueModel).toList(),
        mappedClass: mappedClassName,
        implementationClass: mapperClassName,
        registerGlobally: registerGlobally,
        dependencies: dependencies,
        interpolatedTemplate: interpolatedTemplate,
        interpolatedFragmentTemplate: interpolatedFragmentTemplate,
        propertyVariables: propertyVariables,
        regexPattern: regexPattern,
        contextVariables: contextVariables,
        singleMappedValue: singleMappedValue,
        hasFullIriTemplate: IriModelBuilderSupport.hasFullIriPartTemplate(
            templateInfo.iriParts, templateInfo.template),
        type: mapperType,
      ),
    ];
  }

  static List<MapperModel> buildIriClassMapper(
      Code mappedClassName,
      String mapperImportUri,
      List<ConstructorInfo> constructors,
      List<PropertyInfo> fields,
      List<AnnotationInfo> annotations,
      ValidationContext context,
      Code mapperClassName,
      bool registerGlobally,
      List<DependencyModel> dependencies,
      String interpolatedTemplate,
      String? interpolatedFragmentTemplate,
      Set<VariableNameModel> propertyVariables,
      String regexPattern,
      Set<DependencyUsingVariableModel> contextVariables,
      VariableNameModel? singleMappedValue,
      MapperType mapperType) {
    final mappedClassModel = MappedClassModelBuilder.buildMappedClassModel(
        context,
        mappedClassName,
        mapperImportUri,
        constructors,
        fields,
        annotations,
        vocab: null);

    // Check that all constructor parameters and non-constructor fields are IRI parts
    final invalidParameters = mappedClassModel.properties
        .where((p) => p.isNeedsToBeSet && !p.isIriPart);
    if (invalidParameters.isNotEmpty) {
      context.addError(
        'Iri class constructor must only have IRI part parameters, but found: ${invalidParameters.join(', ')}',
      );
      return const [];
    }
    return [
      IriClassMapperModel(
        id: MapperRef.fromImplementationClass(mapperClassName),
        mappedClass: mappedClassName,
        mappedClassModel: mappedClassModel,
        implementationClass: mapperClassName,
        registerGlobally: registerGlobally,
        dependencies: dependencies,
        interpolatedTemplate: interpolatedTemplate,
        interpolatedFragmentTemplate: interpolatedFragmentTemplate,
        propertyVariables: propertyVariables,
        regexPattern: regexPattern,
        contextVariables: contextVariables,
        singleMappedValue: singleMappedValue,
        type: mapperType,
      ),
    ];
  }
}
