/// Mapper Model Layer - Intermediate layer between Info and Template Data
///
/// This layer represents the business logic of mappers and their dependencies,
/// independent of code generation concerns.

library;

import 'package:logging/logging.dart';
import 'package:rdf_mapper_generator/src/mappers/resolved_mapper_model.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:uuid/uuid.dart';

import '../templates/code.dart';

final _log = Logger('MapperModel');

class MapperFileModel {
  /// The import URI for the generated mapper file
  final String packageName;

  /// The source path of the original Dart file
  final String originalSourcePath;
  final String mapperFileImportUri;

  /// The list of mappers defined in this file
  final List<MapperModel> mappers;
  final Map<String, String> importAliasByImportUri;

  const MapperFileModel({
    required this.packageName,
    required this.originalSourcePath,
    required this.importAliasByImportUri,
    required this.mapperFileImportUri,
    required this.mappers,
  });

  @override
  String toString() {
    return 'MapperFileModel{importUri: $mapperFileImportUri, mappers: $mappers}';
  }
}

sealed class MapperRef {
  final String id;

  const MapperRef(this.id);

  static MapperRef fromImplementationClass(Code mapperClassName,
      [Code? rawClass]) {
    return _ImplementationMapperRef(mapperClassName, rawClass);
  }

  static MapperRef fromInstanceName(String instance) {
    return _InstanceMapperRef(instance);
  }

  static MapperRef fromFactoryName(String factory, Code? configInstance,
      Code? configType, Code resourceType) {
    return _FactoryMapperRef(factory, configInstance, configType, resourceType);
  }

  static MapperRef fromInstantiationCode(Code instantiation) {
    return _InstantiationMapperRef(instantiation);
  }

  @override
  int get hashCode => id.hashCode;

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MapperRef) return false;
    return id == other.id;
  }

  @override
  String toString() => 'MapperId($id)';
}

class _ImplementationMapperRef extends MapperRef {
  final Code code;
  final Code? _rawClass;

  Code get rawClass => _rawClass ?? code;
  _ImplementationMapperRef(this.code, this._rawClass)
      : super('Implementation:' +
            code.code +
            (_rawClass != null ? "|raw:" + (_rawClass.code) : ''));

  @override
  String toString() => 'ImplementationMapperRef($id)';
}

class _InstanceMapperRef extends MapperRef {
  final String name;
  _InstanceMapperRef(this.name) : super('Instance:' + name);

  @override
  String toString() => 'InstanceMapperRef($id)';
}

class _FactoryMapperRef extends MapperRef {
  final String name;
  final Code? configInstance;
  final Code? configType;
  final Code resourceType;
  _FactoryMapperRef(
      this.name, this.configInstance, this.configType, this.resourceType)
      : super('Factory:' + name);

  @override
  String toString() => 'FactoryMapperRef($id)';
}

class _InstantiationMapperRef extends MapperRef {
  final Code instantiationCode;
  _InstantiationMapperRef(this.instantiationCode)
      : super('Instantiation:' + instantiationCode.code);

  @override
  String toString() => 'InstantiationMapperRef($id)';
}

enum MapperType {
  globalResource('GlobalResourceMapper'),
  globalResourceSerializer('GlobalResourceSerializer',
      direction: SerializationDirection.serializeOnly),
  globalResourceDeserializer('GlobalResourceDeserializer',
      direction: SerializationDirection.deserializeOnly),
  localResource('LocalResourceMapper'),
  localResourceSerializer('LocalResourceSerializer',
      direction: SerializationDirection.serializeOnly),
  localResourceDeserializer('LocalResourceDeserializer',
      direction: SerializationDirection.deserializeOnly),
  iri('IriTermMapper'),
  iriSerializer('IriTermSerializer',
      direction: SerializationDirection.serializeOnly),
  iriDeserializer('IriTermDeserializer',
      direction: SerializationDirection.deserializeOnly),
  literal('LiteralTermMapper'),
  literalSerializer('LiteralTermSerializer',
      direction: SerializationDirection.serializeOnly),
  literalDeserializer('LiteralTermDeserializer',
      direction: SerializationDirection.deserializeOnly),
  ;

  final String dartInterfaceName;
  final SerializationDirection? direction;
  const MapperType(this.dartInterfaceName, {this.direction});
}

class IriMappingModel {
  final bool hasMapper;
  final MapperDependency dependency;
  final List<MapperModel> extraMappers;

  IriMappingModel(
      {required this.hasMapper,
      required this.dependency,
      required this.extraMappers});
  IriMappingResolvedModel resolve(
    ResolveStep2Context context,
  ) {
    final resolvedMapper = context.getResolvedMapperModel(dependency.mapperRef);

    return IriMappingResolvedModel(
      hasMapper: hasMapper,
      resolvedMapper: resolvedMapper,
    );
  }
}

class LiteralMappingModel {
  final bool hasMapper;
  final MapperDependency dependency;

  LiteralMappingModel({required this.hasMapper, required this.dependency});

  LiteralMappingResolvedModel resolve(
    ResolveStep2Context context,
  ) {
    final resolvedMapper = context.getResolvedMapperModel(dependency.mapperRef);
    return LiteralMappingResolvedModel(
      hasMapper: hasMapper,
      resolvedMapper: resolvedMapper,
    );
  }
}

class GlobalResourceMappingModel {
  final bool hasMapper;
  final MapperDependency dependency;

  GlobalResourceMappingModel(
      {required this.hasMapper, required this.dependency});

