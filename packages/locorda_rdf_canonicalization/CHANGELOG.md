## 0.11.8

 - Bump "locorda_rdf_canonicalization" to `0.11.8`.

## 0.11.7

 - Bump "locorda_rdf_canonicalization" to `0.11.7`.

## 0.11.6

 - **FIX**: ensure consistent blank node labels across graphs in TriG and JSON-LD encoders.

## 0.11.5

 - Bump "locorda_rdf_canonicalization" to `0.11.5`.

## 0.11.4

 - **DOCS**: simplify package READMEs by removing extensive cross-references.

## 0.11.3

 - Bump to `0.11.3` due to fixes for `locorda_rdf_mapper_generator`. We use synchronized versioning.

## 0.11.2

 - Bump "locorda_rdf_canonicalization" to `0.11.2` to stay in sync with "locorda_rdf_mapper_generator" which has an important bugfix.

## 0.11.1

 - **DOCS**: update CHANGELOGs for version 0.11.0 with complete feature documentation.

## 0.11.0

### Changed

- **Monorepo Migration**: Package moved from kkalass/rdf_canonicalization to locorda/rdf monorepo under new namespace
- **Documentation**: Updated all URLs and references to locorda.dev domain
- **Version Synchronization**: Graduated package to stable 0.11.0 release as part of the Locorda RDF suite

## 0.11.0-dev

 - Version aligned to 0.11.0-dev as part of the Locorda RDF suite. All packages now share synchronized version numbers for simplified dependency management. This release consolidates the monorepo under the locorda/rdf organization in preparation for the upcoming 1.0.0-rc1 release.

## [0.2.0] - 2025-09-28

### Fixed

- **Test Suite Compliance**: Fixed critical bugs to achieve full compliance with the official W3C RDF canonicalization test suite
- **Specification Alignment**: Re-implemented n-degree hashing algorithm to more closely align with the W3C specification
- **Implementation Structure**: Improved canonicalization implementation with better quad handling and processing

### Changed

- **Code Quality**: Introduced typedefs to improve code readability and maintainability
- **Test Infrastructure**: Added comprehensive official test suite for validation

## [0.1.0] - 2025-09-26

### Added

- **Initial Release**: RDF canonicalization library extracted for specialized canonicalization functionality
- **RDF Canonicalization API**: Complete canonicalization framework for RDF graph isomorphism and semantic equality
  - `CanonicalRdfDataset` and `CanonicalRdfGraph` classes for semantic RDF comparison
  - `canonicalize()`, `canonicalizeGraph()`, `isIsomorphic()`, and `isIsomorphicGraphs()` functions
  - `CanonicalizationOptions` and `CanonicalHashAlgorithm` for configurable canonicalization behavior
  - Support for SHA-256 and SHA-384 hash algorithms
  - Deterministic blank node labeling and canonical N-Quads output
