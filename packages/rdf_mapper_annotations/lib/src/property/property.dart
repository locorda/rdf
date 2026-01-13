import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';
import 'package:rdf_mapper_annotations/src/property/collection.dart';
import 'package:rdf_mapper_annotations/src/property/contextual_mapping.dart';
import 'package:rdf_mapper_annotations/src/resource/global_resource.dart';
import 'package:rdf_mapper_annotations/src/resource/local_resource.dart';
import 'package:rdf_mapper_annotations/src/term/iri.dart';
import 'package:rdf_mapper_annotations/src/term/literal.dart';

/// Maps a Dart class property to an RDF predicate.
///
/// This core annotation defines how properties are serialized to RDF and
/// deserialized to Dart objects. Any property that should participate in
/// RDF serialization must use `@RdfProperty` with a predicate IRI that identifies
/// the relationship in the RDF graph.
///
/// NOTE: Only public properties are supported. Private properties (with underscore prefix)
/// cannot be used with RDF mapping.
///
/// The annotation can be applied to:
/// - **Instance fields**: Compatible with all type-annotated fields (mutable, `final`, and `late`)
/// - **Getters and setters**: Follow these rules:
///   - With `include: true` (default): Requires both getter and setter for full serialization/deserialization
///   - With `include: false` (read-only from RDF): Requires only a setter as the value is only deserialized
///
/// `RdfProperty` handles data conversion in these ways:
///
/// - **Automatic type mapping**:
///   - Standard Dart types (String, int, bool, DateTime, etc.) → RDF literals
///   - Types with annotations (`@RdfIri`, `@RdfLiteral`, `@RdfGlobalResource`, `@RdfLocalResource`)
///     → use their generated mappers
///   - Types with registered mappers → handled according to their registration
///
/// - **Custom mapping overrides**: For specialized cases, specify exactly one of:
///   - `iri`: Converts values to IRI references
///   - `localResource`: Maps nested objects without assigned IRIs (using anonymous identifiers)
///   - `globalResource`: Maps nested objects as resources with their own IRIs
///   - `literal`: Applies custom literal serialization
///
/// - **Default value handling**:
///   - Provides fallbacks when properties are missing during deserialization
///   - Optional compact serialization by excluding properties matching defaults
///   - Enables non-nullable fields to work with potentially missing data
///
/// - **Collection handling**: Lists, Sets and Maps receive flexible treatment:
///   - **Default behavior**: Each item generates a separate triple with the same predicate
///   - **Custom collection mappers**: Use `collection` parameter for structured RDF collections (rdf:List, rdf:Seq, etc.)
///   - **Item mapping**: Apply `iri`, `literal`, `globalResource`, or `localResource` to individual items
///   - **Map collections**: Use [RdfMapEntry], [RdfMapKey], and [RdfMapValue] for key-value pairs
///
///
/// ## Basic Usage
///
/// ```dart
/// // Basic literal properties with default serialization
/// @RdfProperty(SchemaBook.name)
/// final String title;
///
/// // Optional property (nullable type makes it not required during deserialization)
/// @RdfProperty(
///   SchemaBook.author,
///   iri: IriMapping('http://example.org/author/{authorId}')
/// )
/// String? authorId;
///
/// // Property that will be read from RDF but not written back during serialization
/// @RdfProperty(SchemaBook.modified, include: false)
/// DateTime lastModified;
///
/// // A setter that updates the lastModified field internally
/// set updateLastModified(DateTime value) {
///   lastModified = value;
/// }
///
/// // A completely separate property without RDF mapping - no annotation needed
/// bool get isRecentlyModified =>
///   DateTime.now().difference(lastModified).inDays < 7;
///
/// // Non-nullable property with default value (won't cause error if missing)
/// @RdfProperty(SchemaBook.status, defaultValue: 'active')
/// final String status;
///
/// // Property with default that will be included in serialization even if equal to default
/// @RdfProperty(
///   SchemaBook.rating,
///   defaultValue: 0,
///   includeDefaultsInSerialization: true
/// )
/// final int rating;
/// ```
///
/// ## Advanced Mapping Scenarios
///
/// These examples demonstrate how to override the default mapping behavior when needed.
///
/// ### IRI Mapping
/// ```dart
/// // Override: String property value converted to an IRI using a template
/// @RdfProperty(
///   Dcterms.creator,
///   iri: IriMapping('{+baseUri}/profile/{userId}')
/// )
/// final String userId;
/// ```
///
/// In the example above:
/// - `{userId}` is a property-specific placeholder that refers directly to the property's value
/// - `{+baseUri}` is a context variable that must be provided through one of three methods:
///   1. Via a global provider function in `initRdfMapper` (e.g., `baseUriProvider: () => 'https://example.com'`)
///      The generator will automatically add a required parameter to `initRdfMapper`.
///   2. Via another property in the same class annotated with `@RdfProvides('baseUri')`
///      This is preferred for context variables that are already available in the class.
///   3. Via the parent resource's IRI, when the parent's `IriStrategy` specifies `providedAs` parameter
///      This is useful for hierarchical structures where children need the parent's IRI.
/// - The `+` prefix (e.g., `{+baseUri}`) indicates variables that may contain URI-reserved
///   characters like slashes, which should not be percent-encoded when substituted
///
/// For instance, if `userId` contains "jsmith", and `baseUri` resolves to "https://example.com",
/// this will generate an IRI: "https://example.com/profile/jsmith"
///
/// ### Local Resource (Anonymous Resource) Mapping
/// ```dart
/// // Automatic: Person class is already annotated with @RdfLocalResource or implemented and registered manually
/// @RdfProperty(SchemaBook.author)
/// final Person author;
///
/// // Override: Use custom mapper for this specific relationship
/// @RdfProperty(
///   SchemaBook.publisher,
///   localResource: LocalResourceMapping.namedMapper('customPublisherMapper')
/// )
/// final Publisher publisher;
/// ```
///
/// ### Global Resource Mapping
/// ```dart
/// // Automatic: Organization class is already annotated with @RdfGlobalResource or implemented and registered manually
/// @RdfProperty(SchemaBook.publisher)
/// final Organization publisher;
///
/// // Override: Use custom mapper for this specific relationship
/// @RdfProperty(
///   SchemaBook.publisher,
///   globalResource: GlobalResourceMapping.namedMapper('specialPublisherMapper')
/// )
/// final Publisher publisher;
/// ```
///
/// ### Custom Literal Serialization
/// ```dart
/// // Override: Use custom serialization for a property with special formatting needs
/// @RdfProperty(
///   SchemaBook.price,
///   literal: LiteralMapping.namedMapper('priceMapper')
/// )
/// final Price price;
/// ```
///
/// ### Contextual Property Mapping
/// ```dart
/// // Properties that need access to parent object/subject during mapping
/// class Document<T> {
///   @RdfProperty(FoafDocument.primaryTopic)
///   final String documentIri;
///
///   // Property mapped with access to parent context
///   @RdfProperty(
///     FoafDocument.primaryTopic,
///     contextual: ContextualMapping.namedProvider("primaryTopic")
///   )
///   final T primaryTopic;
/// }
///
/// // Mapper instantiation with SerializationProvider
/// final mapper = DocumentMapper<Person>(
///   primaryTopic: SerializationProvider.iriContextual((IriTerm iri) =>
///       PersonMapper(documentIriProvider: () => iri.iri)),
/// );
/// ```
///
/// ### Collection Handling
/// ```dart
/// // Default behavior: Automatically uses UnorderedItemsMapper for standard collections
/// @RdfProperty(SchemaBook.authors)
/// final List<Person> authors; // Each Person is fully mapped with its own set of triples
///
/// // Using structured RDF collections (preserves order)
/// @RdfProperty(SchemaBook.chapters, collection: rdfList)
/// final List<Chapter> chapters; // Creates rdf:List structure
///
/// // Custom collection with explicit item type
/// @RdfProperty(
///   SchemaBook.metadata,
///   collection: CollectionMapping.withItemMappers(CustomCollectionMapper),
///   itemType: MetadataEntry
/// )
/// final CustomCollection metadata;
///
/// // Structured RDF collections (different types)
/// @RdfProperty(SchemaBook.authors, collection: rdfSeq)
/// final List<Person> authors; // Creates rdf:Seq structure
///
/// @RdfProperty(SchemaBook.genres, collection: rdfBag)
/// final List<String> genres; // Creates rdf:Bag structure
/// ```
class RdfProperty implements RdfAnnotation {
  /// The RDF predicate (IRI) for this property, e.g., `SchemaBook.name`.
  final IriTerm predicate;

