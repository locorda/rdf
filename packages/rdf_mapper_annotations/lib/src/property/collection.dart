import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

/// Designates a property as the key in a mapped `Map<K,V>` collection.
///
/// This annotation must be used together with `@RdfMapEntry` when mapping to a Dart `Map`.
/// Within the item class specified by `@RdfMapEntry`, the property annotated with `@RdfMapKey`
/// will be used as the key in the resulting Map. Unlike `@RdfMapValue`, this annotation
/// must always be applied to a property, not a class.
///
/// This annotation is an essential part of the RDF Map mapping system, enabling
/// the mapper to correctly serialize and deserialize complex data structures like Maps.
/// Each map entry is serialized as a distinct resource in the RDF graph, with the annotated
/// property serving as the key. This establishes the necessary key-value relationships
/// between Dart Map types and their RDF graph representation.
///
/// Example:
/// ```dart
/// @RdfProperty(VocabTerm.vectorClock)
/// @RdfMapEntry(VectorClockEntry) // Item class with key and value annotations
/// late Map<String, int> vectorClock;
///
/// // The item class that defines the structure of map entries:
/// @RdfLocalResource(IriTerm('http://example.org/vocab/VectorClockEntry'))
/// class VectorClockEntry {
///   @RdfProperty(IriTerm('http://example.org/vocab/clientId'))
///   @RdfMapKey() // This property becomes the map key
///   final String clientId;
///
///   @RdfProperty(IriTerm('http://example.org/vocab/clockValue'))
///   @RdfMapValue() // This property becomes the map value
///   final int clockValue;
///
///   VectorClockEntry(this.clientId, this.clockValue);
/// }
/// ```
class RdfMapKey extends RdfAnnotation {
  const RdfMapKey();
}

/// Designates a property or class as the value in a mapped `Map<K,V>` collection.
///
/// This annotation works with `@RdfMapEntry` and `@RdfMapKey` to enable proper
/// serialization and deserialization of Map structures in RDF. During serialization,
/// each map entry is fully serialized as a separate resource in the RDF graph.
///
/// The RDF mapper needs to know both the key and value of each Map entry. Since RDF
/// has no native concept of key-value pairs, we need to explicitly mark which
/// properties or classes represent the key and value components in the RDF representation.
///
/// There are two valid ways to use the RDF Map annotations to model a Map&lt;K,V&gt;:
///
/// 1. Property-level annotations - one property as key, one property as value:
/// ```dart
/// @RdfLocalResource()
/// class CounterEntry {
///   @RdfProperty(ExampleVocab.key)
///   @RdfMapKey() // Marks this property as the key
///   final String key;
///
///   @RdfProperty(ExampleVocab.count)
///   @RdfMapValue() // Marks this property as the value
///   final int count;
///
///   CounterEntry(this.key, this.count);
/// }
///
/// @RdfLocalResource()
/// class Counters {
///   @RdfProperty(ExampleVocab.counters)
///   @RdfMapEntry(CounterEntry)
///   final Map<String, int> counts; // Keys and values are extracted from CounterEntry
///
///   Counters(this.counts);
/// }
/// ```
///
/// In this approach, both the key and value are individual properties that are
/// specifically marked. The Map's generic type parameters must match the types
/// of these properties (e.g., Map&lt;String, int&gt;). There must not be any
/// additional properties in the `CounterEntry` class except for computed/derived ones.
/// Key and Value properties must be sufficient for full serialization.
///
/// 2. Class-level annotation - entire entry class represents the value:
/// ```dart
/// // The class with @RdfMapValue at class level
/// @RdfMapValue() // Class-level annotation - the whole class represents a value
/// @RdfLocalResource()
/// class SettingsEntry {
///   // When @RdfMapValue is used at class level, @RdfMapKey can be on a derived property
///   // that doesn't need to be an RDF property itself. It is perfectly fine
///   // to use it on an @RdfProperty, though.
///   @RdfMapKey() // The key property - can be computed/derived
///   String get key => id; // This is a derived property used as a map key
///
///   // The actual RDF property that stores the identifier
///   @RdfProperty(ExampleVocab.settingId)
///   final String id;
///
///   // Multiple RDF properties can be part of the value
///   @RdfProperty(ExampleVocab.settingPriority)
///   final int priority;
///
///   @RdfProperty(ExampleVocab.settingEnabled)
///   final bool enabled;
///
///   @RdfProperty(ExampleVocab.settingDescription)
///   final String description;
///
///   // No @RdfMapValue needed on any property since the class itself
///   // is annotated with @RdfMapValue
///   SettingsEntry(this.id, this.priority, this.enabled, this.description);
/// }
///
/// // In your Resource class:
/// @RdfLocalResource()
/// class Settings {
///   @RdfProperty(ExampleVocab.settings)
///   @RdfMapEntry(SettingsEntry) // Using the class with class-level @RdfMapValue
///   Map<String, SettingsEntry> allSettings; // Key is String, value is the whole SettingsEntry
///
///   Settings(this.allSettings);
/// }
/// ```
///
/// This second approach is particularly useful when the value needs to be a complex object
/// with multiple properties. The entire object becomes the value in the Map, with one of its
/// properties designated as the key. When using class-level `@RdfMapValue`, the property marked
/// with `@RdfMapKey` can be a derived Dart property (getter) that doesn't necessarily map to
/// an RDF property itself.
///
/// You can have as many @RdfProperty properties in the class with this approach as you want, but all
/// other properties must be computed/derived properties that don't need serialization.
class RdfMapValue extends RdfAnnotation {
  const RdfMapValue();
}

