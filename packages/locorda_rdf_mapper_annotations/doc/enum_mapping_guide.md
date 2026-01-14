# Enum Mapping Guide

This guide explains how to use enum support in the `locorda_rdf_mapper` package with the `@RdfEnumValue`, `@RdfLiteral`, and `@RdfIri` annotations.

## Overview

The `locorda_rdf_mapper_annotations` package provides comprehensive support for mapping Dart enums to RDF literals and IRIs. This enables clean, type-safe enum usage while supporting domain-specific RDF vocabularies and standards.

## Key Features

- **Automatic enum mapping**: Apply `@RdfLiteral` or `@RdfIri` to enums for automatic mapper generation
- **Custom enum values**: Use `@RdfEnumValue` to override individual enum constant serialization
- **Seamless integration**: Enum properties work with all existing property-level mapping options
- **Validation**: Compile-time validation ensures proper usage and prevents common errors

## Basic Usage

### Literal Enum Mapping

Use `@RdfLiteral` to map enums to RDF literal values:

```dart
@RdfLiteral()
enum BookFormat {
  hardcover,  // → "hardcover"
  paperback,  // → "paperback"
  ebook,      // → "ebook"
}
```

### IRI Enum Mapping

Use `@RdfIri` with a template to map enums to IRI values:

```dart
@RdfIri('http://schema.org/{value}')
enum ItemCondition {
  brandNew,     // → <http://schema.org/brandNew>
  used,         // → <http://schema.org/used>
  refurbished,  // → <http://schema.org/refurbished>
}
```

### Advanced IRI Template Patterns

Enum IRI templates support context variables and reserved expansion for complex vocabulary structures:

```dart
import 'package:locorda_rdf_mapper_annotations/annotations.dart';

// Template with context variables
@RdfIri('{+baseUri}/categories/{category}/{value}')
enum ProductCategory {
  electronics, // → <https://example.org/categories/products/electronics>
  clothing,    // → <https://example.org/categories/products/clothing>
  books,       // → <https://example.org/categories/products/books>
}

// Template with custom enum values and context
@RdfIri('{+baseUri}/status/{environment}/{value}')
enum ServiceStatus {
  @RdfEnumValue('running-ok')
  running,     // → <https://api.example.org/status/prod/running-ok>
  
  @RdfEnumValue('down-error')
  down,        // → <https://api.example.org/status/prod/down-error>
  
  maintenance, // → <https://api.example.org/status/prod/maintenance>
}

// When registerGlobally is true (default), context variables become required providers:
final rdfMapper = initRdfMapper(
  baseUriProvider: () => 'https://example.org',
  categoryProvider: () => 'products',
  environmentProvider: () => 'prod',
);
```

**Template Variable Types:**
- `{value}` - The enum constant value (from `@RdfEnumValue` or enum name)
- `{variable}` - Context variables (percent-encoded for URI safety)
- `{+variable}` - Reserved expansion (preserves URI structure like `/`, `:`, `#`)

Context variables enable dynamic, environment-aware IRI patterns without hardcoding values in your enums.

## Custom Enum Values

Use `@RdfEnumValue` to customize individual enum constant serialization:

### Literal Custom Values

```dart
@RdfLiteral()
enum Priority {
  @RdfEnumValue('H')
  high,         // → "H"
  
  @RdfEnumValue('M')
  medium,       // → "M"
  
  @RdfEnumValue('L')
  low,          // → "L"
}
```

### IRI Custom Values

```dart
@RdfIri('http://schema.org/{value}')
enum ItemCondition {
  @RdfEnumValue('NewCondition')
  brandNew,     // → <http://schema.org/NewCondition>
  
  @RdfEnumValue('UsedCondition')
  used,         // → <http://schema.org/UsedCondition>
  
  refurbished,  // → <http://schema.org/refurbished>
}
```

### Mixed Patterns

You can mix custom and default values within the same enum:

```dart
@RdfLiteral()
enum ProductStatus {
  @RdfEnumValue('available')
  inStock,      // → "available"
  
  @RdfEnumValue('sold-out')
  outOfStock,   // → "sold-out"
  
  discontinued, // → "discontinued" (uses enum name)
}
```

