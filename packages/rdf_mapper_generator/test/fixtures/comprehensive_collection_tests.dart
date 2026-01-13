/// Comprehensive test cases for all collection mapping scenarios.
///
/// This file covers all missing test cases identified in the collection mapping system:
/// 1. CollectionMapping.fromRegistry() tests
/// 2. CollectionMapping.namedMapper() tests
/// 3. CollectionMapping.mapper() vs .withItemMappers() distinction
/// 4. CollectionMapping.mapperInstance() tests
/// 5. `Set<T>` and `Iterable<T>` collection tests
/// 6. itemType parameter tests
/// 7. Combined item mapping tests
/// 8. Edge cases and error scenarios
/// 9. Map collections
/// 10. includeDefaultsInSerialization with collections
library;

import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_schema/schema.dart';
import 'package:rdf_vocabularies_core/xsd.dart';

/// Test vocabulary for comprehensive collection testing
class TestVocab {
  static const _base = 'http://test.example.org/vocab#';

  static const TestEntity = const IriTerm(_base + 'TestEntity');
  static const ComplexItem = const IriTerm(_base + 'ComplexItem');

  static const registryCollection = const IriTerm(_base + 'registryCollection');
  static const namedMapperCollection =
      const IriTerm(_base + 'namedMapperCollection');
  static const selfContainedCollection =
      const IriTerm(_base + 'selfContainedCollection');
  static const instanceManagedCollection =
      const IriTerm(_base + 'instanceManagedCollection');
  static const bagCollection = const IriTerm(_base + 'bagCollection');
  static const orderedCollection = const IriTerm(_base + 'orderedCollection');
  static const defaultIterable = const IriTerm(_base + 'defaultIterable');
  static const sequenceIterable = const IriTerm(_base + 'sequenceIterable');
  static const complexCollection = const IriTerm(_base + 'complexCollection');
  static const iriItemsList = const IriTerm(_base + 'iriItemsList');
  static const resourceItemsSeq = const IriTerm(_base + 'resourceItemsSeq');
  static const languageTaggedBag = const IriTerm(_base + 'languageTaggedBag');
  static const emptyList = const IriTerm(_base + 'emptyList');
  static const nullableList = const IriTerm(_base + 'nullableList');
  static const defaultMap = const IriTerm(_base + 'defaultMap');
  static const customMap = const IriTerm(_base + 'customMap');
  static const defaultHandledList = const IriTerm(_base + 'defaultHandledList');
  static const mixedTypeList = const IriTerm(_base + 'mixedTypeList');
  static const nestedCollections = const IriTerm(_base + 'nestedCollections');
  static const performanceList = const IriTerm(_base + 'performanceList');
}

// =============================================================================
// TEST CASE 1: CollectionMapping.fromRegistry() Tests
// =============================================================================

@RdfLocalResource()
class RegistryCollectionTests {
  /// Uses registry-based collection mapping (matches behavior of other mapping properties)
  @RdfProperty(TestVocab.registryCollection,
      collection: CollectionMapping.fromRegistry())
  final List<String> registryManagedCollection;

  RegistryCollectionTests({required this.registryManagedCollection});
}

// =============================================================================
// TEST CASE 2: CollectionMapping.namedMapper() Tests
// =============================================================================

@RdfLocalResource()
class NamedMapperCollectionTests {
  /// Uses named mapper injection at runtime
  @RdfProperty(TestVocab.namedMapperCollection,
      collection: CollectionMapping.namedMapper('customCollectionMapper'))
  final List<String> namedManagedCollection;

  NamedMapperCollectionTests({required this.namedManagedCollection});
}

// =============================================================================
// TEST CASE 3: CollectionMapping.mapper() vs .withItemMappers() Distinction
// =============================================================================

@RdfLocalResource()
class SelfContainedMapperTests {
  /// Self-contained mapper handles entire collection internally (e.g., as single JSON array)
  @RdfProperty(TestVocab.selfContainedCollection,
      collection: CollectionMapping.mapper(StringListMapper))
  final List<String> selfContainedCollection;

  SelfContainedMapperTests({required this.selfContainedCollection});
}

/// Self-contained mapper that serializes entire list as single literal
class StringListMapper implements LiteralTermMapper<List<String>> {
  const StringListMapper(); // No-argument constructor required

  @override
  IriTerm? get datatype => null;

