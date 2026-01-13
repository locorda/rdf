import 'package:rdf_mapper_generator/builder_helper.dart';
import 'package:rdf_mapper_generator/src/mappers/iri_model_builder_support.dart';
import 'package:rdf_mapper_generator/src/mappers/mapper_model_builder.dart';
import 'package:rdf_mapper_generator/src/mappers/util.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/rdf_property_info.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

import '../processors/models/mapper_info.dart';
import 'mapper_model.dart';

final _rdfGraphType = Code.type('RdfGraph',
    importUri: 'package:rdf_core/src/graph/rdf_graph.dart');

class MappedClassModelBuilder {
  static MappedClassModel buildMappedClassModel(
      ValidationContext context,
      Code mappedClass,
      String mapperImportUri,
      List<ConstructorInfo> constructors,
      List<PropertyInfo> propertyInfos,
      List<AnnotationInfo> annotations) {
    // Validate @RdfUnmappedTriples annotation usage
    _validateUnmappedTriplesFields(context, propertyInfos);

    final constructor = constructors.firstOrNull;
    final properties = _buildPropertyData(context, mappedClass, propertyInfos,
        constructor?.parameters ?? const [], mapperImportUri);

    return MappedClassModel(
      constructorName: constructor?.name,
      className: mappedClass,
      properties: properties,
      isMapValue: annotations.any((a) => a is RdfMapValueAnnotationInfo),
    );
  }

