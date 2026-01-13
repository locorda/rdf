import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/src/base/base_mapping.dart';
import 'package:rdf_mapper_annotations/src/base/mapper_direction.dart';
import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';
import 'package:rdf_vocabularies_core/rdf.dart';

/// Marks a Dart class or enum as representing an RDF literal term.
///
/// This annotation is used for value types that need custom serialization beyond simple
/// Dart primitives:
///
/// - Value objects with validation logic (e.g., ratings, percentages, identifiers)
/// - Objects with formatted string representations (e.g., temperatures, currencies)
/// - Custom types with specific RDF serialization requirements
///
/// When you annotate a class with `@RdfLiteral`, a mapper is created that handles
/// the conversion between your Dart class and RDF literal values.
///
/// ## Usage Options
///
/// You can define how your class is mapped in several ways:
///
/// 1. **Simple value objects** - Use `@RdfLiteral()` and mark a property with `@RdfValue()`
/// 2. **Custom conversion methods** - Use `@RdfLiteral.custom()` and specify class methods
/// 3. **External mappers** - Use `.namedMapper()`, `.mapper()`, or `.mapperInstance()`
///
/// ## Property-Level Usage
///
/// You can also apply this as part of an `@RdfProperty` annotation to override
/// serialization for a specific property:
///
/// ```dart
/// @RdfGlobalResource(...)
/// class Product {
///   @RdfProperty(
///     ProductSchema.price,
///     literal: LiteralMapping.namedMapper('priceMapper')
///   )
///   final Price price;
/// }
/// ```
///
/// ## Examples
///
/// **Simple value with validation:**
/// ```dart
/// @RdfLiteral()
/// class Rating {
///   @RdfValue() // Value to use for serialization
///   final int stars;
///
///   Rating(this.stars) {
///     if (stars < 0 || stars > 5) {
///       throw ArgumentError('Rating must be between 0 and 5 stars');
///     }
///   }
/// }
/// ```
///
/// **Custom conversion methods:**
/// ```dart
/// @RdfLiteral.custom(
///   toLiteralTermMethod: 'formatCelsius',
///   fromLiteralTermMethod: 'parse',
///   datatype: Xsd.string
/// )
/// class Temperature {
///   final double celsius;
///   Temperature(this.celsius);
///
///   LiteralContent formatCelsius() => LiteralContent('$celsius°C');
///
///   static Temperature parse(LiteralContent term) =>
///     Temperature(double.parse(term.value.replaceAll('°C', '')));
/// }
/// ```
///
/// Example with automatic value delegation:
/// ```dart
/// @RdfLiteral()
/// class Rating {
///   @RdfValue() // The 'stars' property value will be used as the literal value
///   final int stars;
///
///   Rating(this.stars) {
///     if (stars < 0 || stars > 5) {
///       throw ArgumentError('Rating must be between 0 and 5 stars');
///     }
///   }
/// }
/// ```
///
/// Example with custom conversion methods:
/// ```dart
/// @RdfLiteral.custom(
///   toLiteralTermMethod: 'toRdf',
///   fromLiteralTermMethod: 'fromRdf',
///   datatype: Xsd.string
/// )
/// class Temperature {
///   final double celsius;
///
///   Temperature(this.celsius);
///
///   LiteralContent toRdf() => LiteralContent('$celsius°C');
///
///   static Temperature fromRdf(LiteralContent term) =>
///     Temperature(double.parse(term.value.replaceAll('°C', '')));
/// }
/// ```
///
/// ## Enum Usage
///
/// `@RdfLiteral` can be applied to enums to generate automatic literal mappers:
///
/// ```dart
/// @RdfLiteral() // Uses enum constant names as literal values
/// enum BookFormat {
///   hardcover, // → "hardcover"
///   paperback, // → "paperback"
///   ebook,     // → "ebook"
/// }
///
/// @RdfLiteral(XSD.string) // With explicit datatype
/// enum Priority {
///   @RdfEnumValue('H') // Custom value override
///   high,              // → "H"
///
///   @RdfEnumValue('M')
///   medium,            // → "M"
///
///   low,               // → "low" (uses enum name)
/// }
/// ```
///
/// When applied to enums, the generator creates a `LiteralTermMapper<EnumType>`
/// that automatically handles conversion between enum constants and RDF literals.
/// By default, the enum constant name is used as the literal value, but this can
/// be overridden using the `@RdfEnumValue` annotation on individual constants.
///
/// **Enum Validation Rules:**
/// - Each enum constant with `@RdfEnumValue` must have a unique custom value
/// - Custom values cannot be empty or contain only whitespace
/// - The enum itself must be annotated with `@RdfLiteral`
///
/// **Integration with Properties:**
/// ```dart
/// @RdfGlobalResource(...)
/// class Product {
///   // Uses the enum's default @RdfLiteral mapping
///   @RdfProperty(ProductSchema.format)
///   final BookFormat format;
///
///   // Override with custom mapper for this property
///   @RdfProperty(
///     ProductSchema.priority,
///     literal: LiteralMapping.namedMapper('customPriorityMapper')
///   )
///   final Priority priority;
/// }
/// ```
class RdfLiteral extends BaseMappingAnnotation<LiteralTermMapper>
    implements RdfAnnotation {
  /// Optional method name to use for converting the object to a [LiteralTerm].
  ///
  /// This method must be an instance method on the annotated class that returns a
  /// [LiteralTerm]. If not specified, the generator will look for a property marked
  /// with `@RdfValue` and use its value for conversion.
  final String? toLiteralTermMethod;

  /// Optional static method name to use for converting a [LiteralTerm] back to
  /// the object type.
  ///
  /// This method must be a static method on the annotated class that accepts
  /// a [LiteralTerm] and returns an instance of the annotated class. If not
  /// specified, the generator will look for a property marked with `@RdfValue`
  /// and attempt to deserialize the literal value into that property's type
  /// and pass it to the class's constructor.
  final String? fromLiteralTermMethod;

  final IriTerm? datatype;

  /// Creates an annotation for a class or enum to be mapped to a literal term.
  ///
  /// This standard constructor creates a mapper that automatically handles the
  /// conversion between your type and an RDF literal term. By default, this mapper is
  /// registered within `initRdfMapper` when [registerGlobally] is `true`.
  ///
  /// ## For Classes
  /// The mapper works by:
  /// 1. Looking for a property in your class marked with `@RdfValue`
  /// 2. Using that property to create a literal value during serialization
  /// 3. Using that property's type and the constructor to deserialize values
  ///
  /// This is the simplest approach for value objects that wrap a single literal value.
  ///
  /// ## For Enums
  /// When applied to enums, generates an automatic literal mapper that:
  /// - Uses enum constant names as literal values by default
  /// - Respects `@RdfEnumValue` annotations for custom values
  /// - Handles bidirectional conversion between enum constants and literals
  ///
  /// ## Parameters
  ///
  /// [datatype] - Optional RDF datatype IRI to apply to generated literals.
  /// If not specified, the datatype is inferred from the Dart type.
  ///
  /// [registerGlobally] - Whether to register the generated mapper in `initRdfMapper`.
  /// Set to `false` if the mapper should be registered manually or used at the property level instead.
  ///
  /// Example with class:
  /// ```dart
  /// @RdfLiteral()
  /// class Rating {
  ///   @RdfValue() // Marks this property as the source for the literal value
  ///   final int stars;
  ///
  ///   Rating(this.stars) {
  ///     if (stars < 0 || stars > 5) {
  ///       throw ArgumentError('Rating must be between 0 and 5 stars');
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// Example with enum:
  /// ```dart
  /// @RdfLiteral() // Uses enum names as literal values
  /// enum Priority {
  ///   @RdfEnumValue('H') // Custom literal value
  ///   high,              // → "H"
  ///   medium,            // → "medium" (uses enum name)
  ///   low,               // → "low" (uses enum name)
  /// }
  /// ```
  const RdfLiteral(
      [this.datatype,
      bool registerGlobally = true,
      MapperDirection direction = MapperDirection.both])
      : toLiteralTermMethod = null,
        fromLiteralTermMethod = null,
        super(registerGlobally: registerGlobally, direction: direction);

  /// Creates an annotation for a class using custom methods for literal conversion.
  ///
  /// This approach allows you to define how your class is converted to/from RDF literals
  /// by specifying methods in your class:
  ///
  /// * [toLiteralTermMethod]: An instance method that converts your object to a `LiteralContent`
  /// * [fromLiteralTermMethod]: A static method that creates your object from a `LiteralContent`
  /// * [datatype]: Optional: The RDF datatype IRI to apply to generated literals.
  ///
  /// This is ideal for classes that need special formatting or validation during
  /// serialization, such as formatted values with specific string representations
  /// (temperatures, currencies, structured values, etc.).
  ///
  /// Example:
  /// ```dart
  /// @RdfLiteral.custom(
  ///   toLiteralTermMethod: 'formatCelsius',
  ///   fromLiteralTermMethod: 'parse',
  ///   datatype: Xsd.string
  /// )
  /// class Temperature {
  ///   final double celsius;
  ///
  ///   Temperature(this.celsius);
  ///
  ///   // Instance method for serialization
  ///   LiteralContent formatCelsius() => LiteralContent('$celsius°C');
  ///
  ///   // Static method for deserialization
  ///   static Temperature parse(LiteralContent term) =>
  ///     Temperature(double.parse(term.value.replaceAll('°C', '')));
  /// }
  /// ```
  const RdfLiteral.custom({
    required String toLiteralTermMethod,
    required String fromLiteralTermMethod,
    IriTerm? datatype,
  })  : toLiteralTermMethod = toLiteralTermMethod,
        fromLiteralTermMethod = fromLiteralTermMethod,
        datatype = datatype,
        super();

  /// Creates a reference to a named mapper for this literal term.
  ///
  /// Use this constructor when you want to provide a custom `LiteralTermMapper`
  /// implementation via dependency injection. When using this approach, you must:
  /// 1. Implement the mapper yourself
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The [name] will correspond to a parameter in the generated `initRdfMapper`
  /// function.
  ///
  /// This approach is particularly useful for complex value objects that require
  /// special serialization logic or context-dependent conversions.
  ///
  /// Example:
  /// ```dart
  /// @RdfLiteral.namedMapper('temperatureMapper')
  /// class Temperature {
  ///   final double celsius;
  ///   Temperature(this.celsius);
  ///   // ...
  /// }
  ///
  /// // You must implement the mapper:
  /// class MyTemperatureMapper implements LiteralTermMapper<Temperature> {
  ///   // Your implementation...
  /// }
  ///
  /// // In initialization code:
  /// final tempMapper = MyTemperatureMapper();
  /// final rdfMapper = initRdfMapper(temperatureMapper: tempMapper);
  /// ```
  const RdfLiteral.namedMapper(String name, {super.direction})
      : toLiteralTermMethod = null,
        fromLiteralTermMethod = null,
        datatype = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of [mapperType] to handle literal
  /// term mapping for this class. The type must implement `LiteralTermMapper<T>`
  /// where T is the annotated class and it must have a no-argument default constructor.
  ///
  /// This approach is useful when the mapper has a default constructor and doesn't
  /// require additional configuration parameters.
  ///
  /// Example:
  /// ```dart
  /// @RdfLiteral.mapper(TemperatureMapper)
  /// class Temperature {
  ///   final double celsius;
  ///   Temperature(this.celsius);
  ///   // ...
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class TemperatureMapper implements LiteralTermMapper<Temperature> {
  ///   @override
  ///   LiteralTerm toRdfTerm(Temperature temp, SerializationContext context) {
  ///     return LiteralTerm('${temp.celsius}°C');
  ///   }
  ///
  ///   @override
  ///   Temperature fromRdfTerm(LiteralTerm term, DeserializationContext context) {
  ///     return Temperature(double.parse(term.value.replaceAll('°C', '')));
  ///   }
  /// }
  /// ```
  const RdfLiteral.mapper(Type mapperType, {super.direction})
      : toLiteralTermMethod = null,
        fromLiteralTermMethod = null,
        datatype = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this literal
  /// term.
  ///
  /// This allows you to supply a pre-existing instance of a `LiteralTermMapper`
  /// for this class. Useful when your mapper requires constructor parameters
  /// or complex setup that cannot be handled by simple instantiation.
  ///
  /// This is the most direct method for providing custom serialization logic,
  /// especially when the mapper needs configuration or context from the
  /// application.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const tempMapper = TemperatureMapper(
  ///   unit: TemperatureUnit.celsius,
  ///   precision: 2,
  ///   locale: 'en_US',
  /// );
  ///
  /// @RdfLiteral.mapperInstance(tempMapper)
  /// class Temperature {
  ///   final double value;
  ///   Temperature(this.value);
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const RdfLiteral.mapperInstance(LiteralTermMapper instance, {super.direction})
      : toLiteralTermMethod = null,
        fromLiteralTermMethod = null,
        datatype = null,
        super.mapperInstance(instance);
}

/// Configures mapping details for literal values in RDF at the property level.
///
/// This class is used within the `@RdfProperty` annotation to customize how objects
/// are serialized as literal values in RDF. Unlike class-level mappings configured with
/// `@RdfLiteral`, these mappings are scoped to the specific property where they
/// are defined and are not registered globally.
///
/// In RDF, literal values represent simple data values like strings, numbers, or dates.
/// This mapping is typically used for:
///
/// - Value objects with special formatting requirements
/// - Custom data types that need specialized serialization logic
/// - Properties that need different literal representation than their default type
/// - Context-specific formatting (e.g., currencies that need different formats in different contexts)
///
/// **Important**: Mappers configured through `LiteralMapping` are only used by
/// the specific `ResourceMapper` whose property annotation references them. They are
/// not registered in the global mapper registry and won't be available for use by
/// other mappers or for direct lookup.
///
/// Example:
/// ```dart
/// @RdfProperty(
///   SchemaBook.price,
///   literal: LiteralMapping.namedMapper('formattedPriceMapper')
/// )
/// final Price price;
/// ```
///
/// Without this override, the property would use the default mapper registered for
/// the `Price` class, which might be configured with `@RdfLiteral` at the class level.
/// The key difference is that the class-level mapper is globally registered (unless
/// `registerGlobally: false` is specified), while this property-level mapping is
/// only used for this specific property.
///
/// ## Property Type Support
///
/// For all property types, there must be a registered mapper available:
/// - **Primitive types**: Built-in mappers (String, int, double, bool, etc.)
/// - **Annotated types**: Generated mappers from `@RdfLiteral` annotations
/// - **Custom types**: Explicitly registered mappers
///
/// The `LiteralMapping.withLanguage()` and `LiteralMapping.withType()` constructors
/// delegate to the registered mapper for the property's type and then apply additional
/// processing (language tag or datatype override).
///
/// ## Examples
///
/// ```dart
/// @RdfGlobalResource(...)
/// class Product {
///   // Uses registered mapper for BookFormat enum
///   @RdfProperty(ProductSchema.format)
///   final BookFormat format;
///
///   // Override with custom mapper for this property
///   @RdfProperty(
///     ProductSchema.priority,
///     literal: LiteralMapping.namedMapper('customPriorityMapper')
///   )
///   final Priority priority;
///
///   // Apply language tag to registered mapper result
///   @RdfProperty(
///     ProductSchema.condition,
///     literal: LiteralMapping.withLanguage('en')
///   )
///   final BookFormat condition;
///
///   // Apply custom datatype to registered mapper result
///   @RdfProperty(
///     ProductSchema.urgency,
///     literal: LiteralMapping.withType(Xsd.string)
///   )
///   final Priority urgency;
/// }
/// ```
class LiteralMapping extends BaseMapping<LiteralTermMapper> {
  final String? language;
  final IriTerm? datatype;

  /// Creates a reference to a named mapper for this literal term.
  ///
  /// Use this constructor when you want to provide a custom `LiteralTermMapper`
  /// implementation via dependency injection. When using this approach, you must:
  /// 1. Implement the mapper yourself
  /// 2. Instantiate the mapper (outside of the generated code)
  /// 3. Provide the mapper instance as a named parameter to `initRdfMapper`
  ///
  /// The `name` will correspond to a parameter in the generated `initRdfMapper` function,
  /// but the mapper will *not* be registered globally in the `RdfMapper` instance
  /// but only used for the Resource Mapper whose property is annotated with this mapping.
  ///
  /// This approach is particularly useful for complex value objects that require
  /// special serialization logic or context-dependent conversions.
  ///
  /// Example:
  /// ```dart
  /// @RdfGlobalResource(...)
  /// class WeatherStation {
  ///   // Using a custom mapper for a Temperature object
  ///   @RdfProperty(
  ///     WeatherSchema.temperature,
  ///     literal: LiteralMapping.namedMapper('temperatureMapper')
  ///   )
  ///   final Temperature temperature;
  /// }
  ///
  /// // You must implement the mapper:
  /// class MyTemperatureMapper implements LiteralTermMapper<Temperature> {
  ///   // Your implementation...
  /// }
  ///
  /// // In initialization code:
  /// final tempMapper = MyTemperatureMapper();
  /// final rdfMapper = initRdfMapper(temperatureMapper: tempMapper);
  /// ```
  const LiteralMapping.namedMapper(String name)
      : language = null,
        datatype = null,
        super.namedMapper(name);

  /// Creates a reference to a mapper that will be instantiated from the given type.
  ///
  /// The generator will create an instance of [mapperType] to handle literal
  /// term mapping for this class. The type must implement `LiteralTermMapper<T>`
  /// where T is the annotated class and it must have a no-argument default constructor.
  ///
  /// It will only be used for the Resource Mapper whose property is annotated with this mapping,
  /// not automatically be registered globally.
  ///
  /// This approach is useful when the mapper has a default constructor and doesn't
  /// require additional configuration parameters.
  ///
  /// Example:
  /// ```dart
  /// @RdfGlobalResource(...)
  /// class WeatherStation {
  ///   // Using a custom mapper for a Temperature object
  ///   @RdfProperty(
  ///     WeatherSchema.temperature,
  ///     literal: LiteralMapping.mapper(TemperatureMapper)
  ///   )
  ///   final Temperature temperature;
  /// }
  ///
  /// // The mapper implementation must be accessible to the generator:
  /// class TemperatureMapper implements LiteralTermMapper<Temperature> {
  ///   @override
  ///   LiteralTerm toRdfTerm(Temperature temp, SerializationContext context) {
  ///     return LiteralTerm('${temp.celsius}°C');
  ///   }
  ///
  ///   @override
  ///   Temperature fromRdfTerm(LiteralTerm term, DeserializationContext context) {
  ///     return Temperature(double.parse(term.value.replaceAll('°C', '')));
  ///   }
  /// }
  /// ```
  const LiteralMapping.mapper(Type mapperType)
      : language = null,
        datatype = null,
        super.mapper(mapperType);

  /// Creates a reference to a directly provided mapper instance for this literal
  /// term.
  ///
  /// This allows you to supply a pre-existing instance of a `LiteralTermMapper`
  /// for this class. Useful when your mapper requires constructor parameters
  /// or complex setup that cannot be handled by simple instantiation.
  ///
  /// It will only be used for the Resource Mapper whose property is annotated with this mapping,
  /// not automatically be registered globally.
  ///
  /// This approach is particularly useful when the mapper needs configuration or context from the
  /// application.
  ///
  /// Example:
  /// ```dart
  /// // Create a pre-configured mapper with const constructor:
  /// const tempMapper = TemperatureMapper(
  ///   unit: TemperatureUnit.celsius,
  ///   precision: 2,
  ///   locale: 'en_US',
  /// );
  ///
  /// @RdfGlobalResource(...)
  /// class WeatherStation {
  ///   // Using a custom pre-configured mapper for a Temperature object
  ///   @RdfProperty(
  ///     WeatherSchema.temperature,
  ///     literal: LiteralMapping.mapperInstance(tempMapper)
  ///   )
  ///   final Temperature temperature;
  /// }
  /// ```
  ///
  /// Note: Since annotations in Dart must be evaluated at compile-time,
  /// the mapper instance must be a compile-time constant.
  const LiteralMapping.mapperInstance(LiteralTermMapper instance)
      : language = null,
        datatype = null,
        super.mapperInstance(instance);

  /// Specifies a language tag for string literals at the property level.
  ///
  /// This constructor creates a mapping that will apply the given language tag
  /// to string values when serialized as RDF literals. This is particularly useful
  /// for human-readable text that appears in a specific language.
  ///
  /// **Important**: This mapping delegates to the registered mapper for the
  /// property's type and then applies the language tag to the result. This means
  /// the property's type must have a registered mapper available (built-in for
  /// primitives, generated from annotations, or explicitly registered).
  ///
  /// The [language] parameter must be a valid BCP47 language tag (e.g., 'en', 'de-DE').
  ///
  /// Example with String property:
  /// ```dart
  /// @RdfGlobalResource(...)
  /// class TravelGuide {
  ///   @RdfProperty(
  ///     TourismSchema.description,
  ///     literal: LiteralMapping.withLanguage('en')
  ///   )
  ///   final String description; // Will be serialized as "description"@en
  /// }
  /// ```
  ///
  /// Example with annotated enum property:
  /// ```dart
  /// @RdfLiteral() // Creates registered mapper
  /// enum Status {
  ///   @RdfEnumValue('active')
  ///   active,
  ///   inactive,
  /// }
  ///
  /// @RdfGlobalResource(...)
  /// class Task {
  ///   @RdfProperty(
  ///     TaskSchema.status,
  ///     literal: LiteralMapping.withLanguage('en')
  ///   )
  ///   final Status status; // Uses registered enum mapper + applies @en language tag
  /// }
  /// ```
  const LiteralMapping.withLanguage(String language)
      : language = language,
        datatype = null,
        super();

  /// Specifies a custom datatype for literal values.
  ///
  /// This constructor creates a mapping that will apply the given datatype IRI
  /// to values when serialized as RDF literals. This is useful when you need to
  /// explicitly set the datatype of a literal, overriding the default datatype
  /// that would be inferred from the Dart type.
  ///
  /// **Important**: This mapping delegates to the registered mapper for the
  /// property's type and then applies the custom datatype to the result. This means
  /// the property's type must have a registered mapper available (built-in for
  /// primitives, generated from annotations, or explicitly registered).
  ///
  /// The [datatype] parameter must be an `IriTerm` representing the IRI of the RDF datatype.
  /// Well-known datatypes are available as constants in the Xsd class in the
  /// `rdf_vocabularies` package. For example:
  /// - Xsd.string
  /// - Xsd.integer
  /// - Xsd.decimal
  /// - Xsd.boolean
  /// - Xsd.date
  /// - Xsd.time
  ///
  /// Example with primitive type:
  /// ```dart
  /// @RdfGlobalResource(...)
  /// class HistoricalEvent {
  ///   @RdfProperty(
  ///     HistorySchema.occurredIn,
  ///     literal: LiteralMapping.withType(Xsd.gYear)
  ///   )
  ///   final int year; // Will be serialized with gYear datatype instead of xsd:integer
  /// }
  /// ```
  ///
  /// Example with annotated enum property:
  /// ```dart
  /// @RdfLiteral() // Creates registered mapper
  /// enum Priority {
  ///   @RdfEnumValue('HIGH')
  ///   high,
  ///   @RdfEnumValue('LOW')
  ///   low,
  /// }
  ///
  /// @RdfGlobalResource(...)
  /// class Task {
  ///   @RdfProperty(
  ///     TaskSchema.priority,
  ///     literal: LiteralMapping.withType(Xsd.string)
  ///   )
  ///   final Priority priority; // Uses registered enum mapper + applies xsd:string datatype
  /// }
  /// ```
  const LiteralMapping.withType(IriTerm datatype)
      : language = null,
        datatype = datatype,
        super();
}

/// Marks a property within a class as the primary value source for RDF literal
/// conversion.
///
/// This annotation is used within classes annotated with `@RdfLiteral`
/// to designate which property provides the value for RDF literal serialization.
/// The generator automatically detects the appropriate datatype from the
/// property's type.
///
/// When the generator creates a `LiteralTermMapper` for a class marked with
/// `@RdfLiteral()`, it uses the property marked with `@RdfValue()` as the source
/// of the literal value. This means that only this property's value will be
/// included in the RDF serialization,
/// while other properties in the class are used only within the Dart application.
///
/// Example:
/// ```dart
/// @RdfLiteral()
/// class Rating {
///   @RdfValue() // The int value becomes the literal value
///   final int stars;
///
///   final String description; // Not included in the RDF serialization
///
///   Rating(this.stars, this.description) {
///     if (stars < 0 || stars > 5) {
///       throw ArgumentError('Rating must be between 0 and 5 stars');
///     }
///   }
/// }
/// ```
class RdfValue implements RdfAnnotation {
  /// Marks a property as the value source for RDF serialization.
  ///
  /// The generator will delegate the conversion of this property's value
  /// to the standard serializer/deserializer registered for its datatype.
  const RdfValue();
}

/// Marks a property as providing the language tag for RDF literals.
///
/// Used within `@RdfLiteral` annotated classes to specify a property that provides
/// the language tag for language-tagged string literals (e.g., "Hello"@en). Only one
/// property per class should be annotated with `@RdfLanguageTag`, and it must be of
/// type `String`.
///
/// Language tags are a crucial feature of RDF literals, particularly for
/// human-readable text in different languages. When a class has both `@RdfValue`
/// and `@RdfLanguageTag` annotations, the generator creates a mapper that produces
/// language-tagged literals in the RDF graph.
///
/// Example:
/// ```dart
/// @RdfLiteral()
/// class LocalizedText {
///   @RdfValue()
///   final String text;
///
///   @RdfLanguageTag()
///   final String language; // e.g., 'en', 'de', 'fr'
///
///   LocalizedText(this.text, this.language);
///
///   // When serialized to RDF, this becomes a literal like: "text"@language
/// }
/// ```
class RdfLanguageTag implements RdfAnnotation {
  const RdfLanguageTag();
}

/// Represents the content for building an RDF Literal.
///
/// Use the default constructor for a value that will be combined with a datatype,
/// or `LiteralContent.withLanguage` for a language-tagged string.
class LiteralContent {
  final String value;
  final String? language;

  /// Creates content for a literal that will be combined with a datatype.
  const LiteralContent(this.value) : language = null;

  /// Creates content for a language-tagged string literal.
  const LiteralContent.withLanguage(this.value, this.language);

  LiteralTerm toLiteralTerm(IriTerm? datatype) {
    if (language != null) {
      if (datatype != null && datatype != Rdf.langString) {
        throw ArgumentError("""
Language-tagged literals must use rdf:langString datatype. Adjust the annotation for example like this:

@RdfLiteral.custom(
  toLiteralTermMethod: 'formatLiteral',
  fromLiteralTermMethod: 'parseLiteral',
  datatype: Rdf.langString,
)
          """);
      }
      return LiteralTerm.withLanguage(value, language!);
    }
    if (datatype != null) {
      return LiteralTerm(value, datatype: datatype);
    }
    return LiteralTerm(value);
  }

  static LiteralContent fromLiteralTerm(LiteralTerm term) {
    if (term.language != null) {
      return LiteralContent.withLanguage(term.value, term.language!);
    }
    return LiteralContent(term.value);
  }
}
