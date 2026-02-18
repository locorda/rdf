library;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_generator/src/mappers/mapper_model.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/template_data.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/util.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';

import '../templates/code.dart';

class ResolvedMapperFileModel {
  /// The import URI for the generated mapper file
  final String packageName;

  /// The source path of the original Dart file
  final String originalSourcePath;
  final String mapperFileImportUri;

  /// The list of mappers defined in this file
  final List<ResolvedMapperModel> mappers;
  final Map<String, String> importAliasByImportUri;

  const ResolvedMapperFileModel({
    required this.packageName,
    required this.originalSourcePath,
    required this.importAliasByImportUri,
    required this.mapperFileImportUri,
    required this.mappers,
  });

  @override
  String toString() {
    return 'ResolvedMapperFileModel{importUri: $mapperFileImportUri, mappers: $mappers}';
  }
}

/// Represents a mapper that will be generated, with its dependencies clearly defined
sealed class ResolvedMapperModel {
  /// Unique identifier for this mapper
  MapperRef get id;

  /// The class this mapper handles
  Code get mappedClass;

  /// the type of mapper
  MapperType get type;

  /// Whether this mapper should be registered globally
  bool get registerGlobally;

  Iterable<DependencyResolvedModel> get dependencies;

  List<ConstructorParameterResolvedModel> get mapperConstructorParameters =>
      dependencies.isEmpty
          ? const []
          : dependencies
              .where((d) => d.constructorParam?.isRequired ?? false)
              .map((d) => d.constructorParam)
              .nonNulls
              .toList(growable: false);

  List<FieldResolvedModel> get mapperFields => dependencies.isEmpty
      ? const []
      : dependencies.map((d) => d.field).nonNulls.toList(growable: false);

  Code get interfaceClass => interfaceClassFor(mappedClass);

  Code interfaceClassFor(Code cls) => Code.combine([
        Code.literal(type.dartInterfaceName),
        Code.genericParamsList([cls])
      ]);

  MappableClassMapperTemplateData toTemplateData(
      ValidationContext context, String mapperImportUri);
}

sealed class GeneratedResolvedMapperModel extends ResolvedMapperModel {
  /// The generated mapper class name
  Code get implementationClass;
}

class ConstructorParameterResolvedModel {
  final Code type;
  final String paramName;
  final Code? defaultValue;

  ConstructorParameterResolvedModel(
      {required this.type,
      required this.paramName,
      required this.defaultValue});

  bool get isRequired => defaultValue == null;

  @override
  String toString() {
    return 'ConstructorParameterResolvedModel{type: $type, paramName: $paramName, defaultValue: $defaultValue}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConstructorParameterResolvedModel) return false;
    return type == other.type &&
        paramName == other.paramName &&
        defaultValue == other.defaultValue;
  }

  @override
  int get hashCode =>
      type.hashCode ^ paramName.hashCode ^ defaultValue.hashCode;

  ConstructorParameterData toTemplateData(ValidationContext context) {
    return ConstructorParameterData(
      type: type,
      parameterName: paramName,
      defaultValue: defaultValue,
    );
  }
}

class FactoryInstantiatedConstructorParameterResolvedModel
    extends ConstructorParameterResolvedModel {
  final Code initFunctionParameterType;
  final String initFunctionParameterName;
  final Code initFunctionParameterCode;
  FactoryInstantiatedConstructorParameterResolvedModel({
    required this.initFunctionParameterType,
    required this.initFunctionParameterName,
    required this.initFunctionParameterCode,
    required Code type,
    required String paramName,
  }) : super(type: type, paramName: paramName, defaultValue: null);

  ConstructorParameterData toTemplateData(ValidationContext context) {
    return ConstructorParameterData.full(
        type: type,
        parameterName: paramName,
        defaultValue: defaultValue,
        initFunctionParameterType: initFunctionParameterType,
        initFunctionParameterName: initFunctionParameterName,
        initFunctionParameterCode: initFunctionParameterCode);
  }
}

class AppVocabResolvedModel {
  final String appBaseUri;
  final String vocabPath;
  final IriTerm defaultBaseClass;
  final Map<String, IriTerm> wellKnownProperties;

  /// Optional human-readable label for the ontology.
  final String? label;

  /// Optional description for the ontology.
  final String? comment;

  /// Optional metadata for the generated ontology.
  /// Maps predicate IRI strings to RDF objects.
  final Map<IriTerm, List<RdfObject>> metadata;

  const AppVocabResolvedModel({
    required this.appBaseUri,
    required this.vocabPath,
    required this.defaultBaseClass,
    this.wellKnownProperties = const {},
    this.label,
    this.comment,
    this.metadata = const {},
  });

  AppVocabData? toTemplateData(ValidationContext context) {
    return AppVocabData(
      appBaseUri: appBaseUri,
      vocabPath: vocabPath,
      defaultBaseClass: defaultBaseClass,
      wellKnownProperties: wellKnownProperties,
      label: label,
      comment: comment,
      metadata: metadata,
    );
  }
}

/// A mapper for global resources
class ResourceResolvedMapperModel extends GeneratedResolvedMapperModel {
  @override
  final MapperRef id;

  @override
  final Code mappedClass;

  final MappedClassResolvedModel mappedClassModel;

  @override
  final Code implementationClass;

  @override
  final bool registerGlobally;

  final Code? typeIri;

  final Code termClass;

  /// IRI strategy information
  final IriResolvedModel? iriStrategy;

  /// Vocabulary generation metadata (appBaseUri and vocabPath)
  final AppVocabResolvedModel? vocab;

  /// SubClass relationship IRI
  final Code? subClassOf;

  /// SubClass relationship IRI value (for vocab generation)
  final String? subClassOfIri;

  /// Optional metadata for the generated vocabulary class resource.
  final Map<IriTerm, List<RdfObject>> genVocabMetadata;

  final bool needsReader;
  final Iterable<DependencyResolvedModel> dependencies;

  final Iterable<ProvidesResolvedModel> provides;

  final List<String> typeParameters;

  final MapperType type;

  ResourceResolvedMapperModel({
    required this.id,
    required this.mappedClass,
    required this.mappedClassModel,
    required this.implementationClass,
    required this.registerGlobally,
    required this.typeIri,
    required this.termClass,
    required this.iriStrategy,
    this.vocab,
    this.subClassOf,
    this.subClassOfIri,
    this.genVocabMetadata = const {},
    required this.needsReader,
    required this.dependencies,
    required this.provides,
    this.typeParameters = const [],
    required this.type,
  });

  Code appendTypeParameters(Code cls) => typeParameters.isEmpty
      ? cls
      : Code.combine(
          [cls, Code.genericParamsList(typeParameters.map(Code.literal))]);

