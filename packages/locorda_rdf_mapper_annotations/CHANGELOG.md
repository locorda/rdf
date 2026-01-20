## 0.11.3

 - Bump to `0.11.3` due to fixes for `locorda_rdf_mapper_generator`. We use synchronized versioning.

 - **FIX**(locorda_rdf_mapper_generator): preserve imports for generic type arguments in code generation.

## 0.11.2

 - Bump "locorda_rdf_mapper_annotations" to `0.11.2`.

## 0.11.1

### Documentation

- **API Documentation**: Replaced all references from deprecated `IriTerm.iri` to `IriTerm.value` throughout documentation
  - Updated README examples
  - Updated example code in document_example.dart
  - Updated API documentation in annotations.dart, contextual_mapping.dart, property.dart, and iri.dart
- **Installation**: Removed hardcoded version comments to prevent documentation staleness
- **CLAUDE.md**: Updated with monorepo-specific testing instructions

## 0.11.0

 - Graduate package to a stable release. See pre-releases prior to this version for changelog entries.

## 0.11.0-dev

 - Version aligned to 0.11.0-dev as part of the Locorda RDF suite. All packages now share synchronized version numbers for simplified dependency management. This release consolidates the monorepo under the locorda/rdf organization in preparation for the upcoming 1.0.0-rc1 release.

## [0.10.4] - 2025-10-11

### Added
- **Directional Mapper Support**: New `MapperDirection` enum enables control over whether mappers handle serialization, deserialization, or both
- **Deserialize-only constructor**: New `@RdfGlobalResource.deserializeOnly(classIri)` constructor for resources that only need to be read from RDF. IRI strategy is optional since it's not needed for deserialization.
- **Serialize-only constructor**: New `@RdfGlobalResource.serializeOnly(classIri, iriStrategy)` constructor for resources that only need to be written to RDF
- **Direction parameter for custom mappers**: All custom mapper constructors (`.namedMapper()`, `.mapper()`, `.mapperInstance()`) now support an optional `direction` parameter (defaults to `MapperDirection.both`)

### Enhanced
- **Hybrid approach for mapper direction**: Combines specialized constructors (`.deserializeOnly()`, `.serializeOnly()`) for standard cases with enum-based control for custom mappers, optimizing both type safety and flexibility
- **Type safety preserved**: Standard constructor maintains required `IriStrategy` parameter, ensuring type safety for the common bidirectional mapping case

## [0.10.3] - 2025-10-07

### Added
- **Parent IRI Provider**: New `providedAs` parameter on `IriStrategy` enables resources to provide their own IRI to dependent mappers. This facilitates hierarchical IRI patterns where child resources need to reference their parent's IRI in their own IRI construction.
- **Fragment-based IRI constructors**: New `withFragment` constructors for `IriStrategy`, `IriMapping`, and `RdfIri` enable creating IRIs by appending a fragment identifier to a base IRI. Works with any URI scheme (hierarchical like `https://` or non-hierarchical like `tag:`), making it ideal for resources within the same document that are distinguished by fragments.
- **Complete context variable documentation**: Added comprehensive documentation across all relevant annotations (`IriStrategy`, `IriMapping`, `RdfIri`, `@RdfProvides`, `@RdfGlobalResource`, `@RdfProperty`) explaining all three methods of providing context variables: global providers, `@RdfProvides`, and the new `providedAs` parameter.
- **README examples**: Added practical examples demonstrating all three context variable resolution approaches with real-world use cases.

### Enhanced
- **IriStrategy constructors**: All `IriStrategy` constructors now support the optional `providedAs` parameter (default constructor uses positional parameter, named constructors use named parameter, `namedFactory` uses positional parameter for compatibility).
- **Context variable resolution**: Extended local resolution to include parent resource IRIs alongside existing `@RdfProvides` annotations and global providers.

### Changed
- Replaced deprecated `IriTerm.prevalidated()` constructor with standard `IriTerm()` constructor throughout codebase
- Updated examples and documentation to use `context.createIriTerm()` for creating IRI terms from strings in mapper implementations
- Updated to access IRI value via `term.value` property instead of deprecated `term.iri` property

## [0.10.2] - 2025-09-15

### Added
- **Factory constructor support**: New `IriStrategy.namedFactory()` and `IriMapping.namedFactory()` constructors enable factory functions with generic type parameters for type-safe coordination between mappers
- **Enhanced factory pattern**: Factory functions can receive configuration instances for coordinated IRI generation, particularly useful for pod-based URI coordination use cases
- **Custom annotation documentation**: Added comprehensive documentation for creating domain-specific annotations by subclassing existing annotation classes like `RdfGlobalResource`, with practical examples including const requirements and limitations