/// Specifies the Dart [Type] that represents each entry in a Map.
///
/// This annotation is specifically designed for `Map` collection properties when a
/// custom structure is needed for key-value pairs in RDF. It's important to note that
/// there are multiple ways to handle Map collections in RDF:
///
/// 1. **Using standard mapping configurations without RdfMapEntry**:
///    Maps are treated as collections of MapEntry instances. If you provide
///    mapping configurations (iri, literal, globalResource, localResource)
///    in your @RdfProperty that work with MapEntry&lt;K,V&gt; and the correct generic
///    type parameters, no RdfMapEntry annotation is required.
///
///    Example with literal mapper for language-tagged strings:
///    ```dart
///    @RdfProperty(
///      IriTerm('http://example.org/book/title'),
///      literal: LiteralMapping.mapperInstance(const LocalizedEntryMapper())
///    )
///    final Map<String, String> translations; // Key=language code, Value=translated text
///
///    // The mapper handles conversion to/from language-tagged literals
///    class LocalizedEntryMapper implements LiteralTermMapper<MapEntry<String, String>> {
///      const LocalizedEntryMapper();
///
///      @override
///      MapEntry<String, String> fromRdfTerm(LiteralTerm term, DeserializationContext context) =>
///          MapEntry(term.language ?? 'en', term.value);
///
///      @override
///      LiteralTerm toRdfTerm(MapEntry<String, String> value, SerializationContext context) =>
///          LiteralTerm.withLanguage(value.value, value.key);
///    }
///    ```
///    This approach works when standard registered mappers or custom mapping
///    configurations can handle the MapEntry directly.
///
/// 2. **Using @RdfMapEntry with a dedicated entry class**:
///    This approach uses a separate class to represent each entry in the Map. Use this
///    approach when:
///    - Map keys and values require separate RDF predicates for complex structures
///    - Your map entries need to be represented as resources with multiple properties
///
///    When using @RdfMapEntry, each entry in the Map is fully serialized as a separate
///    resource in the RDF graph according to its own RDF mapping annotations.
///
///    IMPORTANT: All properties in the referenced resource class must either be:
///    - Annotated with `@RdfProperty` for serialization to RDF, or
///    - Computed/derived properties that don't need serialization
///
///    Without proper annotations, the full serialization/deserialization roundtrip will fail, as the mapper
///    won't know how to reconstitute the object from RDF data.
///
///    The referenced class structure depends on how you use the map value annotation:
///
/// 1. When using property-level `@RdfMapValue`, the class must have exactly two `@RdfProperty` annotated properties:
/// ```dart
/// // In your Resource class:
/// @RdfProperty(ExampleVocab.counts)
/// @RdfMapEntry(CounterEntry) // Each entry is a CounterEntry
/// final Map<String, int> counts; // Keys and values extracted from CounterEntry
///
/// // The item class with property-level @RdfMapValue.
/// // Note that we do not specify the rdf:type (classIri) in the @RdfLocalResource
/// // annotation here, as type actually is optional and not needed in this case:
/// @RdfLocalResource()
/// class CounterEntry {
///   @RdfProperty(IriTerm('http://example.org/vocab/key'))
///   @RdfMapKey() // This property becomes the map key
///   final String key;
///
///   @RdfProperty(IriTerm('http://example.org/vocab/count'))
///   @RdfMapValue() // This property becomes the map value
///   final int count;
///
///   // With property-level @RdfMapValue, no additional @RdfProperty properties are allowed
///   // You can have derived properties that don't need serialization:
///   bool get isHighValue => count > 1000;
///
///   CounterEntry(this.key, this.count);
/// }
/// ```
///
/// 2. When using class-level `@RdfMapValue`, the class can have multiple `@RdfProperty` annotated properties:
/// ```dart
/// // With class-level @RdfMapValue:
/// @RdfMapValue() // Class-level annotation
/// @RdfLocalResource(ExampleVocab.SettingsEntry)
/// class SettingsEntry {
///   @RdfProperty(ExampleVocab.settingKey)
///   @RdfMapKey() // The key property
///   final String key;
///
///   // Multiple RDF properties can be part of the value
///   @RdfProperty(ExampleVocab.settingPriority)
///   final int priority;
///
///   @RdfProperty(ExampleVocab.settingEnabled)
///   final bool enabled;
///
///   @RdfProperty(ExampleVocab.settingTimestamp)
///   final DateTime timestamp;
///
///   // Derived properties are also allowed
///   bool get isRecent => DateTime.now().difference(timestamp).inDays < 7;
///
///   SettingsEntry(this.key, this.priority, this.enabled, this.timestamp);
/// }
/// ```
class RdfMapEntry extends RdfAnnotation {
  /// The Dart [Type] that defines the structure for each entry in the Map.
  ///
  /// For Maps, this class should contain properties annotated with
  /// [RdfMapKey] and [RdfMapValue] to define the mapping structure.
  ///
  /// When serialized to RDF, each instance of this class becomes a separate resource
  /// in the RDF graph, with all of its RDF-annotated properties properly serialized.
  final Type itemClass;

