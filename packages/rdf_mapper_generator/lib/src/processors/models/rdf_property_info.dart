// import 'package:analyzer/dart/constant/value.dart';
// import 'package:analyzer/dart/element/type.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';

class LocalResourceMappingInfo extends BaseMappingInfo {
  LocalResourceMappingInfo({required super.mapper});

  @override
  int get hashCode => Object.hashAll([
        super.hashCode,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! LocalResourceMappingInfo) {
      return false;
    }
    return super == other;
  }

  @override
  String toString() {
    return 'LocalResourceMappingInfo{mapper: $mapper}';
  }
}

/// Configuration for RDF collection mapping strategies.
///
/// This class represents the processed `collection` parameter from [RdfProperty]
/// annotations, which determines how Dart collections are serialized to RDF.
/// This is independent of the underlying Dart collection type analysis.
///
/// **Collection Strategies**:
/// - **Auto-detected mappers**: When `mapper` is set and `isAuto` is true
/// - **Explicit factories**: When `factory` is set (e.g., `rdfList`, `rdfSeq`)
/// - **Custom mappers**: When `mapper` is set with a specific mapper type
///
/// Examples:
/// ```dart
/// @RdfProperty(prop, collection: rdfList) // factory-based
/// @RdfProperty(prop, collection: CollectionMapping.mapper(CustomMapper)) // mapper-based
/// @RdfProperty(prop) // auto-detected based on Dart type
/// ```
class CollectionMappingInfo extends BaseMappingInfo {
  /// Whether the collection mapper was auto-detected from the Dart type.
  ///
  /// When `true`, the system automatically chose an appropriate mapper
  /// based on the field's Dart collection type (List → UnorderedItemsListMapper, etc.).
  bool isAuto;

  /// Factory function for creating collection mappers.
  ///
  /// Set when using predefined collection strategies like `rdfList`, `rdfSeq`,
  /// `rdfBag`, or `rdfAlt`. When this is set, [mapper] should be null.
  Code? factory;

  CollectionMappingInfo(
      {required super.mapper, required this.isAuto, required this.factory});

  @override
  int get hashCode => Object.hashAll([
        super.hashCode,
        isAuto,
        factory,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! CollectionMappingInfo) {
      return false;
    }
    return super == other && isAuto == other.isAuto && factory == other.factory;
  }

  @override
  String toString() {
    return 'CollectionMappingInfo{mapper: $mapper, isAuto: $isAuto, factoryConstructor: $factory}';
  }
}

class LiteralMappingInfo extends BaseMappingInfo {
  final String? language;

  final IriTermInfo? datatype;

  LiteralMappingInfo(
      {required this.language, required this.datatype, required super.mapper});

  @override
  int get hashCode => Object.hashAll([
        super.hashCode,
        language,
        datatype,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! LiteralMappingInfo) {
      return false;
    }
    return super == other &&
        language == other.language &&
        datatype == other.datatype;
  }

  @override
  String toString() {
    return 'LiteralMappingInfo{'
        'mapper: $mapper, '
        'language: $language, '
        'datatype: $datatype}';
  }
}

class GlobalResourceMappingInfo extends BaseMappingInfo {
  GlobalResourceMappingInfo({required super.mapper});

  @override
  int get hashCode => Object.hashAll([
        super.hashCode,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! GlobalResourceMappingInfo) {
      return false;
    }
    return super == other;
  }

  @override
  String toString() {
    return 'GlobalResourceMappingInfo{mapper: $mapper}';
  }
}

class IriMappingInfo extends BaseMappingInfo {
  final IriTemplateInfo? template;

  IriMappingInfo({required this.template, required super.mapper});

  bool get isFullIriTemplate =>
      mapper == null &&
      (template == null ||
          (template!.variables.length == 1 &&
              template!.template == '{+${template!.variables.first}}'));
  @override
  int get hashCode => Object.hashAll([
        super.hashCode,
        template,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! IriMappingInfo) {
      return false;
    }
    return super == other && template == other.template;
  }