  /// Whether to include this property during serialization to RDF.
  ///
  /// If `false`, the property will be read during deserialization but skipped when generating RDF output.
  /// This creates a one-way mapping (read-only from RDF perspective). This is useful for properties that
  /// should be loaded from RDF but then managed internally by your application logic without writing changes
  /// back to RDF. Defaults to `true`.
  final bool include;

  /// Optional default value for this property.
  ///
  /// When provided for non-nullable properties, this value will be used if the property
  /// is missing in the RDF data during deserialization, avoiding errors.
  ///
  /// During serialization, properties with values equal to their default may be omitted
  /// (controlled by [includeDefaultsInSerialization]).
  ///
  /// Note: Due to Dart's annotation constraints, only constant values can be used. This
  /// works well for primitive types and objects with const constructors.
  final dynamic defaultValue;

  /// Whether to include properties with default values during serialization.
  ///
  /// When `true`, properties with values equal to their default will still be
  /// included in the RDF output.
  ///
  /// When `false` (default), properties with values equal to their default will be
  /// omitted from serialization, resulting in a more compact RDF representation.
  final bool includeDefaultsInSerialization;

  /// Specifies how to treat the property's value as an IRI reference.
  ///
  /// Use this when the property's value represents an IRI (e.g., a URL) or when
  /// you need to override the default literal mapping for a type.
  ///
  /// Only needed when there is no IriMapper already registered globally for the
  /// property value's type, or when you need to override the standard mapping behavior
  /// for this specific property.
  ///
  /// This parameter customizes how property values are converted to IRIs, enabling:
  /// - IRI templates with placeholders (e.g., converting a username to a complete URI)
  /// - Custom mappers for specialized IRI conversion
  /// - Context-dependent IRI construction strategies
  ///
  /// Available IriMapping constructor variants:
  /// - Template constructor: `iri: IriMapping('{+baseUri}/profile/{propertyName}')`
  /// - `.namedMapper()` - references a mapper provided to `initRdfMapper`
  /// - `.mapper()` - uses a mapper type that will be instantiated
  /// - `.mapperInstance()` - uses a specific mapper instance
  ///
  /// Template placeholders are resolved in two ways:
  /// 1. Property placeholders (e.g., `{userId}`) use the property's value directly
  /// 2. Context variables (e.g., `{+baseUri}`) are provided through:
  ///    - Global provider functions in `initRdfMapper` (e.g., `baseUriProvider: () => 'https://example.com'`)
  ///    - Properties in the same class annotated with `@RdfProvides('baseUri')`
  ///    - The parent resource's IRI, when the parent's `IriStrategy` specifies `providedAs` parameter
  ///    - The `+` prefix (e.g., `{+baseUri}`) indicates variables that may contain URI-reserved
  ///      characters like slashes, which should not be percent-encoded when substituted
  ///
  /// Example:
  /// ```dart
  /// // Context variable provided by another property
  /// @RdfProvides('baseUri')
  /// final String serviceUrl = 'https://example.com';
  ///
  /// // Using an IRI template for a property
  /// @RdfProperty(
  ///   Dcterms.creator,
  ///   iri: IriMapping('{+baseUri}/profile/{userId}')
  /// )
  /// final String userId; // Converts to "https://example.com/profile/jsmith" if userId="jsmith"
  /// ```
  final IriMapping? iri;