  GlobalResourceMappingResolvedModel resolve(
    ResolveStep2Context context,
  ) {
    final resolvedMapper = context.getResolvedMapperModel(dependency.mapperRef);
    return GlobalResourceMappingResolvedModel(
      hasMapper: hasMapper,
      resolvedMapper: resolvedMapper,
    );
  }
}

class LocalResourceMappingModel {
  final bool hasMapper;
  final MapperDependency dependency;

  LocalResourceMappingModel(
      {required this.hasMapper, required this.dependency});

  LocalResourceMappingResolvedModel resolve(
    ResolveStep2Context context,
  ) {
    final resolvedMapper = context.getResolvedMapperModel(dependency.mapperRef);
    return LocalResourceMappingResolvedModel(
      hasMapper: hasMapper,
      resolvedMapper: resolvedMapper,
    );
  }
}

class ContextualMappingModel {
  final bool hasMapper;
  final MapperDependency dependency;

  ContextualMappingModel({required this.hasMapper, required this.dependency});

  ContextualMappingResolvedModel resolve(
    ResolveStep2Context context,
  ) {
    final resolvedMapper = context.getResolvedMapperModel(dependency.mapperRef);
    return ContextualMappingResolvedModel(
      hasMapper: hasMapper,
      resolvedMapper: resolvedMapper,
    );
  }
}

class CollectionMappingModel {
  final bool hasMapper;
  final MapperDependency dependency;

  CollectionMappingModel({required this.hasMapper, required this.dependency});

  CollectionMappingResolvedModel resolve(
    ResolveStep2Context context,
  ) {
    final resolvedMapper = context.getResolvedMapperModel(dependency.mapperRef);
    return CollectionMappingResolvedModel(
      hasMapper: hasMapper,
      resolvedMapper: resolvedMapper,
    );
  }
}

/// Information about collection properties
class CollectionModel {
  final bool isCollection;
  final bool isMap;
  final bool isIterable;
  final Code? collectionMapperFactoryCode;
  final Code? elementTypeCode;
  final Code? mapKeyTypeCode;
  final Code? mapValueTypeCode;

  final MappedClassModel? mapEntryClassModel;

  const CollectionModel({
    required this.isCollection,
    required this.isMap,
    required this.isIterable,
    required this.collectionMapperFactoryCode,
    required this.elementTypeCode,
    required this.mapKeyTypeCode,
    required this.mapValueTypeCode,
    required this.mapEntryClassModel,
  });

  CollectionResolvedModel resolve(
    ResolveStep2Context context,
  ) {
    return CollectionResolvedModel(
      isCollection: isCollection,
      isMap: isMap,
      isIterable: isIterable,
      collectionMapperFactoryCode: collectionMapperFactoryCode,
      elementTypeCode: elementTypeCode,
      mapKeyTypeCode: mapKeyTypeCode,
      mapValueTypeCode: mapValueTypeCode,
      mapEntryClassModel: resolveEntryClassModel(context),
    );
  }

  MappedClassResolvedModel? resolveEntryClassModel(
      ResolveStep2Context context) {
    if (mapEntryClassModel == null) {
      return null;
    }
    if (mapEntryClassModel!.isMapValue) {
      // If the map entry class is a map value, we resolve it as a regular class
      return mapEntryClassModel!.resolve(
          context, (p) => p.isRdfMapKey || p.isRdfProperty || p.isIriPart);
    }
    return mapEntryClassModel?.resolve(
        context, (p) => p.isRdfMapKey || p.isRdfMapValue);
  }
}

class PropertyModel {
  /// The name of the field
  final String propertyName;
  final Code dartType;

  final bool isRdfProperty;
  final bool isRdfValue;
  final bool isRdfLanguageTag;
  final bool isRdfMapEntry;
  final bool isRdfMapKey;
  final bool isRdfMapValue;
  final bool isRdfUnmappedTriples;
  final bool globalUnmapped;
  final bool isIriPart;
  final String? iriPartName;
  final bool isProvides;
  final String? providesVariableName;

  final Code? predicate;
  final bool include;
  final Code? defaultValue;
  final bool hasDefaultValue;
  final bool includeDefaultsInSerialization;

  bool get isConstructor => constructorParameterName != null;
  final String? constructorParameterName;
  final bool isNamedConstructorParameter;
  final bool isRequired; // constructor parameter required, actually

  final bool isField;
  final bool isFieldFinal;
  final bool isFieldLate;
  final bool isFieldStatic;
  final bool isFieldSynthetic;
  final bool isFieldNullable;
  final bool hasInitializer;
  final bool isSettable;
  bool get isNeedsToBeSet =>
      (isConstructor && isRequired) ||
      (isField && isFieldLate) ||
      (isField && !isFieldLate && isFieldFinal && !hasInitializer) ||
      (isField &&
          !isFieldLate &&
          !isFieldFinal &&
          !isFieldNullable &&
          isSettable);

  final CollectionModel collectionInfo;
  final CollectionMappingModel? collectionMapping;
  final IriMappingModel? iriMapping;
  final LiteralMappingModel? literalMapping;
  final GlobalResourceMappingModel? globalResourceMapping;
  final LocalResourceMappingModel? localResourceMapping;
  final ContextualMappingModel? contextualMapping;

