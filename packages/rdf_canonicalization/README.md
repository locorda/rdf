
# RDF Canonicalization

[![pub package](https://img.shields.io/pub/v/rdf_canonicalization.svg)](https://pub.dev/packages/rdf_canonicalization)
[![build](https://github.com/kkalass/rdf_canonicalization/actions/workflows/ci.yml/badge.svg)](https://github.com/kkalass/rdf_canonicalization/actions)
[![codecov](https://codecov.io/gh/kkalass/rdf_canonicalization/branch/main/graph/badge.svg)](https://codecov.io/gh/kkalass/rdf_canonicalization)
[![license](https://img.shields.io/github/license/kkalass/rdf_canonicalization.svg)](https://github.com/kkalass/rdf_canonicalization/blob/main/LICENSE)

A Dart library for RDF graph canonicalization and isomorphism testing, implementing the standard canonicalization algorithm for deterministic RDF serialization and semantic equality comparison.

## Part of the RDF ecosystem

This library provides canonicalization capabilities for RDF data. For creating and manipulating RDF graphs, use our core library:

- Core RDF functionality: [rdf_core](https://github.com/kkalass/rdf_core) - Create, parse, and serialize RDF data
- Easy-to-use constants for vocabularies: [rdf_vocabularies](https://github.com/kkalass/rdf_vocabularies)
- Map Dart Objects ↔️ RDF: [rdf_mapper](https://github.com/kkalass/rdf_mapper)

**Further Resources:** [🌐 **Official Homepage**](https://kkalass.github.io/rdf_canonicalization/) | [📖 **Example Code**](example/main.dart)

## Installation

```bash
dart pub add rdf_canonicalization
dart pub add rdf_core  # For creating RDF graphs
```

## 🚀 Quick Start

```dart
import 'package:rdf_canonicalization/rdf_canonicalization.dart';
import 'package:rdf_core/rdf_core.dart';

void main() {
  // Two N-Quads documents with identical semantic content but different blank node labels
  final nquads1 = '''
    _:alice <http://xmlns.com/foaf/0.1/name> "Alice" .
    _:alice <http://xmlns.com/foaf/0.1/knows> _:bob .
    _:bob <http://xmlns.com/foaf/0.1/name> "Bob" .
  ''';

  final nquads2 = '''
    _:person1 <http://xmlns.com/foaf/0.1/name> "Alice" .
    _:person1 <http://xmlns.com/foaf/0.1/knows> _:person2 .
    _:person2 <http://xmlns.com/foaf/0.1/name> "Bob" .
  ''';

  // Parse both documents
  final dataset1 = nquads.decode(nquads1);
  final dataset2 = nquads.decode(nquads2);

  // They are different as strings and objects
  print('N-Quads strings are identical: ${nquads1.trim() == nquads2.trim()}'); // false
  print('Dataset objects are identical: ${dataset1 == dataset2}'); // false

  // But they are semantically equivalent (isomorphic)
  print('Datasets are isomorphic: ${isIsomorphic(dataset1, dataset2)}'); // true

  // Canonicalization produces identical output
  final canonical1 = canonicalize(dataset1);
  final canonical2 = canonicalize(dataset2);
  print('Canonical forms are identical: ${canonical1 == canonical2}'); // true

  print('Canonical form:\n$canonical1');
}
```

## ✨ Features

- **RDF Graph Canonicalization:** Deterministic serialization of RDF graphs with blank nodes
- **RDF Dataset Canonicalization:** Support for named graphs and quads canonicalization
- **Isomorphism Testing:** Test semantic equivalence between RDF graphs and datasets
- **Configurable Hash Algorithms:** Support for SHA-256 and SHA-384 hashing
- **Blank Node Relabeling:** Deterministic blank node identifier assignment
- **Standards Compliant:** Implements the RDF Dataset Canonicalization specification
- **Easy Integration:** Works seamlessly with `rdf_core` for complete RDF processing workflows

## Core API Usage

### Basic Canonicalization

```dart
import 'package:rdf_canonicalization/rdf_canonicalization.dart';
import 'package:rdf_core/rdf_core.dart';

void main() {
  // Create an RDF graph with blank nodes
  final alice = BlankNodeTerm();
  final bob = BlankNodeTerm();
  final graph = RdfGraph(triples: [
    Triple(alice, const IriTerm('http://xmlns.com/foaf/0.1/name'), LiteralTerm.string('Alice')),
    Triple(alice, const IriTerm('http://xmlns.com/foaf/0.1/knows'), bob),
    Triple(bob, const IriTerm('http://xmlns.com/foaf/0.1/name'), LiteralTerm.string('Bob')),
  ]);

  // Get canonical N-Quads representation
  final canonical = canonicalizeGraph(graph);
  print('Canonical representation:\n$canonical');
}
```

### Real-World Isomorphism Problem

```dart
import 'package:rdf_canonicalization/rdf_canonicalization.dart';
import 'package:rdf_core/rdf_core.dart';

void main() {
  // Two N-Quads documents from different sources with same semantic meaning
  final document1 = '''
    _:student <http://schema.org/name> "Alice Johnson" .
    _:student <http://schema.org/enrolledIn> _:course .
    _:course <http://schema.org/name> "Computer Science" .
  ''';

  final document2 = '''
    _:s1 <http://schema.org/name> "Alice Johnson" .
    _:s1 <http://schema.org/enrolledIn> _:c1 .
    _:c1 <http://schema.org/name> "Computer Science" .
  ''';

  // Parse both documents
  final data1 = nquads.decode(document1);
  final data2 = nquads.decode(document2);

  // Different representations, same meaning
  print('Documents are string-identical: ${document1 == document2}'); // false
  print('Datasets are object-equal: ${data1 == data2}'); // false
  print('But semantically isomorphic: ${isIsomorphic(data1, data2)}'); // true

  // Show canonical forms are identical
  print('\nCanonical form 1:\n${canonicalize(data1)}');
  print('Canonical form 2:\n${canonicalize(data2)}');
  print('Canonical forms match: ${canonicalize(data1) == canonicalize(data2)}'); // true
}
```

### Working with RDF Datasets

```dart
import 'package:rdf_canonicalization/rdf_canonicalization.dart';
import 'package:rdf_core/rdf_core.dart';

void main() {
  // Create dataset with named graphs and blank nodes
  final person = BlankNodeTerm();
  final orgGraph = const IriTerm('http://example.org/graphs/organizations');

  final dataset = RdfDataset.fromQuads([
    // Default graph
    Quad(person, const IriTerm('http://xmlns.com/foaf/0.1/name'), LiteralTerm.string('Alice')),

    // Named graph
    Quad(
      BlankNodeTerm(),
      const IriTerm('http://xmlns.com/foaf/0.1/name'),
      LiteralTerm.string('ACME Corp'),
      orgGraph
    ),
  ]);

  // Canonicalize the entire dataset
  final canonical = canonicalize(dataset);
  print('Canonical dataset:\n$canonical');

  // Test isomorphism between datasets
  final dataset2 = RdfDataset.fromQuads([
    Quad(
      BlankNodeTerm(),
      const IriTerm('http://xmlns.com/foaf/0.1/name'),
      LiteralTerm.string('ACME Corp'),
      orgGraph
    ),
    Quad(BlankNodeTerm(), const IriTerm('http://xmlns.com/foaf/0.1/name'), LiteralTerm.string('Alice')),
  ]);

  if (isIsomorphic(dataset, dataset2)) {
    print('Datasets are semantically equivalent!');
  }
}
```

### Custom Canonicalization Options

```dart
import 'package:rdf_canonicalization/rdf_canonicalization.dart';
import 'package:rdf_core/rdf_core.dart';

void main() {
  final graph = RdfGraph(triples: [
    Triple(BlankNodeTerm(), const IriTerm('http://example.org/property'), LiteralTerm.string('value')),
  ]);

  // Use SHA-384 instead of default SHA-256
  final options = const CanonicalizationOptions(
    hashAlgorithm: CanonicalHashAlgorithm.sha384,
    blankNodePrefix: 'custom'
  );

  final canonical = canonicalizeGraph(graph, options: options);
  print('Canonical with SHA-384:\n$canonical');
}
```

## 🧑‍💻 Advanced Usage

### Working with Canonical Classes

```dart
import 'package:rdf_canonicalization/rdf_canonicalization.dart';
import 'package:rdf_core/rdf_core.dart';

void main() {
  final graph = RdfGraph(triples: [
    Triple(BlankNodeTerm(), const IriTerm('http://example.org/name'), LiteralTerm.string('Example')),
  ]);

  // Create a canonical graph for repeated isomorphism tests (more efficient)
  final canonicalGraph = CanonicalRdfGraph(graph);

  // Create another canonical graph
  final graph2 = RdfGraph(triples: [
    Triple(BlankNodeTerm(), const IriTerm('http://example.org/name'), LiteralTerm.string('Example')),
  ]);
  final canonicalGraph2 = CanonicalRdfGraph(graph2);

  // Direct comparison using canonical forms (efficient)
  if (canonicalGraph == canonicalGraph2) {
    print('Graphs are isomorphic');
  }

  // Access the canonical N-Quads string
  print('Canonical form: ${canonicalGraph.canonicalNQuads}');
}
```

### Integration with RDF Core

```dart
import 'package:rdf_canonicalization/rdf_canonicalization.dart';
import 'package:rdf_core/rdf_core.dart';

void main() {
  // Parse RDF data and canonicalize
  final turtleData = '''
    @prefix foaf: <http://xmlns.com/foaf/0.1/> .
    _:alice foaf:name "Alice" .
    _:bob foaf:name "Bob" .
    _:alice foaf:knows _:bob .
  ''';

  final graph = turtle.decode(turtleData);
  final canonical = canonicalizeGraph(graph);

  print('Canonical representation:');
  print(canonical);

  // Parse the canonical form back to verify
  final canonicalGraph = ntriples.decode(canonical);

  // Verify they are isomorphic
  assert(isIsomorphicGraphs(graph, canonicalGraph));
  print('Original and canonical graphs are isomorphic: ✓');
}
```

### Performance Considerations

```dart
import 'package:rdf_canonicalization/rdf_canonicalization.dart';
import 'package:rdf_core/rdf_core.dart';

void main() {
  final graphs = <RdfGraph>[];

  // Create multiple graphs for comparison
  for (int i = 0; i < 100; i++) {
    final graph = RdfGraph(triples: [
      Triple(BlankNodeTerm(), const IriTerm('http://example.org/id'), LiteralTerm.string('$i')),
    ]);
    graphs.add(graph);
  }

  // For many isomorphism tests, pre-compute canonical forms
  final canonicalGraphs = graphs.map((g) => CanonicalRdfGraph(g)).toList();

  // Now comparisons are O(1) string comparisons instead of expensive graph isomorphism
  for (int i = 0; i < canonicalGraphs.length; i++) {
    for (int j = i + 1; j < canonicalGraphs.length; j++) {
      if (canonicalGraphs[i] == canonicalGraphs[j]) {
        print('Graphs $i and $j are isomorphic');
      }
    }
  }
}
```

---

## ⚠️ Error Handling

- Canonicalization functions throw `ArgumentError` for invalid input or null graphs/datasets
- Hash computation may throw `CanonicalizationException` for unsupported hash algorithms
- Catch and handle exceptions for robust canonicalization processing

---

## 🚦 Performance

- **Efficient blank node handling**: Uses optimized hash-based blank node labeling algorithm
- **Deterministic ordering**: Lexicographic sorting ensures consistent canonical output
- **Optimized for isomorphism testing**: `CanonicalRdfGraph` and `CanonicalRdfDataset` cache canonical forms for O(1) equality comparison
- **Configurable hashing**: Choose between SHA-256 (faster) and SHA-384 (more secure) based on your needs

---

## 🗺️ API Overview

| Type/Function           | Description                                   |
|------------------------|-----------------------------------------------|
| `canonicalize()`       | Canonicalize an RdfDataset to N-Quads string |
| `canonicalizeGraph()`  | Canonicalize an RdfGraph to N-Quads string   |
| `isIsomorphic()`       | Test if two RdfDatasets are isomorphic       |
| `isIsomorphicGraphs()` | Test if two RdfGraphs are isomorphic         |
| `CanonicalRdfGraph`    | Cached canonical representation of an RdfGraph |
| `CanonicalRdfDataset`  | Cached canonical representation of an RdfDataset |
| `CanonicalizationOptions` | Configuration for hash algorithm and blank node prefix |
| `CanonicalHashAlgorithm` | Enum for SHA-256 or SHA-384 hash algorithms |

---

## 📚 Standards & References

- [RDF Dataset Canonicalization](https://www.w3.org/TR/rdf-canon/) - W3C Specification for RDF canonicalization
- [RDF 1.1 Concepts](https://www.w3.org/TR/rdf11-concepts/) - Core RDF concepts and abstract syntax
- [RDF 1.1 Datasets](https://www.w3.org/TR/rdf11-datasets/) - RDF datasets with named graphs
- [N-Quads](https://www.w3.org/TR/n-quads/) - Line-based syntax for RDF datasets (canonical output format)

---

## 🧠 Use Cases

RDF canonicalization is essential for:

- **Digital Signatures**: Ensuring RDF data can be reliably signed and verified
- **Caching and Deduplication**: Using canonical forms as consistent cache keys
- **Data Synchronization**: Detecting changes in RDF datasets reliably
- **Graph Comparison**: Testing semantic equality between different RDF representations
- **Compliance and Standards**: Meeting requirements for deterministic RDF serialization

---

## 🛣️ Roadmap

- **Performance optimizations** for large graphs with many blank nodes
- **Streaming canonicalization** for memory-efficient processing of large datasets
- **RDF-star support** when the specification is finalized
- **Additional hash algorithms** as standardized by W3C

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!

- Fork the repo and submit a PR
- See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
- Join the discussion in [GitHub Issues](https://github.com/kkalass/rdf_canonicalization/issues)

---

## 🤖 AI Policy

This project is proudly human-led and human-controlled, with all key decisions, design, and code reviews made by people. At the same time, it stands on the shoulders of LLM giants: generative AI tools are used throughout the development process to accelerate iteration, inspire new ideas, and improve documentation quality. We believe that combining human expertise with the best of AI leads to higher-quality, more innovative open source software.

---

© 2025 Klas Kalaß. Licensed under the MIT License.
