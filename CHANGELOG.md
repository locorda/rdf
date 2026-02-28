# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2026-02-28

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`locorda_rdf_canonicalization` - `v0.11.9`](#locorda_rdf_canonicalization---v0119)
 - [`locorda_rdf_core` - `v0.11.9`](#locorda_rdf_core---v0119)
 - [`locorda_rdf_mapper` - `v0.11.9`](#locorda_rdf_mapper---v0119)
 - [`locorda_rdf_mapper_annotations` - `v0.11.9`](#locorda_rdf_mapper_annotations---v0119)
 - [`locorda_rdf_mapper_generator` - `v0.11.9`](#locorda_rdf_mapper_generator---v0119)
 - [`locorda_rdf_terms_core` - `v0.11.9`](#locorda_rdf_terms_core---v0119)
 - [`locorda_rdf_terms_generator` - `v0.11.9`](#locorda_rdf_terms_generator---v0119)
 - [`locorda_rdf_xml` - `v0.11.9`](#locorda_rdf_xml---v0119)

---

#### `locorda_rdf_canonicalization` - `v0.11.9`

 - Bump "locorda_rdf_canonicalization" to `0.11.9`.

#### `locorda_rdf_core` - `v0.11.9`

 - **PERF**(trig-encoder): reduce 2.4 MB TriG encode time from ~7 s to ~100 ms.

#### `locorda_rdf_mapper` - `v0.11.9`

 - **FIX**(annotations): use generated universal term constants for defaultWellKnownProperties.

#### `locorda_rdf_mapper_annotations` - `v0.11.9`

 - **FIX**(annotations): use generated universal term constants for defaultWellKnownProperties.
 - **DOCS**: fixed reference to dc: where it should have been dcterms:.

#### `locorda_rdf_mapper_generator` - `v0.11.9`

 - **FIX**(vocab-builder): deduplicate shared noDomain fragments across resources.
 - **FIX**(vocab_builder): improve lock file error messages with detailed resolution steps.
 - **FIX**(mapper-generator): exclude hashCode and @RdfUnmappedTriples from .define() mode properties.
 - **FIX**: remove analyzer warnings our users sometimes see.
 - **FIX**(annotations): use generated universal term constants for defaultWellKnownProperties.

#### `locorda_rdf_terms_core` - `v0.11.9`

 - Bump "locorda_rdf_terms_core" to `0.11.9`.

#### `locorda_rdf_terms_generator` - `v0.11.9`

 - Bump "locorda_rdf_terms_generator" to `0.11.9`.

#### `locorda_rdf_xml` - `v0.11.9`

 - Bump "locorda_rdf_xml" to `0.11.9`.


## 2026-02-18

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`locorda_rdf_canonicalization` - `v0.11.8`](#locorda_rdf_canonicalization---v0118)
 - [`locorda_rdf_core` - `v0.11.8`](#locorda_rdf_core---v0118)
 - [`locorda_rdf_mapper` - `v0.11.8`](#locorda_rdf_mapper---v0118)
 - [`locorda_rdf_mapper_annotations` - `v0.11.8`](#locorda_rdf_mapper_annotations---v0118)
 - [`locorda_rdf_mapper_generator` - `v0.11.8`](#locorda_rdf_mapper_generator---v0118)
 - [`locorda_rdf_terms_core` - `v0.11.8`](#locorda_rdf_terms_core---v0118)
 - [`locorda_rdf_terms_generator` - `v0.11.8`](#locorda_rdf_terms_generator---v0118)
 - [`locorda_rdf_xml` - `v0.11.8`](#locorda_rdf_xml---v0118)

---

#### `locorda_rdf_canonicalization` - `v0.11.8`

 - Bump "locorda_rdf_canonicalization" to `0.11.8`.

#### `locorda_rdf_core` - `v0.11.8`

 - **FIX**(turtle): recognize boolean literals after commas and closing brackets.
 - **FEAT**: new const constructors for LiteralTerm.

#### `locorda_rdf_mapper` - `v0.11.8`

 - Bump "locorda_rdf_mapper" to `0.11.8`.

#### `locorda_rdf_mapper_annotations` - `v0.11.8`

 - **FEAT**(annotations): add vocabulary generation API.
 - **DOCS**: concept for automatic vocabulary .ttl generating.

#### `locorda_rdf_mapper_generator` - `v0.11.8`

 - **FEAT**(generator): implement vocabulary generation pipeline.

#### `locorda_rdf_terms_core` - `v0.11.8`

 - Bump "locorda_rdf_terms_core" to `0.11.8`.

#### `locorda_rdf_terms_generator` - `v0.11.8`

 - Bump "locorda_rdf_terms_generator" to `0.11.8`.

#### `locorda_rdf_xml` - `v0.11.8`

 - Bump "locorda_rdf_xml" to `0.11.8`.


## 2026-02-12

### Changes

---

Packages with breaking changes:

 - [`locorda_rdf_core` - `v0.11.7`](#locorda_rdf_core---v0117)
 - [`locorda_rdf_mapper` - `v0.11.7`](#locorda_rdf_mapper---v0117)

Packages with other changes:

 - [`locorda_rdf_canonicalization` - `v0.11.7`](#locorda_rdf_canonicalization---v0117)
 - [`locorda_rdf_mapper_annotations` - `v0.11.7`](#locorda_rdf_mapper_annotations---v0117)
 - [`locorda_rdf_mapper_generator` - `v0.11.7`](#locorda_rdf_mapper_generator---v0117)
 - [`locorda_rdf_terms_core` - `v0.11.7`](#locorda_rdf_terms_core---v0117)
 - [`locorda_rdf_terms_generator` - `v0.11.7`](#locorda_rdf_terms_generator---v0117)
 - [`locorda_rdf_xml` - `v0.11.7`](#locorda_rdf_xml---v0117)

---

#### `locorda_rdf_core` - `v0.11.7`

 - **FIX**(core): show error message of detected format when we have a parse error with detected format, not the error message of the last tried format.
 - **BREAKING** **FEAT**(turtle): add pretty-printing options for collections and blank nodes.

#### `locorda_rdf_mapper` - `v0.11.7`

 - **BREAKING** **FEAT**(turtle): add pretty-printing options for collections and blank nodes.

#### `locorda_rdf_canonicalization` - `v0.11.7`

 - Bump "locorda_rdf_canonicalization" to `0.11.7`.

#### `locorda_rdf_mapper_annotations` - `v0.11.7`

 - Bump "locorda_rdf_mapper_annotations" to `0.11.7`.

#### `locorda_rdf_mapper_generator` - `v0.11.7`

 - Bump "locorda_rdf_mapper_generator" to `0.11.7`.

#### `locorda_rdf_terms_core` - `v0.11.7`

 - Bump "locorda_rdf_terms_core" to `0.11.7`.

#### `locorda_rdf_terms_generator` - `v0.11.7`

 - Bump "locorda_rdf_terms_generator" to `0.11.7`.

#### `locorda_rdf_xml` - `v0.11.7`

 - Bump "locorda_rdf_xml" to `0.11.7`.


## 2026-02-05

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`locorda_rdf_canonicalization` - `v0.11.6`](#locorda_rdf_canonicalization---v0116)
 - [`locorda_rdf_core` - `v0.11.6`](#locorda_rdf_core---v0116)
 - [`locorda_rdf_mapper` - `v0.11.6`](#locorda_rdf_mapper---v0116)
 - [`locorda_rdf_mapper_annotations` - `v0.11.6`](#locorda_rdf_mapper_annotations---v0116)
 - [`locorda_rdf_mapper_generator` - `v0.11.6`](#locorda_rdf_mapper_generator---v0116)
 - [`locorda_rdf_terms_core` - `v0.11.6`](#locorda_rdf_terms_core---v0116)
 - [`locorda_rdf_terms_generator` - `v0.11.6`](#locorda_rdf_terms_generator---v0116)
 - [`locorda_rdf_xml` - `v0.11.6`](#locorda_rdf_xml---v0116)

---

#### `locorda_rdf_canonicalization` - `v0.11.6`

 - **FIX**: ensure consistent blank node labels across graphs in TriG and JSON-LD encoders.

#### `locorda_rdf_core` - `v0.11.6`

 - **FIX**: ensure consistent blank node labels across graphs in TriG and JSON-LD encoders.
 - **FIX**(trig-encoder): ensure blank line before GRAPH keyword in dataset serialization.

#### `locorda_rdf_mapper` - `v0.11.6`

 - Bump "locorda_rdf_mapper" to `0.11.6`.

#### `locorda_rdf_mapper_annotations` - `v0.11.6`

 - Bump "locorda_rdf_mapper_annotations" to `0.11.6`.

#### `locorda_rdf_mapper_generator` - `v0.11.6`

 - Bump "locorda_rdf_mapper_generator" to `0.11.6`.

#### `locorda_rdf_terms_core` - `v0.11.6`

 - Bump "locorda_rdf_terms_core" to `0.11.6`.

#### `locorda_rdf_terms_generator` - `v0.11.6`

 - Bump "locorda_rdf_terms_generator" to `0.11.6`.

#### `locorda_rdf_xml` - `v0.11.6`

 - Bump "locorda_rdf_xml" to `0.11.6`.


## 2026-02-03

### Changes

---

Packages with breaking changes:

 - [`locorda_rdf_core` - `v0.11.5`](#locorda_rdf_core---v0115)

Packages with other changes:

 - [`locorda_rdf_canonicalization` - `v0.11.5`](#locorda_rdf_canonicalization---v0115)
 - [`locorda_rdf_mapper` - `v0.11.5`](#locorda_rdf_mapper---v0115)
 - [`locorda_rdf_mapper_annotations` - `v0.11.5`](#locorda_rdf_mapper_annotations---v0115)
 - [`locorda_rdf_mapper_generator` - `v0.11.5`](#locorda_rdf_mapper_generator---v0115)
 - [`locorda_rdf_terms_core` - `v0.11.5`](#locorda_rdf_terms_core---v0115)
 - [`locorda_rdf_terms_generator` - `v0.11.5`](#locorda_rdf_terms_generator---v0115)
 - [`locorda_rdf_xml` - `v0.11.5`](#locorda_rdf_xml---v0115)

---

#### `locorda_rdf_core` - `v0.11.5`

 - **FIX**(jsonld): implement @base context support for relative IRI resolution.
 - **FEAT**: Add comprehensive JSON-LD dataset support with named graphs and base URI handling, and introduce TriG format for RDF datasets.
 - **FEAT**(jsonld): add configurable named graph handling for JsonLdGraphDecoder.
 - **BREAKING** **FEAT**(jsonld): add named graph support and refactor graph codecs.
 - **BREAKING** **FEAT**(trig): complete TriG implementation with named graph support.

#### `locorda_rdf_canonicalization` - `v0.11.5`

 - Bump "locorda_rdf_canonicalization" to `0.11.5`.

#### `locorda_rdf_mapper` - `v0.11.5`

 - Bump "locorda_rdf_mapper" to `0.11.5`.

#### `locorda_rdf_mapper_annotations` - `v0.11.5`

 - Bump "locorda_rdf_mapper_annotations" to `0.11.5`.

#### `locorda_rdf_mapper_generator` - `v0.11.5`

 - Bump "locorda_rdf_mapper_generator" to `0.11.5`.

#### `locorda_rdf_terms_core` - `v0.11.5`

 - Bump "locorda_rdf_terms_core" to `0.11.5`.

#### `locorda_rdf_terms_generator` - `v0.11.5`

 - Bump "locorda_rdf_terms_generator" to `0.11.5`.

#### `locorda_rdf_xml` - `v0.11.5`

 - Bump "locorda_rdf_xml" to `0.11.5`.


## 2026-01-21

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`locorda_rdf_canonicalization` - `v0.11.4`](#locorda_rdf_canonicalization---v0114)
 - [`locorda_rdf_core` - `v0.11.4`](#locorda_rdf_core---v0114)
 - [`locorda_rdf_mapper` - `v0.11.4`](#locorda_rdf_mapper---v0114)
 - [`locorda_rdf_mapper_annotations` - `v0.11.4`](#locorda_rdf_mapper_annotations---v0114)
 - [`locorda_rdf_mapper_generator` - `v0.11.4`](#locorda_rdf_mapper_generator---v0114)
 - [`locorda_rdf_terms_core` - `v0.11.4`](#locorda_rdf_terms_core---v0114)
 - [`locorda_rdf_terms_generator` - `v0.11.4`](#locorda_rdf_terms_generator---v0114)
 - [`locorda_rdf_xml` - `v0.11.4`](#locorda_rdf_xml---v0114)

---

#### `locorda_rdf_canonicalization` - `v0.11.4`

 - **DOCS**: simplify package READMEs by removing extensive cross-references.

#### `locorda_rdf_core` - `v0.11.4`

 - **DOCS**: simplify package READMEs by removing extensive cross-references.

#### `locorda_rdf_mapper` - `v0.11.4`

 - **DOCS**: corrected links to locorda.dev subpages.
 - **DOCS**: simplify package READMEs by removing extensive cross-references.

#### `locorda_rdf_mapper_annotations` - `v0.11.4`

 - **DOCS**: initialization file name was documented wrongly.

#### `locorda_rdf_mapper_generator` - `v0.11.4`

#### `locorda_rdf_terms_core` - `v0.11.4`

 - **DOCS**: corrected links to locorda.dev subpages.

#### `locorda_rdf_terms_generator` - `v0.11.4`

 - **FEAT**(terms-generator): improve list output for skipped vocabularies.
 - **DOCS**: corrected links to locorda.dev subpages.
 - **DOCS**: simplify package READMEs by removing extensive cross-references.

#### `locorda_rdf_xml` - `v0.11.4`

 - **DOCS**: simplify package READMEs by removing extensive cross-references.


## 2026-01-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`locorda_rdf_canonicalization` - `v0.11.3`](#locorda_rdf_canonicalization---v0113)
 - [`locorda_rdf_core` - `v0.11.3`](#locorda_rdf_core---v0113)
 - [`locorda_rdf_mapper` - `v0.11.3`](#locorda_rdf_mapper---v0113)
 - [`locorda_rdf_mapper_annotations` - `v0.11.3`](#locorda_rdf_mapper_annotations---v0113)
 - [`locorda_rdf_mapper_generator` - `v0.11.3`](#locorda_rdf_mapper_generator---v0113)
 - [`locorda_rdf_terms_core` - `v0.11.3`](#locorda_rdf_terms_core---v0113)
 - [`locorda_rdf_terms_generator` - `v0.11.3`](#locorda_rdf_terms_generator---v0113)
 - [`locorda_rdf_xml` - `v0.11.3`](#locorda_rdf_xml---v0113)

---

#### `locorda_rdf_canonicalization` - `v0.11.3`

 - Bump to `0.11.3` due to fixes for `locorda_rdf_mapper_generator`. We use synchronized versioning.

#### `locorda_rdf_core` - `v0.11.3`

 - Bump to `0.11.3` due to fixes for `locorda_rdf_mapper_generator`. We use synchronized versioning.

#### `locorda_rdf_mapper` - `v0.11.3`

 - Bump to `0.11.3` due to fixes for `locorda_rdf_mapper_generator`. We use synchronized versioning.

#### `locorda_rdf_mapper_annotations` - `v0.11.3`

 - Bump to `0.11.3` due to fixes for `locorda_rdf_mapper_generator`. We use synchronized versioning.

 - **FIX**(locorda_rdf_mapper_generator): preserve imports for generic type arguments in code generation.

#### `locorda_rdf_mapper_generator` - `v0.11.3`

 - **FIX**(locorda_rdf_mapper_generator): preserve imports for generic type arguments in code generation.

#### `locorda_rdf_terms_core` - `v0.11.3`

 - Bump to `0.11.3` due to fixes for `locorda_rdf_mapper_generator`. We use synchronized versioning.

#### `locorda_rdf_terms_generator` - `v0.11.3`

 - Bump to `0.11.3` due to fixes for `locorda_rdf_mapper_generator`. We use synchronized versioning.

#### `locorda_rdf_xml` - `v0.11.3`

 - Bump to `0.11.3` due to fixes for `locorda_rdf_mapper_generator`. We use synchronized versioning.


## 2026-01-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`locorda_rdf_canonicalization` - `v0.11.2`](#locorda_rdf_canonicalization---v0112)
 - [`locorda_rdf_core` - `v0.11.2`](#locorda_rdf_core---v0112)
 - [`locorda_rdf_mapper` - `v0.11.2`](#locorda_rdf_mapper---v0112)
 - [`locorda_rdf_mapper_annotations` - `v0.11.2`](#locorda_rdf_mapper_annotations---v0112)
 - [`locorda_rdf_mapper_generator` - `v0.11.2`](#locorda_rdf_mapper_generator---v0112)
 - [`locorda_rdf_terms_core` - `v0.11.2`](#locorda_rdf_terms_core---v0112)
 - [`locorda_rdf_terms_generator` - `v0.11.2`](#locorda_rdf_terms_generator---v0112)
 - [`locorda_rdf_xml` - `v0.11.2`](#locorda_rdf_xml---v0112)

---

#### `locorda_rdf_canonicalization` - `v0.11.2`

 - Bump "locorda_rdf_canonicalization" to `0.11.2` to stay in sync with "locorda_rdf_mapper_generator" which has an important bugfix.

#### `locorda_rdf_core` - `v0.11.2`

 - **FIX**(locorda_rdf_mapper_generator): Fixed analyzer support, min version is 8.1 now.

#### `locorda_rdf_mapper` - `v0.11.2`

 - Bump "locorda_rdf_mapper" to `0.11.2`.

#### `locorda_rdf_mapper_annotations` - `v0.11.2`

 - Bump "locorda_rdf_mapper_annotations" to `0.11.2`.

#### `locorda_rdf_mapper_generator` - `v0.11.2`

 - **FIX**(locorda_rdf_mapper_generator): Fixed analyzer support, min version is 8.1 now.

#### `locorda_rdf_terms_core` - `v0.11.2`

 - Bump "locorda_rdf_terms_core" to `0.11.2`.

#### `locorda_rdf_terms_generator` - `v0.11.2`

 - Bump "locorda_rdf_terms_generator" to `0.11.2`.

#### `locorda_rdf_xml` - `v0.11.2`

 - Bump "locorda_rdf_xml" to `0.11.2`.


## 2026-01-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`locorda_rdf_canonicalization` - `v0.11.1`](#locorda_rdf_canonicalization---v0111)
 - [`locorda_rdf_core` - `v0.11.1`](#locorda_rdf_core---v0111)
 - [`locorda_rdf_mapper` - `v0.11.1`](#locorda_rdf_mapper---v0111)
 - [`locorda_rdf_mapper_annotations` - `v0.11.1`](#locorda_rdf_mapper_annotations---v0111)
 - [`locorda_rdf_mapper_generator` - `v0.11.1`](#locorda_rdf_mapper_generator---v0111)
 - [`locorda_rdf_terms_core` - `v0.11.1`](#locorda_rdf_terms_core---v0111)
 - [`locorda_rdf_terms_generator` - `v0.11.1`](#locorda_rdf_terms_generator---v0111)
 - [`locorda_rdf_xml` - `v0.11.1`](#locorda_rdf_xml---v0111)

---

#### `locorda_rdf_canonicalization` - `v0.11.1`

 - **REFACTOR**: use dynamic Dart SDK version for code formatter.
 - **DOCS**: update CHANGELOGs for version 0.11.0 with complete feature documentation.

#### `locorda_rdf_core` - `v0.11.1`

 - **REFACTOR**: use dynamic Dart SDK version for code formatter.
 - **DOCS**: update CHANGELOGs for version 0.11.0 with complete feature documentation.

#### `locorda_rdf_mapper` - `v0.11.1`

 - **DOCS**: replace pubspec.yaml examples with dart pub add commands.

#### `locorda_rdf_mapper_annotations` - `v0.11.1`

 - **DOCS**: remove hardcoded version comment from mapper_annotations README.

#### `locorda_rdf_mapper_generator` - `v0.11.1`

 - **REFACTOR**: use dynamic Dart SDK version for code formatter.
 - **FIX**(mapper_generator): correct file extension from .locorda_rdf_mapper.g.dart to .rdf_mapper.g.dart.
 - **DOCS**: replace pubspec.yaml examples with dart pub add commands.

#### `locorda_rdf_terms_core` - `v0.11.1`

 - **DOCS**: update CHANGELOGs for version 0.11.0 with complete feature documentation.

#### `locorda_rdf_terms_generator` - `v0.11.1`

 - **REFACTOR**: use dynamic Dart SDK version for code formatter.
 - **DOCS**: update CHANGELOGs for version 0.11.0 with complete feature documentation.

#### `locorda_rdf_xml` - `v0.11.1`

 - **DOCS**: replace pubspec.yaml examples with dart pub add commands.
 - **DOCS**: update CHANGELOGs for version 0.11.0 with complete feature documentation.


## 2026-01-17

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`locorda_rdf_canonicalization` - `v0.11.0`](#locorda_rdf_canonicalization---v0110)
 - [`locorda_rdf_core` - `v0.11.0`](#locorda_rdf_core---v0110)
 - [`locorda_rdf_mapper` - `v0.11.0`](#locorda_rdf_mapper---v0110)
 - [`locorda_rdf_mapper_annotations` - `v0.11.0`](#locorda_rdf_mapper_annotations---v0110)
 - [`locorda_rdf_mapper_generator` - `v0.11.0`](#locorda_rdf_mapper_generator---v0110)
 - [`locorda_rdf_terms_core` - `v0.11.0`](#locorda_rdf_terms_core---v0110)
 - [`locorda_rdf_terms_generator` - `v0.11.0`](#locorda_rdf_terms_generator---v0110)
 - [`locorda_rdf_xml` - `v0.11.0`](#locorda_rdf_xml---v0110)

Packages graduated to a stable release (see pre-releases prior to the stable version for changelog entries):

 - `locorda_rdf_canonicalization` - `v0.11.0`
 - `locorda_rdf_core` - `v0.11.0`
 - `locorda_rdf_mapper` - `v0.11.0`
 - `locorda_rdf_mapper_annotations` - `v0.11.0`
 - `locorda_rdf_mapper_generator` - `v0.11.0`
 - `locorda_rdf_terms_core` - `v0.11.0`
 - `locorda_rdf_terms_generator` - `v0.11.0`
 - `locorda_rdf_xml` - `v0.11.0`

---

#### `locorda_rdf_canonicalization` - `v0.11.0`

#### `locorda_rdf_core` - `v0.11.0`

#### `locorda_rdf_mapper` - `v0.11.0`

#### `locorda_rdf_mapper_annotations` - `v0.11.0`

#### `locorda_rdf_mapper_generator` - `v0.11.0`

#### `locorda_rdf_terms_core` - `v0.11.0`

#### `locorda_rdf_terms_generator` - `v0.11.0`

#### `locorda_rdf_xml` - `v0.11.0`


## 2026-01-13

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`locorda_rdf_core` - `v0.11.0-dev`](#locorda_rdf_core---v0110-dev)
 - [`locorda_rdf_canonicalization` - `v0.11.0-dev`](#locorda_rdf_canonicalization---v0110-dev)
 - [`locorda_rdf_mapper` - `v0.11.0-dev`](#locorda_rdf_mapper---v0110-dev)
 - [`locorda_rdf_mapper_annotations` - `v0.11.0-dev`](#locorda_rdf_mapper_annotations---v0110-dev)
 - [`locorda_rdf_mapper_generator` - `v0.11.0-dev`](#locorda_rdf_mapper_generator---v0110-dev)
 - [`locorda_rdf_xml` - `v0.11.0-dev`](#locorda_rdf_xml---v0110-dev)
 - [`locorda_rdf_terms_generator` - `v0.11.0-dev`](#locorda_rdf_terms_generator---v0110-dev)

---

#### `locorda_rdf_core` - `v0.11.0-dev`

 - Version aligned to 0.11.0-dev as part of the Locorda RDF suite. All packages now share synchronized version numbers for simplified dependency management. This release consolidates the monorepo under the locorda/rdf organization in preparation for the upcoming 1.0.0-rc1 release.

#### `locorda_rdf_canonicalization` - `v0.11.0-dev`

 - Version aligned to 0.11.0-dev as part of the Locorda RDF suite. All packages now share synchronized version numbers for simplified dependency management. This release consolidates the monorepo under the locorda/rdf organization in preparation for the upcoming 1.0.0-rc1 release.

#### `locorda_rdf_mapper` - `v0.11.0-dev`

 - Version aligned to 0.11.0-dev as part of the Locorda RDF suite. All packages now share synchronized version numbers for simplified dependency management. This release consolidates the monorepo under the locorda/rdf organization in preparation for the upcoming 1.0.0-rc1 release.

#### `locorda_rdf_mapper_annotations` - `v0.11.0-dev`

 - Version aligned to 0.11.0-dev as part of the Locorda RDF suite. All packages now share synchronized version numbers for simplified dependency management. This release consolidates the monorepo under the locorda/rdf organization in preparation for the upcoming 1.0.0-rc1 release.

#### `locorda_rdf_mapper_generator` - `v0.11.0-dev`

 - Version aligned to 0.11.0-dev as part of the Locorda RDF suite. All packages now share synchronized version numbers for simplified dependency management. This release consolidates the monorepo under the locorda/rdf organization in preparation for the upcoming 1.0.0-rc1 release.

#### `locorda_rdf_xml` - `v0.11.0-dev`

 - Version aligned to 0.11.0-dev as part of the Locorda RDF suite. All packages now share synchronized version numbers for simplified dependency management. This release consolidates the monorepo under the locorda/rdf organization in preparation for the upcoming 1.0.0-rc1 release.

#### `locorda_rdf_terms_generator` - `v0.11.0-dev`

 - Version aligned to 0.11.0-dev as part of the Locorda RDF suite. All packages now share synchronized version numbers for simplified dependency management. This release consolidates the monorepo under the locorda/rdf organization in preparation for the upcoming 1.0.0-rc1 release.

