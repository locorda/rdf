import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/src/base/base_mapping.dart';
import 'package:locorda_rdf_mapper_annotations/src/base/mapper_direction.dart';
import 'package:locorda_rdf_mapper_annotations/src/base/rdf_annotation.dart';
import 'package:locorda_rdf_mapper_annotations/src/vocab/app_vocab.dart';

/// Marks a Dart class as a local RDF resource (referred to via a blank node).
///
/// Local resources represent embedded entities that don't need globally unique
/// identifiers and whose identity depends on the context of their parent resource.
///
/// Unlike `@RdfGlobalResource`, instances with this annotation will be mapped to
/// blank nodes (anonymous resources) rather than resources with IRIs.
/// Instances of the annotated class will be mapped to blank nodes in RDF triples
/// by a corresponding mapper - either a mapper generated automatically from this
/// annotation, or a mapper that you implement manually and register with `locorda_rdf_mapper`.
///
/// With custom (i.e. manually implemented) mappers, the actual RDF triple generation depends on your mapper
/// implementation, regardless of any property annotations.
///
/// When using the standard constructor (`@RdfLocalResource(classIri)`), a mapper is
/// automatically generated based on the property annotations (like `@RdfProperty`)
/// in your class. By default, this mapper is registered within `initRdfMapper`
/// (when [registerGlobally] is true). This generated mapper will create RDF triples
/// with the blank node as the subject for each annotated property.
///
/// Set [registerGlobally] to `false` if this mapper should not be registered
/// automatically. This is useful when the mapper requires constructor parameters
/// that are only available at runtime and should be provided via `@RdfProvides`
/// annotations in the parent class.
///
/// Use this for value objects or components that only make sense in the context of
/// their parent entity.
///
/// You can use this annotation in several ways, depending on your mapping needs:
/// 1. Standard: With a class IRI (`@RdfLocalResource(classIri)`) - the mapper is
///    automatically generated and registered within `initRdfMapper` when
///    [registerGlobally] is true, which is the default
/// 2. Named mapper: With `@RdfLocalResource.namedMapper()` - you must implement
///    the mapper, instantiate it, and provide it to `initRdfMapper` as a named
///    parameter
/// 3. Mapper type: With `@RdfLocalResource.mapper()` - you must implement the
///    mapper, it will be instantiated and registered within initRdfMapper
///    automatically
/// 4. Mapper instance: With `@RdfLocalResource.mapperInstance()` - you must
///    implement the mapper, your instance will be registered within initRdfMapper
///    automatically
///
/// Example:
/// ```dart
/// @RdfGlobalResource(SchemaBook.classIri, IriStrategy('http://example.org/book/{id}'))
/// class Book {
///   // ...
///   @RdfProperty(SchemaBook.hasPart)
///   final Iterable<Chapter> chapters;
/// }
///
/// @RdfLocalResource(SchemaChapter.classIri)
/// class Chapter {
///   @RdfProperty(SchemaChapter.name)
///   final String title;
///
///   @RdfProperty(SchemaChapter.position)
///   final int number;
///   // ...
/// }
/// ```
class RdfLocalResource extends BaseMappingAnnotation<LocalResourceMapper>
    implements RdfAnnotation {
  /// The RDF class IRI for this blank node.
  ///
  /// This defines the RDF type of the blank node using the `rdf:type` predicate.
  final IriTerm? classIri;

  /// The vocabulary configuration for define mode.
  ///
  /// When using the `.define()` constructor, this field specifies the application
  /// vocabulary configuration. It is `null` for all other constructors.
  final AppVocab? vocab;

  /// The superclass for this resource in define mode.
  ///
  /// When using the `.define()` constructor, this field can optionally specify
  /// an `rdfs:subClassOf` relationship. It is `null` for all other constructors.
  final IriTerm? subClassOf;

  /// Optional additional metadata triples for this class in define mode.
  ///
  /// Each entry is a `(predicate, object)` record written on the generated
  /// class resource (`vocab#ClassName`).
  final List<(IriTerm, RdfObject)>? metadata;

  /// Optional human-readable label for this class in define mode.
  final String? label;

  /// Optional description for this class in define mode.
  final String? comment;

  /// Creates an annotation for a class whose instances will be mapped to RDF
  /// blank nodes.
  ///
  /// This standard constructor creates a mapper that will create RDF triples from
  /// instances of the annotated class, with each instance represented as a blank
  /// node. The generated mapper is automatically registered within `initRdfMapper`
  /// when [registerGlobally] is `true` (the default).
  ///
  /// Set [registerGlobally] to `false` if this mapper should not be registered
  /// automatically. This is required when the generated mapper needs providers
  /// injected in its constructor which should be provided by a parent class and not
  /// globally in `initRdfMapper`. This can happen in these cases:
  ///
  /// 1. Any `@RdfProperty` annotation in this class has an [IriMapping] that
  ///    contains a template variable not provided by this resource class
  ///    via an `@RdfProvides` annotation.
  ///
  /// 2. The `@RdfIri` annotation of any `@RdfProperty`'s value class contains `registerGlobally: false` (so it will be instantiated by this resource mapper instead of using the globally registered mapper) and contains
  ///    a template variable not provided by either:
  ///    - The value class's own `@RdfIriPart` annotations
  ///    - This resource class via `@RdfProvides` annotations
  ///
  /// Also set to `false` if you want to manually manage the mapper registration.
  ///
  ///
  /// [classIri] specifies the `rdf:type` for the blank node, which defines what kind
  /// of entity this is in RDF terms. It is optional, but it's highly recommended to
  /// provide a class IRI to ensure proper typing in the RDF graph.
  ///
  /// [registerGlobally] controls whether the generated mapper should be registered globally
  /// in the `initRdfMapper` function. Set to `false` when the mapper should not be
  /// globally accessible, typically when all required context will be provided by parent
  /// objects via `@RdfProvides` annotations.
  ///
  /// Unlike `RdfGlobalResource`, no IRI construction strategy is needed since blank
  /// nodes are anonymous resources that do not have permanent identifiers.
  ///
  /// Example:
  /// ```dart
  /// @RdfLocalResource(SchemaChapter.classIri)
  /// class Chapter {
  ///   @RdfProperty(SchemaChapter.name)
  ///   final String title;
  ///
  ///   @RdfProperty(SchemaChapter.position)
  ///   final int number;
  ///   // ...
  /// }
  /// ```
  const RdfLocalResource(
      [this.classIri,
      bool registerGlobally = true,
      MapperDirection direction = MapperDirection.both])
      : vocab = null,
        subClassOf = null,
        metadata = null,
        label = null,
        comment = null,
        super(registerGlobally: registerGlobally, direction: direction);

  /// Creates a reference to a named mapper for this local resource.
  ///
  /// Use this constructor when you want to provide a custom `LocalResourceMapper`
  /// implementation via dependency injection. When using this approach, you must:
  /// 1. Implement the mapper yourself
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The `name` will correspond to a parameter in the generated `initRdfMapper` function,
  /// but the mapper will *not* be registered globally in the `RdfMapper` instance
  /// but only used for the Resource Mapper whose property is annotated with this mapping.
  ///
  /// Example:
  /// ```dart
  /// class Book {
  ///   // Using a custom mapper for a nested Chapter object
  ///   @RdfProperty(
  ///     SchemaBook.chapter,
  ///     localResource: LocalResourceMapping.namedMapper('customChapterMapper')
  ///   )
  ///   final Chapter chapter;
  /// }
  ///
  /// // You must implement the mapper:
  /// class MyChapterMapper implements LocalResourceMapper<Chapter> {
  ///   // Your implementation...
  /// }
  ///
  /// // In initialization code:
  /// final chapterMapper = MyChapterMapper();
  /// final rdfMapper = initRdfMapper(customChapterMapper: chapterMapper);
  /// ```
  const RdfLocalResource.namedMapper(String name, {super.direction})
      : classIri = null,
        vocab = null,
        subClassOf = null,
        metadata = null,
        label = null,
        comment = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of [mapperType] to handle mapping
  /// for this class. The type must implement `LocalResourceMapper<T>` where T
  /// is the annotated class and it must have a no-argument default constructor.
  ///
  /// Example:
  /// ```dart
  /// @RdfLocalResource.mapper(CustomChapterMapper)
  /// class Chapter {
  ///   // ...
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class CustomChapterMapper implements LocalResourceMapper<Chapter> {
  ///   // Implementation details...
  /// }
  /// ```
  const RdfLocalResource.mapper(Type mapperType, {super.direction})
      : classIri = null,
        vocab = null,
        subClassOf = null,
        metadata = null,
        label = null,
        comment = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this local
  /// resource.
  ///
  /// This allows you to supply a pre-existing instance of a `LocalResourceMapper`
  /// for this class. Useful when your mapper requires constructor parameters
  /// or complex setup that cannot be handled by simple instantiation.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const chapterMapper = CustomChapterMapper(
  ///   validation: strictValidation,
  ///   options: chapterOptions,
  /// );
  ///
  /// @RdfLocalResource.mapperInstance(chapterMapper)
  /// class Chapter {
  ///   // ...
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const RdfLocalResource.mapperInstance(LocalResourceMapper instance,
      {super.direction})
      : classIri = null,
        vocab = null,
        subClassOf = null,
        metadata = null,
        label = null,
        comment = null,
        super.mapperInstance(instance);

  /// Creates an annotation for vocabulary generation mode.
  ///
  /// Use this constructor when you want to automatically generate a vocabulary
  /// (Turtle/RDF file) from your Dart class structure. In this mode, the class IRI
  /// is derived automatically from the class name and the vocabulary configuration.
  ///
  /// When using this constructor:
  /// - The [vocab] parameter specifies the application vocabulary configuration
  /// - The [subClassOf] parameter optionally specifies a superclass relationship
  /// - The [metadata] parameter adds custom RDF metadata triples for this class resource
  /// - The [label] parameter optionally sets `rdfs:label` for the generated class
  /// - The [comment] parameter optionally sets `rdfs:comment` for the generated class
  /// - The [registerGlobally] parameter controls whether the generated mapper is registered
  ///   globally (defaults to `true`). Set to `false` when the mapper requires runtime context
  /// - The [direction] parameter controls the mapping direction: `both` (default), `toRdf`, or `fromRdf`
  /// - The class IRI is computed at build time as: `vocab.appBaseUri + vocab.vocabPath + '#' + ClassName`
  /// - All properties (both annotated with `@RdfProperty.define()` and unannotated)
  ///   contribute to the vocabulary unless explicitly excluded
  ///
  /// Unlike `RdfGlobalResource.define()`, local resources don't have an IRI strategy
  /// since they are represented as blank nodes in RDF.
  ///
  /// Example (basic usage):
  /// ```dart
  /// const myVocab = AppVocab(
  ///   appBaseUri: 'https://my.app.de',
  ///   vocabPath: '/vocab',
  /// );
  ///
  /// @RdfLocalResource.define(
  ///   myVocab,
  ///   subClassOf: SchemaChapter.classIri,
  /// )
  /// class Chapter {
  ///   // This property will be included in the vocabulary with fragment 'title'
  ///   final String title;
  ///
  ///   // This property can explicitly use .define() to customize the fragment
  ///   @RdfProperty.define(fragment: 'chapterNumber')
  ///   final int number;
  /// }
  /// ```
  ///
  /// This will generate a vocabulary file containing:
  /// - Class definition: `<https://my.app.de/vocab#Chapter> a owl:Class`
  /// - SubClass relationship: `rdfs:subClassOf <https://schema.org/Chapter>`
  /// - Property definitions for 'title' and 'chapterNumber'
  ///
  /// Example (with metadata):
  /// ```dart
  /// // Using label and comment for documentation
  /// @RdfLocalResource.define(
  ///   myVocab,
  ///   label: 'Chapter',
  ///   comment: 'A chapter within a book or document',
  /// )
  /// class Chapter { /* ... */ }
  ///
  /// // Combining label/comment with custom metadata
  /// @RdfLocalResource.define(
  ///   myVocab,
  ///   label: 'Chapter',
  ///   metadata: [
  ///     (OwlVocab.deprecated, LiteralTerm('false', datatype: Xsd.boolean)),
  ///     (Dcterms.modified, LiteralTerm('2025-02-17', datatype: Xsd.date)),
  ///   ],
  /// )
  /// class Chapter { /* ... */ }
  /// ```
  ///
  /// The generated Turtle will include metadata triples:
  /// ```turtle
  /// <https://my.app.de/vocab#Chapter> a owl:Class ;
  ///     rdfs:label "Chapter" ;
  ///     owl:deprecated false ;
  ///     dcterms:modified "2025-02-17"^^xsd:date .
  /// ```
  const RdfLocalResource.define(
    AppVocab vocab, {
    IriTerm? subClassOf,
    List<(IriTerm, RdfObject)> metadata = const [],
    this.label,
    this.comment,
    bool registerGlobally = true,
    MapperDirection direction = MapperDirection.both,
  })  : vocab = vocab,
        subClassOf = subClassOf,
        metadata = metadata,
        classIri = null,
        super(registerGlobally: registerGlobally, direction: direction);
}

/// Configures mapping details for local resources (blank nodes) at the property level.
///
/// This class is used within the `@RdfProperty` annotation to customize how objects
/// are serialized as blank nodes in RDF. Unlike class-level mappings configured with
/// `@RdfLocalResource`, these mappings are scoped to the specific property where they
/// are defined and are not registered globally.
///
/// In RDF, blank nodes represent anonymous resources that exist within the context of
/// their parent resource, rather than having globally unique identifiers. This mapping
/// is ideal for:
///
/// - Composite objects or value objects
/// - Nested structures where identity outside the parent context isn't needed
/// - Objects that semantically don't make sense as standalone entities
/// - Property-specific mapping behavior that differs from the class-level configuration
///
/// **Important**: Mappers configured through `LocalResourceMapping` are only used by
/// the specific `ResourceMapper` whose property annotation references them. They are
/// not registered in the global mapper registry and won't be available for use by
/// other mappers or for direct lookup.
///
/// Example:
/// ```dart
/// @RdfProperty(
///   SchemaBook.chapter,
///   localResource: LocalResourceMapping.namedMapper('customChapterMapper')
/// )
/// final Chapter firstChapter;
/// ```
///
/// Without this override, the property would use the default mapper registered for
/// the `Chapter` class, which might be configured with `@RdfLocalResource` at the class level.
/// The key difference is that the class-level mapper is globally registered (unless
/// `registerGlobally: false` is specified), while this property-level mapping is
/// only used for this specific property.
class LocalResourceMapping extends BaseMapping<LocalResourceMapper> {
  /// Creates a reference to a named mapper that will be injected at runtime.
  ///
  /// Use this constructor when you want to provide your own custom
  /// `LocalResourceMapper` implementation rather than using the automatic generator.
  /// The mapper you provide will determine how instances of the class are mapped to
  /// RDF subjects. When using this approach, you must:
  /// 1. Implement the mapper yourself
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The `name` will correspond to a parameter in the generated `initRdfMapper` function,
  /// but the mapper will *not* be registered globally in the `RdfMapper` instance
  /// but only used for the Resource Mapper whose property is annotated with this mapping.
  ///
  /// Example:
  /// ```dart
  /// @RdfGlobalResource.namedMapper('customBookMapper')
  /// class Book {
  ///   // ...
  /// }
  ///
  /// // You must implement the mapper:
  /// class MyBookMapper implements GlobalResourceMapper<Book> {
  ///   // Your implementation...
  /// }
  ///
  /// // In initialization code:
  /// final bookMapper = MyBookMapper();
  /// final rdfMapper = initRdfMapper(customBookMapper: bookMapper);
  /// ```
  const LocalResourceMapping.namedMapper(String name) : super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// Use this constructor when you want to provide your own custom mapper implementation
  /// rather than using the automatic generator. The mapper you provide will determine
  /// how instances of the class are mapped to RDF subjects.
  ///
  /// The generator will create an instance of `mapperType` to handle mapping
  /// for instances of this class. The type must implement `LocalResourceMapper<T>` where T
  /// is the annotated class and it must have a no-argument default constructor.
  /// It will only be used for the Resource Mapper whose property is annotated with this mapping, not automatically be registered globally.
  ///
  /// Example:
  /// ```dart
  /// class Book {
  ///   // Using a custom mapper for a nested Chapter object
  ///   @RdfProperty(
  ///     SchemaBook.chapter,
  ///     localResource: LocalResourceMapping.mapper(CustomChapterMapper)
  ///   )
  ///   final Chapter chapter;
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class CustomChapterMapper implements LocalResourceMapper<Chapter> {
  ///   // Implementation details...
  /// }
  /// ```
  const LocalResourceMapping.mapper(Type mapperType) : super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this local
  /// resource.
  ///
  /// This allows you to supply a pre-existing instance of a `LocalResourceMapper`
  /// for this class. Useful when your mapper requires constructor parameters
  /// or complex setup that cannot be handled by simple instantiation.
  ///
  /// It will only be used for the Resource Mapper whose property is annotated with this mapping, not automatically be registered globally.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const chapterMapper = CustomChapterMapper(
  ///   validation: strictValidation,
  ///   options: chapterOptions,
  /// );
  ///
  /// class Book {
  ///   // Using a custom mapper for a nested Chapter object
  ///   @RdfProperty(
  ///     SchemaBook.chapter,
  ///     localResource: LocalResourceMapping.mapperInstance(chapterMapper)
  ///   )
  ///   final Chapter chapter;
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const LocalResourceMapping.mapperInstance(LocalResourceMapper instance)
      : super.mapperInstance(instance);
}
