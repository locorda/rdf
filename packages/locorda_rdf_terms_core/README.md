# RDF Vocabularies Core - Essential RDF Vocabularies

[![pub package](https://img.shields.io/pub/v/locorda_rdf_terms_core.svg)](https://pub.dev/packages/locorda_rdf_terms_core)
[![build](https://github.com/kkalass/rdf_vocabularies/actions/workflows/ci.yml/badge.svg)](https://github.com/kkalass/rdf_vocabularies/actions)
[![license](https://img.shields.io/github/license/kkalass/rdf_vocabularies.svg)](https://github.com/kkalass/rdf_vocabularies/blob/main/LICENSE)

## Overview

[🌐 **Official Homepage**](https://kkalass.github.io/rdf_vocabularies/)

`locorda_rdf_terms_core` provides type-safe access to **core RDF vocabulary terms** as Dart constants for use with [`locorda_rdf_core`](https://pub.dev/packages/locorda_rdf_core). 

This package contains the **essential RDF vocabularies** (~5MB) that cover most semantic web applications without the large Schema.org vocabularies.

## 📦 Package Selection Guide

| Package | Download Size | Content | Best For |
|---------|---------------|---------|----------|
| **`locorda_rdf_terms_core`** (this package) | **~5MB** | Core RDF vocabularies | Most applications |
| **[`rdf_vocabularies`](https://pub.dev/packages/rdf_vocabularies)** | ~77MB | All vocabularies | Full compatibility |
| **[`locorda_rdf_terms_schema`](https://pub.dev/packages/locorda_rdf_terms_schema)** | ~35MB | Schema.org HTTPS | Schema.org apps |
| **[`locorda_rdf_terms_schema_http`](https://pub.dev/packages/locorda_rdf_terms_schema_http)** | ~36MB | Schema.org HTTP | Legacy compatibility |

The library is designed for both RDF newcomers and experts, offering structured ways to work with semantic data while maintaining compilation-time safety.

---

## Part of a whole family of projects

If you are looking for more rdf-related functionality, have a look at our companion projects:

* basic graph classes as well as turtle/jsonld/n-triple encoding and decoding: [locorda_rdf_core](https://github.com/kkalass/locorda_rdf_core) 
* encode and decode rdf/xml format: [locorda_rdf_xml](https://github.com/kkalass/locorda_rdf_xml) 
* generate your own easy-to-use constants for other vocabularies with a build_runner: [locorda_rdf_terms_generator](https://github.com/kkalass/locorda_rdf_terms_generator)
* map Dart Objects ↔️ RDF: [locorda_rdf_mapper](https://github.com/kkalass/locorda_rdf_mapper)

---

## Package Characteristics

- **Zero Runtime Overhead**: Nearly all content is composed of compile-time constants
- **Small Binary Size**: Minimal impact on your application's size
- **Type Safety**: Catch vocabulary usage errors at compile time
- **IDE Assistance**: Get autocompletion and documentation directly in your editor

## Features

- **Dual Interface**: Choose between class-specific access for beginners or full vocabulary access for experts
- **Comprehensive Coverage**: Access terms from popular RDF vocabularies (Schema.org, FOAF, Dublin Core, etc.)
- **Rich Documentation**: Each term includes its original description from the vocabulary
- **Seamless Integration**: Works perfectly with the `locorda_rdf_core` library

## Getting Started

### Installation

Add the package to your project:

```sh
# Install core vocabularies package (~5MB)
dart pub add locorda_rdf_terms_core locorda_rdf_core
```

### Why Choose Core Package?

- **Smaller Download**: Only ~5MB vs ~77MB for the full meta-package
- **Essential Vocabularies**: Includes RDF, RDFS, OWL, FOAF, Dublin Core, SKOS, and more
- **Most Use Cases**: Covers the majority of semantic web applications
- **Add Schema.org Later**: Easily add Schema.org vocabularies if needed

## Usage

### For RDF Newcomers: Class-Specific Approach

If you're new to RDF, the class-specific approach guides you to use the correct properties for each type of resource:

```dart
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_terms_core/foaf.dart';
import 'package:locorda_rdf_terms_core/rdf.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';

void main() {
  final personIri = IriTerm('http://example.org/person/jane_doe');
  
  // Create a graph using class-specific constants
  final graph = RdfGraph.fromTriples([
    // Use FoafPerson class for type-safe property access
    Triple(personIri, Rdf.type, FoafPerson.classIri),
    Triple(personIri, FoafPerson.name, LiteralTerm.string('Jane Doe')),
    Triple(personIri, FoafPerson.givenName, LiteralTerm.string('Jane')),
    Triple(personIri, FoafPerson.familyName, LiteralTerm.string('Doe')),
    Triple(personIri, FoafPerson.age, LiteralTerm.integer(42)),
    Triple(personIri, FoafPerson.mbox, IriTerm('mailto:jane.doe@example.com')),
  ]);
  
  print(RdfCore.withStandardCodecs().encode(graph));
```

**Benefits**: IDE autocompletion, compile-time validation, guided vocabulary discovery.

### For RDF Experts: Direct Vocabulary Approach

Use vocabulary classes directly for maximum flexibility:

```dart
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_terms_core/foaf.dart';
import 'package:locorda_rdf_terms_core/rdf.dart';
import 'package:locorda_rdf_terms_core/dc.dart';

void main() {
  final personIri = IriTerm('http://example.org/person/jane_doe');
  
  // Create a graph with direct vocabulary access
  final graph = RdfGraph.fromTriples([
    Triple(personIri, Rdf.type, Foaf.Person),
    Triple(personIri, Foaf.name, LiteralTerm.string('Jane Doe')),
    Triple(personIri, Foaf.age, LiteralTerm.integer(42)),
    Triple(personIri, Dc.creator, LiteralTerm.string('System')),
  ]);
  
  print(RdfCore.withStandardCodecs().encode(graph));
}
```

**Benefits**: Maximum flexibility, concise syntax, mix vocabularies freely.

## Core Vocabularies Included

This package includes the essential RDF vocabularies for most semantic web applications:

- **RDF**: Resource Description Framework base vocabulary
- **RDFS**: RDF Schema vocabulary  
- **OWL**: Web Ontology Language
- **FOAF**: Friend of a Friend vocabulary
- **DC/DCTerms**: Dublin Core vocabularies (metadata)
- **SKOS**: Simple Knowledge Organization System
- **VCard**: vCard ontology for contacts
- **XSD**: XML Schema Datatypes
- **ACL**: Web Access Control vocabulary
- **Contact**: Contact information vocabulary
- **EventOwl**: Event vocabulary
- **GEO**: Geospatial vocabulary
- **LDP**: Linked Data Platform vocabulary
- **Solid**: Solid platform vocabulary
- **VS**: Vocabulary Status ontology

## Adding Schema.org Support

If you need Schema.org vocabularies, add them separately:

```sh
# Modern Schema.org with HTTPS URIs (+35MB)
dart pub add locorda_rdf_terms_schema

# Legacy Schema.org with HTTP URIs (+36MB) 
dart pub add locorda_rdf_terms_schema_http
```

## Performance Characteristics

- **Zero Runtime Overhead**: Nearly all content consists of compile-time constants
- **Optimized Size**: Only ~5MB vs ~77MB for the full package
- **Type Safety**: Catch vocabulary usage errors at compile time
- **IDE Integration**: Get autocompletion and documentation directly in your editor

## Upgrading from Meta-Package

Easily switch from the full `rdf_vocabularies` package to optimize size:

```sh
# Remove the large meta-package
dart pub remove rdf_vocabularies

# Add the optimized core package
dart pub add locorda_rdf_terms_core

# Update imports from 'package:rdf_vocabularies/' to 'package:locorda_rdf_terms_core/'
```

The API remains identical - only import paths change.

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!

- Fork the repo and submit a PR
- See [CONTRIBUTING.md](https://github.com/kkalass/rdf_vocabularies/blob/main/CONTRIBUTING.md) for guidelines
- Join the discussion in [GitHub Issues](https://github.com/kkalass/rdf_vocabularies/issues)

## 🤖 AI Policy

This project is proudly human-led and human-controlled, with all key decisions, design, and code reviews made by people. At the same time, it stands on the shoulders of LLM giants: generative AI tools are used throughout the development process to accelerate iteration, inspire new ideas, and improve documentation quality. We believe that combining human expertise with the best of AI leads to higher-quality, more innovative open source software.

---

© 2025 Klas Kalaß. Licensed under the MIT License.
