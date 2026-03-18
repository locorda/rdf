# RDF XML

[![pub package](https://img.shields.io/pub/v/locorda_rdf_xml.svg)](https://pub.dev/packages/locorda_rdf_xml)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/locorda/rdf/blob/main/LICENSE)

A RDF/XML decoder and encoder for the [locorda_rdf_core](https://pub.dev/packages/locorda_rdf_core) library, offering a complete implementation of the W3C RDF/XML specification.

Part of the [Locorda RDF monorepo](https://github.com/locorda/rdf) with additional packages for core RDF functionality, canonicalization, object mapping, vocabulary generation, and more.

[🌐 **Official Documentation**](https://locorda.dev/rdf/xml)

---

## 📋 Features

- **W3C conformant** - Passes all 166 W3C RDF/XML conformance tests
- **Complete RDF/XML support** - Full implementation of the W3C RDF/XML standard
- **High performance** - Optimized for both speed and memory efficiency
- **Configurable behavior** - Strict or lenient parsing modes, formatting options
- **Clean architecture** - Follows SOLID principles with dependency injection
- **Extensible design** - Easy to customize and adapt to specific needs
- **Well tested** - Comprehensive test suite including W3C conformance tests

## 🚀 Installation

```bash
dart pub add locorda_rdf_xml
```

## 📖 Usage

### Decoding RDF/XML

```dart
import 'package:locorda_rdf_xml/xml.dart';

void main() {
  final xmlContent = '''
    <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
             xmlns:dc="http://purl.org/dc/elements/1.1/">
      <rdf:Description rdf:about="http://example.org/resource">
        <dc:title>Example Resource</dc:title>
        <dc:creator>Example Author</dc:creator>
      </rdf:Description>
    </rdf:RDF>
  ''';

  // Use the global rdfxml codec
  final rdfGraph = rdfxml.decode(xmlContent);
  
  // Print the decoded triples
  for (final triple in rdfGraph.triples) {
    print(triple);
  }
}
```



### Encoding to RDF/XML

```dart
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_xml/xml.dart';

void main() {
  // Create a graph with some triples
  final graph = RdfGraph.fromTriples([
    Triple(
      const IriTerm('http://example.org/resource'),
      const IriTerm('http://purl.org/dc/elements/1.1/title'),
      LiteralTerm.string('Example Resource'),
    ),
    Triple(
      const IriTerm('http://example.org/resource'),
      const IriTerm('http://purl.org/dc/elements/1.1/creator'),
      LiteralTerm.string('Example Author'),
    ),
  ]);

  // Use the global rdfxml codec
  final rdfXml = rdfxml.encode(graph);
  
  print(rdfXml);
}
```

### Integration with RdfCore

```dart
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_xml/xml.dart';

void main() {
  final xmlContent = '''
    <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
             xmlns:dc="http://purl.org/dc/elements/1.1/">
      <rdf:Description rdf:about="http://example.org/resource">
        <dc:title>Example Resource</dc:title>
        <dc:creator>Example Author</dc:creator>
      </rdf:Description>
    </rdf:RDF>
  ''';

  // Register the codec with RdfCore
  final rdfCore = RdfCore.withStandardCodecs(additionalCodecs: [RdfXmlCodec()]);

  // Decode using RdfCore
  final rdfGraph = rdfCore.decode(xmlContent, contentType: "application/rdf+xml");
  
  // Print the decoded triples
  for (final triple in rdfGraph.triples) {
    print(triple);
  }

  // Encode using RdfCore with specified content type
  final rdfXml = rdfCore.encode(rdfGraph, contentType: "application/rdf+xml");
  
  print(rdfXml);
}
```

### Decoding from a File

```dart
import 'dart:io';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_xml/xml.dart';

Future<void> parseFromFile(String filePath) async {
  final file = File(filePath);
  final xmlContent = await file.readAsString();
  
  // Decode with base URI set to the file location
  final rdfGraph = rdfxml.decode(
    xmlContent, 
    documentUrl: 'file://${file.absolute.path}',
  );
  
  print('Parsed ${rdfGraph.size} triples from $filePath');
}
```

## ⚙️ Configuration

### Decoder Options

```dart
// Create a codec with strict validation
final strictCodec = RdfXmlCodec.strict();

// Create a codec that handles non-standard RDF/XML
final lenientCodec = RdfXmlCodec.lenient();

// Custom configuration
final customCodec = RdfXmlCodec(
  decoderOptions: RdfXmlDecoderOptions(
    strictMode: false,
    normalizeWhitespace: true,
    validateOutput: true,
    maxNestingDepth: 50,
  ),
);
```

### Encoder Options

```dart
// Human-readable output
final readableCodec = RdfXmlCodec.readable();

// Compact output for storage
final compactCodec = RdfXmlCodec.compact();

// Custom configuration
final customCodec = RdfXmlCodec(
  encoderOptions: RdfXmlEncoderOptions(
    prettyPrint: true,
    indentSpaces: 4,
    useTypedNodes: true,
    includeBaseDeclaration: true, // Controls xml:base attribute inclusion
  ),
);

// Control base URI handling
final baseUri = 'http://example.org/base/';
final withBase = rdfxml.encode(graph, baseUri: baseUri); // Includes xml:base
final withoutBase = RdfXmlCodec(
  encoderOptions: RdfXmlEncoderOptions(includeBaseDeclaration: false)
).encode(graph, baseUri: baseUri); // Omits xml:base but still relativizes URIs
```

> 💡 **See also**: Check out [`example/base_uri_handling.dart`](example/base_uri_handling.dart) for a comprehensive demonstration of base URI options and practical use cases.

## 📚 RDF/XML Features

This library supports all features of the RDF/XML syntax and passes all 166 W3C RDF/XML conformance tests (126 positive evaluation tests + 40 negative syntax tests):

- Resource descriptions (rdf:Description)
- Typed node elements
- Property elements with XML literal canonicalization (C14N)
- Container elements (rdf:Bag, rdf:Seq, rdf:Alt)
- Collection elements (rdf:List)
- rdf:parseType (Resource, Literal, Collection)
- XML Base support with correct fragment resolution (RFC 3986)
- XML language tag inheritance across element hierarchy
- IRI support with correct non-ASCII handling (RFC 3987)
- Datatyped literals
- Blank nodes (anonymous and labeled)
- RDF reification

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!

- Fork the repo and submit a PR
- See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines
- Join the discussion in [GitHub Issues](https://github.com/locorda/rdf/issues)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤖 AI Policy

This project is proudly human-led and human-controlled, with all key decisions, design, and code reviews made by people. At the same time, it stands on the shoulders of LLM giants: generative AI tools are used throughout the development process to accelerate iteration, inspire new ideas, and improve documentation quality. We believe that combining human expertise with the best of AI leads to higher-quality, more innovative open source software.

---

© 2025-2026 Klas Kalaß. Licensed under the MIT License. Part of the [Locorda RDF monorepo](https://github.com/locorda/rdf).
