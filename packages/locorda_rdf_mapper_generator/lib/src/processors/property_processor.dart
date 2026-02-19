// import 'package:analyzer/dart/constant/value.dart';
// import 'package:analyzer/dart/element/element2.dart';
// import 'package:analyzer/dart/element/type.dart';
// import 'package:analyzer/dart/element/type_system.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/iri_strategy_processor.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/rdf_property_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/util.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';

/// Container for inferred mapping information
class _InferredMappings {
  final GlobalResourceMappingInfo? globalResource;
  final LocalResourceMappingInfo? localResource;
  final LiteralMappingInfo? literal;
  final IriMappingInfo? iri;

  /// The DartType of the inferred dependency (for cross-file processing)
  final DartType? dependencyType;

  const _InferredMappings({
    this.globalResource,
    this.localResource,
    this.literal,
    this.iri,
    this.dependencyType,
  });
}

/// Processes field elements to extract RDF property information.
class PropertyProcessor {
  /// Processes a field element to extract RDF property information.
  ///
  /// Returns a [RdfPropertyInfo] if the field is annotated with `@RdfProperty`,
  /// otherwise returns `null`.
  static RdfPropertyInfo? processField(
      ValidationContext context, FieldElem field) {
    final mapEntry =
        extractMapEntryAnnotation(context, field.name, field.annotations);
    return processFieldAlike(context,
        name: field.name,
        annotations: field.annotations,
        isFinal: field.isFinal,
        isLate: field.isLate,
        isStatic: field.isStatic,
        isSynthetic: field.isSynthetic,
        type: field.type,
        mapEntry: mapEntry,
        allowImplicitGenVocab: false,
        hasIriPart: false);
  }

  static RdfPropertyInfo? processFieldAlike(ValidationContext context,
      {required String name,
      required DartType type,
      required Iterable<ElemAnnotation> annotations,
      required bool isStatic,
      required bool isFinal,
      required bool isLate,
      required bool isSynthetic,
      required RdfMapEntryAnnotationInfo? mapEntry,
      required bool allowImplicitGenVocab,
      required bool hasIriPart}) {
    // Check for @RdfIgnore annotation - completely excludes the field
    if (getAnnotation(annotations, 'RdfIgnore') != null) {
      return null;
    }

    final annotationObj = _getRdfPropertyAnnotation(annotations);
    if (annotationObj == null && !allowImplicitGenVocab) {
      return null;
    }

    // Analyze collection information
    final collectionInfo = analyzeCollectionType(type);

    final RdfPropertyAnnotationInfo? rdfProperty;
    if (annotationObj == null) {
      // In .define() mode (implicit gen vocab), exclude special fields that aren't RDF properties:

      // @RdfIriPart fields are identifiers, not properties
      if (hasIriPart) {
        return null;
      }

      // @RdfUnmappedTriples fields capture unmapped triples, they are not properties themselves
      if (getAnnotation(annotations, 'RdfUnmappedTriples') != null) {
        return null;
      }

      // Well-known fields like hashCode should not be mapped
      if (name == 'hashCode') {
        return null;
      }

      rdfProperty = _createImplicitGenVocabProperty(
        context,
        name,
        type,
        collectionInfo,
        mapEntry,
      );
    } else {
      // Create an instance of RdfProperty from the annotation data
      rdfProperty = _createRdfProperty(
          context, name, type, collectionInfo, mapEntry, annotationObj);
    }

    // Check if the type is nullable
    final isNullable = type.isNullable;

    return RdfPropertyInfo(
      name: name,
      type: typeToCode(type),
      annotation: rdfProperty,
      isRequired: !isNullable,
      isFinal: isFinal,
      isLate: isLate,
      isStatic: isStatic,
      isSynthetic: isSynthetic,
      collectionInfo: collectionInfo,
    );
  }