  static List<PropertyModel> _buildPropertyData(
      ValidationContext context,
      Code mappedClass,
      List<PropertyInfo> propertyInfos,
      List<ParameterInfo> constructorParameters,
      String mapperImportUri) {
    final propertyInfosByName = {
      for (var propertyInfo in propertyInfos) propertyInfo.name: propertyInfo
    };
    final constructorParametersByName = {
      for (var param in constructorParameters) param.name: param
    };
    final allPropertyNames = {
      ...propertyInfosByName.keys,
      ...constructorParametersByName.keys,
    };
    return allPropertyNames.map((propertyName) {
      final p = propertyInfosByName[propertyName];
      final c = constructorParametersByName[propertyName];
      final propertyInfo = p?.propertyInfo ?? c?.propertyInfo;
      // Determine collection information and methods
      final collectionInfo = propertyInfo?.collectionInfo;

      var dartType = p?.type ?? c?.type ?? const Code.literal('dynamic');
      var dartTypeNonNull = p?.typeNonNull ?? dartType;

      final iri = propertyInfo?.annotation.iri;
      final literal = propertyInfo?.annotation.literal;
      final globalResource = propertyInfo?.annotation.globalResource;
      final localResource = propertyInfo?.annotation.localResource;
      final contextual = propertyInfo?.annotation.contextual;

      final MappedClassModel? mapEntryClassModel;
      if (p?.mapEntry != null) {
        final mapEntry = p!.mapEntry!;
        final entryClassInfo =
            BuilderHelper.processClass(context, mapEntry.itemClassElement);
        // FIXME: mapperImportUri might be wrong here! Maybe we should use
        // the importUri from the mapEntry.itemType or maybe better entryClassInfo.className?
        if (entryClassInfo == null) {
          context.addError(
              'Could not find class for map entry type: ${mapEntry.itemType}');
          mapEntryClassModel = null;
        } else {
          final entryClassModels = MapperModelBuilder.buildModel(
              context, mapperImportUri, entryClassInfo);
          final entryClassModel = entryClassModels
              .firstWhere((m) => m.mappedClass == mapEntry.itemType)
              .mappedClassModel;
          mapEntryClassModel = entryClassModel;
        }
      } else {
        mapEntryClassModel = null;
      }

      final collectionMappingInfo = propertyInfo?.annotation.collection;
      final collectionFactory = collectionMappingInfo?.factory;
      final isCollection = ((collectionInfo?.isCoreCollection ?? false) &&
              (collectionMappingInfo?.isAuto ?? false)) ||
          collectionFactory != null;
      final itemType = propertyInfo?.annotation.itemType;

      Code? defaultValue = propertyInfo?.annotation.defaultValue == null
          ? null
          : toCode(propertyInfo?.annotation.defaultValue);
      Code? collectionMapperTypeCode;
      if (collectionFactory != null) {
        collectionMapperTypeCode = collectionFactory;
      } else {
        if (collectionInfo != null &&
            collectionInfo.isCoreCollection &&
            (collectionMappingInfo?.isAuto ?? false)) {
          if (collectionInfo.isCoreList) {
            collectionMapperTypeCode = Code.type('UnorderedItemsListMapper',
                importUri: importRdfMapper);
            defaultValue ??= Code.literal('[]');
          } else if (collectionInfo.isCoreSet) {
            collectionMapperTypeCode = Code.type('UnorderedItemsSetMapper',
                importUri: importRdfMapper);
            defaultValue ??= Code.literal('{}');
          } else if (collectionInfo.isCoreMap) {
            // currently, we have special handling for Maps that does not follow
            // the addCollection/requireCollection/optionalCollection pattern.
            collectionMapperTypeCode = null;
          } else if (collectionInfo.isIterable) {
            // Fallback to generic UnorderedItemsMapper
            collectionMapperTypeCode =
                Code.type('UnorderedItemsMapper', importUri: importRdfMapper);
            defaultValue ??= Code.literal('[]');
          }
        } else {
          collectionMapperTypeCode = null;
        }
      }
      final collectionMapperFactoryCode = collectionMapperTypeCode != null
          ? Code.combine([collectionMapperTypeCode, Code.literal('.new')])
          : null;
      var collectionModel = CollectionModel(
        isCollection: isCollection,
        isMap: collectionInfo?.isCoreMap ?? false,
        isIterable: collectionInfo?.isIterable ?? false,
        collectionMapperFactoryCode: collectionMapperFactoryCode,
        elementTypeCode: (itemType == null ? null : typeToCode(itemType)) ??
            collectionInfo?.elementTypeCode,
        mapValueTypeCode: collectionInfo?.valueTypeCode,
        mapKeyTypeCode: collectionInfo?.keyTypeCode,
        mapEntryClassModel: mapEntryClassModel,
      );
      var itemDartTypeNonNull = collectionModel.isCollection
          ? collectionModel.elementTypeCode ?? dartTypeNonNull
          : dartTypeNonNull;
      return PropertyModel(
        propertyName: propertyName,
        dartType: dartType,
        isRdfProperty: propertyInfo != null,
        isRdfValue: p?.isRdfValue ?? c?.isRdfValue ?? false,
        isRdfLanguageTag: p?.isRdfLanguageTag ?? c?.isRdfLanguageTag ?? false,
        isRdfMapEntry: p?.mapEntry != null,
        isRdfMapKey: p?.mapKey != null,
        isRdfMapValue: p?.mapValue != null,
        isRdfUnmappedTriples: p?.unmappedTriples != null,
        globalUnmapped: p?.unmappedTriples?.globalUnmapped ?? false,
        isIriPart: p?.iriPart != null,
        iriPartName: p?.iriPart?.name,
        isProvides: p?.provides != null,
        providesVariableName: p?.provides?.name,
        predicate: propertyInfo?.annotation.predicate.code,
        include: propertyInfo?.annotation.include ?? false,
        defaultValue: defaultValue,
        hasDefaultValue: propertyInfo?.annotation.defaultValue != null,
        includeDefaultsInSerialization:
            propertyInfo?.annotation.includeDefaultsInSerialization ?? false,

        constructorParameterName: c?.name,
        isNamedConstructorParameter: c?.isNamed ?? false,
        isRequired:
            c?.isRequired ?? false, // constructor parameter required, actually

        isField: p != null,
        isFieldFinal: p?.isFinal ?? false,
        isFieldLate: p?.isLate ?? false,
        isFieldStatic: p?.isStatic ?? false,
        isFieldSynthetic: p?.isSynthetic ?? false,
        isFieldNullable: !(p?.isRequired ?? true),
        hasInitializer: p?.hasInitializer ?? false,
        isSettable: p?.isSettable ?? true,

        collectionInfo: collectionModel,
        collectionMapping: collectionMappingInfo?.mapper == null
            ? null
            : buildCollectionMapping(collectionMappingInfo!, propertyInfo!,
                collectionModel, dartTypeNonNull, propertyName),
        iriMapping: iri == null
            ? null
            : buildIriMapping(
                context,
                mappedClass,
                mapperImportUri,
                iri,
                propertyInfo!,
                collectionModel,
                propertyInfos,
                itemDartTypeNonNull,
                propertyName),
        literalMapping: literal == null
            ? null
            : buildLiteralMapping(literal, propertyInfo!, collectionModel,
                itemDartTypeNonNull, propertyName),
        globalResourceMapping: globalResource == null
            ? null
            : buildGlobalResourceMapping(globalResource, propertyInfo!,
                collectionModel, itemDartTypeNonNull, propertyName),
        localResourceMapping: localResource == null
            ? null
            : buildLocalResourceMapping(localResource, propertyInfo!,
                collectionModel, itemDartTypeNonNull, propertyName),
        contextualMapping: contextual == null
            ? null
            : buildContextualMapping(
                contextual,
                propertyInfo!,
                collectionModel,
                // FIXME: I need the mappedClass with generic params here - is
                // there actually use for the non-complete version anywhere, or should
                // mappedClass contain the generic params?
                mappedClass,
                itemDartTypeNonNull,
                propertyName),
      );
    }).toList();
  }

