## 0.11.3

 - Bump to `0.11.3` due to fixes for `locorda_rdf_mapper_generator`. We use synchronized versioning.

## 0.11.2

 - Bump "locorda_rdf_terms_generator" to `0.11.2`.

## 0.11.1

### Changed

- **Dart Formatter**: Refactored vocabulary builder to use dynamic Dart SDK version detection for code formatter
- **Testing**: Updated test vocabulary sources to use dynamic Dart SDK version

 - **REFACTOR**: use dynamic Dart SDK version for code formatter.
 - **DOCS**: update CHANGELOGs for version 0.11.0 with complete feature documentation.

## 0.11.0

### Added

- **Command-Line Tools**: Add `init` and `list` CLI commands to aid with generator configuration
  - `init`: Initialize vocabulary configuration with interactive prompts
  - `list`: Display available vocabularies and their configuration status
- **PackageVocabularySource**: Add new vocabulary source type for loading vocabularies from packages, enabling hierarchical vocabulary configurations with defaults in shared packages
- **Asset Management**: Add xsd.ttl vocabulary asset for XSD datatype definitions
- **Vocabulary Download Caching**: Add optional caching mechanism  for vocabulary downloads to improve build performance and reduce network requests (disabled by default)
- **Improved Logging**: Enhanced logging for vocabularies that were skipped via configuration

### Changed

- **Simplified Configuration**: Configuration no longer requires build.yaml changes - adding `lib/src/vocabularies.json` is sufficient
- **Multiple Vocabulary Files**: Support multiple vocabulary configuration files with automatic root at `package:locorda_rdf_terms_generator/standard_vocabularies.json`
- **Per-Property Override**: Vocabulary files use per-property override system - set only `generate: true` for vocabularies already configured elsewhere, drastically simplifying custom term generation configuration
- **Monorepo Migration**: Package moved from kkalass/rdf_vocabulary_to_dart to locorda/rdf monorepo under new namespace
- **Documentation**: Updated all URLs and references to locorda.dev domain
- **Version Synchronization**: Graduated package to stable 0.11.0 release as part of the Locorda RDF suite

### Fixed

- **Class Generation**: Fix class member name collision in vocabulary term generator

## 0.11.0-dev

 - Version aligned to 0.11.0-dev as part of the Locorda RDF suite. All packages now share synchronized version numbers for simplified dependency management. This release consolidates the monorepo under the locorda/rdf organization in preparation for the upcoming 1.0.0-rc1 release.

## [0.9.4] - 2025-09-29

### Fixed
- Fixed logging output by switching from direct logger usage to build package's log field to ensure log messages are properly displayed during build process
- Added exclusion pattern for IRIs ending with just a slash to prevent generation of invalid vocabulary terms

## [0.9.3] - 2025-09-24

### Changed
- Added test builder so that build_runner for this project generates vocabularies

### Fixed
- Removed redundant `const` from generated classes.

## [0.9.2] - 2025-09-23

### Changed
- **Breaking Change**: Updated to use `const IriTerm()` constructor instead of deprecated `IriTerm.prevalidated()` in generated code and templates
- Updated locorda_rdf_core dependency to ^0.9.15 (from ^0.9.11)
- Updated locorda_rdf_xml dependency to ^0.4.6 (from ^0.4.5)
- Migrated from deprecated `iri` property to `value` property on IriTerm throughout codebase
- Updated all documentation examples to use the new `const IriTerm()` constructor

### Fixed
- All generated vocabulary classes now use the preferred `const IriTerm()` constructor for better performance and consistency with locorda_rdf_core library changes

## [0.9.1] - 2025-07-24

### Changed
- Updated locorda_rdf_core dependency to ^0.9.11
- Updated other dependencies as well

## [0.9.0] - 2025-05-14

### Changed
- Updated locorda_rdf_core dependency to ^0.9.0, which contains breaking changes (only a few small ones though)

## [0.8.0] - 2025-05-13

### Added
- Documentation clarification about platform compatibility: The package shows "no support for web" on pub.dev only because it's a build_runner tool, but the generated code is 100% compatible with all platforms including web, Flutter, and native Dart

### Changed
- Updated locorda_rdf_core dependency to ^0.8.1
- Updated other dependencies to latest versions
- Improved documentation clarity and formatting

### Fixed
- Documentation issue regarding "unresolved doc reference" in the generated documentation

## [0.7.2] - 2025-05-08

### Added
- New vocabulary support: VCard (vCard ontology for contact information)
- New vocabulary support: VS (Vocabulary Status ontology)
- New vocabulary support: XSD (XML Schema Definition)
- Universal properties classes for all vocabularies to simplify access to common properties

### Fixed
- Vocabularies which use https (like https://schema.org) sometimes are referenced via http://. We are now consistently only including those references to the scheme we first saw - e.g. foaf will have http://schema.org references, while schema (which is connected to foaf) will have only https://schema.org.

## [0.7.1] - 2025-05-06

### Added
- Missing dev dependencies

## [0.7.0] - 2025-05-06

### Added
- Initial release of RDF Vocabulary Builder
- Dynamic code generation from RDF vocabulary sources
- Automatic loading of vocabulary files from local filesystem or URLs
- Cross-vocabulary reference resolution and intelligent linking
- Support for configurable input manifest path and output directory
- Automatic generation of vocabulary index file for easy imports
- Custom builder for integration with Dart build_runner system
- Comprehensive documentation and examples