  /// Analyzes a property type to determine collection information
  static CollectionInfo analyzeCollectionType(
    DartType dartType,
  ) {
    // Check if it's a collection type
    if (dartType.isInterfaceType) {
      final element = dartType.element;
      final className = element.name;

      // Check for List
      if (className == 'List' && dartType.typeArguments.length == 1) {
        return CollectionInfo(
          type: CollectionType.list,
          elementTypeCode: typeToCode(dartType.typeArguments[0]),
          elementType: dartType.typeArguments[0],
        );
      }

      // Check for Set
      if (className == 'Set' && dartType.typeArguments.length == 1) {
        return CollectionInfo(
          type: CollectionType.set,
          elementTypeCode: typeToCode(dartType.typeArguments[0]),
          elementType: dartType.typeArguments[0],
        );
      } // Check for Map
      if (className == 'Map' && dartType.typeArguments.length == 2) {
        final keyType = dartType.typeArguments[0];
        final valueType = dartType.typeArguments[1];

        return CollectionInfo(
          type: CollectionType.map,
          elementTypeCode:
              null, // We'll handle this specially in code generation
          keyTypeCode: typeToCode(keyType),
          valueTypeCode: typeToCode(valueType),
        );
      }

      if (dartType.isDartCoreIterable && dartType.typeArguments.length == 1) {
        return CollectionInfo(
          type: CollectionType.iterable,
          elementTypeCode: typeToCode(dartType.typeArguments[0]),
          elementType: dartType.typeArguments[0],
        );
      }
      if (dartType.typeArguments.length == 1) {
        return CollectionInfo(
          type: null,
          elementTypeCode: typeToCode(dartType.typeArguments[0]),
          elementType: dartType.typeArguments[0],
        );
      }
    }

    // Not a recognized collection type
    return const CollectionInfo();
  }

  static DartObject? _getRdfPropertyAnnotation(
      Iterable<ElemAnnotation> annotations) {
    return getAnnotation(annotations, 'RdfProperty');
  }

  static RdfPropertyAnnotationInfo _createRdfProperty(
      ValidationContext context,
      String fieldName,

      /// The field's Dart type (e.g. List&lt;Foo&gt;)
      DartType fieldType,
      CollectionInfo collectionInfo,
      RdfMapEntryAnnotationInfo? rdfMapEntryAnnotation,
      DartObject annotation) {
    // Extract the predicate IRI (nullable for define mode)
    final predicate = getIriTermInfo(getField(annotation, 'predicate'));

    // Extract the fragment (for define mode)
    final fragment = getField(annotation, 'fragment')?.toStringValue();
    final metadata = withLabelCommentMetadata(
      getMetadataMap(
        getField(annotation, 'metadata'),
        contextName: 'RdfProperty.define',
      ),
      label: getField(annotation, 'label')?.toStringValue(),
      comment: getField(annotation, 'comment')?.toStringValue(),
    );

    final include = getField(annotation, 'include')?.toBoolValue() ?? true;
    final noDomain = getField(annotation, 'noDomain')?.toBoolValue() ?? false;
    final defaultValue = getField(annotation, 'defaultValue');
    final includeDefaultsInSerialization =
        getField(annotation, 'includeDefaultsInSerialization')?.toBoolValue() ??
            false;
    final localResource = _extractLocalResourceMapping(annotation);
    final literal = _extractLiteralMapping(annotation);
    final globalResource = _extractGlobalResourceMapping(annotation);
    final contextual = _extractContextualMapping(annotation);

    // FIXME: validate that collection.mapper.type is a subclass of Mapper<T>, and that its
    // default constructor corresponds to the type `CollectionMapperFactory<C, T>` which is a typedef for
    // `Mapper<C> Function({Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})`
    final collection = _extractCollectionMapping(annotation);
    final itemTypeField = getField(annotation, 'itemType');
    final itemType = itemTypeField?.toTypeValue();

    final isCollection =
        collectionInfo.isCoreCollection || collection?.factory != null;

    /// The dart type that is used for the serialization/deserialization
    /// of the field, e.g. Foo for List<Foo>
    /// or MapEntry<Foo, Bar> for Map<Foo, Bar>
    /// or even Baz for Map<Foo, Bar> if property is annotated with
    /// @RdfMapEntry(Baz)
    DartType? collectionItemType = (isCollection
        ? itemType ??
            rdfMapEntryAnnotation?.itemClassType ??
            collectionInfo.elementType ??
            // FIXME: in the docs I claimed that the fallback type was Object not fieldType - should we adjust the docs (easy) or the code (probably hard)?
            fieldType
        : null);

    DartType fieldMappedClassType = collectionItemType ?? fieldType;

    // Extract IRI mapping if present
    final iri = _extractIriMapping(
        context, fieldName, fieldMappedClassType, annotation);

    // Validate mutual exclusivity of mapping strategies
    final mappingCount = [
      localResource,
      literal,
      globalResource,
      contextual,
      iri
    ].where((m) => m != null).length;
    if (mappingCount > 1) {
      context.addError(
          'RdfProperty on field $fieldName cannot have multiple mapping strategies (localResource, literal, globalResource, contextual, iri)');
    }

    // Smart inference: if no explicit mapping is provided and the field type
    // has an RDF annotation with registerGlobally: false, infer the appropriate mapper
    final inferredMappings = _inferMappingsFromType(
        fieldMappedClassType, localResource, literal, globalResource, iri);

    // Create and return the RdfProperty instance
    return RdfPropertyAnnotationInfo(predicate,
        fragment: fragment,
        metadata: metadata,
        include: include,
        defaultValue: defaultValue,
        includeDefaultsInSerialization: includeDefaultsInSerialization,
        noDomain: noDomain,
        isImplicitDefine: false,
        localResource: inferredMappings.localResource ?? localResource,
        literal: inferredMappings.literal ?? literal,
        globalResource: inferredMappings.globalResource ?? globalResource,
        contextual: contextual,
        iri: inferredMappings.iri ?? iri,
        collection: collection,
        itemType: fieldMappedClassType);
  }

