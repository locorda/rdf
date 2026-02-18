# RDF Mapper Generator for Dart

[![pub package](https://img.shields.io/pub/v/locorda_rdf_mapper_generator.svg)](https://pub.dev/packages/locorda_rdf_mapper_generator)
[![license](https://img.shields.io/badge/license-MIT-blue.svg))](https://github.com/locorda/rdf/blob/main/packages/locorda_rdf_mapper_generator/LICENSE)

**Code generator for type-safe, annotation-driven RDF mappers in Dart.**

This package generates optimized mapping code from RDF annotations defined by [`locorda_rdf_mapper_annotations`](https://pub.dev/packages/locorda_rdf_mapper_annotations). It transforms your annotated Dart classes into zero-overhead RDF serialization/deserialization code at build time.

> **📚 Looking for the complete mapping guide?**  
> See the [locorda_rdf_mapper_annotations documentation](https://pub.dev/packages/locorda_rdf_mapper_annotations) for comprehensive examples, feature explanations, and RDF mapping concepts.

## What This Generator Does

Given annotated classes like this:

```dart
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('https://example.org/books/{isbn}'),
)
class Book {
  @RdfIriPart()
  final String isbn;

  @RdfProperty(SchemaBook.name)
  final String title;

  Book({required this.isbn, required this.title});
}
```

The generator creates:
- **Mapper classes** (`BookMapper`) with encode/decode methods
- **IRI pattern matching** using optimized regex
- **Type-safe serialization** with compile-time validation
- **Initialization code** in `init_rdf_mapper.g.dart`

## Quick Start

### Install

```bash
# Runtime dependencies
dart pub add locorda_rdf_mapper locorda_rdf_mapper_annotations

# Development dependencies
dart pub add build_runner locorda_rdf_mapper_generator --dev
```

### Generate Code

```bash
dart run build_runner build
```

This scans your project for RDF annotations and generates:
- `*.rdf_mapper.g.dart` - Mapper classes for each annotated file
- `lib/init_rdf_mapper.g.dart` - Initialization function

### Use Generated Mappers

```dart
import 'package:your_package/init_rdf_mapper.g.dart';

void main() {
  final mapper = initRdfMapper();
  
  final book = Book(isbn: '978-0-544-00341-5', title: 'The Hobbit');
  final turtle = mapper.encodeObject(book);
  print(turtle);
  
  final parsed = mapper.decodeObject<Book>(turtle);
  print(parsed.title); // 'The Hobbit'
}
```

## Generated Code Examples

### Mapper Class

For a simple annotated class, the generator creates a mapper with:

```dart
class BookMapper extends GlobalResourceMapper<Book> {
  // Regex pattern for efficient IRI matching
  static final iriPattern = RegExp(r'^https://example\.org/books/([^/]+)$');
  
  @override
  Book decode(IriTerm iri, RdfGraph graph, DeserializationContext context) {
    final match = iriPattern.firstMatch(iri.value);
    final isbn = match?.group(1);
    
    final title = context.decodeLiteral<String>(
      graph.getObject(iri, SchemaBook.name),
    );
    
    return Book(isbn: isbn!, title: title);
  }
  
  @override
  (IriTerm, Iterable<Triple>) encode(Book object, SerializationContext context) {
    final iri = IriTerm('https://example.org/books/${object.isbn}');
    final triples = [
      Triple(iri, rdfType, SchemaBook.classIri),
      Triple(iri, SchemaBook.name, context.encodeLiteral(object.title)),
    ];
    return (iri, triples);
  }
}
```

### Initialization Code

The generator creates an `initRdfMapper()` function with a **dynamic signature** - it only requires providers that are actually used in your annotations:

**No runtime placeholders used:**
```dart
// If no IRI templates use {+baseUri} or other runtime values
RdfMapper initRdfMapper() {
  final mapper = ...;
  // Registers all generated mappers
  return mapper;
}
```

**Using `{+baseUri}` in IRI templates:**
```dart
// When @RdfGlobalResource uses IriStrategy('{+baseUri}/books/{isbn}')
RdfMapper initRdfMapper({
  required String Function() baseUriProvider,  // ← Required!
}) {
  final mapper = ...;
  return mapper;
}
```

**Multiple runtime placeholders:**
```dart
// When using {+baseUri}, {version}, {tenantId} across your models
RdfMapper initRdfMapper({
  required String Function() baseUriProvider,
  required String Function() versionProvider,
  required String Function() tenantIdProvider,
}) {
  final mapper = ...;
  return mapper;
}
```

The generator analyzes all `@RdfGlobalResource` IRI strategies across your codebase and creates a type-safe initialization function that enforces providing exactly the runtime values you need - **no more, no less**.

## Vocabulary Generation

The generator can create formal RDF vocabularies (ontologies) from your annotated classes using the `@RdfGlobalResource.define()` constructor:

```dart
@RdfGlobalResource.define(
  AppVocab(appBaseUri: 'https://example.com'),
  IriStrategy('https://example.com/entities/{id}'),
)
class MyEntity {
  @RdfIriPart('id')
  final String id;
  
  final String name;
  final int count;
  
  const MyEntity({required this.id, required this.name, required this.count});
}
```

The generator creates `lib/vocab.g.ttl`:

```turtle
@prefix ex: <https://example.com/vocab#> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .

<https://example.com/vocab#> a owl:Ontology .

ex:MyEntity a owl:Class;
    rdfs:isDefinedBy ex:;
    rdfs:label "My Entity";
    rdfs:subClassOf rdfs:Resource .

ex:name a rdf:Property;
    rdfs:domain ex:MyEntity;
    rdfs:isDefinedBy ex:;
    rdfs:label "Name" .

ex:count a rdf:Property;
    rdfs:domain ex:MyEntity;
    rdfs:isDefinedBy ex:;
    rdfs:label "Count" .
```

For advanced vocabulary features (custom labels, multilingual support, domain-specific metadata), see the [vocabulary generation guide](doc/vocab_generating.md).

## Build Configuration

Configure the generator in `build.yaml`:

```yaml
targets:
  $default:
    builders:
      # Vocabulary generation (optional)
      locorda_rdf_mapper_generator|vocab_builder:
        options:
          vocabularies:
            'https://myapp.com/vocab#':
              output_file: 'lib/myapp_vocab.g.ttl'
              # Optional: extend with manual definitions
              extensions: 'lib/vocab_extensions.ttl'
      
      # Mapper code generation scope (optional)
      locorda_rdf_mapper_generator|cache_builder:
        generate_for:
          - lib/**.dart
          - test/**.dart
```

## Development

### Running Tests

```bash
dart pub get
dart test
```

### Rebuilding Test Fixtures

```bash
cd test
dart run build_runner build --delete-conflicting-outputs
```

### Exploring Generated Code

View generated mappers in the test fixtures:

```bash
# List all generated files
find test/fixtures -name "*.rdf_mapper.g.dart"

# Example generated files:
# - test/fixtures/annotation_test_models.rdf_mapper.g.dart
# - test/fixtures/enum_test_models.rdf_mapper.g.dart
# - test/fixtures/comprehensive_collection_tests.rdf_mapper.g.dart
```

## Part of the RDF Ecosystem

| Package | Purpose |
|---------|---------|
| [**locorda_rdf_core**](https://pub.dev/packages/locorda_rdf_core) | Core graph classes and serialization |
| [**locorda_rdf_mapper**](https://pub.dev/packages/locorda_rdf_mapper) | Runtime mapping system |
| [**locorda_rdf_mapper_annotations**](https://pub.dev/packages/locorda_rdf_mapper_annotations) | Annotation definitions (**start here!**) |
| **locorda_rdf_mapper_generator** | **This package** - Code generator |
| [**locorda_rdf_terms**](https://pub.dev/packages/locorda_rdf_terms) | Vocabulary constants (Schema.org, FOAF, etc.) |

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

```bash
git clone https://github.com/locorda/rdf.git
cd rdf/packages/locorda_rdf_mapper_generator
dart pub get
dart test
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

**© 2025-2026 Klas Kalaß**

---

[**📦 pub.dev**](https://pub.dev/packages/locorda_rdf_mapper_generator) • [**📚 Annotations Docs**](https://pub.dev/packages/locorda_rdf_mapper_annotations) • [**🐛 Issues**](https://github.com/locorda/rdf/issues) 
