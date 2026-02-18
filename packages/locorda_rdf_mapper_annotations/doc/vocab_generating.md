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

2. **Generated vocabulary (convenience option):** Use the `.define()` annotation API to auto-generate vocabulary definitions from your Dart classes. The mapper generator produces both the mapping code AND a deployable OWL ontology. This is ideal for prototypes, beginners, or cases where vocabulary design is tightly coupled with your data model.

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

**Only use `.define()` for the auto-generation workflow.** If you write your own vocabulary TTL files (even for app-specific terms), use the manual API above with `locorda_rdf_terms_generator` or direct `IriTerm(...)` references.

The `.define()` constructors tell the mapper generator to derive IRIs from Dart names and produce a deployable OWL ontology:

```dart
// Define once per app (e.g. in a config file)
// Vocab IRI is derived: appBaseUri + vocabPath → https://my.app.de/vocab#
const myVocab = AppVocab(appBaseUri: 'https://my.app.de');

@RdfGlobalResource.define(myVocab, IriStrategy('http://example.org/book/{id}'))
class Book {
  final String title; // Auto-matched to dc:title (from default curated list)
  final String isbn; // Custom property — generates vocab entry

  @RdfProperty.define(fragment: 'displayTitle') // override fragment
  final String bookTitle; // Custom property with explicit fragment
}
```

This would generate a proper OWL ontology as Turtle, deployable to the vocab URI:

```turtle
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix dc: <http://purl.org/dc/terms/> .

<https://my.app.de/vocab#> a owl:Ontology .

<https://my.app.de/vocab#Book> a owl:Class .

# Custom properties (title auto-matched to dc:title, not in vocab)
<https://my.app.de/vocab#isbn> a rdf:Property ;
    rdfs:domain <https://my.app.de/vocab#Book> .
<https://my.app.de/vocab#displayTitle> a rdf:Property ;
    rdfs:domain <https://my.app.de/vocab#Book> .
```

### Annotation Metadata

The `.define()` constructors support adding RDF metadata directly through annotation parameters. This is ideal for simple, compile-time metadata that should be visible in your Dart code.

**Three ways to add metadata:**

1. **`label` and `comment` parameters**: Convenience shortcuts for the most common metadata (`rdfs:label` and `rdfs:comment`)
2. **`metadata` parameter**: List of `(predicate, object)` records for arbitrary RDF triples
3. **Combination**: Use both approaches together — they are merged into the generated vocabulary