  /// Creates a new RdfMapEntry annotation with the specified item class.
  ///
  /// The [itemClass] parameter defines the type used for mapping Map entries.
  const RdfMapEntry(this.itemClass);
}

/// Configures mapping details for collection properties in RDF.
///
/// This class is used within the `@RdfProperty` annotation to customize how collections
/// (List, Set, Iterable, Map) as well as further custom collection or container classes are serialized in RDF.
/// Collection mapping controls the
/// overall structure and behavior of how collection data is represented in the RDF graph.
///
/// ## Default Collection Behavior
///
/// Unlike other mapping properties (iri, literal, globalResource, localResource) which
/// default to registry lookup when not specified, collections have different default behavior:
///
/// When no `collection` parameter is specified on collection properties:
/// - `List<T>` defaults to `CollectionMapping.auto()` (uses `UnorderedItemsListMapper`)
/// - `Set<T>` defaults to `CollectionMapping.auto()` (uses `UnorderedItemsSetMapper`)
/// - `Iterable<T>` defaults to `CollectionMapping.auto()` (uses `UnorderedItemsMapper`)
/// - `Map<K,V>` defaults to `CollectionMapping.auto()` (uses entry-based mapping with `@RdfMapEntry`)
/// - Each item generates a separate triple with the same predicate
/// - Order is not preserved in RDF representation
/// - NOT serialized as structured RDF Collections (rdf:List, rdf:Seq, etc.)
///
/// To use registry-based mapper lookup (matching other mapping properties), explicitly
/// specify `collection: CollectionMapping.fromRegistry()`.
///
/// ## Collection vs Item Mapping
///
/// It's important to understand the distinction:
/// - **Collection mapping** (this class): Controls how the collection structure itself is serialized
/// - **Item mapping** (iri, literal, globalResource, localResource): Controls how individual items are serialized
///
/// These work together - the collection mapper handles the overall RDF structure,
/// while item mappers handle the conversion of individual elements.
///
/// ## Well-Known Collection Mappers
///
/// For common RDF collection structures, use the predefined global constants instead
/// of the verbose `CollectionMapping.withItemMappers()` syntax:
///
/// **Recommended (using global constants):**
/// ```dart
/// @RdfProperty(SchemaBook.chapters, collection: rdfList)
/// @RdfProperty(SchemaBook.authors, collection: rdfSeq)
/// @RdfProperty(SchemaBook.topics, collection: rdfBag)
/// @RdfProperty(SchemaBook.formats, collection: rdfAlt)
/// ```
///
/// **Not recommended (verbose syntax), but equivalent:**
/// ```dart
/// @RdfProperty(SchemaBook.chapters, collection: CollectionMapping.withItemMappers(RdfListMapper))
/// @RdfProperty(SchemaBook.authors, collection: CollectionMapping.withItemMappers(RdfSeqMapper))
/// ```
///
/// Available global constants:
/// - `rdfList` - Ordered RDF List structure (rdf:first/rdf:rest/rdf:nil)
/// - `rdfSeq` - RDF Sequence structure for numbered sequences
/// - `rdfBag` - RDF Bag structure for unordered collections
/// - `rdfAlt` - RDF Alternative structure for alternative values
/// - `unorderedItems` - Multiple triples (same as default auto behavior)
/// - `unorderedItemsList` - Multiple triples for `List<T>` specifically
/// - `unorderedItemsSet` - Multiple triples for `Set<T>` specifically
///
/// ## Examples
///
/// ```dart
/// class Book {
///   // Default: Multiple triples, one per chapter
///   @RdfProperty(SchemaBook.chapters)
///   final List<Chapter> chapters;
///
///   // Structured RDF List (preserves order)
///   @RdfProperty(SchemaBook.orderedChapters, collection: rdfList)
///   final List<Chapter> orderedChapters;
///
///   // RDF Sequence structure
///   @RdfProperty(SchemaBook.authorSequence, collection: rdfSeq)
///   final List<Person> authorSequence;
///
///   // Default collection with custom item mapping
///   @RdfProperty(
///     SchemaBook.contributorIds,
///     iri: IriMapping('{+baseUri}/person/{contributorId}')
///   )
///   final List<String> contributorIds; // Each ID → IRI, separate triples
///
///   // Custom collection mapper
///   @RdfProperty(
///     SchemaBook.keywords,
///     collection: CollectionMapping.mapper(StringListMapper)
///   )
///   final List<String> keywords; // Entire list handled as single value
/// }
/// ```
class CollectionMapping extends BaseMapping<Mapper> {
  final bool isAuto;
  final Type? factory;

