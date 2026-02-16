# Custom Vocabulary Generation

## Motivation

For certain use cases, requiring upfront vocabulary definition (TTL files + `locorda_rdf_terms_generator`) creates friction:
- **RDF beginners** want to start mapping without learning vocabulary design first
- **Prototype builders** need "quick and dirty" iteration without maintaining separate vocab files
- **Library-driven users** (e.g. forced into RDF by locorda/sync-engine) want minimal RDF involvement

The manual vocabulary approach remains the **recommended path for production** (full control, documentation, semantic precision), but a generated-vocab option lowers the barrier for these scenarios.

## Design Goals

- **No sacrifice** of current capabilities
- **Breaking changes** are acceptable but must be well-justified
- **Simplicity first** — lower the RDF barrier as much as sensibly possible
- The vocab generator **lives in the mapper generator**, producing proper vocabulary definitions that users can deploy to their servers
- Support a **one-vocab-per-app** default pattern, with opt-in for more structure
- Optional **app base URI** config that other annotations (e.g. sync-engine) can reuse for generated CRDT mapping files etc.

## Core Concept

This feature provides **two fully supported approaches** for working with vocabularies:

1. **Manual vocabulary definition (recommended for production):** Write your vocabulary as Turtle/RDF and use `locorda_rdf_terms_generator` to generate Dart constants. This gives you full control over your vocabulary's structure, documentation, and semantic relationships.

2. **Generated vocabulary (convenience option):** Use the `.genVocab()` annotation API to auto-generate vocabulary definitions from your Dart classes. The mapper generator produces both the mapping code AND a deployable OWL ontology. This is ideal for prototypes, beginners, or cases where vocabulary design is tightly coupled with your data model.

**Both approaches are first-class citizens.** You can freely mix them (manual vocabs for stable/shared concepts, generated vocabs for app-specific types) or choose one consistently.

### Manual Vocabulary API (unchanged)

Use direct `IriTerm(...)` references for vocabulary terms. Works for:
- **External vocabularies** (Schema.org, FOAF, etc.) — use `locorda_rdf_terms_generator` to generate Dart constants from published vocab files
- **Custom vocabularies** — write your own Turtle/RDF vocab file, then use `locorda_rdf_terms_generator` to generate Dart constants
- **Inline definitions** — use `IriTerm('...')` directly without generated constants (quick but less maintainable)

```dart
@RdfGlobalResource(SchemaBook.classIri, IriStrategy('http://example.org/book/{id}'))
class Book {
  @RdfProperty(SchemaBook.name)
  final String title;
  
  // Or inline for custom properties:
  @RdfProperty(IriTerm('https://my.app.de/vocab#customField'))
  final String customField;
}
```

### Generated Vocabulary API (new)

**Only use `.genVocab()` for the auto-generation workflow.** If you write your own vocabulary TTL files (even for app-specific terms), use the manual API above with `locorda_rdf_terms_generator` or direct `IriTerm(...)` references.

The `.genVocab()` constructors tell the mapper generator to derive IRIs from Dart names and produce a deployable OWL ontology:

```dart
// Define once per app (e.g. in a config file)
// Vocab IRI is derived: appBaseUri + vocabPath → https://my.app.de/vocab#
const myVocab = AppVocab(appBaseUri: 'https://my.app.de');

@RdfGlobalResource.genVocab(myVocab, IriStrategy('http://example.org/book/{id}'))
class Book {
  final String title; // no annotation needed — fragment derived from field name: ...#title

  @RdfProperty.genVocab(fragment: 'bookTitle') // override fragment
  final String displayTitle;
}
```

This would generate a proper OWL ontology as Turtle, deployable to the vocab URI:

```turtle
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

<https://my.app.de/vocab#> a owl:Ontology .

<https://my.app.de/vocab#Book> a owl:Class .
<https://my.app.de/vocab#title> a rdf:Property ;
    rdfs:domain <https://my.app.de/vocab#Book> .
<https://my.app.de/vocab#bookTitle> a rdf:Property ;
    rdfs:domain <https://my.app.de/vocab#Book> .
```

## Key Design Decisions

### 1. Vocab Configuration Object (`AppVocab`)


All vocab-tuning on class annotations should be controlled by a dedicated config class rather than adding parameters to the resource annotations directly. 

