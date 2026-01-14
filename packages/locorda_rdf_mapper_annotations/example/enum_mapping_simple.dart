/// Simple examples demonstrating enum support in the locorda_rdf_mapper package.
///
/// This file shows basic usage of `@RdfLiteral`, `@RdfIri`, and `@RdfEnumValue`
/// annotations for enum mapping in RDF.
library enum_mapping_examples;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';

// ==============================================================================
// Basic Enum Examples
// ==============================================================================

/// Simple enum with default literal mapping using enum constant names.
///
/// Each enum constant will be serialized as a literal using its name:
/// - BookFormat.hardcover → "hardcover"
/// - BookFormat.paperback → "paperback"
/// - BookFormat.ebook → "ebook"
@RdfLiteral()
enum BookFormat {
  hardcover,
  paperback,
  ebook,
}

/// Enum with custom literal values using @RdfEnumValue annotations.
///
/// This demonstrates how to use short codes or abbreviations:
/// - Priority.high → "H"
/// - Priority.medium → "M"
/// - Priority.low → "L"
@RdfLiteral()
enum Priority {
  @RdfEnumValue('H')
  high,

  @RdfEnumValue('M')
  medium,

  @RdfEnumValue('L')
  low,
}

/// Enum with mixed custom and default values.
@RdfLiteral()
enum ProductStatus {
  @RdfEnumValue('available')
  inStock,

  @RdfEnumValue('sold-out')
  outOfStock,

  discontinued, // Uses enum constant name
}

// ==============================================================================
// IRI-based Enum Examples
// ==============================================================================

/// Enum mapped to IRIs using a template pattern.
///
/// The {value} placeholder is replaced with either the custom @RdfEnumValue
/// or the enum constant name:
/// - ItemCondition.brandNew → <http://schema.org/NewCondition>
/// - ItemCondition.used → <http://schema.org/UsedCondition>
/// - ItemCondition.refurbished → <http://schema.org/refurbished>
@RdfIri('http://schema.org/{value}')
enum ItemCondition {
  @RdfEnumValue('NewCondition')
  brandNew,

  @RdfEnumValue('UsedCondition')
  used,

  refurbished, // Uses enum constant name
}

/// Enum with controlled vocabulary IRI pattern.
@RdfIri('http://example.org/vocab/order-status/{value}')
enum OrderStatus {
  pending,

  @RdfEnumValue('in-progress')
  processing,

  shipped,

  @RdfEnumValue('delivered-completed')
  delivered,
}

// ==============================================================================
// Advanced Examples
// ==============================================================================

/// Enum with ISO currency codes.
@RdfLiteral()
enum CurrencyCode {
  @RdfEnumValue('USD')
  usDollar,

  @RdfEnumValue('EUR')
  euro,

  @RdfEnumValue('GBP')
  britishPound,

  @RdfEnumValue('JPY')
  japaneseYen,
}

/// Enum with hierarchical vocabulary IRIs.
@RdfIri('http://purl.org/goodrelations/v1#{value}')
enum BusinessEntityType {
  @RdfEnumValue('Business')
  business,

  @RdfEnumValue('Enduser')
  endUser,

  @RdfEnumValue('PublicInstitution')
  publicInstitution,

  @RdfEnumValue('Reseller')
  reseller,
}

/// Enum demonstrating proper naming patterns for RDF.
@RdfIri('http://example.org/rating-system/{value}')
enum UserRating {
  @RdfEnumValue('excellent-5-stars')
  excellent,

  @RdfEnumValue('good-4-stars')
  good,

  @RdfEnumValue('average-3-stars')
  average,

  @RdfEnumValue('poor-2-stars')
  poor,

  @RdfEnumValue('terrible-1-star')
  terrible,
}

// ==============================================================================
// Context Variable Examples
// ==============================================================================

/// Enum using context variables for deployment-specific base URIs.
///
/// The {+baseVocab} placeholder will be resolved from providers in initRdfMapper.
/// This enables different vocabulary bases for different environments:
/// - Development: http://dev.example.org/vocab/categories/electronics
/// - Production: https://vocab.mycompany.com/categories/electronics
@RdfIri('{+baseVocab}/categories/{value}')
enum ProductCategory {
  electronics,

  @RdfEnumValue('books-media')
  booksAndMedia,

  clothing,

  @RdfEnumValue('home-garden')
  homeAndGarden,
}

/// Enum with multiple context variables for hierarchical vocabularies.
///
/// This demonstrates complex URI construction with:
/// - {+apiBase}: The API base URL (e.g., https://api.example.org)
/// - {version}: API version (e.g., v1, v2)
/// - {value}: The enum value
@RdfIri('{+apiBase}/{version}/shipping-methods/{value}')
enum ShippingMethod {
  standard,

  @RdfEnumValue('express-overnight')
  express,

  @RdfEnumValue('same-day-delivery')
  sameDay,

