## 0.11.5

 - Bump "locorda_rdf_terms_core" to `0.11.5`.

## 0.11.4

 - **DOCS**: corrected links to locorda.dev subpages.

## 0.11.3

 - Bump to `0.11.3` due to fixes for `locorda_rdf_mapper_generator`. We use synchronized versioning.

## 0.11.2

 - Bump "locorda_rdf_terms_core" to `0.11.2`.

## 0.11.1

### Changed

- **Maintenance**: Synchronized version release with other Locorda RDF packages

 - **DOCS**: update CHANGELOGs for version 0.11.0 with complete feature documentation.

## 0.11.0

### Changed

- **Vocabulary Scope Reduction**: Package created from kkalass/rdf_vocabulary_to_dart_core and reduced to truly core vocabularies (RDF, RDFS, OWL, XSD) - other vocabularies moved to new locorda_rdf_terms_common package in locorda/rdf-vocabularies monorepo
- **Generated Vocabularies**: Regenerate all vocabulary files with updated generator
- **Monorepo Migration**: Package moved from kkalass/rdf_vocabulary_to_dart_core to locorda/rdf monorepo under new namespace
- **Documentation**: Updated all URLs and references to locorda.dev domain
- **Version Synchronization**: Graduated package to stable 0.11.0 release as part of the Locorda RDF suite


## [0.4.5] - 2025-09-23

### Changed
- **Dependency updates**: Updated locorda_rdf_core to ^0.9.15 and locorda_rdf_terms_generator to ^0.9.2
- **Vocabulary regeneration**: Regenerated all vocabulary files with latest code generation improvements
  - Enhanced code generation with improved type safety and documentation
  - Updated XSD vocabulary asset (xsd.ttl) with latest specifications
  - Refreshed all vocabulary class definitions and universal property mappings
- **Code quality improvements**: Applied latest linting rules and formatting standards

## [0.4.4] - 2025-08-11

### Fixed
- **PIM vocabulary export**: Added missing export for PIM (Personal Information Management) vocabulary in public API
  - PIM vocabulary classes and properties are now properly accessible through the package interface

## [0.4.3] - 2025-07-30

### Added
- **PIM vocabulary support**: Added complete W3C Personal Information Management (PIM) vocabulary (http://www.w3.org/ns/pim/space#)
  - Workspace management classes: `Workspace`, `PrivateWorkspace`, `PublicWorkspace`, `SharedWorkspace`, `PreferencesWorkspace`, `MasterWorkspace`
  - Storage management classes: `Storage`, `PersonalStorage`, `PublicStorage`, `ControlledStorage`
  - Configuration classes: `ConfigurationFile`
  - Universal properties for workspace and storage organization
- Enhanced agent classes (FOAF Agent, Person, Group, Organization) with PIM properties (`masterWorkspace`, `preferencesFile`)
- Enhanced authenticated agent classes (ACL, Contact, DC Terms) with PIM workspace properties

### Changed
- Updated vocabulary source configurations to include PIM namespace integration
- Expanded cross-vocabulary property mappings for better RDF interoperability

## [0.4.2] - 2025-07-24

### Changed
- Updated README documentation with improved formatting and clarity
- Removed codecov reporting from CI pipeline (not applicable for vocabulary constants)

### Fixed
- Corrected documentation formatting errors and inconsistencies

## [0.4.1] - 2025-07-24

### Fixed
- Improved release automation workflow
- Enhanced documentation generation and deployment
- Streamlined publishing process with proper dependency management

## [0.4.0] - 2025-07-24

### Added
- **Initial release** as separate core vocabularies package
- Core RDF vocabularies: RDF, RDFS, OWL, XSD, SKOS, Dublin Core, FOAF, vCard, ACL, LDP, GEO, and more
- Optimized package size (~5MB) for projects not requiring Schema.org vocabularies
- Comprehensive test suite with class-specific access patterns
- Class-specific examples using `FoafPerson`, `VcardAddress`, etc.

### Migration
- **100% API compatibility** with original `rdf_vocabularies` package
- Direct replacement for projects using core vocabularies only
- All import statements remain unchanged when switching from meta-package

## [0.3.1] - 2025-07-24

### Changed
- Updated `locorda_rdf_core` dependency to ^0.9.11
- Ran `dart pub upgrade`

## [0.3.0] - 2025-05-14

### Changed
- Updated `locorda_rdf_core` dependency to ^0.9.0

## [0.2.0] - 2025-05-13

### Changed
- Updated `locorda_rdf_core` dependency from ^0.7.6 to ^0.8.1
- Updated `locorda_rdf_terms_generator` dependency from ^0.7.2 to ^0.8.0
- Improved documentation and examples

### Compatible
- Maintains compatibility with the latest version of `locorda_rdf_core`

## [0.1.0] - 2025-05-09

### Added
- Initial generation of 19 well-known vocabularies
