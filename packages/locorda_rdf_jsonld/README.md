<div align="center">
  <img src="https://locorda.dev/logo.svg" alt="locorda_rdf_jsonld logo" width="96" height="96"/>
</div>

# RDF JSON-LD

[![pub package](https://img.shields.io/pub/v/locorda_rdf_jsonld.svg)](https://pub.dev/packages/locorda_rdf_jsonld)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/locorda/rdf/blob/main/LICENSE)

A JSON-LD 1.1 codec for the [locorda_rdf_core](https://pub.dev/packages/locorda_rdf_core) library, providing full support for JSON-LD expansion, compaction, flattening, toRdf, and fromRdf processing.

Part of the [Locorda RDF monorepo](https://github.com/locorda/rdf) with additional packages for core RDF functionality, RDF/XML, canonicalization, object mapping, vocabulary generation, and more.

[Official Documentation](https://locorda.dev/rdf/jsonld)

---

## Features

- **W3C conformant** - Validated against the official JSON-LD 1.1 test suites (see below)
- **Full JSON-LD 1.1 processing** - Expansion, compaction, flattening, toRdf, and fromRdf
- **RDF Graph and Dataset support** - Decode/encode both `RdfGraph` and `RdfDataset` (with named graphs)
- **Context processing** - Full JSON-LD context handling including remote context loading
- **Async decoding** - `AsyncJsonLdDecoder` for loading remote `@context` documents
- **Compact output** - Intelligent compaction with automatic prefix generation
- **Plugin-compatible** - Register with `RdfCore` alongside other codecs for format auto-detection
- **Configurable** - Fail-fast or tolerant mode, customizable encoder/decoder options
- **Well tested** - Comprehensive test suite including all W3C conformance tests

## Standards Compliance

All processors are validated against the official W3C JSON-LD 1.1 test suites:

| Operation | W3C Suite | Result |
|-----------|-----------|--------|
| toRdf | [JSON-LD 1.1 toRdf](https://www.w3.org/TR/json-ld11-api/#dom-jsonldprocessor-tordf) | 465/467 passing (2 skipped) |
| fromRdf | [JSON-LD 1.1 fromRdf](https://www.w3.org/TR/json-ld11-api/#dom-jsonldprocessor-fromrdf) | 52/53 passing (1 skipped) |
| expand | [JSON-LD 1.1 Expansion](https://www.w3.org/TR/json-ld11-api/#expansion) | 385/385 passing |
| compact | [JSON-LD 1.1 Compaction](https://www.w3.org/TR/json-ld11-api/#compaction) | 244/244 passing |
| flatten | [JSON-LD 1.1 Flattening](https://www.w3.org/TR/json-ld11-api/#flattening) | 55/55 passing |

The 2 skipped toRdf tests require **Generalized RDF** (blank node predicates), which `locorda_rdf_core` does not support. The 1 skipped fromRdf test uses **JSON-LD 1.0 semantics** for list-of-lists conversion, where the 1.0 algorithm fails to fully collapse nested lists into `@list` structures. Our implementation follows the corrected 1.1 behaviour and passes the corresponding 1.1 variant of the same test.

## Installation

```bash
dart pub add locorda_rdf_jsonld
```

## Usage

### Basic Decoding and Encoding

```dart
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';

void main() {
  // Parse a JSON-LD document to an RDF graph
  final jsonLdData = '''
  {
    "@context": {
      "name": "http://xmlns.com/foaf/0.1/name",
      "knows": {
        "@id": "http://xmlns.com/foaf/0.1/knows",
        "@type": "@id"
      },
      "Person": "http://xmlns.com/foaf/0.1/Person"
    },
    "@id": "http://example.org/alice",
    "@type": "Person",
    "name": "Alice",
    "knows": "http://example.org/bob"
  }
  ''';

  // Decode to an RDF graph (ignoring named graphs)
  final graph = jsonldGraph.decode(jsonLdData);

  for (final triple in graph.triples) {
    print('${triple.subject} ${triple.predicate} ${triple.object}');
  }

  // Encode an RDF graph back to JSON-LD
  final serialized = jsonldGraph.encode(graph);
  print(serialized);
}
```

### Working with RDF Datasets (Named Graphs)

```dart
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';

void main() {
  final jsonLdData = '''
  {
    "@context": { "ex": "http://example.org/" },
    "@graph": [
      {
        "@id": "ex:alice",
        "ex:name": "Alice"
      }
    ]
  }
  ''';

  // Decode to a full RDF dataset (preserving named graphs)
  final dataset = jsonld.decode(jsonLdData);

  print('Default graph: ${dataset.defaultGraph.triples.length} triples');
  print('Named graphs: ${dataset.namedGraphs.length}');

  // Encode a dataset back to JSON-LD
  final serialized = jsonld.encode(dataset);
  print(serialized);
}
```

### Registering with RdfCore

```dart
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';

void main() {
  // Register JSON-LD codecs with RdfCore for unified format handling
  final rdfCore = RdfCore.withStandardCodecs(
    additionalCodecs: [jsonldGraph],
    additionalDatasetCodecs: [jsonld],
  );

  // Now JSON-LD works alongside Turtle, N-Triples, etc.
  final graph = rdfCore.decode(jsonLdData, contentType: 'application/ld+json');
  final turtleOutput = rdfCore.encode(graph, contentType: 'text/turtle');

  // Auto-detection also works
  final autoDetected = rdfCore.decode(jsonLdData); // detects JSON-LD
}
```

### Validation Mode (Fail-Fast vs. Skip Invalid)

`JsonLdDecoder` is **fail-fast by default**. Invalid IRIs or invalid language tags raise an exception immediately.

Use `skipInvalidRdfTerms: true` for best-effort conversion where invalid RDF terms are silently skipped.

```dart
import 'package:locorda_rdf_jsonld/jsonld.dart';

void main() {
  const input = '''
  {
    "@id": "http://example.org/s",
    "http://example.org/p": {"@value": "hello", "@language": "en_foo"}
  }
  ''';

  // Default: fail-fast (throws on invalid RDF terms)
  final strict = JsonLdDecoder();
  // strict.convert(input); // throws!

  // Opt-in: skip invalid RDF terms instead of throwing
  final tolerant = JsonLdDecoder(
    options: const JsonLdDecoderOptions(skipInvalidRdfTerms: true),
  );
  final dataset = tolerant.convert(input);
  print(dataset.defaultGraph.triples.length); // 0 (invalid triple skipped)
}
```

### Async Context Loading

For JSON-LD documents that reference remote `@context` URLs:

```dart
import 'package:locorda_rdf_jsonld/jsonld.dart';

void main() async {
  final decoder = AsyncJsonLdDecoder(
    options: AsyncJsonLdDecoderOptions(
      contextDocumentLoader: MyHttpContextLoader(),
    ),
  );

  final dataset = await decoder.convert(jsonLdWithRemoteContext);
}
```

## API Overview

| Type | Description |
|------|-------------|
| `jsonld` | Global convenience variable for JSON-LD dataset codec |
| `jsonldGraph` | Global convenience variable for JSON-LD graph codec |
| `JsonLdCodec` | Full dataset codec (encode/decode `RdfDataset`) |
| `JsonLdGraphCodec` | Graph codec (encode/decode `RdfGraph`) |
| `JsonLdDecoder` | Synchronous JSON-LD to RDF decoder |
| `JsonLdEncoder` | RDF to JSON-LD encoder |
| `AsyncJsonLdDecoder` | Async decoder with remote context loading |
| `JsonLdDecoderOptions` | Configuration for decoder behavior |
| `JsonLdEncoderOptions` | Configuration for encoder output |
| `JsonLdExpansionProcessor` | JSON-LD expansion algorithm |
| `JsonLdCompactionProcessor` | JSON-LD compaction algorithm |
| `JsonLdFlattenProcessor` | JSON-LD flattening algorithm |
| `JsonLdContext` | Represents a processed JSON-LD context |
| `JsonLdContextProcessor` | Processes JSON-LD context definitions |

## Standards & References

- [JSON-LD 1.1](https://www.w3.org/TR/json-ld11/)
- [JSON-LD 1.1 Processing Algorithms and API](https://www.w3.org/TR/json-ld11-api/)
- [RDF 1.1 Concepts](https://www.w3.org/TR/rdf11-concepts/)

---

## AI Policy

This JSON-LD implementation was primarily developed with the assistance of LLM agents, using the W3C JSON-LD 1.1 specification and official test cases as authoritative references. All key design decisions and code reviews were made by humans. The W3C test suite results above serve as the primary quality gate for correctness.

The broader Locorda RDF project is human-led and human-controlled, with generative AI tools used throughout the development process to accelerate iteration and improve quality.

---

## Contributing

Contributions, bug reports, and feature requests are welcome!

- Fork the repo and submit a PR
- See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines
- Join the discussion in [GitHub Issues](https://github.com/locorda/rdf/issues)

---

(c) 2025-2026 Klas Kalass. Licensed under the MIT License. Part of the [Locorda RDF monorepo](https://github.com/locorda/rdf).
