import 'package:locorda_rdf_mapper_generator/src/mappers/iri_model_builder_support.dart';
import 'package:locorda_rdf_mapper_generator/src/mappers/mapped_model_builder.dart';
import 'package:locorda_rdf_mapper_generator/src/mappers/mapper_model.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/util.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:locorda_rdf_mapper_generator/src/vocab/fragment_validator.dart';

class ResourceModelBuilderSupport {
  /// Builds template data for a global resource mapper.
  static List<MapperModel> buildResourceMapper(ValidationContext context,
      ResourceInfo resourceInfo, String mapperImportUri) {
    var annotation = resourceInfo.annotation;
    if (annotation.mapper != null) {
      throw Exception(
        'ResourceMapper cannot have a mapper defined in the annotation.',
      );
    }
    final isGlobalResource = annotation is RdfGlobalResourceInfo;
    final mappedClassName = resourceInfo.className;
    final implementationClass = Code.type(
        '${mappedClassName.codeWithoutAlias}Mapper',
        importUri: mapperImportUri);
    final termClass = isGlobalResource
        ? Code.type('IriTerm', importUri: importRdfCore)
        : Code.type('BlankNodeTerm', importUri: importRdfCore);

    (AppVocabModel?, Code?, String?) convertVocab(
        AppVocabInfo? vocabInfo, IriTermInfo? subClassOf) {
      if (vocabInfo == null) return (null, null, null);
      final vocabModel = AppVocabModel(
        appBaseUri: vocabInfo.appBaseUri,
        vocabPath: vocabInfo.vocabPath,
        defaultBaseClass: vocabInfo.defaultBaseClass,
        wellKnownProperties: vocabInfo.wellKnownProperties,
        label: vocabInfo.label,
        comment: vocabInfo.comment,
        metadata: vocabInfo.metadata,
      );
      final subClassOfIri = subClassOf?.value.value;
      return (vocabModel, subClassOf?.code, subClassOfIri);
    }

    // Extract vocabulary generation metadata
    final (vocab, subClassOf, subClassOfIri) = switch (annotation) {
      RdfGlobalResourceInfo(vocab: final globalVocab) =>
        convertVocab(globalVocab, annotation.subClassOf),
      RdfLocalResourceInfo(vocab: final localVocab) =>
        convertVocab(localVocab, annotation.subClassOf),
    };

    // Build type IRI expression
    final typeIri = _buildTypeIri(context, resourceInfo, vocab);

    // Build IRI strategy data
    final iriStrategy = _buildIriStrategyForResource(resourceInfo, 'iri');

    final mappedClassModel = MappedClassModelBuilder.buildMappedClassModel(
      context,
      mappedClassName,
      mapperImportUri,
      resourceInfo.constructors,
      resourceInfo.properties,
      resourceInfo.annotations,
      vocab: vocab,
    );

    final invalidParameters = mappedClassModel.properties.where((p) =>
        p.isNeedsToBeSet &&
        !(p.isIriPart || p.isRdfProperty || p.isRdfUnmappedTriples));
    if (invalidParameters.isNotEmpty) {
      context.addError(
        'Resource class "${resourceInfo.className.code}" has invalid constructor parameters\n'
        '  • Constructor parameters must be annotated with @RdfIriPart, @RdfProperty, or @RdfUnmappedTriples\n'
        '  • Invalid parameters: ${invalidParameters.map((p) => p.propertyName).join(', ')}\n'
        '  • Consider adding appropriate annotations or making these parameters optional',
      );
    }

    final dependencies = _collectDependencies(iriStrategy, mappedClassModel,
        mapperImportUri, resourceInfo.typeParameters);
    final provides = [
      ...mappedClassModel.properties.where((p) => p.isProvides).map((p) =>
          ProvidesModel(
              dartPropertyName: p.propertyName,
              name: p.providesVariableName ?? p.propertyName)),
      // Add IRI providedAs if specified
      if (iriStrategy?.providedAs != null)
        ProvidesModel(
            dartPropertyName: '\$iri',
            name: iriStrategy!.providedAs!,
            isIriProvider: true),
    ].toList();
    final MapperType mapperType = switch (annotation.direction) {
      SerializationDirection.serializeOnly => isGlobalResource
          ? MapperType.globalResourceSerializer
          : MapperType.localResourceSerializer,
      SerializationDirection.deserializeOnly => isGlobalResource
          ? MapperType.globalResourceDeserializer
          : MapperType.localResourceDeserializer,
      null =>
        isGlobalResource ? MapperType.globalResource : MapperType.localResource,
    };

    final resourceMapper = ResourceMapperModel(
      mappedClass: mappedClassName,
      mappedClassModel: mappedClassModel,
      id: MapperRef.fromImplementationClass(implementationClass),
      implementationClass: implementationClass,
      termClass: termClass,
      typeIri: typeIri,
      dependencies: dependencies,
      iriStrategy: iriStrategy,
      vocab: vocab,
      subClassOf: subClassOf,
      subClassOfIri: subClassOfIri,
      genVocabMetadata: switch (annotation) {
        RdfGlobalResourceInfo(metadata: final metadata) => metadata,
        RdfLocalResourceInfo(metadata: final metadata) => metadata,
      },
      needsReader: resourceInfo.properties.any((p) => p.propertyInfo != null),
      registerGlobally: resourceInfo.annotation.registerGlobally,
      provides: provides,
      typeParameters: resourceInfo.typeParameters,
      type: mapperType,
    );

    return [
      resourceMapper,
      ...resourceMapper.mappedClassModel.properties
          .expand((p) => p.iriMapping?.extraMappers ?? const [])
    ];
  }