  @override
  MappableClassMapperTemplateData toTemplateData(
      ValidationContext context, String mapperImportUri) {
    final providesByVariableNames = {
      for (final p in provides) p.providerName: p
    };
    final mappedClassData = mappedClassModel.toTemplateData(
        context, providesByVariableNames, mapperImportUri);
    final fullMappedClass = appendTypeParameters(mappedClass);
    final fullImplementationClass = appendTypeParameters(implementationClass);
    return ResourceMapperTemplateData(
        className: fullMappedClass,
        mapperClassName: fullImplementationClass,
        mapperInterfaceName: interfaceClassFor(fullMappedClass),
        typeParameters: typeParameters,
        registerGlobally: registerGlobally,
        typeIri: typeIri,
        termClass: termClass,
        iriStrategy: iriStrategy?.toTemplateData(context),
        vocab: vocab?.toTemplateData(context),
        subClassOf: subClassOf,
        subClassOfIri: subClassOfIri,
        genVocabMetadata: genVocabMetadata,
        propertiesToDeserializeAsConstructorParameters:
            mappedClassData.constructorParameters,
        needsReader: needsReader,
        propertiesToSerialize: mappedClassData.propertiesToSerialize,
        propertiesToDeserializeAsFields:
            mappedClassData.nonConstructorRdfFields,
        direction: type.direction,
        mapperFields: mapperFields
            .map((f) => f.toTemplateData(context))
            .toList(growable: false),
        mapperConstructor: _toMapperConstructorTemplateData(
            implementationClass, dependencies, context));
  }
}

class IriMappingResolvedModel {
  final bool hasMapper;
  final ResolvedMapperModel? resolvedMapper;
  IriMappingResolvedModel(
      {required this.hasMapper, required this.resolvedMapper});
}

class LiteralMappingResolvedModel {
  final bool hasMapper;
  final ResolvedMapperModel? resolvedMapper;
  LiteralMappingResolvedModel(
      {required this.hasMapper, required this.resolvedMapper});
}

class GlobalResourceMappingResolvedModel {
  final bool hasMapper;
  final ResolvedMapperModel? resolvedMapper;
  GlobalResourceMappingResolvedModel(
      {required this.hasMapper, required this.resolvedMapper});
}

class LocalResourceMappingResolvedModel {
  final bool hasMapper;
  final ResolvedMapperModel? resolvedMapper;

  LocalResourceMappingResolvedModel(
      {required this.hasMapper, required this.resolvedMapper});
}

class ContextualMappingResolvedModel {
  final bool hasMapper;
  final ResolvedMapperModel? resolvedMapper;

  ContextualMappingResolvedModel({
    required this.hasMapper,
    required this.resolvedMapper,
  });
}

class CollectionMappingResolvedModel {
  final bool hasMapper;
  final ResolvedMapperModel? resolvedMapper;

  CollectionMappingResolvedModel(
      {required this.hasMapper, required this.resolvedMapper});
}

/// Information about collection properties
class CollectionResolvedModel {
  final bool isCollection;
  final bool isMap;
  final bool isIterable;
  final Code? collectionMapperFactoryCode;
  final Code? elementTypeCode;
  final Code? mapKeyTypeCode;
  final Code? mapValueTypeCode;

  final MappedClassResolvedModel? mapEntryClassModel;

  const CollectionResolvedModel(
      {required this.isCollection,
      required this.isMap,
      required this.isIterable,
      required this.collectionMapperFactoryCode,
      required this.elementTypeCode,
      required this.mapKeyTypeCode,
      required this.mapValueTypeCode,
      required this.mapEntryClassModel});
}

class PropertyResolvedModel {
  final String propertyName;
  final bool isRequired;
  final bool isFieldNullable;
  final bool isRdfProperty;
  final bool isIriPart;
  final bool isRdfValue;
  final bool isRdfLanguageTag;
  final bool isRdfMapEntry;
  final bool isRdfMapKey;
  final bool isRdfMapValue;
  final bool isRdfUnmappedTriples;
  final bool globalUnmapped;
  final String? iriPartName;
  final String? constructorParameterName;
  final bool isNamedConstructorParameter;

  final bool include;
  final Code? predicate;
  final String? predicateIri;
  final String? fragment;
  final String? vocabPropertySource;
  final bool noDomain;
  final Map<IriTerm, List<RdfObject>> metadata;
  final Code? defaultValue;
  final bool hasDefaultValue;
  final bool includeDefaultsInSerialization;
  final Code dartType;

  final CollectionResolvedModel collectionInfo;
  final CollectionMappingResolvedModel? collectionMapping;
  final IriMappingResolvedModel? iriMapping;
  final LiteralMappingResolvedModel? literalMapping;
  final GlobalResourceMappingResolvedModel? globalResourceMapping;
  final LocalResourceMappingResolvedModel? localResourceMapping;
  final ContextualMappingResolvedModel? contextualMapping;

  const PropertyResolvedModel({
    required this.propertyName,
    required this.isRequired,
    required this.isFieldNullable,
    required this.isRdfProperty,
    required this.isIriPart,
    required this.isRdfValue,
    required this.isRdfLanguageTag,
    required this.isRdfMapEntry,
    required this.isRdfMapKey,
    required this.isRdfMapValue,
    required this.isRdfUnmappedTriples,
    required this.globalUnmapped,
    required this.iriPartName,
    required this.constructorParameterName,
    required this.isNamedConstructorParameter,
    required this.include,
    required this.predicate,
    required this.predicateIri,
    required this.fragment,
    required this.vocabPropertySource,
    required this.noDomain,
    this.metadata = const {},
    required this.defaultValue,
    required this.hasDefaultValue,
    required this.includeDefaultsInSerialization,
    required this.dartType,
    required this.collectionInfo,
    required this.collectionMapping,
    required this.iriMapping,
    required this.literalMapping,
    required this.globalResourceMapping,
    required this.localResourceMapping,
    required this.contextualMapping,
  });

  bool get isConstructorParameter => constructorParameterName != null;

  Code? _generateBuilderCall(
    ValidationContext context, {
    required Map<String, ProvidesResolvedModel> providesByProviderNames,
  }) {
    if (isRdfUnmappedTriples) {
      // Generate addUnmapped call for unmapped triples
      return Code.combine([
        Code.literal('.addUnmapped(resource.'),
        Code.literal(propertyName),
        Code.literal(')')
      ]);
    }

    if (!isRdfProperty || predicate == null) {
      return null;
    }
    if (!include) {
      return null;
    }

    final customSerializerParameters = _extractCustomSerializerParameters(
        constructorParameterName ?? propertyName, this, providesByProviderNames,
        name: collectionInfo.collectionMapperFactoryCode != null
            ? 'itemSerializer'
            : 'serializer');

    final serializerCall = _generateSerializerCall(
      context,
      this,
      namedParameters: customSerializerParameters,
      predicate: predicate!,
      propertyName: propertyName,
    );

    final checkDefaultValue =
        hasDefaultValue && !includeDefaultsInSerialization;
    final checkNullValue = isFieldNullable;
    final useConditionalSerialization = checkDefaultValue || checkNullValue;

    if (!useConditionalSerialization) {
      return serializerCall;
    }
    return Code.combine([
      Code.literal('.when'),
      Code.paramsList([
        Code.combine([
          if (checkDefaultValue)
            Code.literal('resource.$propertyName != $defaultValue'),
          if (checkNullValue) Code.literal('resource.$propertyName != null'),
        ], separator: ' && '),
        Code.combine([
          Code.literal('(b) => b'),
          serializerCall,
        ])
      ]),
    ]);
  }

