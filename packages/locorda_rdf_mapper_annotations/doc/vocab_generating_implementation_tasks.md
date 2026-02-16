# Custom Vocabulary Generation — Implementation Tasks

Reference: [vocab_generating.md](./vocab_generating.md)

---

## Architecture Overview

### Existing Build Pipeline

```
Phase 1: cache_builder (.dart → .rdf_mapper.cache.json)
  ├── AnalyzerWrapperService parses Dart files
  ├── ResourceProcessor / PropertyProcessor extract annotation info via DartObject API
  ├── BuilderHelper orchestrates: Processors → MapperModel → ResolvedMapperModel → TemplateData
  └── FileTemplateData.toMap() → JSON

Phase 2: source_builder (.rdf_mapper.cache.json → .rdf_mapper.g.dart)
  └── Reads JSON, renders Mustache templates → Dart mapper code

Phase 3: init_file_builder (pubspec.yaml → lib/init_rdf_mapper.g.dart)
  └── Globs all .rdf_mapper.cache.json, aggregates mapper registrations
```

### New Components

```
New Phase (after cache_builder, before init_file_builder):
  vocab_builder (pubspec.yaml → lib/vocab.g.ttl or configured paths)
    └── Globs .rdf_mapper.cache.json, extracts vocab metadata, generates Turtle

New Annotation Classes:
  AppVocab                            → locorda_rdf_mapper_annotations/lib/src/vocab/
  RdfGlobalResource.genVocab()        → extends existing class
  RdfLocalResource.genVocab()         → extends existing class
  RdfProperty.genVocab()              → extends existing class

Extended Pipeline:
  ResourceProcessor                   → extract AppVocab fields from DartObject
  PropertyProcessor                   → extract fragment from DartObject
  ResourceMapperTemplateData.toMap()  → serialize vocab metadata to cache JSON
```

### Key Files to Modify

| File | Change |
|------|--------|
| `annotations/lib/src/resource/global_resource.dart` | Add `.genVocab()` constructor, `vocab` and `subClassOf` fields |
| `annotations/lib/src/resource/local_resource.dart` | Add `.genVocab()` constructor, `vocab` and `subClassOf` fields |
| `annotations/lib/src/property/property.dart` | Add `.genVocab()` constructor, `fragment` field |
| `annotations/lib/annotations.dart` | Export new `app_vocab.dart` |
| `generator/lib/src/processors/resource_processor.dart` | Read `vocab`, `subClassOf` fields from `DartObject` |
| `generator/lib/src/processors/property_processor.dart` | Read `fragment` field from `DartObject` |
| `generator/lib/src/templates/template_data.dart` | Add vocab fields to `ResourceMapperTemplateData`, update `toMap()` |
| `generator/build.yaml` | Add `vocab_builder` definition |
| `generator/lib/builder.dart` | Export vocab builder factory |

### Key Files to Create

| File | Purpose |
|------|---------|
| `annotations/lib/src/vocab/app_vocab.dart` | `AppVocab` config class |
| `generator/lib/vocab_builder.dart` | Builder factory + `VocabBuilder` class |
| `generator/lib/src/vocab/turtle_generator.dart` | Turtle output generation |
| `generator/lib/src/vocab/fragment_validator.dart` | Casing validation for auto-derived fragments |

---

## Task 1: AppVocab Configuration Class

**Package:** `locorda_rdf_mapper_annotations`  
**File:** `lib/src/vocab/app_vocab.dart`

Create `AppVocab` class with:
- `final String appBaseUri` (required)
- `final String vocabPath` (default `'/vocab'`)
- `const` constructor
- Must be subclassable (not final/sealed) — sync-engine will subclass it as `CustomContracts`
- No getters, no computed properties — the generator reads fields via `DartObject` API

Export from `lib/annotations.dart`.

**Tests:** `test/src/vocab/app_vocab_test.dart`
- Constructing with defaults
- Constructing with custom vocabPath
- Subclassability (create a subclass in test, verify it compiles)

---

## Task 2: RdfGlobalResource.genVocab() Constructor