  @override
  String toString() {
    return 'IriMappingInfo{'
        'mapper: $mapper, '
        'template: $template}';
  }
}

/// Information about contextual mapping configuration.
///
/// Used when a property needs access to its parent object during serialization
/// and subject during deserialization for computing context-dependent values.
class ContextualMappingInfo extends BaseMappingInfo<SerializationProvider> {
  ContextualMappingInfo({required super.mapper});
  @override
  int get hashCode => Object.hashAll([
        super.hashCode,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! ContextualMappingInfo) {
      return false;
    }
    return super == other;
  }

  @override
  String toString() {
    return 'ContextualMappingInfo{mapper: $mapper}';
  }
}

/// Processed information from an [RdfProperty] annotation.
///
/// This class represents the complete parsed and validated RDF property
/// configuration, including all mapping strategies and metadata.
///
/// **Mapping Strategy Priority**:
/// The processor validates that only one primary mapping strategy is configured:
/// - [iri]: Map to IRI resources
/// - [literal]: Map to RDF literals
/// - [localResource]: Map to local RDF resources
/// - [globalResource]: Map to global RDF resources
///
/// **Collection Handling**:
/// The [collection] property is orthogonal to the primary mapping strategies
/// and determines how Dart collections are structured in RDF, not how
/// individual elements are mapped.
class RdfPropertyAnnotationInfo implements RdfAnnotation {
  /// The RDF predicate (property) IRI for this field.
  final IriTermInfo predicate;

  /// Whether this property should be included in RDF serialization.
  ///
  /// When `false`, the field is ignored during RDF processing.
  final bool include;

  /// The default value for this property, if specified.
  final DartObject? defaultValue;

  /// Whether to include default values in RDF serialization.
  ///
  /// When `false`, fields with default values are omitted from RDF output
  /// to reduce verbosity.
  final bool includeDefaultsInSerialization;

  /// IRI mapping configuration for this property.
  ///
  /// When set, field values are mapped to IRI resources using the specified
  /// template or mapper. Mutually exclusive with other mapping strategies.
  final IriMappingInfo? iri;

  /// Local resource mapping configuration.
  ///
  /// When set, field values are mapped to blank nodes or local IRI resources.
  /// Mutually exclusive with other mapping strategies.
  final LocalResourceMappingInfo? localResource;

  /// Literal mapping configuration.
  ///
  /// When set, field values are mapped to RDF literals with optional
  /// datatype or language tags. Mutually exclusive with other mapping strategies.
  final LiteralMappingInfo? literal;

  /// Global resource mapping configuration.
  ///
  /// When set, field values are mapped to globally registered IRI resources.
  /// Mutually exclusive with other mapping strategies.
  final GlobalResourceMappingInfo? globalResource;

  /// Contextual mapping configuration.
  ///
  /// When set, field values are mapped using contextual serializer and deserializer
  /// factory functions that have access to the parent object and subject.
  /// Mutually exclusive with other mapping strategies.
  final ContextualMappingInfo? contextual;

  /// Collection mapping strategy configuration.
  ///
  /// Determines how Dart collections are structured in RDF (default triples,
  /// rdf:List, rdf:Seq, etc.). This is independent of how individual collection
  /// elements are mapped, which is determined by the other mapping strategies.
  final CollectionMappingInfo? collection;

  /// The runtime type of collection elements, when applicable.
  final DartType? itemType;

  const RdfPropertyAnnotationInfo(
    this.predicate, {
    required this.include,
    required this.defaultValue,
    required this.includeDefaultsInSerialization,
    required this.iri,
    required this.localResource,
    required this.literal,
    required this.globalResource,
    required this.contextual,
    required this.collection,
    required this.itemType,
  });