  const PropertyModel({
    required this.propertyName,
    required this.dartType,
    required this.isRequired,
    required this.isField,
    required this.isFieldFinal,
    required this.isFieldLate,
    required this.isFieldStatic,
    required this.isFieldSynthetic,
    required this.isFieldNullable,
    required this.hasInitializer,
    required this.isSettable,
    required this.isProvides,
    required this.providesVariableName,
    required this.isRdfProperty,
    required this.isIriPart,
    required this.isRdfValue,
    required this.isRdfLanguageTag,
    required this.iriPartName,
    required this.constructorParameterName,
    required this.isNamedConstructorParameter,
    required this.include,
    required this.predicate,
    required this.defaultValue,
    required this.hasDefaultValue,
    required this.includeDefaultsInSerialization,
    required this.collectionInfo,
    required this.collectionMapping,
    required this.iriMapping,
    required this.literalMapping,
    required this.globalResourceMapping,
    required this.localResourceMapping,
    required this.contextualMapping,
    required this.isRdfMapEntry,
    required this.isRdfMapKey,
    required this.isRdfMapValue,
    required this.isRdfUnmappedTriples,
    required this.globalUnmapped,
  });

  PropertyResolvedModel resolve(
    ResolveStep2Context context,
  ) {
    return PropertyResolvedModel(
      propertyName: propertyName,
      isRequired: isRequired,
      isFieldNullable: isFieldNullable,
      isRdfProperty: isRdfProperty,
      isRdfMapEntry: isRdfMapEntry,
      isRdfMapKey: isRdfMapKey,
      isRdfMapValue: isRdfMapValue,
      isRdfUnmappedTriples: isRdfUnmappedTriples,
      globalUnmapped: globalUnmapped,
      include: include,
      predicate: predicate,
      defaultValue: defaultValue,
      hasDefaultValue: hasDefaultValue,
      includeDefaultsInSerialization: includeDefaultsInSerialization,
      dartType: dartType,
      collectionInfo: collectionInfo.resolve(context),
      isIriPart: isIriPart,
      collectionMapping: collectionMapping?.resolve(context),
      iriMapping: iriMapping?.resolve(context),
      literalMapping: literalMapping?.resolve(context),
      globalResourceMapping: globalResourceMapping?.resolve(context),
      localResourceMapping: localResourceMapping?.resolve(context),
      contextualMapping: contextualMapping?.resolve(context),
      isRdfValue: isRdfValue,
      isRdfLanguageTag: isRdfLanguageTag,
      iriPartName: iriPartName,
      constructorParameterName: constructorParameterName,
      isNamedConstructorParameter: isNamedConstructorParameter,
    );
  }
}

class MappedClassModel {
  final Code className;

  /// empty for the default constructor
  final String? constructorName;
  final List<PropertyModel> properties;
  final bool isMapValue;

  const MappedClassModel(
      {required this.constructorName,
      required this.className,
      required this.properties,
      required this.isMapValue});

  @override
  String toString() => 'MappedClass(className: $className)';

  MappedClassResolvedModel resolve(
      ResolveStep2Context context, IsRdfFieldFilter isRdfFieldFilter) {
    return MappedClassResolvedModel(
        className: className,
        isMapValue: isMapValue,
        properties:
            properties.map((p) => p.resolve(context)).toList(growable: false),
        isRdfFieldFilter: isRdfFieldFilter);
  }
}

/// Contains information about an enum value and its serialized representation
class EnumValueModel {
  /// The name of the enum constant
  final String constantName;

  /// The serialized value (either custom from @RdfEnumValue or the constant name)
  final String serializedValue;

  const EnumValueModel({
    required this.constantName,
    required this.serializedValue,
  });

  Map<String, dynamic> toTemplateData(ValidationContext context) => {
        'constantName': constantName,
        'serializedValue': serializedValue,
      };
}

/// Represents a mapper that will be generated, with its dependencies clearly defined
sealed class MapperModel {
  /// Unique identifier for this mapper
  MapperRef get id;

  /// The class this mapper handles
  Code get mappedClass;

  MappedClassModel? get mappedClassModel => null;

  /// the type of mapper
  MapperType get type;

  /// Whether this mapper should be registered globally
  bool get registerGlobally;

  Code get interfaceClass => Code.combine([
        Code.literal(type.dartInterfaceName),
        Code.literal('<'),
        mappedClass,
        Code.literal('>')
      ]);

  /// Dependencies this mapper requires to function -
  /// note that this is not the same as constructor parameters,
  /// it can also represent instances that will be instantiated.
  ///
  /// It certainly is the basis for resolving the "external"
  /// dependencies though
  List<DependencyModel> get dependencies;

  /// Called once all mappers are known, in order to compute the correct
  /// constructor dependencies and other additional state.
  ///
  /// Note that the caller of this method has to take care to call this
  /// only on mappers which only reference dependencies that were already
  /// initialized.
  ResolvedMapperModel resolve(ValidationContext context,
      Map<MapperRef, ResolvedMapperModel> resolvedMapperDependencies) {
    var resolveContext = ResolveStep1Context(
      validationContext: context,
      mapperModel: this,
      resolvedMapperDependencies: resolvedMapperDependencies,
    );
    var resolvedDependencies = dependencies
        .expand((d) => d.resolve(resolveContext))
        .toList(growable: false);

    return resolveInternal(ResolveStep2Context(
        validationContext: context,
        resolvedMapperDependencies: resolvedMapperDependencies,
        resolvedDependencies: {for (var d in resolvedDependencies) d.id: d}));
  }

  ResolvedMapperModel resolveInternal(
    ResolveStep2Context context,
  );
}

class ResolveStep1Context {
  final ValidationContext _validationContext;
  final Map<MapperRef, ResolvedMapperModel> _resolvedMapperDependencies;
  final MapperModel mapperModel;

  ResolveStep1Context({
    required ValidationContext validationContext,
    required this.mapperModel,
    required Map<MapperRef, ResolvedMapperModel> resolvedMapperDependencies,
  })  : _validationContext = validationContext,
        _resolvedMapperDependencies = resolvedMapperDependencies;