**Subclassing is explicitly supported:**
Just as `locorda/sync-engine` subclasses `RdfGlobalResource` (e.g. as `LcrdRootResource`), you can subclass `AppVocab` (e.g. as `CustomContracts`) to control both vocabulary and CRDT mapping generation in one place. This enables advanced use cases where vocab and mapping logic are tightly coupled, and allows downstream libraries to provide their own vocab/mapping conventions by subclassing.

```dart
class AppVocab {
  /// The application's base URI (e.g. 'https://my.app.de').
  /// NOT the vocabulary IRI itself — that is derived as: appBaseUri + vocabPath + '#'
  /// e.g. 'https://my.app.de' + '/vocab' → vocabulary IRI 'https://my.app.de/vocab#'
  final String appBaseUri;

  /// Relative path appended to appBaseUri to form the vocabulary namespace.
  final String vocabPath; // defaults to '/vocab'

  const AppVocab({required this.appBaseUri, this.vocabPath = '/vocab'});

  // Subclassing example:
  // class CustomContracts extends AppVocab {
  //   const CustomContracts() : super(appBaseUri: 'https://contracts.app', vocabPath: '/contracts');
  //   // Add CRDT mapping config, etc.
  // }
}
```

The `appBaseUri` is intentionally reusable: locorda/sync-engine annotations can reference the same `AppVocab` instance to derive paths for CRDT mapping files and other generated resources. The vocabulary IRI is always derived (`appBaseUri + vocabPath + '#'`), never specified directly.

### 2. Grouping

- **Default:** One `AppVocab` per app → all classes go into one vocabulary namespace.
- **Structured:** Multiple `AppVocab` instances with different `vocabPath` values → multiple vocabulary namespaces.
- The generated vocab class name derives from the annotated Dart class name.

### 3. `RdfProperty` Constructor Constraint

`RdfProperty` has `predicate` as a **required positional parameter** (`IriTerm`), followed by optional named parameters. Making `predicate` optional would be a breaking change since Dart does not allow a positional parameter to be optional when it precedes named parameters without making it a positional optional (wrapped in `[]`), which changes call-site syntax.

**Solution: Named constructor.**

```dart
class RdfProperty {
  // Existing — unchanged
  const RdfProperty(this.predicate, { ... });

  // New — for generated vocab mode
  const RdfProperty.genVocab({
    this.fragment, // override the auto-derived fragment identifier
    // ... other named params as in default constructor
  });
}
```

This is acceptable because `.genVocab()` is intended as the **default annotation for unannotated fields** when the class annotation activates generated vocab mode. The generator would treat a bare field (no `@RdfProperty` at all) in a generated-vocab class as implicitly `@RdfProperty.genVocab()`.

### 4. SubclassOf on Class Annotations

`subClassOf` is a per-class concern (different classes in the same vocab typically have different superclasses), so it belongs on the `.genVocab()` constructor of the resource annotation, not on `AppVocab`.

```dart
@RdfGlobalResource.genVocab(
  myVocab,
  IriStrategy('http://example.org/person/{id}'),
  subClassOf: SchemaPerson.classIri,
)
class Person { ... }
```

### 5. `RdfLocalResource` Generated Vocab

Same pattern applies:

```dart
@RdfLocalResource.genVocab(myVocab)
class Chapter {
  @RdfProperty.genVocab()
  final String title;
}
```

## Resolved Decisions

### Fragment Derivation

- **Properties:** Auto-derived fragment = Dart field name, enforced as `camelCase`. E.g. `final String title` → `#title`.
- **Types:** Auto-derived fragment = Dart class name, enforced as `UpperCamelCase`. E.g. `class Book` → `#Book`.
- **Explicit `fragment` parameter:** Used as-is, no casing enforcement. The user takes full responsibility.
- **Enforcement:** Build error (not auto-conversion). If an auto-derived name violates the convention (e.g. a field named `MyField` or a class named `book`), the generator emits a build error. This is clearer than silent transformation and follows fail-fast principles.

### Mixing Vocabulary Sources

Fully supported and encouraged. You can combine:
- **External vocabularies** (e.g. `SchemaBook.name` from `locorda_rdf_terms_generator`)
- **Your own manual vocabularies** (e.g. `MyVocab.customProp` from your TTL + `locorda_rdf_terms_generator`)
- **Direct `IriTerm(...)` references** for ad-hoc terms
- **Generated vocab properties** (via `.genVocab()` + implicit fields)

This is especially useful when subclassing external types:

