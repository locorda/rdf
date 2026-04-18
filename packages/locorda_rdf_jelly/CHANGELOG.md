## 0.12.1

 - **FIX**(locorda_rdf_jelly): use correct assertor URL and omit milliseconds in EARL report dates.
 - **FEAT**(jelly): add Jelly-RDF conformance EARL report generator.
 - **DOCS**(locorda_rdf_jelly,locorda_rdf_jsonld): use terms_common vocab constants in examples.
 - **DOCS**(locorda_rdf_jelly): add examples for pub.dev.

## 0.12.0

 - Bump "locorda_rdf_jelly" to `0.12.0`.

## 0.11.12

 - Bump "locorda_rdf_jelly" to `0.11.12`.

## 0.11.11

 - **REFACTOR**(jelly): replace ensure() with ensureAndGetId() for single-lookup table operations.
 - **PERF**(jelly): add JellyRawFrameWriter and raw encode hotpath.
 - **PERF**(jelly): eliminate GeneratedMessage allocations via raw frame parser.
 - **PERF**(jelly): eliminate super-linear decode overhead.
 - **PERF**(jelly): incremental frame serialisation eliminates super-linear scaling.
 - **PERF**(jelly): cache IRI splits and skip reensure when no eviction.
 - **PERF**(jelly): optimise encoder hot path — O(1) eviction + zero per-triple allocs.
 - **FIX**(jelly): fix frame buffer reset and dataset default stream type.
 - **DOCS**: documented reason for jelly spead.
 - **DOCS**: update READMEs and add Jelly package docs.

## 0.11.10

 - **FEAT**(jelly): add Jelly codec package and core binary registry support.

## 0.11.9

- Initial implementation of Jelly RDF binary codec.