  void addError(String message) {
    _validationContext.addError(message);
  }

  void addWarning(String message) {
    _validationContext.addWarning(message);
  }

  void addFine(String message) {
    _validationContext.addFine(message);
  }

  ResolvedMapperModel? getResolvedMapperModel(MapperRef id) {
    return _resolvedMapperDependencies[id];
  }
}

class ResolveStep2Context {
  final ValidationContext _validationContext;
  final Map<DependencyId, DependencyResolvedModel> _resolvedDependencies;
  final Map<MapperRef, ResolvedMapperModel> _resolvedMapperDependencies;
  ResolveStep2Context({
    required ValidationContext validationContext,
    required Map<MapperRef, ResolvedMapperModel> resolvedMapperDependencies,
    required Map<DependencyId, DependencyResolvedModel> resolvedDependencies,
  })  : _validationContext = validationContext,
        _resolvedDependencies = resolvedDependencies,
        _resolvedMapperDependencies = resolvedMapperDependencies;

  Iterable<DependencyResolvedModel> get resolvedDependencies =>
      _resolvedDependencies.values;

  void addError(String message) {
    _validationContext.addError(message);
  }

  void addWarning(String message) {
    _validationContext.addWarning(message);
  }

  DependencyResolvedModel getDependencyResolvedModel(DependencyId id) {
    final result = _resolvedDependencies[id];
    if (result == null) {
      throw StateError('Dependency $id is not resolved');
    }
    return result;
  }

  ResolvedMapperModel? getResolvedMapperModel(MapperRef mapperRef) {
    return _resolvedMapperDependencies[mapperRef];
  }
}

sealed class GeneratedMapperModel extends MapperModel {
  /// The generated mapper class name
  Code get implementationClass;
}

/// A mapper for global resources
class ResourceMapperModel extends GeneratedMapperModel {
  @override
  final MapperRef id;

  @override
  final Code mappedClass;

  @override
  final MappedClassModel mappedClassModel;

  @override
  final Code implementationClass;

  @override
  final List<DependencyModel> dependencies;

  @override
  final bool registerGlobally;

  final Code? typeIri;

  final Code termClass;

  /// IRI strategy information
  final IriModel? iriStrategy;

  final bool needsReader;

  final Iterable<ProvidesModel> provides;

  final List<String> typeParameters;

  final MapperType type;

  ResourceMapperModel({
    required this.id,
    required this.mappedClass,
    required this.mappedClassModel,
    required this.implementationClass,
    required this.dependencies,
    required this.registerGlobally,
    required this.typeIri,
    required this.termClass,
    required this.iriStrategy,
    required this.needsReader,
    required this.provides,
    this.typeParameters = const [],
    required this.type,
  });

  @override
  ResolvedMapperModel resolveInternal(
    ResolveStep2Context context,
  ) {
    return ResourceResolvedMapperModel(
      id: id,
      mappedClass: mappedClass,
      mappedClassModel: mappedClassModel.resolve(context,
          (p) => p.isRdfProperty || p.isIriPart || p.isRdfUnmappedTriples),
      implementationClass: implementationClass,
      registerGlobally: registerGlobally,
      typeIri: typeIri,
      termClass: termClass,
      iriStrategy: iriStrategy?.resolve(context),
      dependencies: context.resolvedDependencies,
      needsReader: needsReader,
      provides: provides.map((p) => p.resolve(context)).toList(growable: false),
      typeParameters: typeParameters,
      type: type,
    );
  }
}

/// A mapper for IRI terms
sealed class IriMapperModel extends GeneratedMapperModel {
  @override
  final MapperRef id;

  @override
  final Code mappedClass;

  @override
  final Code implementationClass;

  @override
  final List<DependencyModel> dependencies;

  @override
  final bool registerGlobally;

  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<VariableNameModel> propertyVariables;

  final Set<DependencyUsingVariableModel> contextVariables;

  /// The regex pattern built from the template.
  final String regexPattern;

  /// The template converted to Dart string interpolation syntax.
  final String interpolatedTemplate;
  final String? interpolatedFragmentTemplate;

  final VariableNameModel? singleMappedValue;

  final MapperType type;

  IriMapperModel(
      {required this.id,
      required this.mappedClass,
      required this.implementationClass,
      required this.registerGlobally,
      required this.dependencies,
      required this.propertyVariables,
      required this.interpolatedTemplate,
      required this.interpolatedFragmentTemplate,
      required this.regexPattern,
      required this.singleMappedValue,
      required this.contextVariables,
      required this.type});
}

class IriClassMapperModel extends IriMapperModel {
  @override
  final MappedClassModel mappedClassModel;

  IriClassMapperModel(
      {required super.id,
      required super.mappedClass,
      required this.mappedClassModel,
      required super.implementationClass,
      required super.registerGlobally,
      required super.dependencies,
      required super.propertyVariables,
      required super.interpolatedTemplate,
      required super.interpolatedFragmentTemplate,
      required super.regexPattern,
      required super.singleMappedValue,
      required super.contextVariables,
      required super.type});

  @override
  ResolvedMapperModel resolveInternal(
    ResolveStep2Context context,
  ) {
    return IriClassResolvedMapperModel(
      id: id,
      mappedClass: mappedClass,
      mappedClassModel: mappedClassModel.resolve(context, (p) => p.isIriPart),
      implementationClass: implementationClass,
      registerGlobally: registerGlobally,
      propertyVariables:
          propertyVariables.map((v) => v.resolve(context)).toSet(),
      interpolatedTemplate: interpolatedTemplate,
      interpolatedFragmentTemplate: interpolatedFragmentTemplate,
      regexPattern: regexPattern,
      singleMappedValue: singleMappedValue?.resolve(context),
      contextVariables: contextVariables.map((v) => v.resolve(context)).toSet(),
      dependencies: context.resolvedDependencies,
      type: type,
    );
  }
}