**When to use annotation metadata:**
- ✅ Simple key-value metadata (version info, labels, comments)
- ✅ Multiple values for same predicate (e.g., multiple `rdfs:label` with different languages)
- ✅ Literal values (strings, numbers, dates)
- ✅ IRI references (e.g., `dc:creator <https://orcid.org/0000-0001-2345-6789>`)
- ✅ Metadata that should be visible in code for developers
- ❌ Complex structured metadata with blank nodes → use [extension files](#extension-files)

**Example: Class metadata**

```dart
@RdfGlobalResource.define(
  myVocab,
  IriStrategy('https://my.app.de/books/{id}'),
  label: 'Book',
  comment: 'Represents a published book with bibliographic metadata',
  metadata: [
    (Dcterms.created, LiteralTerm.withDatatype('2025-01-15', Xsd.date)),
    (Dcterms.creator, IriTerm('https://orcid.org/0000-0001-2345-6789')),
    (OwlVocab.versionInfo, LiteralTerm('1.0.0')),
  ],
)
class Book {
  // ...
}
```

This generates:

```turtle
<https://my.app.de/vocab#Book> a owl:Class ;
    rdfs:label "Book" ;
    rdfs:comment "Represents a published book with bibliographic metadata" ;
    dc:created "2025-01-15"^^xsd:date ;
    dc:creator <https://orcid.org/0000-0001-2345-6789> ;
    owl:versionInfo "1.0.0" .
```

**Example: Property metadata**

```dart
@RdfProperty.define(
  fragment: 'isbn',
  label: 'ISBN',
  comment: 'International Standard Book Number',
  metadata: [
    (RdfsVocab.range, Xsd.string),
    (OwlVocab.deprecated, LiteralTerm.withDatatype('false', Xsd.boolean)),
  ],
)
final String isbn;
```

This generates:

```turtle
<https://my.app.de/vocab#isbn> a rdf:Property ;
    rdfs:label "ISBN" ;
    rdfs:comment "International Standard Book Number" ;
    rdfs:range xsd:string ;
    owl:deprecated false .
```

**Metadata value types:**

- **Literal values**: Use `LiteralTerm('value')`, optionally with `LiteralTerm.withDatatype(...)` or `LiteralTerm.withLanguage(...)`. Note that the general `LiteralTerm('value', datatype:..., language:...)` constructor will cause analyze errors in const context, so you need to use the specific ones mentioned before instead.
- **IRI values**: Use `IriTerm('https://...')` for references to external resources
- **Mixing types**: `metadata` accepts `List<(IriTerm, RdfObject)>`, so you can mix literals and IRIs freely

**Merging behavior:**

When you use both `label`/`comment` AND `metadata`, they are merged:

```dart
@RdfGlobalResource.define(
  myVocab,
  IriStrategy('https://my.app.de/books/{id}'),
  label: 'Book',  // Becomes rdfs:label
  metadata: [
    (Dcterms.title, LiteralTerm('Book Class')),  // Different predicate
    (OwlVocab.versionInfo, LiteralTerm('1.0')),
  ],
)
```

Results in:

```turtle
<https://my.app.de/vocab#Book> a owl:Class ;
    rdfs:label "Book" ;
    dc:title "Book Class" ;
    owl:versionInfo "1.0" .
```

**Note on `AppVocab` metadata:**

`AppVocab` also supports `label`, `comment`, and `metadata` parameters for ontology-level metadata (applying to the vocabulary IRI itself, e.g., `<https://my.app.de/vocab#>`). This is useful for versioning, authorship, and licensing information at the vocabulary level.

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

  /// Default base class for generated classes when not explicitly specified via subClassOf.
  /// Defaults to owl:Thing (modern OWL best practice).
  /// Can be overridden to rdfs:Resource or other base classes.
  final IriTerm defaultBaseClass; // defaults to Owl.Thing

  /// Well-known properties for auto-matching.
  /// Maps fragment names to standard property IRIs.
  /// When non-empty, properties matching these fragments will reuse
  /// the specified standard property IRIs instead of generating custom ones.
  /// 
  /// **Optional with sensible default:** Defaults to a curated list of common properties
  /// (Dublin Core, FOAF, etc.). Users can:
  /// - Accept default: omit parameter or use `defaultWellKnownProperties`
  /// - Customize: provide custom map
  /// - Opt-out completely: set to empty map `{}`
  final Map<String, IriTerm> wellKnownProperties;

  /// Default curated list of well-known properties.
  /// Conservative list of most common properties from Dublin Core and FOAF.
  static const Map<String, IriTerm> defaultWellKnownProperties = {
    'title': Dc.title,
    'description': Dc.description,
    'creator': Dc.creator,
    'created': Dc.created,
    'modified': Dc.modified,
    'publisher': Dc.publisher,
    'subject': Dc.subject,
    'name': Foaf.name,
    'homepage': Foaf.homepage,
    'email': Foaf.mbox,
    // ... can be extended in minor versions with careful compatibility management
  };

  const AppVocab({
    required this.appBaseUri,
    this.vocabPath = '/vocab',
    this.defaultBaseClass = Owl.Thing,
    this.wellKnownProperties = defaultWellKnownProperties, // Optional with default
  });

  // Subclassing example:
  // class CustomContracts extends AppVocab {
  //   const CustomContracts() : super(
  //     appBaseUri: 'https://contracts.app',
  //     vocabPath: '/contracts',
  //     defaultBaseClass: Owl.Thing,
  //     wellKnownProperties: {
  //       // Custom list - completely replaces default
  //       'title': Dc.title,
  //       'subject': Dc.subject,
  //       'contractDate': Dc.created,
  //     },
  //   );
  //   // ... or use wellKnownProperties: {} to disable auto-matching
  //   // ... or omit wellKnownProperties to use default curated list
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
  const RdfProperty.define({
    this.fragment, // override the auto-derived fragment identifier
    // ... other named params as in default constructor
  });
}
```

This is acceptable because `.define()` is intended as the **default annotation for unannotated fields** when the class annotation activates generated vocab mode. The generator would treat a bare field (no `@RdfProperty` at all) in a generated-vocab class as implicitly `@RdfProperty.define()`.

### 4. SubclassOf on Class Annotations

`subClassOf` is a per-class concern (different classes in the same vocab typically have different superclasses), so it belongs on the `.define()` constructor of the resource annotation, not on `AppVocab`.

```dart
@RdfGlobalResource.define(
  myVocab,
  IriStrategy('http://example.org/person/{id}'),
  subClassOf: SchemaPerson.classIri,
)
class Person { ... }
```

### 5. `RdfLocalResource` Generated Vocab

Same pattern applies:

```dart
@RdfLocalResource.define(myVocab)
class Chapter {
  @RdfProperty.define()
  final String chapterNumber; // Custom property
  final String title; // Auto-matched to dc:title
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
- **Generated vocab properties** (via `.define()` + implicit fields)

This is especially useful when subclassing external types:

```dart
@RdfGlobalResource.define(
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

The generator only creates vocab entries for fields that:
1. Don't have an explicit `@RdfProperty(iriTerm)` annotation, AND
2. Don't match any entry in `wellKnownProperties` (which auto-match to standard vocabs)

### Naming

The config class is named **`AppVocab`**. It's the shortest, most intuitive option and aligns with the `appBaseUri` parameter. The "app" framing matches the target audience (software developers building apps who are RDF beginners). Documentation clarifies that it works equally well for libraries via subclassing (e.g. `CustomContracts extends AppVocab`).

The constructor name is **`.define()`** .

### Field Handling in Generated-Vocab Mode

In generated-vocab mode (`.define()` on the class), unannotated fields are automatically processed for RDF mapping. The user already opted in explicitly via `.define()` on the class, so automatic property handling is expected and desired.

**Rules:**

- **Completely unannotated fields** (in `.define()` classes) → Generator checks `wellKnownProperties` first. If fragment matches, uses standard IRI (no custom vocab entry). Otherwise, generates custom vocab entry.
- **`@RdfProperty.define()` fields** → ALWAYS generates custom property IRI, bypassing `wellKnownProperties` lookup. This is an opt-out mechanism for auto-matching.
- **`@RdfIriPart` fields** → excluded from property generation (IRI parts are identifiers, not properties). If a field should be both an IRI part *and* a serialized property, an explicit `@RdfProperty` or `@RdfProperty.define()` is required — consistent with existing API behavior.
- **Excluding a field entirely** → `@RdfIgnore()`. Completely excludes the field from RDF mapping (no vocab entry, not serialized, not deserialized). Use for application state, UI fields, or computed properties that shouldn't be persisted to RDF.
- **Read-only RDF properties** → `@RdfProperty.define(include: false)`. The property IS in the vocabulary and will be deserialized, but NOT serialized (read-only from application perspective). Use when data flows from RDF into your app but shouldn't be written back. Note: Uses custom property IRI, bypasses wellKnownProperties.
- **Explicitly annotated `@RdfProperty(iriTerm)` fields** → use the provided IRI term as-is, no vocab entry generated, bypasses wellKnownProperties.

**Example showing all field handling options:**

```dart
@RdfGlobalResource.define(myVocab, IriStrategy('https://my.app.de/books/{id}'))
class Book {
  @RdfIriPart('id')
  final String id; // IRI part, not a property