  @override
  List<String> fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    // Parse JSON array from literal value
    final value = term.value;
    if (value.startsWith('[') && value.endsWith(']')) {
      return value
          .substring(1, value.length - 1)
          .split(',')
          .map((s) => s.trim().replaceAll('"', ''))
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  @override
  LiteralTerm toRdfTerm(List<String> value, SerializationContext context) {
    // Serialize entire list as JSON array literal
    final jsonArray = '[${value.map((s) => '"$s"').join(', ')}]';
    return LiteralTerm(jsonArray);
  }
}

// =============================================================================
// TEST CASE 4: CollectionMapping.mapperInstance() Tests
// =============================================================================

/// Configurable collection mapper for direct instance usage
class ConfigurableCollectionMapper implements LiteralTermMapper<List<String>> {
  final String prefix;
  final String separator;

  const ConfigurableCollectionMapper({
    this.prefix = '',
    this.separator = ',',
  });

  @override
  IriTerm? get datatype => null;

  @override
  List<String> fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    final value = term.value;
    if (value.startsWith(prefix)) {
      return value.substring(prefix.length).split(separator);
    }
    return value.split(separator);
  }

  @override
  LiteralTerm toRdfTerm(List<String> value, SerializationContext context) {
    return LiteralTerm('$prefix${value.join(separator)}');
  }
}

// Pre-configured mapper instance
const customMapperInstance = ConfigurableCollectionMapper(
  prefix: 'LIST:',
  separator: '|',
);

@RdfLocalResource()
class InstanceManagedCollectionTests {
  /// Uses direct mapper instance with custom configuration
  @RdfProperty(TestVocab.instanceManagedCollection,
      collection: CollectionMapping.mapperInstance(customMapperInstance))
  final List<String> instanceManagedCollection;

  InstanceManagedCollectionTests({required this.instanceManagedCollection});
}

// =============================================================================
// TEST CASE 5: Set<T> and Iterable<T> Collection Tests
// =============================================================================

@RdfLocalResource()
class SetAndIterableCollectionTests {
  /// Bag collections (unordered) - use List since RDF bags map to Lists
  @RdfProperty(TestVocab.bagCollection, collection: rdfBag)
  final List<String> bagCollection;

  @RdfProperty(TestVocab.orderedCollection, collection: rdfList)
  final List<String> orderedCollection;

  /// Iterable collections (semantic distinction without structural mapping)
  @RdfProperty(TestVocab.defaultIterable) // Uses default multi-triple mapping
  final Iterable<String> defaultIterable;

  @RdfProperty(TestVocab.sequenceIterable, collection: rdfSeq)
  final List<String> sequenceIterable; // RDF Seq also maps to List

  SetAndIterableCollectionTests({
    required this.bagCollection,
    required this.orderedCollection,
    required this.defaultIterable,
    required this.sequenceIterable,
  });
}

// =============================================================================
// TEST CASE 6: itemType Parameter Tests
// =============================================================================

/// Custom collection type that doesn't expose generic parameters clearly
class CustomCollection with Iterable<ComplexItem> {
  final List<ComplexItem> _items;

  CustomCollection(this._items);

  @override
  Iterator<ComplexItem> get iterator => _items.iterator;

  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;
  ComplexItem operator [](int index) => _items[index];
}

/// Complex item type for testing
@RdfLocalResource()
class ComplexItem {
  @RdfProperty(SchemaEvent.name)
  final String name;

  @RdfProperty(SchemaEvent.identifier)
  final int id;

  ComplexItem({required this.name, required this.id});
}

/// Custom collection mapper that needs item mappers
class CustomCollectionMapper
    with
        UnorderedItemsSerializerMixin<ComplexItem>,
        UnorderedItemsDeserializerMixin<ComplexItem>
    implements MultiObjectsMapper<CustomCollection> {
  final Deserializer<ComplexItem>? _itemDeserializer;
  final Serializer<ComplexItem>? _itemSerializer;

  const CustomCollectionMapper({
    Deserializer<ComplexItem>? itemDeserializer,
    Serializer<ComplexItem>? itemSerializer,
  })  : _itemDeserializer = itemDeserializer,
        _itemSerializer = itemSerializer;

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          CustomCollection value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemSerializer);

  @override
  CustomCollection fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      CustomCollection(
          readRdfObjects(objects, context, _itemDeserializer).toList());
}

@RdfLocalResource()
class ItemTypeParameterTests {
  /// Explicit item type specification for complex generics
  @RdfProperty(TestVocab.complexCollection,
      collection: CollectionMapping.withItemMappers(CustomCollectionMapper),
      itemType:
          ComplexItem, // Explicit because type inference will not work here and produce incorrect type
      localResource: LocalResourceMapping.namedMapper('complexItemMapperLocal'))
  final CustomCollection complexCollection;

  ItemTypeParameterTests({required this.complexCollection});
}

// =============================================================================
// TEST CASE 7: Combined Item Mapping Tests
// =============================================================================