class IriEnumMapperModel extends IriMapperModel {
  final List<EnumValueModel> enumValues;
  final bool hasFullIriTemplate;

  IriEnumMapperModel(
      {required super.id,
      required super.mappedClass,
      required this.enumValues,
      required super.implementationClass,
      required super.registerGlobally,
      required super.dependencies,
      required super.propertyVariables,
      required super.interpolatedTemplate,
      required super.interpolatedFragmentTemplate,
      required super.regexPattern,
      required super.singleMappedValue,
      required super.contextVariables,
      required this.hasFullIriTemplate,
      required super.type});

  @override
  ResolvedMapperModel resolveInternal(
    ResolveStep2Context context,
  ) {
    return IriEnumResolvedMapperModel(
      id: id,
      mappedClass: mappedClass,
      enumValues: enumValues,
      implementationClass: implementationClass,
      registerGlobally: registerGlobally,
      propertyVariables:
          propertyVariables.map((p) => p.resolve(context)).toSet(),
      interpolatedTemplate: interpolatedTemplate,
      interpolatedFragmentTemplate: interpolatedFragmentTemplate,
      regexPattern: regexPattern,
      singleMappedValue: singleMappedValue?.resolve(context),
      dependencies: context.resolvedDependencies,
      contextVariables: contextVariables.map((v) => v.resolve(context)).toSet(),
      hasFullIriTemplate: hasFullIriTemplate,
      type: type,
    );
  }
}

/// A mapper for literal terms
sealed class LiteralMapperModel extends GeneratedMapperModel {
  @override
  final MapperRef id;

  @override
  final Code mappedClass;

  @override
  final Code implementationClass;

  @override
  final List<DependencyModel> dependencies;

  @override
  final bool registerGlobally;

  final Code? datatype;

  final String? fromLiteralTermMethod;

  final String? toLiteralTermMethod;

  final MapperType type;

  LiteralMapperModel(
      {required this.id,
      required this.mappedClass,
      required this.implementationClass,
      required this.dependencies,
      required this.registerGlobally,
      required this.datatype,
      required this.fromLiteralTermMethod,
      required this.toLiteralTermMethod,
      required this.type});

  bool get isMethodBased =>
      fromLiteralTermMethod != null && toLiteralTermMethod != null;
}

class LiteralClassMapperModel extends LiteralMapperModel {
  @override
  final MappedClassModel mappedClassModel;

  LiteralClassMapperModel(
      {required super.id,
      required super.mappedClass,
      required super.implementationClass,
      required super.dependencies,
      required super.registerGlobally,
      required super.datatype,
      required this.mappedClassModel,
      required super.fromLiteralTermMethod,
      required super.toLiteralTermMethod,
      required super.type});

  @override
  ResolvedMapperModel resolveInternal(
    ResolveStep2Context context,
  ) {
    return LiteralClassResolvedMapperModel(
      id: id,
      mappedClass: mappedClass,
      implementationClass: implementationClass,
      registerGlobally: registerGlobally,
      datatype: datatype,
      dependencies: context.resolvedDependencies,
      mappedClassModel: mappedClassModel.resolve(
          context, (p) => p.isRdfValue || p.isRdfLanguageTag),
      fromLiteralTermMethod: fromLiteralTermMethod,
      toLiteralTermMethod: toLiteralTermMethod,
      type: type,
    );
  }
}

class IriPartModel {
  final String name;
  final String dartPropertyName;
  final bool isRdfProperty;

  const IriPartModel({
    required this.name,
    required this.dartPropertyName,
    required this.isRdfProperty,
  });

  IriPartResolvedModel resolve(
    ResolveStep2Context context,
  ) {
    return IriPartResolvedModel(
      name: name,
      dartPropertyName: dartPropertyName,
      isRdfProperty: isRdfProperty,
    );
  }
}

class VariableNameModel {
  final String variableName;
  final String placeholder;
  final bool isString;
  final bool isMappedValue;

  const VariableNameModel({
    required this.variableName,
    required this.placeholder,
    required this.isString,
    required this.isMappedValue,
  });

  VariableNameResolvedModel resolve(
    ResolveStep2Context context,
  ) {
    return VariableNameResolvedModel(
      variableName: variableName,
      placeholder: placeholder,
      isString: isString,
      isMappedValue: isMappedValue,
    );
  }
}

class DependencyUsingVariableModel {
  final String variableName;
  final DependencyModel dependency;

  const DependencyUsingVariableModel({
    required this.variableName,
    required this.dependency,
  });

  DependencyUsingVariableResolvedModel resolve(
    ResolveStep2Context context,
  ) {
    final DependencyResolvedModel resolved;
    try {
      resolved = context.getDependencyResolvedModel(dependency.id);
    } on StateError catch (e) {
      throw StateError(
          'Failed to resolve dependency ${dependency.id} for variable ${variableName}: ${e.message}');
    }
    final usageCode = resolved.usageCode;
    if (usageCode == null) {
      context.addError(
          'Dependency $dependency is not resolved or does not have a usage code.');
    }
    return DependencyUsingVariableResolvedModel(
      variableName: variableName,
      // The fallback is actually wrong, but we add an error above
      // about it.
      code: usageCode ?? Code.literal(''),
    );
  }
}