  Code? _generateReaderCall({
    required Map<String, ProvidesResolvedModel> providesByProviderNames,
  }) {
    if (isRdfUnmappedTriples) {
      // Generate getUnmapped call for unmapped triples
      final globalParameter = globalUnmapped ? 'globalUnmapped: true' : '';
      return Code.combine([
        Code.literal('reader.getUnmapped<'),
        dartType,
        Code.literal('>('),
        if (globalUnmapped) Code.literal(globalParameter),
        Code.literal(')')
      ]);
    }

    if (!isRdfProperty || predicate == null) {
      return null;
    }

    final customDeserializerParameters = _extractCustomDeserializerParameters(
      constructorParameterName != null
          ? constructorParameterName!
          : propertyName,
      this,
      providesByProviderNames,
      name: collectionInfo.collectionMapperFactoryCode != null
          ? 'itemDeserializer'
          : 'deserializer',
    );

    return _getReaderCall(this,
        predicate: predicate!,
        extraNamedParameters: customDeserializerParameters);
  }

  PropertyData toTemplateData(
      ValidationContext context,
      Code className,
      Map<String, ProvidesResolvedModel> providesByProviderNames,
      String mapperImportUri) {
    final builderCall = _generateBuilderCall(
      context,
      providesByProviderNames: providesByProviderNames,
    );

    final readerCall = _generateReaderCall(
      providesByProviderNames: providesByProviderNames,
    );

    return PropertyData(
        propertyName: propertyName,
        isFieldNullable: isFieldNullable,
        isRdfProperty: isRdfProperty,
        isIriPart: isIriPart,
        isRdfValue: isRdfValue,
        isRdfLanguageTag: isRdfLanguageTag,
        isRdfMapEntry: isRdfMapEntry,
        isRdfMapKey: isRdfMapKey,
        isRdfMapValue: isRdfMapValue,
        isRdfUnmappedTriples: isRdfUnmappedTriples,
        iriPartName: iriPartName,
        name: constructorParameterName,
        isNamed: isNamedConstructorParameter,
        include: include,
        defaultValue: defaultValue,
        hasDefaultValue: hasDefaultValue,
        dartType: dartType,
        predicateIri: predicateIri,
        fragment: fragment,
        vocabPropertySource: vocabPropertySource,
        noDomain: noDomain,
        metadata: metadata,
        readerCall: readerCall,
        builderCall: builderCall);
  }
}

typedef IsRdfFieldFilter = bool Function(PropertyData property);

class MappedClassResolvedModel {
  final Code className;
  final List<PropertyResolvedModel> properties;
  final IsRdfFieldFilter _isRdfField;
  final bool isMapValue;
  const MappedClassResolvedModel(
      {required this.className,
      required this.properties,
      required IsRdfFieldFilter isRdfFieldFilter,
      required this.isMapValue})
      : _isRdfField = isRdfFieldFilter;

  @override
  String toString() => 'MappedClass(className: $className)';

  MappedClassData toTemplateData(
      ValidationContext context,
      Map<String, ProvidesResolvedModel> providesByProviderNames,
      String mapperImportUri) {
    final convertedProperties = properties
        .map((p) => p.toTemplateData(
            context, className, providesByProviderNames, mapperImportUri))
        .toList(growable: false);
    return MappedClassData(
      className: className,
      constructorParameters: convertedProperties
          .where((p) => p.isConstructorParameter)
          .toList(growable: false),
      constructorRdfFields: convertedProperties
          .where((p) => p.isConstructorParameter && _isRdfField(p))
          .toList(growable: false),
      nonConstructorRdfFields: convertedProperties
          .where((p) => !p.isConstructorParameter && _isRdfField(p))
          .toList(growable: false),
      properties: convertedProperties,
    );
  }
}

class MappedClassData {
  final Code className;
  final List<PropertyData> constructorParameters;
  final List<PropertyData> constructorRdfFields;
  final List<PropertyData> nonConstructorRdfFields;
  List<PropertyData> get propertiesToSerialize => properties;
  final List<PropertyData> properties;

  List<PropertyData> get allRdfFields =>
      [...constructorRdfFields, ...nonConstructorRdfFields];

  const MappedClassData(
      {required this.className,
      required this.constructorParameters,
      required this.constructorRdfFields,
      required this.nonConstructorRdfFields,
      required this.properties});

  @override
  String toString() => 'MappedClass(className: $className)';
}

class ContextProviderResolvedModel {
  /// The name of the context variable
  final String variableName;

  /// The name of the private field that stores the provider
  final String privateFieldName;

  /// The name of the constructor parameter
  final String parameterName;

  /// The placeholder pattern to replace in IRI templates (e.g., '{baseUri}')
  final String placeholder;

  final bool isField;
  final Code type;
  const ContextProviderResolvedModel(
      {required this.variableName,
      required this.privateFieldName,
      required this.parameterName,
      required this.placeholder,
      this.isField = true,
      this.type = const Code.literal('String Function()')});

  ContextProviderData toTemplateData(ValidationContext context) {
    return ContextProviderData(
      variableName: variableName,
      privateFieldName: privateFieldName,
      parameterName: parameterName,
      placeholder: placeholder,
      isField: isField,
      type: type,
    );
  }
}

/// A mapper for IRI terms
sealed class IriResolvedMapperModel extends GeneratedResolvedMapperModel {
  @override
  final MapperRef id;

  @override
  final Code mappedClass;

  @override
  final Code implementationClass;

  @override
  final bool registerGlobally;

  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<VariableNameResolvedModel> propertyVariables;
  final Set<DependencyUsingVariableResolvedModel> contextVariables;

  /// The regex pattern built from the template.
  final String regexPattern;

  /// The template converted to Dart string interpolation syntax.
  final String interpolatedTemplate;
  final String? interpolatedFragmentTemplate;

  final VariableNameResolvedModel? singleMappedValue;

  final Iterable<DependencyResolvedModel> dependencies;
  final MapperType type;

  IriResolvedMapperModel({
    required this.id,
    required this.mappedClass,
    required this.implementationClass,
    required this.registerGlobally,
    required this.propertyVariables,
    required this.contextVariables,
    required this.interpolatedTemplate,
    required this.interpolatedFragmentTemplate,
    required this.regexPattern,
    required this.singleMappedValue,
    required this.dependencies,
    required this.type,
  });
}

class IriClassResolvedMapperModel extends IriResolvedMapperModel {
  final MappedClassResolvedModel mappedClassModel;

  IriClassResolvedMapperModel({
    required super.id,
    required super.mappedClass,
    required this.mappedClassModel,
    required super.implementationClass,
    required super.registerGlobally,
    required super.propertyVariables,
    required super.contextVariables,
    required super.interpolatedTemplate,
    required super.interpolatedFragmentTemplate,
    required super.regexPattern,
    required super.singleMappedValue,
    required super.dependencies,
    required super.type,
  });