  /// Creates automatic collection mapping behavior.
  ///
  /// This is the default for collection properties when no explicit collection mapping
  /// is specified. Uses appropriate unordered mappers based on collection type:
  /// - `List<T>` → `UnorderedItemsListMapper`
  /// - `Set<T>` → `UnorderedItemsSetMapper`
  /// - `Iterable<T>` → `UnorderedItemsMapper`
  /// - `Map<K,V>` → Entry-based mapping with `@RdfMapEntry`
  ///
  /// Results in multiple triples with the same predicate, one per collection item.
  const CollectionMapping.auto()
      : isAuto = true,
        factory = null;

  /// Creates registry-based collection mapping.
  ///
  /// Uses the mapper registry to look up a collection mapper for the property type,
  /// similar to how other mapping properties (iri, literal, globalResource, localResource)
  /// behave by default. Only use this when you have registered a specific collection
  /// mapper for your collection type.
  const CollectionMapping.fromRegistry()
      : isAuto = false,
        factory = null;

  /// Creates a reference to a named collection mapper that will be injected at runtime.
  ///
  /// Use this constructor when you want to provide your own custom collection mapper
  /// implementation. The mapper you provide will determine how the collection is
  /// serialized to and deserialized from RDF. When using this approach, you must:
  /// 1. Implement a collection mapper (e.g., `Mapper<List<T>>`)
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The `name` will correspond to a parameter in the generated `initRdfMapper` function.
  /// The mapper will only be used for the specific property annotated with this mapping.
  ///
  /// Example:
  /// ```dart
  /// class Playlist {
  ///   @RdfProperty(
  ///     PlaylistVocab.tracks,
  ///     collection: CollectionMapping.namedMapper('orderedTrackMapper')
  ///   )
  ///   final List<Track> tracks;
  /// }
  ///
  /// // You must implement the collection mapper:
  /// class OrderedTrackMapper implements UnifiedResourceMapper<List<Track>> {
  ///   final Serializer<Track> trackSerializer;
  ///   final Deserializer<Track> trackDeserializer;
  ///
  ///   OrderedTrackMapper({
  ///     required this.trackSerializer,
  ///     required this.trackDeserializer,
  ///   });
  ///
  ///   // Implementation details...
  /// }
  ///
  /// // In initialization code:
  /// final trackMapper = OrderedTrackMapper(/* params */);
  /// final rdfMapper = initRdfMapper(orderedTrackMapper: trackMapper);
  /// ```
  const CollectionMapping.namedMapper(String name)
      : isAuto = false,
        factory = null,
        super.namedMapper(name);