class IriTemplateModel {
  /// The original template string.
  final String template;

  /// All variables found in the template.
  final Set<VariableNameModel> variables;

  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<VariableNameModel> propertyVariables;

  /// Variables that need to be provided from context.
  final Set<DependencyUsingVariableModel> contextVariables;

  /// The regex pattern built from the template.
  final String regexPattern;

  /// The template converted to Dart string interpolation syntax.
  final String interpolatedTemplate;

  /// The fragment template converted to Dart string interpolation syntax (optional).
  final String? interpolatedFragmentTemplate;

  /// Whether this template has a fragment component.
  bool get hasFragment => interpolatedFragmentTemplate != null;

  const IriTemplateModel({
    required this.template,
    required this.variables,
    required this.propertyVariables,
    required this.contextVariables,
    required this.regexPattern,
    required this.interpolatedTemplate,
    this.interpolatedFragmentTemplate,
  });

  IriTemplateResolvedModel resolve(
    ResolveStep2Context context,
  ) {
    return IriTemplateResolvedModel(
      template: template,
      variables: variables.map((v) => v.resolve(context)).toSet(),
      propertyVariables:
          propertyVariables.map((v) => v.resolve(context)).toSet(),
      contextVariables: contextVariables.map((v) => v.resolve(context)).toSet(),
      regexPattern: regexPattern,
      interpolatedTemplate: interpolatedTemplate,
      interpolatedFragmentTemplate: interpolatedFragmentTemplate,
    );
  }
}

class IriModel {
  final IriTemplateModel? template;
  final bool hasFullIriPartTemplate;
  final DependencyModel? mapper;
  final List<IriPartModel> iriMapperParts;
  final String? providedAs;

  const IriModel({
    required this.template,
    required this.hasFullIriPartTemplate,
    required this.mapper,
    required this.iriMapperParts,
    this.providedAs,
  });

  bool get hasMapper => mapper != null;
  bool get hasTemplate => template != null;

  IriResolvedModel resolve(
    ResolveStep2Context context,
  ) =>
      IriResolvedModel(
          template: template?.resolve(context),
          hasFullIriPartTemplate: hasFullIriPartTemplate,
          hasMapper: hasMapper,
          iriMapperParts: iriMapperParts
              .map((part) => part.resolve(context))
              .toList(growable: false),
          providedAs: providedAs);
}

class LiteralEnumMapperModel extends LiteralMapperModel {
  final List<EnumValueModel> enumValues;

  LiteralEnumMapperModel({
    required super.id,
    required super.mappedClass,
    required super.implementationClass,
    required super.dependencies,
    required super.registerGlobally,
    required super.datatype,
    required super.fromLiteralTermMethod,
    required super.toLiteralTermMethod,
    required this.enumValues,
    required super.type,
  });

  @override
  ResolvedMapperModel resolveInternal(ResolveStep2Context context) {
    return LiteralEnumResolvedMapperModel(
      id: id,
      mappedClass: mappedClass,
      implementationClass: implementationClass,
      registerGlobally: registerGlobally,
      datatype: datatype,
      dependencies: context.resolvedDependencies,
      fromLiteralTermMethod: fromLiteralTermMethod,
      toLiteralTermMethod: toLiteralTermMethod,
      enumValues: enumValues,
      type: type,
    );
  }
}

/// A custom mapper (externally provided)
class CustomMapperModel extends MapperModel {
  @override
  final MapperRef id;

  @override
  final MapperType type;

  @override
  final Code mappedClass;

  @override
  // Currently, we do not support dependency analysis for custom mappers
  // but at least type based mappers could be supported in the future
  List<DependencyModel> get dependencies => const [];

  @override
  final bool registerGlobally;

  final String? instanceName;
  final Code? instanceInstantiationCode;
  final Code? implementationClass;

  CustomMapperModel(
      {required this.id,
      required this.type,
      required this.mappedClass,
      required this.registerGlobally,
      required this.instanceName,
      required this.instanceInstantiationCode,
      required this.implementationClass});

  @override
  ResolvedMapperModel resolveInternal(ResolveStep2Context context) {
    // "resolve" the implementation class to the instantiation code
    // for now we only support implementation classes without
    // dependencies, but in future we could support them
    // and then correctly resolve them here.
    final implementationClassCode = implementationClass == null
        ? null
        : Code.combine([implementationClass!, Code.literal('()')]);
    return CustomResolvedMapperModel(
        id: id,
        type: type,
        mappedClass: mappedClass,
        registerGlobally: registerGlobally,
        instanceName: instanceName,
        customMapperInstanceCode:
            implementationClassCode ?? instanceInstantiationCode,
        implementationClass: implementationClass);
  }
}

class DependencyId {
  final String id;
  const DependencyId(this.id);

  static DependencyId generateId() {
    return DependencyId(Uuid().v4().toString());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DependencyId && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DependencyId($id)';
}

/// Represents a dependency that a model has
sealed class DependencyModel {
  DependencyId get id;
  const DependencyModel();

  List<DependencyResolvedModel> resolve(ResolveStep1Context context);

  static MapperDependency mapper(
      Code type, String referenceName, MapperRef mapperId,
      {String suffix = "Mapper"}) {
    return MapperDependency(
        id: DependencyId.generateId(),
        type: type,
        referenceName: referenceName,
        mapperRef: mapperId,
        suffix: suffix);
  }

