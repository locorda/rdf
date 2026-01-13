# RDF Vocabulary to Dart - Type-safe RDF for Dart

[![pub package](https://img.shields.io/pub/v/rdf_vocabulary_to_dart.svg)](https://pub.dev/packages/rdf_vocabulary_to_dart)
[![build](https://github.com/kkalass/rdf_vocabulary_to_dart/actions/workflows/ci.yml/badge.svg)](https://github.com/kkalass/rdf_vocabulary_to_dart/actions)
[![codecov](https://codecov.io/gh/kkalass/rdf_vocabulary_to_dart/branch/main/graph/badge.svg)](https://codecov.io/gh/kkalass/rdf_vocabulary_to_dart)
[![license](https://img.shields.io/github/license/kkalass/rdf_vocabulary_to_dart.svg)](https://github.com/kkalass/rdf_vocabulary_to_dart/blob/main/LICENSE)

## Overview

[🌐 **Official Homepage**](https://kkalass.github.io/rdf_vocabulary_to_dart/)

`rdf_vocabulary_to_dart` is a Dart build tool that transforms RDF vocabularies into type-safe Dart code. Built on top of [rdf_core](https://pub.dev/packages/rdf_core), it enables Dart developers to work with RDF data using familiar, strongly-typed patterns.

The tool generates two complementary sets of classes:

1. **Vocabulary Classes** - Each vocabulary (like Schema.org, FOAF, etc.) gets a dedicated class containing constants for all terms within that vocabulary, ideal for developers already familiar with RDF.

2. **RDF Class-Specific Classes** - For each RDF class within a vocabulary (like schema:Person, foaf:Agent), a dedicated Dart class is generated containing properties from that class and all its superclasses.

This dual approach makes RDF concepts accessible to both RDF experts and Dart developers new to the semantic web.

---

## Part of a whole family of projects

If you are looking for more rdf-related functionality, have a look at our companion projects:

* basic graph classes as well as turtle/jsonld/n-triple encoding and decoding: [rdf_core](https://github.com/kkalass/rdf_core) 
* encode and decode rdf/xml format: [rdf_xml](https://github.com/kkalass/rdf_xml) 
* easy-to-use constants for many well-known vocabularies: [rdf_vocabularies](https://github.com/kkalass/rdf_vocabularies)
* map Dart Objects ↔️ RDF: [rdf_mapper](https://github.com/kkalass/rdf_mapper)

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

### Installation

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  rdf_core: ^0.9.0  # Core library for working with RDF data

dev_dependencies:
  build_runner: ^2.4.0  # Runs the code generator
  rdf_vocabulary_to_dart: ^0.9.0  # The code generator
```

### Configuration

1. Create a configuration file in your project (e.g., `lib/src/vocab/vocabulary_sources.vocab.json`):

```json
{
  "vocabularies": {
    "schema": {
      "type": "url",
      "namespace": "https://schema.org/"
    },
    "foaf": {
      "type": "url",
      "namespace": "http://xmlns.com/foaf/0.1/"
    },
    "custom": {
      "type": "file",
      "namespace": "http://example.org/myvocab#",
      "filePath": "lib/src/vocab/custom_vocab.ttl"
    }
  }
}
```

2. Configure `build.yaml` in your project root:

```yaml
targets:
  $default:
    builders:
      rdf_vocabulary_to_dart|rdf_to_dart_generator:
        enabled: true
        options:
          vocabulary_config_path: "lib/src/vocab/vocabulary_sources.vocab.json"
          output_dir: "lib/src/vocab/generated"
```

3. Run the code generator:

```bash
dart run build_runner build
```

### Usage Examples

#### Using Vocabulary Classes

```dart
import 'package:rdf_core/rdf_core.dart';
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
import 'package:rdf_core/rdf_core.dart';
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

## How It Works

1. **Loading Configuration**: The builder reads your vocabulary configuration
2. **Fetching Vocabularies**: For each vocabulary, retrieves content from URL or file
3. **Decode RDF**: Processes the vocabulary data using rdf_core decoders
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

The generated code works seamlessly with rdf_core's decoders and encoders, making it easy to process RDF data from various sources:

```dart
import 'package:rdf_core/rdf_core.dart';
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
- See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
- Join the discussion in [GitHub Issues](https://github.com/kkalass/rdf_mapper/issues)

## 🤖 AI Policy

This project is proudly human-led and human-controlled, with all key decisions, design, and code reviews made by people. At the same time, it stands on the shoulders of LLM giants: generative AI tools are used throughout the development process to accelerate iteration, inspire new ideas, and improve documentation quality. We believe that combining human expertise with the best of AI leads to higher-quality, more innovative open source software.

---

© 2025 Klas Kalaß. Licensed under the MIT License.
