# Plan: Jelly RDF Binary Format Support

## Context

The current codec system is entirely text-based (`Converter<G, String>`). Jelly RDF is a
Protocol Buffers-based binary streaming format that achieves ~16% the size of N-Triples and
~7-15M triples/sec throughput. Adding it requires binary codec abstractions and streaming APIs
that don't yet exist in the codebase.

## Key Design Decisions

### 1. Package Structure

**Two new packages:**

| Package | Purpose |
|---------|---------|
| `locorda_rdf_core` (extended) | New binary codec base classes + streaming interfaces |
| `locorda_rdf_jelly` | Jelly-specific implementation (protobuf, lookup tables, etc.) |

**Rationale:** Binary codec abstractions belong in core (just like text codec abstractions).
The Jelly implementation is a separate package (like `locorda_rdf_xml`) so users only pull in
`protobuf` when they actually need Jelly. This also keeps the door open for other binary
formats (e.g., HDT) later.

### 2. Binary Codec Abstractions (in core)

The existing text codecs use `Converter<G, String>`. Binary codecs need `Uint8List`.
We introduce a parallel hierarchy:

```
RdfBinaryCodec<G>                    (parallel to RdfCodec<G>)
├── RdfBinaryGraphCodec              (parallel to RdfGraphCodec)
└── RdfBinaryDatasetCodec            (parallel to RdfDatasetCodec)

RdfBinaryDecoder<G>                  (Converter<Uint8List, G>)
├── RdfBinaryGraphDecoder
└── RdfBinaryDatasetDecoder

RdfBinaryEncoder<G>                  (Converter<G, Uint8List>)
├── RdfBinaryGraphEncoder
└── RdfBinaryDatasetEncoder
```

These mirror the text APIs but work with `Uint8List` instead of `String`.
`canParse(String)` becomes `canParseBytes(Uint8List)`.

A `RdfBinaryCodecRegistry` and integration into `RdfCore` will follow the same
pattern as existing registries (with `additionalBinaryCodecs` etc.).

### 3. Streaming API (in core)

Jelly is inherently streaming — frames arrive over time. We define streaming
interfaces using Dart's native `Stream<T>`:

```dart
/// Streaming decoder: bytes → stream of triples/quads
abstract class RdfStreamingDecoder {
  Stream<Triple> decodeTriples(Stream<List<int>> input);
  Stream<Quad> decodeQuads(Stream<List<int>> input);
}

/// Streaming encoder: stream of triples/quads → bytes
abstract class RdfStreamingEncoder {
  Stream<List<int>> encodeTriples(Stream<Triple> triples, {RdfStreamingEncoderOptions? options});
  Stream<List<int>> encodeQuads(Stream<Quad> quads, {RdfStreamingEncoderOptions? options});
}
```

The batch (non-streaming) `RdfBinaryCodec` can be implemented on top of these
by collecting the stream, so the streaming API is the primary one.

### 4. Jelly Implementation Details