  factory DependencyModel.external(Code type, String referenceName,
      {bool isProvider = false}) {
    return ExternalDependency(
        id: DependencyId.generateId(),
        type: type,
        referenceName: referenceName,
        isProvider: true);
  }
}

final class ProvidesModel {
  final String name;
  final String dartPropertyName;
  final bool isIriProvider;
  String get providerName => '${name}Provider';
  const ProvidesModel({
    required this.name,
    required this.dartPropertyName,
    this.isIriProvider = false,
  });

  @override
  int get hashCode => Object.hash(name, dartPropertyName, isIriProvider);

  @override
  bool operator ==(Object other) {
    if (other is! ProvidesModel) {
      return false;
    }
    return name == other.name &&
        dartPropertyName == other.dartPropertyName &&
        isIriProvider == other.isIriProvider;
  }

  @override
  String toString() {
    return 'ProvidesModel{name: $name, dartPropertyName: $dartPropertyName, isIriProvider: $isIriProvider}';
  }

  ProvidesResolvedModel resolve(ResolveStep2Context context) {
    return ProvidesResolvedModel(
      name: name,
      dartPropertyName: dartPropertyName,
      isIriProvider: isIriProvider,
    );
  }
}

/// Depends on some mapper, typically to use it during (de-)serialization
///
/// Most complex dependency because it may be replaced during resolution
/// with different dependencies
class MapperDependency extends DependencyModel {
  final DependencyId id;
  final MapperRef mapperRef;
  final Code type;
  final String referenceName;
  final String suffix;

  MapperDependency(
      {required this.type,
      required this.id,
      required this.mapperRef,
      required this.referenceName,
      this.suffix = 'Mapper'});

  List<DependencyResolvedModel> resolve(ResolveStep1Context context) {
    final fieldName = '_${referenceName}${suffix}';
    final parameterName = '${referenceName}${suffix}';
    _log.fine('Resolve mapper dependency $id for $referenceName: $mapperRef');

    switch (mapperRef) {
      case _ImplementationMapperRef implRef:
        final resolvedMapperModel = context.getResolvedMapperModel(mapperRef);
        _log.fine('resolvedMapperModel: $resolvedMapperModel');
        if (resolvedMapperModel == null) {
          context.addFine(
              '${suffix.isEmpty ? 'Mapper' : suffix} dependency $mapperRef for $referenceName is not resolved - this is OK for references to user provided mappers. Will assume a no-args constructor');
          return [forSimpleDependency(fieldName, parameterName, implRef)];
        }
        switch (resolvedMapperModel) {
          case GeneratedResolvedMapperModel _:
            // those can have dependencies.
            final otherConstructorRequiredDepencencies = resolvedMapperModel
                .dependencies
                //c?.defaultValue != null && (e.field?.isLate ?? false)
                .where((d) =>
                    d.constructorParam != null &&
                    d.constructorParam!.isRequired)
                .toList(growable: false);
            _log.fine(
                '  Dependencies of $mapperRef: ${otherConstructorRequiredDepencencies.map((d) => '${d.id} (${d.constructorParam?.paramName ?? 'no param'})').join(', ')}');
            _log.fine(
                '  Resolved mapper details: type=${resolvedMapperModel.runtimeType}, id=${resolvedMapperModel.id}, mappedClass=${resolvedMapperModel.mappedClass}, registerGlobally=${resolvedMapperModel.registerGlobally}');
            if (otherConstructorRequiredDepencencies.isEmpty) {
              return [forSimpleDependency(fieldName, parameterName, implRef)];
            }
            var otherConstructorParamNames =
                otherConstructorRequiredDepencencies
                    .map((d) => d.constructorParam!.paramName)
                    .toSet() // deduplicate
                    .toList(growable: false)
                  ..sort((a, b) => a.compareTo(b));

            // we will make the mapper's dependencies to ours,
            // but we can also maybe provide some of them based
            // on our providers, so we will check that and remove those
            final mapperModel = context.mapperModel;
            final List<DependencyResolvedModel> newDependencies;
            if (mapperModel is ResourceMapperModel) {
              final providesByConstructorParameterName = {
                for (var p in mapperModel.provides) p.providerName: p
              };
              _log.fine(
                  'Provides by constructor parameter name: $providesByConstructorParameterName');
              newDependencies = otherConstructorRequiredDepencencies
                  .where((d) => !providesByConstructorParameterName
                      .containsKey(d.constructorParam!.paramName))
                  .toList(growable: false);
            } else {
              _log.fine(
                  '${suffix.isEmpty ? 'Mapper' : suffix} model is not a ResourceMapperModel, using all dependencies');
              newDependencies = otherConstructorRequiredDepencencies;
            }

            final hasCustomProviders = newDependencies.length !=
                otherConstructorRequiredDepencencies.length;
            _log.fine('Has custom providers: $hasCustomProviders');
            _log.fine(
                'New dependencies: ${newDependencies.map((d) => '${d.id} (${d.constructorParam?.paramName ?? 'no param'})').join(', ')}');
            //if (customProvides.isEmpty) {
            // take over the dependencies and implement our original
            // dependency with its help.
            return [
              ...newDependencies,
              DependencyResolvedModel(
                id: id,
                field: hasCustomProviders
                    ? null
                    : FieldResolvedModel(
                        isFinal: true,
                        isLate: true,
                        name: fieldName,
                        type: type,
                      ),
                constructorParam: hasCustomProviders
                    ? null
                    : ConstructorParameterResolvedModel(
                        type: type,
                        paramName: parameterName,
                        defaultValue: Code.combine([
                          implRef.rawClass,
                          Code.paramsList(
                            otherConstructorParamNames.map((d) => Code.combine([
                                  Code.literal(d),
                                  Code.literal(': '),
                                  Code.literal(d),
                                ])),
                          ),
                        ])),
                usageCode: Code.literal(fieldName),
              )
            ];

          case CustomResolvedMapperModel customMapper:
            // FIXME: what was my idea here? what is this good for?
            // FIXME: use forSimpleDependency (beware of the defaultValue code below)
            // we do not (yet) support custom mappers with dependencies,
            // so we try to instantiate it with its constructor.
            return [
              DependencyResolvedModel(
                id: id,
                field: FieldResolvedModel(
                  isFinal: true,
                  isLate: false,
                  name: fieldName,
                  type: type,
                ),
                constructorParam: ConstructorParameterResolvedModel(
                    type: type,
                    paramName: parameterName,
                    defaultValue: customMapper.customMapperInstanceCode ??
                        Code.combine([implRef.rawClass, Code.literal('()')])),
                usageCode: Code.literal(fieldName),
              )
            ];
        }
      case _FactoryMapperRef factoryRef:
        // From the point of view of the mapper, this is injected as an instance
        // and can be used directly. The init function needs to get the factory
        // injected and instantiate it to get the instane injected here.

        var factoryName = factoryRef.name;
        return [
          DependencyResolvedModel(
            id: id,
            field: FieldResolvedModel(
              isFinal: true,
              isLate: false,
              name: fieldName,
              type: type,
            ),
            constructorParam:
                FactoryInstantiatedConstructorParameterResolvedModel(
                    type: type,
                    paramName: fieldName.startsWith('_')
                        ? fieldName.substring(1)
                        : fieldName,
                    initFunctionParameterName: factoryName,
                    initFunctionParameterType: _buildFactorySignature(
                        type, 'T', factoryRef.configType),
                    initFunctionParameterCode: _buildCodeInstantiateFactory(
                        factoryName,
                        factoryRef.configInstance,
                        factoryRef.resourceType)),
            usageCode: Code.literal(fieldName),
          )
        ];
      case _InstanceMapperRef instanceRef:
        // This is a mapper that is injected as an instance, we can use it directly.
        return [
          DependencyResolvedModel(
            id: id,
            field: FieldResolvedModel(
              isFinal: true,
              isLate: false,
              name: fieldName,
              type: type,
            ),
            constructorParam: ConstructorParameterResolvedModel(
                type: type, paramName: instanceRef.name, defaultValue: null),
            usageCode: Code.literal(fieldName),
          )
        ];
      case _InstantiationMapperRef instantiationRef:
        // This is a mapper that is instantiated, we can use it directly.
        return [
          DependencyResolvedModel(
            id: id,
            field: FieldResolvedModel(
              isFinal: true,
              isLate: false,
              name: fieldName,
              type: type,
            ),
            constructorParam: ConstructorParameterResolvedModel(
                type: type,
                paramName: parameterName,
                defaultValue: instantiationRef.instantiationCode),
            usageCode: Code.literal(fieldName),
          )
        ];
    }
  }