```dart
@RdfGlobalResource.genVocab(
  myVocab,
  IriStrategy('http://example.org/book/{id}'),
  subClassOf: SchemaBook.classIri,
)
class Book {
  @RdfProperty(SchemaBook.name) // external vocab — Schema.org
  final String title;

  @RdfProperty(IriTerm('https://my.app.de/manual#isbn')) // manual vocab — direct IriTerm
  final String isbn;

  final String internalNote; // generated vocab — auto-generated as myVocab#internalNote
}
```

The generator only creates vocab entries for fields without an explicit `@RdfProperty(iriTerm)` annotation.

### Naming

The config class is named **`AppVocab`**. It's the shortest, most intuitive option and aligns with the `appBaseUri` parameter. The "app" framing matches the target audience (software developers building apps who are RDF beginners). Documentation clarifies that it works equally well for libraries via subclassing (e.g. `CustomContracts extends AppVocab`).

The constructor name is **`.genVocab()`** — short, establishes the "gen" pattern (familiar from codegen), and semantically flexible ("generates vocab" on classes, "generated vocab" on properties).

### Implicit `@RdfProperty.genVocab()` and Field Exclusion

In generated-vocab mode, unannotated fields are implicitly treated as `@RdfProperty.genVocab()`. The user already opted in explicitly via `.genVocab()` on the class, so implicit property generation is expected and desired.

**Rules:**

- **Unannotated fields** → implicitly `@RdfProperty.genVocab()`, vocab entry auto-generated
- **`@RdfIriPart` fields** → excluded from implicit property generation (IRI parts are identifiers, not properties). If a field should be both an IRI part *and* a serialized property, an explicit `@RdfProperty` or `@RdfProperty.genVocab()` is required — consistent with existing API behavior.
- **Excluding a field** → `@RdfProperty.genVocab(include: false)`. No new `@RdfIgnore()` annotation — stays consistent with the existing `include` parameter pattern and avoids introducing a new concept.
- **Explicitly annotated `@RdfProperty(iriTerm)` fields** → use the provided IRI term as-is, no vocab entry generated.

### Vocab File Output

The generator produces Turtle `owl:Ontology` definitions deployable to the vocabulary URIs. Since [dart-lang/build#3171](https://github.com/dart-lang/build/pull/3171) (Aug 2021), `build_runner` officially supports **dynamic `buildExtensions` computed from `BuilderOptions`** at runtime. This enables flexible output file configuration via `build.yaml`.

**Implementation approach:**

An `AggregatingBuilder` (similar to the existing init file builder) collects all `@*.genVocab()` annotated classes, groups them by vocabulary IRI (`appBaseUri + vocabPath`), and outputs one `.ttl` file per vocabulary.

**Output file paths** are determined by a vocab-IRI-to-filename map in `build.yaml` options:

```yaml
targets:
  $default:
    builders:
      locorda_rdf_mapper_generator|vocab_builder:
        options:
          output_files:
            "https://my.app.de/vocab#": "lib/vocab.g.ttl"
            "https://my.app.de/contracts#": "lib/contracts.g.ttl"
```

**Default behavior** (no `output_files` map configured):
- All vocabularies merge into a single file: `lib/vocab.g.ttl`
- This covers the common case: one `AppVocab` per app

**Multi-vocabulary projects:**
- Configure explicit `output_files` map
- Each unique vocab IRI gets its own output file
- Build error if a vocab IRI appears in code but not in the map (fail-fast)

**File naming conventions:**
- **`.g.ttl` extension:** Signals "generated file, do not edit" — follows `build_runner` convention for generated artifacts (e.g. `.g.dart`)
- **`lib/` directory:** Correct location for public, deployable artifacts (not `lib/src/`, which implies private implementation details). Consistent with `lib/init_rdf_mapper.g.dart`.

**Builder mechanics:**
1. Builder constructor: Parse `output_files` map from `BuilderOptions` → compute `buildExtensions` (or default to `{'$lib$': ['vocab.g.ttl']}`)
2. `build()` method: Parse all Dart inputs, extract vocab IRIs from `AppVocab` instances
3. Match vocab IRIs to output filenames via the map
4. Aggregate vocabulary definitions and write to the mapped output files

**Why this works:**
- `buildExtensions` is computed from static `build.yaml` config (not from Dart code content)
- AggregatingBuilder handles n:1 (many annotated classes → one vocab file per namespace)
- Dynamic `buildExtensions` from options is an officially supported feature since 2021