  /// Specifies how to treat the property's value as a nested anonymous resource.
  ///
  /// Use this when the property represents a nested object that shouldn't have its own
  /// persistent identifier (IRI). The object will be serialized as a set of triples
  /// with an anonymous identifier (internally implemented as an RDF blank node).
  ///
  /// Only needed when there is no LocalResourceMapper already registered globally for the
  /// property value's type, or when you need to override the standard mapping behavior for
  /// this specific relationship.
  final LocalResourceMapping? localResource;

  /// Specifies custom literal conversion for the property value.
  ///
  /// Use this parameter when a property requires specialized literal serialization
  /// different from the standard mapping behavior, such as custom formatting,
  /// language tags, or datatype handling.
  ///
  /// Only needed when there is no LiteralMapper already registered globally for the
  /// property value's type, or when you need to override the standard literal conversion
  /// for this specific property.
  ///
  /// This provides property-specific literal conversion rules, useful when:
  /// - Different serialization rules are needed for the same type in different contexts
  /// - A property requires special datatype handling or language tags
  /// - You need specialized formatting for a specific property
  ///
  /// Available LiteralMapping constructor variants:
  /// - `.namedMapper()` - reference a mapper provided to `initRdfMapper`
  /// - `.mapper()` - use a mapper type that will be instantiated
  /// - `.mapperInstance()` - use a specific mapper instance
  /// - `.withLanguage()` - add a language tag to string literals (e.g., "text"@en)
  /// - `.withType()` - specify a custom RDF datatype for the literal
  ///
  /// Examples:
  /// ```dart
  /// // Using a custom literal mapper for a property
  /// @RdfProperty(
  ///   SchemaBook.price,
  ///   literal: LiteralMapping.namedMapper('currencyMapper')
  /// )
  /// final Price price; // Serialized using the custom 'currencyMapper'
  ///
  /// // Adding a language tag to a string property
  /// @RdfProperty(
  ///   SchemaBook.description,
  ///   literal: LiteralMapping.withLanguage('en')
  /// )
  /// final String description; // Serialized as "description"@en
  ///
  /// // Specifying a custom datatype
  /// @RdfProperty(
  ///   SchemaBook.publicationDate,
  ///   literal: LiteralMapping.withType(Xsd.date)
  /// )
  /// final String date; // Serialized with a specific datatype
  /// ```
  final LiteralMapping? literal;