  static RdfPropertyAnnotationInfo _createImplicitGenVocabProperty(
      ValidationContext context,
      String fieldName,
      DartType fieldType,
      CollectionInfo collectionInfo,
      RdfMapEntryAnnotationInfo? rdfMapEntryAnnotation) {
    final include = true;
    final defaultValue = null;
    final includeDefaultsInSerialization = false;
    final collection = CollectionMappingInfo(
      mapper: null,
      isAuto: true,
      factory: null,
    );

    final isCollection =
        collectionInfo.isCoreCollection || collection.factory != null;

    final DartType? collectionItemType = (isCollection
        ? rdfMapEntryAnnotation?.itemClassType ??
            collectionInfo.elementType ??
            fieldType
        : null);
    final fieldMappedClassType = collectionItemType ?? fieldType;

    final inferredMappings = _inferMappingsFromType(
      fieldMappedClassType,
      null,
      null,
      null,
      null,
    );

    return RdfPropertyAnnotationInfo(
      null,
      fragment: null,
      metadata: const {},
      include: include,
      defaultValue: defaultValue,
      includeDefaultsInSerialization: includeDefaultsInSerialization,
      noDomain: false,
      isImplicitDefine: true,
      iri: inferredMappings.iri,
      localResource: inferredMappings.localResource,
      literal: inferredMappings.literal,
      globalResource: inferredMappings.globalResource,
      contextual: null,
      collection: collection,
      itemType: fieldMappedClassType,
    );
  }

  static IriMappingInfo? _extractIriMapping(ValidationContext context,
      String fieldName, DartType fieldType, DartObject annotation) {
    // Check for named parameter 'iri'
    final iriMapping = getField(annotation, 'iri');
    if (isNull(iriMapping)) {
      return null;
    }
    // Check if it's an IriMapping
    final template = iriMapping!.getField('template')?.toStringValue();
    final fragmentTemplateFieldValue =
        getField(iriMapping, 'fragmentTemplate')?.toStringValue();
    final mapper = getMapperRefInfo<IriTermMapper>(iriMapping);

    final templateInfo = template == null && mapper == null
        ? IriStrategyProcessor.processTemplate(
            context,
            '{+${fieldName}}',
            [
              IriPartInfo(
                  name: fieldName,
                  dartPropertyName: fieldName,
                  type: typeToCode(fieldType),
                  pos: 1,
                  isMappedValue: true)
            ],
            fragmentTemplate: fragmentTemplateFieldValue)!
        : template != null
            ? IriStrategyProcessor.processTemplate(
                context,
                template,
                [
                  IriPartInfo(
                      name: fieldName,
                      dartPropertyName: fieldName,
                      type: typeToCode(fieldType),
                      pos: 1,
                      isMappedValue: true)
                ],
                fragmentTemplate: fragmentTemplateFieldValue)!
            : null;
    return IriMappingInfo(template: templateInfo, mapper: mapper);
  }

  static LocalResourceMappingInfo? _extractLocalResourceMapping(
      DartObject annotation) {
    // Check for named parameter 'iri'
    final localResource = getField(annotation, 'localResource');
    if (isNull(localResource)) {
      return null;
    }
    // Check if it's an IriMapping
    final mapper = getMapperRefInfo<IriTermMapper>(localResource!);
    return LocalResourceMappingInfo(mapper: mapper);
  }

  static CollectionMappingInfo? _extractCollectionMapping(
      DartObject annotation) {
    // Check for named parameter 'iri'
    final collection = getField(annotation, 'collection');
    if (isNull(collection)) {
      return null;
    }
    final isAuto = getField(collection!, 'isAuto')?.toBoolValue() ?? false;
    final factory = getField(collection, 'factory')?.toTypeValue();
    Code? factoryCode;
    if (factory != null) {
      final className = factory.element.name;
      factoryCode =
          Code.type(className, importUri: factory.element.libraryIdentifier);
    }
    // Check if it's an IriMapping
    final mapper = getMapperRefInfo<IriTermMapper>(collection);
    return CollectionMappingInfo(
        mapper: mapper, isAuto: isAuto, factory: factoryCode);
  }