  @override
  int get hashCode => Object.hashAll([
        predicate,
        include,
        defaultValue,
        includeDefaultsInSerialization,
        iri,
        localResource,
        literal,
        globalResource,
        contextual,
        collection,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! RdfPropertyAnnotationInfo) {
      return false;
    }
    return predicate == other.predicate &&
        include == other.include &&
        defaultValue == other.defaultValue &&
        includeDefaultsInSerialization ==
            other.includeDefaultsInSerialization &&
        iri == other.iri &&
        localResource == other.localResource &&
        literal == other.literal &&
        globalResource == other.globalResource &&
        contextual == other.contextual &&
        collection == other.collection;
  }

  @override
  String toString() {
    return 'RdfPropertyInfo{'
        'predicate: $predicate, '
        'include: $include, '
        'defaultValue: $defaultValue, '
        'includeDefaultsInSerialization: $includeDefaultsInSerialization, '
        'iri: $iri, '
        'localResource: $localResource, '
        'literal: $literal, '
        'globalResource: $globalResource, '
        'contextual: $contextual, '
        'collection: $collection}';
  }
}

/// Information about collection properties in Dart code.
///
/// This class analyzes the Dart type system to determine if a property represents
/// a Dart core collection type (List, Set, Iterable, Map) and extracts type information
/// about elements and keys/values.
///
/// **Important**: The `isCoreCollection` family of properties specifically detect
/// Dart core collection types, not custom collection implementations or the general
/// concept of collections in RDF mapping. Custom collection types (like `ImmutableList`)
/// will have `isCoreCollection = false` even if they represent collections conceptually.
class CollectionInfo {
  /// The detected Dart core collection type, or null if not a core collection.
  ///
  /// This will be null for custom collection types even if they implement
  /// collection-like behavior.
  final CollectionType? type;

  /// The element type for List/Set, or MapEntry&lt;K,V&gt; type for Map.
  ///
  /// For custom collection types, this may still contain the element type
  /// if it can be extracted from the generic type parameters.
  final Code? elementTypeCode;

  /// The runtime element type for List/Set collections.
  final DartType? elementType;

  /// For Maps: the key type extracted from Map&lt;K,V&gt;.
  final Code? keyTypeCode;

  /// For Maps: the value type extracted from Map&lt;K,V&gt;.
  final Code? valueTypeCode;

  const CollectionInfo({
    this.type,
    this.elementTypeCode,
    this.keyTypeCode,
    this.valueTypeCode,
    this.elementType,
  });

  /// Whether this property represents a Dart core collection type.
  ///
  /// Returns `true` only for standard Dart collections: List, Set, Iterable, Map.
  /// Custom collection implementations (like `ImmutableList`, `BuiltList`, etc.)
  /// will return `false` even if they provide collection-like functionality.
  ///
  /// Use this to distinguish between core Dart collections and custom types
  /// that may require different handling in code generation.
  bool get isCoreCollection => type != null;

  /// Whether this property is specifically a Dart core `List<T>` type.
  ///
  /// Returns `false` for custom list implementations and other collection types.
  bool get isCoreList => type == CollectionType.list;

  /// Whether this property is specifically a Dart core `Set<T>` type.
  ///
  /// Returns `false` for custom set implementations and other collection types.
  bool get isCoreSet => type == CollectionType.set;

  /// Whether this property is specifically a Dart core `Map<K,V>` type.
  ///
  /// Returns `false` for custom map implementations and other collection types.
  bool get isCoreMap => type == CollectionType.map;

  /// Whether this property represents an iterable type in the Dart core library.
  ///
  /// Returns `true` for:
  /// - Dart core `Iterable<T>`
  /// - Dart core `List<T>` (since List implements Iterable)
  /// - Dart core `Set<T>` (since Set implements Iterable)
  ///
  /// Returns `false` for custom iterable implementations and Map types.
  bool get isIterable =>
      type == CollectionType.iterable || isCoreList || isCoreSet;

  @override
  int get hashCode => Object.hashAll([
        type,
        elementTypeCode,
        keyTypeCode,
        valueTypeCode,
        elementType,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! CollectionInfo) {
      return false;
    }
    return type == other.type &&
        elementTypeCode == other.elementTypeCode &&
        keyTypeCode == other.keyTypeCode &&
        valueTypeCode == other.valueTypeCode &&
        elementType == other.elementType;
  }