## Integration with Resource Classes

Enums work seamlessly with resource mapping:

```dart
import 'package:locorda_rdf_mapper_annotations/annotations.dart';

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
  static const IriTerm bookFormat =
      IriTerm('${namespace}bookFormat');
  static const IriTerm itemCondition =
      IriTerm('${namespace}itemCondition');
  static const IriTerm priority = IriTerm('${namespace}priority');
  static const IriTerm status = IriTerm('${namespace}status');
}
```

## Property-Level Overrides

You can override enum mapping at the property level:

### Custom Mappers

```dart
@RdfProperty(
  IriTerm('http://example.org/status'),
  literal: LiteralMapping.namedMapper('customStatusMapper')
)
final Status status;
```

### Language Tags (Requires Global Enum Mapper)

**Important**: `LiteralMapping.withLanguage` and `LiteralMapping.withType` delegate to the existing registered mapper for the property type. Therefore, the enum must be annotated with `@RdfLiteral` (with `registerGlobally: true`, which is the default) for these overrides to work, or must have a manually registered custom mapper.

```dart
// First, ensure the enum has a global mapper
@RdfLiteral() // This registers a global mapper
enum LocalizedStatus {
  @RdfEnumValue('active')
  active,
  
  @RdfEnumValue('inactive') 
  inactive,
}

// Then you can use language tag override
@RdfProperty(
  IriTerm('http://example.org/condition'),
  literal: LiteralMapping.withLanguage('en')
)
final LocalizedStatus condition; // Uses the global enum mapper + adds @en language tag
```

### Custom Datatypes (Requires Global Enum Mapper)

Similarly, custom datatypes work by delegating to the registered enum mapper:

```dart
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';

// Enum with global mapper
@RdfLiteral()
enum Priority {
  @RdfEnumValue('HIGH')
  high,
  
  @RdfEnumValue('MEDIUM')
  medium,
  
  @RdfEnumValue('LOW')
  low,
}

// Property using custom datatype
@RdfProperty(
  IriTerm('http://example.org/priority'),
  literal: LiteralMapping.withType(Xsd.string)
)
final Priority priority; // Uses enum mapper result + applies xsd:string datatype
```

### For Enums Without Global Mappers

If your enum uses `registerGlobally: false`, you cannot use `.withLanguage()` or `.withType()` because there's no global mapper to delegate to. Instead, use a custom mapper:

```dart
@RdfLiteral(registerGlobally: false)
enum LocalEnum {
  @RdfEnumValue('A')
  first,
  
  @RdfEnumValue('B')
  second,
}

// This would NOT work - no global mapper to delegate to:
// @RdfProperty(IriTerm('http://example.org/value'), literal: LiteralMapping.withLanguage('en'))
// final LocalEnum value;

// Instead, use a custom mapper:
@RdfProperty(
  IriTerm('http://example.org/value'),
  literal: LiteralMapping.namedMapper('localEnumMapperWithLanguage')
)
final LocalEnum value;
```

## Understanding Property-Level Mapping Delegation

It's crucial to understand how different `LiteralMapping` constructors work:

### Direct Mapper Constructors (No Delegation)
These constructors completely replace the mapping logic:
- `LiteralMapping.namedMapper()` - Uses a custom mapper you provide
- `LiteralMapping.mapper()` - Instantiates a mapper type you specify
- `LiteralMapping.mapperInstance()` - Uses a pre-configured mapper instance

### Delegating Constructors (Require Existing Mapper)
These constructors enhance an existing mapper by modifying its output:
- `LiteralMapping.withLanguage()` - Uses existing mapper + adds language tag
- `LiteralMapping.withType()` - Uses existing mapper + changes datatype

**For enums**: The delegating constructors require the enum to have a globally registered mapper (i.e., `@RdfLiteral()` with default `registerGlobally: true`).

## Advanced Examples

### Currency Codes

```dart
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
```

### Hierarchical Vocabularies

```dart
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
```

### Rating Systems

```dart
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
```