  /// Creates a reference to a collection mapper that will be instantiated from the given type.
  ///
  /// Use this constructor when you want to provide your own custom collection mapper
  /// implementation that can be instantiated automatically and needs access to item-level
  /// serializers/deserializers. The mapper you provide will determine how the collection
  /// is serialized to and deserialized from RDF.
  ///
  /// The generator will create an instance of `mapperType` to handle collection mapping.
  /// The type must implement `Mapper<C>` where C is the collection type (e.g., `List<T>`)
  /// and must have a constructor that accepts optional `itemSerializer` and `itemDeserializer`
  /// parameters: `Mapper<C> Function({Serializer<T>? itemSerializer, Deserializer<T>? itemDeserializer})`
  ///
  /// **Use this constructor when**: Your collection mapper needs to delegate item serialization
  /// to the generated or overridden item mappers (e.g., for complex objects, resources, or custom item mapping).
  ///
  /// **Use `CollectionMapping.mapper()` instead when**: Your collection mapper handles the entire
  /// collection serialization internally without needing item-level delegation.
  ///
  /// Example:
  /// ```dart
  /// class Book {
  ///   // Using a custom collection mapper that needs item serializers for complex objects
  ///   @RdfProperty(
  ///     SchemaBook.chapters,
  ///     collection: CollectionMapping.withItemMappers(OrderedChapterListMapper)
  ///   )
  ///   final List<Chapter> chapters;
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class OrderedChapterListMapper implements UnifiedResourceMapper<List<Chapter>> {
  ///   final Serializer<Chapter> itemSerializer;
  ///   final Deserializer<Chapter> itemDeserializer;
  ///
  ///   OrderedChapterListMapper({
  ///     Serializer<Chapter>? itemSerializer,
  ///     Deserializer<Chapter>? itemDeserializer,
  ///   }) : itemSerializer = itemSerializer ?? throw ArgumentError('itemSerializer required'),
  ///        itemDeserializer = itemDeserializer ?? throw ArgumentError('itemDeserializer required');
  ///
  ///   // Implementation details...
  /// }
  /// ```
  const CollectionMapping.withItemMappers(Type mapperType)
      : isAuto = false,
        factory = mapperType;

  /// Creates a reference to a collection mapper that will be instantiated from the given type.
  ///
  /// Use this constructor when you want to provide your own custom collection mapper
  /// implementation that handles the entire collection serialization internally without
  /// needing access to item-level serializers/deserializers.
  ///
  /// The generator will create an instance of `mapperType` to handle collection mapping.
  /// The type must implement `Mapper<C>` where C is the collection type (e.g., `List<T>`)
  /// and must have a no-argument default constructor.
  ///
  /// **Use this constructor when**: Your collection mapper handles the entire collection
  /// serialization internally (e.g., serializing a `List<String>` as a single JSON array
  /// literal, or using a custom RDF structure that doesn't require item delegation).
  ///
  /// **Use `CollectionMapping.withItemMappers()` instead when**: Your collection mapper
  /// needs to delegate individual item serialization to the generated item mappers.
  ///
  /// Example:
  /// ```dart
  /// class Book {
  ///   // Using a collection mapper that handles entire list as single literal
  ///   @RdfProperty(
  ///     SchemaBook.keywords,
  ///     collection: CollectionMapping.mapper(StringListMapper)
  ///   )
  ///   final List<String> keywords; // Serialized as single JSON array literal
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class StringListMapper implements LiteralTermMapper<List<String>> {
  ///   StringListMapper(); // No-argument constructor required
  ///
  ///   @override
  ///   List<String> fromRdfTerm(LiteralTerm term, DeserializationContext context) {
  ///     // Parse JSON array from literal value
  ///     return (jsonDecode(term.value) as List).cast<String>();
  ///   }
  ///
  ///   @override
  ///   LiteralTerm toRdfTerm(List<String> value, SerializationContext context) {
  ///     // Serialize entire list as JSON array literal
  ///     return LiteralTerm(jsonEncode(value));
  ///   }
  /// }
  /// ```
  const CollectionMapping.mapper(Type mapperType)
      : isAuto = false,
        factory = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided collection mapper instance.
  ///
  /// This allows you to supply a pre-existing instance of a collection mapper.
  /// Useful when your mapper requires constructor parameters or complex setup
  /// that cannot be handled by simple instantiation.
  ///
  /// The mapper will only be used for the specific property annotated with this mapping.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured collection mapper with const constructor -
  /// // note that the mapper instance must be a compile-time constant and that
  /// // it must be a Mapper<List<Track>> in our example here due to the field type:
  /// const orderedTrackListMapper = CustomOrderedTrackListMapper(
  ///   preserveOrder: true,
  ///   validateUniqueness: false,
  /// );
  ///
  /// class Playlist {
  ///   @RdfProperty(
  ///     PlaylistVocab.tracks,
  ///     collection: CollectionMapping.mapperInstance(orderedTrackListMapper)
  ///   )
  ///   final List<Track> tracks;
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const CollectionMapping.mapperInstance(Mapper instance)
      : isAuto = false,
        factory = null,
        super.mapperInstance(instance);
}