  /// Specifies how to treat the property's value as an RDF resource with its own IRI.
  ///
  /// Use this when the property represents a nested resource that should have its own
  /// globally unique IRI, or to override default mapping behavior for this relationship.
  ///
  /// Only needed when there is no GlobalResourceMapper already registered globally for the
  /// property value's type, or when you need a specific mapper for this relationship that
  /// differs from the standard global resource mapping.
  ///
  /// This parameter can override globally registered mappers for the same type,
  /// allowing relationship-specific mapping while maintaining standard mapping elsewhere:
  ///
  /// ```dart
  /// class Book {
  ///   // Uses custom mapper for this specific relationship
  ///   @RdfProperty(
  ///     SchemaBook.publisher,
  ///     globalResource: GlobalResourceMapping.namedMapper('customPublisherMapper')
  ///   )
  ///   final Publisher publisher;
  ///
  ///   // Uses the globally registered mapper for Publisher
  ///   @RdfProperty(SchemaBook.recommendedBy)
  ///   final Publisher recommendedBy;
  /// }
  /// ```
  ///
  /// Available GlobalResourceMapping constructor variants:
  /// - `.namedMapper()` - references a mapper provided to `initRdfMapper`
  /// - `.mapper()` - uses a mapper type that will be instantiated
  /// - `.mapperInstance()` - uses a specific mapper instance
  final GlobalResourceMapping? globalResource;