  DependencyResolvedModel forSimpleDependency(String fieldName,
      String parameterName, _ImplementationMapperRef implRef) {
    final defaultValue = Code.combine(
        [Code.literal('const '), implRef.rawClass, Code.literal('()')]);

    return DependencyResolvedModel(
      id: id,
      field: FieldResolvedModel(
        isFinal: true,
        isLate: false,
        name: fieldName,
        type: type,
      ),
      constructorParam: ConstructorParameterResolvedModel(
          type: type, paramName: parameterName, defaultValue: defaultValue),
      usageCode: Code.literal(fieldName),
    );
  }
}

/// A dependency that needs to be injected into the mapper, like a provider.
class ExternalDependency extends DependencyModel {
  final DependencyId id;
  final Code type;
  final String referenceName;
  final bool isProvider;

  ExternalDependency(
      {required this.id,
      required this.type,
      required this.referenceName,
      required this.isProvider});

  List<DependencyResolvedModel> resolve(ResolveStep1Context context) {
    final fieldName = '_${referenceName}';
    final parameterName = referenceName;
    _log.fine('Resolve external dependency for $referenceName: $type');
    final usageCode = Code.combine(
        [Code.literal(fieldName), if (isProvider) Code.literal('()')]);
    return [
      DependencyResolvedModel(
          id: id,
          field: FieldResolvedModel(
            isFinal: true,
            isLate: false,
            name: fieldName,
            type: type,
          ),
          constructorParam: ConstructorParameterResolvedModel(
              type: type, paramName: parameterName, defaultValue: null),
          usageCode: usageCode)
    ];
  }
}

/// Builds the factory function signature for namedFactory pattern
Code _buildFactorySignature(
    Code mapperType, String genericParamName, Code? configType) {
  // Build generic constraint: <T>
  final genericConstraint =
      Code.genericParamsList([Code.literal(genericParamName)]);

  // Build parameter list: () or (ConfigType)
  final parameters = Code.paramsList([if (configType != null) configType]);

  // Build complete signature
  return Code.combine(
      [mapperType, Code.literal(' Function'), genericConstraint, parameters]);
}

/// Builds the factory function call for namedFactory pattern
Code _buildCodeInstantiateFactory(
  String factoryName,
  Code? configCode,
  Code resourceType,
) {
  // Build generic type argument: <ResourceType>
  final typeArgument = Code.genericParamsList([resourceType]);

  // Build parameter list: () or (configInstance)
  final parameters = Code.paramsList([if (configCode != null) configCode]);

  // Build complete factory call: factoryName<ResourceType>() or factoryName<ResourceType>(config)
  return Code.combine([Code.literal(factoryName), typeArgument, parameters]);
}