  @override
  MappableClassMapperTemplateData toTemplateData(
    ValidationContext context,
    String mapperImportUri,
  ) {
    // This type of mapper does not provide any fields to children
    final providesByVariableNames = const <String, ProvidesResolvedModel>{};
    final mappedClassData = mappedClassModel.toTemplateData(
        context, providesByVariableNames, mapperImportUri);
    return IriMapperTemplateData(
      className: mappedClass,
      mapperClassName: implementationClass,
      mapperInterfaceName: interfaceClass,
      propertyVariables:
          propertyVariables.map((v) => v.toTemplateData(context)).toSet(),
      contextVariables:
          contextVariables.map((v) => v.toTemplateData(context)).toSet(),
      interpolatedTemplate: interpolatedTemplate,
      interpolatedFragmentTemplate: interpolatedFragmentTemplate,
      regexPattern: regexPattern,
      constructorParameters: mappedClassData.constructorParameters,
      nonConstructorFields: mappedClassData.nonConstructorRdfFields,
      registerGlobally: registerGlobally,
      singleMappedValue: singleMappedValue?.toTemplateData(context),
      mapperFields: mapperFields
          .map((f) => f.toTemplateData(context))
          .toList(growable: false),
      mapperConstructor: _toMapperConstructorTemplateData(
          implementationClass, dependencies, context),
      direction: type.direction,
    );
  }
}

MapperConstructorTemplateData _toMapperConstructorTemplateData(
  Code implementationClass,
  Iterable<DependencyResolvedModel> dependencies,
  ValidationContext context,
) {
  List<ConstructorParameterData> mapperConstructorParameters = dependencies
      .map((e) {
        if (e.constructorParam?.defaultValue != null &&
            (e.field?.isLate ?? false)) {
          return null; // skip late fields with default values
        } else {
          return e.constructorParam?.toTemplateData(context);
        }
      })
      .nonNulls
      .toSet() // deduplicate
      .toList(growable: false)
    ..sort(
      (a, b) => a.parameterName.compareTo(b.parameterName),
    );
  var hasAnyLateConstructorFields = dependencies
      .any((d) => d.constructorParam != null && (d.field?.isLate ?? false));
  bool isConst = !hasAnyLateConstructorFields;
  List<BodyAssignmentData> bodyAssignments = dependencies
      .where((p) =>
          p.constructorParam?.defaultValue != null &&
          (p.field?.isLate ?? false))
      .map((p) => BodyAssignmentData(
            fieldName: p.field!.name,
            defaultValue: p.constructorParam!.defaultValue!,
          ))
      .nonNulls
      .toSet() // deduplicate
      .toList()
    ..sort(
      (a, b) => a.fieldName.compareTo(b.fieldName),
    );
  List<ParameterAssignmentData> parameterAssignments = dependencies
      .where((p) => (p.field != null) && !(p.field?.isLate ?? false))
      .map((p) => ParameterAssignmentData(
            fieldName: p.field!.name,
            parameterName: p.constructorParam!.paramName,
          ))
      .toSet() // deduplicate
      .toList()
    ..sort((a, b) => a.parameterName.compareTo(b.parameterName));

  return MapperConstructorTemplateData(
    mapperClassName: implementationClass,
    parameterAssignments: parameterAssignments,
    bodyAssignments: bodyAssignments,
    mapperConstructorParameters: mapperConstructorParameters,
    isConst: isConst,
  );
}

class IriEnumResolvedMapperModel extends IriResolvedMapperModel {
  final List<EnumValueModel> enumValues;
  final bool hasFullIriTemplate;
  IriEnumResolvedMapperModel({
    required super.id,
    required super.mappedClass,
    required this.enumValues,
    required this.hasFullIriTemplate,
    required super.implementationClass,
    required super.registerGlobally,
    required super.propertyVariables,
    required super.contextVariables,
    required super.interpolatedTemplate,
    required super.interpolatedFragmentTemplate,
    required super.regexPattern,
    required super.singleMappedValue,
    required super.dependencies,
    required super.type,
  });

  @override
  MappableClassMapperTemplateData toTemplateData(
    ValidationContext context,
    String mapperImportUri,
  ) {
    return EnumIriMapperTemplateData(
      className: mappedClass,
      mapperClassName: implementationClass,
      mapperInterfaceName: interfaceClass,
      enumValues: enumValues.map((e) => e.toTemplateData(context)).toList(),
      interpolatedTemplate: interpolatedTemplate,
      interpolatedFragmentTemplate: interpolatedFragmentTemplate,
      regexPattern: regexPattern,
      registerGlobally: registerGlobally,
      contextVariables:
          contextVariables.map((v) => v.toTemplateData(context)).toSet(),
      requiresIriParsing: !hasFullIriTemplate,
      mapperFields: mapperFields
          .map((f) => f.toTemplateData(context))
          .toList(growable: false),
      mapperConstructor: _toMapperConstructorTemplateData(
          implementationClass, dependencies, context),
      direction: type.direction,
      // TODO: we could use a singleMappedValue here
      //singleMappedValue: singleMappedValue
    );
  }
}

/// A mapper for literal terms
sealed class LiteralResolvedMapperModel extends GeneratedResolvedMapperModel {
  @override
  final MapperRef id;

  @override
  final Code mappedClass;

  @override
  final Code implementationClass;

  @override
  final bool registerGlobally;

  final Code? datatype;

  final String? fromLiteralTermMethod;

  final String? toLiteralTermMethod;

  final Iterable<DependencyResolvedModel> dependencies;

  final MapperType type;

  LiteralResolvedMapperModel({
    required this.id,
    required this.mappedClass,
    required this.implementationClass,
    required this.registerGlobally,
    required this.datatype,
    required this.fromLiteralTermMethod,
    required this.toLiteralTermMethod,
    required this.dependencies,
    required this.type,
  });

  bool get isMethodBased =>
      fromLiteralTermMethod != null && toLiteralTermMethod != null;
}

class LiteralClassResolvedMapperModel extends LiteralResolvedMapperModel {
  final MappedClassResolvedModel mappedClassModel;

  LiteralClassResolvedMapperModel({
    required super.id,
    required super.mappedClass,
    required super.implementationClass,
    required super.registerGlobally,
    required super.datatype,
    required this.mappedClassModel,
    required super.fromLiteralTermMethod,
    required super.toLiteralTermMethod,
    required super.dependencies,
    required super.type,
  });