  static List<DependencyModel> _collectDependencies(
          IriModel? iriStrategy,
          MappedClassModel mappedClassModel,
          String mapperImportUri,
          List<String> typeParameters) =>
      [
        if (iriStrategy?.mapper != null) iriStrategy!.mapper!,
        if (iriStrategy?.template?.contextVariables != null)
          ...iriStrategy!.template!.contextVariables.map((cv) => cv.dependency),
        ...mappedClassModel.properties.expand((f) {
          final collection = f.collectionMapping;
          final iri = f.iriMapping;
          final literal = f.literalMapping;
          final globalResourceMapper = f.globalResourceMapping;
          final localResourceMapper = f.localResourceMapping;
          final contextual = f.contextualMapping;

          return [
            if (collection != null) collection.dependency,
            if (iri != null) iri.dependency,
            if (literal != null) literal.dependency,
            if (globalResourceMapper != null) globalResourceMapper.dependency,
            if (localResourceMapper != null) localResourceMapper.dependency,
            if (contextual != null) contextual.dependency
          ];
        })
      ];

  /// Builds the type IRI expression.
  static Code? _buildTypeIri(ValidationContext context,
      ResourceInfo resourceInfo, AppVocabModel? vocab) {
    final classIriInfo = resourceInfo.annotation.classIri;
    if (classIriInfo != null) {
      return classIriInfo.code;
    }
    if (vocab == null) {
      return null;
    }

    final className = resourceInfo.className.codeWithoutAlias.split('<').first;
    final error = validateUpperCamelCase(className);
    if (error != null) {
      context.addError(error);
    }

    final vocabIri = '${vocab.appBaseUri}${vocab.vocabPath}#';
    final iriValue = '$vocabIri$className';
    return const Code.literal('const ') +
        Code.type('IriTerm', importUri: importRdfCore)
            .newInstance([Code.literal("'$iriValue'")]);
  }

  static IriModel? _buildIriStrategyForResource(
      ResourceInfo resourceInfo, String referenceName) {
    final annotation = resourceInfo.annotation;
    if (annotation is! RdfGlobalResourceInfo) {
      return null;
    }
    final iriStrategy = annotation.iri;
    if (iriStrategy == null) {
      // IRI strategy is optional for deserialize-only mappers
      if (annotation.direction == SerializationDirection.deserializeOnly) {
        return null;
      }
      throw Exception(
        'Trying to generate a mapper for resource ${resourceInfo.className}, but iri strategy is not defined. This should not be possible.',
      );
    }
    return IriModelBuilderSupport.buildIriData(
        referenceName,
        iriStrategy.template,
        iriStrategy.mapper,
        iriStrategy.iriMapperType?.type,
        iriStrategy.iriMapperType?.parts,
        iriStrategy.templateInfo,
        resourceInfo.properties,
        resourceInfo.className,
        providedAs: iriStrategy.providedAs);
  }
}