### Enhanced
- **Improved base mapping infrastructure**: Enhanced `BaseMapping` class to support factory pattern with better type safety and configuration passing
- **Extended IRI strategy examples**: Updated `example/example_iri_strategies.dart` with pod-coordinated IRI generation demonstrations
- **Better development tooling**: Updated README with clearer guidance on custom annotation creation via subclassing

### Changed
- **Dependency updates**: Updated `build_runner` to `^2.8.0` and `mockito` to `^5.5.1` for latest tooling improvements
- **Enhanced testing**: Added comprehensive tests for new factory constructors and coordination patterns

## [0.10.1] - 2025-08-13

### Added
- **Contextual Property Mapping**: New `contextual` parameter for `@RdfProperty` annotation enables properties to access parent object, parent subject, and full context during RDF operations
- **ContextualMapping class**: Configuration class for contextual property mapping with `ContextualMapping.namedProvider()` factory method
- Enables complex scenarios like computing dependent object IRIs based on parent properties or creating nested resources that reference their container
- **Global Unmapped Triples**: New `globalUnmapped` parameter for `@RdfUnmappedTriples` annotation enables collecting unmapped triples from entire graph instead of just current subject. Designed for top-level document classes like Solid WebID/Profile Documents.
- **Document-level lossless mapping example**: Added `example/document_example.dart` demonstrating global unmapped triples preservation for complete document round-trip fidelity

### Changed
- **ContextualMapping API refinement**: Unified mapping class hierarchy by extending `BaseMapping<SerializationProvider>` for consistent constructor patterns and type safety
- **Enhanced `BaseMapping` generics**: Removed `Mapper` constraint from generic parameter to support broader range of mapping configurations including `SerializationProvider`
- **Improved documentation**: Enhanced `@RdfUnmappedTriples` documentation with performance considerations, usage guidelines, and clear distinction between subject-scoped and global unmapped triples
- **Updated dependencies**: Upgraded `locorda_rdf_terms_core` and `locorda_rdf_terms_schema` to version `^0.4.4` and switched to local path dependency for `locorda_rdf_mapper` for development

### Enhanced
- **Comprehensive lossless mapping guide**: Expanded README documentation with detailed comparison of different unmapped triples strategies and when to use each approach
- **Better example organization**: Enhanced documentation structure with clear sections for subject-scoped vs global unmapped triples with practical use cases

## [0.10.0] - 2025-07-25

### Changed

- **Breaking Change**: Updated `rdf_vocabularies` dependency to use the new multipackage structure:
  - Replaced `rdf_vocabularies: ^0.3.0` with `locorda_rdf_terms_core: ^0.4.1` and `locorda_rdf_terms_schema: ^0.4.1`
  - Updated all import statements throughout the codebase to use the new package structure
  - `import 'package:rdf_vocabularies/rdf.dart'` → `import 'package:locorda_rdf_terms_core/rdf.dart'`
  - `import 'package:rdf_vocabularies/xsd.dart'` → `import 'package:locorda_rdf_terms_core/xsd.dart'`
  - `import 'package:rdf_vocabularies/schema.dart'` → `import 'package:locorda_rdf_terms_schema/schema.dart'`
  - And similar updates for other vocabulary imports (`foaf`, `vcard`, etc.)

## [0.3.2] - 2025-07-24

### Changed
- **Dependency updates**: Updated to locorda_rdf_core ^0.9.11 and locorda_rdf_mapper ^0.9.3 for latest bug fixes and improvements
- **Documentation formatting**: Improved consistency in API documentation with proper formatting of generic type references (`List<T>`, `Set<T>`)
- **Code quality**: Enhanced formatting and readability in tool scripts and examples

## [0.3.1] - 2025-07-18

### Added
- **Comprehensive collection mapping documentation**: Added extensive documentation with examples for all collection mapping constants (`rdfList`, `rdfSeq`, `rdfBag`, `rdfAlt`, `unorderedItems`, `unorderedItemsList`, `unorderedItemsSet`)
- **Public collection constants library**: New `collection_constants.dart` library file for convenient access to collection mapping constants
- **Enhanced IRI mapping documentation**: Added detailed documentation for collection item IRI mapping with template placeholder requirements and common usage patterns

### Enhanced
- **Improved API documentation**: Complete documentation overhaul for collection mapping constants with RDF structure examples, use cases, and underlying mapper information
- **Better example quality**: Fixed template placeholder names in examples to match property names correctly
- **Documentation coverage**: Added comprehensive library-level documentation explaining when and how to use each collection mapping strategy

## [0.3.0] - 2025-07-17