  @override
  MappableClassMapperTemplateData toTemplateData(
      ValidationContext context, String mapperImportUri) {
    // This type of mapper does not provide any fields to children
    final providesByVariableNames = const <String, ProvidesResolvedModel>{};

    final mappedClassData = mappedClassModel.toTemplateData(
        context, providesByVariableNames, mapperImportUri);
    final rdfValueField =
        mappedClassData.allRdfFields.where((p) => p.isRdfValue).singleOrNull;

    final rdfLanguageField = mappedClassData.allRdfFields
        .where((p) => p.isRdfLanguageTag)
        .singleOrNull;

//{{className}}.{{fromLiteralTermMethod}}(LiteralContent.fromLiteralTerm(term))
    final fromLiteralTermMethodCall = fromLiteralTermMethod == null
        ? null
        : Code.combine([
            mappedClass,
            Code.literal('.'),
            Code.literal(fromLiteralTermMethod!),
            Code.paramsList([
              Code.combine([
                Code.type('LiteralContent',
                    importUri: importRdfMapperAnnotations),
                Code.literal('.fromLiteralTerm(term)')
              ])
            ]),
          ]);
    //value.{{toLiteralTermMethod}}().toLiteralTerm(datatype)
    final toLiteralTermMethodCall = toLiteralTermMethod == null
        ? null
        : Code.literal('value.$toLiteralTermMethod().toLiteralTerm(datatype)');
    return LiteralMapperTemplateData(
      className: mappedClass,
      mapperClassName: implementationClass,
      mapperInterfaceName: interfaceClass,
      datatype: datatype,
      fromLiteralTermMethodCall: fromLiteralTermMethodCall,
      toLiteralTermMethodCall: toLiteralTermMethodCall,
      constructorParameters: mappedClassData.constructorParameters,
      nonConstructorFields: mappedClassData.nonConstructorRdfFields,
      registerGlobally: registerGlobally,
      properties: mappedClassData.properties,
      rdfValue: rdfValueField,
      rdfLanguageTag: rdfLanguageField,
      mapperFields: mapperFields
          .map((f) => f.toTemplateData(context))
          .toList(growable: false),
      mapperConstructor: _toMapperConstructorTemplateData(
          implementationClass, dependencies, context),
      direction: type.direction,
    );
  }
}

class IriPartResolvedModel {
  final String name;
  final String dartPropertyName;
  final bool isRdfProperty;

  const IriPartResolvedModel({
    required this.name,
    required this.dartPropertyName,
    required this.isRdfProperty,
  });

  IriPartData toTemplateData(ValidationContext context) {
    return IriPartData(
      name: name,
      dartPropertyName: dartPropertyName,
      isRdfProperty: isRdfProperty,
    );
  }
}

class VariableNameResolvedModel {
  final String variableName;
  final String placeholder;
  final bool isString;
  final bool isMappedValue;

  // FIXME: this corresponds to the provider - we need to reference it correctly

  const VariableNameResolvedModel({
    required this.variableName,
    required this.placeholder,
    required this.isString,
    required this.isMappedValue,
  });

  VariableNameData toTemplateData(ValidationContext context) {
    return VariableNameData(
      variableName: variableName,
      placeholder: placeholder,
      isString: isString,
      isMappedValue: isMappedValue,
    );
  }

  @override
  String toString() {
    return 'VariableNameResolvedModel{variableName: $variableName, placeholder: $placeholder, isString: $isString, isMappedValue: $isMappedValue}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is VariableNameResolvedModel &&
        other.variableName == variableName &&
        other.placeholder == placeholder &&
        other.isString == isString &&
        other.isMappedValue == isMappedValue;
  }

  @override
  int get hashCode {
    return variableName.hashCode ^
        placeholder.hashCode ^
        isString.hashCode ^
        isMappedValue.hashCode;
  }
}

class DependencyUsingVariableResolvedModel {
  final String variableName;
  final Code code;

  const DependencyUsingVariableResolvedModel({
    required this.variableName,
    required this.code,
  });

  DependencyUsingVariableData toTemplateData(ValidationContext context) {
    return DependencyUsingVariableData(
      variableName: variableName,
      code: code,
    );
  }
}

class IriTemplateResolvedModel {
  /// The original template string.
  final String template;

  /// All variables found in the template.
  final Set<VariableNameResolvedModel> variables;

  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<VariableNameResolvedModel> propertyVariables;

  /// Variables that need to be provided from context.
  final Set<DependencyUsingVariableResolvedModel> contextVariables;

  /// The regex pattern built from the template.
  final String regexPattern;

  /// The template converted to Dart string interpolation syntax.
  final String interpolatedTemplate;

  /// The fragment template converted to Dart string interpolation syntax (optional).
  final String? interpolatedFragmentTemplate;

  /// Whether this template has a fragment component.
  bool get hasFragment => interpolatedFragmentTemplate != null;

  const IriTemplateResolvedModel({
    required this.template,
    required this.variables,
    required this.propertyVariables,
    required this.contextVariables,
    required this.regexPattern,
    required this.interpolatedTemplate,
    this.interpolatedFragmentTemplate,
  });

  IriTemplateData toTemplateData(ValidationContext context) {
    return IriTemplateData(
      template: template,
      variables: variables.map((e) => e.toTemplateData(context)).toSet(),
      propertyVariables:
          propertyVariables.map((e) => e.toTemplateData(context)).toSet(),
      contextVariables:
          contextVariables.map((e) => e.toTemplateData(context)).toSet(),
      regexPattern: regexPattern,
      interpolatedTemplate: interpolatedTemplate,
      interpolatedFragmentTemplate: interpolatedFragmentTemplate,
    );
  }
}

class IriResolvedModel {
  final IriTemplateResolvedModel? template;
  final bool hasFullIriPartTemplate;
  final bool hasMapper;
  final List<IriPartResolvedModel> iriMapperParts;
  final String? providedAs;

  const IriResolvedModel({
    required this.template,
    required this.hasFullIriPartTemplate,
    required this.hasMapper,
    required this.iriMapperParts,
    this.providedAs,
  });

  bool get hasTemplate => template != null;

  IriData toTemplateData(ValidationContext context) => IriData(
      template: template?.toTemplateData(context),
      hasFullIriPartTemplate: hasFullIriPartTemplate,
      hasMapper: hasMapper,
      iriMapperParts:
          iriMapperParts.map((e) => e.toTemplateData(context)).toList());
}

class LiteralEnumResolvedMapperModel extends LiteralResolvedMapperModel {
  final List<EnumValueModel> enumValues;

  LiteralEnumResolvedMapperModel({
    required super.id,
    required super.mappedClass,
    required super.implementationClass,
    required super.registerGlobally,
    required super.datatype,
    required super.fromLiteralTermMethod,
    required super.toLiteralTermMethod,
    required this.enumValues,
    required super.dependencies,
    required super.type,
  });

  @override
  MappableClassMapperTemplateData toTemplateData(
          ValidationContext context, String mapperImportUri) =>
      EnumLiteralMapperTemplateData(
        className: mappedClass,
        mapperClassName: implementationClass,
        mapperInterfaceName: interfaceClass,
        datatype: datatype,
        fromLiteralTermMethod: fromLiteralTermMethod,
        toLiteralTermMethod: toLiteralTermMethod,
        registerGlobally: registerGlobally,
        enumValues: enumValues.map((e) => e.toTemplateData(context)).toList(),
        mapperFields: mapperFields
            .map((f) => f.toTemplateData(context))
            .toList(growable: false),
        mapperConstructor: _toMapperConstructorTemplateData(
            implementationClass, dependencies, context),
        direction: type.direction,
      );
}

