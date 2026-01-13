import 'package:rdf_mapper_annotations/src/base/rdf_annotation.dart';

/// Annotation for customizing how individual enum constants are serialized in RDF.
///
/// This annotation can be applied to enum constants to override their default
/// serialization value. Without this annotation, the enum constant name is used.
/// The annotation works with both `@RdfLiteral` and `@RdfIri` annotated enums.
///
/// When used with `@RdfLiteral` enums, the custom value becomes the literal string
/// representation. When used with `@RdfIri` enums, the custom value replaces the
/// `{value}` placeholder in the IRI template.
///
/// ## Usage with @RdfLiteral Enums
///
/// ```dart
/// @RdfLiteral()
/// enum BookFormat {
///   @RdfEnumValue('H')
///   hardcover, // → serializes as literal "H"
///
///   @RdfEnumValue('P')
///   paperback, // → serializes as literal "P"
///
///   ebook, // → serializes as literal "ebook" (default: enum constant name)
/// }
/// ```
///
/// ## Usage with @RdfIri Enums
///
/// ```dart
/// @RdfIri(template: 'http://example.org/formats/{value}')
/// enum StatusType {
///   @RdfEnumValue('active-status')
///   active, // → <http://example.org/formats/active-status>
///
///   @RdfEnumValue('inactive-status')
///   inactive, // → <http://example.org/formats/inactive-status>
///
///   pending, // → <http://example.org/formats/pending> (default: enum constant name)
/// }
/// ```
///
/// ## Usage with Complex IRI Templates
///
/// For enums with multi-part IRI templates, the custom value replaces the specific
/// variable corresponding to the enum value:
///
/// ```dart
/// @RdfIri(template: 'http://schema.org/{category}/{value}')
/// enum ItemCondition {
///   @RdfEnumValue('NewCondition')
///   brandNew, // → <http://schema.org/product/NewCondition>
///
///   @RdfEnumValue('UsedCondition')
///   used, // → <http://schema.org/product/UsedCondition>
///
///   refurbished, // → <http://schema.org/product/refurbished>
/// }
/// ```
///
/// ## Validation Rules
///
/// - `@RdfEnumValue` can only be applied to enum constants
/// - The parent enum must be annotated with either `@RdfLiteral` or `@RdfIri`
/// - Custom values must be unique within the same enum
/// - For `@RdfIri` enums, custom values must be valid IRI path segments
/// - Empty or whitespace-only values are not allowed
///
/// ## Error Handling
///
/// The code generator will validate these rules and provide meaningful error
/// messages during compilation if violations are detected. Common issues include:
///
/// - Applying `@RdfEnumValue` to non-enum constants
/// - Using duplicate custom values within the same enum
/// - Using invalid characters in IRI template values
/// - Missing required `@RdfLiteral` or `@RdfIri` annotation on the parent enum
///
/// ## Best Practices
///
/// - Use descriptive custom values that align with your domain vocabulary
/// - Keep custom values short but meaningful for better RDF readability
/// - Consider backward compatibility when changing custom values
/// - Use consistent naming patterns across related enums
/// - For IRI enums, follow URI naming conventions (lowercase, hyphens over underscores)
///
/// ## Integration with Property Mappings
///
/// Enum values with `@RdfEnumValue` work seamlessly with property-level overrides:
///
/// ```dart
/// @RdfGlobalResource(...)
/// class Product {
///   // Uses the enum's default @RdfLiteral mapping with custom values
///   @RdfProperty(ProductSchema.format)
///   final BookFormat format;
///
///   // Override with a custom mapper while preserving custom enum values
///   @RdfProperty(
///     ProductSchema.condition,
///     literal: LiteralMapping.namedMapper('customConditionMapper')
///   )
///   final ItemCondition condition;
/// }
/// ```
class RdfEnumValue implements RdfAnnotation {
  /// Custom value to use when serializing this enum constant.
  ///
  /// This value replaces the default enum constant name during RDF serialization.
  /// The specific usage depends on the parent enum's annotation:
  ///
  /// - For `@RdfLiteral` enums: becomes the literal string value
  /// - For `@RdfIri` enums: replaces the `{value}` placeholder in the IRI template
  ///
  /// Requirements:
  /// - Must not be null, empty, or contain only whitespace
  /// - Must be unique within the same enum
  /// - For IRI enums, should be a valid IRI path segment
  ///
  /// Examples:
  /// ```dart
  /// @RdfEnumValue('H') // Short code for hardcover
  /// hardcover,
  ///
  /// @RdfEnumValue('active-status') // Kebab-case for IRI
  /// active,
  ///
  /// @RdfEnumValue('NewCondition') // PascalCase matching vocabulary
  /// brandNew,
  /// ```
  final String value;

  /// Creates an annotation that customizes the serialization value for an enum constant.
  ///
  /// The [value] parameter specifies the custom serialization value to use instead
  /// of the enum constant name. This value must be non-empty and unique within
  /// the enum.
  ///
  /// Example:
  /// ```dart
  /// enum Priority {
  ///   @RdfEnumValue('HIGH')
  ///   high,
  ///
  ///   @RdfEnumValue('MEDIUM')
  ///   medium,
  ///
  ///   @RdfEnumValue('LOW')
  ///   low,
  /// }
  /// ```
  const RdfEnumValue(this.value);
}