  @override
  String toString() {
    return 'CollectionInfo{type: $type, elementType: ${elementTypeCode?.code}, keyType: ${keyTypeCode?.code}, valueType: ${valueTypeCode?.code}, elementType: ${elementType}}';
  }
}

/// Enumeration of Dart core collection types that can be automatically detected.
///
/// These correspond to the standard collection types in the Dart core library.
/// Custom collection implementations are not represented in this enum and will
/// be handled differently by the property processor.
enum CollectionType {
  /// Represents `List<T>` from dart:core
  list,

  /// Represents `Set<T>` from dart:core
  set,

  /// Represents `Iterable<T>` from dart:core
  iterable,

  /// Represents `Map<K,V>` from dart:core
  map
}

/// Contains comprehensive information about a field annotated with [RdfProperty].
///
/// This class combines the parsed RDF property annotation with static analysis
/// information about the field's Dart type, including collection type detection
/// and metadata about the field declaration.
///
/// The [collectionInfo] property specifically analyzes Dart core collection types
/// and should not be confused with RDF collection mapping strategies, which are
/// handled separately in the [RdfPropertyAnnotationInfo.collection] annotation.
class RdfPropertyInfo {
  /// The field name as declared in the Dart source code.
  final String name;

  /// The complete Dart type of the field, including generic parameters.
  final Code type;

  /// The parsed and processed RDF property annotation.
  ///
  /// Contains all RDF mapping information including collection strategies,
  /// literal mappings, IRI mappings, etc.
  final RdfPropertyAnnotationInfo annotation;

  /// Whether this field is required (non-nullable and no default value).
  final bool isRequired;

  /// Whether this field is declared as `final`.
  final bool isFinal;

  /// Whether this field is declared as `late`.
  final bool isLate;

  /// Whether this field is declared as `static`.
  final bool isStatic;

  /// Whether this is a synthetic field (generated by the analyzer).
  final bool isSynthetic;

  /// Analysis of the field's Dart type for core collection detection.
  ///
  /// This analyzes the Dart type system to detect standard collection types
  /// (List, Set, Map, Iterable) and extract element/key/value type information.
  ///
  /// **Note**: This is separate from RDF collection mapping configuration,
  /// which is found in [annotation.collection]. A field can have a custom
  /// collection type (like `ImmutableList`) with `collectionInfo.isCoreCollection = false`
  /// but still have RDF collection mapping configured.
  final CollectionInfo collectionInfo;

  const RdfPropertyInfo({
    required this.name,
    required this.type,
    required this.annotation,
    required this.isRequired,
    required this.isFinal,
    required this.isLate,
    required this.isStatic,
    required this.isSynthetic,
    required this.collectionInfo,
  });

  @override
  int get hashCode => Object.hashAll([
        name,
        type,
        annotation,
        isRequired,
        isFinal,
        isLate,
        isStatic,
        isSynthetic,
        collectionInfo,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! RdfPropertyInfo) {
      return false;
    }
    return name == other.name &&
        type == other.type &&
        annotation == other.annotation &&
        isRequired == other.isRequired &&
        isFinal == other.isFinal &&
        isLate == other.isLate &&
        isStatic == other.isStatic &&
        isSynthetic == other.isSynthetic &&
        collectionInfo == other.collectionInfo;
  }

  @override
  String toString() {
    return 'PropertyInfo{\n'
        '  name: $name,\n'
        '  annotation: $annotation,\n'
        '  type: ${type.codeWithoutAlias},\n'
        '  isRequired: $isRequired,\n'
        '  isFinal: $isFinal,\n'
        '  isLate: $isLate,\n'
        '  isStatic: $isStatic,\n'
        '  isSynthetic: $isSynthetic,\n'
        '  collectionInfo: $collectionInfo,\n'
        '}';
  }
}