/// A custom mapper (externally provided)
class CustomResolvedMapperModel extends ResolvedMapperModel {
  @override
  final MapperRef id;

  @override
  final MapperType type;

  @override
  final Code mappedClass;

  @override
  final bool registerGlobally;

  final String? instanceName;
  final Code? customMapperInstanceCode;
  final Code? implementationClass;

  List<DependencyResolvedModel> get dependencies => const [];

  CustomResolvedMapperModel(
      {required this.id,
      required this.type,
      required this.mappedClass,
      required this.registerGlobally,
      required this.instanceName,
      required this.customMapperInstanceCode,
      required this.implementationClass});

  @override
  MappableClassMapperTemplateData toTemplateData(
      ValidationContext context, String mapperImportUri) {
    return CustomMapperTemplateData(
        className: mappedClass,
        mapperInterfaceType: interfaceClass,
        customMapperName: instanceName,
        isTypeBased: implementationClass != null,
        customMapperInstance: customMapperInstanceCode,
        registerGlobally: registerGlobally);
  }
}

class DependencyResolvedModel {
  final DependencyId id;
  final FieldResolvedModel? field;
  final ConstructorParameterResolvedModel? constructorParam;
  final Code? usageCode;

  DependencyResolvedModel(
      {required this.id,
      required this.field,
      required this.constructorParam,
      required this.usageCode});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DependencyResolvedModel) return false;
    return id == other.id &&
        field == other.field &&
        constructorParam == other.constructorParam &&
        usageCode == other.usageCode;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        (field?.hashCode ?? 0) ^
        (constructorParam?.hashCode ?? 0) ^
        usageCode.hashCode;
  }

  @override
  String toString() {
    return 'DependencyResolvedModel{id: $id, field: $field, constructorParam: $constructorParam, usageCode: $usageCode}';
  }
}

class FieldResolvedModel {
  final String name;
  final Code type;
  final bool isLate;
  final bool isFinal;

  FieldResolvedModel(
      {required this.name,
      required this.type,
      required this.isLate,
      required this.isFinal});

  @override
  String toString() {
    return 'FieldResolvedModel{name: $name, type: $type, isLate: $isLate, isFinal: $isFinal}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FieldResolvedModel) return false;
    return name == other.name &&
        type == other.type &&
        isLate == other.isLate &&
        isFinal == other.isFinal;
  }

  @override
  int get hashCode {
    return name.hashCode ^ type.hashCode ^ isLate.hashCode ^ isFinal.hashCode;
  }

  FieldData toTemplateData(ValidationContext context) {
    return FieldData(
      name: name,
      type: type,
      isLate: isLate,
      isFinal: isFinal,
    );
  }
}

final class ProvidesResolvedModel {
  final String name;
  final String dartPropertyName;
  final bool isIriProvider;

  const ProvidesResolvedModel({
    required this.name,
    required this.dartPropertyName,
    this.isIriProvider = false,
  });

  @override
  int get hashCode => Object.hash(name, dartPropertyName, isIriProvider);

  String get providerName => '${name}Provider';

  @override
  bool operator ==(Object other) {
    if (other is! ProvidesResolvedModel) {
      return false;
    }
    return name == other.name &&
        dartPropertyName == other.dartPropertyName &&
        isIriProvider == other.isIriProvider;
  }

  @override
  String toString() {
    return 'ProvidesResolvedModel{name: $name, dartPropertyName: $dartPropertyName, isIriProvider: $isIriProvider}';
  }
}

String _buildMapperFieldName(String fieldName) => '_' + fieldName + 'Mapper';

List<Code> _extractCustomDeserializerParameters(
    String fieldName,
    PropertyResolvedModel? propertyInfo,
    Map<String, ProvidesResolvedModel> providesByConstructorParameterNames,
    {String? name = 'deserializer'}) {
  var (paramName, paramValue) = switch (propertyInfo) {
    PropertyResolvedModel(
      collectionMapping: var collectionMapping?,
    ) =>
      (
        name,
        _buildMapperDeserializerCode(
            _buildMapperFieldName(fieldName),
            collectionMapping.resolvedMapper,
            providesByConstructorParameterNames)
      ),
    PropertyResolvedModel(
      iriMapping: var iriMapping?,
    ) =>
      (
        name,
        _buildMapperDeserializerCode(_buildMapperFieldName(fieldName),
            iriMapping.resolvedMapper, providesByConstructorParameterNames)
      ),
    PropertyResolvedModel(
      literalMapping: var literalMapping?,
    ) =>
      (
        name,
        _buildMapperDeserializerCode(_buildMapperFieldName(fieldName),
            literalMapping.resolvedMapper, providesByConstructorParameterNames)
      ),
    PropertyResolvedModel(
      globalResourceMapping: var globalResourceMapping?,
    ) =>
      (
        name,
        _buildMapperDeserializerCode(
            _buildMapperFieldName(fieldName),
            globalResourceMapping.resolvedMapper,
            providesByConstructorParameterNames)
      ),
    PropertyResolvedModel(
      localResourceMapping: var localResourceMapping?,
    ) =>
      (
        name,
        _buildMapperDeserializerCode(
            _buildMapperFieldName(fieldName),
            localResourceMapping.resolvedMapper,
            providesByConstructorParameterNames)
      ),
    PropertyResolvedModel(
      contextualMapping: var contextualMapping?,
    ) =>
      (
        name,
        Code.combine([
          _buildMapperDeserializerCode(
              '_${fieldName}SerializationProvider',
              contextualMapping.resolvedMapper,
              providesByConstructorParameterNames),
          Code.literal('.deserializer(subject, context)')
        ]),
      ),
    _ => const (null, null)
  };
  if (paramName == null || paramValue == null) {
    return const <Code>[];
  }

  return [
    Code.combine([
      Code.literal(paramName),
      Code.literal(': '),
      paramValue,
    ])
  ];
}