  /// Specifies a custom collection mapper for handling collection properties.
  ///
  /// This parameter references a Type that implements `Mapper<C>` and has a constructor
  /// with the signature `Mapper<C> Function({Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})`, where:
  /// - `C` is the collection type (e.g., `List<Person>`)
  /// - `T` is the item type (e.g., `Person`)
  /// - The class implements `Mapper<C>` to handle collection serialization/deserialization
  /// - The constructor takes optional item serializer and item deserializer parameters
  ///
  /// The collection mapper handles the overall RDF structure of the collection, while
  /// the item mapper (derived from iri/literal/globalResource/localResource parameters)
  /// is passed as item serializer and item deserializer to the collection mapper and
  /// handles individual item conversion.
  ///
  /// **Default behavior without explicit collection mapper**:
  /// Unlike other mapping properties (iri, literal, globalResource, localResource)
  /// which default to registry lookup when not specified, collections have a different
  /// default behavior:
  /// - `List<T>` automatically uses `UnorderedItemsListMapper` (equivalent to `CollectionMapping.auto()`)
  /// - `Set<T>` automatically uses `UnorderedItemsSetMapper` (equivalent to `CollectionMapping.auto()`)
  /// - `Iterable<T>` automatically uses `UnorderedItemsMapper` (equivalent to `CollectionMapping.auto()`)
  /// - Each item generates a separate triple with the same predicate
  /// - Not serialized as RDF Collection structures (rdf:first/rdf:rest/rdf:nil)
  /// - List order is not preserved in RDF representation
  /// - Map collections continue using existing [RdfMapEntry]/[RdfMapKey]/[RdfMapValue] annotations
  ///
  /// To use registry-based mapper lookup (matching the default behavior of other mapping
  /// properties), explicitly specify `collection: CollectionMapping.fromRegistry()`
  ///
  /// **When to specify a collection mapper**:
  /// 1. **Custom collection types**: When using non-standard collection types
  /// 2. **Structured RDF collections**: When you need rdf:List, rdf:Seq, or other RDF collection structures
  /// 3. **Custom serialization**: When you need specialized collection handling
  ///
  /// The item type (`T`) is determined using this fallback strategy:
  /// 1. If [itemType] is explicitly specified, use it
  /// 2. Try to extract from generic parameters of the field type (e.g., `List<Person>` → `Person`)
  /// 3. Fall back to `Object` as last resort
  ///
  /// ## Examples
  ///
  /// ### Default Multi-Triple Collections
  /// ```dart
  /// // Uses UnorderedItemsListMapper automatically (default) - creates one triple per Person
  /// @RdfProperty(SchemaBook.authors)
  /// final List<Person> authors;
  ///
  /// // Uses UnorderedItemsSetMapper automatically (default) - creates one triple per Person
  /// @RdfProperty(SchemaBook.contributors)
  /// final Set<Person> contributors;
  ///
  /// // Same with custom item mapping - one triple per ID
  /// @RdfProperty(
  ///   SchemaBook.contributorIds,
  ///   iri: IriMapping('{+baseUri}/person/{contributorId}')
  /// )
  /// final List<String> contributorIds; // Each ID converted to IRI, separate triples
  /// ```
  ///
  /// ### Structured RDF Collections
  /// ```dart
  /// // Creates an rdf:List structure preserving order - single collection object
  /// @RdfProperty(SchemaBook.chapters, collection: rdfList)
  /// final List<Chapter> chapters;
  ///
  /// // rdf:List with custom item mapping - single ordered collection
  /// @RdfProperty(
  ///   SchemaBook.authorIds,
  ///   collection: rdfList,
  ///   iri: IriMapping('{+baseUri}/person/{authorId}')
  /// )
  /// final List<String> authorIds; // Ordered rdf:List of IRIs
  /// ```
  ///
  /// ### Custom Collection Types
  /// ```dart
  /// // For non-standard collection types, explicit mapper needed
  /// @RdfProperty(
  ///   SchemaBook.metadata,
  ///   collection: (CustomCollectionMapper),
  ///   itemType: MetadataEntry,  // Explicit when type can't be inferred
  ///   globalResource: GlobalResourceMapping.namedMapper('metadataEntryMapper')
  ///   // => We will require a GlobalResourceMapper<MetadataEntry> with the name 'metadataEntryMapper' in the generated initRdfMapper function and pass it as `itemMapper` to `CustomCollectionMapper(itemMapper)`.
  /// )
  /// final CustomCollection metadata;
  /// ```
  ///
  /// ### Single-Value Treatment
  /// ```dart
  /// // For treating collections as single values, use a custom mapper
  /// // that handles the entire collection as one unit
  /// @RdfProperty(
  ///   SchemaBook.keywords,
  ///   collection: CollectionMapping.mapper(StringListMapper)
  /// )
  /// final List<String> keywords; // Uses a custom literal mapper that serializes entire list
  ///
  /// // Alternative RDF collection structures
  /// @RdfProperty(SchemaBook.alternativeFormats, collection: rdfAlt)
  /// final List<String> formats; // Creates rdf:Alt structure
  ///
  /// @RdfProperty(SchemaBook.relatedTopics, collection: rdfBag)
  /// final List<String> topics; // Creates rdf:Bag structure
  /// ```
  ///
  /// **Well-known collection mappers**:
  ///
  /// *Default mappers (automatically applied - create multiple triples)*:
  /// - `UnorderedItemsListMapper`: Default for `List<T>` - creates separate triple per item
  /// - `UnorderedItemsSetMapper`: Default for `Set<T>` - creates separate triple per item
  /// - `UnorderedItemsMapper`: Default for `Iterable<T>` - creates separate triple per item
  ///
  /// *Structured RDF collection mappers (create single collection object)*:
  /// - `RdfListMapper`: Creates ordered rdf:List structure (rdf:first/rdf:rest/rdf:nil)
  /// - `RdfSeqMapper`: Creates rdf:Seq structure for ordered sequences
  /// - `RdfBagMapper`: Creates rdf:Bag structure for unordered collections
  /// - `RdfAltMapper`: Creates rdf:Alt structure for alternative values
  ///
  /// *Custom mappers*:
  /// - Implement `Mapper<C>` with constructor matching `Mapper<C> Function({Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})` signature
  ///
  final CollectionMapping? collection;