  static LocalResourceMappingModel buildLocalResourceMapping(
      LocalResourceMappingInfo localResource,
      RdfPropertyInfo propertyInfo,
      CollectionModel collectionModel,
      Code dartTypeNonNull,
      String propertyName) {
    return LocalResourceMappingModel(
        hasMapper: true,
        dependency: createMapperDependency(
            collectionModel,
            localResource.mapper!,
            dartTypeNonNull,
            propertyName,
            'LocalResourceMapper'));
  }

  static ContextualMappingModel buildContextualMapping(
      ContextualMappingInfo contextual,
      RdfPropertyInfo propertyInfo,
      CollectionModel collectionModel,
      Code mappedClass,
      Code dartTypeNonNull,
      String propertyName) {
    return ContextualMappingModel(
        hasMapper: true,
        dependency: createSerializationProviderDependency(collectionModel,
            contextual.mapper!, mappedClass, dartTypeNonNull, propertyName));
  }

  static CollectionMappingModel buildCollectionMapping(
      CollectionMappingInfo collection,
      RdfPropertyInfo propertyInfo,
      CollectionModel collectionModel,
      Code dartTypeNonNull,
      String propertyName) {
    return CollectionMappingModel(
        hasMapper: true,
        dependency: createMapperDependency(collectionModel, collection.mapper!,
            dartTypeNonNull, propertyName, 'Mapper'));
  }

  static GlobalResourceMappingModel buildGlobalResourceMapping(
      GlobalResourceMappingInfo globalResource,
      RdfPropertyInfo propertyInfo,
      CollectionModel collectionModel,
      Code dartTypeNonNull,
      String propertyName) {
    return GlobalResourceMappingModel(
        hasMapper: true,
        dependency: createMapperDependency(
            collectionModel,
            globalResource.mapper!,
            dartTypeNonNull,
            propertyName,
            'GlobalResourceMapper'));
  }

  static LiteralMappingModel? buildLiteralMapping(
      LiteralMappingInfo literal,
      RdfPropertyInfo propertyInfo,
      CollectionModel collectionModel,
      Code dartTypeNonNull,
      String propertyName) {
    if (literal.mapper == null &&
        literal.datatype == null &&
        literal.language == null) {
      return null;
    }

    final MapperRef mapperRef;
    if (literal.mapper != null) {
      mapperRef = IriModelBuilderSupport.mapperRefInfoToMapperRef(
          literal.mapper!, propertyInfo.type);
    } else if (literal.datatype != null) {
      mapperRef = MapperRef.fromInstantiationCode(Code.combine([
        Code.literal('const '),
        codeGeneric1(
            Code.type('DatatypeOverrideMapper', importUri: importRdfMapper),
            dartTypeNonNull),
        Code.paramsList([literal.datatype!.code]),
      ]));
    } else if (literal.language != null) {
      mapperRef = MapperRef.fromInstantiationCode(Code.combine([
        Code.literal('const '),
        codeGeneric1(
            Code.type('LanguageOverrideMapper', importUri: importRdfMapper),
            dartTypeNonNull),
        Code.paramsList([Code.literal("'${literal.language!}'")])
      ]));
    } else {
      throw Exception(
          'LiteralMappingInfo must have either a mapper, datatype or language defined.');
    }
    final dependency = DependencyModel.mapper(
      buildMapperInterfaceTypeForProperty(
          Code.type('LiteralTermMapper', importUri: importRdfMapper),
          collectionModel,
          dartTypeNonNull),
      propertyName,
      mapperRef,
    );

    return LiteralMappingModel(
        hasMapper: literal.mapper != null, dependency: dependency);
  }

