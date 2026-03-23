# JSON-LD Encoder Modes — Concept & Implementation Plan

## 1. Goal

Implement two JSON-LD output modes — **expanded** and **compact** — and pass the
corresponding W3C test suites:

| Test Suite  | Positive | Negative | Total | Pipeline |
|-------------|----------|----------|-------|----------|
| **fromRdf** | ~50      | ~3       | ~53   | NQuads → decode → **expanded encode** |
| **expand**  | ~276     | ~109     | ~385  | JSON-LD → decode → **expanded encode** |
| **compact** | ~229     | ~17      | ~246  | JSON-LD → decode → **compact encode** (with provided context) |

Tests requiring `GeneralizedRdf` will be skipped (not representable in our data
model).

---

## 2. Quality Requirements & Design Principles

### 2.1 Code Quality

- **Clean, idiomatic Dart**: All new code must follow Dart conventions. No `dynamic`
  types in place of precise types — use exact type annotations (`Map<String, Object>`,
  `List<Map<String, Object>>`, sealed classes, records, etc.).
- **Full static type safety**: The expanded JSON-LD intermediate structure must be
  properly typed, not passed around as `dynamic` or `Object?` without narrowing.
- **Effective Dart**: Follow the official Effective Dart guidelines for API design,
  naming, documentation, and style.

### 2.2 Architecture Principles

- **DRY**: Context processing logic exists once and only once. The decoder's context
  processing (~700 lines covering `_extractSingleContext`, `_parseTermDefinition`,
  `_mergeContextDefinition`, `_expandPredicate`) **must be extracted** into a shared
  `JsonLdContextProcessor` module. The expansion processor, compaction processor,
  and decoder all use this shared module. **No duplication of context processing
  logic.**
- **Separation of Concerns**: Each module has exactly one responsibility:
  - `JsonLdContextProcessor` — context parsing and term resolution
  - `JsonLdExpandedSerializer` — RDF → expanded JSON-LD
  - `JsonLdExpansionProcessor` — JSON-LD → expanded JSON-LD
  - `JsonLdCompactionProcessor` — expanded JSON-LD + context → compact JSON-LD
  - `JsonLdEncoder` — orchestration and `RdfDatasetEncoder` contract
- **KISS**: No speculative abstractions. Build exactly what the spec requires,
  no more.
- **SOLID**: Each class has a single reason to change. Depend on abstractions
  (e.g., `JsonLdContextDocumentProvider`) not concrete implementations.
- **Composition over Inheritance**: The encoder composes the serializer and
  processors, it does not inherit from them.
- **Immutability**: `JsonLdContext` and `TermDefinition` are immutable value
  objects (they already are in the decoder — maintain this when extracting).

### 2.3 Testability

- Every module must be independently testable.
- `JsonLdContextProcessor` gets its own unit tests (context merging, term parsing,
  IRI expansion) before being consumed by other modules.
- All W3C test suites run as integration tests.
- Existing decoder tests (2394+) must continue to pass throughout all phases.

---

## 3. Key Observations from the W3C Tests

### 3.1 Expanded JSON-LD Format (fromRdf & expand output)

The expected output is **always** a top-level JSON array containing node objects.
Every node object follows strict rules:

```jsonc
[
  {
    "@id": "http://full/iri",                          // full IRI, always present
    "@type": ["http://full/type/iri"],                 // always array of full IRIs
    "http://full/predicate/iri": [                     // always array
      {"@value": "plain string"},                      // plain strings: {"@value": "..."}
      {"@value": "42", "@type": "http://...#integer"}, // typed: full datatype IRI
      {"@value": "en-text", "@language": "en"},        // lang-tagged
      {"@id": "http://other/node"}                     // node reference
    ],
    "@graph": [...]                                    // named graph contents
  }
]
```

Key rules that **differ from our current encoder output**:

| Rule | Current encoder | Required for expanded |
|------|-----------------|----------------------|
| Top level | single object or `{@context, @graph}` | always a plain `[...]` array |
| `@context` | auto-generated with prefixes | **none** |
| Predicates | compact `foaf:name` | full IRI `http://xmlns.com/foaf/0.1/name` |
| `@type` values | single string or array | **always array** |
| Property values | single value or array | **always array** |
| String literals | bare `"Alice"` | `{"@value": "Alice"}` |
| xsd:integer | native `42` | `{"@value": "42", "@type": "http://...#integer"}` (unless `useNativeTypes`) |
| xsd:boolean | native `true`/`false` | `{"@value": "true", "@type": "http://...#boolean"}` (unless `useNativeTypes`) |
| xsd:string | bare string | `{"@value": "string"}` (no `@type` at all) |
| xsd:double | native `3.14` | `{"@value": "3.14E0", "@type": "http://...#double"}` (unless `useNativeTypes`) |
| IRI objects | `{"@id": "compact:iri"}` | `{"@id": "http://full/iri"}` |
| Blank nodes | `_:b0` | `_:b0` (same) |
| RDF lists | not handled | convert `rdf:first/rest/nil` chains to `{"@list": [...]}` |
| Named graphs | `{@id, @graph}` | same, but graph node can also have own properties |