  /// Explicitly specifies the item type for collection mapping.
  ///
  /// This parameter is used as a fallback when the item type cannot be automatically
  /// extracted from the field's generic type parameters. It's particularly useful
  /// for custom collection types that don't follow standard generic patterns.
  ///
  /// The item type determines what `T` will be when instantiating the collection mapper
  /// with the constructor function `Mapper<C> Function({Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})`.
  ///
  /// **When to use**:
  /// - Custom collection types without clear generic parameters
  /// - Complex nested generics where extraction might fail
  /// - Explicit control over item type resolution
  ///
  /// **Not needed when**:
  /// - Using standard collections like `List<Person>`, `Set<String>` (type extracted automatically)
  /// - Type can be clearly inferred from field declaration
  /// - No item mapper is needed (e.g. no iri/literal/globalResource/localResource mapping defined explicitly for items)
  ///
  /// Example:
  /// ```dart
  /// @RdfProperty(
  ///   SchemaBook.customData,
  ///   collection: (CustomCollectionMapper),
  ///   itemType: DataEntry,  // Explicit because CustomCollection doesn't expose item type
  ///   localResource: LocalResourceMapping.namedMapper('dataEntryMapper')
  /// )
  /// final CustomCollection customData;
  /// ```
  final Type? itemType;

  /// Optional contextual mapping configuration.
  ///
  /// When provided, the generated mapper will require a SerializationProvider
  /// that has access to the parent object, parent subject, and full context during RDF operations.
  ///
  /// This enables complex mapping scenarios where the property's serialization
  /// or deserialization depends on:
  /// - The parent object's state and other properties
  /// - The parent resource's IRI (for global resources) or blank node (for local resources)
  /// - The full serialization/deserialization context
  ///
  /// **Usage**:
  /// ```dart
  /// class Document<T> {
  ///   @RdfProperty(FoafDocument.primaryTopic)
  ///   final String documentIri;
  ///
  ///   @RdfProperty(
  ///     FoafDocument.primaryTopic,
  ///     contextual: ContextualMapping.namedProvider("primaryTopic")
  ///   )
  ///   final T primaryTopic;
  /// }
  /// ```
  ///
  /// **Generated Code**:
  /// The mapper constructor will require a SerializationProvider:
  /// ```dart
  /// DocumentMapper<T>({
  ///   required SerializationProvider<Document<T>, T> primaryTopic,
  /// });
  /// ```
  ///
  /// **Consumer Implementation**:
  /// ```dart
  /// final mapper = DocumentMapper<Person>(
  ///   primaryTopic: SerializationProvider.iriContextual((IriTerm iri) =>
  ///       PersonMapper(documentIriProvider: () => iri.iri)),
  /// );
  /// ```
  ///
  /// The SerializationProvider encapsulates both serializer and deserializer creation
  /// based on the parent context, providing a more cohesive API.
  ///
  /// **Compatibility**: Cannot be used together with iri/literal/globalResource/localResource
  /// parameters as contextual mapping provides its own serialization strategy.
  final ContextualMapping? contextual;

