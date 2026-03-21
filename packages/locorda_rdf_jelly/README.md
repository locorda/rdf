# Jelly RDF Binary Codec

[![pub package](https://img.shields.io/pub/v/locorda_rdf_jelly.svg)](https://pub.dev/packages/locorda_rdf_jelly)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/locorda/rdf/blob/main/LICENSE)

A [Jelly RDF](https://jelly-rdf.github.io/) binary serialization codec for [locorda_rdf_core](https://pub.dev/packages/locorda_rdf_core). Jelly is a high-performance, streaming binary format for RDF data based on Protocol Buffers, achieving significantly better compression and throughput than text-based formats like Turtle or N-Triples.

Part of the [Locorda RDF monorepo](https://github.com/locorda/rdf) with additional packages for core RDF functionality, canonicalization, object mapping, vocabulary generation, and more.

---

## Installation

```
dart pub add locorda_rdf_jelly
```

---

## 🚀 Quick Start

### Batch (non-streaming)

```dart
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';

// Use the pre-configured global codec directly
final graph = jellyGraph.decode(jellyBytes);
final bytes = jellyGraph.encode(graph);

// Dataset (named graphs)
final dataset = jelly.decode(jellyBytes);
final encoded = jelly.encode(dataset);
```

### Frame-level streaming

```dart
import 'package:locorda_rdf_jelly/jelly.dart';

// Encode a stream of triple batches — lookup tables are shared across all
// frames for maximum compression efficiency
final encoded = JellyTripleFrameEncoder().bind(frameStream);
await encoded.pipe(file.openWrite());

// Decode — emits one List<Triple> per physical Jelly frame
final triples = JellyTripleFrameDecoder()
    .bind(byteStream)
    .expand((frame) => frame);
```

### Integration with `RdfCore`

```dart
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';

// Register Jelly alongside other codecs for content-type dispatching
final rdfCore = RdfCore.withStandardCodecs(
  additionalBinaryGraphCodecs: [JellyGraphCodec()],
  additionalBinaryDatasetCodecs: [JellyDatasetCodec()],
);

// Codec-agnostic decode/encode via content type
final graph = rdfCore.decodeGraph(jellyBytes, contentType: jellyMimeType);
final bytes = rdfCore.encodeGraph(graph, contentType: jellyMimeType);
```

---

## ✨ Features

- **High performance** — Writes protobuf wire format directly (no `GeneratedMessage` allocation), with IRI/datatype lookup-table compression and repeated-term delta encoding. Fastest encoder in the suite — see [benchmarks](../../BENCHMARKS.md)
- **Frame-level streaming** — `JellyTripleFrameEncoder` / `JellyTripleFrameDecoder` (and quad equivalents) are idiomatic `StreamTransformerBase` instances, composable with `.bind()` and `.expand()`
- **Cross-frame table sharing** — In streaming mode the lookup tables accumulate across frames, giving better compression for continuous streams than independent per-frame encoding
- **All three physical stream types** — TRIPLES, QUADS, and GRAPHS, selectable via `JellyEncoderOptions.physicalType`
- **Batch API** — `JellyGraphCodec` / `JellyDatasetCodec` implement the `RdfBinaryGraphCodec` / `RdfBinaryDatasetCodec` interfaces for drop-in use with `RdfCore`
- **Configurable** — `JellyEncoderOptions` exposes table sizes, frame size, physical/logical stream type, and optional stream name; `JellyDecoderOptions` follows the same pattern for extensibility
- **Conformance tested** — Verified against 82 official Jelly-RDF conformance tests (RDF 1.1)

---

## Standards Compliance

This package is tested against the official [jelly-protobuf](https://github.com/Jelly-RDF/jelly-protobuf) conformance test suite, executed via `git submodule`. All RDF 1.1 test cases pass. RDF-star cases are tracked as a roadmap item (see below). Generalized RDF is intentionally out of scope — this library strictly follows the official RDF 1.1 specification.

### Decoding (`from_jelly`)

| Stream type | Positive | Negative | Total |
|---|---|---|---|
| TRIPLES | 17 | 10 | 27 |
| QUADS | 8 | 3 | 11 |
| GRAPHS | 11 | 2 | 13 |
| **Total** | **36** | **15** | **51** |

### Encoding (`to_jelly`)

| Stream type | Positive |
|---|---|
| TRIPLES | 16 |
| QUADS | 6 |
| GRAPHS | 9 |
| **Total** | **31** |

The `to_jelly` suite defines conformance in terms of RDF isomorphism: the encoded output is decoded and compared to the expected result rather than requiring bit-identical output. This allows flexibility in lookup-table layout while still verifying semantic correctness.

---

## Advanced Usage

### Encoder options

The physical stream type is determined entirely by the encoder class you choose — `JellyTripleFrameEncoder` always writes TRIPLES, `JellyQuadFrameEncoder` always writes QUADS. `JellyEncoderOptions` therefore only exposes table sizes, frame size, and metadata:

```dart
import 'package:locorda_rdf_jelly/jelly.dart';

final opts = JellyEncoderOptions(
  // Lookup table sizes — larger → better compression, more memory
  maxNameTableSize: 256,    // default: 128, min: 8 (spec requirement)
  maxPrefixTableSize: 64,   // default: 32
  maxDatatypeTableSize: 32, // default: 16

  // Maximum rows per frame — smaller → lower latency, more overhead
  maxRowsPerFrame: 512,     // default: 256

  // Optional informational metadata
  streamName: 'my-export',
);

final encoder = JellyTripleFrameEncoder(options: opts);
```

The one exception is `JellyDatasetEncoder`, which can emit either the flat QUADS physical type (default) or the GRAPHS physical type that preserves named-graph boundaries in the stream. Choose via `physicalType` in `JellyEncoderOptions` — this requires importing the internal proto enum:

```dart
import 'package:locorda_rdf_jelly/jelly.dart';
import 'package:locorda_rdf_jelly/src/proto/rdf.pbenum.dart';

// GRAPHS physical type keeps graph boundaries in the encoded stream
final encoder = JellyDatasetEncoder(
  options: JellyEncoderOptions(
    physicalType: PhysicalStreamType.PHYSICAL_STREAM_TYPE_GRAPHS,
  ),
);
```

### Streaming pipeline (quads / named graphs)

```dart
import 'package:locorda_rdf_jelly/jelly.dart';

// Quad (dataset) streaming
final Stream<Iterable<Quad>> quadFrameStream = ...;
final encoded = JellyQuadFrameEncoder().bind(quadFrameStream);
await encoded.pipe(sink);

final decoded = JellyQuadFrameDecoder()
    .bind(byteStream)
    .expand((frame) => frame);
```

### Multi-frame input files (encoding)

When a logical dataset spans multiple source files or chunks — for example
when streaming from a database in pages — feed each chunk as a separate batch
to the frame encoder. The shared lookup table state means later frames benefit
from IRIs already seen in earlier frames:

```dart
final encoder = JellyTripleFrameEncoder();
final controller = StreamController<Iterable<Triple>>();

final outputStream = encoder.bind(controller.stream);
outputStream.listen(sink.add, onDone: sink.close);

for (final page in pages) {
  controller.add(page);
}
await controller.close();
```

---

## Error Handling

Decoding throws a `RdfDecoderException` (from `locorda_rdf_core`) for:

- Malformed protobuf frames (truncated or corrupt data)
- Protocol violations caught by the Jelly specification (e.g. invalid stream type combinations, missing options row)
- Lookup table index out of range

Encoder constraint violations — such as specifying a `maxNameTableSize` below the spec minimum of 8 — are caught by a Dart `assert` at construction time, so they surface during development rather than at runtime in production.

```dart
try {
  final graph = jellyGraph.decode(corruptBytes);
} on RdfDecoderException catch (e) {
  // e.message contains a human-readable description of the violation
}
```

---

## Performance

Jelly consistently outperforms all text-based RDF codecs in both encoding speed and output size. On the large benchmark (17.2k triples), Jelly encodes in **80% of Turtle's time** while producing **75% of the output size**. See the full [benchmark results](../../BENCHMARKS.md) for detailed comparisons across all codecs and dataset sizes.

### Why is it fast?

The encoder writes protobuf wire format directly to byte buffers instead of constructing intermediate `GeneratedMessage` objects. Each proto object allocation costs ~200–400ns due to internal field arrays, type checking, and `BuilderInfo` setup — for a large graph this adds up to tens of thousands of unnecessary allocations. By computing field tags and varint-encoding in-place, the encoder eliminates this overhead entirely while producing byte-identical output (verified by dedicated [wire-format equivalence tests](test/src/raw_wire_format_equivalence_test.dart)).

On top of the raw encoding, two protocol-level mechanisms provide the compression advantage:

1. **Lookup tables** — IRIs and datatypes are assigned small integer IDs on first occurrence and referenced by ID thereafter. The encoder caches up to `maxNameTableSize` name entries, `maxPrefixTableSize` prefix entries, and `maxDatatypeTableSize` datatype entries simultaneously.

2. **Repeated-term delta encoding** — Subject, predicate, and object terms that repeat between consecutive triples are omitted entirely from the encoded row. Dense datasets with high locality (e.g. all triples about the same subject grouped together) benefit most.

Tune `maxRowsPerFrame` based on your latency vs. throughput trade-off:
- Larger frames → fewer frame headers → higher throughput
- Smaller frames → lower end-to-end latency for streaming consumers

The Jelly specification recommends keeping frames under 1 MB.

---

## API Overview

| Symbol | Kind | Description |
|---|---|---|
| `jellyGraph` | `RdfBinaryGraphCodec` | Pre-configured global codec for single-graph Jelly streams |
| `jelly` | `RdfBinaryDatasetCodec` | Pre-configured global codec for dataset Jelly streams |
| `jellyMimeType` | `String` | MIME type `application/x-jelly-rdf` |
| `JellyGraphCodec` | `RdfBinaryGraphCodec` | Instantiable graph codec for use with `RdfCore` |
| `JellyDatasetCodec` | `RdfBinaryDatasetCodec` | Instantiable dataset codec for use with `RdfCore` |
| `JellyGraphEncoder` | `RdfBinaryGraphEncoder` | Batch graph encoder (single `Uint8List` output) |
| `JellyGraphDecoder` | `RdfBinaryGraphDecoder` | Batch graph decoder (single `Uint8List` input) |
| `JellyDatasetEncoder` | `RdfBinaryDatasetEncoder` | Batch dataset encoder |
| `JellyDatasetDecoder` | `RdfBinaryDatasetDecoder` | Batch dataset decoder |
| `JellyTripleFrameEncoder` | `Converter` / `StreamTransformerBase` | Stateful frame-level triple encoder |
| `JellyTripleFrameDecoder` | `Converter` / `StreamTransformerBase` | Frame-level triple decoder |
| `JellyQuadFrameEncoder` | `Converter` / `StreamTransformerBase` | Stateful frame-level quad encoder |
| `JellyQuadFrameDecoder` | `Converter` / `StreamTransformerBase` | Frame-level quad decoder |
| `JellyEncoderOptions` | Value object | Lookup table sizes, frame size, stream type, stream name |
| `JellyDecoderOptions` | Value object | Extensibility hook for future decoder configuration |

---

## Roadmap / Next Steps

- **RDF-star support** — Decode and encode RDF-star (quoted triples) once `locorda_rdf_core` adds RDF-star term types
- **Negative encoder conformance tests** — Exercise the 2 `to_jelly` negative cases (invalid stream-type requests) once the error-mapping API is stabilised
- **Formal conformance reporting** — Submit results to the [Jelly conformance registry](https://jelly-rdf.github.io/dev/conformance/reporting-conformance/)

---

## References

- [Jelly RDF specification](https://jelly-rdf.github.io/dev/specification/serialization/)
- [Jelly-protobuf conformance test suite](https://github.com/Jelly-RDF/jelly-protobuf)
- [locorda_rdf_core](https://pub.dev/packages/locorda_rdf_core) — RDF model and binary codec registry
- [W3C RDF 1.1 Concepts](https://www.w3.org/TR/rdf11-concepts/)

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!

- Fork the repo and submit a PR
- See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
- Join the discussion in [GitHub Issues](https://github.com/locorda/rdf/issues)

---

## 🤖 AI Policy

This project is proudly human-led and human-controlled, with all key decisions,
design, and code reviews made by people. At the same time, it stands on the shoulders of LLM giants: generative AI tools are used throughout the development process to accelerate iteration, inspire new ideas, and improve documentation quality. We believe that combining human expertise with the best of AI leads to higher-quality, more innovative open source software.

---

© 2025-2026 Klas Kalaß. Licensed under the MIT License. Part of the [Locorda RDF monorepo](https://github.com/locorda/rdf).