List<Code> _extractCustomSerializerParameters(
    String fieldName,
    PropertyResolvedModel? propertyInfo,
    Map<String, ProvidesResolvedModel> providesByConstructorParameterNames,
    {String? name = 'serializer'}) {
  var (paramName, paramValue) = switch (propertyInfo) {
    PropertyResolvedModel(
      collectionMapping: var collectionMapping?,
    ) =>
      (
        name,
        _buildMapperSerializerCode(
            _buildMapperFieldName(fieldName),
            collectionMapping.resolvedMapper,
            providesByConstructorParameterNames)
      ),
    PropertyResolvedModel(
      iriMapping: var iriMapping?,
    ) =>
      (
        name,
        _buildMapperSerializerCode(_buildMapperFieldName(fieldName),
            iriMapping.resolvedMapper, providesByConstructorParameterNames)
      ),
    PropertyResolvedModel(
      literalMapping: var literalMapping?,
    ) =>
      (
        name,
        _buildMapperSerializerCode(_buildMapperFieldName(fieldName),
            literalMapping.resolvedMapper, providesByConstructorParameterNames)
      ),
    PropertyResolvedModel(
      globalResourceMapping: var globalResourceMapping?,
    ) =>
      (
        name,
        _buildMapperSerializerCode(
            _buildMapperFieldName(fieldName),
            globalResourceMapping.resolvedMapper,
            providesByConstructorParameterNames)
      ),
    PropertyResolvedModel(
      localResourceMapping: var localResourceMapping?,
    ) =>
      (
        name,
        _buildMapperSerializerCode(
            _buildMapperFieldName(fieldName),
            localResourceMapping.resolvedMapper,
            providesByConstructorParameterNames)
      ),
    PropertyResolvedModel(
      contextualMapping: var contextualMapping?,
    ) =>
      (
        name,
        Code.combine([
          _buildMapperSerializerCode(
              '_' + fieldName + 'SerializationProvider',
              contextualMapping.resolvedMapper,
              providesByConstructorParameterNames),
          Code.literal('.serializer(resource, subject, context)')
        ]),
      ),
    _ => const (null, null)
  };

  if (paramName == null || paramValue == null) {
    return const <Code>[];
  }

  return [
    Code.combine([
      Code.literal(paramName),
      Code.literal(': '),
      paramValue,
    ])
  ];
}

(List<String>, Code?) _extractGeneratedMapperInfos(
    ResolvedMapperModel? resolvedMapper) {
  final generatedMapper =
      resolvedMapper is GeneratedResolvedMapperModel ? resolvedMapper : null;
  final parameterNames = (generatedMapper?.dependencies ?? const [])
      .where((e) => e.constructorParam?.isRequired ?? false)
      .map((e) => e.constructorParam!.paramName)
      .toSet()
      .toList(growable: false)
    ..sort();
  final generatedMapperName = generatedMapper?.implementationClass;
  return (parameterNames, generatedMapperName);
}

Code _buildMapperSerializerCode(
    String mapperFieldName,
    ResolvedMapperModel? resolvedMapper,
    Map<String, ProvidesResolvedModel> providesByConstructorParameterNames) {
  final (mapperConstructorParameterNames, mapperName) =
      _extractGeneratedMapperInfos(resolvedMapper);
  if (mapperName == null || mapperConstructorParameterNames.isEmpty) {
    return Code.literal(mapperFieldName);
  }

  if (mapperConstructorParameterNames.isEmpty) {
    // No context variables at all, the mapper will be initialized as a field.
    return Code.literal(mapperFieldName);
  }
  final hasProvides = mapperConstructorParameterNames
      .any((v) => providesByConstructorParameterNames.containsKey(v));
  if (!hasProvides) {
    // All context variables will be injected, the mapper will be initialized as a field.
    return Code.literal(mapperFieldName);
  }
  return Code.combine([
    mapperName,
    Code.paramsList(mapperConstructorParameterNames.map((v) {
      final provides = providesByConstructorParameterNames[v];
      if (provides == null) {
        // context variable is not provided, so it will be injected as a field
        return Code.literal('${v}: _${v}');
      }
      // Check if this is an IRI provider (from providedAs)
      if (provides.isIriProvider) {
        return Code.literal('${v}: () => subject.value');
      }
      return Code.literal('${v}: () => resource.${provides.dartPropertyName}');
    })),
  ]);
}

Code _getReaderCall(PropertyResolvedModel propertyInfo,
    {required Code predicate, required List<Code> extraNamedParameters}) {
  return switch (propertyInfo) {
    // Case 1a: Property is a collection, it's specifically a Map, but it does not
    // have a collectionMapperFactoryCode, plus it
    // shall be mapped with the help of a supplement MapEntry class.
    PropertyResolvedModel(
      collectionInfo: CollectionResolvedModel(
        isCollection: true,
        isMap: true,
        collectionMapperFactoryCode: null,
        mapKeyTypeCode: final mapKeyType?,
        mapValueTypeCode: final mapValueType?,
        mapEntryClassModel: final mapEntryClassModel?
      ),
    ) =>
      _generateMapEntryReaderCall(mapEntryClassModel, mapKeyType, mapValueType,
          predicate, extraNamedParameters),

    // Case 1b: Property is a collection (not none), and it's specifically a Map,
    // but it does not have a collectionMapperFactoryCode.
    PropertyResolvedModel(
      collectionInfo: CollectionResolvedModel(
        isCollection: true,
        isMap: true,
        collectionMapperFactoryCode: null,
        mapKeyTypeCode: final mapKeyType?,
        mapValueTypeCode: final mapValueType?
      )
    ) =>
      Code.combine([
        Code.literal('reader.'),
        Code.literal('getMap'),
        Code.genericParamsList([mapKeyType, mapValueType]),
        Code.paramsList([
          predicate,
          ...extraNamedParameters,
        ]),
      ]),

    // Case 2a: Property has a collectionMapperFactoryCode, but neither is it nullable nor does it have a default value, so it is requireCollection.
    PropertyResolvedModel(
      isFieldNullable: false,
      hasDefaultValue: false,
      dartType: final dartType,
      collectionInfo: CollectionResolvedModel(
        collectionMapperFactoryCode: final collectionMapperFactoryCode?,
        elementTypeCode: final elementType
      ),
    ) =>
      Code.combine([
        Code.literal('reader.'),
        codeGeneric2(Code.literal('requireCollection'), dartType,
            elementType ?? Code.coreType('dynamic')),
        Code.paramsList([
          predicate,
          collectionMapperFactoryCode,
          ...extraNamedParameters,
        ]),
      ]),

    // Case 2b: Property has a collectionMapperFactoryCode, but it is either nullable or it has a default value, so it is optionalCollection.
    PropertyResolvedModel(
      dartType: final dartType,
      hasDefaultValue: final hasDefaultValue,
      defaultValue: final defaultValue,
      collectionInfo: CollectionResolvedModel(
        collectionMapperFactoryCode: final collectionMapperFactoryCode?,
        elementTypeCode: final elementType
      ),
    ) =>
      Code.combine([
        Code.literal('reader.'),
        codeGeneric2(Code.literal('optionalCollection'), dartType,
            elementType ?? Code.coreType('dynamic')),
        Code.paramsList([
          predicate,
          collectionMapperFactoryCode,
          ...extraNamedParameters,
        ]),
        if (hasDefaultValue)
          Code.combine([
            Code.literal(' ?? '),
            defaultValue!,
          ])
      ]),

    // Case 3: not to be treated as a collection, but required value
    PropertyResolvedModel(isFieldNullable: false, hasDefaultValue: false) =>
      Code.combine([
        Code.literal('reader.require'),
        Code.paramsList([
          predicate,
          ...extraNamedParameters,
        ]),
      ]),

    // Default Case: Any other scenario (not a collection, or collectionType is none, or just a single value and not required)
    PropertyResolvedModel(
      hasDefaultValue: final hasDefaultValue,
      defaultValue: final defaultValue
    ) =>
      Code.combine([
        Code.literal('reader.optional'),
        Code.paramsList([
          predicate,
          ...extraNamedParameters,
        ]),
        if (hasDefaultValue)
          Code.combine([
            Code.literal(' ?? '),
            defaultValue!,
          ])
      ]),
  };
}