### Added
- **New `LiteralContent` class**: Added helper class for building RDF literals with simplified datatype and language handling
- **Enhanced datatype support**: `@RdfLiteral.custom` now accepts optional `datatype` parameter for consistent datatype handling
- **Collection item type specification**: Added `itemType` parameter to `@RdfProperty` for explicit item type control in custom collections
- **Global collection mapping constants**: Added convenient constants (`rdfList`, `rdfSeq`, `rdfBag`, `rdfAlt`, `unorderedItems`, `unorderedItemsList`, `unorderedItemsSet`) for common collection mapping strategies

### Changed
- **BREAKING**: `@RdfLiteral.custom` methods now use `LiteralContent` instead of `LiteralTerm` for parameters and return types
- **BREAKING**: `@RdfProperty.collection` parameter changed from `RdfCollectionType` enum to `CollectionMapping?` for much more flexibility and better API consistency
- **BREAKING**: Removed `RdfCollectionType` enum - collection behavior now specified through `CollectionMapping` class
- **Enhanced collection mapping defaults**: Clarified that collections default to `CollectionMapping.auto()` behavior (multiple triples) unlike other mapping properties which default to registry lookup
- Adjusted to API changes in locorda_rdf_mapper (Iterable<Triple>, datatype property in LiteralTermMapper etc.)
- Updated examples and documentation to use new global collection constants

### Removed
- **BREAKING**: `RdfCollectionType` enum - replaced with `CollectionMapping` class for collection mapper specification

## [0.2.4] - 2025-07-10

### Added
- **Lossless mapping support**: Added `@RdfUnmappedTriples` annotation for capturing unmapped RDF triples during deserialization
- **Enhanced examples**: Updated `catch_all.dart` example to demonstrate both `@RdfUnmappedTriples` and `RdfGraph` usage for comprehensive RDF data handling
- **Comprehensive documentation**: Added detailed "Lossless RDF Mapping" section to README with object-level and document-level mapping examples
- **Feature showcase**: Updated project documentation to highlight lossless mapping capabilities

### Enhanced
- **Improved example quality**: Enhanced `catch_all.dart` with realistic Person class and full round-trip usage demonstration
- **Better documentation coverage**: Added usage examples for `encodeObjectLossless`/`decodeObjectLossless` methods for complete document preservation
- **Feature visibility**: Added lossless mapping feature card to project documentation homepage

## [0.2.3] - 2025-07-04

### Changed

- Improved example code quality and readability
- Renamed example file to ensure better discoverability on pub.dev
- Ensured all source files are properly formatted according to Dart conventions

## [0.2.2] - 2025-07-04

### Changed

- Updated README to reflect that the generator package is released and ready for use


## [0.2.1] - 2025-06-25

### Added
- **Comprehensive enum support**: Added `@RdfEnumValue` annotation for customizing individual enum constant serialization values
- **Enhanced `@RdfLiteral` for enums**: Extended `@RdfLiteral` annotation to support direct application to enums with automatic mapper generation
- **Enhanced `@RdfIri` for enums**: Extended `@RdfIri` annotation to support enum mapping with IRI templates and `{value}` placeholder substitution
- **Property-level enum overrides**: Enum properties can now use all existing property-level mapping options (custom mappers, language tags, datatypes)
- **Validation and documentation**: Added comprehensive validation rules, error handling documentation, and best practices for enum mapping
- **Examples and guides**: Added `example/enum_mapping_simple.dart` and `doc/enum_mapping_guide.md` with complete usage examples

### Enhanced
- **Improved documentation**: Updated main library documentation with enum usage examples and integration patterns
- **Extended property mappings**: Enhanced `LiteralMapping` and `IriMapping` classes with enum-specific documentation and examples

## [0.2.0] - 2025-06-20

### Changed
- **BREAKING**: Updated dependency to locorda_rdf_mapper ^0.8.0 and adjusted to breaking API changes in the underlying mapper library
- **BREAKING**: Fixed design issues in `@RdfLiteral.custom()` constructor - methods now work with `LiteralTerm` instead of `String` so that they can me used for any LiteralTerm (de-)serialization (including language tags). 
- Updated IRI template semantics to support `{+variable}` syntax for context variables that may contain URI-reserved characters (prevents percent-encoding)
- Improved documentation for IRI template variables and context variable handling

### Fixed
- Corrected parameter order and nullability in `@RdfLiteral.custom()` constructor
- Updated examples to work with the new locorda_rdf_mapper 0.8.0 API

## [0.1.0] - 2025-05-23

### Added

- Initial Release - Added all annotations and some examples
- Comprehensive documentation for all annotation classes
- Quick start example in README.md