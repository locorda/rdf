
 - **Initial release** - JSON-LD codec extracted from `locorda_rdf_core` into its own package.
 - Full JSON-LD 1.1 processing: expansion, compaction, flattening, toRdf, and fromRdf.
 - W3C test suite compliance: 465/467 toRdf, 52/53 fromRdf, 385/385 expand, 244/244 compact, 55/55 flatten.
 - `JsonLdCodec` for RDF dataset encode/decode and `JsonLdGraphCodec` for RDF graph encode/decode.
 - `AsyncJsonLdDecoder` for loading remote `@context` documents.
 - Global convenience variables `jsonld` and `jsonldGraph` for quick access.
 - Optimized compaction with automatic prefix generation.