Code _generateMapEntryReaderCall(
    MappedClassResolvedModel mapEntryClassModel,
    Code mapKeyType,
    Code mapValueType,
    Code predicate,
    List<Code> extraNamedParameters) {
  final keyPropertyName = mapEntryClassModel.properties
      .firstWhere((p) => p.isRdfMapKey)
      .constructorParameterName;
  final valuePropertyName = mapEntryClassModel.properties
      .firstWhere((p) => p.isRdfMapValue)
      .constructorParameterName;
  return Code.combine([
    Code.literal('reader.'),
    codeGeneric2(Code.literal('collect'), mapEntryClassModel.className,
        codeGeneric2(Code.coreType('Map'), mapKeyType, mapValueType)),
    Code.paramsList([
      predicate,
      Code.literal(
          "(it) => {for (var vc in it) vc.${keyPropertyName}: ${mapEntryClassModel.isMapValue ? 'vc' : 'vc.${valuePropertyName}'}}"),
      ...extraNamedParameters,
    ]),
  ]);
}

Code _generateMapEntryBuilderCall(
    ValidationContext context,
    MappedClassResolvedModel mapEntryClassModel,
    Code predicate,
    String propertyName,
    List<Code> namedParameters) {
  return Code.combine([
    Code.literal('.'),
    codeGeneric1(Code.literal('addValues'), mapEntryClassModel.className),
    Code.paramsList([
      predicate,
      Code.combine([
        Code.literal('resource.${propertyName}.entries.map((e)=>'),
        if (mapEntryClassModel.isMapValue)
          Code.literal('e.value')
        else
          _generateMapEntryConstructorCall(context, mapEntryClassModel),
        Code.literal(')'),
      ]),
      ...namedParameters
    ]),
  ]);
}

Code _generateMapEntryConstructorCall(
    ValidationContext context, MappedClassResolvedModel mapEntryClassModel) {
  final constructorParams = mapEntryClassModel.properties
      .where((e) => e.isConstructorParameter)
      .map((e) {
    Code? value = _getMapEntryReference(e);
    if (value == null) {
      context.addError(
          'The Constructor parameter ${e.constructorParameterName} of MapEntry mapping class ${mapEntryClassModel.className} either does not have a corresponding field, or the corresponding field is neither is annotated with @RdfMapKey nor with @RdfMapValue. We thus cannot instantiate this class.');
      return null;
    }
    if (e.isNamedConstructorParameter) {
      return Code.combine([
        Code.literal('${e.constructorParameterName}: '),
        value,
      ]);
    }
    return value;
  }).nonNulls;
  final nonConstructorSetters = mapEntryClassModel.properties
      .where((e) =>
          !e.isConstructorParameter && (e.isRdfMapValue || e.isRdfMapKey))
      .map((e) => Code.combine([
            Code.literal('..${e.constructorParameterName}='),
            _getMapEntryReference(e)!,
          ]));
  return Code.combine([
    mapEntryClassModel.className,
    Code.paramsList(constructorParams),
    ...nonConstructorSetters
  ]);
}

Code? _getMapEntryReference(PropertyResolvedModel e) {
  final value = e.isRdfMapKey
      ? const Code.literal('e.key')
      : (e.isRdfMapValue ? const Code.literal('e.value') : null);
  return value;
}

Code _generateSerializerCall(
        ValidationContext context, PropertyResolvedModel? propertyInfo,
        {required String propertyName,
        required Code predicate,
        required List<Code> namedParameters}) =>
    switch (propertyInfo) {
      // Case 1a: Property is a collection, it's specifically a Map, but it does not
      // have a collectionMapperFactoryCode, plus it
      // shall be mapped with the help of a supplement MapEntry class.
      PropertyResolvedModel(
        collectionInfo: CollectionResolvedModel(
          isCollection: true,
          isMap: true,
          collectionMapperFactoryCode: null,
          mapEntryClassModel: final mapEntryClassModel?
        ),
      ) =>
        _generateMapEntryBuilderCall(context, mapEntryClassModel, predicate,
            propertyName, namedParameters),

      // Case 1b: Property is a collection (not none), and it's specifically a Map,
      // but it does not have a collectionMapperFactoryCode.
      PropertyResolvedModel(
        collectionInfo: CollectionResolvedModel(
          isCollection: true,
          isMap: true,
          collectionMapperFactoryCode: null,
          mapKeyTypeCode: final mapKeyType?,
          mapValueTypeCode: final mapValueType?
        ),
      ) =>
        Code.combine([
          Code.literal('.'),
          codeGeneric2(Code.literal('addMap'), mapKeyType, mapValueType),
          Code.paramsList([
            predicate,
            Code.literal('resource.$propertyName'),
            ...namedParameters
          ]),
        ]),

      // Case 2:  Property has a collectionMapperFactoryCode
      PropertyResolvedModel(
        dartType: final dartType,
        collectionInfo: CollectionResolvedModel(
          collectionMapperFactoryCode: final collectionMapperFactoryCode?,
          elementTypeCode: final elementType
        ), // Destructure elementTypeCode here
      ) =>
        Code.combine([
          Code.literal('.'),
          codeGeneric2(Code.literal('addCollection'), dartType,
              elementType ?? Code.coreType('dynamic')),
          Code.paramsList([
            predicate,
            Code.literal('resource.$propertyName'),
            collectionMapperFactoryCode,
            ...namedParameters
          ]),
        ]),

      // Default Case: Any other scenario (not a collection, or collectionType is none, or just a single value)
      _ => Code.combine([
          Code.literal('.addValue'),
          Code.paramsList([
            predicate,
            Code.literal('resource.$propertyName'),
            ...namedParameters
          ]),
        ]),
    };

Code _buildMapperDeserializerCode(
    String mapperFieldName,
    ResolvedMapperModel? resolvedMapper,
    Map<String, ProvidesResolvedModel> providesByConstructorParameterNames) {
  final (constructorParameterNames, mapperClassName) =
      _extractGeneratedMapperInfos(resolvedMapper);
  if (mapperClassName == null || constructorParameterNames.isEmpty) {
    return Code.literal(mapperFieldName);
  }

  if (constructorParameterNames.isEmpty) {
    // No context variables at all, the mapper will be initialized as a field.
    return Code.literal(mapperFieldName);
  }
  final hasProvides = constructorParameterNames
      .any((v) => providesByConstructorParameterNames.containsKey(v));
  if (!hasProvides) {
    // All context variables will be injected, the mapper will be initialized as a field.
    return Code.literal(mapperFieldName);
  }
  // we will need to build our own initialization code
  return Code.combine([
    mapperClassName,
    Code.paramsList(constructorParameterNames.map((v) {
      final provides = providesByConstructorParameterNames[v];
      if (provides == null) {
        // context variable is not provided, so it will be injected as a field
        return Code.literal('${v}: _${v}');
      }
      return Code.literal(
          "${v}: () => throw Exception('Must not call provider for deserialization')");
    })),
  ]);
}
