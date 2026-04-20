## 0.12.2

## 0.12.1

 - **FIX**: added missing test asset.
 - **FIX**: remove locorda_rdf_jsonld dependency and related tests for JSON-LD roundtrip.
 - **DOCS**(locorda_rdf_jelly,locorda_rdf_jsonld): use terms_common vocab constants in examples.
 - **DOCS**(locorda_rdf_jsonld): add RdfCore integration example.
 - **DOCS**(locorda_rdf_jsonld): improve pub.dev scoring.

## 0.12.0

> Note: This release has breaking changes.

 - **FIX**: allow setting of JsonLdDecoderOptions fields on Graph and Async variants.
 - **FIX**(jsonld): rename JsonLdDecoderOptions.base to baseUri.
 - **FEAT**(jsonld): add copyWith method to decoder options for better configurability.
 - **FEAT**(jsonld): add new configuration options for JSON-LD encoding.
 - **BREAKING** **REFACTOR**(jsonld): simplify context resolution to pure provider composition.
 - **BREAKING** **REFACTOR**(jsonld): clean up JsonLdDecoderOptions API surface.
 - **BREAKING** **REFACTOR**(jsonld): replace rdfDirection strings with RdfDirection enum and make useNativeTypes mode-aware.
 - **BREAKING** **REFACTOR**(jsonld): extract JSON-LD codec into locorda_rdf_jsonld package.


 - **Initial release** - JSON-LD codec extracted from `locorda_rdf_core` into its own package.
 - Full JSON-LD 1.1 processing: expansion, compaction, flattening, toRdf, and fromRdf.
 - W3C test suite compliance: 465/467 toRdf, 52/53 fromRdf, 385/385 expand, 244/244 compact, 55/55 flatten.
 - `JsonLdCodec` for RDF dataset encode/decode and `JsonLdGraphCodec` for RDF graph encode/decode.
 - `AsyncJsonLdDecoder` for loading remote `@context` documents.
 - Global convenience variables `jsonld` and `jsonldGraph` for quick access.
 - Optimized compaction with automatic prefix generation.