  // Completely unannotated - auto-matched to dc:title (no vocab entry)
  final String title;
  
  // Completely unannotated - generates custom vocab entry
  final String isbn;
  final String pageCount;

  // Explicit external vocabulary - no vocab entry generated
  @RdfProperty(SchemaBook.publisher)
  final String publisher;

  // Explicit custom property - bypasses wellKnownProperties, generates custom vocab entry
  @RdfProperty.define()
  final String description; // Custom #description, NOT dc:description

  // Read-only RDF property - custom vocab entry, deserialized but NOT serialized
  @RdfProperty.define(include: false)
  final DateTime lastModified; // Server updates this, app reads it

  // Completely excluded from RDF - no vocab entry, no mapping at all
  @RdfIgnore()
  bool isExpanded; // UI state

  @RdfIgnore()
  bool get isOverdue => DateTime.now().isAfter(dueDate); // Computed
}
```

Generated vocabulary will contain:
- `#isbn` (rdf:Property)
- `#pageCount` (rdf:Property)
- `#description` (rdf:Property) — custom property, wellKnownProperties bypassed by explicit @RdfProperty.define()
- `#lastModified` (rdf:Property) — even though it's read-only from app perspective
- NO entry for `title` (auto-matched to dc:title from wellKnownProperties)
- NO entry for `publisher` (external vocab)
- NO entry for `isExpanded` or `isOverdue` (@RdfIgnore)

### Well-Known Property Auto-Matching

**Primary mechanism for unannotated properties in generated-vocab mode.** When using `.define()` on a class, unannotated fields are checked against `AppVocab.wellKnownProperties`. If the field name matches an entry in the map (which by default contains a curated list), the generator uses that standard property IRI instead of generating a custom one.

This auto-matching happens as the **first step** for unannotated fields in `.define()` classes, regardless of whether there are naming collisions or not.

**Scope:** Auto-matching ONLY applies to:
- Classes annotated with `Rdf*Resource.define()` (not regular `RdfGlobalResource` or `RdfLocalResource`)
- Fields WITHOUT any `@RdfProperty` annotation (completely unannotated)

**Does NOT apply to:**
- Fields with `@RdfProperty(iriTerm)` (explicit IRI provided)
- Fields with `@RdfProperty.define()` (explicit custom property generation requested)
- Classes using regular `RdfGlobalResource` / `RdfLocalResource` (non-generated vocab mode)

```dart
// Default behavior - uses built-in curated list
const myVocab = AppVocab(appBaseUri: 'https://my.app.de');

// Or customize the list
const myVocabCustom = AppVocab(
  appBaseUri: 'https://my.app.de',
  wellKnownProperties: {
    'title': Dc.title,
    'description': Dc.description,
    'name': Foaf.name,
    'subject': Dc.subject,
  },
);

@RdfGlobalResource.define(myVocab, IriStrategy('https://my.app.de/books/{id}'))
class Book {
  final String title; // Auto-matched to dc:title (from default curated list)
  final String description; // Auto-matched to dc:description
}

@RdfGlobalResource.define(myVocab, IriStrategy('https://my.app.de/persons/{id}'))
class Person {
  final String name; // Auto-matched to foaf:name (from default curated list)
  final String title; // Auto-matched to dc:title (same property as Book.title!)
}
```

Generated vocabulary:
```turtle
# No custom property definitions needed — all auto-matched to standard vocabs
<https://my.app.de/vocab#Book> a owl:Class .
<https://my.app.de/vocab#Person> a owl:Class .

# Properties use standard IRIs (from wellKnownProperties map)
# No rdfs:domain restrictions are added (preserving domain-neutral semantics)
```

**Benefits:**
- ✅ **"Just works" by default** - RDF beginners get sensible standard property reuse automatically
- ✅ **Configurable** - Power users can customize or disable as needed
- ✅ Promotes vocabulary reuse and interoperability
- ✅ Reduces custom vocabulary bloat
- ✅ Leverages well-established semantics
- ✅ Aligns with the `.define()` philosophy: lower the RDF barrier

**Risks and Mitigations:**
- ⚠️ **Future compatibility:** Changing the default curated list could change generated IRIs
  - **Mitigation:** Be extremely conservative about the default list (10-15 most common properties only)
  - **Mitigation:** Warn on regeneration if IRIs would change (see [Future Compatibility](#future-compatibility-with-auto-matching))
  - **Mitigation:** Users can lock their list by explicitly providing `wellKnownProperties`
- ⚠️ **Unintended semantic matches:** User's "title" might have different semantics than dc:title
  - **Risk analysis:** Consequences are semantic errors (RDF consumers misinterpret data, SPARQL queries find it incorrectly), NOT structural errors. For the target audience (RDF beginners, prototypes), this is acceptable - they're unlikely to have complex RDF consumers initially. Production use should employ manual vocabularies.
  - **Mitigation:** Override with `@RdfProperty.define(fragment: 'bookTitle')` to bypass auto-matching
  - **Mitigation:** Set `wellKnownProperties: {}` to disable entirely for specific AppVocab
  - **Accepted risk:** Users may not detect semantic mismatch, but impact is limited to semantics, not functionality

**Opt-out mechanisms:**
1. **Disable for specific property:** `@RdfProperty.define()` — forces custom IRI generation, bypasses wellKnownProperties auto-matching
2. **Disable for entire vocabulary:** `wellKnownProperties: {}` — empty map disables auto-matching
3. **Custom list:** `wellKnownProperties: {'name': Foaf.name}` — only match what you specify
4. **Explicit property:** `@RdfProperty(Dcterms.title)` — use specific standard property, complete manual control

**Open question:** Future compatibility when default curated list changes - see [Future Compatibility](#future-compatibility-with-auto-matching).

### Custom Property Collision Handling

For properties that are **NOT matched** by `wellKnownProperties`, the generator creates custom property IRIs. When the same property fragment appears in multiple classes, collision handling uses domain-based merging logic.

**Auto-domain behavior:** By default, the generator automatically adds `rdfs:domain` to each custom property pointing to the class IRI where it's defined.

**Merging strategies:**

1. **Same domain** (explicit or auto) → Merge into one property definition
2. **Domain-neutral properties** (`noDomain: true`) → Merge if all occurrences use `noDomain: true`
3. **Explicit custom domain** (via metadata) → Merge if same fragment has same explicit domain
4. **Conflicting cases** → Build error with resolution options

**Example: Explicit shared domain**

```dart
@RdfGlobalResource.define(
  myVocab,
  IriStrategy('https://my.app.de/books/{id}'),
  subClassOf: IriTerm('https://my.app.de/vocab#Publication'),
)
class Book {
  @RdfProperty.define(
    metadata: [(Rdfs.domain, IriTerm('https://my.app.de/vocab#Publication'))],
  )
  final String customTitle; // Custom domain specified - will merge with Article.customTitle
}

@RdfGlobalResource.define(
  myVocab,
  IriStrategy('https://my.app.de/articles/{id}'),
  subClassOf: IriTerm('https://my.app.de/vocab#Publication'),
)
class Article {
  @RdfProperty.define(
    metadata: [(Rdfs.domain, IriTerm('https://my.app.de/vocab#Publication'))],
  )
  final String customTitle; // Same fragment + same domain → merged!
}
```

Generated vocabulary:
```turtle
<https://my.app.de/vocab#Book> a owl:Class ;
    rdfs:subClassOf <https://my.app.de/vocab#Publication> .
<https://my.app.de/vocab#Article> a owl:Class ;
    rdfs:subClassOf <https://my.app.de/vocab#Publication> .

# Single property definition with explicit domain
<https://my.app.de/vocab#customTitle> a rdf:Property ;
    rdfs:domain <https://my.app.de/vocab#Publication> .
```

**Example: Domain-neutral property**

```dart
@RdfGlobalResource.define(myVocab, IriStrategy('https://my.app.de/books/{id}'))
class Book {
  @RdfProperty.define(noDomain: true)
  final String identifier; // Domain-neutral - can be shared
}

@RdfGlobalResource.define(myVocab, IriStrategy('https://my.app.de/persons/{id}'))
class Person {
  @RdfProperty.define(noDomain: true)
  final String identifier; // Same fragment + both noDomain → merged!
}
```

Generated vocabulary:
```turtle
<https://my.app.de/vocab#Book> a owl:Class .
<https://my.app.de/vocab#Person> a owl:Class .

# Single domain-neutral property
<https://my.app.de/vocab#identifier> a rdf:Property .
# No rdfs:domain specified - can be used with any class
```

**Example: Collision error**

```dart
@RdfGlobalResource.define(myVocab, IriStrategy('https://my.app.de/books/{id}'))
class Book {
  final String customField; // Auto-domain: Book
}

@RdfGlobalResource.define(myVocab, IriStrategy('https://my.app.de/persons/{id}'))
class Person {
  final String customField; // Auto-domain: Person - CONFLICT!
}
```

**Error message:**
```
Error: Duplicate property fragment 'customField' found in multiple classes with conflicting domains:
  - Book.customField (auto-domain: https://my.app.de/vocab#Book)
  - Person.customField (auto-domain: https://my.app.de/vocab#Person)

This is ambiguous. Options to resolve:

1. Use a well-known property (add to wellKnownProperties or use explicit annotation):
   @RdfProperty(Dcterms.identifier)
   final String customField;

2. Make the property domain-neutral to share it:
   @RdfProperty.define(noDomain: true)
   final String customField;

3. Specify a shared domain explicitly:
   @RdfProperty.define(
     metadata: [(Rdfs.domain, IriTerm('https://my.app.de/vocab#Thing'))],
   )
   final String customField;

4. Use different fragments to keep them separate:
   @RdfProperty.define(fragment: 'bookCustomField')
   final String customField;
```

**Complete property handling flow:**

1. **First:** Check if fragment matches `wellKnownProperties` → use standard IRI (no custom property generated)
2. **Then:** For custom properties only, apply domain-based collision logic above

**Collision resolution rules:**

| Scenario | Domain | Action |
|----------|--------|--------|
| Same domain (explicit or auto) | Same | Merge into one property with shared domain |
| Different domains | Different | **Error:** Conflicting domain declarations |
| Both noDomain | Both noDomain | Merge into domain-neutral property |
| Mixed (some domain, some noDomain) | Mixed | **Error:** Inconsistent declarations |
| No fragment collision | Any | Generate separate properties (each with auto-domain unless noDomain: true) |

**Note:** Well-known property matching happens before this collision handling - matched properties use standard IRIs and skip custom property generation entirely.

### Vocab File Output and Configuration

The generator produces Turtle `owl:Ontology` definitions deployable to the vocabulary URIs. Since [dart-lang/build#3171](https://github.com/dart-lang/build/pull/3171) (Aug 2021), `build_runner` officially supports **dynamic `buildExtensions` computed from `BuilderOptions`** at runtime. This enables flexible output file configuration via `build.yaml`.

**Implementation approach:**

An `AggregatingBuilder` (similar to the existing init file builder) collects all `@*.define()` annotated classes, groups them by vocabulary IRI (`appBaseUri + vocabPath`), and outputs one `.ttl` file per vocabulary.

**Vocabulary configuration** is specified per vocabulary IRI in `build.yaml` options:

```yaml
targets:
  $default:
    builders:
      locorda_rdf_mapper_generator|vocab_builder:
        options:
          vocabularies:
            "https://my.app.de/vocab#":
              output_file: "lib/vocab.g.ttl"
              extensions: "lib/vocab_extensions.ttl"  # optional
            "https://my.app.de/contracts#":
              output_file: "lib/contracts.g.ttl"
```

**Configuration options per vocabulary:**

- **`output_file`** (optional): Path where the generated Turtle file will be written. If omitted, defaults to `lib/vocab.g.ttl` when only one vocabulary exists, or requires explicit configuration for multiple vocabularies.
- **`extensions`** (optional): Path to a Turtle/TriG file containing additional RDF triples to merge with the generated vocabulary. See [Extension Files](#extension-files) below.

**Shorthand syntax:**

For simple cases where you only need to specify the output file, you can use a string directly:

```yaml
vocabularies:
  "https://my.app.de/vocab#": "lib/vocab.g.ttl"
```

This is equivalent to:

```yaml
vocabularies:
  "https://my.app.de/vocab#":
    output_file: "lib/vocab.g.ttl"
```

**Default behavior** (no `vocabularies` map configured):
- All vocabularies merge into a single file: `lib/vocab.g.ttl`
- This covers the common case: one `AppVocab` per app
- No extension files are loaded

**Multi-vocabulary projects:**
- Configure explicit `vocabularies` map
- Each unique vocab IRI should have its own configuration
- Build error if a vocab IRI appears in code but not in the configuration (fail-fast)

**File naming conventions:**
- **`.g.ttl` extension:** Signals "generated file, do not edit" — follows `build_runner` convention for generated artifacts (e.g. `.g.dart`)
- **`lib/` directory:** Correct location for public, deployable artifacts (not `lib/src/`, which implies private implementation details). Consistent with `lib/init_rdf_mapper.g.dart`.

#### Extension Files

Extension files provide a **clean separation** between annotation-based vocabulary generation and complex metadata that doesn't fit well in const annotations.

**Use cases:**
- **Structured metadata with blank nodes:** Complex creator info, provenance records, structured descriptions
- **Advanced OWL constructs:** Property chains, complex axioms, SHACL shapes
- **Human-curated documentation:** Rich examples, usage notes, see-also links with context
- **Metadata beyond simple key-value:** Any RDF that requires multiple triples or blank nodes

**Extension file format:**

Extension files are standard Turtle or TriG files. They can contain any RDF triples you want to merge with the generated vocabulary:

```turtle
# lib/vocab_extensions.ttl
@prefix dc: <http://purl.org/dc/terms/> .
@prefix foaf: <http://xmlns.com/foaf/0.1/> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .

# Complex ontology metadata with blank nodes
<https://my.app.de/vocab#> 
  dc:creator [
    foaf:name "John Doe" ;
    foaf:mbox <mailto:john@example.com> ;
    foaf:homepage <https://johndoe.com>
  ] ;
  dc:contributor <https://orcid.org/0000-0001-2345-6789> ;
  owl:versionIRI <https://my.app.de/vocab/1.0#> .

# Additional class annotations
<https://my.app.de/vocab#Book>
  dc:description "A comprehensive representation of published books with extended metadata." ;
  owl:deprecated false .

# Property constraints or examples
<https://my.app.de/vocab#isbn>
  dc:example "978-3-16-148410-0" .
```

**Processing:**

1. Generator creates base vocabulary from annotated Dart classes
2. If `extensions` file is configured, parse it as RDF (Turtle/TriG)
3. Merge extension triples with generated triples (simple concatenation of graphs)
4. Write combined result to the output file

**Why extension files:**

- ✅ **No const constraints:** Full RDF expressiveness, blank nodes, arbitrary complexity
- ✅ **Separation of concerns:** Annotation metadata stays simple, complex metadata in dedicated files
- ✅ **Version controlled:** Extension files are source files, tracked alongside code
- ✅ **Reviewable:** Plain text, can be reviewed and diffed like any source file
- ✅ **Gradual adoption:** Start with annotation metadata, add extension file when needed
- ❌ **One more file:** But only when needed, and clearly separated from generated code

**Annotation metadata vs Extension files:**

Use **annotation metadata** (`AppVocab.metadata`, class/property metadata params) for:
- Simple triples (key-value pairs, version info, labels, creator IRIs)
- Multiple values for same predicate (e.g., `rdfs:label` translations)
- Metadata that should be visible in code
- Common cases (95% of use cases)

Use **extension files** for:
- Structured metadata with blank nodes
- Complex provenance or attribution
- Advanced OWL/RDFS constructs (property chains, restrictions, etc.)

**Builder mechanics:**
1. Builder constructor: Parse `vocabularies` map from `BuilderOptions` → compute `buildExtensions` (or default to `{'$lib$': ['vocab.g.ttl']}`)
2. `build()` method: 
   - Parse all Dart inputs, extract vocab IRIs from `AppVocab` instances
   - Match vocab IRIs to configuration
   - Generate base vocabulary triples from annotations
   - If `extensions` configured, parse extension file and merge graphs
   - Write combined result to the configured output file
3. Aggregate vocabulary definitions per namespace

**Why this works:**
- `buildExtensions` is computed from static `build.yaml` config (not from Dart code content)
- AggregatingBuilder handles n:1 (many annotated classes → one vocab file per namespace)
- Dynamic `buildExtensions` from options is an officially supported feature since 2021
- TriG/Turtle parser already exists in `locorda_rdf_core`

### Future Compatibility with Auto-Matching

**Context:** Auto-matching only makes sense if it is the default behavior (no configuration required) as its aim is to lower the barrier for non-RDF-savvy developers. This is especially critical for **locorda/sync-engine** users who may not care about RDF at all — the library's success depends on ease of use. "Just works for beginners" is a strong requirement, so treating auto-matching as a power-user opt-in feature is not an option.

**The Challenge:**

If we auto-match by default with a built-in curated list, and later add properties to that list, existing vocabularies would silently change property IRIs on regeneration. This could break data compatibility.

**Example scenario:**
1. Developer uses `.define()` mode in 2025
2. Auto-matching is enabled but `publisher` is not in the curated list
3. Their `publisher` property generates custom IRI: `<https://my.app.de/vocab#publisher>`
4. They publish data using this IRI
5. In 2026, we add `publisher → dc:publisher` to the curated auto-match list  
6. They regenerate their code → property now uses `<http://purl.org/dc/elements/1.1/publisher>`
7. **Breaking change:** Old data uses one IRI, new code expects another

**Reality Check - What We Can't Do:**

1. ❌ **Generated code comments** - RdfGraph doesn't support comments in TTL output, and users won't read generated code
2. ❌ **Build-time INFO logging** - Not shown by default in current build_runner versions
3. ❌ **Detect changes from previous build** - build_runner might have cleaned outputs, user might have run `clean`
4. ❌ **Prevent the problem entirely** - Developers can cause same breaking changes with custom wellKnownProperties lists

**What We CAN Do:**

1. **Lock file tracking via direct File I/O (effective protection):**
   - **Bypass buildStep entirely** - use `dart:io` File API directly
   - Write `.locorda_rdf_mapper.lock` file in package root (alongside `pubspec.yaml`)
   - **Single file for all vocabularies** - simpler than per-vocabulary files
   - **Survives `build_runner clean`** - not treated as build output
   - Committed to source control (permanent state tracking)
   - Similar to `pubspec.lock`, `.flutter-plugins` - metadata ABOUT the build, not build output
   
   **Tradeoffs:**
   - ✅ **Reliable persistence** - immune to clean operations
   - ✅ **Always written** - even if nothing else changed, lock file updates
   - ✅ **Source of truth** - guaranteed to reflect last successful build
   - ✅ **Standard location** - package root, like all other lock files
   - ✅ **Single file simplicity** - one lock file per package, not per vocabulary
   - ⚠️ **Violates build_runner isolation** - but justified for state tracking
   - ⚠️ **Side effects outside buildStep** - but necessary for cross-build state
   
   Example `.locorda_rdf_mapper.lock`:
   ```json
   {
     "lockFileVersion": 1,
     "types": {
       "Book": {
         "classIri": "https://my.app.de/vocab#Book",
         "properties": {
           "title": {
             "iri": "http://purl.org/dc/terms/title",
             "source": "auto"
           },
           "isbn": {
             "iri": "https://my.app.de/vocab#isbn",
             "source": "auto"
           },
           "publisher": {
             "iri": "http://purl.org/dc/elements/1.1/publisher",
             "source": "external"
           }
         }
       },
       "Person": {
         "classIri": "https://my.app.de/vocab#Person",
         "properties": {
           "name": {
             "iri": "http://xmlns.com/foaf/0.1/name",
             "source": "auto"
           },
           "title": {
             "iri": "http://purl.org/dc/terms/title",
             "source": "auto"
           }
         }
       }
     }
   }
   ```
   
   **Lock file structure:**
   - `lockFileVersion`: Format version (currently 1) - allows lock file format evolution
   - `types`: Per-Dart-class tracking, keyed by class name
     - `classIri`: The class IRI for this type (enables class IRI change detection)
     - `properties`: All properties in this class, keyed by field name
       - `iri`: The resolved property IRI
       - `source`: How the IRI was determined:
         - `"auto"` - Unannotated field, auto-matched or custom generated (breaking change if IRI changes)
         - `"define"` - `@RdfProperty.define()` field (warning if IRI changes unexpectedly)
         - `"external"` - `@RdfProperty(iriTerm)` field (warning if IRI changes - unusual, might indicate annotation mistake)
   - Future extensions could add: `subClassOf`, `domains`, etc. at type level
   
   **Detection behavior:**
   - `source: "auto"` IRI change → **Build FAILS** (breaking compatibility change for this type's mapping)
   - `source: "auto"` property disappears → **Build FAILS** (field removed/renamed, existing RDF data won't deserialize)
   - `source: "auto"` class disappears → **Build FAILS** (class removed/renamed, breaking change)
   - `source: "define"` IRI change → **Warning** (unexpected, review annotation changes)
   - `source: "define"` property/class disappears → **Info** (explicit annotation removed, likely intentional)
   - `source: "external"` IRI change → **Warning** (unusual, might be intentional refactoring)
   - `source: "external"` property/class disappears → **Info** (explicit annotation removed, likely intentional)
   - Class IRI change → **Warning** (class identity changed, review)
   - New `source: "auto"` property → **Info** (tracked going forward)
   
   **What's tracked:**
   - All RDF-mapped classes using `.define()` mode
   - All properties from fields in those classes, regardless of annotation
   - Complete picture of RDF mapping state for change detection
   - Source tracking enables appropriate response (fail vs warn) based on change impact
   
   **Implementation approach:**
   - Builder reads lock file from package root via File I/O at start of build
   - For each `.define()` class, check if class exists in `types[className]`
   - For each field in the class, determine source (`auto`, `define`, or `external`)
   - If class+field exists in lock file: compare current IRI vs locked IRI
     - `source: "auto"` + IRI mismatch → **fail build** (breaking change for this type's mapping)
     - `source: "define"` + IRI mismatch → **warn** (unexpected but might be intentional)
     - `source: "external"` + IRI mismatch → **warn** (unusual, possibly annotation typo fix)
   - After processing all current classes, check for disappeared items:
     - Lock file class not in current build + has `source: "auto"` properties → **fail build** (class removed/renamed)
     - Lock file property not in current class + `source: "auto"` → **fail build** (field removed/renamed)
     - Disappeared `source: "define"` or `source: "external"` → **info** (explicit annotation removed)
   - Compare class IRI, warn if changed
   - Write updated lock file with all types, their class IRIs, and properties with sources
   - Lock file write happens OUTSIDE buildStep.writeAsString()

2. **Build failure on incompatible changes:**
   ```
   [ERROR] Property IRI changed in class 'Book'
   
   Lock file (.locorda_rdf_mapper.lock) shows:
     Book.publisher → https://my.app.de/vocab#publisher (source: auto)
   
   Current wellKnownProperties would map to:
     Book.publisher → http://purl.org/dc/elements/1.1/publisher
   
   This is a BREAKING CHANGE for auto-matched properties. Options:
   
   1. Keep current behavior (recommended):
      Lock the property to its custom IRI using explicit annotation:
      @RdfProperty(IriTerm('https://my.app.de/vocab#publisher'))
      final String publisher;
      
      Or force custom property generation:
      @RdfProperty.define()
      final String publisher;
   
   2. Accept breaking change and migrate data:
      Delete lock file, regenerate, update all existing RDF data to use dc:publisher
   
   Build halted to prevent silent data incompatibility.
   ```
   
   **Disappeared properties/classes:**
   ```
   [ERROR] Auto-matched property disappeared from class 'Book'
   
   Lock file (.locorda_rdf_mapper.lock) shows:
     Book.publisher → https://my.app.de/vocab#publisher (source: auto)
   
   This property no longer exists in the current code. This is a BREAKING CHANGE.
   Existing RDF data with this property IRI cannot be deserialized.
   
   Options:
   1. If field was renamed, rename it back or add compatibility mapping
   2. If class was renamed, rename it back or handle migration explicitly
   3. If removal is intentional, delete lock file and migrate existing RDF data
   
   Build halted to prevent silent data incompatibility.
   ```

3. **Warnings for non-breaking changes:**
   ```
   [WARNING] Property IRI changed in class 'Book'
   
   Lock file (.locorda_rdf_mapper.lock) shows:
     Book.title → http://purl.org/dc/terms/title (source: external)
   
   Current annotation uses:
     Book.title → http://purl.org/dc/elements/1.1/title
   
   This might be intentional refactoring. If this change is unexpected, review your
   @RdfProperty annotations. Build will continue - only auto-matched properties cause failures.
   ```
   
   For `source: "define"` or `source: "external"` changes, the build continues with a warning since these
   are explicitly annotated and the developer has direct control over the IRI.

**How This Protects Us:**

- **Lock file immune to `clean`** - written via direct File I/O, not managed by build_runner
- **Always reflects last build** - updated even when other outputs are cached
- **Detects RDF mapping changes** - tracks how each Dart class maps to RDF, protecting serialization stability
- **Developer-friendly organization** - keyed by class name (Book, Person), not abstract vocabulary IRIs
- **Appropriate responses** - fails for breaking changes (`auto`), warns for unusual changes (`define`/`external`)
- **Complete type tracking** - all properties tracked per class, handles collision/merging cases explicitly
- **Class IRI changes detected** - warns if class identity changes
- **Precise error messages** - "Book.publisher changed" instead of "publisher in https://... changed"
- **Escape hatch always works** - explicit annotations override auto-matching, lock file warns about changes

**Why Direct File I/O Works:**

The lock file is **metadata about the build state**, not a build output:
- Similar to `pubspec.lock` (dependency resolution state) - package root
- Similar to `.flutter-plugins` (plugin registration state) - package root
- Similar to `.flutter-plugins-dependencies` (plugin dependency state) - package root

These are all written directly by their respective tools in the package root, not through build_runner, because they track state that needs to survive across build operations. Our lock file serves the same purpose - tracking RDF mapping state (how Dart types map to RDF IRIs) so we can detect breaking changes in serialization behavior.

**Limitations:**

- **First-time users have no lock file** - they get current auto-match list by default (acceptable for new projects)
- **Manual intervention required on conflicts** - but that's better than silent breaking changes
- **File I/O outside build system** - technically violates build_runner's isolation, but justified for state tracking (established pattern: `pubspec.lock`, etc.)

**Curation guidelines:**

While the lock file protects existing projects, the default list should still be curated thoughtfully:
- **Semantic clarity** - only include properties with clear, widely-understood semantics
- **Common usage** - properties that are genuinely common across many domains
- **Minimal surprise** - developers should be able to reasonably guess what's in the default list
- Start with 10-15 core properties: `title`, `description`, `creator`, `created`, `modified`, `name`, `homepage`, `email`
- Can be expanded in minor versions - lock file protects existing projects from breaking changes
- Curation is part of the codebase - no special governance process needed beyond standard code review

**Lock file must be committed:** Unlike `pubspec.lock` (which is sometimes gitignored for libraries), `.locorda_rdf_mapper.lock` should ALWAYS be committed to source control. It guards against breaking RDF mapping changes and is useless if not shared across developers/CI/CD.

**Decision:** Implement auto-matching with `.locorda_rdf_mapper.lock` protection via direct File I/O. Type-based organization (keyed by Dart class name) aligns with developer mental model and provides precise error messages. Lock file protection eliminates the need for extremely conservative curation - we can expand the default list in minor versions without breaking existing projects. Source tracking (`auto`/`define`/`external`) enables appropriate responses: build failures for breaking RDF mapping changes, warnings for unusual but non-breaking changes. Established precedent (`pubspec.lock`, `.flutter-plugins`) justifies breaking build_runner isolation for state tracking. This gives sync-engine the "just works" experience while protecting existing projects from silent breaking changes in RDF serialization behavior.

### Class Generation Philosophy

**Decision:** **Always generate custom classes**, even when only using well-known properties.

**Reasoning:**
1. Users chose `.define()` mode → they're defining their application vocabulary
2. Class membership has semantic meaning independent of properties
3. The class IRI establishes your application's domain model
4. Simpler implementation: No conditional logic about "is this class really needed?"
5. Better user experience: Predictable behavior (always generates what you define)

**Escape hatch:** Users who don't want custom classes should use manual vocabulary mode:
```dart
// Manual mode: No custom class generated
@RdfGlobalResource(Foaf.Person, IriStrategy('https://my.app.de/persons/{id}'))
class Person {
  @RdfProperty(Foaf.name)
  final String name;
}
```

### Default Base Class

**Decision:** Default to `owl:Thing`, configurable via `AppVocab.defaultBaseClass`.

**Reasoning:**
- Modern OWL ontologies use `owl:Thing` as the root class
- `owl:Thing` is the class of all OWL individuals (well-defined semantics)
- `rdfs:Resource` is too broad (includes literals, properties, etc.)
- Configurable for users who prefer `rdfs:Resource` or custom base classes
- Consistency with OWL ecosystem