### 3.2 Compact JSON-LD Format (compact output)

The compaction algorithm takes **expanded JSON-LD** + a **context** and produces
compact output. Key operations:

1. **Term selection**: Given a full IRI and context, pick the best matching term
   (term alias > prefix:local > full IRI)
2. **Value compaction**: If a term has `@type: @id`, strip `{"@id": ...}` wrapper.
   If a term has `@type: xsd:integer`, strip `{"@value": "42", "@type": ...}` to
   native `42`. Etc.
3. **Array compaction**: Single-element arrays are unwrapped to bare values
   (unless `compactArrays: false`)
4. **Container handling**: `@container: @language` → language map,
   `@container: @index` → index map, `@container: @list` → inline array, etc.
5. **@vocab resolution**: If `@vocab` is set, predicates matching it are shortened
   to bare terms
6. **Structural nesting**: `@reverse`, `@nest`, `@included`, `@graph` containers

### 3.3 Expand & Compact Tests — What Survives RDF Round-Trip?

See **Appendix A** for a detailed explanation of each non-RDF feature, how the
decoder handles it, and why it cannot survive an RDF round-trip.

Of the ~276 positive expand tests, ~57 produce output containing `@index`,
`@reverse`, `@included`, or `@direction` — information that is **not representable
in RDF** and therefore cannot survive decode → re-encode.

### 3.4 Implications