  static GlobalResourceMappingInfo? _extractGlobalResourceMapping(
      DartObject annotation) {
    // Check for named parameter 'iri'
    final globalResource = getField(annotation, 'globalResource');
    if (isNull(globalResource)) {
      return null;
    }
    final mapper = getMapperRefInfo<IriTermMapper>(globalResource!);
    return GlobalResourceMappingInfo(mapper: mapper);
  }

  static ContextualMappingInfo? _extractContextualMapping(
      DartObject annotation) {
    // Check for named parameter 'contextual'
    final contextual = getField(annotation, 'contextual');
    if (isNull(contextual)) {
      return null;
    }
    final mapper = getMapperRefInfo<SerializationProvider>(contextual!);
    return ContextualMappingInfo(mapper: mapper);
  }

  static LiteralMappingInfo? _extractLiteralMapping(DartObject annotation) {
    // Check for named parameter 'iri'
    final literal = getField(annotation, 'literal');
    if (isNull(literal)) {
      return null;
    }
    // Check if it's an IriMapping
    final language = getField(literal!, 'language')?.toStringValue();
    final datatype = getIriTermInfo(getField(literal, 'datatype'));
    final mapper = getMapperRefInfo<IriTermMapper>(literal);
    return LiteralMappingInfo(
        language: language, datatype: datatype, mapper: mapper);
  }

  /// Infers appropriate mappings if no explicit mapping is provided
  /// and the field type has an RDF annotation with registerGlobally: false.
  static _InferredMappings _inferMappingsFromType(
    DartType fieldType,
    LocalResourceMappingInfo? existingLocalResource,
    LiteralMappingInfo? existingLiteral,
    GlobalResourceMappingInfo? existingGlobalResource,
    IriMappingInfo? existingIri,
  ) {
    // Only infer if no explicit mapping is already provided
    if (existingLocalResource != null ||
        existingLiteral != null ||
        existingGlobalResource != null ||
        existingIri != null) {
      return const _InferredMappings();
    }

    // Analyze the field type for RDF annotations
    final rdfAnnotationInfo = analyzeTypeForRdfAnnotation(fieldType);
    //log.warning(
    //    'rdfAnnotationInfo for ${fieldType.toCode().codeWithoutAlias}: $rdfAnnotationInfo - ${rdfAnnotationInfo?.registerGlobally} - ${rdfAnnotationInfo?.mapperClassName}');
    if (rdfAnnotationInfo == null) {
      return const _InferredMappings();
    }

    // Only infer for types with registerGlobally: false
    if (rdfAnnotationInfo.registerGlobally) {
      return const _InferredMappings();
    }
    final type = Code.type(rdfAnnotationInfo.mapperClassName,
        importUri: rdfAnnotationInfo.mapperImportPath);

    // Create the appropriate mapper reference based on annotation type
    switch (rdfAnnotationInfo.annotationType) {
      case 'RdfGlobalResource':
        final mapperRef = MapperRefInfo<GlobalResourceMapper>(
          name: null,
          type: type, // We'll use the mapper class name directly
          instance: null,
        );
        return _InferredMappings(
          globalResource: GlobalResourceMappingInfo(mapper: mapperRef),
          dependencyType: fieldType, // Pass the type for cross-file processing
        );

      case 'RdfLocalResource':
        final mapperRef = MapperRefInfo<LocalResourceMapper>(
          name: null,
          type: type,
          instance: null,
        );
        return _InferredMappings(
          localResource: LocalResourceMappingInfo(mapper: mapperRef),
          dependencyType: fieldType, // Pass the type for cross-file processing
        );

      case 'RdfLiteral':
        final mapperRef = MapperRefInfo<LiteralTermMapper>(
          name: null,
          type: type,
          instance: null,
        );
        return _InferredMappings(
          literal: LiteralMappingInfo(
            language: null, // Default values since we're inferring
            datatype: null,
            mapper: mapperRef,
          ),
          dependencyType: fieldType, // Pass the type for cross-file processing
        );

      case 'RdfIri':
        final mapperRef = MapperRefInfo<IriTermMapper>(
          name: null,
          type: type,
          instance: null,
        );
        return _InferredMappings(
          iri: IriMappingInfo(
            template: null, // Default template will be handled elsewhere
            mapper: mapperRef,
          ),
          dependencyType: fieldType, // Pass the type for cross-file processing
        );

      default:
        return const _InferredMappings();
    }
  }
}
