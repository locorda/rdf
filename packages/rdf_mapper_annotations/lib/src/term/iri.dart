import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/src/base/base_mapping.dart';
import 'package:rdf_mapper_annotations/src/base/mapper_direction.dart';
import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';

/// Marks a Dart class or enum as representing an RDF IRI term.
///
/// This annotation is used for classes that represent identifiers or references
/// that should be serialized as IRIs (Internationalized Resource Identifiers)
/// in RDF graphs:
///
/// - URIs and URLs
/// - ISBNs, DOIs, and other standardized identifiers
/// - Domain-specific identifiers with structured formats
///
/// When you annotate a class with `@RdfIri`, a mapper is created that handles
/// the conversion between your Dart class and IRI terms.
///
/// ## Property Requirements
///
/// For classes with `@RdfIri` (enum support see below) using the default constructor:
/// - All properties used for serialization/deserialization **must** be annotated with `@RdfIriPart`
/// - Any property without `@RdfIriPart` will be ignored during mapping
/// - The class must be fully serializable/deserializable using only the `@RdfIriPart` properties
/// - Derived or computed properties (not needed for serialization) don't need annotations
///
/// **Important:** When using external mappers (via `.namedMapper()`, `.mapper()`, or `.mapperInstance()`),
/// the `@RdfIriPart` annotations are ignored. In this case, your custom mapper implementation is fully
/// responsible for the serialization/deserialization logic.
///
/// ## IRI Generation
///
/// The IRI is computed using:
///
/// 1. An optional **template pattern** with variables in curly braces, e.g., `urn:isbn:{value}`
/// 2. Properties annotated with `@RdfIriPart` that provide values for these variables
/// 3. For the simplest case without a template, the property marked with `@RdfIriPart`
///    is used directly as the complete IRI
///
/// ## Usage Options
///
/// You can define how your class is mapped in several ways:
///
/// 1. **Template-based** - `@RdfIri('prefix:{value}')`
/// 2. **Direct value** - `@RdfIri()` (uses the `@RdfIriPart` property value as-is)
/// 3. **External mappers** - `.namedMapper()`, `.mapper()`, or `.mapperInstance()`
///
/// By default, the generated mapper is registered globally in `initRdfMapper`. Set
/// [registerGlobally] to `false` if this mapper should not be registered
/// automatically. This is useful when the mapper requires constructor parameters
/// that are only available at runtime and should be provided via `@RdfProvides`
/// annotations in the parent class.
///
/// ## Examples
///
/// **Template-based IRI:**
/// ```dart
/// @RdfIri('urn:isbn:{value}')
/// class ISBN {
///   @RdfIriPart() // 'value' is inferred from property name
///   final String value;
///
///   ISBN(this.value);
///   // Serialized as: urn:isbn:9780261102217
/// }
/// ```
///
/// **Direct value as IRI:**
/// ```dart
/// @RdfIri()
/// class AbsoluteUri {
///   @RdfIriPart()
///   final String uri;
///
///   AbsoluteUri(this.uri);
///   // Uses the value directly as IRI: 'https://example.org/resource/123'
/// }
/// ```
///
/// ## Advanced Template Patterns
///
/// All `@RdfIri` templates support a powerful placeholder system with context variables
/// and reserved expansion, applicable to both classes and enums:
///
/// ### Template Variable Types
/// - `{value}` - Property values from `@RdfIriPart` annotations
/// - `{variable}` - Context variables (percent-encoded)
/// - `{+variable}` - Reserved expansion (preserves URI structure like `/`)
///
/// ### Context Variable Resolution
/// Context variables are resolved from:
/// - Providers passed to the constructor of the generated Mapper.
/// - Global providers in `initRdfMapper()` are automatically passed to the generated Mapper constructor (when `registerGlobally: true`)
///
/// ### General Template Examples
///
/// **Classes with context variables:**
/// ```dart
/// @RdfIri('{+baseUri}/users/{userId}/profile')
/// class UserProfile {
///   @RdfIriPart('userId')
///   final String userId;
///
///   UserProfile(this.userId);
/// }
///
/// // When registerGlobally is true (default), this adds required providers:
/// final rdfMapper = initRdfMapper(
///   baseUriProvider: () => 'https://api.example.org',
/// );
/// ```
///
/// **Multi-part class IRIs:**
/// ```dart
/// @RdfIri('{+baseUri}/collections/{collection}/{item}')
/// class CollectionItem {
///   @RdfIriPart('collection')
///   final String collection;
///
///   @RdfIriPart('item')
///   final String item;
///
///   CollectionItem(this.collection, this.item);
/// }
/// ```
///
/// **Enums with context variables:**
/// ```dart
/// @RdfIri('{+baseUri}/categories/{category}/{value}')
/// enum ProductCategory {
///   electronics, // → <https://example.org/categories/products/electronics>
///   clothing,    // → <https://example.org/categories/products/clothing>
/// }
///
/// // Same provider setup applies to enums:
/// final rdfMapper = initRdfMapper(
///   baseUriProvider: () => 'https://example.org',
///   categoryProvider: () => 'products',
/// );
/// ```
///
/// ## Enum Usage
///
/// `@RdfIri` can be applied to enums to generate automatic IRI mappers:
///
/// ```dart
/// @RdfIri('http://example.org/formats/{value}')
/// enum BookFormat {
///   @RdfEnumValue('hardcover-type')
///   hardcover, // → <http://example.org/formats/hardcover-type>
///
///   paperback, // → <http://example.org/formats/paperback>
/// }
///
/// @RdfIri('http://vocab.org/status/{value}')
/// enum Status {
///   active,   // → <http://vocab.org/status/active>
///   inactive, // → <http://vocab.org/status/inactive>
/// }
/// ```
///
/// ### Advanced Enum Templates
///
/// Enums also support the full template system with context variables:
///
/// ```dart
/// @RdfIri('{+baseUri}/categories/{category}/{value}')
/// enum ProductCategory {
///   electronics, // → <https://example.org/categories/products/electronics>
///   clothing,    // → <https://example.org/categories/products/clothing>
/// }
///
/// // When registerGlobally is true (default), this adds required providers to initRdfMapper:
/// final rdfMapper = initRdfMapper(
///   baseUriProvider: () => 'https://example.org',
///   categoryProvider: () => 'products',
/// );
/// ```
///
/// For enums, the `{value}` placeholder is replaced with either:
/// - The custom value from `@RdfEnumValue('custom')` annotation
/// - The enum constant name (default)
///
/// When applied to enums, the generator creates an `IriTermMapper<EnumType>`
/// that automatically handles conversion between enum constants and IRI terms.
/// This is particularly useful for representing controlled vocabularies or
/// taxonomies as IRIs in RDF.
///
/// **Enum Validation Rules:**
/// - Each enum constant with `@RdfEnumValue` must have a unique custom value
/// - Custom values must be valid IRI path segments (no spaces, proper encoding)
/// - The enum itself must be annotated with `@RdfIri`
/// - Template must contain `{value}` placeholder when used with enums
/// - Additional context variables are supported and follow the same resolution rules as class mappings
///
/// **Integration with Properties:**
/// ```dart
/// @RdfGlobalResource(...)
/// class Product {
///   // Uses the enum's default @RdfIri mapping
///   @RdfProperty(ProductSchema.condition)
///   final ItemCondition condition;
///
///   // Override with custom mapper for this property
///   @RdfProperty(
///     ProductSchema.format,
///     iri: IriMapping.namedMapper('customFormatMapper')
///   )
///   final BookFormat format;
/// }
/// ```
class RdfIri extends BaseMappingAnnotation<IriTermMapper>
    implements RdfAnnotation {
  /// An optional template string for constructing the IRI.
  ///
  /// Template variables are enclosed in curly braces and can be of two types:
  ///
  /// 1. **Class property variables**: Correspond to properties in the class marked with `@RdfIriPart`
  ///    - Example: In `@RdfIri('urn:isbn:{value}')`, the `{value}` variable will be replaced with
  ///      the value of the property marked with `@RdfIriPart()` (or `@RdfIriPart('value')`)
  ///    - When multiple properties use `@RdfIriPart.position()`, the generator creates a record-based
  ///      mapper to handle complex multi-part IRIs
  ///
  /// 2. **Context variables**: Variables like `{+baseUri}` or `{+storageRoot}` that are provided
  ///    through one of three methods:
  ///    - Via global provider functions in `initRdfMapper` (e.g., `baseUriProvider: () => 'https://example.com'`).
  ///      The generator will automatically add a required parameter to `initRdfMapper`.
  ///    - Via other properties in the same class annotated with `@RdfProvides('baseUri')`.
  ///      This is preferred for context variables that are already available in the class.
  ///    - Via the parent resource's IRI, when the parent's `IriStrategy` specifies `providedAs` parameter.
  ///      This is useful for hierarchical structures where children need the parent's IRI.
  ///    - The `+` prefix (e.g., `{+baseUri}`) indicates variables that may contain URI-reserved
  ///      characters like slashes, which should not be percent-encoded when substituted
  ///
  /// If no template is provided (`template == null`), the property marked with `@RdfIriPart`
  /// will be used as the complete IRI value.
  final String? template;

  /// Optional template for the fragment identifier to append to the base IRI.
  ///
  /// When specified (via `RdfIri.withFragment` constructor), the generator will:
  /// 1. Process [template] to get the base IRI
  /// 2. Strip any existing fragment from the base IRI (everything after and including `#`)
  /// 3. Process [fragmentTemplate] to get the fragment value
  /// 4. Append `#${fragmentValue}` to create the final IRI
  ///
  /// This enables creating IRI term classes that differ from a base IRI only by their fragment identifier,
  /// which works with any URI scheme (hierarchical or non-hierarchical like `tag:`).
  final String? fragmentTemplate;

  /// Creates an annotation for a class or enum to be mapped to an IRI term.
  ///
  /// This standard constructor creates a mapper that automatically handles the
  /// conversion between your Dart type and an IRI term. By default, this mapper is
  /// registered within `initRdfMapper` when [registerGlobally] is `true`.
  ///
  /// ## Template System
  ///
  /// The [template] parameter supports a powerful placeholder system that works for
  /// both classes and enums:
  ///
  /// ### Placeholder Types:
  /// - `{propertyName}` - Values from `@RdfIriPart` annotated properties (percent-encoded)
  /// - `{contextVariable}` - Context variables from providers (percent-encoded)
  /// - `{+contextVariable}` - Reserved expansion for URI structure preservation
  ///
  /// ### Context Variable Resolution:
  /// Context variables are resolved from:
  /// - Global providers in `initRdfMapper()` (e.g., `baseUriProvider: () => 'https://api.example.com'`)
  /// - Class properties annotated with `@RdfProvides('variableName')`
  /// - Parent resource's IRI, when the parent's `IriStrategy` specifies `providedAs` parameter
  ///
  /// ### Usage for Classes:
  /// ```dart
  /// // Template with property placeholders
  /// @RdfIri('urn:isbn:{value}')
  /// class ISBN {
  ///   @RdfIriPart()
  ///   final String value;
  ///   ISBN(this.value);
  /// }
  ///
  /// // Template with context variables
  /// @RdfIri('{+baseUri}/users/{userId}')
  /// class UserProfile {
  ///   @RdfIriPart('userId')
  ///   final String id;
  ///   UserProfile(this.id);
  /// }
  ///
  /// // Direct value (no template)
  /// @RdfIri()
  /// class AbsoluteUri {
  ///   @RdfIriPart()
  ///   final String uri;
  ///   AbsoluteUri(this.uri);
  /// }
  /// ```
  ///
  /// ### Usage for Enums:
  /// For enums, the template system provides an automatic `{value}` placeholder
  /// in addition to context variables:
  ///
  /// ```dart
  /// // Using enum value with custom @RdfEnumValue annotations
  /// @RdfIri('https://vocab.example.com/status#{value}')
  /// enum TaskStatus {
  ///   pending,
  ///   @RdfEnumValue('in-progress')
  ///   inProgress,  // → <https://vocab.example.com/status#in-progress>
  ///   completed    // → <https://vocab.example.com/status#completed>
  /// }
  ///
  /// // Using context variables with enums
  /// @RdfIri('{+vocabBase}/priority/{value}')
  /// enum Priority { low, medium, high }
  /// ```
  ///
  /// For enums:
  /// - `{value}` resolves to the custom value from `@RdfEnumValue` or the enum constant name if not specified
  /// - Context variables work the same as with classes
  /// - If no template is provided, the enum value (respecting `@RdfEnumValue`) is used as the complete IRI
  ///
  /// ## Parameters
  ///
  /// [template] - Optional IRI template with placeholders. If not provided:
  /// - For classes: the single `@RdfIriPart` property value is used directly as the IRI
  /// - For enums: the enum value (respecting `@RdfEnumValue` annotations) is used directly as the IRI
  ///
  /// [registerGlobally] - Whether to register the generated mapper in `initRdfMapper`.
  /// Set to `false` if the mapper should be registered manually or used at the property level instead.
  const RdfIri(
      [this.template,
      bool registerGlobally = true,
      MapperDirection direction = MapperDirection.both])
      : fragmentTemplate = null,
        super(registerGlobally: registerGlobally, direction: direction);

  /// Creates a reference to a named mapper for this IRI term.
  ///
  /// Use this constructor when you want to provide a custom `IriTermMapper`
  /// implementation via dependency injection. When using this approach, you must:
  /// 1. Implement the mapper yourself
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The [name] will be used as a parameter name in the generated `initRdfMapper` function.
  ///
  /// This approach is particularly useful for IRIs that require complex logic or
  /// external context (like base URLs) that might vary between deployments.
  ///
  /// Example:
  /// ```dart
  /// @RdfIri.namedMapper('userReferenceMapper')
  /// class UserReference {
  ///   final String username;
  ///   UserReference(this.username);
  /// }
  ///
  /// // You must implement the mapper:
  /// class MyUserReferenceMapper implements IriTermMapper<UserReference> {
  ///   // Your implementation...
  /// }
  ///
  /// // In initialization code:
  /// final userRefMapper = MyUserReferenceMapper();
  /// final rdfMapper = initRdfMapper(userReferenceMapper: userRefMapper);
  /// ```
  const RdfIri.namedMapper(String name, {super.direction})
      : template = null,
        fragmentTemplate = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of [mapperType] to handle IRI mapping
  /// for this class. The type must implement `IriTermMapper`.
  ///
  /// This approach is useful when the mapper has a default constructor and doesn't
  /// require additional configuration parameters.
  ///
  /// Example:
  /// ```dart
  /// @RdfIri.mapper(StandardIsbnMapper)
  /// class ISBN {
  ///   final String value;
  ///   ISBN(this.value);
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class StandardIsbnMapper implements IriTermMapper<ISBN> {
  ///   @override
  ///   IriTerm toRdfTerm(ISBN isbn, SerializationContext context) {
  ///     return context.createIriTerm('urn:isbn:${isbn.value}');
  ///   }
  ///
  ///   @override
  ///   ISBN fromRdfTerm(IriTerm term, DeserializationContext context) {
  ///     final iri = term.iri;
  ///     if (!iri.startsWith('urn:isbn:')) {
  ///       throw ArgumentError('Invalid ISBN IRI: $iri');
  ///     }
  ///     return ISBN(iri.substring(9));
  ///   }
  /// }
  /// ```
  const RdfIri.mapper(Type mapperType, {super.direction})
      : template = null,
        fragmentTemplate = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this IRI term.
  ///
  /// This allows you to directly provide a pre-configured `IriTermMapper` instance
  /// to handle mapping for this class without dependency injection.
  ///
  /// This approach is ideal when your mapper requires configuration that must be
  /// provided at initialization time, such as base URLs or formatting parameters.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const catalogMapper = ProductCatalogMapper(
  ///   baseUrl: 'https://shop.example.org/catalog/',
  ///   format: UriFormat.pretty,
  /// );
  ///
  /// @RdfIri.mapperInstance(catalogMapper)
  /// class ProductReference {
  ///   final String sku;
  ///   ProductReference(this.sku);
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const RdfIri.mapperInstance(IriTermMapper instance, {super.direction})
      : template = null,
        fragmentTemplate = null,
        super.mapperInstance(instance);

  /// Creates an IRI mapping by appending a fragment to a base IRI.
  ///
  /// This constructor is specifically designed for classes that represent IRI terms which differ
  /// from a base IRI only by their fragment identifier. It works with any URI scheme (hierarchical
  /// like `https://` or non-hierarchical like `tag:`), making it ideal for identifier classes
  /// that represent fragment-based references within a document.
  ///
  /// The generator will:
  /// 1. Process [baseIriTemplate] to get the base IRI
  /// 2. Strip any existing fragment from the base IRI (everything after and including `#`)
  /// 3. Process [fragmentTemplate] to get the fragment value
  /// 4. Append `#${fragmentValue}` to create the final IRI
  ///
  /// Both templates support the standard placeholder system:
  /// - Property placeholders from `@RdfIriPart` annotated properties
  /// - Context variables from global providers, `@RdfProvides`, or parent's `providedAs`
  /// - Reserved expansion with `{+variable}` to preserve URI structure
  ///
  /// Example usage:
  /// ```dart
  /// @RdfIri.withFragment('{+documentIri}', 'section-{sectionId}')
  /// class SectionReference {
  ///   @RdfIriPart()
  ///   final String sectionId;
  ///
  ///   SectionReference(this.sectionId);
  /// }
  ///
  /// @RdfGlobalResource(
  ///   DocumentClass.classIri,
  ///   IriStrategy('tag:example.org,2025:document-{id}', 'documentIri')
  /// )
  /// class Document {
  ///   @RdfIriPart()
  ///   final String id;
  ///
  ///   @RdfProperty(Vocab.currentSection)
  ///   final SectionReference section;
  ///   // Section IRI will be: tag:example.org,2025:document-123#section-intro
  /// }
  /// ```
  const RdfIri.withFragment(String baseIriTemplate, String fragmentTemplate,
      {bool registerGlobally = true})
      : template = baseIriTemplate,
        fragmentTemplate = fragmentTemplate,
        super(registerGlobally: registerGlobally);
}

/// Configures mapping details for IRI terms in RDF at the property level.
///
/// This class is used within the `@RdfProperty` annotation to customize how objects
/// are serialized as IRI terms in RDF. Unlike class-level mappings configured with
/// `@RdfIri`, these mappings are scoped to the specific property where they
/// are defined and are not registered globally.
///
/// In RDF, IRIs (Internationalized Resource Identifiers) are used to uniquely identify
/// resources and properties. This mapping is ideal for:
///
/// - Properties representing identifiers that need custom formatting as IRIs
/// - References to other resources with specific IRI patterns
/// - Properties that must be serialized as IRIs rather than literals
/// - Customizing resource references for specific relationship contexts
///
/// **Important**: Mappers configured through `IriMapping` are only used by
/// the specific `ResourceMapper` whose property annotation references them. They are
/// not registered in the global mapper registry and won't be available for use by
/// other mappers or for direct lookup.
///
/// ## Property Type Support
///
/// The default constructor (`IriMapping([template])`) only supports `String` properties.
/// For non-String types like value objects (e.g., `UserId` or `ISBN` classes), you have
/// two options:
///
/// 1. Use one of the mapper constructors:
///    - `.namedMapper()` - Reference a named mapper provided at runtime
///    - `.mapper()` - Instantiate a mapper from a type
///    - `.mapperInstance()` - Use a pre-configured mapper instance
///
/// 2. Annotate the class of the property value with `@RdfIri` and implement the
///    template logic based on fields of that class there. This approach leverages
///    automatic mapper registration and is often cleaner when the value class
///    is fully under your control.
///
/// These approaches ensure proper serialization and deserialization for complex types.
///
/// ## Examples
///
/// For String properties:
/// ```dart
/// @RdfProperty(
///   Dcterms.creator,
///   iri: IriMapping('https://example.org/users/{userId}')
/// )
/// final String userId;
/// ```
///
/// For value objects:
/// ```dart
/// @RdfProperty(
///   SchemaPerson.identifier,
///   iri: IriMapping.mapper(UserIdMapper)
/// )
/// final UserId userId;
/// ```
///
/// Without this override, the property would use the default mapper registered for
/// the value class, which might be configured with `@RdfIri` at the class level.
/// The key difference is that the class-level mapper is globally registered (unless
/// `registerGlobally: false` is specified), while this property-level mapping is
/// only used for this specific property.
///
/// ## Enum Property Mapping
///
/// Can be used to override enum IRI serialization at the property level:
///
/// ```dart
/// @RdfGlobalResource(...)
/// class Product {
///   // Uses the enum's default @RdfIri mapping with @RdfEnumValue annotations
///   @RdfProperty(ProductSchema.condition)
///   final ItemCondition condition;
///
///   // Override the enum's default mapping with a custom mapper for this property
///   @RdfProperty(
///     ProductSchema.format,
///     iri: IriMapping.namedMapper('customFormatMapper')
///   )
///   final BookFormat format;
///
///   // Use a different IRI template for the same enum in this specific context
///   @RdfProperty(
///     ProductSchema.category,
///     iri: IriMapping('http://local.vocab/{value}/category')
///   )
///   final ItemCondition categoryCondition; // Same enum, different IRI pattern
/// }
/// ```
///
/// This is particularly useful when you need different IRI patterns for the same
/// enum type in different contexts, or when you want to override the global enum
/// mapping for specific properties.
class IriMapping extends BaseMapping<IriTermMapper> {
  /// An optional template string for constructing the IRI.
  ///
  /// Template variables are enclosed in curly braces and can be of two types:
  ///
  /// 1. **Property variables**: Correspond to values from the property this mapping is applied to
  ///    - Example: In `IriMapping('urn:isbn:{userId}')`, the `{userId}` variable will be replaced with
  ///      the value of the property it's applied to
  ///    - The actual property name is used as the placeholder, creating a clear connection between
  ///      the template and the property
  ///
  /// 2. **Context variables**: Variables like `{+baseUri}` or `{+storageRoot}` that are provided
  ///    through one of three methods:
  ///    - Via global provider functions in `initRdfMapper` (e.g., `baseUriProvider: () => 'https://example.com'`).
  ///      The generator will automatically add a required parameter to `initRdfMapper`.
  ///    - Via other properties in the same class annotated with `@RdfProvides('baseUri')`.
  ///      This is preferred for context variables that are already available in the class.
  ///    - Via the parent resource's IRI, when the parent's `IriStrategy` specifies `providedAs` parameter.
  ///      This is useful for hierarchical structures where children need the parent's IRI.
  ///    - Example: `IriMapping('{+baseUri}/users/{userId}')`
  ///    - The `+` prefix (e.g., `{+baseUri}`) indicates variables that may contain URI-reserved
  ///      characters like slashes, which should not be percent-encoded when substituted
  ///
  /// If no template is provided (`template == null`), the property value will be used directly
  /// as the complete IRI, which is useful for properties that already contain fully qualified URIs.
  ///
  /// **Note:** When using the default constructor with a template, the property must be of type
  /// `String`. For non-String types like value objects (e.g., `UserId`), either:
  /// 1. Use one of the mapper constructors (`.namedMapper()`, `.mapper()`, or `.mapperInstance()`)
  ///    to provide explicit conversion logic, or
  /// 2. Annotate the value class itself with `@RdfIri` and implement the template logic there.
  final String? template;

  /// Optional template for the fragment identifier to append to the base IRI.
  ///
  /// When specified (via `IriMapping.withFragment` constructor), the generator will:
  /// 1. Process [template] to get the base IRI
  /// 2. Strip any existing fragment from the base IRI (everything after and including `#`)
  /// 3. Process [fragmentTemplate] to get the fragment value
  /// 4. Append `#${fragmentValue}` to create the final IRI
  ///
  /// This enables creating property IRIs that differ from a base IRI only by their fragment identifier,
  /// which works with any URI scheme (hierarchical or non-hierarchical like `tag:`).
  final String? fragmentTemplate;

  /// Creates an IRI mapping template for property-specific IRI generation.
  ///
  /// Use this constructor to customize how a specific property should be
  /// transformed into an IRI term in the RDF graph.
  ///
  /// ## Template System
  ///
  /// The [template] supports a powerful placeholder system:
  /// - **Property placeholders**: `{propertyName}` - replaced with the property value
  /// - **Context variables**: `{+contextVar}` or `{contextVar}` - resolved from providers
  /// - **Reserved expansion**: Use `{+variable}` to preserve URI structure (like `/`)
  ///
  /// Context variables are resolved from:
  /// - Global providers in `initRdfMapper()` (e.g., `baseUriProvider: () => 'https://api.example.com'`)
  /// - Class properties annotated with `@RdfProvides('variableName')`
  /// - Parent resource's IRI, when the parent's `IriStrategy` specifies `providedAs` parameter
  ///
  /// **Important:** This constructor is only designed for properties of type `String`.
  /// For non-String types (like value objects or domain-specific types), you have two options:
  /// 1. Use one of the mapper constructors: `.namedMapper()`, `.mapper()`, or `.mapperInstance()`
  /// 2. Annotate the value class itself with `@RdfIri` and implement the template logic there
  ///
  /// ## Collection Item IRI Mapping
  ///
  /// **Critical Rule**: When using `IriMapping` for collection properties, template placeholders
  /// must **exactly match the property name** that contains the collection.
  ///
  /// For collections (`List<String>`, `Set<String>`, `Iterable<String>`), each item in the
  /// collection becomes a separate IRI using the template:
  ///
  /// ```dart
  /// @RdfLocalResource()
  /// class BookCollection {
  ///   /// Each author ID becomes an IRI: https://example.org/author/[authorId]
  ///   @RdfProperty(
  ///     SchemaBook.author,
  ///     iri: IriMapping('{+baseUri}/author/{authorIds}'), // ← matches property name
  ///   )
  ///   final List<String> authorIds; // ← property name matches placeholder
  ///
  ///   /// Combined with collection structure
  ///   @RdfProperty(
  ///     SchemaBook.contributors,
  ///     collection: rdfList, // Ordered list structure
  ///     iri: IriMapping('{+baseUri}/contributor/{contributorIds}'), // ← matches property name
  ///   )
  ///   final List<String> contributorIds; // ← property name matches placeholder
  /// }
  /// ```
  ///
  /// **Common Mistake**: Using arbitrary placeholder names that don't match the property:
  /// ```dart
  /// // ❌ WRONG: Placeholder doesn't match property name
  /// @RdfProperty(
  ///   MyVocab.items,
  ///   iri: IriMapping('{+baseUri}/item/{itemId}'), // ← 'itemId' doesn't exist
  /// )
  /// final List<String> itemsList; // ← property name is 'itemsList', not 'itemId'
  ///
  /// // ✅ CORRECT: Placeholder matches property name exactly
  /// @RdfProperty(
  ///   MyVocab.items,
  ///   iri: IriMapping('{+baseUri}/item/{itemsList}'), // ← matches property name
  /// )
  /// final List<String> itemsList;
  /// ```
  ///
  /// ## Template Patterns
  /// - Property only: `IriMapping('http://example.org/users/{userId}')`
  /// - With context: `IriMapping('{+baseUri}/users/{userId}')`
  /// - Direct value: `IriMapping()` - uses the property value directly as the IRI
  ///
  /// This approach enables flexible, context-aware IRI generation for individual properties
  /// while maintaining clear separation from global mapping configurations.
  ///
  /// Examples:
  /// ```dart
  /// // For String properties - using template is fine:
  /// @RdfProperty(
  ///   Dcterms.source,
  ///   iri: IriMapping('urn:isbn:{isbn}')
  /// )
  /// final String isbn; // Will be mapped to an IRI like "urn:isbn:9780123456789"
  ///
  /// // Option 1: For value types - use custom mapper:
  /// @RdfProperty(
  ///   SchemaPerson.identifier,
  ///   iri: IriMapping.mapper(UserIdMapper)
  /// )
  /// final UserId userId; // Will use UserIdMapper for conversion
  ///
  /// // Option 2: For value types - annotate the value class with @RdfIri:
  /// @RdfProperty(SchemaPerson.identifier)
  /// final UserId userId; // The UserId class is annotated with @RdfIri
  ///
  /// // Definition of the UserId class:
  /// @RdfIri('https://example.org/users/{value}')
  /// class UserId {
  ///   @RdfIriPart()
  ///   final String value;
  ///
  ///   UserId(this.value);
  /// }
  /// ```
  const IriMapping([this.template])
      : fragmentTemplate = null,
        super();

  /// Creates a reference to a named mapper for this IRI term.
  ///
  /// Use this constructor when you want to provide a custom `IriTermMapper`
  /// implementation via dependency injection. When using this approach, you must:
  /// 1. Implement the mapper yourself
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The [name] will correspond to a parameter in the generated `initRdfMapper` function,
  /// but the mapper will *not* be registered globally in the `RdfMapper` instance
  /// but only used for the Resource Mapper whose property is annotated with this mapping.
  ///
  /// This approach is particularly useful for IRIs that require complex logic or
  /// external context (like base URLs) that might vary between deployments.
  ///
  /// Example:
  /// ```dart
  /// class Book {
  ///   // Using a custom mapper for a UserReference object
  ///   @RdfProperty(
  ///     SchemaPerson.identifier,
  ///     iri: IriMapping.namedMapper('userReferenceMapper')
  ///   )
  ///   final UserReference userRef;
  /// }
  ///
  /// // You must implement the mapper:
  /// class UserReferenceMapper implements IriTermMapper<UserReference> {
  ///   @override
  ///   IriTerm toRdfTerm(UserReference value, SerializationContext context) {
  ///     return context.createIriTerm('https://example.org/users/${value.username}');
  ///   }
  ///
  ///   @override
  ///   UserReference fromRdfTerm(IriTerm term, DeserializationContext context) {
  ///     final segments = Uri.parse(term.iri).pathSegments;
  ///     return UserReference(segments.last);
  ///   }
  /// }
  ///
  /// // In initialization code:
  /// final userRefMapper = UserReferenceMapper();
  /// final rdfMapper = initRdfMapper(userReferenceMapper: userRefMapper);
  /// ```
  const IriMapping.namedMapper(String name)
      : template = null,
        fragmentTemplate = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of [mapperType] to handle IRI mapping
  /// for this class. The type must implement `IriTermMapper` and it must have a
  /// no-argument default constructor.
  ///
  /// It will only be used for the Resource Mapper whose property is annotated with this mapping,
  /// not automatically be registered globally.
  ///
  /// This approach is useful when the mapper has a default constructor and doesn't
  /// require additional configuration parameters.
  ///
  /// Example:
  /// ```dart
  /// class Book {
  ///   // Using a custom mapper for an ISBN object
  ///   @RdfProperty(
  ///     Dcterms.source,
  ///     iri: IriMapping.mapper(IsbnMapper)
  ///   )
  ///   final ISBN isbn;
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class IsbnMapper implements IriTermMapper<ISBN> {
  ///   @override
  ///   IriTerm toRdfTerm(ISBN isbn, SerializationContext context) {
  ///     return context.createIriTerm('urn:isbn:${isbn.value}');
  ///   }
  ///
  ///   @override
  ///   ISBN fromRdfTerm(IriTerm term, DeserializationContext context) {
  ///     final iri = term.iri;
  ///     if (!iri.startsWith('urn:isbn:')) {
  ///       throw ArgumentError('Invalid ISBN IRI: $iri');
  ///     }
  ///     return ISBN(iri.substring(9));
  ///   }
  /// }
  /// ```
  const IriMapping.mapper(Type mapperType)
      : template = null,
        fragmentTemplate = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this IRI term.
  ///
  /// This allows you to directly provide a pre-configured `IriTermMapper` instance
  /// to handle mapping for this class without dependency injection.
  ///
  /// This approach is ideal when your mapper requires configuration that must be
  /// provided at initialization time, such as base URLs or formatting parameters.
  ///
  /// It will only be used for the Resource Mapper whose property is annotated with this mapping,
  /// not automatically be registered globally.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const catalogMapper = ProductCatalogMapper(
  ///   baseUrl: 'https://shop.example.org/catalog/',
  ///   format: UriFormat.pretty,
  /// );
  ///
  /// class Book {
  ///   // Using a custom pre-configured mapper for a product reference
  ///   @RdfProperty(
  ///     Schema.product,
  ///     iri: IriMapping.mapperInstance(catalogMapper)
  ///   )
  ///   final ProductReference product;
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const IriMapping.mapperInstance(IriTermMapper instance)
      : template = null,
        fragmentTemplate = null,
        super.mapperInstance(instance);

  /// Creates a reference to a named factory function for creating IRI mappers.
  ///
  /// Use this constructor when you want to provide a factory function that creates
  /// `IriTermMapper` instances dynamically for this specific property. This is
  /// particularly useful when the property mapping needs to be coordinated with
  /// other systems or requires runtime configuration.
  ///
  /// The factory function is called with the type of the property this mapping
  /// is applied to, and optionally a configuration object if [configInstance] is
  /// specified. This allows sophisticated mapping strategies that adapt to the
  /// specific property type and context.
  ///
  /// When using this approach, you must:
  /// 1. Implement a factory function with the appropriate signature
  /// 2. Provide the factory function as a named parameter to `initRdfMapper`
  ///
  /// This approach is ideal for:
  /// - Property-specific mapping that needs coordination with external systems
  /// - IRI generation that depends on runtime configuration or storage policies
  ///
  /// **Important**: The mapper created by this factory is only used for the specific
  /// property where this mapping is applied. It is not registered globally and won't
  /// be available for other mappers or direct lookup.
  ///
  /// ## Factory Function Signatures
  ///
  /// The generated factory function signature depends on whether [configInstance] is provided:
  ///
  /// **Without configuration:**
  /// ```dart
  /// IriTermMapper<T> Function<T>() factoryName
  /// ```
  ///
  /// **With configuration:**
  /// ```dart
  /// IriTermMapper<T> Function<T>(ConfigType config) factoryName
  /// ```
  ///
  /// Where `T` is the type of the property this mapping is applied to (currently only String is supported),
  /// and `ConfigType` is the type of the configuration object provided.
  ///
  /// ## Example
  ///
  /// **Factory with the target type as configuration object:**
  ///
  /// This works together with the Solid Pod example from [IriStrategy.namedFactory]
  /// where a single strategy mapper implements complex, pod specific IRI logic.
  /// The IriMapping is for creating IRIs for properties as a reference, so in
  /// this example we want to reference a User in the same Pod. So we also use
  /// a namedFactory, but we pass the target type (User) as configInstance to tell
  /// the named factory that we need references to Users. The named factory `podIriReferenceFactory` here
  /// is expected to work together with the named factory `podIriFactory` for the [IriStrategy.namedFactory] example,
  /// so that the same Pod IRI logic is used for both creating the User resource
  /// and for creating references to Users.
  ///
  /// ```dart
  ///
  /// @RdfProperty(
  ///   SchemaPerson.identifier,
  ///   iri: IriMapping.namedFactory('podIriReferenceFactory', User)
  /// )
  /// final String userRef;
  ///
  /// // Factory function with generic type parameter and config:
  /// IriTermMapper<T> createPodIriReferenceMapper<T>(Type targetType) {
  ///   // actually, we can only support String properties here
  ///   if (T != String) {
  ///     throw ArgumentError('Only String properties are supported for IriMapping');
  ///   }
  ///   return PodIriReferenceMapper(
  ///     targetType: targetType,
  ///     // podCoordinator would be available in the scope where the factory is defined
  ///     coordinator: podCoordinator,
  ///   );
  /// }
  ///
  /// final rdfMapper = initRdfMapper(
  ///   podIriReferenceFactory: createPodIriReferenceMapper,
  ///   // Note: userConfig is embedded in generated code, not passed here
  /// );
  /// // Generated code within initRdfMapper calls: podIriReferenceFactory<String>(User)
  /// ```
  ///
  /// This factory approach enables sophisticated property-level coordination while
  /// maintaining clean separation between global and property-specific mapping strategies.
  const IriMapping.namedFactory(String name, [Object? configInstance])
      : template = null,
        fragmentTemplate = null,
        super.namedFactory(name, configInstance);

  /// Creates a mapping for generating IRIs by appending a fragment to a base IRI.
  ///
  /// This constructor is specifically designed for creating property IRIs that differ from a base IRI
  /// only by their fragment identifier. It works with any URI scheme (hierarchical like `https://`
  /// or non-hierarchical like `tag:`), making it ideal for properties that reference resources
  /// within the same document distinguished by fragments.
  ///
  /// The generator will:
  /// 1. Process [baseIriTemplate] to get the base IRI
  /// 2. Strip any existing fragment from the base IRI (everything after and including `#`)
  /// 3. Process [fragmentTemplate] to get the fragment value
  /// 4. Append `#${fragmentValue}` to create the final IRI
  ///
  /// Both templates support the standard placeholder system:
  /// - Property placeholders corresponding to the annotated property's value
  /// - Context variables from global providers, `@RdfProvides`, or parent's `providedAs`
  /// - Reserved expansion with `{+variable}` to preserve URI structure
  ///
  /// Example usage:
  /// ```dart
  /// @RdfGlobalResource(
  ///   DocumentClass.classIri,
  ///   IriStrategy('tag:example.org,2025:document-{docId}', 'documentIri')
  /// )
  /// class Document {
  ///   @RdfIriPart()
  ///   final String docId;
  ///
  ///   @RdfProperty(
  ///     Vocab.relatedItem,
  ///     iri: IriMapping.withFragment('{+documentIri}', 'item-{itemId}')
  ///   )
  ///   final String itemId;
  ///   // Property IRI will be: tag:example.org,2025:document-123#item-456
  /// }
  /// ```
  const IriMapping.withFragment(String baseIriTemplate, String fragmentTemplate)
      : template = baseIriTemplate,
        fragmentTemplate = fragmentTemplate,
        super();
}

/// Defines the strategy for generating IRIs for RDF resources.
///
/// This class is a key component of the `@RdfGlobalResource` annotation that specifies
/// how to construct unique IRIs for instances of annotated classes. It provides a
/// template-based mechanism that combines static text with dynamic values from object properties.
///
/// ## IRI Template Variables
/// The IRI template supports two types of variables with different expansion syntaxes:
///
/// ### Variable Expansion Syntax
/// - **Standard variables** (`{variable}`): Values are percent-encoded according to URI standards
/// - **Reserved expansion** (`{+variable}`): Values containing URI-reserved characters like
///   slashes (`/`) are not percent-encoded, allowing them to remain as structural URI components
///
/// ### Variable Types
/// 1. **Property-based variables** - Values from properties marked with `@RdfIriPart`:
///    ```dart
///    @RdfGlobalResource(SchemaBook.classIri, IriStrategy('http://example.org/books/{isbn}'))
///    class Book {
///      @RdfIriPart('isbn')  // Maps to {isbn} in the template
///      final String isbn;
///      // ...
///    }
///    ```
///
/// 2. **Context variables** - Values provided externally, often using reserved expansion:
///    ```dart
///    @RdfGlobalResource(
///      SchemaBook.classIri,
///      IriStrategy('{+baseUrl}/books/{id}')  // {+baseUrl} preserves slashes
///    )
///    class Book {
///      @RdfIriPart('id')
///      final String id;
///      // ...
///    }
///
///    // When registerGlobally is true (default):
///    final rdfMapper = initRdfMapper(
///      baseUrlProvider: () => 'https://myapp.example.org'  // Auto-injected parameter
///    );
///    ```
///
/// ## Context Variable Resolution
///
/// When the generator encounters template variables that aren't bound to properties with
/// `@RdfIriPart`, it treats them as context variables and resolves them in the following ways:
///
/// 1. **Global Registration** (when `registerGlobally = true` in `@RdfGlobalResource`, which is the default):
///    - The generator adds required provider parameters to `initRdfMapper()`
///    - These providers must be supplied when initializing the RDF mapper
///    - Example: `{baseUrl}` becomes `required String Function() baseUrlProvider`
///
/// 2. **Local Resolution** (when `registerGlobally = false`):
///    - The parent mapper that uses this type needs to provide the context values
///    - Context variables can be resolved from:
///      a. Properties in the parent class annotated with `@RdfProvides('variableName')`
///      b. The parent resource's IRI itself, when the parent's `IriStrategy` specifies `providedAs` parameter
///      c. Or required in the parent mapper's constructor (which may propagate up to `initRdfMapper`)
///
/// This system enables flexible, context-aware IRI patterns that can adapt to different
/// deployment environments without hardcoding values. Unlike the `RdfIri` annotation which is used
/// for classes that represent IRI terms themselves, `IriStrategy` is used within `RdfGlobalResource`
/// to define how instance IRIs are constructed from their properties.
///
/// ### Example: Providing Parent IRI to Child Resources
///
/// The [providedAs] parameter enables a resource to provide its own IRI to dependent mappers.
/// This is particularly useful for hierarchical data structures:
///
/// ```dart
/// @RdfGlobalResource(
///   ParentClass.classIri,
///   IriStrategy('{+baseUri}/parents/{id}', 'parentIri')
/// )
/// class Parent {
///   @RdfIriPart()
///   final String id;
///
///   @RdfProperty(Vocab.child)
///   final Child child;
/// }
///
/// @RdfGlobalResource(
///   ChildClass.classIri,
///   IriStrategy('{+parentIri}/children/{childId}'),
///   registerGlobally: false
/// )
/// class Child {
///   @RdfIriPart()
///   final String childId;
/// }
/// ```
///
/// In this example, the `Parent` mapper will provide a `String Function()` that returns
/// the parent's IRI, making it available to the `Child` mapper via `{+parentIri}`.
///
/// ## Internal Record-Based Mechanism
///
/// Unlike `RdfIri` and `IriMapping` which work with complete objects, `IriStrategy` operates
/// on a record composed of the values from properties marked with `@RdfIriPart`. This
/// record-based approach allows resource mappers to:
///
/// 1. Extract only the necessary IRI-related properties when serializing
/// 2. Populate these same properties when deserializing from an IRI term
///
///
/// ## Constructor Choice and RdfIriPart Usage
///
/// * **Default constructor**: The generator creates an `IriTermMapper` implementation that
///   handles mapping between a record of the `@RdfIriPart` values and IRI terms. With this
///   approach, you can use the standard `@RdfIriPart([name])` constructor.
///
/// * **Custom mappers** (via `.namedMapper()`, `.mapper()`, or `.mapperInstance()`): You must
///   implement an `IriTermMapper` that works with a record of the property values. For multiple
///   `@RdfIriPart` properties, use `@RdfIriPart.position(index, [name])` to specify the
///   positional order of fields in the record for more robustness and to avoid bugs introduced by
///   changing field order.
///
class IriStrategy extends BaseMapping<IriTermMapper> {
  /// An optional template string for constructing IRIs from resource properties.
  ///
  /// The template can contain static text combined with variables in curly braces. Two variable
  /// expansion syntaxes are supported:
  ///
  /// - **Standard variables** (`{variable}`): Values are percent-encoded according to URI standards
  /// - **Reserved expansion** (`{+variable}`): Values containing URI-reserved characters like
  ///   slashes are not percent-encoded, preserving them as structural URI components
  ///
  /// Variables are resolved in the following order:
  ///
  /// 1. **Class property variables**: Bound to properties marked with `@RdfIriPart`
  ///    - Example: `IriStrategy('urn:isbn:{isbn}')` where `{isbn}` is replaced with
  ///      the value of a property marked with `@RdfIriPart('isbn')`
  ///    - Multiple properties can be combined: `{+baseUrl}/users/{userId}/profiles/{profileId}`
  ///
  /// 2. **Context variables**: Any variable not bound to a property (commonly using `+` prefix)
  ///    - When used with `registerGlobally = true` (default):
  ///      - The generator adds provider parameters to `initRdfMapper`
  ///      - Example: `{+baseUri}` creates `required baseUriProvider: () => 'https://example.org'`
  ///    - When used with `registerGlobally = false`:
  ///      - The mapper looks for:
  ///        - Properties in the parent class with `@RdfProvides('variableName')`
  ///        - Or adds the provider as a required constructor parameter
  ///    - The `+` prefix (e.g., `{+baseUri}`) indicates variables that may contain URI-reserved
  ///      characters like slashes, which should not be percent-encoded when substituted
  ///
  /// If no template is provided (`template == null`), the property marked with `@RdfIriPart`
  /// will be used directly as the complete IRI value.
  final String? template;

  /// Optional template for the fragment identifier to append to the base IRI.
  ///
  /// When specified (via `IriStrategy.withFragment` constructor), the generator will:
  /// 1. Process [template] to get the base IRI
  /// 2. Strip any existing fragment from the base IRI (everything after and including `#`)
  /// 3. Process [fragmentTemplate] to get the fragment value
  /// 4. Append `#${fragmentValue}` to create the final IRI
  ///
  /// This enables creating IRIs that differ from a base IRI only by their fragment identifier,
  /// which works with any URI scheme (hierarchical or non-hierarchical like `tag:`).
  final String? fragmentTemplate;

  /// Optional name under which this resource's IRI will be provided to dependent mappers.
  ///
  /// When specified, the generated mapper will provide a `String Function()` that returns
  /// the resource's IRI, making it available to child/dependent mappers that reference
  /// `{providedName}` in their IRI templates.
  ///
  /// This is particularly useful for hierarchical data structures where child resources
  /// need to reference their parent's IRI in their own IRI construction.
  ///
  /// Example:
  /// ```dart
  /// @RdfGlobalResource(
  ///   ParentClass.classIri,
  ///   IriStrategy('{+baseUri}/parents/{id}', 'parentIri')
  /// )
  /// class Parent {
  ///   @RdfIriPart()
  ///   final String id;
  ///
  ///   @RdfProperty(Vocab.child)
  ///   final Child child;
  /// }
  ///
  /// @RdfGlobalResource(
  ///   ChildClass.classIri,
  ///   IriStrategy('{+parentIri}/children/{childId}'),
  ///   registerGlobally: false
  /// )
  /// class Child {
  ///   @RdfIriPart()
  ///   final String childId;
  /// }
  /// ```
  final String? providedAs;

  /// Creates a strategy for generating IRIs from resource properties.
  ///
  /// Use this constructor with `@RdfGlobalResource` to have the generator create
  /// an IRI mapper automatically. The generator will:
  ///
  /// 1. Create a record type from all properties marked with `@RdfIriPart`
  /// 2. Generate an `IriTermMapper<RecordType>` implementation
  /// 3. Extract values from the resource into this record during serialization
  /// 4. Set properties in the resource from the record during deserialization
  ///    (unless they are also annotated with `@RdfProperty`, in which case the
  ///     value from @RdfProperty takes precedence)
  ///
  /// ## Template System
  ///
  /// The [template] supports flexible IRI construction with:
  /// - **Property placeholders**: `{propertyName}` - values from `@RdfIriPart` properties
  /// - **Context variables**: `{+contextVar}` or `{contextVar}` - external values from providers
  /// - **Reserved expansion**: Use `{+variable}` to preserve URI structure (like `/`)
  ///
  /// Context variables enable deployment-specific configuration without hardcoding URIs.
  /// They are resolved from:
  /// - Global providers in `initRdfMapper()` when `registerGlobally = true` (default)
  /// - Parent class properties with `@RdfProvides()` annotations
  /// - Constructor parameters when `registerGlobally = false`
  ///
  /// Examples:
  /// ```dart
  /// // Property-based IRI
  /// @RdfGlobalResource(Person.classIri, IriStrategy('http://example.org/people/{id}'))
  /// class Person {
  ///   @RdfIriPart('id')
  ///   final String id;
  /// }
  ///
  /// // Context-aware IRI (auto-adds baseUriProvider to initRdfMapper)
  /// @RdfGlobalResource(Book.classIri, IriStrategy('{+baseUri}/books/{isbn}'))
  /// class Book {
  ///   @RdfIriPart('isbn')
  ///   final String isbn;
  /// }
  /// ```
  ///
  /// When the [template] contains unbound variables (not matching any property with `@RdfIriPart`),
  /// the generator will automatically create provider parameters. With `registerGlobally = true`
  /// (the default), these providers become required parameters in the `initRdfMapper` function.
  ///
  /// The optional [providedAs] parameter allows this resource's IRI to be provided to dependent
  /// mappers under the specified name. When set, child/dependent mappers can reference this IRI
  /// in their templates using `{providedName}`.
  const IriStrategy([this.template, this.providedAs])
      : fragmentTemplate = null,
        super();

  /// Creates a reference to a named mapper for this IRI strategy.
  ///
  /// Use this constructor when you want to provide a custom `IriTermMapper`
  /// implementation via dependency injection. With this approach, you must:
  /// 1. Implement the mapper yourself that works with a **record type**
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// Note that - unlike similar constructors like `RdfIri.namedMapper` - the
  /// named mapper will not be registered globally, it will only be used
  /// for the class annotated with `@RdfGlobalResource`.
  ///
  /// Unlike the default constructor which generates a mapper, this requires you to
  /// implement a mapper that works with a record of the property values from fields
  /// marked with `@RdfIriPart`.
  ///
  /// **Important:** When using custom mappers with multiple IRI part properties,
  /// use `@RdfIriPart.position(index)` to specify the order of fields in the record:
  ///
  /// ```dart
  /// @RdfGlobalResource(Product.classIri, IriStrategy.namedMapper('productIdMapper'))
  /// class Product {
  ///   @RdfIriPart.position(1) // First field in the record
  ///   final String category;
  ///
  ///   @RdfIriPart.position(2) // Second field in the record
  ///   final String id;
  ///   // ...
  /// }
  ///
  /// // Implement mapper for the (String, String) record:
  /// class ProductIdMapper implements IriTermMapper<(String, String)> {
  ///   @override
  ///   IriTerm toRdfTerm((String, String) record, SerializationContext context) {
  ///     final (category, id) = record;
  ///     return context.createIriTerm('https://example.org/products/$category/$id');
  ///   }
  ///
  ///   @override
  ///   (String, String) fromRdfTerm(IriTerm term, DeserializationContext context) {
  ///     final parts = term.iri.split('/').takeLast(2).toList();
  ///     return (parts[0], parts[1]);
  ///   }
  /// }
  ///
  /// // In initialization code:
  /// final productMapper = ProductIdMapper();
  /// final rdfMapper = initRdfMapper(productIdMapper: productMapper);
  /// ```
  ///
  /// The resource mapper will:
  /// - During serialization: Extract the properties into a record to pass to your mapper
  /// - During deserialization: Take the record your mapper produces and set the properties
  ///
  /// The optional [providedAs] parameter allows this resource's IRI to be provided to dependent
  /// mappers under the specified name, enabling hierarchical IRI patterns.
  const IriStrategy.namedMapper(String name, {this.providedAs})
      : template = null,
        fragmentTemplate = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of [mapperType] to handle IRI mapping
  /// for this class. The type must implement `IriTermMapper` for a **record type**
  /// composed of the `@RdfIriPart` property values.
  ///
  /// Note that - unlike similar constructors like `RdfIri.namedMapper` - the
  /// mapper will not be registered globally, it will only be used
  /// for the class annotated with `@RdfGlobalResource`.
  ///
  /// When implementing the mapper for multiple IRI parts, use `@RdfIriPart.position(index)`
  /// to define the position of each property in the record that will be passed to your mapper.
  ///
  /// Example:
  /// ```dart
  /// @RdfGlobalResource(Product.classIri, IriStrategy.mapper(ProductIdMapper))
  /// class Product {
  ///   @RdfIriPart.position(1) // First field in record
  ///   final String category;
  ///
  ///   @RdfIriPart.position(2) // Second field in record
  ///   final String id;
  ///   // ...
  /// }
  ///
  /// // Mapper must work with the record type defined by the RdfIriPart positions:
  /// class ProductIdMapper implements IriTermMapper<(String, String)> {
  ///   @override
  ///   IriTerm toRdfTerm((String, String) record, SerializationContext context) {
  ///     final (category, id) = record;
  ///     return context.createIriTerm('https://example.org/products/$category/$id');
  ///   }
  ///
  ///   @override
  ///   (String, String) fromRdfTerm(IriTerm term, DeserializationContext context) {
  ///     final parts = term.iri.split('/').takeLast(2).toList();
  ///     return (parts[0], parts[1]);
  ///   }
  /// }
  /// ```
  ///
  /// The optional [providedAs] parameter allows this resource's IRI to be provided to dependent
  /// mappers under the specified name, enabling hierarchical IRI patterns.
  const IriStrategy.mapper(Type mapperType, {this.providedAs})
      : template = null,
        fragmentTemplate = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this IRI term.
  ///
  /// This allows you to directly provide a pre-configured `IriTermMapper` instance
  /// that works with a **record type** composed of the values from properties marked
  /// with `@RdfIriPart`. Unlike `RdfIri` and `IriMapping` which work with whole objects,
  /// `IriStrategy` mappers must work with records of property values.
  ///
  /// For multiple IRI parts, use `@RdfIriPart.position(index)` to specify the order
  /// of each property in the record:
  ///
  /// ```dart
  /// // Create a pre-configured mapper for a record type:
  /// const productMapper = CustomProductMapper(
  ///   baseUrl: 'https://shop.example.org/catalog/',
  ///   format: UriFormat.pretty,
  /// );
  ///
  /// @RdfGlobalResource(Product.classIri, IriStrategy.mapperInstance(productMapper))
  /// class Product {
  ///   // First field in the record passed to productMapper
  ///   @RdfIriPart.position(0)
  ///   final String category;
  ///
  ///   // Second field in the record passed to productMapper
  ///   @RdfIriPart.position(1)
  ///   final String sku;
  ///   // ...
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  ///
  /// The optional [providedAs] parameter allows this resource's IRI to be provided to dependent
  /// mappers under the specified name, enabling hierarchical IRI patterns.
  const IriStrategy.mapperInstance(IriTermMapper instance, {this.providedAs})
      : template = null,
        fragmentTemplate = null,
        super.mapperInstance(instance);

  /// Creates a reference to a named factory function for creating IRI mappers.
  ///
  /// Use this constructor when you want to provide a factory function that creates
  /// `IriTermMapper` instances dynamically. This is particularly useful for libraries
  /// that need to coordinate IRI generation across multiple types with a single,
  /// shared configuration and strategy.
  ///
  /// The factory function is called with the specific record type inferred from this
  /// class's `@RdfIriPart` annotations, and optionally a configuration object if
  /// [configInstance] is specified. This allows a single factory to handle different
  /// classes while maintaining type safety.
  ///
  /// When using this approach, you must:
  /// 1. Implement a factory function with the appropriate signature
  /// 2. Provide the factory function as a named parameter to `initRdfMapper`
  ///
  /// This approach is ideal for:
  /// - Libraries that need to coordinate IRI generation across all stored types
  /// - Pod-based storage systems where IRI allocation requires coordination
  ///
  /// **Important:** When using custom factories with multiple IRI part properties,
  /// use `@RdfIriPart.position(index)` to specify the order of fields in the record
  /// that will be passed to your factory-created mapper.
  ///
  /// ## Factory Function Signatures
  ///
  /// The generated factory function signature depends on whether [configInstance] is provided:
  ///
  /// **Without configuration:**
  /// ```dart
  /// IriTermMapper<RecordType> Function<T>() factoryName
  /// ```
  ///
  /// **With configuration:**
  /// ```dart
  /// IriTermMapper<RecordType> Function<T>(ConfigType config) factoryName
  /// ```
  ///
  /// Where `RecordType` is inferred from the `@RdfIriPart` annotations on this specific class,
  /// `T` is the class of the resource being mapped, and `ConfigType` is the type of the configuration object.
  ///
  /// ## Examples
  ///
  /// **Simple factory without configuration:**
  /// ```dart
  /// @RdfGlobalResource(Person.classIri, IriStrategy.namedFactory('podIriFactory'))
  /// class Person {
  ///   @RdfIriPart()
  ///   final String id;
  ///   // ...
  /// }
  ///
  /// // Factory function with generic type parameter:
  /// IriTermMapper<(String,)> createIriMapper<T>() {
  ///   return IriStrategyMapper<(String,)>(targetType: T, coordinator: globalPodCoordinator);
  /// }
  ///
  /// final rdfMapper = initRdfMapper(podIriFactory: createIriMapper);
  /// ```
  ///
  /// **Factory with configuration:**
  /// ```dart
  /// @RdfGlobalResource(
  ///   Document.classIri,
  ///   IriStrategy.namedFactory('podIriFactory', PodConfig(storagePolicy: 'distributed'))
  /// )
  /// class Document {
  ///   @RdfIriPart.position(1)
  ///   final String documentId;
  ///   // ...
  /// }
  ///
  /// // Factory function with generic type parameter and config:
  /// IriTermMapper<(String,)> createIriMapper<T>(PodConfig config) {
  ///   return DocumentIriMapper<(String,)>(
  ///     targetType: T,
  ///     // podCoordinator would be available in the scope where the factory is defined
  ///     coordinator: podCoordinator,
  ///     storagePolicy: config.storagePolicy
  ///   );
  /// }
  ///
  /// final rdfMapper = initRdfMapper(
  ///   podIriFactory: createDocumentIriMapper,
  ///   // Note: podConfig is embedded in generated code, not passed here
  /// );
  /// // Generated code within initRdfMapper calls `podIriFactory<Document>(PodConfig(storagePolicy: 'distributed'))`
  /// // and provides the returned mapper to the Document resource mapper
  /// ```
  ///
  /// The factory approach enables sophisticated coordination strategies while maintaining
  /// the simplicity of annotation-driven configuration. The factory function can access
  /// shared resources, configuration, or coordination services to ensure consistent
  /// IRI allocation patterns across your application.
  ///
  /// The optional [providedAs] parameter allows this resource's IRI to be provided to dependent
  /// mappers under the specified name, enabling hierarchical IRI patterns.
  const IriStrategy.namedFactory(String name,
      [Object? configInstance, String? providedAs])
      : template = null,
        fragmentTemplate = null,
        providedAs = providedAs,
        super.namedFactory(name, configInstance);

  /// Creates a strategy for generating IRIs by appending a fragment to a base IRI.
  ///
  /// This constructor is specifically designed for creating IRIs that differ from a base IRI
  /// only by their fragment identifier. It works with any URI scheme (hierarchical like `https://`
  /// or non-hierarchical like `tag:`), making it ideal for resources within the same document
  /// that are distinguished by fragments.
  ///
  /// The generator will:
  /// 1. Process [baseIriTemplate] to get the base IRI
  /// 2. Strip any existing fragment from the base IRI (everything after and including `#`)
  /// 3. Process [fragmentTemplate] to get the fragment value
  /// 4. Append `#${fragmentValue}` to create the final IRI
  ///
  /// Both templates support the standard placeholder system:
  /// - Property placeholders from `@RdfIriPart` annotated properties
  /// - Context variables from global providers, `@RdfProvides`, or parent's `providedAs`
  /// - Reserved expansion with `{+variable}` to preserve URI structure
  ///
  /// The optional [providedAs] parameter allows this resource's IRI to be provided to dependent
  /// mappers under the specified name.
  ///
  /// Example with `tag:` URI:
  /// ```dart
  /// @RdfGlobalResource(
  ///   DocumentClass.classIri,
  ///   IriStrategy('tag:example.org,2025:document-{docId}', 'documentIri')
  /// )
  /// class Document {
  ///   @RdfIriPart()
  ///   final String docId;
  ///
  ///   @RdfProperty(Vocab.hasItem)
  ///   final List<Item> items;
  /// }
  ///
  /// @RdfGlobalResource(
  ///   ItemClass.classIri,
  ///   IriStrategy.withFragment('{+documentIri}', 'item-{itemId}'),
  ///   registerGlobally: false
  /// )
  /// class Item {
  ///   @RdfIriPart()
  ///   final String itemId;
  ///   // IRI will be: tag:example.org,2025:document-123#item-456
  /// }
  /// ```
  ///
  /// Example with `https://` URI:
  /// ```dart
  /// @RdfGlobalResource(
  ///   PageClass.classIri,
  ///   IriStrategy('{+baseUri}/page/{pageId}', 'pageIri')
  /// )
  /// class Page {
  ///   @RdfIriPart()
  ///   final String pageId;
  ///
  ///   @RdfProperty(Vocab.hasSection)
  ///   final List<Section> sections;
  /// }
  ///
  /// @RdfGlobalResource(
  ///   SectionClass.classIri,
  ///   IriStrategy.withFragment('{+pageIri}', 'section-{sectionId}'),
  ///   registerGlobally: false
  /// )
  /// class Section {
  ///   @RdfIriPart()
  ///   final String sectionId;
  ///   // IRI will be: https://example.org/page/123#section-intro
  /// }
  /// ```
  const IriStrategy.withFragment(
      String baseIriTemplate, String fragmentTemplate,
      {this.providedAs})
      : template = baseIriTemplate,
        fragmentTemplate = fragmentTemplate,
        super();
}

/// Marks a property as a part of the IRI for the enclosing class.
///
/// Used in classes annotated with `@RdfIri` or `@RdfGlobalResource` to designate
/// properties that contribute to IRI construction. This annotation creates a binding
/// between template variables and property values.
///
/// ## Supported Property Types
///
/// This annotation works with:
///
/// - **Instance fields**: Compatible with all type-annotated fields (mutable, `final`, and `late`)
/// - **Getters and setters**: Both getter and setter must be provided.
/// - **Only public properties**: Private properties (with underscore prefix) are not supported.
///
/// For classes with `@RdfIri` (or indirectly with @IriMapping), all properties necessary for complete serialization/deserialization
/// must be annotated with `@RdfIriPart`. The instance must be fully reconstructable from just
/// these annotated properties.
///
/// ## Usage with IriStrategy
///
/// The annotation has different usage patterns depending on the `IriStrategy` constructor:
///
/// * With the **default constructor** (`IriStrategy(template)`), use the standard form
///   `@RdfIriPart([name])` - the generator handles record creation automatically.
///
/// * With **custom mappers** (`IriStrategy.namedMapper()`, `.mapper()`, or `.mapperInstance()`),
///   use `@RdfIriPart.position(index, [name])` for multiple properties to ensure
///   correct positioning in the record passed to your mapper.
///
/// ## Examples
///
/// Example with named template variable (generated mapper):
/// ```dart
/// @RdfGlobalResource(SchemaBook.classIri, IriStrategy('http://example.org/book/{id}'))
/// class Book {
///   @RdfIriPart('id') // Property value replaces {id} in the template
///   final String id;
///   // ...
/// }
/// ```
///
/// Example with unnamed (default) template variable:
/// ```dart
/// @RdfIri('urn:isbn:{value}')
/// class ISBN {
///   @RdfIriPart() // Property name 'value' is used as the variable name
///   final String value;
///   // ...
/// }
/// ```
///
/// Example with positional parts for custom mappers:
/// ```dart
/// @RdfGlobalResource(
///   Product.classIri,
///   IriStrategy.namedMapper('productIdMapper')
/// )
/// class Product {
///   @RdfIriPart.position(1) // First position in the generated record type
///   final String category;
///
///   @RdfIriPart.position(2) // Second position in the generated record type
///   final String id;
///   // ...
/// }
/// ```
class RdfIriPart implements RdfAnnotation {
  /// The name of the IRI part. This corresponds to a named template variable
  /// in the `RdfIri` template (e.g., `id` for `{id}`).
  final String? name;

  /// The positional index of the IRI part, used when the IRI is constructed
  /// from multiple unnamed parts, typically for record types in custom mappers.
  ///
  /// Starts from 1 for the first part, 2 for the second, and so on - in sync
  /// with the `.$1`, `.$2` syntax for accessing the first, second etc.
  /// part of a record.
  final int? pos;

  /// Creates an IRI part annotation with a given [name].
  const RdfIriPart([this.name]) : pos = null;

  /// Creates an IRI part annotation with a given [position].
  const RdfIriPart.position(int position, [this.name]) : pos = position;
}