  /// Creates an RDF property mapping annotation.
  ///
  /// [predicate] - The RDF predicate IRI that identifies this property in the graph,
  /// typically from a vocabulary constant (e.g., `SchemaBook.name`, `Dcterms.creator`).
  ///
  /// [include] - Controls serialization behavior. When false, creates a one-way mapping
  /// where the property is read from RDF during deserialization but not written back
  /// during serialization. Useful for properties managed internally after loading.
  ///
  /// [defaultValue] - Fallback value for properties missing during deserialization.
  /// Critical for non-nullable properties. Without a default, non-nullable properties
  /// will throw an error if missing from RDF data.
  ///
  /// [includeDefaultsInSerialization] - When true, includes properties even if they
  /// match their default value. When false (default), omits them for more compact RDF.
  ///
  /// Advanced mapping parameters (specify at most one):
  /// - [iri] - Treats property value as an IRI reference
  /// - [localResource] - Treats property as a nested anonymous resource
  /// - [literal] - Applies custom literal serialization
  /// - [globalResource] - Treats property as a resource with its own IRI
  /// - [contextual] - Enables contextual property mapping where serializers and deserializers
  ///   have access to the parent object, parent subject, and full context
  ///
  /// Most properties work with automatic type-based mapping without these advanced
  /// parameters. Only use them to override default behavior for specific cases.
  ///
  /// [collection] - Specifies a custom collection mapper Type for handling collections.
  /// When provided, the Type must implement `Mapper<C>` and have a constructor that matches
  /// the `Mapper<C> Function({Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})` signature where `T` is the item type and `C` the collection type (e.g. `List<T>`).
  /// If not specified, standard collections
  /// use their respective default mappers: `List<T>` → UnorderedItemsListMapper,
  /// `Set<T>` → UnorderedItemsSetMapper, `Iterable<T>` → UnorderedItemsMapper.
  ///
  /// Well-known collection mappers include:
  /// - Default mappers (multiple triples): `unorderedItems`, `unorderedItemsList`, `unorderedItemsSet`
  /// - RDF structures (single collection): `rdfList`, `rdfSeq`, `rdfBag`, `rdfAlt`
  /// - Custom mappers: Implement `Mapper<C>` with constructor matching `Mapper<C> Function({Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})` signature and refer to that type with `(MyMapper) - you can of course also store the result of that call in a global const variable to have a shortcut, like we do for `rdfList`, `rdfSeq` etc.
  ///
  /// [itemType] - Explicitly specifies the item type for collection mapping when
  /// it cannot be automatically extracted from the field's generic type parameters.
  /// Only needed for custom collection types or complex generics.
  const RdfProperty(
    this.predicate, {
    this.include = true,
    this.defaultValue,
    this.includeDefaultsInSerialization = false,
    this.iri,
    this.localResource,
    this.literal,
    this.globalResource,
    this.collection = const CollectionMapping.auto(),
    this.itemType,
    this.contextual,
  });
}