### Advanced IRI Template Patterns

Enum IRI templates support context variables and reserved expansion for complex vocabulary structures:

```dart
import 'package:locorda_rdf_mapper_annotations/annotations.dart';

// Template with context variables
@RdfIri('{+baseUri}/categories/{category}/{value}')
enum ProductCategory {
  electronics, // → <https://example.org/categories/products/electronics>
  clothing,    // → <https://example.org/categories/products/clothing>
  books,       // → <https://example.org/categories/products/books>
}

// Template with custom enum values and context
@RdfIri('{+baseUri}/status/{environment}/{value}')
enum ServiceStatus {
  @RdfEnumValue('running-ok')
  running,     // → <https://api.example.org/status/prod/running-ok>
  
  @RdfEnumValue('down-error')
  down,        // → <https://api.example.org/status/prod/down-error>
  
  maintenance, // → <https://api.example.org/status/prod/maintenance>
}

// When registerGlobally is true (default), context variables become required providers:
final rdfMapper = initRdfMapper(
  baseUriProvider: () => 'https://example.org',
  categoryProvider: () => 'products',
  environmentProvider: () => 'prod',
);
```

**Template Variable Types:**
- `{value}` - The enum constant value (from `@RdfEnumValue` or enum name)
- `{variable}` - Context variables (percent-encoded for URI safety)
- `{+variable}` - Reserved expansion (preserves URI structure like `/`, `:`, `#`)

Context variables enable dynamic, environment-aware IRI patterns without hardcoding values in your enums.

## Validation Rules

The code generator enforces these validation rules:

### Enum-Level Rules

- Enums must be annotated with either `@RdfLiteral` or `@RdfIri`
- Cannot use both `@RdfLiteral` and `@RdfIri` on the same enum
- IRI templates must contain the `{value}` placeholder when used with enums

### RdfEnumValue Rules

- Can only be applied to enum constants
- Custom values must be unique within the same enum
- Custom values cannot be empty or contain only whitespace
- For IRI enums, custom values must be valid IRI path segments

### Property Rules

- Enum properties can use any property-level mapping override
- Property-level mappers take precedence over class-level mappings
- Multiple properties can reference the same enum with different mappings
- `LiteralMapping.withLanguage()` and `LiteralMapping.withType()` require the enum to have a globally registered mapper
- If an enum uses `registerGlobally: false` or is not annotated at all, only direct mapper constructors (`.namedMapper()`, `.mapper()`, `.mapperInstance()`) can be used for property-level overrides

## Error Prevention

### Common Mistakes

```dart
// ❌ ERROR: Missing enum annotation
enum InvalidFormat {
  @RdfEnumValue('H')
  hardcover,
}

// ❌ ERROR: Duplicate custom values
@RdfLiteral()
enum InvalidPriority {
  @RdfEnumValue('HIGH')
  high,
  
  @RdfEnumValue('HIGH') // Duplicate!
  urgent,
}

// ❌ ERROR: Empty custom value
@RdfLiteral()
enum InvalidStatus {
  @RdfEnumValue('') // Empty!
  unknown,
}

// ❌ ERROR: Using @RdfEnumValue on non-enum
@RdfLiteral()
class InvalidClass {
  @RdfEnumValue('value') // Not allowed on classes!
  String property;
}
```

### Best Practices

- Use descriptive enum constant names in your Dart code
- Keep custom values short but meaningful for better RDF readability
- Use consistent naming patterns across related enums
- For IRI enums, follow URI naming conventions (lowercase, hyphens over underscores)
- Align custom values with domain vocabularies when possible
- Consider backward compatibility when changing custom values

## Integration with locorda_rdf_mapper_generator

When you use these annotations, the `locorda_rdf_mapper_generator` package will:

1. **Generate enum mappers**: Create `LiteralTermMapper<EnumType>` or `IriTermMapper<EnumType>` implementations
2. **Handle custom values**: Use `@RdfEnumValue` annotations to determine serialization values
3. **Register globally**: Add enum mappers to the global registry (unless `registerGlobally: false`)
4. **Validate usage**: Ensure proper annotation usage and provide helpful error messages
5. **Support round-trip**: Generate both serialization and deserialization logic

