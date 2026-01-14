# RDF Mapper Generator for Dart

[![pub package](https://img.shields.io/pub/v/locorda_rdf_mapper_generator.svg)](https://pub.dev/packages/locorda_rdf_mapper_generator)
[![build](https://github.com/kkalass/locorda_rdf_mapper_generator/actions/workflows/ci.yml/badge.svg)](https://github.com/kkalass/locorda_rdf_mapper_generator/actions)
[![codecov](https://codecov.io/gh/kkalass/locorda_rdf_mapper_generator/branch/main/graph/badge.svg)](https://codecov.io/gh/kkalass/locorda_rdf_mapper_generator)
[![license](https://img.shields.io/github/license/kkalass/locorda_rdf_mapper_generator.svg)](https://github.com/kkalass/locorda_rdf_mapper_generator/blob/main/LICENSE)

**Transform your Dart classes into RDF mappers with zero boilerplate!** 🚀

A code generator for creating **type-safe, annotation-driven RDF mappers** in Dart. Simply annotate your classes, run `dart run build_runner build`, and get generated mappers that seamlessly convert between your Dart objects and RDF data.

## ✨ Key Features

- **🔥 Zero Boilerplate**: Write business logic, not serialization code
- **🛡️ Type Safety**: Compile-time guarantees for your RDF mappings  
- **⚡ Optimized Generation**: Generated code with no runtime overhead
- **🎯 Schema.org Support**: Works with vocabularies from rdf_vocabularies
- **🔧 Flexible Mapping**: Custom mappers, IRI templates, and complex relationships
- **🔄 Lossless Mapping**: Preserve unmapped triples with `@RdfUnmappedTriples` for round-trip data integrity
- **🏗️ Build System Integration**: Seamless integration with build_runner

[🌐 **Official Documentation**](https://kkalass.github.io/locorda_rdf_mapper_generator/)

## 🚀 Quick Start

### 1. Add Dependencies

```yaml
dependencies:
  locorda_rdf_mapper: ^0.10.2
  locorda_rdf_mapper_annotations: ^0.10.2
  rdf_vocabularies: ^0.4.0

dev_dependencies:
  build_runner: '>2.5.3'
  locorda_rdf_mapper_generator: ^0.10.5
```

### 2. Annotate Your Classes

```dart
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:rdf_vocabularies/schema.dart';

@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('https://example.org/books/{isbn}'),
)
class Book {
  @RdfIriPart()
  final String isbn;

  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfProperty(SchemaBook.author)
  final String author;

  @RdfProperty(SchemaBook.datePublished)
  final DateTime published;

  Book({
    required this.isbn,
    required this.title, 
    required this.author,
    required this.published,
  });
}
```

### 3. Generate Mappers

```bash
dart run build_runner build
```

### 4. Use Your Generated Mappers

```dart
// Initialize the mapper system
final mapper = initRdfMapper();

// Convert Dart object to RDF
final book = Book(
  isbn: '978-0-544-00341-5',
  title: 'The Hobbit',
  author: 'J.R.R. Tolkien',
  published: DateTime(1937, 9, 21),
);

final turtle = mapper.encodeObject(book);
print('Book as RDF: ${turtle}');

// Convert RDF back to Dart object
final deserializedBook = mapper.decodeObject<Book>(turtle);
print('Title: ${deserializedBook.title}');
// Output: Title: The Hobbit

// For lossless round-trip preservation, use the lossless API:
final (bookFromRdf, remainder) = mapper.decodeObjectLossless<Book>(complexRdfData);
final roundTripData = mapper.encodeObjectLossless((bookFromRdf, remainder));
```

**That's it!** No manual mapping code, no runtime reflection, just pure generated performance.

## 🎯 What Makes This Useful?

### Advanced Features That Work

#### 🔗 Flexible IRI Generation
```dart
@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('{+baseUrl}/books/{isbn}'),
)
class Book {
  @RdfIriPart()
  final String isbn;
  
  // baseUrl comes from context - useful for configurable deployments, 
  // must be a vaild URL like 'https://library.org/'
}
```

#### 🗂️ Complex Collections  
```dart
@RdfProperty(SchemaBook.keywords)
final Set<String> keywords;  // Automatic set handling

@RdfProperty(SchemaBook.reviews)
@RdfMapEntry(ReviewEntry)
final Map<String, Review> reviews;  // Custom map entry types
```

#### 🏷️ Custom Literal Types
```dart
@RdfLiteral()
class Temperature {
  @RdfValue()
  final double celsius;
  
  // Custom serialization with type safety
  LiteralTerm formatCelsius() => LiteralTerm('${celsius}°C');
}
```

#### 🔄 Enum Mapping
```dart
@RdfIri('https://schema.org/BookFormatType/{value}')
enum BookFormat {
  @RdfEnumValue('Hardcover')
  hardcover,
  
  @RdfEnumValue('Paperback') 
  paperback,
  
  @RdfEnumValue('EBook')
  ebook,
}
```

#### 🌐 Multi-Language Support
```dart
@RdfProperty(
  SchemaBook.description,
  literal: LiteralMapping.withLanguage('en'),
)
final String description;
```

### What Gets Generated (Automatically!)

For each annotated class, you get:
- **Type-safe serialization/deserialization**
- **Optimized IRI pattern matching** with regex
- **Smart default value handling**
- **Collection type inference**
- **Custom mapper integration**
- **Null safety throughout**
- **Performance-optimized code**

## 🏗️ Architecture Overview

### Perfect Integration
Part of a complete **RDF ecosystem for Dart**:

| Package | Purpose | Latest Version |
|---------|---------|----------------|
| [**locorda_rdf_core**](https://pub.dev/packages/locorda_rdf_core) | Core graph classes, serialization (Turtle, JSON-LD, N-Triples) | ![pub](https://img.shields.io/pub/v/locorda_rdf_core.svg) |
| [**locorda_rdf_mapper**](https://pub.dev/packages/locorda_rdf_mapper) | Runtime mapping system between Dart objects and RDF | ![pub](https://img.shields.io/pub/v/locorda_rdf_mapper.svg) |
| [**locorda_rdf_mapper_annotations**](https://pub.dev/packages/locorda_rdf_mapper_annotations) | Annotation definitions for mapping configuration | ![pub](https://img.shields.io/pub/v/locorda_rdf_mapper_annotations.svg) |
| [**locorda_rdf_mapper_generator**](https://pub.dev/packages/locorda_rdf_mapper_generator) | **This package** - Code generator for mappers | ![pub](https://img.shields.io/pub/v/locorda_rdf_mapper_generator.svg) |
| [**rdf_vocabularies**](https://pub.dev/packages/rdf_vocabularies) | Constants for Schema.org, FOAF, Dublin Core, etc. | ![pub](https://img.shields.io/pub/v/rdf_vocabularies.svg) |
| [**locorda_rdf_xml**](https://pub.dev/packages/locorda_rdf_xml) | RDF/XML format support | ![pub](https://img.shields.io/pub/v/locorda_rdf_xml.svg) |

### The Build Process
1. **Scan** your code for RDF annotations
2. **Analyze** types, relationships, and mapping requirements  
3. **Generate** optimized mapper classes with zero runtime overhead
4. **Validate** mappings at compile time
5. **Register** mappers automatically in your initialization code

## 📋 Comprehensive Feature Matrix

| Feature | Supported | Example |
|---------|-----------|---------|
| ✅ Global Resources | ✓ | `@RdfGlobalResource(Schema.Book)` |
| ✅ Local Resources (Blank Nodes) | ✓ | `@RdfLocalResource(Schema.Chapter)` |
| ✅ IRI Templates | ✓ | `IriStrategy('https://api.com/{version}/books/{id}')` |
| ✅ Context Variables | ✓ | `{+baseUri}`, `{category}` |
| ✅ Custom Literal Types | ✓ | `@RdfLiteral()` with `@RdfValue()` |
| ✅ Enum Mappings | ✓ | `@RdfIri()` and `@RdfLiteral()` on enums |
| ✅ Collection Types | ✓ | `List<T>`, `Set<T>`, `Map<K,V>` |
| ✅ Map Entry Resources | ✓ | `@RdfMapEntry()` with `@RdfMapKey/@RdfMapValue` |
| ✅ Language Tags | ✓ | `LiteralMapping.withLanguage('en')` |
| ✅ Custom Datatypes | ✓ | `LiteralMapping(datatype: XSD.dateTime)` |
| ✅ Default Values | ✓ | `@RdfProperty(predicate, defaultValue: 'default')` |
| ✅ Optional Properties | ✓ | Nullable types with smart handling |
| ✅ Lossless Mapping | ✓ | `@RdfUnmappedTriples()` for round-trip preservation |
| ✅ Named Mappers | ✓ | `LiteralMapping.namedMapper('myMapper')` |
| ✅ Mapper Instances | ✓ | `LiteralMapping.mapperInstance(MyMapper())` |
| ✅ Provider Functions | ✓ | Dynamic context through provider functions |
| ✅ Null Safety | ✓ | Full null safety throughout |

## 📖 Complete Examples

### E-commerce Product Catalog
```dart
@RdfGlobalResource(
  SchemaProduct.classIri,
  IriStrategy('https://store.example.com/products/{sku}'),
)
class Product {
  @RdfIriPart()
  final String sku;

  @RdfProperty(SchemaProduct.name)
  final String name;

  @RdfProperty(SchemaProduct.offers)
  final List<Offer> offers;

  @RdfProperty(SchemaProduct.brand)
  final Brand brand;

  @RdfProperty(SchemaProduct.aggregateRating)
  final AggregateRating? rating;

  Product({...});
}

@RdfLocalResource(SchemaOffer.classIri)
class Offer {
  @RdfProperty(SchemaOffer.price)
  final double price;

  @RdfProperty(SchemaOffer.priceCurrency)
  final Currency currency;

  @RdfProperty(SchemaOffer.availability)
  final ProductAvailability availability;
}

@RdfIri('https://schema.org/ItemAvailability/{value}')
enum ProductAvailability {
  @RdfEnumValue('InStock')
  inStock,
  
  @RdfEnumValue('OutOfStock') 
  outOfStock,
  
  @RdfEnumValue('PreOrder')
  preOrder,
}
```

### Scientific Data with Custom Types
```dart
@RdfLiteral(datatype: 'https://units.org/Temperature')
class Temperature {
  @RdfValue()
  final double celsius;

  LiteralTerm formatCelsius() => 
    LiteralTerm('${celsius}°C', datatype: const IriTerm('https://units.org/Temperature'));
    
  static Temperature parse(LiteralTerm term) => 
    Temperature(double.parse(term.value.replaceAll('°C', '')));
}

@RdfGlobalResource(
  'https://science.org/Measurement',
  IriStrategy('https://lab.org/measurements/{id}'),
)
class Measurement {
  @RdfIriPart()
  final String id;

  @RdfProperty('https://science.org/temperature')
  final Temperature temperature;

  @RdfProperty('https://science.org/timestamp')
  final DateTime timestamp;

  @RdfProperty(
    'https://science.org/location',
    iri: IriMapping('https://geo.org/{latitude},{longitude}'),
  )
  final String coordinates;
}
```

## 🔄 Lossless Round-Trip Mapping

RDF Mapper Generator supports **lossless round-trip mapping** where you can preserve all RDF data, even triples that aren't mapped to explicit properties. This is crucial for data pipelines, ETL operations, and scenarios where you cannot afford to lose any RDF information.

### Basic Lossless Mapping

```dart
@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('https://example.org/books/{isbn}'),
)
class Book {
  @RdfIriPart()
  final String isbn;

  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfProperty(SchemaBook.author)
  final String author;

  // Capture all unmapped triples
  @RdfUnmappedTriples()
  final RdfGraph unmappedTriples;

  Book({
    required this.isbn,
    required this.title,
    required this.author,
    required this.unmappedTriples,
  });
}
```

### Understanding Lossless Mapping

Lossless mapping provides two complementary mechanisms:

1. **@RdfUnmappedTriples annotation**: Captures unmapped triples for a specific resource
2. **decodeObjectLossless method**: Returns both the mapped object and all remaining document triples

### Concrete Example

Consider this RDF data:
```turtle
@prefix schema: <https://schema.org/> .
@prefix ex: <https://example.org/> .

ex:book123 a schema:Book ;
  schema:name "The Dart Guide" ;
  schema:author "Jane Developer" ;
  schema:isbn "978-0123456789" ;
  schema:publisher "Tech Press" ;          # Not mapped to Book class
  schema:datePublished "2023-01-01" ;      # Not mapped to Book class
  ex:internalId "B123" ;                   # Custom property not mapped
  ex:lastModified "2023-12-01T10:00:00Z" . # Custom property not mapped

ex:event123 a schema:Event ;              # Unrelated resource
  schema:name "Book Launch" ;
  schema:startDate "2023-01-15" .
```

**Standard decoding** (`decodeObject`):
```dart
// With strict mode (default) - throws exception due to unmapped triples
try {
  final book = mapper.decodeObject<Book>(rdfData);
} catch (IncompleteDeserializationException e) {
  // Exception thrown because of unmapped triples
}

// With lenient mode - discards unmapped data
final book = mapper.decodeObject<Book>(rdfData, 
    completenessMode: CompletenessMode.lenient);
// book.isbn = "978-0123456789"
// book.title = "The Dart Guide"  
// book.author = "Jane Developer"
// book.unmappedTriples contains:
//   - ex:book123 schema:publisher "Tech Press"
//   - ex:book123 schema:datePublished "2023-01-01"  
//   - ex:book123 ex:internalId "B123"
//   - ex:book123 ex:lastModified "2023-12-01T10:00:00Z"
// Note: Event triples are discarded (not about this book)
```

**Lossless decoding** (`decodeObjectLossless`):
```dart
final (book, remainder) = mapper.decodeObjectLossless<Book>(rdfData);
// book.isbn = "978-0123456789"
// book.title = "The Dart Guide"
// book.author = "Jane Developer"
// book.unmappedTriples contains triples about the book that weren't mapped
// remainder contains ALL other triples from the document:
//   - ex:event123 a schema:Event
//   - ex:event123 schema:name "Book Launch"
//   - ex:event123 schema:startDate "2023-01-15"
```

### Perfect Round-Trip Preservation

```dart
// Load RDF data losslessly - returns (object, remainder)
final (originalBook, remainder) = mapper.decodeObjectLossless<Book>(originalRdfData);

// Modify only the mapped properties
final updatedBook = originalBook.copyWith(
  author: 'Jane Developer, PhD',
);

// Encode back to RDF with remainder - preserves complete document
final updatedRdfData = mapper.encodeObjectLossless((updatedBook, remainder));
// updatedRdfData contains both the updated book AND all unrelated triples
```

### Use Cases

**Data Pipeline Operations**:
```dart
// Load from one RDF source with lossless decoding
final productRdfData = await loadProductsFromWarehouse();
final (products, remainder) = mapper.decodeObjectsLossless<Product>(productRdfData);

// Process only the mapped fields
final processedProducts = products.map((p) => 
  p.copyWith(price: applyDiscount(p.price))).toList();

// Save to another RDF store - no data loss
final updatedRdfData = mapper.encodeObjectsLossless((processedProducts, remainder));
await saveProductsToStore(updatedRdfData);
```

**ETL with Unknown Schemas**:
```dart
// When source RDF contains more properties than your model knows about
final (enrichedData, remainder) = mapper.decodeObjectLossless<BasicProduct>(sourceRdf);
// Process known properties, preserve unknown ones
final processed = enrichedData.copyWith(category: deriveCategory(enrichedData.name));
// Output contains both processed AND original unknown properties
final outputRdf = mapper.encodeObjectLossless((processed, remainder));
```

### Validation and Requirements

- **Type Safety**: `@RdfUnmappedTriples` fields must be of a type that has a registered `UnmappedTriplesMapper` (e.g., `RdfGraph` by default)
- **Uniqueness**: Only one `@RdfUnmappedTriples` field per class
- **Serialization**: Unmapped triples are automatically included during encoding

```dart
// ❌ Invalid - no UnmappedTriplesMapper registered for List<String>
@RdfUnmappedTriples()
final List<String> unmapped; // Error: No UnmappedTriplesMapper for List<String>

// ❌ Invalid - multiple fields  
@RdfUnmappedTriples()
final RdfGraph unmapped1;
@RdfUnmappedTriples()
final RdfGraph unmapped2; // Error: Only one @RdfUnmappedTriples field allowed

// ✅ Valid - RdfGraph has a built-in UnmappedTriplesMapper
@RdfUnmappedTriples()
final RdfGraph unmappedTriples;

// ✅ Valid - custom type with registered UnmappedTriplesMapper
@RdfUnmappedTriples()
final MyCustomGraph customGraph;
```

## 🛠️ Advanced Configuration

### Build Configuration (`build.yaml`)
```yaml
targets:
  $default:
    builders:
      locorda_rdf_mapper_generator:locorda_rdf_mapper_generator:
        generate_for:
          - lib/**.dart
        options:
          # Generator options
```

### Context Providers for Dynamic Mapping
```dart
final mapper = initRdfMapper(
  // Dynamic base URIs for multi-tenant applications
  baseUriProvider: () => getCurrentTenant().baseUri,
  
  // API versioning
  versionProvider: () => 'v2',
  
  // User-specific contexts
  userIdProvider: () => getCurrentUser().id,
);
```

## 🚀 Performance & Production Ready

### Why This Approach Works
- **Zero runtime overhead**: All mapping logic generated at compile time
- **Tree-shakeable**: Only used mappers included in final build  
- **Type-safe**: Compile-time validation of all mappings
- **Optimized patterns**: Smart regex generation for IRI parsing
- **Null safety**: Full null safety with smart default handling

## 🎓 Learning Resources

### 🎯 Real Examples
- [**Full Book Example**](test/fixtures/locorda_rdf_mapper_annotations/examples/example_full_book.dart) - Complete Schema.org Book with chapters
- [**CRDT Item Example**](test/fixtures/locorda_rdf_mapper_annotations/examples/example_crdt_item.dart) - Distributed systems with vector clocks  
- [**Enum Mapping Examples**](test/fixtures/locorda_rdf_mapper_annotations/examples/enum_mapping_simple.dart) - All enum mapping patterns
- [**IRI Strategy Examples**](test/fixtures/locorda_rdf_mapper_annotations/examples/example_iri_strategies.dart) - Dynamic IRI generation

### 🧪 Try It
```bash
# Clone and explore examples
git clone https://github.com/kkalass/locorda_rdf_mapper_generator.git
cd locorda_rdf_mapper_generator
dart pub get
dart run build_runner build

# Run comprehensive tests
dart test

# Explore the generated mappers
find test/fixtures/locorda_rdf_mapper_annotations/examples -name "*.locorda_rdf_mapper.g.dart"
# Look at specific generated files:
# - test/fixtures/locorda_rdf_mapper_annotations/examples/provides.locorda_rdf_mapper.g.dart
# - test/fixtures/locorda_rdf_mapper_annotations/examples/example_full_book.locorda_rdf_mapper.g.dart  
# - test/fixtures/locorda_rdf_mapper_annotations/examples/enum_mapping_simple.locorda_rdf_mapper.g.dart
```

## 🛣️ Roadmap & Evolution

### Current: v0.2.2 ✅
- ✅ Full annotation support (global/local resources, literals, IRIs)
- ✅ Complex IRI templates with context variables
- ✅ Custom mapper integration (named, by type, by instance)
- ✅ Collection support (List, Set, Map with custom entry types)
- ✅ Enum mappings (both IRI and literal)
- ✅ Language tag support
- ✅ Comprehensive test coverage
- ✅ Null safety throughout
- ✅ Support for lossless RDF mapping

### Next: v0.3.0 🎯
- 🔄 Enhanced validation with helpful error messages
- 🔄 Documentation improvements
- 🔄 Support "proper" rdf Lists (e.g. with `rdf:first`, `rdf:rest`, `rdf:nil` )
- 🔄 Support rdf Container (rdf:Bag / rdf:Seq etc)

### Future: v1.0.0 🌟
- 🌟 Stable API guarantee
- 🌟 Advanced inheritance support

## 🤝 Contributing

**We'd love your help making this even better!**

### Get Started
```bash
git clone https://github.com/kkalass/locorda_rdf_mapper_generator.git
cd locorda_rdf_mapper_generator
dart pub get
dart test
```

### Ways to Contribute
- 🐛 **Bug Reports**: Found an issue? [Open an issue](https://github.com/kkalass/locorda_rdf_mapper_generator/issues)
- 💡 **Feature Requests**: Have ideas? [Start a discussion](https://github.com/kkalass/locorda_rdf_mapper_generator/discussions)
- 📝 **Documentation**: Help improve our docs
- 🧪 **Examples**: Add real-world usage examples
- ⚡ **Performance**: Help optimize generated code
- 🔧 **Testing**: Expand our test coverage

### Guidelines
- See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines
- Follow Dart conventions and best practices
- Add tests for new features
- Update documentation for API changes

## 🏆 Project Status

### Development Milestones
- **First functional release**: Successfully generating working mappers
- **Test applications**: Used in experimental projects for validation
- **Growing feature set**: Continuous addition of mapping capabilities

### Community Impact
- **Zero-boilerplate RDF**: Novel approach in Dart ecosystem
- **Type-safe mapping**: Advancing RDF tooling standards  
- **Open development**: Transparent development process
- **Real-world validation**: Tested with actual use cases


## 🤖 AI Policy

This project combines **human expertise with AI assistance**:

- **Human-led**: All architectural decisions, code reviews, and design choices made by humans
- **AI-enhanced**: Leveraging LLMs for code generation, documentation, and testing
- **Quality-focused**: AI helps iterate faster while maintaining high standards
- **Innovation-driven**: Using available tools to build better software

*The future of development is human creativity enhanced by AI capabilities.*

---


## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

**© 2025 Klas Kalaß** - Built with ❤️ for the Dart & RDF communities.

---

⭐ **Star this repo** if it helped you build something awesome!

[**🌐 Documentation**](https://kkalass.github.io/locorda_rdf_mapper_generator/) • [**📦 pub.dev**](https://pub.dev/packages/locorda_rdf_mapper_generator) • [**🐛 Issues**](https://github.com/kkalass/locorda_rdf_mapper_generator/issues) 