**Protobuf:** Use `package:protobuf` with generated Dart code from the official
`.proto` files in [jelly-protobuf](https://github.com/Jelly-RDF/jelly-protobuf).

**Core components:**
- `JellyCodec` / `JellyDatasetCodec` — extends `RdfBinaryGraphCodec` / `RdfBinaryDatasetCodec`
- `JellyStreamingDecoder` — implements `RdfStreamingDecoder`
  - Manages prefix/name/datatype lookup tables
  - Handles repeated-term compression (zero-cost same-position terms)
  - Supports TRIPLES, QUADS, and GRAPHS physical stream types
- `JellyStreamingEncoder` — implements `RdfStreamingEncoder`
  - Builds and emits lookup table entries
  - Configurable frame size, table sizes
  - Repeated-term compression
- `JellyOptions` — table sizes, physical/logical stream type, RDF-star support

**Not in scope (initially):**
- gRPC streaming service (can be layered on later)
- RDF-star / quoted triples (can be added once core supports RDF-star)
- Jelly Patch format

### 5. Test Strategy

**Official conformance suite:** The [jelly-protobuf](https://github.com/Jelly-RDF/jelly-protobuf)
repo contains 187 tests (110 parse, 77 serialize) with Turtle manifests.

**Plan:**
1. Add `jelly-protobuf` as a git submodule under `test_assets/jelly/jelly-protobuf`
   (following the existing pattern for W3C tests in `test_assets/w3c/rdf-tests`)
2. Parse the Turtle manifests to discover test cases
3. For "from_jelly" tests: decode `.jelly` binary → compare against expected RDF (N-Triples/N-Quads)
4. For "to_jelly" tests: encode input RDF → decode result → verify isomorphic match
5. Negative tests: verify graceful failure on malformed input

**Additional tests:**
- Round-trip: encode → decode → verify isomorphic graphs
- Streaming: verify incremental processing (not buffering everything)
- Edge cases: empty graphs, large literals, Unicode, deeply nested blank nodes

## Implementation Phases

### Phase 1: Core Binary Abstractions
1. Add `RdfBinaryDecoder`, `RdfBinaryEncoder` base classes to `locorda_rdf_core`
2. Add `RdfBinaryGraphCodec`, `RdfBinaryDatasetCodec`
3. Add `RdfBinaryCodecRegistry` and wire into `RdfCore`
4. Add `RdfStreamingDecoder`, `RdfStreamingEncoder` interfaces
5. Unit tests for the abstractions

### Phase 2: Jelly Package Scaffolding
1. Create `locorda_rdf_jelly` package with pubspec, exports
2. Add `jelly-protobuf` as git submodule at `test_assets/jelly/jelly-protobuf`
3. Copy `.proto` files into package, generate Dart protobuf code
4. Wire conformance test suite from the submodule

### Phase 3: Jelly Streaming Decoder
1. Implement `RdfStreamFrame` / `RdfStreamRow` processing
2. Implement lookup tables (prefix, name, datatype) with eviction
3. Implement IRI reconstruction (prefix + name concatenation)
4. Implement repeated-term decompression
5. Implement `JellyStreamingDecoder` for TRIPLES physical type
6. Extend for QUADS and GRAPHS physical types
7. Implement `JellyGraphDecoder` / `JellyDatasetDecoder` (batch, on top of streaming)
8. Run "from_jelly" conformance tests

### Phase 4: Jelly Streaming Encoder
1. Implement lookup table builder with configurable sizes
2. Implement IRI splitting (prefix/name) heuristics
3. Implement repeated-term compression
4. Implement frame chunking (configurable max frame size)
5. Implement `JellyStreamingEncoder` for TRIPLES type
6. Extend for QUADS and GRAPHS types
7. Implement `JellyGraphEncoder` / `JellyDatasetEncoder` (batch, on top of streaming)
8. Run "to_jelly" conformance tests

### Phase 5: Integration & Polish
1. Add `decodeBinary` / `encodeBinary` / `decodeBinaryDataset` / `encodeBinaryDataset`
   methods to `RdfCore`, backed by `RdfBinaryCodecRegistry`
2. Wire into `RdfCore.withStandardCodecs(additionalBinaryCodecs: [...])`
3. Add `final jelly = JellyCodec();` convenience instance
4. Delimited file format support (varint-prefixed frames for `.jelly` files)
5. Performance benchmarks vs Turtle
6. Documentation and examples

## Resolved Questions

1. **Namespace declarations** (Jelly v1.1): Treated as cosmetic-only, like prefix maps
   in Turtle/TriG. Not carried through the data model.

2. **RDF-star**: Deferred — we only support RDF 1.1. Jelly input containing quoted
   triples will be rejected with a clear error.

3. **Binary codec registration**: Separate `RdfBinaryCodecRegistry` (different type
   signatures — `Uint8List` not `String`). `RdfCore` gets new **dedicated binary methods**
   (`decodeBinary`, `encodeBinary`, `decodeBinaryDataset`, `encodeBinaryDataset`) rather
   than weakening the existing `String`-typed `decode`/`encode` signatures.