@RdfLocalResource()
class CombinedItemMappingTests {
  /// Collection with IRI item mapping
  @RdfProperty(
    TestVocab.iriItemsList,
    collection: rdfList,
    iri: IriMapping('{+baseUri}/item/{iriItemsList}'), // Each item becomes IRI
  )
  final List<String> iriItemsList;

  /// Collection with global resource item mapping
  @RdfProperty(
    TestVocab.resourceItemsSeq,
    collection: rdfSeq,
    globalResource:
        GlobalResourceMapping.namedMapper('complexItemMapperGlobal'),
  )
  final List<ComplexItem> resourceItemsSeq;

  /// Collection with literal item mapping including language tags
  @RdfProperty(
    TestVocab.languageTaggedBag,
    collection: rdfBag,
    literal: LiteralMapping.withLanguage('en'),
  )
  final List<String> languageTaggedBag;

  CombinedItemMappingTests({
    required this.iriItemsList,
    required this.resourceItemsSeq,
    required this.languageTaggedBag,
  });
}

// =============================================================================
// TEST CASE 8: Edge Cases and Error Scenarios
// =============================================================================

@RdfLocalResource()
class EdgeCaseTests {
  /// Empty collections
  @RdfProperty(TestVocab.emptyList, collection: rdfList)
  final List<String> emptyList;

  /// Null handling with defaults
  @RdfProperty(TestVocab.nullableList, collection: rdfSeq, defaultValue: [])
  final List<String> nullableList;

  EdgeCaseTests({
    required this.emptyList,
    required this.nullableList,
  });
}

/// Performance test with large collections
@RdfLocalResource()
class PerformanceTests {
  /// Large collection for performance testing
  @RdfProperty(TestVocab.performanceList, collection: rdfList)
  final List<String> performanceList;

  PerformanceTests({required this.performanceList});
}

// =============================================================================
// TEST CASE 9: Map Collections
// =============================================================================

@RdfLocalResource()
class MapCollectionTests {
  /// Default map using @RdfMapEntry annotations
  @RdfProperty(TestVocab.defaultMap)
  final Map<String, String> defaultMap;

  /// Map with custom collection mapping
  @RdfProperty(TestVocab.customMap,
      collection: CollectionMapping.mapper(CustomMapMapper))
  final Map<String, String> customMap;

  MapCollectionTests({
    required this.defaultMap,
    required this.customMap,
  });
}

/// Custom map mapper that serializes as single literal
class CustomMapMapper implements LiteralTermMapper<Map<String, String>> {
  const CustomMapMapper();

  @override
  IriTerm? get datatype => null;

  @override
  Map<String, String> fromRdfTerm(
      LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    final entries = term.value.split(';');
    final map = <String, String>{};
    for (final entry in entries) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }

  @override
  LiteralTerm toRdfTerm(
      Map<String, String> value, SerializationContext context) {
    final entries = value.entries.map((e) => '${e.key}:${e.value}').join(';');
    return LiteralTerm(entries);
  }
}

// =============================================================================
// TEST CASE 10: includeDefaultsInSerialization with Collections
// =============================================================================

@RdfLocalResource()
class DefaultSerializationTests {
  /// Default value handling in collections
  @RdfProperty(TestVocab.defaultHandledList,
      collection: rdfList,
      defaultValue: [],
      includeDefaultsInSerialization: true)
  final List<String> defaultHandledList;

  DefaultSerializationTests({required this.defaultHandledList});
}

// =============================================================================
// Additional Complex Test Cases
// =============================================================================

/// Nested collection scenarios
@RdfLocalResource()
class NestedCollectionTests {
  /// Testing nested collections (List of Lists)
  @RdfProperty(TestVocab.nestedCollections, collection: rdfList)
  final List<List<String>> nestedCollections;

  NestedCollectionTests({required this.nestedCollections});
}

/// Mixed type collections
@RdfLocalResource()
class MixedTypeTests {
  /// Collection with mixed item mapping strategies
  @RdfProperty(TestVocab.mixedTypeList,
      collection: rdfSeq, literal: LiteralMapping.withType(Xsd.string))
  final List<dynamic> mixedTypeList;

  MixedTypeTests({required this.mixedTypeList});
}

/// Provider context for IRI templates
@RdfLocalResource()
class ContextProviderTests {
  @RdfProvides('baseUri')
  final String serviceUrl = 'https://test.example.org';

  @RdfProperty(TestVocab.iriItemsList,
      collection: rdfBag,
      iri: IriMapping('{+baseUri}/item/{contextManagedItems}'))
  final List<String> contextManagedItems;

  ContextProviderTests({required this.contextManagedItems});
}