  static IriMappingModel? buildIriMapping(
      ValidationContext context,
      Code mappedClassName,
      String mapperImportUri,
      IriMappingInfo iri,
      RdfPropertyInfo propertyInfo,
      CollectionModel collectionModel,
      List<PropertyInfo> fields,
      Code dartTypeNonNull,
      String propertyName) {
    if (iri.mapper == null && iri.template == null) {
      return null;
    }

    final MapperRef mapperRef;
    final List<MapperModel> extraMappers = [];
    if (iri.mapper != null) {
      mapperRef = IriModelBuilderSupport.mapperRefInfoToMapperRef(
          iri.mapper!, propertyInfo.type);
    } else if (iri.template != null && !iri.isFullIriTemplate) {
      if (!iri.template!.propertyVariables.any((v) => v.name == propertyName)) {
        context.addError(
            'Property ${propertyName} is not defined in the IRI template: ${iri.template!.template}, but this property is annotated with a template based IriMapping');
      }
      final Code generatedMapperClassName = _buildPropertyMapperClassName(
          mappedClassName, propertyName, mapperImportUri);
      mapperRef = MapperRef.fromImplementationClass(generatedMapperClassName);
      final generatedMapper = IriModelBuilderSupport.buildIriMapper(
          context: context,
          mappedClassName: dartTypeNonNull,
          templateInfo: iri.template!,
          iriParts: iri.template!.iriParts,
          mapperClassName: generatedMapperClassName,
          registerGlobally: false,
          /* local to the resource mapper */
          mapperImportUri: mapperImportUri,
          // for property based IRI mappers, we do not do the Serializer/Deserializer/Mapper distinction for now
          type: MapperType.iri);
      extraMappers.addAll(generatedMapper);
    } else if (iri.isFullIriTemplate) {
      mapperRef = MapperRef.fromInstantiationCode(Code.combine([
        Code.literal('const '),
        Code.type('IriFullMapper', importUri: importRdfMapper),
        Code.literal('()')
      ]));
    } else {
      throw Exception(
          'IriMappingInfo must have either a mapper or a template defined.');
    }
    final dependency = DependencyModel.mapper(
      buildMapperInterfaceTypeForProperty(
          Code.type('IriTermMapper', importUri: importRdfMapper),
          collectionModel,
          dartTypeNonNull),
      propertyName,
      mapperRef,
    );

    return IriMappingModel(
        hasMapper: iri.mapper != null,
        dependency: dependency,
        extraMappers: extraMappers);
  }

  static String _capitalizeFirstLetter(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  static Code _buildPropertyMapperClassName(
      Code className, String fieldName, String mapperImportUri) {
    return Code.type(
        '${className.codeWithoutAlias}${_capitalizeFirstLetter(fieldName)}Mapper',
        importUri: mapperImportUri);
  }

  static MapperDependency createMapperDependency(
      CollectionModel? collectionModel,
      MapperRefInfo mapper,
      Code dartTypeNonNull,
      String propertyName,
      String interfaceTypeName) {
    return DependencyModel.mapper(
      buildMapperInterfaceTypeForProperty(
          Code.type(interfaceTypeName, importUri: importRdfMapper),
          collectionModel,
          dartTypeNonNull),
      propertyName,
      IriModelBuilderSupport.mapperRefInfoToMapperRef(mapper, dartTypeNonNull),
    );
  }

  static MapperDependency createSerializationProviderDependency(
      CollectionModel? collectionModel,
      MapperRefInfo mapper,
      Code parentInstanceType,
      Code dartTypeNonNull,
      String propertyName) {
    return DependencyModel.mapper(
        codeGeneric2(
          Code.type('SerializationProvider', importUri: importRdfMapper),
          parentInstanceType,
          buildElementTypeForProperty(collectionModel, dartTypeNonNull),
        ),
        propertyName,
        IriModelBuilderSupport.mapperRefInfoToMapperRef(
            mapper, dartTypeNonNull),
        suffix: "SerializationProvider");
  }

  static void _validateUnmappedTriplesFields(
      ValidationContext context, List<PropertyInfo> fields) {
    final unmappedFields =
        fields.where((f) => f.unmappedTriples != null).toList();

    if (unmappedFields.isEmpty) return;

    // Check for multiple fields with @RdfUnmappedTriples annotation
    if (unmappedFields.length > 1) {
      context.addError(
          'Only one field per class may be annotated with @RdfUnmappedTriples. '
          'Found fields: ${unmappedFields.map((f) => f.name).join(', ')}');
    }

    // Validate the type of each field with @RdfUnmappedTriples annotation
    for (final field in unmappedFields) {
      final fieldType = field.type;

      if (fieldType != _rdfGraphType) {
        context.addWarning(
            '@RdfUnmappedTriples field "${field.name}" uses non-standard type "${fieldType.codeWithoutAlias}"\n'
            '  • Ensure UnmappedTriplesMapper<${fieldType.codeWithoutAlias}> is registered in your RdfMapper registry\n'
            '  • ${_rdfGraphType.codeWithoutAlias} has a default mapper and is recommended for most use cases');
      }
    }
  }
}