- **fromRdf** tests: RDF → JSON-LD (our encoder's natural domain)
- **expand** tests: JSON-LD → JSON-LD expansion (a **JSON-LD processor** algorithm,
  not an RDF encoder)
- **compact** tests: JSON-LD → JSON-LD compaction (same — a **JSON-LD processor**
  algorithm)

Passing expand and compact tests requires implementing the W3C **Expansion
Algorithm** and **Compaction Algorithm** as JSON-LD document transformations,
separate from RDF encoding/decoding.

The ~57 expand tests and corresponding compact tests that rely on non-RDF features
cannot pass through an RDF pipeline. They **must** be handled by the expansion and
compaction processors operating on the JSON-LD document model directly.

---

## 4. Architecture

### 4.1 Three Distinct Concerns

```
┌─────────────────────────────────────────────────────────────┐
│                    JSON-LD Processor                         │
│                                                             │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐    │
│  │  Expansion    │   │  Compaction   │   │   fromRdf    │    │
│  │  Algorithm    │   │  Algorithm    │   │  Algorithm   │    │
│  │              │   │              │   │              │    │
│  │ JSON→JSON    │   │ JSON→JSON    │   │ RDF→JSON     │    │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘    │
│         │                  │                  │             │
│         ▼                  ▼                  ▼             │
│  expanded JSON-LD    compact JSON-LD    expanded JSON-LD    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                 RDF Codec Layer (existing)                   │
│                                                             │
│  ┌──────────────┐                    ┌──────────────┐       │
│  │ JsonLdDecoder │                    │ JsonLdEncoder │       │
│  │ (JSON→RDF)   │                    │ (RDF→JSON)   │       │
│  └──────────────┘                    └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Module Design

#### A) `JsonLdExpandedSerializer` (new) — fromRdf Algorithm

Implements the W3C **Deserialize JSON-LD to RDF** algorithm in reverse
(**Serialize RDF to JSON-LD** / **fromRdf**). Takes `RdfDataset` → produces
expanded JSON-LD (a `List<Map<String, Object>>`).

This is the core of the expanded encoder and handles:
- Subject grouping
- `rdf:type` → `@type` conversion (configurable via `useRdfType`)
- RDF list detection (`rdf:first/rest/nil` → `@list`)
- Native type conversion (configurable via `useNativeTypes`)
- Named graph → `@graph` conversion
- Blank node label management
- All values in arrays, all strings wrapped in `{"@value": ...}`
- `rdf:direction` handling (i18n-datatype, compound-literal)

**Options**: `useNativeTypes`, `useRdfType`, `rdfDirection`

#### B) `JsonLdExpansionProcessor` (new) — Expansion Algorithm

Implements the W3C **Expansion Algorithm** (§ 4.1 of JSON-LD API spec).
Takes any JSON-LD document → produces expanded JSON-LD.

This is needed for the expand tests and internally as the first step of the
compact pipeline. Our **existing decoder already implements most of this logic**
(it expands context, resolves term definitions, handles `@container`, `@reverse`,
`@nest`, etc.) — but it outputs RDF triples, discarding JSON-LD-only information
like `@index`, `@reverse` nesting structure, and `@included`.

**Approach**: The expansion processor uses the shared `JsonLdContextProcessor`
(extracted from the decoder, see § 2.2) for context handling, and implements only
the expansion-specific document walk that builds expanded JSON-LD output. This
means:
- Context processing: **shared** with decoder (single implementation)
- Document traversal & expanded output construction: **new code**, specific to
  expansion (the decoder's traversal emits RDF triples; the expansion processor's
  traversal emits expanded JSON-LD nodes)
- The decoder is then refactored to also use `JsonLdContextProcessor`, replacing
  its current inline context methods

This approach maximizes code reuse while keeping the expansion and RDF-emission
concerns cleanly separated.

#### C) `JsonLdCompactionProcessor` (new) — Compaction Algorithm

Implements the W3C **Compaction Algorithm** (§ 4.2 of JSON-LD API spec).
Takes expanded JSON-LD + context → produces compact JSON-LD.

The compaction algorithm is well-specified and modular:
1. **Context Processing** (§ 4.1.2): Parse `@context` into an active context
   with term definitions
2. **IRI Compaction** (§ 4.2.1): Select the best term/prefix for a given IRI
3. **Value Compaction** (§ 4.2.2): Strip value objects when context allows
4. **Compaction** (§ 4.2): Walk expanded document, compact each node

**Key sub-algorithms:**
- **Term selection**: Given IRI + value type + container, pick best matching term
- **Value compaction**: If term defines `@type`, `@language`, or `@container`,
  simplify value representation
- **Array compaction**: Unwrap single-element arrays (configurable)

#### D) `JsonLdEncoder` (refactored) — RDF Codec Integration

The existing `JsonLdEncoder` becomes a thin orchestrator:

```dart
enum JsonLdOutputMode { expanded, compact }

class JsonLdEncoderOptions extends RdfDatasetEncoderOptions {
  final JsonLdOutputMode outputMode;        // default: compact
  final Map<String, Object>? context;      // for compact mode
  final bool useNativeTypes;                // for expanded/fromRdf mode
  final bool useRdfType;                    // for expanded/fromRdf mode
  final String? rdfDirection;               // i18n-datatype | compound-literal
  // existing: customPrefixes, generateMissingPrefixes, includeBaseDeclaration
}
```

**Encode flow:**
- `expanded` mode: `RdfDataset` → `JsonLdExpandedSerializer` → JSON string
- `compact` mode:
  - `RdfDataset` → `JsonLdExpandedSerializer` → expanded JSON-LD
  - If `context` provided → `JsonLdCompactionProcessor(context)` → compact JSON
  - If `context` not provided → auto-generate context from prefix mappings
    (current behaviour, using `IriCompaction`), then compact

---

## 5. Performance Analysis

### 5.1 Compact Mode: Two-Step (expand → compact) vs. Direct Generation

The compact encoder pipeline is: `RdfDataset → expanded JSON-LD → compact JSON-LD`.
An alternative would be to produce compact JSON-LD directly from RDF triples.

**Two-step approach (recommended):**
- Step 1 (fromRdf): Walk all triples once, build in-memory expanded JSON-LD
  structure (maps and lists). O(n) where n = number of triples.
- Step 2 (compaction): Walk the expanded structure once, apply term selection and
  value compaction, produce compact structure. O(m) where m = number of JSON nodes.
- Total: Two O(n) passes over the data, one intermediate data structure in memory.

**Direct generation:**
- Would need to consult the context during triple emission to decide term names,
  value shapes, container structures, etc.
- The W3C compaction algorithm is **defined** in terms of expanded input. Building
  a correct direct-production compactor means reimplementing the compaction spec
  from scratch in a different paradigm — high complexity, high bug risk.
- Any optimization we'd gain from avoiding the intermediate structure is negligible
  compared to the complexity cost.

**Performance impact of the intermediate structure:**

| Dataset size | Expanded JSON-LD memory | Compaction pass time |
|-------------|------------------------|---------------------|
| 1K triples  | ~100-200 KB            | < 1 ms              |
| 10K triples | ~1-2 MB                | < 10 ms             |
| 100K triples| ~10-20 MB              | < 100 ms            |
| 1M triples  | ~100-200 MB            | < 1 s               |

The intermediate maps/lists are lightweight Dart objects (no string serialization
at this stage). The extra memory is proportional to the output size — we'd
allocate something similar in any case. The extra pass is a simple tree walk.

For typical use cases (JSON-LD documents with hundreds to low thousands of
triples), the overhead is **unmeasurable**. For very large datasets, the
bottleneck would be I/O and string serialization, not the intermediate structure.

### 5.2 Expansion Processor (expand tests)

The expansion processor operates on parsed JSON (the output of `jsonDecode`). It
walks the input document once, resolving contexts and building expanded output.
This is a single O(n) pass — no performance concern.

### 5.3 Summary

The two-step approach adds negligible overhead while keeping the code
spec-compliant, testable, and maintainable. Direct compact generation would save
one in-memory tree walk at the cost of significantly higher code complexity and
deviation from the spec's algorithm definitions. Not worth it.

---

## 6. Implementation Phases

### Phase 0: Extract Shared Context Processing

**Goal**: Make context processing reusable before building new consumers.

**Tasks**:
1. Move `_TermDefinition` and `_JsonLdContext` to a public shared module
   `lib/src/jsonld/jsonld_context.dart`. Rename to `TermDefinition` and
   `JsonLdContext` (drop private prefix). Adjust visibility.
2. Create `JsonLdContextProcessor` class in
   `lib/src/jsonld/jsonld_context_processor.dart`:
   - Constructor takes `processingMode`, `contextDocumentProvider`, optional
     `contextDocumentCache`
   - Extract `_extractSingleContext` → `processSingleContext()`
   - Extract `_parseTermDefinition` → `parseTermDefinition()`
   - Extract `_mergeContextDefinition` → `mergeContext()`
   - Extract `_expandPredicate` → `expandIri()`
   - External context loading stays as-is (already uses provider abstraction)
   - Base URI handling: return updated base URI along with new context
     (e.g., as a record `(JsonLdContext, Uri?)`) instead of mutating instance
     state
3. Refactor `JsonLdParser` (decoder) to delegate to `JsonLdContextProcessor`
   instead of having these methods inline. All existing tests must still pass.
4. Unit test `JsonLdContextProcessor` independently.

**Estimated scope**: ~200-300 lines of new code, ~700 lines moved/adapted.
Moderate effort but zero new algorithm logic — pure structural refactoring.

### Phase 1: Expanded Encoder (fromRdf tests)

**Goal**: Pass all ~50 positive fromRdf tests.

**Tasks**:
1. Create `JsonLdExpandedSerializer` class
   - Input: `RdfDataset`
   - Output: `List<Map<String, Object>>` (the expanded JSON-LD array)
2. Implement core fromRdf algorithm:
   - Subject grouping (existing logic, adapted)
   - `rdf:type` → `@type` (always array)
   - All property values always wrapped in arrays
   - All string literals → `{"@value": "..."}` (no bare strings)
   - Typed literals → `{"@value": "...", "@type": "full-iri"}`
   - Language-tagged → `{"@value": "...", "@language": "..."}`
   - IRI objects → `{"@id": "full-iri"}` (inside array)
   - Named graphs → `{@id, @graph, ...own-properties}`
3. Implement RDF list detection:
   - Walk `rdf:first`/`rdf:rest` chains
   - Only convert to `@list` if: terminates at `rdf:nil`, no branching,
     no extra predicates on list nodes, not used as subject of other triples
   - Partially valid lists → keep as raw `rdf:first`/`rdf:rest` triples
4. Implement `useNativeTypes` option:
   - When true: `xsd:integer` → JSON number, `xsd:double` → JSON number,
     `xsd:boolean` → JSON boolean
   - When false (default): all typed literals stay as `{"@value", "@type"}`
5. Implement `useRdfType` option:
   - When true: `rdf:type` rendered as regular predicate, not `@type`
6. Add `JsonLdOutputMode.expanded` to `JsonLdEncoderOptions`
7. Wire into `JsonLdEncoder.convert()`: when mode is expanded, use
   `JsonLdExpandedSerializer` and return `jsonEncode(result)`
8. Write fromRdf W3C test runner (parse fromRdf-manifest.jsonld, run tests)

**Estimated scope**: ~400-600 lines of new code + tests

### Phase 2: Expansion Algorithm (expand tests)

**Goal**: Pass all ~276 positive and ~109 negative expand tests.

**Tasks**:
1. Implement **Context Processing Algorithm** (§ 4.1.2):
   - Parse `@context` objects and arrays
   - Build active context with term definitions
   - Handle `@base`, `@vocab`, `@language`, `@direction`, `@propagate`
   - Handle `@protected`, `@import`
   - Handle remote context loading (reuse existing
     `JsonLdContextDocumentProvider`)
   - Handle scoped contexts on terms
2. Implement **Expansion Algorithm** (§ 4.1):
   - Walk input JSON document
   - Expand property names using active context
   - Expand values according to term definitions (`@type` coercion, `@language`,
     `@container`)
   - Handle `@graph`, `@index`, `@reverse`, `@nest`, `@included`
   - Handle `@list`, `@set`
   - Handle `@json` type (JSON literals)
   - Produce expanded JSON-LD output (array of node objects)
3. Write expand W3C test runner
4. Handle negative tests (detect and throw appropriate errors for invalid
   contexts, circular references, etc.)

**Dependencies**: Phase 0 (uses extracted `JsonLdContextProcessor`).

**Estimated scope**: ~800-1500 lines of new code (significantly less than a
from-scratch implementation because context processing is shared).

### Phase 3: Compaction Algorithm (compact tests)

**Goal**: Pass all ~229 positive and ~17 negative compact tests.

**Tasks**:
1. Implement **IRI Compaction Algorithm** (§ 4.2.1):
   - Given IRI, active context, and value characteristics → select best term
   - Priority: exact term alias > `@vocab`-relative > prefix:local > full IRI
   - Consider `@type` coercion, `@container`, `@language` when ranking
2. Implement **Value Compaction Algorithm** (§ 4.2.2):
   - With term's type coercion: strip `{"@value"/"@type"}` when redundant
   - With `@type: @id`: strip `{"@id": ...}` to bare string
   - With `@container: @language`: build language map
   - With `@container: @index`: build index map
   - Array compaction (configurable)
3. Implement **Compaction Algorithm** (§ 4.2):
   - First expand input (if not already expanded) using Phase 2
   - Walk expanded JSON-LD, compact each node recursively
   - Handle `@graph`, `@reverse`, `@nest`, `@included`
   - Add provided `@context` to output
4. Wire into `JsonLdEncoder`:
   - `compact` mode with provided context: use compaction algorithm
   - `compact` mode without context: auto-generate context from namespace
     mappings (current behaviour), then use compaction algorithm
5. Write compact W3C test runner
6. Handle negative tests

**Dependencies**: Phase 0 (context processing) and Phase 2 (expansion is needed
as the first step of compaction).

**Estimated scope**: ~800-1200 lines of new code

### Phase 4: Integration & Cleanup

1. Refactor `JsonLdEncoder` to delegate to new modules
2. Ensure backward compatibility for existing users of `jsonld.encode()` and
   `jsonldGraph.encode()` — default mode should produce output equivalent to
   current compact output (with auto-generated context)
3. Deprecate or migrate old `IriCompaction`-based prefix logic for the compact
   path (still useful for TriG/Turtle/NQuads encoders)
4. Update documentation
5. Update `locorda_rdf_benchmark`:
   - Rename existing `'JSON-LD'` entries to `'JSON-LD (compact)'`
   - Add `'JSON-LD (expanded)'` entries alongside them
   - No user-context entry — benchmark datasets have no naturally associated
     context, and an invented context would not reflect real-world usage

---

## 7. Test Strategy

### 7.1 fromRdf Tests (Phase 1)

```
Pipeline: read NQuads file → NQuadsDecoder → RdfDataset → JsonLdExpandedSerializer → JSON string
Compare:  JSON structure equality with expected -out.jsonld file
```

JSON comparison must be **order-insensitive** for:
- Array of node objects (top level) — sort by `@id`
- Properties within a node — use unordered map comparison
- Array values for a property — **order-sensitive** (RDF does not guarantee
  order, but the spec recommends preserving insertion order)

**Blank node handling**: Blank node identifiers may differ between expected and
actual. Need isomorphism-aware JSON comparison (rename blank nodes consistently).

### 7.2 Expand Tests (Phase 2)

```
Pipeline: read JSON-LD file → JsonLdExpansionProcessor → expanded JSON
Compare:  JSON deep equality with expected -out.jsonld file
```

This is a pure JSON-LD-to-JSON-LD transformation — no RDF involved.

### 7.3 Compact Tests (Phase 3)

```
Pipeline: read JSON-LD file → (expand first if has @context) → JsonLdCompactionProcessor(context) → compact JSON
Compare:  JSON deep equality with expected -out.jsonld file
```

### 7.4 Test Runner Structure

Create separate test files for each manifest:
- `jsonld_w3c_fromrdf_test.dart` — fromRdf-manifest.jsonld
- `jsonld_w3c_expand_test.dart` — expand-manifest.jsonld
- `jsonld_w3c_compact_test.dart` — compact-manifest.jsonld

Reuse manifest parsing logic from existing `jsonld_w3c_test.dart` (refactor into
shared utility).

---

## 8. Shared Infrastructure

### 8.1 `JsonLdContextProcessor` (Phase 0)

See § 6, Phase 0 for the extraction plan. This is the foundation that all subsequent
phases build on.

### 8.2 `JsonLdContext` & `TermDefinition` (Phase 0)

Already exist as `_JsonLdContext` and `_TermDefinition` in the decoder. Public
versions become the lingua franca between decoder, expansion processor, and
compaction processor.

### 8.3 JSON-LD Comparison Utilities (Phase 1)

For test assertions, we need:
- `jsonLdEquals(actual, expected)` — deep comparison with blank node isomorphism
- Property-order-insensitive comparison
- Array-order handling per spec rules

---

## 9. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Expansion algorithm complexity (scoped contexts, propagation, protection) | High | High | Implement incrementally; core features first, 1.1 features later |
| Context extraction breaks decoder | Low | High | Purely structural refactoring with full test coverage; extract → test → refactor decoder |
| Blank node isomorphism in test comparison | Medium | Low | Implement canonical blank node renaming for JSON comparison |
| Performance of expand→compact two-step pipeline | Low | Low | Negligible overhead (see § 5); spec-mandated architecture |

---

## 10. Open Questions

1. **Phase 2 scope**: The expansion algorithm is the largest piece. Should it be
   split into sub-phases (core expansion → 1.1 features → error handling)?

2. **`@json` type literals**: The decoder already handles these via
   `rdf:JSON` datatype. The expanded serializer needs to convert
   `rdf:JSON`-typed literals back to `{"@value": <parsed-json>, "@type": "@json"}`.
   Is this in scope for Phase 1?

3. **`rdfDirection` options**: Both `i18n-datatype` and `compound-literal` modes
   need to be supported in the expanded serializer. The decoder already handles
   both. Priority?

---

## 11. Recommended Execution Order

```
Phase 0 (context extraction)  →  Phase 1 (expanded/fromRdf)  →  Phase 2 (expansion)  →  Phase 3 (compaction)  →  Phase 4 (integration)
     ↓                               ↓                              ↓                        ↓
  shared foundation               ~50 tests                    ~385 tests                ~246 tests
  enables all phases              RDF→JSON-LD                  JSON-LD processor         final encoder
```

Phase 0 is the enabling refactoring — it produces no new features but creates the
shared foundation. Phase 1 delivers the first visible result (expanded encoder).
Phase 2 is the largest piece (expansion algorithm) but builds on shared context
processing. Phase 3 delivers the compact mode.

The auto-generated-context compact mode (no user context, current default
behaviour) should work without Phase 2/3 by keeping the existing `IriCompaction`
path as a fallback — this ensures backward compatibility throughout.

---

## Appendix A: JSON-LD Features That Cannot Survive RDF Round-Trip

This appendix explains each JSON-LD feature that exists in the expanded/compact
test outputs but **has no equivalent in the RDF data model**. For each feature
we explain: what it is, a concrete example, why RDF cannot represent it, how
our decoder currently handles it, and the consequence for our test pipeline.

### A.1 `@index` — Arbitrary Indexing Metadata

**What it is**: `@index` attaches an arbitrary string label to a JSON-LD node or
value. It serves as an organizational hint — like a "tag" or "bucket label" for
grouping entries in a map. It carries **no semantic meaning** in RDF.

**Example** (input JSON-LD):
```json
{
  "@context": {"items": {"@id": "http://ex.com/items", "@container": "@index"}},
  "items": {
    "photo": {"@id": "http://ex.com/photo1"},
    "video": {"@id": "http://ex.com/video1"}
  }
}
```

**Expanded output** (what the expand tests expect):
```json
[{"http://ex.com/items": [
  {"@id": "http://ex.com/photo1", "@index": "photo"},
  {"@id": "http://ex.com/video1", "@index": "video"}
]}]
```

**RDF output** (Turtle — what our decoder actually produces):
```turtle
# The document has no explicit subject IRI, so it becomes a blank node.
_:b0 <http://ex.com/items> <http://ex.com/photo1> .
_:b0 <http://ex.com/items> <http://ex.com/video1> .
# The index labels "photo" and "video" are gone — no trace of them in RDF.
```

**Why RDF cannot represent it**: RDF triples are `(subject, predicate, object)` —
there is no slot for attaching an arbitrary string label to a relationship or
value. The triple `<subject> <http://ex.com/items> <http://ex.com/photo1>` has no
place to store `"photo"`. The `@index` value is **pure JSON-LD presentation
metadata** with no RDF semantics.

**How our decoder handles it**: The decoder **silently drops** `@index` values.
The RDF output above is what is produced — the index labels `"photo"` and
`"video"` are lost.

Exception: When `@index` is combined with a **property-valued index**
(`"@index": "http://schema.org/name"` in the term definition), the decoder injects
the index key as a string literal value of that property. But the standard
`@index` (no property mapping) is simply discarded.

**Consequence for tests**: ~20 expand tests produce output containing `@index`.
If run through RDF decode→encode, the `@index` values would be missing. These
tests **must** use the expansion processor (JSON-LD → JSON-LD) to pass.

---

### A.2 `@reverse` — Structural Reverse Relationships

**What it is**: `@reverse` in expanded JSON-LD preserves the **direction** of a
relationship from the perspective of the current node. It says "this node is the
*object* of a triple, not the subject." In expanded output, `@reverse` appears
as a nested structure that groups incoming relationships.

**Example** (expanded JSON-LD):
```json
[{
  "@id": "http://ex.com/Alice",
  "@reverse": {
    "http://ex.com/knows": [{"@id": "http://ex.com/Bob"}]
  }
}]
```

This means: Bob knows Alice (Bob is the subject, Alice is the object). The
`@reverse` structure preserves that Alice is "the known one" here.

**RDF output** (Turtle — what our decoder produces):
```turtle
# One perfectly normal triple. Subject and object are swapped by the decoder.
<http://ex.com/Bob> <http://ex.com/knows> <http://ex.com/Alice> .
# The fact that this was expressed as a @reverse on Alice's node is lost.
# Re-encoding from RDF would produce the triple under Bob, not Alice.
```

**Why RDF cannot preserve the nesting**: In RDF, `<Bob> <knows> <Alice>` is
indistinguishable from a forward relationship. There is no way to mark that a
triple was originally expressed as a reverse relationship of Alice. When we
re-encode from RDF, Bob's node would naturally list `<knows> <Alice>` as a
forward property — the `@reverse` nesting structure under Alice is gone.

**How our decoder handles it**: The decoder correctly **swaps subject and object**
and emits a normal triple. `@reverse: {knows: [Bob]}` on Alice becomes the
triple `<Bob> <knows> <Alice>`. The structural nesting information ("this was
expressed as reverse on Alice's node") is discarded — it's not part of the RDF.

**Consequence for tests**: ~15 expand tests produce output with `@reverse`
nesting. These cannot pass through RDF round-trip because the nesting structure
is presentational, not semantic.

---

### A.3 `@included` — Co-Delivered Node Objects

**What it is**: `@included` allows a JSON-LD document to "include" additional
node objects alongside the main content, without asserting any relationship
between the including node and the included nodes. Think of it like an "also
relevant" sidebar.

**Example** (expanded JSON-LD):
```json
[{
  "@id": "http://ex.com/Article1",
  "http://ex.com/title": [{"@value": "My Article"}],
  "@included": [{
    "@id": "http://ex.com/Author1",
    "http://ex.com/name": [{"@value": "Alice"}]
  }]
}]
```

The Author1 node is included — delivered alongside Article1 — but there is no
triple linking Article1 to Author1 via `@included`.

**RDF output** (Turtle — what our decoder produces):
```turtle
# Both nodes appear as flat, unrelated triples in the same graph.
# There is no triple encoding the @included grouping — it is simply dropped.
<http://ex.com/Article1> <http://ex.com/title> "My Article" .
<http://ex.com/Author1>  <http://ex.com/name>  "Alice" .
```

**Why RDF cannot represent the grouping**: Both nodes are fully representable as
RDF triples, but RDF has no mechanism to express "Author1 was delivered as part
of Article1's payload." The grouping is a **JSON-LD delivery/packaging concern**,
not a semantic one — and that concern has no RDF equivalent.

**How our decoder handles it**: The decoder **extracts the included nodes and
processes them as separate RDF triples**. The `@included` grouping is discarded.
Author1's triples end up in the same graph as Article1's, just as independent
statements.

**Consequence for tests**: ~5 expand tests produce output with `@included`. The
grouping is lost in RDF.

---

### A.4 `@direction` — Base Text Direction

**What it is**: `@direction` specifies whether text should be rendered
left-to-right (`"ltr"`) or right-to-left (`"rtl"`). This is essential for
correctly displaying mixed-script text (e.g., Arabic or Hebrew alongside Latin).

**Example** (expanded JSON-LD):
```json
[{
  "http://ex.com/label": [{
    "@value": "مرحبا",
    "@language": "ar",
    "@direction": "rtl"
  }]
}]
```

**Why standard RDF cannot represent it**: RDF language-tagged literals are
`"مرحبا"@ar` — the BCP47 language tag has no standard slot for text direction.
An `xsd:string` literal is just a string. There is no triple component for
"this string is right-to-left."

**How our decoder handles it**: Depends on the `rdfDirection` option:

- **Default (no option)**: `@direction` is **silently dropped**.
  ```turtle
  _:b0 <http://ex.com/label> "مرحبا"@ar .
  # Direction "rtl" is gone — no way to recover it from this triple.
  ```

- **`rdfDirection: 'i18n-datatype'`**: Direction is encoded in a special
  datatype IRI, combining language tag and direction into a single token:
  ```turtle
  _:b0 <http://ex.com/label> "مرحبا"^^<https://www.w3.org/ns/i18n#ar_rtl> .
  # Non-standard datatype, but direction is recoverable.
  ```

- **`rdfDirection: 'compound-literal'`**: A blank node is created with three
  separate triples — value, language, and direction as individual properties:
  ```turtle
  @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
  _:b0  <http://ex.com/label>  _:dir .
  _:dir rdf:value              "مرحبا" .
  _:dir rdf:language           "ar" .
  _:dir rdf:direction          "rtl" .
  # All information preserved, but one literal became four triples.
  ```

The i18n-datatype and compound-literal approaches are **RDF-compatible
workarounds** (not standard RDF), and the expanded serializer can reverse them.
But the default (no option) loses the direction entirely.

**Consequence for tests**: ~20 expand tests produce output with `@direction`.
With appropriate `rdfDirection` options, some can round-trip. Without, direction
is lost.

---

### A.5 `@json` — JSON Literals

**What it is**: `@json` type allows embedding arbitrary JSON values (arrays,
objects, numbers, booleans, null) as literal values in JSON-LD. The JSON value
is preserved exactly as-is.

**Example** (expanded JSON-LD):
```json
[{
  "http://ex.com/data": [{
    "@value": {"key": [1, 2, 3], "nested": true},
    "@type": "@json"
  }]
}]
```

**RDF output** (Turtle — what our decoder produces):
```turtle
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
# The entire JSON value is canonicalized and stored as a single typed literal.
_:b0 <http://ex.com/data> "{\"key\":[1,2,3],\"nested\":true}"^^rdf:JSON .
# The expanded serializer can parse this string back to recover the original JSON.
```

**RDF representation**: This one **does have an RDF equivalent**:
`"..."^^rdf:JSON`. The JSON value is serialized as a canonical string and stored
as a typed literal with datatype `rdf:JSON`.

**How our decoder handles it**: The decoder serializes the JSON value to a
canonical string and creates a `LiteralTerm` with datatype
`http://www.w3.org/1999/02/22-rdf-syntax-ns#JSON`. This **does survive RDF
round-trip** — the expanded serializer can parse the string back to JSON and
produce `{"@value": <parsed>, "@type": "@json"}`.

**Consequence for tests**: `@json` tests **can** pass through RDF round-trip.
This is the exception — it's listed here for completeness but is NOT a blocker.

---

### A.6 Summary: Feature Support Matrix

| Feature | Survives RDF? | Decoder behavior | Expand tests affected | Must skip in RDF pipeline? |
|---------|--------------|------------------|-----------------------|---------------------------|
| `@index` | No | Silently dropped (or mapped to property if property-valued) | ~20 | Yes |
| `@reverse` | Triple survives, nesting doesn't | Swaps subject/object, emits normal triple | ~15 | Yes |
| `@included` | Triples survive, grouping doesn't | Extracts as separate independent triples | ~5 | Yes |
| `@direction` | Depends on rdfDirection option | Default: dropped. i18n-datatype/compound-literal: preserved. | ~20 | Partially (depends on option) |
| `@json` | **Yes** | Canonical JSON string with `rdf:JSON` datatype | ~5 | **No** |

### A.7 Why Implement the Expansion Algorithm Instead of Skipping These Tests?

A natural question: if ~57 tests can't pass through RDF, why not skip them and
only support the RDF-based pipeline?

**Answer: Because the expansion and compaction algorithms are essential for the
compact encoder, not just for tests.**

The compact encoder's pipeline is:
`RdfDataset → expanded JSON-LD → compact JSON-LD`

The **compaction algorithm** (step 2) is defined by the W3C spec as operating on
expanded JSON-LD. To implement it correctly, we need the shared foundation of
context processing and IRI expansion/compaction — the same machinery that the
expansion algorithm uses.

Even if we didn't care about the expand tests at all, we would still need:
- `JsonLdContextProcessor` — for interpreting user-provided contexts
- The term selection / IRI compaction logic — for compact output
- The value compaction logic — for compact output

Building the expansion processor is not wasted work for test compliance — it's
the **natural first consumer** of the shared context machinery, and it provides
the documented, spec-compliant foundation that compaction builds on.

The ~57 non-RDF expand tests are a **free bonus** that validates our context
processing is correct. Skipping them would mean less test coverage for the
shared code, not less code to write.
