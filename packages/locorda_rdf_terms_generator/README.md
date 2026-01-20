# RDF Vocabulary to Dart - Type-safe RDF for Dart

[![pub package](https://img.shields.io/pub/v/locorda_rdf_terms_generator.svg)](https://pub.dev/packages/locorda_rdf_terms_generator)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/locorda/rdf/blob/main/LICENSE)

## Overview

[🌐 **Official Homepage**](https://locorda.dev/rdf/terms-generator)

`locorda_rdf_terms_generator` is a Dart build tool that transforms RDF vocabularies into type-safe Dart code. Built on top of [locorda_rdf_core](https://pub.dev/packages/locorda_rdf_core), it enables Dart developers to work with RDF data using familiar, strongly-typed patterns.

The tool generates two complementary sets of classes:

1. **Vocabulary Classes** - Each vocabulary (like Schema.org, FOAF, etc.) gets a dedicated class containing constants for all terms within that vocabulary, ideal for developers already familiar with RDF.

2. **RDF Class-Specific Classes** - For each RDF class within a vocabulary (like schema:Person, foaf:Agent), a dedicated Dart class is generated containing properties from that class and all its superclasses.

This dual approach makes RDF concepts accessible to both RDF experts and Dart developers new to the semantic web.

Part of the [Locorda RDF monorepo](https://github.com/locorda/rdf) with additional packages for core RDF functionality, RDF/XML support, canonicalization, object mapping, and more.

---

---

## Features

- **Type-Safe RDF Terms**: Access vocabulary terms as constants with proper typing
- **Intelligent Code Generation**: Automatic handling of namespaces, prefixes, and term resolution
- **Cross-Vocabulary Integration**: Properties from related vocabularies are properly prefixed and included
- **IDE Completion**: Discover available terms through IDE autocompletion
- **Inheritance Support**: Class-specific objects include properties from parent classes
- **Comprehensive Vocabulary Coverage**: Works with any RDF vocabulary accessible via URL or local file
- **Full Platform Compatibility**: While pub.dev shows "no support for web" (because this is a build_runner tool used only during build time), the generated code is 100% compatible with all platforms including web, Flutter, and native Dart

## Getting Started

### Quick Start (Zero Configuration)

1. **Install dependencies**:

```bash
dart pub add locorda_rdf_core
dart pub add dev:build_runner
dart pub add dev:locorda_rdf_terms_generator
```

2. **Initialize vocabulary configuration**:

```bash
dart run locorda_rdf_terms_generator init
```

This creates `lib/src/vocabularies.json` with helpful examples.

3. **Edit `lib/src/vocabularies.json`** to define your vocabularies or override standard ones:

```json
{
  "vocabularies": {
    "foaf": { "generate": true },
    "myOntology": {
      "type": "file",
      "namespace": "https://example.com/my#",
      "source": "file://ontologies/my.ttl",
      "generate": true
    }
  }
}
```

4. **Generate code**:

```bash
dart run build_runner build
```

That's it! No `build.yaml` needed for simple cases.

### Advanced: Multi-Layer Configuration

For complex scenarios (e.g., company-wide + project-specific configs), use `build.yaml`:

```yaml
targets:
  $default:
    builders:
      locorda_rdf_terms_generator|vocabulary_builder:
        options:
          vocabulary_configs:
            - package://company_rdf_standards/vocabularies.json
            - lib/src/vocabularies.json
          output_dir: "lib/vocab/generated"
```

**Layer merging:** Later files override earlier ones (field-level merge).

## CLI Commands

The generator includes helpful CLI commands for vocabulary discovery and configuration.

### List Available Vocabularies

See all available standard vocabularies and any custom vocabularies you've configured:

```bash
dart run locorda_rdf_terms_generator list
```

**Output:**
```
Available Vocabularies (8 total)
======================================================================

📚 Standard Vocabularies:
  rdf
    http://www.w3.org/1999/02/22-rdf-syntax-ns#
  foaf
    http://xmlns.com/foaf/0.1/
  schema
    https://schema.org/
  ... and more

To generate a vocabulary, set "generate": true in your vocabularies.json
```

The list command automatically merges standard vocabularies (provided by the generator) with any custom vocabularies you've defined, showing which ones are set to generate.

### Initialize Configuration Template

Create a starter `vocabularies.json` file with helpful examples:

```bash
dart run locorda_rdf_terms_generator init
```

This creates a template with three example vocabulary configurations:
- File-based local vocabulary
- URL-based remote vocabulary  
- Example showing all available configuration options

Simply edit the generated file to customize for your needs, or add entries to override standard vocabulary settings (e.g., set `"foaf": { "generate": true }` to generate the FOAF vocabulary).

### Standard Vocabularies

The generator includes definitions for common RDF vocabularies:
- **rdf** - RDF core concepts
- **rdfs** - RDF Schema
- **xsd** - XML Schema datatypes
- **owl** - Web Ontology Language
- **foaf** - Friend of a Friend
- **schema** - Schema.org
- **dcterms** - Dublin Core  
- **skos** - Simple Knowledge Organization System

All are available for cross-vocabulary resolution by default. To generate classes for any of them, add an override in your `vocabularies.json`:

```json
{
  "vocabularies": {
    "foaf": { "generate": true },
    "schema": { "generate": true }
  }
}
```

### Usage Examples

#### Using Vocabulary Classes

```dart
import 'package:locorda_rdf_core/core.dart';
import 'package:your_package/src/vocab/generated/schema.dart';
import 'package:your_package/src/vocab/generated/foaf.dart';

// Create a triple using vocabulary constants
final triple = Triple(
  const IriTerm('http://example.org/john'),
  Schema.name,  // https://schema.org/name
  LiteralTerm.string('John Doe')
);

// Use vocabulary terms in queries or graph operations
final graph = RdfGraph(triples: [triple]);

final nameQuery = graph.find(
  subject: null,
  predicate: Schema.name,
  object: null
);
```

#### Using Class-Specific Classes

```dart
import 'package:locorda_rdf_core/core.dart';
import 'package:your_package/src/vocab/generated/schema_person.dart';

void createPersonTriples(IriTerm person) {
  // SchemaPerson contains all properties related to the schema:Person class
  // including inherited properties from parent classes
  final graph = RdfGraph(triples: [
    // Properties from other vocabularies are properly prefixed, like e.g. type from rdf which you need to declare this to be a schema:Person.
    Triple(person, SchemaPerson.rdfType, SchemaPerson.classIri),
    Triple(person, SchemaPerson.name, LiteralTerm.string('Jane Doe')),
    Triple(person, SchemaPerson.email, LiteralTerm.string('jane@example.com')),
  ]);
}
```

## Understanding the Generated Code

For a vocabulary like Schema.org, the generator produces:

1. **Schema.dart** - Contains all terms from the Schema.org vocabulary:

```dart
/// Schema.org Vocabulary 
class Schema {
  Schema._();
  
  /// Base namespace for Schema.org
  static const namespace = 'https://schema.org/';
  
  /// A person (alive, dead, undead, or fictional).
  static const Person = const IriTerm('https://schema.org/Person');
  
  /// The name of the item.
  static const name = const IriTerm('https://schema.org/name');
  
  // ... many more terms
}
```

2. **SchemaPerson.dart** - Contains properties specific to the schema:Person class:

```dart
/// Properties for the Schema.org Person class
class SchemaPerson {
  SchemaPerson._();
  
  /// The RDF class IRI
  static const classIri = Schema.Person;
  
  /// The name of the person.
  static const name = Schema.name;
  
  /// Email address.
  static const email = Schema.email;
  
  /// A person known by this person (from FOAF vocabulary, if Schema.Person properly inherits from Foaf.Person).
  static const foafKnows = FOAF.knows;
  
  // ... including inherited properties from parent classes
}
```

## Configuration Options

### Vocabulary Source Configuration

Each vocabulary in your configuration file can have these properties:

| Property | Description | Required |
|----------|-------------|----------|
| `type` | Either "url" for remote vocabularies or "file" for local files | Yes |
| `namespace` | The base IRI namespace of the vocabulary | Yes |
| `source` | For "url" type: URL to fetch the vocabulary from; for "file" type: path to local file | Yes (for "file" type), No (for "url" type, defaults to namespace) |
| `parsingFlags` | Array of string flags passed to the TurtleCodec when decoding Turtle files | No |
| `generate` | Boolean indicating if this vocabulary should be processed (defaults to true) | No |
| `contentType` | Explicit content type to use for the vocabulary source, overriding auto-detection | No |
| `skipDownload` | Boolean flag to deliberately skip a vocabulary (defaults to false) | No |
| `skipDownloadReason` | Text explanation for why a vocabulary is skipped | No |

### Build Configuration

The `build.yaml` file supports these options:

| Option | Description | Default |
|--------|-------------|---------|
| `vocabulary_config_path` | Path to vocabulary configuration JSON | `"lib/src/vocab/vocabulary_sources.vocab.json"` |
| `output_dir` | Directory where generated files are placed | `"lib/src/vocab/generated"` |
| `cache_dir` | Directory for caching downloaded vocabularies | Not set (no caching) |

#### Vocabulary Caching

When `cache_dir` is configured, the builder will:

1. **Check for cached files** before downloading from remote URLs
2. **Download and cache** vocabulary files that aren't already cached
3. **Reuse cached files** on subsequent builds, avoiding redundant downloads

Cached files are named using the pattern `{name}.{extension}` where:
- `{name}` is the vocabulary's name in snake_case (e.g., `schema`, `foaf`, `dublin_core`)
- `{extension}` is determined by the content type (`.ttl`, `.rdf`, `.jsonld`, etc.)

This approach:
- **Speeds up builds** by avoiding repeated downloads
- **Enables offline development** once vocabularies are cached
- **Helps debugging** by letting you inspect the exact content being parsed
- **Provides version control** by allowing you to commit cached vocabularies

Example configuration in `build.yaml`:

```yaml
targets:
  $default:
    builders:
      locorda_rdf_terms_generator|rdf_terms_generator:
        enabled: true
        options:
          vocabulary_config_path: "lib/src/vocab/all.vocabulary_sources.vocab.json"
          output_dir: "lib/src/vocab/generated"
          cache_dir: ".dart_tool/rdf_vocabulary_cache"  # Enable caching
```

**Note**: You can choose any directory for caching. Using `.dart_tool/` keeps caches gitignored by default, or use a committed directory like `lib/vocab_cache/` for version control.

## How It Works

1. **Loading Configuration**: The builder reads your vocabulary configuration
2. **Fetching Vocabularies**: For each vocabulary, retrieves content from URL or file
3. **Decode RDF**: Processes the vocabulary data using locorda_rdf_core decoders
4. **Cross-Vocabulary Resolution**: Identifies relationships between vocabularies
5. **Code Generation**: Produces Dart classes for each vocabulary and RDF class
6. **Indexing**: Creates an index file for easy importing

## Advanced Use Cases

### Working with Multiple Vocabularies

You can define multiple vocabularies in your configuration file, and they will be automatically cross-referenced when generating class-specific modules.

### Custom RDF Vocabularies

For domain-specific RDF vocabularies, use the "file" type and provide a local Turtle file:

```json
{
  "vocabularies": {
    "myapp": {
      "type": "file",
      "namespace": "http://example.org/myapp#",
      "filePath": "lib/src/vocab/myapp.ttl"
    }
  }
}
```

### Integration with RDF Data Sources

The generated code works seamlessly with locorda_rdf_core's decoders and encoders, making it easy to process RDF data from various sources:

```dart
import 'package:locorda_rdf_core/core.dart';
import 'package:your_package/src/vocab/generated/schema.dart';

final turtleContent = ...;
final graph = await turtle.decode(turtleContent);

// Query using vocabulary terms
final people = graph.find(
  subject: null,
  predicate: Rdf.type,
  object: Schema.Person
);

for (final person in people) {
  final names = graph.find(
    subject: person.subject,
    predicate: Schema.name,
    object: null
  );
  
  // Process results...
}
```

## 🛣️ Roadmap / Next Steps

- More and better tests
- Ensure that we stick to dart file name conventions for lowerCamelCase prefixes, e.g. do not write schemaHttp.dart files but schema_http.dart instead.
- Improve generated documentation 
  - ensure that every predicate is linked to its original definition
  - resolve referenced IRIs to their dart classes and reference them instead
  - Be more precise in your wording (eg: expects IRI for a SchemaPerson)
  - Better introductions / explanations to generated classes - maybe by allowing to include JSON files with additional docs that will be included
  - other documentation improvements where applicable - maybe even generate usage examples if possible for every predicate?
- Include an example
- Solve the issue with "unresolved doc reference" in the generated documentation


## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!

- Fork the repo and submit a PR
- See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines
- Join the discussion in [GitHub Issues](https://github.com/locorda/rdf/issues)

## 🤖 AI Policy

This project is proudly human-led and human-controlled, with all key decisions, design, and code reviews made by people. At the same time, it stands on the shoulders of LLM giants: generative AI tools are used throughout the development process to accelerate iteration, inspire new ideas, and improve documentation quality. We believe that combining human expertise with the best of AI leads to higher-quality, more innovative open source software.

---

© 2025-2026 Klas Kalaß. Licensed under the MIT License. Part of the [Locorda RDF monorepo](https://github.com/locorda/rdf).