**File:** `annotations/lib/src/resource/global_resource.dart`

Add a new named constructor to the existing `RdfGlobalResource` class. Study the existing constructors (default, `.deserializeOnly`, `.serializeOnly`, `.namedMapper`, `.mapper`, `.mapperInstance`) to understand the initialization pattern — particularly how `classIri`, `iri`, and the `super()` call work.

Constructor signature:
```dart
const RdfGlobalResource.genVocab(
  AppVocab vocab,
  IriStrategy iriStrategy, {
  IriTerm? subClassOf,
  bool registerGlobally = true,
});
```

Requirements:
- New fields needed on the class: `vocab` (`AppVocab?`), `subClassOf` (`IriTerm?`)
- Existing constructors must initialize these new fields to `null`
- `classIri` is `null` in genVocab mode (derived by generator at build time)
- `iri` is set from the `iriStrategy` parameter (same as default constructor)

**Tests:** `test/src/resource/global_resource_test.dart`
- Add tests for the new constructor alongside existing tests
- Verify field values after construction

---

## Task 3: RdfLocalResource.genVocab() Constructor

**File:** `annotations/lib/src/resource/local_resource.dart`

Same pattern as Task 2, but without `IriStrategy` (local resources don't have IRI strategies).

Constructor signature:
```dart
const RdfLocalResource.genVocab(
  AppVocab vocab, {
  IriTerm? subClassOf,
});
```

Requirements:
- New fields: `vocab` (`AppVocab?`), `subClassOf` (`IriTerm?`)
- Existing constructors must initialize these to `null`
- `classIri` is `null` in genVocab mode

**Tests:** `test/src/resource/local_resource_test.dart`

---

## Task 4: RdfProperty.genVocab() Constructor

**File:** `annotations/lib/src/property/property.dart`

Study the existing `RdfProperty` constructor carefully — it has a required positional `predicate` parameter (`IriTerm`) followed by many named parameters (`include`, `defaultValue`, `includeDefaultsInSerialization`, `iri`, `localResource`, `literal`, `globalResource`, `collection`, `itemType`, `contextual`).

Constructor signature:
```dart
const RdfProperty.genVocab({
  String? fragment,
  // ... same named params as default constructor (include, defaultValue, etc.)
});
```

Requirements:
- New field: `fragment` (`String?`)
- `predicate` must accommodate being `null` in genVocab mode. Since `predicate` is currently a non-nullable `IriTerm`, this is a structural change. Options:
  - Make `predicate` nullable (`IriTerm?`) — may require updating all code referencing `predicate`
  - Use a sentinel value — fragile
  - **Investigate the actual field usage** in `RdfProperty` and in the generator's `PropertyProcessor` to determine the best approach
- All other named parameters should be available in both constructors

**Tests:** `test/src/property/property_test.dart`
- Construction with and without fragment
- All named params accessible

---

## Task 5: ResourceProcessor — Extract Vocab Metadata

**File:** `generator/lib/src/processors/resource_processor.dart`

This is the critical integration point. Study how `ResourceProcessor` currently:
1. Gets the annotation `DartObject` from the element
2. Reads `classIri` via `getIriTermInfo(getField(annotation, 'classIri'))`
3. Reads `iriStrategy` via the `IriStrategyProcessor`
4. Builds `RdfGlobalResourceInfo` / `RdfLocalResourceInfo`

Extend to also read:
- `vocab` field → extract `appBaseUri` and `vocabPath` string values from the nested `DartObject`
- `subClassOf` field → extract as `IriTermInfo` (same pattern as `classIri`)

The extracted data must flow through the existing pipeline:
```
ResourceProcessor → RdfGlobalResourceInfo → MapperModel → ResolvedMapperModel → ResourceMapperTemplateData → toMap() → JSON
```

Study each step of this pipeline to understand what model classes need new fields.

**Key consideration:** In genVocab mode, `classIri` is `null` in the annotation. The processor must handle this — either by:
- Deriving the classIri from the class name + vocab config at processing time
- Passing the vocab config through the pipeline and letting a later stage derive it

The choice depends on where `className` is available. Read the processor code to determine this.

**Tests:** Match existing test patterns in `test/src/processors/`

---

## Task 6: PropertyProcessor — Extract Fragment

**File:** `generator/lib/src/processors/property_processor.dart`

Study how `PropertyProcessor` currently reads the `predicate` field. Extend to:
- Detect genVocab mode (where `predicate` is null but `fragment` may be set)
- Read `fragment` string value from `DartObject`
- Handle implicit genVocab properties (fields with no `@RdfProperty` annotation in a genVocab class)

**Key consideration:** Implicit properties (unannotated fields) are currently ignored by the processor. In genVocab mode, they should be treated as `@RdfProperty.genVocab()`. This logic change likely lives in `ResourceProcessor` or `BuilderHelper` where the field list is iterated — investigate where unannotated fields are currently filtered out.

**Tests:** Match existing test patterns in `test/src/processors/`

---

## Task 7: Template Data — Serialize Vocab Metadata to Cache

**File:** `generator/lib/src/templates/template_data.dart`

Extend `ResourceMapperTemplateData` (the class that gets serialized to `.rdf_mapper.cache.json`):
- Add fields to store vocab metadata: `appBaseUri`, `vocabPath`, `subClassOfIri`
- Add per-property field: `fragment`
- Update `toMap()` to include these fields
- These fields are only needed by the vocab_builder; the source_builder can ignore them

Study how `PropertyData` stores the `predicate` and ensure the fragment info is also serialized.

**Tests:** Extend existing template_data tests

---

## Task 8: Fragment Casing Validation

**Package:** `locorda_rdf_mapper_generator`  
**File:** `lib/src/vocab/fragment_validator.dart`

Simple utility with two regex-based validation functions:
- `lowerCamelCase` check: `^[a-z][a-zA-Z0-9]*$` — for auto-derived property fragments (field names)
- `UpperCamelCase` check: `^[A-Z][a-zA-Z0-9]*$` — for auto-derived class fragments (class names)

Returns error message string or null. Error messages must tell the user how to fix the problem (use `fragment:` parameter to override).

Validation is called during cache building (Task 5/6), not in a separate phase.

Explicit `fragment:` values bypass validation (user's responsibility).

**Tests:** `test/src/vocab/fragment_validator_test.dart`
- Valid and invalid cases for both checks
- Error message includes the field/class name

---

## Task 9: Vocabulary Builder

**Package:** `locorda_rdf_mapper_generator`  
**File:** `lib/vocab_builder.dart`

Create a new `Builder` (not `AggregatingBuilder` — the existing init_file_builder also uses plain `Builder` with `findAssets`/`Glob`). Follow the same pattern as `RdfInitFileBuilder`:
- Triggered by `pubspec.yaml` as input
- Globs `**/*.rdf_mapper.cache.json`
- Reads JSON, filters for entries with vocab metadata
- Groups by vocab IRI
- Generates Turtle output

**buildExtensions:** Computed from `BuilderOptions` in the constructor.
- Default (no config): `{'pubspec.yaml': ['lib/vocab.g.ttl']}`
- With `output_files` map: `{'pubspec.yaml': [<all configured paths>]}`

**Output logic:**
- Default mode: merge all vocabs into `lib/vocab.g.ttl`
- Configured mode: one file per vocab IRI, build error if a vocab IRI has no configured output path

**Factory function** in `lib/vocab_builder.dart`:
```dart
Builder rdfVocabBuilder(BuilderOptions options) => VocabBuilder(options);
```

Export from `lib/builder.dart`.

**Tests:** `test/src/vocab/vocab_builder_test.dart`
- Follow the testability pattern of `RdfInitFileBuilder` / `RdfMapperCacheBuilder` — both expose their logic for unit testing

---

## Task 10: Turtle Generator

**Package:** `locorda_rdf_mapper_generator`  
**File:** `lib/src/vocab/turtle_generator.dart`

Pure function that takes vocabulary data (vocab IRI, list of classes with properties) and returns a Turtle string. No build_runner dependencies.

Output format per the concept doc:
```turtle
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

<https://my.app.de/vocab#> a owl:Ontology .

<https://my.app.de/vocab#Book> a owl:Class .
<https://my.app.de/vocab#title> a rdf:Property ;
    rdfs:domain <https://my.app.de/vocab#Book> .
```

With `subClassOf`:
```turtle
<https://my.app.de/vocab#Book> a owl:Class ;
    rdfs:subClassOf <https://schema.org/Book> .
```

**Tests:** `test/src/vocab/turtle_generator_test.dart`
- Use golden file comparison (expected Turtle strings)
- Single class, multiple classes, with/without subClassOf, with/without properties
- Merged multi-vocab output

---

## Task 11: build.yaml Configuration

**File:** `generator/build.yaml`

Add `vocab_builder` entry. Follow the pattern of `init_file_builder` (also pubspec.yaml-triggered, build_to: source, auto_apply: root_package).

Key differences from init_file_builder:
- `build_extensions` default includes `.ttl` output (overridable at runtime via options)
- Must run after `cache_builder` (needs cache JSON files)
- No dependency on `source_builder` or `init_file_builder`

---

## Task 12: Integration Tests

Follow the existing integration test patterns in the generator package. Create test fixtures with annotated Dart classes and verify:

1. **Single vocab, default output** — one AppVocab, default config → `lib/vocab.g.ttl` with correct content
2. **Mixed vocab sources** — class with both `@RdfProperty(iriTerm)` and implicit genVocab fields → only genVocab fields appear in TTL
3. **Custom fragment** — `@RdfProperty.genVocab(fragment: 'x')` → fragment `x` in TTL instead of field name
4. **Field exclusion** — `@RdfProperty.genVocab(include: false)` → field absent from TTL
5. **SubClassOf** — `subClassOf: SomeClass.classIri` → `rdfs:subClassOf` triple in TTL
6. **Invalid casing** — lowercase class name or uppercase field name → build error with actionable message
7. **Existing tests still pass** — no regression in manual vocab workflow

---

## Implementation Order

```
1. Task 1   AppVocab class (no dependencies)
2. Task 2   RdfGlobalResource.genVocab()  (depends on AppVocab)
3. Task 3   RdfLocalResource.genVocab()   (depends on AppVocab)
4. Task 4   RdfProperty.genVocab()        (no dependencies)
5. Task 8   Fragment validator             (no dependencies)
6. Task 5   ResourceProcessor extension   (depends on Tasks 1-3)
7. Task 6   PropertyProcessor extension   (depends on Task 4)
8. Task 7   Template data extension        (depends on Tasks 5-6)
9. Task 10  Turtle generator               (no dependencies on pipeline)
10. Task 9  Vocab builder                  (depends on Tasks 7-10)
11. Task 11 build.yaml                     (depends on Task 9)
12. Task 12 Integration tests              (depends on all above)
```

Tasks 1-4 and Task 8 can be implemented in parallel.
Tasks 9 and 10 can be implemented in parallel.

---

## Error Scenarios

The generator must produce clear, actionable build errors for:

| Scenario | Error Message Pattern |
|----------|----------------------|
| Class name not UpperCamelCase | `Class 'foo' must be UpperCamelCase for vocab fragment derivation. Rename to 'Foo'.` |
| Field name not lowerCamelCase | `Field 'Title' must be lowerCamelCase for vocab fragment derivation. Use @RdfProperty.genVocab(fragment: 'Title') to override.` |
| Vocab IRI in code but not in `output_files` map | `Vocabulary 'https://x/vocab#' found in code but not configured in build.yaml output_files.` |
| Duplicate fragment in same vocab | `Duplicate fragment 'title' in vocabulary 'https://x/vocab#'. Used by Book.title and Article.title.` |

---

## Future Work (not part of this implementation)

- **rdfs:range from Dart types** — Dart type → XSD/OWL type mapping
- **rdfs:label/comment from DartDoc** — parse doc comments for vocabulary documentation
- **TriG output** — named graphs for multi-vocab-in-single-file scenarios
