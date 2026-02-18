# RDF Mapper Annotations for Dart

> **🎯 Code Generation Now Available**  
> This library provides the annotation system for mapping Dart objects to RDF graphs. Use it with the `locorda_rdf_mapper_generator` package to automatically generate type-safe mapping code from your annotated classes.

[![pub package](https://img.shields.io/pub/v/locorda_rdf_mapper_annotations.svg)](https://pub.dev/packages/locorda_rdf_mapper_annotations)
[![license](https://img.shields.io/badge/license-MIT-blue.svg))](https://github.com/locorda/rdf/blob/main/packages/locorda_rdf_mapper_annotations/LICENSE)

A powerful, declarative annotation system for seamless mapping between Dart objects and RDF graphs.

## Overview

[🌐 **Official Homepage**](https://locorda.dev/rdf/mapper/annotations)

`locorda_rdf_mapper_annotations` provides the annotation system for declaring how to map between Dart objects and RDF data, similar to how an ORM works for databases. These annotations are processed by the `locorda_rdf_mapper_generator` package to generate the actual mapping code at build time.

**To use these annotations:**
1. Annotate your Dart classes with the provided RDF annotations
2. Run the `locorda_rdf_mapper_generator` code generator to create mapping code
3. Use the generated mappers to serialize/deserialize between Dart objects and RDF formats

With this declarative approach, you can define how your domain model maps to RDF without writing boilerplate serialization code.

### Key Features

- **Declarative annotations** for clean, maintainable code
- **Type-safe mapping** between Dart classes and RDF resources
- **Support for code generation** (via locorda_rdf_mapper_generator)
- **Lossless RDF mapping** with `@RdfUnmappedTriples` - both subject-scoped and global document-level preservation
- **Flexible IRI generation strategies** for resource identification
- **Comprehensive collection support** for lists, sets, and maps
- **Native enum support** with custom values and IRI templates
- **Extensible architecture** through custom mappers

## Part of a Family of Projects

This library is part of a comprehensive ecosystem for working with RDF in Dart:

* [locorda_rdf_core](https://github.com/locorda/rdf/tree/main/packages/locorda_rdf_core) - Core graph classes and serialization (Turtle, JSON-LD, N-Triples)
* [locorda_rdf_mapper](https://github.com/locorda/rdf/tree/main/packages/locorda_rdf_mapper) - Base mapping system between Dart objects and RDF
* [locorda_rdf_mapper_generator](https://github.com/locorda/rdf/tree/main/packages/locorda_rdf_mapper_generator) - Code generator for this annotation library
* [locorda_rdf_terms](https://github.com/locorda/rdf-vocabularies/tree/main/packages/locorda_rdf_terms) - Constants for common RDF vocabularies (Schema.org, FOAF, etc.)
* [locorda_rdf_xml](https://github.com/locorda/rdf/tree/main/packages/locorda_rdf_xml) - RDF/XML format support
* [locorda_rdf_terms_generator](https://github.com/locorda/rdf/tree/main/packages/locorda_rdf_terms_generator) - Generate constants for custom vocabularies

## What is RDF?

[Resource Description Framework (RDF)](https://www.w3.org/RDF/) is a standard model for data interchange on the Web. RDF represents information as simple statements in the form of subject-predicate-object triples.

**Think of it like this:** Instead of storing data in tables (like SQL) or nested objects (like JSON), RDF stores data as simple facts:
- "Alice" (subject) "knows" (predicate) "Bob" (object)
- "Book #123" (subject) "has title" (predicate) "The Great Gatsby" (object)
- "Book #123" (subject) "has author" (predicate) "F. Scott Fitzgerald" (object)

This library lets you work with RDF data using familiar Dart objects without needing to manage triples directly.

### Key RDF Terms

To better understand this library, it's helpful to know these core RDF concepts:

- **Triple**: The basic building block - three parts that make one statement. For example: `(Book #123, has-title, "The Great Gatsby")`

- **IRI** (International Resource Identifier): A globally unique web address for a thing, like `https://example.org/books/123`. Similar to URLs but more flexible. In RDF, IRIs uniquely identify resources.

- **Subject**: The "thing" being described in a triple (always an IRI or blank node). Example: `Book #123`

- **Predicate**: The relationship or property name (always an IRI). Example: `has-title`, `has-author`

- **Object**: The value or related resource (can be an IRI, literal, or blank node). Example: `"The Great Gatsby"` or another `Book #456`

- **Literal**: A simple value like text, numbers, or dates. Example: `"The Great Gatsby"`, `42`, `2024-01-15`

- **Blank Node**: An anonymous resource without a global IRI - only meaningful within its local context. Like a nested object that doesn't need its own ID.

## Quick Start

**Prerequisites:** This library requires the `locorda_rdf_mapper_generator` package to generate the actual mapping code from your annotations.

### Add Dependencies

```bash
# Add runtime dependencies
dart pub add locorda_rdf_core locorda_rdf_mapper locorda_rdf_mapper_annotations

# Add development dependencies (required for code generation)
dart pub add build_runner --dev
dart pub add locorda_rdf_mapper_generator --dev
```

The following guide shows three progressively more complex approaches to RDF mapping:

### Step 1: Define Your Own Vocabulary (Simplest)

Start by creating a mapper with your own custom vocabulary - no external dependencies needed:

```dart
import 'package:locorda_rdf_mapper_annotations/annotations.dart';

@RdfGlobalResource.define(
  AppVocab(appBaseUri: 'https://myapp.example.com'),
  IriStrategy('https://myapp.example.com/people/{id}'),
)
class Person {
  @RdfIriPart('id')
  final String id;

  final String name;
  final int age;

  const Person({
    required this.id,
    required this.name,
    required this.age,
  });
}
```

Run the code generator:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates:
- **Mapper code** for bidirectional Dart ↔ RDF conversion
- **Vocabulary file** (`lib/vocab.g.ttl`) documenting your domain model

**Generated vocabulary (`lib/vocab.g.ttl`):**
```turtle
@prefix app: <https://myapp.example.com/vocab#> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

<https://myapp.example.com/vocab#> a owl:Ontology .

app:Person a owl:Class;
    rdfs:isDefinedBy app:;
    rdfs:label "Person";
    rdfs:subClassOf rdfs:Resource .

app:name a rdf:Property;
    rdfs:domain app:Person;
    rdfs:isDefinedBy app:;
    rdfs:label "Name" .

app:age a rdf:Property;
    rdfs:domain app:Person;
    rdfs:isDefinedBy app:;
    rdfs:label "Age" .
```

Use the generated mapper:

```dart
import 'package:your_package/init_rdf_mapper.g.dart';

void main() {
  final mapper = initRdfMapper();
  
  final person = Person(id: '123', name: 'Alice', age: 30);
  
  // Convert to RDF
  final turtle = mapper.encodeObject(person);
  print(turtle);
  
  // Parse back to Dart
  final parsedPerson = mapper.decodeObject<Person>(turtle);
  print(parsedPerson.name); // 'Alice'
}
```

**What gets generated (RDF output):**
```turtle
@prefix app: <https://myapp.example.com/vocab#> .

<https://myapp.example.com/people/123> a app:Person ;
    app:age 30 ;
    app:name "Alice" .
```

**What you just did:**
- Created an RDF mapper without needing any existing RDF vocabulary
- Automatically generated a formal vocabulary describing your model
- Got type-safe RDF serialization/deserialization

**Note:** Fields without annotations (like `name` and `age`) are automatically mapped to RDF properties when using `.define()` mode. See [Field Handling in .define() Mode](#field-handling-in-define-mode) for details on controlling this behavior.

### Step 2: Mix Your Terms with Existing Vocabularies

Extend established vocabularies like Schema.org with your own custom properties:

```bash
# Add Schema.org vocabulary terms
dart pub add locorda_rdf_terms_schema
```

```dart
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

@RdfGlobalResource.define(
  AppVocab(appBaseUri: 'https://myapp.example.com'),
  IriStrategy('https://myapp.example.com/products/{sku}'),
  subClassOf: SchemaProduct.classIri,
)
class Product {
  @RdfIriPart('sku')
  final String sku;

  // Use Schema.org property
  @RdfProperty(SchemaProduct.name)
  final String name;

  // Use Schema.org property
  @RdfProperty(SchemaProduct.price)
  final double price;

  // Your custom property (will be in your vocabulary)
  final String internalNotes;

  const Product({
    required this.sku,
    required this.name,
    required this.price,
    required this.internalNotes,
  });
}
```

Your generated vocabulary will properly declare `Product` as a subclass of `schema:Product` and include the custom `internalNotes` property. The mapper uses standard Schema.org properties for `name` and `price`.

**When to use this:**
- You're working in a well-established domain (e-commerce, events, etc.)
- You need custom extensions for your specific use case
- You want proper semantic integration with external vocabularies

### Step 3: Use External Vocabularies Only

When your vocabulary is already defined externally (established standards, manually crafted, or generated by other tools):

```dart
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

@RdfGlobalResource(
  SchemaBook.classIri, 
  IriStrategy('https://library.example.com/books/{id}')
)
class Book {
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfProperty(SchemaBook.author, iri: IriMapping('https://library.example.com/authors/{authorId}'))
  final String authorId;

  @RdfProperty(SchemaBook.hasPart)
  final List<Chapter> chapters;

  Book({
    required this.id,
    required this.title,
    required this.authorId,
    required this.chapters,
  });
}

@RdfLocalResource(SchemaChapter.classIri)
class Chapter {
  @RdfProperty(SchemaChapter.name)
  final String title;

  @RdfProperty(SchemaChapter.position)
  final int number;

  Chapter(this.title, this.number);
}
```

Run the code generator and use the mapper as shown in Step 1.

You can reference external vocabulary terms using:
- **Generated constants**: `SchemaBook.classIri`, `FoafPerson.classIri` - use `locorda_rdf_terms_generator` to generate constants from any vocabulary file (Turtle, RDF/XML, etc.)
- **Manual IRIs**: `IriTerm('https://example.com/vocab#Term')` - quick approach when you only need a few terms

**When to use this:**
- Publishing data using established standards (Schema.org, FOAF, Dublin Core)
- Your vocabulary is manually crafted (Protégé, TopBraid, etc.) or generated by other tools
- You prefer to keep vocabulary definition separate from code
- SEO with Schema.org markup
- Integration with existing semantic web infrastructure

### Next Steps

Choose the approach that fits your needs:
- **Starting fresh?** Use `.define` to generate vocabulary from code (Step 1)
- **Extending established standards?** Mix generated and external vocabularies (Step 2)  
- **Vocabulary already exists?** Use external vocabularies only (Step 3)

To enhance generated vocabularies with custom labels, multilingual support, and metadata, see [Advanced Vocabulary Generation Features](#advanced-vocabulary-generation-features).

## How It Works

This library follows a two-step process:

1. **Annotation Phase**: You annotate your Dart classes with RDF mapping annotations (this library)
2. **Code Generation Phase**: The `locorda_rdf_mapper_generator` analyzes your annotations and generates efficient mapping code

**Development Workflow:**
- Annotate your classes → Run `dart run build_runner build` → Use generated mappers
- When you change annotations → Re-run the build command → Updated mappers are ready to use

The generated code is type-safe, efficient, and handles all the RDF serialization/deserialization complexity for you.

## Key Concepts

### Class Annotations

- **@RdfGlobalResource**: For entities that have their own unique web address (IRI) and can be referenced from anywhere. Examples: People, Products, Books. These become the "subjects" in RDF triples with globally unique IRIs like `https://example.org/people/123`.

- **@RdfLocalResource**: For nested/child entities that only make sense within their parent and don't need global IDs. Examples: Addresses within a Person, Chapters within a Book. These become "blank nodes" in RDF - anonymous resources without their own IRI.

- **@RdfIri**: For classes representing web addresses (IRIs) themselves. Use when you need a custom type for IRIs with validation or special formatting.

- **@RdfLiteral**: For classes representing simple values like strings, numbers, or custom formats with validation. These serialize as RDF literals with optional datatypes.

### Property Annotations

- **@RdfProperty**: Maps a Dart class property to an RDF relation (predicate). Defines how properties connect to other resources. When using `.define()` mode (with `@RdfGlobalResource.define` or `@RdfLocalResource.define`), unannotated fields are implicitly treated as `@RdfProperty.define()`.
- **@RdfIriPart**: Marks fields that help construct the resource's web address (IRI). These fields are excluded from implicit property generation.
- **@RdfIgnore**: Completely excludes a field from RDF mapping (no vocabulary entry, not serialized, not deserialized). Use for UI state, computed properties, or any field that shouldn't be persisted to RDF.
- **@RdfValue**: Identifies which field provides the actual data value for a literal.
- **@RdfMapEntry**: Specifies how key-value pairs are converted to RDF (since RDF has no native map concept).

### IRI Strategies

IRI Strategies define how to generate unique web addresses (IRIs) for your resources. Think of it as defining the URL structure for your data.

#### Template-based IRIs (Most Common)

Use a template with placeholders for dynamic parts:

```dart
@RdfGlobalResource(
  Person.classIri, 
  IriStrategy('https://example.org/people/{id}')
)
class Person {
  @RdfIriPart()  // Will be substituted into {id} in the template
  final String id;
  
  @RdfProperty(SchemaPerson.name)
  final String name;
}
```

Result: `Person(id: '123', name: 'Alice')` → `https://example.org/people/123`

**Multi-part IRIs** - Build IRIs from multiple fields:

```dart
@RdfGlobalResource(
  SchemaChapter.classIri,
  IriStrategy('https://example.org/books/{bookId}/chapters/{chapterNumber}')
)
class Chapter {
  @RdfIriPart()  // Maps to {bookId}
  final String bookId;
  
  @RdfIriPart("chapterNumber")  // Maps to {chapterNumber}
  final int number;
}
```

Result: `Chapter(bookId: '456', number: 3)` → `https://example.org/books/456/chapters/3`

#### Other IRI Strategies

For less common scenarios, see the advanced section:
**Advanced patterns:**
- **Direct IRI Storage** - Store the complete IRI in your object (`IriStrategy()`)
- **Runtime Placeholders** - Inject values at runtime (multi-tenant apps, configurable base URIs)
- **Fragment-based IRIs** - Share a base IRI with different fragments (`#section1`, `#section2`)
- **Custom Mappers** - Complete control over IRI generation/parsing

See [Advanced IRI Strategies](#advanced-iri-strategies) for these patterns.

### IRI Property Mapping

When a property should reference another resource (rather than contain a literal value), use `IriMapping` to generate proper IRIs from simple values:

```dart
class Book {
  // Maps the string "k42" to the IRI "http://example.org/author/k42"
  @RdfProperty(
    SchemaBook.author,  // Expects an IRI to a Person
    iri: IriMapping('http://example.org/author/{authorId}')
  )
  final String authorId;
  
  // ...
}
```

This is especially valuable for:
- Referencing external resources with IRIs
- Creating semantic connections between objects
- Adhering to vocabulary specifications (like Schema.org)
- Maintaining proper RDF graph structure when a predicate expects an IRI rather than a literal

---

## Advanced Features

### Advanced IRI Strategies

While simple template-based IRIs cover most use cases (see [IRI Strategies](#iri-strategies) in Key Concepts), here are advanced patterns for complex scenarios:

#### Direct IRI Storage

Store the complete IRI directly in your object (no template needed):

```dart
@RdfGlobalResource(
  SchemaPerson.classIri, 
  IriStrategy()  // Empty strategy means use the IRI field directly
)
class Person {
  @RdfIriPart()  // Contains the complete IRI
  final String iri;
  
  @RdfProperty(SchemaPerson.name)
  final String name;
}
```

#### Runtime-Injected Placeholders

Use globally injected placeholders for values that should be provided at runtime:

```dart
// Define models with configurable base URIs
@RdfGlobalResource(
  SchemaPerson.classIri, 
  IriStrategy('{+baseUri}/persons/{id}')  // {baseUri} is not directly from a class field and is marked with +, thus matches including /
)
class Person {
  @RdfIriPart()
  final String id;
  
  @RdfProperty(SchemaPerson.name)
  final String name;
  
  Person({required this.id, required this.name});
}

@RdfGlobalResource(
  SchemaOrganization.classIri, 
  IriStrategy('{+baseUri}/organizations/{id}')  // Same placeholder across models
)
class Organization {
  @RdfIriPart()
  final String id;
  
  @RdfProperty(SchemaOrganization.name)
  final String name;
  
  Organization({required this.id, required this.name});
}

// At runtime, provide values for the global placeholders
void main() {
  // The generated initRdfMapper function will require providers for global placeholders
  final mapper = initRdfMapper(
    // Provide a function that returns the baseUri value
    baseUriProvider: () => 'https://user-specific-domain.com',
  );
  
  // Now when you create and serialize objects, the baseUri will be injected
  final person = Person(id: '123', name: 'Alice');
  final org = Organization(id: 'acme', name: 'ACME Inc.');
  
  // IRI will be: https://user-specific-domain.com/persons/123
  final personGraph = mapper.encodeObject(person);
  
  // IRI will be: https://user-specific-domain.com/organizations/acme
  final orgGraph = mapper.encodeObject(org);
}
```

This approach is particularly useful for:
- Multi-tenant applications where each tenant has their own domain
- Applications that need to switch between development/staging/production URLs
- Supporting user-specific or deployment-specific base URIs
- Maintaining a consistent IRI structure across your entire model

#### Property-Level Context Variables with `@RdfProvides`

For context variables that are already available as properties in your class, use `@RdfProvides` to pass them to child mappers:

```dart
@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('{+baseUri}/books/{id}')
)
class Book {
  @RdfIriPart()
  @RdfProvides('bookId')  // Make the book's ID available to child mappers
  final String id;

  @RdfProperty(SchemaBook.hasPart)
  final List<Chapter> chapters;  // Chapters can use {bookId} in their IRI templates
}

@RdfGlobalResource(
  SchemaChapter.classIri,
  IriStrategy('{+baseUri}/books/{bookId}/chapters/{chapterNum}'),
  registerGlobally: false  // Only used within Book context
)
class Chapter {
  @RdfIriPart()
  final int chapterNum;
  // {bookId} will be provided by the parent Book
}
```

This approach avoids the need for global provider parameters when context values are already available in the object graph.

#### Parent IRI as Context with `providedAs`

For hierarchical structures where child resources need their parent's IRI, use the `providedAs` parameter:

```dart
@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('{+baseUri}/books/{id}', 'bookIri')  // Provide this resource's IRI as {bookIri}
)
class Book {
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaBook.author)
  final Author author;  // Author can reference the book's IRI
}

@RdfGlobalResource(
  SchemaAuthor.classIri,
  IriStrategy('{+bookIri}/author'),  // Use the parent book's IRI
  registerGlobally: false
)
class Author {
  @RdfProperty(SchemaPerson.name)
  final String name;
}
```

This is particularly useful for creating URIs that are relative to their parent resource.

For complete details on context variable resolution, see the API documentation for `IriStrategy`, `@RdfProvides`, and `IriMapping`.

#### Fragment-based IRIs with `withFragment`

For resources within the same document that differ only by their fragment identifier, use the `withFragment` constructor. This works with any URI scheme, including non-hierarchical schemes like `tag:`:

```dart
@RdfGlobalResource(
  DocumentClass.classIri,
  IriStrategy('tag:example.org,2025:document-{docId}', 'documentIri')
)
class Document {
  @RdfIriPart()
  final String docId;

  @RdfProperty(Vocab.hasSection)
  final List<Section> sections;
}

@RdfGlobalResource(
  SectionClass.classIri,
  IriStrategy.withFragment('{+documentIri}', 'section-{sectionId}'),
  registerGlobally: false
)
class Section {
  @RdfIriPart()
  final String sectionId;

  @RdfProperty(SchemaCreativeWork.name)
  final String name;
  // Section IRI will be: tag:example.org,2025:document-123#section-intro
}
```

The `withFragment` constructor automatically strips any existing fragment from the base IRI and appends the new fragment with a `#` separator. This is particularly useful for:
- Document-based structures (WebID profiles, HTML documents with internal links)
- Non-hierarchical URI schemes like `tag:` where traditional path-based hierarchies don't apply
- RDF graphs where multiple resources share the same document but have different fragment identifiers

Similar constructors are available for property-level (`IriMapping.withFragment`) and IRI term classes (`RdfIri.withFragment`).

#### Custom Mapper for Complex Cases

When you need complete control over IRI generation and parsing:

```dart
@RdfGlobalResource(
  SchemaChapter.classIri,
  IriStrategy.namedMapper('chapterIdMapper')  // Reference to your custom mapper
)
class Chapter {
  @RdfIriPart.position(1)  // Position in the record type used by the mapper
  final String bookId;
  
  @RdfIriPart.position(2)  // Position matters for the record type
  final int chapterNumber;
  
  // Other properties...
}

// Your custom IRI mapper implementation
class ChapterIdMapper implements IriTermMapper<(String bookId, int chapterId)> {
  final String baseUrl;
  
  ChapterIdMapper({required this.baseUrl});
  
  @override
  IriTerm toRdfTerm((String, int) value, SerializationContext context) {
    return context.createIriTerm('$baseUrl/books/${value.$1}/chapters/${value.$2}');
  }
  
  @override
  (String, int) fromRdfTerm(IriTerm term, DeserializationContext context) {
    // Parse the IRI and extract components
    final uri = Uri.parse(term.value);
    final segments = uri.pathSegments;
    
    // Expected path: /books/{bookId}/chapters/{chapterId}
    if (segments.length >= 4 && segments[0] == 'books' && segments[2] == 'chapters') {
      return (segments[1], int.parse(segments[3]));
    }
    
    throw FormatException('Invalid Chapter IRI format: ${term.value}');
  }
}
```

### Directional Mappers (Serialize-Only / Deserialize-Only)

Control whether a mapper handles serialization, deserialization, or both. This is useful for:
- **Read-only scenarios**: Consuming external RDF data without needing to serialize
- **Write-only scenarios**: Generating RDF exports without deserialization support
- **Performance optimization**: Generated code only includes the necessary direction

#### For Auto-Generated Mappers

Use specialized constructors that make the intent explicit:

```dart
// Deserialize-only: IRI strategy is optional since it's not needed
@RdfGlobalResource.deserializeOnly(SchemaBook.classIri)
class ExternalBook {
  // No @RdfIriPart needed - we're only reading RDF
  @RdfProperty(SchemaBook.name)
  final String title;
  
  @RdfProperty(SchemaBook.isbn)
  final String isbn;
  
  ExternalBook({required this.title, required this.isbn});
}

// Serialize-only: IRI strategy is required for generating IRIs
@RdfGlobalResource.serializeOnly(
  SchemaProduct.classIri,
  IriStrategy('http://example.org/products/{id}')
)
class ProductExport {
  @RdfIriPart('id')
  final String productId;
  
  @RdfProperty(SchemaProduct.name)
  final String name;
  
  ProductExport({required this.productId, required this.name});
}

// Standard bidirectional (default)
@RdfGlobalResource(
  SchemaPerson.classIri,
  IriStrategy('http://example.org/people/{id}')
)
class Person {
  @RdfIriPart('id')
  final String id;
  
  @RdfProperty(SchemaPerson.name)
  final String name;
  
  Person({required this.id, required this.name});
}
```

#### For Custom Mappers

Use the `direction` parameter with custom mapper constructors:

```dart
// Deserialize-only custom mapper
@RdfGlobalResource.namedMapper(
  'readOnlyArticleMapper',
  direction: MapperDirection.deserializeOnly
)
class ReadOnlyArticle {
  final String title;
  final String content;
  
  ReadOnlyArticle({required this.title, required this.content});
}

// Serialize-only custom mapper
@RdfGlobalResource.mapper(
  WriteOnlyArticleMapper,
  direction: MapperDirection.serializeOnly
)
class WriteOnlyArticle {
  final String articleId;
  final String title;
  
  WriteOnlyArticle({required this.articleId, required this.title});
}

// Also works with .mapperInstance()
@RdfGlobalResource.mapperInstance(
  myCustomMapper,
  direction: MapperDirection.deserializeOnly
)
class CustomClass { /* ... */ }
```

The `MapperDirection` enum has three values:
- `MapperDirection.both` (default) - Full bidirectional mapping
- `MapperDirection.serializeOnly` - Only write to RDF
- `MapperDirection.deserializeOnly` - Only read from RDF

**Benefits:**
- Type safety: Standard constructor maintains required IRI strategy
- Explicit intent: Code clearly shows the mapping direction
- Optimization: Generator creates optimized single-direction code
- Flexibility: Works with all custom mapper constructors

See [`example/directional_mappers.dart`](example/directional_mappers.dart) for a complete demonstration.

### Custom Annotation Classes

Create domain-specific annotations by subclassing existing annotation classes:

```dart
enum PodIriStrategy { twoTwoDigitDirs, noDirs }

class PodResource extends RdfGlobalResource {
  const PodResource.twoTwoDigits(IriTerm classIri)
      : super(
            classIri,
            const IriStrategy.namedFactory(r'$podIriStrategyFactory$', PodIriStrategy.twoTwoDigitDirs),
            registerGlobally: true);

  const PodResource.noDirs(IriTerm classIri)
      : super(
            classIri,
            const IriStrategy.namedFactory(r'$podIriStrategyFactory$', PodIriStrategy.noDirs),
            registerGlobally: true);
}

// Usage
@PodResource.twoTwoDigits(SchemaPerson.classIri)
class Person {
  @RdfIriPart()
  final String id;
  // ...
}
```

**Important limitations**: Due to Dart's const requirements for annotations, subclassing is only useful for predefined configurations switched between using named constructors. You can only pass through parameters to the super constructor and provide compile-time constants to the super constructor - no dynamic parameterization is possible.

### Custom Types and Literals

Create custom types with specialized serialization:

```dart
@RdfLiteral()
class Rating {
  @RdfValue()
  final int stars;
  
  Rating(this.stars) {
    if (stars < 0 || stars > 5) {
      throw ArgumentError('Rating must be between 0 and 5 stars');
    }
  }
}

@RdfLiteral.custom(
  toLiteralTermMethod: 'formatCelsius',
  fromLiteralTermMethod: 'parse',
  datatype: IriTerm('http://example.org/temperature')
)
class Temperature {
  final double celsius;
  
  Temperature(this.celsius);
  
  LiteralContent formatCelsius() => LiteralContent('$celsius°C');
  
  static Temperature parse(LiteralContent term) {
    return Temperature(double.parse(term.value.replaceAll('°C', '')));
  }
}
```

### Internationalization Support

Handle localized texts with language tags:

```dart
@RdfLiteral()
class LocalizedText {
  @RdfValue()
  final String text;
  
  @RdfLanguageTag()
  final String languageTag;
  
  LocalizedText(this.text, this.languageTag);
  
  // Convenience constructors
  LocalizedText.en(String text) : this(text, 'en');
  LocalizedText.de(String text) : this(text, 'de');
}
```

### Collection Handling

RDF Mapper provides flexible support for collection types (List, Set, Iterable) and Map collections with different serialization strategies.

#### Standard Collections (List, Set, Iterable)

By default, standard Dart collections are serialized as multiple separate RDF triples with the same predicate:

```dart
class Book {
  // Uses UnorderedItemsListMapper automatically - each author generates a separate triple
  @RdfProperty(SchemaBook.author)
  final List<Person> authors;
  
  // Uses UnorderedItemsSetMapper automatically - each keyword as separate triple
  @RdfProperty(SchemaBook.keywords)
  final Set<String> keywords;
  
  // Uses UnorderedItemsMapper automatically - recommended for semantic clarity
  @RdfProperty(SchemaBook.contributors)
  final Iterable<Person> contributors;
}
```

**Important notes about default collection behavior:**
- **Order is not preserved** in RDF representation
- Each item generates its own triple: `book:123 schema:author person:1`, `book:123 schema:author person:2`
- **NOT** serialized as RDF Collection structures (rdf:first/rdf:rest/rdf:nil)
- Use `Iterable<T>` for clarity that order shouldn't be relied upon
- **Default behavior**: Unlike other mapping properties (`iri`, `literal`, `globalResource`, `localResource`) which default to registry lookup when not specified, collections have a different default. When no `collection` parameter is specified on `Set`, `List`, `Map`, or `Iterable` properties, it defaults to `collection: CollectionMapping.auto()` (which provides the automatic behavior described above)
- **Registry lookup**: To use registry-based mapper lookup (matching the default behavior of other mapping properties), explicitly specify `collection: CollectionMapping.fromRegistry()`

#### Custom Collection Mappers

Use the `collection` parameter to specify custom collection mapping strategies:

```dart
class Book {
  // Structured RDF List (preserves order)
  @RdfProperty(SchemaBook.chapters, collection: rdfList)
  final List<Chapter> chapters;
  
  // RDF Sequence structure
  @RdfProperty(SchemaBook.authors, collection: rdfSeq)
  final List<Person> authors;
  
  // Custom collection behavior - treating entire collection as single value
  @RdfProperty(SchemaBook.keywords, collection: CollectionMapping.mapper(StringListMapper))
  final List<String> keywords; // Uses custom collection mapper for entire list
}
```

#### Item Mapping within Collections

The `iri`, `literal`, `globalResource`, and `localResource` parameters configure how individual items are mapped:

```dart
class Book {
  // Default collection behavior (multiple triples) with custom item mapping
  @RdfProperty(
    SchemaBook.authors,
    iri: IriMapping('{+baseUri}/person/{authorId}')
  )
  final List<String> authorIds; // Each ID converted to IRI, separate triples
  
  // Default collection with custom literal mapping for each item
  @RdfProperty(
    SchemaBook.tags,
    literal: LiteralMapping.withLanguage('en')
  )
  final List<String> tags; // Each tag as separate literal with @en language tag
  
  // Structured collection with custom item mapping
  @RdfProperty(
    SchemaBook.chapters,
    collection: rdfList,
    globalResource: GlobalResourceMapping.namedMapper('chapterMapper')
  )
  final List<Chapter> chapters;
}
```

### Map Collections

RDF has no native concept of key-value pairs. This library provides two different approaches for mapping Map<K,V> collections:

#### 1. Using a dedicated entry class (Most common approach)

This approach uses a class with `@RdfMapKey` and `@RdfMapValue` annotations:

```dart
// In your main class
class Task {
  @RdfProperty(TaskVocab.vectorClock)
  @RdfMapEntry(VectorClockEntry)  // Specify the entry class
  Map<String, int> vectorClock;  // clientId → version number
}

// The entry class with key and value properties
@RdfLocalResource(VectorClockVocab.classIri)  
class VectorClockEntry {
  @RdfProperty(VectorClockVocab.clientId)
  @RdfMapKey()  // This property provides the Map key
  final String clientId;

  @RdfProperty(VectorClockVocab.clockValue)
  @RdfMapValue()  // This property provides the Map value 
  final int clockValue;

  VectorClockEntry(this.clientId, this.clockValue);
}
```

Each map entry is represented as a separate resource in the RDF graph with its own properties.

#### 2. Using a custom mapper (For special cases)

This approach handles map entries directly without separate resources:

```dart
// Direct mapping using a custom mapper
class Book {
  @RdfProperty(
    BookVocab.title,
    literal: LiteralMapping.mapperInstance(const LocalizedEntryMapper())
  )
  final Map<String, String> translations;  // language → translated text
  
  Book({required this.translations});
}

// Custom mapper converts between Map entries and RDF literals
class LocalizedEntryMapper implements LiteralTermMapper<MapEntry<String, String>> {
  const LocalizedEntryMapper();

  @override
  MapEntry<String, String> fromRdfTerm(LiteralTerm term, DeserializationContext context) =>
    MapEntry(term.language ?? 'en', term.value);

  @override
  LiteralTerm toRdfTerm(MapEntry<String, String> value, SerializationContext context) =>
    LiteralTerm.withLanguage(value.value, value.key);
}
```

In this example, map entries are serialized as language-tagged literals, where the key becomes the language tag and the value becomes the literal value.

### Lossless RDF Mapping

Preserve all RDF data during serialization/deserialization cycles with lossless mapping features:

#### @RdfUnmappedTriples - Catch-All for Unknown Properties

Use `@RdfUnmappedTriples()` to capture any RDF properties that aren't explicitly mapped to other fields:

```dart
@RdfGlobalResource(SchemaPerson.classIri, IriStrategy("https://example.org/people/{id}"))
class Person {
  @RdfIriPart("id")
  final String id;

  @RdfProperty(SchemaPerson.name)
  final String name;

  // Captures email, telephone, and any other unmapped properties
  @RdfUnmappedTriples()
  final RdfGraph unmappedProperties;

  Person({required this.id, required this.name, RdfGraph? unmappedProperties})
    : unmappedProperties = unmappedProperties ?? RdfGraph(triples: []);
}
```

#### Global Unmapped Triples - Document-Level Preservation

For complete document preservation, use `@RdfUnmappedTriples(globalUnmapped: true)` on document-level containers. This captures **all** unmapped triples from the entire RDF graph, not just the current subject:

```dart
@RdfGlobalResource(
  FoafPersonalProfileDocument.classIri, 
  IriStrategy()
)
class ProfileDocument {
  @RdfIriPart()
  final String documentIri;

  @RdfProperty(FoafPersonalProfileDocument.primaryTopic)
  final Person primaryTopic;

  @RdfProperty(FoafPersonalProfileDocument.maker)
  final Uri maker;

  // Captures ALL unmapped triples from the entire document
  @RdfUnmappedTriples(globalUnmapped: true)
  final RdfGraph globalUnmappedTriples;

  ProfileDocument({
    required this.documentIri,
    required this.primaryTopic,
    required this.maker,
    RdfGraph? globalUnmappedTriples,
  }) : globalUnmappedTriples = globalUnmappedTriples ?? RdfGraph(triples: []);
}
```

**Important:** Only use `globalUnmapped: true` on a single top-level document class to avoid duplicate data collection.

#### RdfGraph as Property Type

Use `RdfGraph` as a regular property type to capture structured subgraphs without creating custom classes:

```dart
class Person {
  @RdfProperty(SchemaPerson.name)
  final String name;

  // Captures address as a subgraph (streetAddress, city, postalCode, etc.)
  @RdfProperty(SchemaPerson.address)
  final RdfGraph? address;

  // Still preserves any other unmapped properties
  @RdfUnmappedTriples()
  final RdfGraph unmappedProperties;
}
```

#### Document-Level Lossless Workflow

For complete document preservation including unrelated entities, use the lossless methods:

```dart
// Decode with remainder - captures both object data and document-level unmapped data
final (person, remainderGraph) = mapper.decodeObjectLossless<Person>(turtle);

// person.unmappedProperties contains triples about the person that weren't mapped
// remainderGraph contains all other triples from the document (other entities, etc.)

// Encode back preserving everything - perfect round-trip
final restoredTurtle = mapper.encodeObjectLossless((person, remainderGraph));
```

**Benefits:**
- **Perfect round-trip preservation**: No data loss during Dart ↔ RDF conversion
- **Future-proof**: Handle evolving RDF schemas gracefully
- **Flexibility**: Mix strongly-typed properties with flexible graph storage
- **Document integrity**: Preserve entire RDF documents, not just individual objects

See `example/catch_all.dart` for subject-scoped unmapped triples and `example/document_example.dart` for global document-level preservation.

#### When to Use Which Approach

Choose the right unmapped triples strategy based on your use case:

**Subject-scoped (`@RdfUnmappedTriples()`)**:
- ✅ Individual objects with unknown/evolving properties
- ✅ Multiple instances of the same class in a document
- ✅ Lightweight preservation with minimal performance impact
- ✅ Standard object-level lossless mapping

**Global unmapped (`@RdfUnmappedTriples(globalUnmapped: true)`)**:
- ✅ Document-level containers (WebID profiles, configuration files)
- ✅ Complete preservation of entire RDF documents
- ✅ Capturing unrelated entities and document metadata
- ⚠️ Only use on a single top-level document class
- ⚠️ Higher performance cost due to full graph traversal

**RdfGraph properties (`@RdfProperty(...) RdfGraph subgraph`)**:
- ✅ Known subgraphs that are too complex for custom classes
- ✅ Variable structure that doesn't justify strong typing
- ✅ Mix of structured and flexible data handling

**Document-level lossless methods (`decodeObjectLossless`, `encodeObjectLossless`)**:
- ✅ Working with documents that contain unmapped data outside your object model
- ✅ Need to capture entities not represented by your classes
- ✅ Perfect round-trip preservation without needing global unmapped annotations
- ✅ Programmatic control over remainder graph handling
- ✅ Use when you want lossless mapping without modifying class definitions

```dart
// Document-level lossless workflow
final (person, remainderGraph) = mapper.decodeObjectLossless<Person>(turtle);
// remainderGraph contains all triples not consumed by Person mapping

// Perfect round-trip preservation
final restoredTurtle = mapper.encodeObjectLossless((person, remainderGraph));
```

### Enum Support

RDF Mapper provides comprehensive support for mapping Dart enums to RDF literals and IRIs with type safety and custom serialization values.

#### Basic Enum Mapping

Use `@RdfLiteral` for enums that should serialize as literal values:

```dart
@RdfLiteral()
enum BookFormat {
  hardcover,  // → "hardcover"
  paperback,  // → "paperback"
  ebook,      // → "ebook"
}
```

Use `@RdfIri` with templates for enums that should serialize as IRIs:

```dart
@RdfIri('http://schema.org/{value}')
enum ItemCondition {
  brandNew,     // → <http://schema.org/brandNew>
  used,         // → <http://schema.org/used>
  refurbished,  // → <http://schema.org/refurbished>
}
```

#### Custom Enum Values

Override individual enum constant serialization with `@RdfEnumValue`:

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

@RdfIri('http://schema.org/{value}')
enum ItemCondition {
  @RdfEnumValue('NewCondition')
  brandNew,     // → <http://schema.org/NewCondition>
  
  @RdfEnumValue('UsedCondition')
  used,         // → <http://schema.org/UsedCondition>
  
  refurbished,  // → <http://schema.org/refurbished> (uses enum name)
}
```

#### Enum Integration with Resources

Enums work seamlessly with resource classes:

```dart
@RdfGlobalResource(BookVocab.classIri, IriStrategy('http://example.org/books/{id}'))
class Book {
  @RdfIriPart()
  final String id;

  @RdfProperty(BookVocab.format)
  final BookFormat format;  // Uses enum's @RdfLiteral mapping

  @RdfProperty(BookVocab.condition)
  final ItemCondition condition;  // Uses enum's @RdfIri mapping

  // Override with custom language tag for this property
  @RdfProperty(BookVocab.priority, literal: LiteralMapping.withLanguage('en'))
  final Priority priority;

  Book({required this.id, required this.format, required this.condition, required this.priority});
}
```

For detailed examples including advanced IRI templates with context variables, see the [Enum Mapping Guide](doc/enum_mapping_guide.md).

### Using Custom Mappers

For special cases, you can implement custom mappers alongside generated ones:

```dart
// Custom mapper implementation
class EventMapper implements GlobalResourceMapper<Event> {
  @override
  final IriTerm typeIri = EventVocab.classIri;
  
  @override
  RdfSubject toRdfResource(Event instance, SerializationContext context, {RdfSubject? parentSubject}) {
    // Custom serialization logic here
    return context.resourceBuilder(context.createIriTerm('http://example.org/events/${instance.id}'))
      .addValue(EventVocab.timestamp, instance.timestamp)
      .addValues(instance.customData.entries.map(
        (e) => MapEntry(context.createIriTerm('http://example.org/property/${e.key}'), e.value)))
      .build();
  }
  
  @override
  Event fromRdfResource(RdfSubject subject, DeserializationContext context) {
    // Custom deserialization logic here
    return Event(/* ... */);
  }
}

// Register your custom mapper with the system
final rdfMapper = initRdfMapper();
rdfMapper.registerMapper<Event>(EventMapper());

// Now use it alongside generated mappers
final eventGraph = rdfMapper.encodeObject(event);
```

## Advanced Vocabulary Generation Features

The `.define` constructor shown in the Quick Start creates both your mapper and vocabulary automatically. You can enhance the generated vocabulary with rich metadata:

### Field Handling in .define() Mode

When using `@RdfGlobalResource.define` or `@RdfLocalResource.define`, the mapper generator automatically treats unannotated fields as RDF properties. This reduces boilerplate while giving you full control when needed.

**Automatic property mapping:**
```dart
@RdfGlobalResource.define(
  AppVocab(appBaseUri: 'https://myapp.example.com'),
  IriStrategy('https://myapp.example.com/people/{id}'),
)
class Person {
  @RdfIriPart('id')
  final String id;        // Used for IRI construction, not a property
  
  final String name;      // Automatically becomes @RdfProperty.define()
  final int age;          // Automatically becomes @RdfProperty.define()
}
```

**Controlling field behavior:**
```dart
@RdfGlobalResource.define(
  AppVocab(appBaseUri: 'https://myapp.example.com'),
  IriStrategy('https://myapp.example.com/books/{id}'),
)
class Book {
  @RdfIriPart('id')
  final String id;
  
  // Implicit mapping - vocab entry auto-generated
  final String title;
  
  // External vocabulary - no vocab entry generated
  @RdfProperty(SchemaBook.author)
  final String author;
  
  // Read-only property - in vocab, deserialized but not serialized
  @RdfProperty.define(include: false)
  final DateTime lastModified;
  
  // Completely excluded - no vocab entry, no RDF mapping
  @RdfIgnore()
  bool isExpanded = false;
}
```

**Field handling rules:**
- **Unannotated fields** → Implicit `@RdfProperty.define()`, vocab entry auto-generated
- **`@RdfIriPart` fields** → Excluded from property generation (used for IRI construction)
- **`@RdfProperty(ExternalVocab.term)`** → Uses external vocabulary, no vocab entry generated
- **`@RdfIgnore()`** → Completely excluded from RDF (no vocab entry, not serialized/deserialized)
- **`@RdfProperty.define(include: false)`** → In vocabulary, deserialized but not serialized

### Custom Labels and Comments

```dart
import 'package:locorda_rdf_mapper_annotations/annotations.dart';

@RdfGlobalResource.define(
  AppVocab(
    appBaseUri: 'https://myapp.example.com',
    label: 'My Application Vocabulary',
    comment: 'Domain model for my application',
  ),
  IriStrategy('https://myapp.example.com/people/{id}'),
  label: 'Person',
  comment: 'Represents an individual person in the system',
)
class Person {
  @RdfIriPart('id')
  final String id;

  @RdfProperty.define(
    label: 'Full Name',
    comment: 'The complete name of the person',
  )
  final String name;

  const Person({required this.id, required this.name});
}
```

### Custom Vocabulary Fragments

By default, property fragments in your vocabulary are derived from the field name (e.g., `name` → `https://myapp.example.com/vocab#name`). Use the `fragment` parameter to customize the vocabulary IRI fragment independently from the Dart field name:

```dart
@RdfGlobalResource.define(
  AppVocab(appBaseUri: 'https://myapp.example.com'),
  IriStrategy('https://myapp.example.com/books/{id}'),
)
class Book {
  @RdfIriPart('id')
  final String id;
  
  // Field name doesn't follow vocabulary conventions
  @RdfProperty.define(
    fragment: 'title',  // Vocabulary IRI: https://myapp.example.com/vocab#title
    label: 'Book Title',
  )
  final String bookTitle;  // Dart field name can be different
  
  // When field names conflict across classes, use explicit fragments
  @RdfProperty.define(
    fragment: 'publicationDate',  // Clear semantic meaning
    label: 'Publication Date',
  )
  final String pubDate;  // Shorter field name in code
  
  const Book({
    required this.id,
    required this.bookTitle,
    required this.pubDate,
  });
}
```

### Multilingual Labels

```dart
@RdfGlobalResource.define(
  AppVocab(appBaseUri: 'https://myapp.example.com'),
  IriStrategy('https://myapp.example.com/products/{id}'),
  metadata: [
    (Rdfs.label, LiteralTerm.withLanguage('Product', 'en')),
    (Rdfs.label, LiteralTerm.withLanguage('Produkt', 'de')),
    (Rdfs.label, LiteralTerm.withLanguage('Produit', 'fr')),
  ],
)
class Product {
  // ...
}
```

### Custom Metadata

Add domain-specific metadata using custom predicates:

```dart
@RdfProperty.define(
  metadata: [
    (Dc.creator, LiteralTerm('Development Team')),
    (Dc.created, LiteralTerm.withDatatype('2026-01-15', Xsd.date)),
    (IriTerm('https://myapp.example.com/vocab#validationPattern'), 
     LiteralTerm(r'^\d{3}-\d{2}-\d{4}$')),
  ],
)
final String ssn;
```

### Configuring Vocabulary Output

By default, all generated vocabulary classes and properties are collected into a single `lib/vocab.g.ttl` file. You only need to configure vocabulary output in your `build.yaml` if you're using **multiple `AppVocab` instances with different base URIs** and want to control where each vocabulary is written.

#### Custom Output Files

Specify different output files for different vocabularies:

```yaml
targets:
  $default:
    builders:
      locorda_rdf_mapper_generator:vocab_builder:
        options:
          vocabularies:
            'https://myapp.example.com/vocab#':
              output_file: 'lib/my_vocab.g.ttl'
            'https://myapp.example.com/internal#':
              output_file: 'lib/internal_vocab.g.ttl'
```

#### Including External RDF with Extensions

You can merge arbitrary RDF triples into the generated vocabulary using the `extensions` field. This is useful for:
- Adding manually-crafted ontology metadata
- Including external definitions or imports


```yaml
targets:
  $default:
    builders:
      locorda_rdf_mapper_generator:vocab_builder:
        options:
          vocabularies:
            'https://myapp.example.com/vocab#':
              output_file: 'lib/vocab.g.ttl'
              extensions: 'lib/vocab_extensions.ttl'  # Turtle file with additional triples
```

**Example extension file (`lib/vocab_extensions.ttl`):**

```turtle
@prefix app: <https://myapp.example.com/vocab#> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix dcterms: <http://purl.org/dc/terms/> .

<https://myapp.example.com/vocab#> 
    dcterms:creator "Development Team" ;
    dcterms:license <https://spdx.org/licenses/MIT> ;
    owl:versionInfo "1.0.0" .

# Additional axioms, restrictions, or documentation
app:Person owl:equivalentClass <http://schema.org/Person> .
```

The extension file's triples will be merged with the auto-generated vocabulary definitions.

For complete documentation on vocabulary generation features, see the [vocabulary generation guide](doc/vocab_generating.md).

## Best Practices

To get the most out of RDF Mapper:

- **Use standard vocabularies** - The `locorda_rdf_terms` package provides ready-to-use constants for common vocabularies.

- **Choose the right resource type**:
  - `@RdfGlobalResource` for entities with independent identity
  - `@RdfLocalResource` for entities that only exist in context of a parent
  - `@RdfLiteral` for values you want to serialize as a primitive like String, int etc.
  - `@RdfIri` for IRI (similar to URL) reference values 

- **Model relationships correctly** - Use IRI mapping for references to other resources rather than string literals

## Learn More

For detailed examples and advanced topics:

- **[Enum Mapping Guide](doc/enum_mapping_guide.md)** - Comprehensive guide to enum support with examples
- **[Examples Directory](https://github.com/locorda/rdf/tree/main/packages/locorda_rdf_mapper_annotations/example)** - Complex mappings, vector clocks, IRI strategies, and more

## 🛣️ Roadmap / Next Steps

- Schema generating based on annotations, for example `@RdfProperty.schemaDefine('https://my.app.com/vocab/MyType/myProp')` or similar


## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!

- Fork the repo and submit a PR
- See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
- Join the discussion in [GitHub Issues](https://github.com/locorda/rdf/issues)

## 🤖 AI Policy

This project is proudly human-led and human-controlled, with all key decisions, design, and code reviews made by people. At the same time, it stands on the shoulders of LLM giants: generative AI tools are used throughout the development process to accelerate iteration, inspire new ideas, and improve documentation quality. We believe that combining human expertise with the best of AI leads to higher-quality, more innovative open source software.

---

© 2025-2026 Klas Kalaß. Licensed under the MIT License.