  @RdfEnumValue('pickup-in-store')
  pickup,
}

/// Enum showing mixed context and reserved expansion.
///
/// The template uses:
/// - {+orgNamespace}: Organization namespace with reserved chars (preserves slashes)
/// - {department}: Department code (percent-encoded)
/// - {value}: Enum value
@RdfIri('{+orgNamespace}/departments/{department}/roles/{value}')
enum EmployeeRole {
  manager,

  @RdfEnumValue('team-lead')
  teamLead,

  developer,

  @RdfEnumValue('quality-assurance')
  qualityAssurance,
}

// ==============================================================================
// Usage Examples (Annotations Only)
// ==============================================================================

/// Example showing how enums would be used in resource classes.
/// These demonstrate practical usage patterns with proper imports.
///
/// For enums using context variables (like ProductCategory, ShippingMethod, EmployeeRole),
/// the context variables would be provided in initRdfMapper:
///
/// ```dart
/// final rdfMapper = initRdfMapper(
///   baseVocabProvider: () => 'https://vocab.mycompany.com',
///   versionProvider: () => 'v2',
///   apiBaseProvider: () => 'https://api.mycompany.com',
///   orgNamespaceProvider: () => 'https://org.example.com/ns',
///   departmentProvider: () => 'engineering',
/// );
/// ```

@RdfGlobalResource(
  MyBookVocab.classIri,
  IriStrategy('http://example.org/books/{sku}'),
)
class Book {
  @RdfIriPart()
  final String sku;

  // Uses the enum's default @RdfLiteral mapping
  @RdfProperty(MyBookVocab.bookFormat)
  final BookFormat format;

  // Uses the enum's default @RdfIri mapping
  @RdfProperty(MyBookVocab.itemCondition)
  final ItemCondition condition;

  // Override with custom literal mapper for this property
  @RdfProperty(MyBookVocab.priority,
      literal: LiteralMapping.namedMapper('customPriorityMapper'))
  final Priority priority;

  // Apply language tag to enum literal for this property
  @RdfProperty(MyBookVocab.status, literal: LiteralMapping.withLanguage('en'))
  final ProductStatus status;

  Book({
    required this.sku,
    required this.format,
    required this.condition,
    required this.priority,
    required this.status,
  });
}

class MyBookVocab {
  static const String namespace = 'http://example.org/vocab/';
  static const IriTerm classIri = IriTerm('${namespace}Book');
  static const IriTerm bookFormat = IriTerm('${namespace}bookFormat');
  static const IriTerm itemCondition = IriTerm('${namespace}itemCondition');
  static const IriTerm priority = IriTerm('${namespace}priority');
  static const IriTerm status = IriTerm('${namespace}status');
}

// ==============================================================================
// Error Prevention Examples
// ==============================================================================

// The following patterns would cause compilation errors:

/*
// ERROR: Duplicate custom values
@RdfLiteral()
enum InvalidPriority {
  @RdfEnumValue('HIGH')
  high,
  
  @RdfEnumValue('HIGH') // ERROR: Duplicate value
  urgent,
}

// ERROR: Empty custom value
@RdfLiteral()
enum InvalidStatus {
  @RdfEnumValue('') // ERROR: Empty value not allowed
  unknown,
}

// ERROR: Missing @RdfLiteral or @RdfIri on enum
enum InvalidFormat { // ERROR: Enum must have @RdfLiteral or @RdfIri
  @RdfEnumValue('H')
  hardcover,
}
*/

/// This file demonstrates the core enum mapping capabilities.
/// For complete usage examples with full resource classes,
/// see the documentation and integration tests.

// ==============================================================================
// Simple Test Function
// ==============================================================================

/// Test function to demonstrate that all enums and classes work correctly.
void testEnumExamples() {
  // Test that all enums are accessible
  assert(BookFormat.values.length == 3);
  assert(Priority.values.length == 3);
  assert(ProductStatus.values.length == 3);
  assert(ItemCondition.values.length == 3);
  assert(OrderStatus.values.length == 4);
  assert(CurrencyCode.values.length == 4);
  assert(BusinessEntityType.values.length == 4);
  assert(UserRating.values.length == 5);
  assert(ProductCategory.values.length == 4);
  assert(ShippingMethod.values.length == 4);
  assert(EmployeeRole.values.length == 4);

  // Test that the Product class can be instantiated
  final product = Book(
    sku: 'TEST123',
    format: BookFormat.hardcover,
    condition: ItemCondition.brandNew,
    priority: Priority.high,
    status: ProductStatus.inStock,
  );

  assert(product.sku == 'TEST123');
  assert(product.format == BookFormat.hardcover);
  assert(product.condition == ItemCondition.brandNew);
  assert(product.priority == Priority.high);
  assert(product.status == ProductStatus.inStock);

  print('All enum examples work correctly!');
}

/// Main function to run the test
void main() {
  testEnumExamples();
}