## Migration from Manual Enum Handling

If you previously handled enums manually with custom mapper classes, migration is straightforward:

### Before (Manual)

Previously, you had to implement a full custom mapper class extending the base mapper:

```dart
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';

// Define your enum without annotations
enum Priority {
  high,
  medium,
  low,
}

// Implement a full custom mapper class
class PriorityMapper extends BaseRdfLiteralTermMapper<Priority> {
  const PriorityMapper({IriTerm? datatype}) : super(datatype: datatype ?? Xsd.string);

  @override
  Priority convertFromLiteral(LiteralTerm term, DeserializationContext context) {
    switch (term.value) {
      case 'H':
        return Priority.high;
      case 'M':
        return Priority.medium;
      case 'L':
        return Priority.low;
      default:
        throw ArgumentError('Unknown priority literal: ${term.value}');
    }
  }

  @override
  String convertToString(Priority value) {
    switch (value) {
      case Priority.high:
        return 'H';
      case Priority.medium:
        return 'M';
      case Priority.low:
        return 'L';
    }
  }
}

// Manual registration
final rdfMapper = initRdfMapper();
rdfMapper.registerMapper<Priority>(const PriorityMapper());
```

### After (Annotations)

Now, you simply annotate the enum and the mapper is generated automatically:

```dart
@RdfLiteral()
enum Priority {
  @RdfEnumValue('H')
  high,
  
  @RdfEnumValue('M')
  medium,
  
  @RdfEnumValue('L')
  low,
}

// The mapper is automatically generated and registered by initRdfMapper()
final rdfMapper = initRdfMapper(); // Priority mapper included automatically
```

### IRI Enum Migration Example

For IRI-based enums, the manual approach was even more complex:

#### Before (Manual IRI Mapper)

```dart
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';

// Define your enum without annotations
enum ItemCondition {
  brandNew,
  used,
  refurbished,
}

// Implement a full custom IRI mapper class
class ItemConditionMapper extends BaseRdfIriTermMapper<ItemCondition> {
  const ItemConditionMapper() : super('http://schema.org/{value}', 'value');

  @override
  ItemCondition convertFromString(String valueString) {
    switch (valueString) {
      case 'NewCondition':
        return ItemCondition.brandNew;
      case 'UsedCondition':
        return ItemCondition.used;
      case 'refurbished':
        return ItemCondition.refurbished;
      default:
        throw ArgumentError('Unknown condition value: $valueString');
    }
  }

  @override
  String convertToString(ItemCondition value) {
    switch (value) {
      case ItemCondition.brandNew:
        return 'NewCondition';
      case ItemCondition.used:
        return 'UsedCondition';
      case ItemCondition.refurbished:
        return 'refurbished';
    }
  }
}

// Manual registration
final rdfMapper = initRdfMapper();
rdfMapper.registerMapper<ItemCondition>(const ItemConditionMapper());
```

#### After (Annotations)

```dart
@RdfIri('http://schema.org/{value}')
enum ItemCondition {
  @RdfEnumValue('NewCondition')
  brandNew,
  
  @RdfEnumValue('UsedCondition')
  used,
  
  refurbished, // Uses enum constant name
}

// The mapper is automatically generated and registered by initRdfMapper()
final rdfMapper = initRdfMapper(); // ItemCondition mapper included automatically
```

The generator handles all the conversion logic automatically.

## Performance Considerations

- Enum mappers are generated at compile-time, so there's no runtime reflection overhead
- Enum value lookup uses efficient switch statements or maps
- Custom values are resolved at generation time, not runtime
- Round-trip conversions are optimized for common enum patterns

## Conclusion

Enum support in `locorda_rdf_mapper` provides a clean, type-safe way to work with controlled vocabularies and standardized value sets in RDF. The combination of automatic mapping generation and flexible customization options makes it easy to integrate domain-specific enums into your RDF data models while maintaining clean, readable Dart code.

For more examples, see the `example/enum_mapping_simple.dart` file in this package.
