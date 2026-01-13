## 0.11.0-dev

 - Version aligned to 0.11.0-dev as part of the Locorda RDF suite. All packages now share synchronized version numbers for simplified dependency management. This release consolidates the monorepo under the locorda/rdf organization in preparation for the upcoming 1.0.0-rc1 release.

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


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
