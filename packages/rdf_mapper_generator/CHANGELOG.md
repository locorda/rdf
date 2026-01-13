## 0.11.0-dev

 - Version aligned to 0.11.0-dev as part of the Locorda RDF suite. All packages now share synchronized version numbers for simplified dependency management. This release consolidates the monorepo under the locorda/rdf organization in preparation for the upcoming 1.0.0-rc1 release.

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.10.9] - 2025-10-11

### Added

- **Directional Mappers**: Support for serialize-only and deserialize-only mappers
  - Added `serializeOnly` and `deserializeOnly` named constructors to `@RdfGlobalResource` annotations and a direction parameter to most existing constructors
  of `@RdfGlobalResource`, `@RdfLocalResource`, `@RdfIri` and `@RdfLiteral`
  - Generated mappers implement specific interfaces: `GlobalResourceSerializer`/`GlobalResourceDeserializer`, `LocalResourceSerializer`/`LocalResourceDeserializer`, `IriTermSerializer`/`IriTermDeserializer`, `LiteralTermSerializer`/`LiteralTermDeserializer`
  - Serialize-only mappers omit deserialization logic (no regex parsing, no `fromRdfResource` method)
  - Deserialize-only mappers omit serialization logic (no `toRdfResource` method, IRI strategy optional for global resources)
  - Registry automatically uses correct registration method: `registerSerializer()`, `registerDeserializer()`, or `registerMapper()`

## [0.10.8] - 2025-10-07

### Added

- **Cross-File Mapper Dependencies**: Mapper generator now processes property field types across file boundaries
  - Automatically detects and generates mappers for classes referenced in properties from other files
  - Supports both `@RdfGlobalResource` and `@RdfLocalResource` annotated types used in properties
  - Enables parent-child document patterns where child classes are defined in separate files
  - Internal processing distinguishes between top-level mappers (output to generated file) and nested mappers (used for dependency resolution only)

## [0.10.7] - 2025-10-07

### Added

- **IRI Fragment Template Support**: Added `fragmentTemplate` parameter to `IriStrategy` for IRI fragment handling
  - Allows separate template for URI fragment component (the part after `#`)
  - Both base and fragment templates can use the same IRI part variables
  - Variables unused in one template but used in the other won't generate warnings
  - Generated mappers combine base and fragment templates at runtime

- **IRI Provider Feature**: Added support for `providedAs` parameter in `IriStrategy` constructors
  - Parent resources can now provide their IRI to dependent child resources
  - Child resources can reference parent IRIs in their own IRI templates using context variables
  - Generated mappers automatically pass parent IRI via `() => subject.value` during serialization
  - Enables hierarchical IRI patterns like `{+parentIri}/children/{childId}`
  - Supports complex parent-child relationships with automatic IRI context propagation

## [0.10.6] - 2025-10-07

### Changed

- **BREAKING**: Dropped support for `analyzer` versions below 7.4.0
  - Updated `analyzer` constraint from `>=6.9.0 <8.0.0` to `>=7.4.0 <9.0.0`
  - Switched active analyzer wrapper from v6 to v7_4
  - Disabled v6 analyzer wrapper (now provides stub implementations only)
  - Added v8_2 analyzer wrapper skeleton (prepared for future analyzer 8.x/9.x support)

- **Updated Dependencies**: Upgraded build system and code generation dependencies
  - Updated `build` constraint from `<4.0.0` to `<5.0.0`
  - Updated `analyzer` to 8.2.0
  - Updated `build` to 4.0.1
  - Updated `build_runner` to 2.9.0
  - Updated `dart_style` to 3.1.2

### Fixed

- **Code Generation Improvements**: Enhanced v7_4 analyzer wrapper
  - Filter out synthetic fields, getters, and setters to prevent duplicate property generation
  - Fixed `Code.paramsList` usage in DartObject-to-Code conversion for better readability
  - Added linter suppressions for deprecated APIs to reduce noise in analyzer output

## [0.10.5] - 2025-09-23

### Changed

- **Updated Dependencies**: Updated RDF-related dependencies to latest versions
  - Updated `rdf_mapper` from 0.10.1 to 0.10.2 for improved functionality
  - Updated `rdf_core` from 0.9.14 to 0.9.15 for bug fixes and enhancements

- **Improved IRI Handling**: Enhanced IRI creation and processing throughout generated code
  - Changed from direct `IriTerm()` constructor to `context.createIriTerm()` for better context awareness
  - Updated generated mappers to use `term.value` instead of `term.iri` for consistent IRI access
  - Templates now generate more contextually aware IRI creation and processing

- **Enhanced Code Generation**: Improved generated code quality and consistency
  - Updated processor utilities to use `IriTerm.validated()` for safer IRI creation
  - Fixed IRI field access in processor utils to use correct field name (`value` instead of `iri`)
  - Improved enum mapper generation with consistent IRI handling patterns

- **Documentation Updates**: Updated README and API documentation
  - Updated dependency version examples in README to reflect current stable versions
  - Fixed code examples to use proper `const IriTerm()` constructor calls
  - Updated vocabulary constants to use `const` constructors for better performance

### Fixed

- **IRI Term Processing**: Fixed inconsistent IRI field access patterns
  - Corrected processor utilities to access IRI values using proper field names
  - Fixed enum and resource mappers to use consistent IRI value extraction
  - Resolved issues with IRI template processing and regex matching

## [0.10.4] - 2025-09-17

### Fixed

- **Init File Import Resolution**: Fixed init file builder to properly apply BroaderImports for import resolution
  - Init files now use clean import aliases like `RdfListMapper.new` instead of verbose prefixes like `rlm.RdfListMapper.new`
  - Extended `_InitFileTemplateData` to include BroaderImports from cache files
  - Improved consistency between individual mapper files and init file generation

## [0.10.3] - 2025-09-17

### Fixed

- **Transitive Import Chain Resolution**: Fixed `BroaderImports` to properly handle transitive import dependencies
  - Added recursive processing of imported libraries to resolve import->import->export chains
  - Fixed issue where libraries imported through intermediate dependencies weren't properly mapped to their broader imports
  - Results in cleaner generated code with simplified import aliases (e.g., `RdfListMapper.new` instead of `rlm.RdfListMapper.new`)
  - Added comprehensive test coverage for complex transitive import scenarios including deep dependency chains

## [0.10.2] - 2025-09-16

### Added

- **Annotation Subclassing Support**: Added comprehensive support for inheritance of RDF annotations
  - Classes can now inherit RDF mappings from their parent classes
  - Proper handling of annotation inheritance chains for complex class hierarchies
  - Validation and error handling for annotation inheritance conflicts
  - Enhanced mapper generation to support inherited annotation patterns

- **Named Factory Constructor Support**: Added full support for named factory constructors in RDF mapping
  - Enhanced analyzer wrapper models (both v6 and v7.4) to detect and handle named constructors
  - Updated mapper model builder to properly configure named factory constructors
  - Generated mappers now support classes using named factory constructors for instantiation
  - Improved constructor resolution and parameter handling in code generation

### Changed

- **Enhanced Mapper Model Building**: Improved internal mapper model building infrastructure
  - Updated `IriModelBuilderSupport` and `MapperModel` classes for better constructor handling
  - Enhanced parameter resolution and type inference for complex constructor scenarios
  - Better integration between analyzer wrapper and mapper generation systems

- **Updated Dependencies**: Updated to latest versions of RDF-related dependencies
  - Updated `rdf_mapper_annotations` to version 0.10.2 for enhanced annotation features
  - Refreshed other RDF ecosystem dependencies for improved compatibility and features

### Fixed

- **Constructor Resolution**: Fixed issues with constructor detection and parameter mapping
  - Resolved problems with named factory constructor parameter resolution
  - Improved handling of complex constructor scenarios in inheritance hierarchies
  - Fixed edge cases in constructor validation and error reporting

- **Code Generation Consistency**: Improved consistency in generated mapper code
  - Fixed formatting and structure issues in generated test files
  - Enhanced code generation for complex inheritance and constructor scenarios
  - Better handling of import dependencies in generated code

## [0.10.1] - 2025-08-13

### Added

- **Contextual Property Mapping Improvements**: Enhanced support for context-dependent property serialization/deserialization
  - Refactored `ContextualMapping` to use proper `SerializationProvider` dependencies instead of named providers
  - Improved dependency injection for contextual mappers in generated code
  - Added support for `@RdfUnmappedTriples(globalUnmapped: true)` to capture all unmapped triples globally

- **Raw Type Support**: Added `raw` parameter to type code generation for better mapper instantiation
  - New `raw` parameter in `DartType.toCode()` method allows getting raw class names without generic parameters
  - Enables proper mapper constructor calls with raw class types while preserving generic type information
  - Implemented across all analyzer wrapper versions (v6 and v7.4)

### Changed

- **Code Generation Improvements**: Enhanced template system and dependency management
  - Removed deprecated `Code.constructor()` factory method in favor of more flexible `Code.type()` and `Code.literal()` combination
  - Improved mapper dependency resolution with better parameter naming (configurable suffix support)
  - Enhanced contextual mapping code generation with proper `SerializationProvider` integration
  - Simplified constructor code generation using `Code.paramsList()` for better readability

- **Mapper Reference Handling**: Improved mapper reference tracking and instantiation
  - Enhanced `MapperRefInfo` to track both full type and raw type separately
  - Better handling of generic type parameters in mapper references
  - Improved mapper dependency default value generation

- **Test Infrastructure Updates**: Enhanced testing capabilities and examples
  - Updated document example to demonstrate contextual mapping with `IriRelativeSerializationProvider`
  - Improved test fixtures with better generic type handling
  - Enhanced validation test infrastructure with proper project setup

### Fixed

- **Constructor Code Generation**: Fixed issues with const constructor and parameter handling
  - Corrected const constructor generation to use proper `Code.literal()` and `Code.type()` combination
  - Fixed parameter list generation for cleaner, more readable generated code
  - Resolved issues with import alias handling in constructor calls

- **Dependency Management**: Improved dependency resolution and parameter handling
  - Fixed contextual mapping dependency generation with proper `SerializationProvider` types
  - Corrected mapper dependency suffix handling for better naming consistency
  - Improved error handling for unresolved mapper dependencies

## [0.10.0] - 2025-07-25

### Changed

- **Breaking Change**: Updated `rdf_vocabularies` dependency to use the new multipackage structure:
  - Replaced `rdf_vocabularies: ^0.3.0` with `rdf_vocabularies_core: ^0.4.1` and `rdf_vocabularies_schema: ^0.4.1`
  - Updated all import statements throughout the codebase to use the new package structure
  - `import 'package:rdf_vocabularies/rdf.dart'` → `import 'package:rdf_vocabularies_core/rdf.dart'`
  - `import 'package:rdf_vocabularies/xsd.dart'` → `import 'package:rdf_vocabularies_core/xsd.dart'`
  - `import 'package:rdf_vocabularies/schema.dart'` → `import 'package:rdf_vocabularies_schema/schema.dart'`
  - And similar updates for other vocabulary imports (`foaf`, `vcard`, etc.)

## [0.3.3] - 2025-07-24

### Added

- Automated dependency management with Dependabot configuration for weekly updates

### Changed

- **BREAKING**: Updated `build` dependency from 2.5.4 to 3.0.0 for improved build performance and compatibility, but continue to support older build versions
- Updated dependency versions:
  - `dart_style` from 3.1.0 to 3.1.1
  - `analyzer` from 7.7.0 to 7.7.1  
  - `rdf_core` from 0.9.7 to 0.9.11
  - `rdf_mapper` from 0.9.2 to 0.9.3
  - `rdf_mapper_annotations` from 0.3.1 to 0.3.2
  - Various test dependencies updated to latest versions

### Fixed

- Compatibility with `build` package 3.0.0 by adding explicit type cast in analyzer wrapper
- Code cleanup in analyzer v7.4 wrapper by removing unused exports

## [0.3.2] - 2025-07-18

### Added

- Added `hasInitializer` and `isSettable` properties to field analysis for better code generation control
- Added comprehensive collection mapping test coverage including all collection types and edge cases

### Changed

- Refactored internal model class names for improved clarity:
  - `FieldInfo` → `PropertyInfo`
  - `PropertyInfo` → `RdfPropertyInfo`
  - `RdfPropertyInfo` → `RdfPropertyAnnotationInfo`
- Renamed collection type detection methods for consistency:
  - `isList` → `isCoreList`
  - `isMap` → `isCoreMap`
  - `isSet` → `isCoreSet`
  - `isCollection` → `isCoreCollection`
- Updated internal property structures to use `properties` instead of `fields` for consistency with RDF terminology

### Fixed

- Improved analyzer wrapper to properly detect field initializers and settability
- Removed warning about missing constructor parameter during build_runner that happened for initialized final fields and getters without accompanying setters
- Detection if something is a collection sometimes did not work, itemType override thus failed for custom collection types
- important constants like rdfList, rdfSeq etc. were not documented at all

## [0.3.1] - 2025-07-17

### Added

- Added additional test cases for collection property annotation mapper generating.

### Fixed

- Fixed collection item mapper type generation where item mappers were incorrectly typed for the collection type instead of the individual item type (e.g., `IriTermMapper<List<String>>` now correctly generates as `IriTermMapper<String>`)
- Fixed parameter naming inconsistency in collection mappers where custom serializer/deserializer parameters are now correctly named `itemSerializer`/`itemDeserializer` instead of `serializer`/`deserializer` when dealing with collection item mappers
- Improved documentation formatting in generated IRI mappers by properly wrapping class names in backticks

## [0.3.0] - 2025-07-17

### Changed

- Support powerfull collection mapping
- **BREAKING**: Updated `toRdfResource` return type from `(RdfSubject, List<Triple>)` to `(RdfSubject, Iterable<Triple>)` for improved performance and flexibility
- **BREAKING**: Standardized custom mapper parameter names in generated code:
  - `iriTermDeserializer`/`iriTermSerializer` → `deserializer`/`serializer`
  - `literalTermDeserializer`/`literalTermSerializer` → `deserializer`/`serializer` 
  - `globalResourceDeserializer`/`resourceSerializer` → `deserializer`/`serializer`
  - `localResourceDeserializer`/`resourceSerializer` → `deserializer`/`serializer`
- **BREAKING**: Updated `@RdfLiteral.custom` method signatures to use `LiteralContent` instead of `LiteralTerm`:
  - `toLiteralTermMethod` and `fromLiteralTermMethod` now work with `LiteralContent` objects
  - Methods are automatically wrapped with proper datatype handling in generated code
- Added `datatype` field to generated `LiteralTermMapper` and `IriTermMapper` implementations for better type safety

### Fixed

- Improved datatype handling in custom literal mappers with explicit datatype support
- Enhanced method call generation for custom literal conversion methods

## [0.2.4] - 2025-07-10

### Added

- **Lossless Mapping Support**: Added complete support for `@RdfUnmappedTriples` annotation to enable lossless round-trip RDF mapping
  - Fields annotated with `@RdfUnmappedTriples` capture all triples not explicitly mapped to other class properties
  - Generated code includes `reader.getUnmapped<T>()` calls for deserialization and `builder.addUnmapped(field)` calls for serialization
  - Supports custom types with registered `UnmappedTriplesMapper<T>` implementations
  - `RdfGraph` type has built-in support and is recommended for most use cases
- **Enhanced Validation**: Added comprehensive validation for `@RdfUnmappedTriples` usage
  - Error when multiple fields per class are annotated with `@RdfUnmappedTriples`
  - Warning when non-`RdfGraph` types are used with clear guidance about custom mapper registration
- **Improved Developer Experience**: Enhanced warning and error message formatting
  - Professional, structured warning messages with bullet points for better readability
  - Clear, actionable guidance for resolving validation issues
  - Improved build-time feedback for annotation usage problems

### Fixed

- Fixed logging configuration for proper warning display during build_runner execution
- Ensured `getUnmapped()` calls are always executed last during deserialization for correct lossless mapping behavior

## [0.2.3] - 2025-07-04

### Fixed

- Corrected example code in README.md

## [0.2.2] - 2025-07-04

### Added

- Professional homepage at doc/index.html with modern design and feature highlights
- `ignore_for_file: unused_field` directive to generated files to suppress analyzer warnings

### Changed

- Major rewrite and modernization of README.md with clearer feature descriptions
- Improved documentation accuracy and removed overstated claims
- Enhanced onboarding experience with better "Try It" section
- Restructured documentation to be more compelling and professional for new users
- Cleaned up test fixtures for better maintainability


## [0.2.1] - 2025-07-04

### Fixed

- Fixed Stack Overflow error caused by infinite recursion in BroaderImports when processing circular library exports
- Added cycle detection to prevent infinite loops in library import/export resolution
- Fixed regex pattern rendering bug where regex patterns were not properly escaped as raw strings in generated code

## [0.2.0] - 2025-07-04

### Changed

- Expanded analyzer package version support to include older versions (>6.9.0 <8.0.0)
- Added analyzer API wrapper layer to ensure compatibility across analyzer versions
- Updated dart_style dependency constraints to support broader version range

### Fixed

- Compatibility issues with analyzer package versions 6.x
- Build compatibility with projects using older analyzer versions

## [0.1.0] - 2025-07-03

### Added

- Full support for all annotations from rdf_mapper_annotations 0.2.2:
  - Resource annotations (@RdfGlobalResource, @RdfLocalResource)
  - IRI processing (@RdfIri, @RdfIriPart) with template support
  - Literal processing (@RdfLiteral, @RdfValue)
  - Property annotations (@RdfProperty) with various mapping options
  - Collection support (Lists, Sets, Maps)
  - Map entry processing (@RdfMapEntry, @RdfMapKey, @RdfMapValue)
  - Enumeration support with @RdfEnumValue
  - Language tag support via @RdfLanguageTag
- Dynamic IRI resolution with template variables and context variables
- Provider-based IRI strategies for flexible URI creation
- Type-safe mapper generation for global and local resources
- Automatic registration of generated mappers
- Custom mapper integration (named, by type, and by instance)
- Smart type inference for RDF annotations with `registerGlobally: false` option
- Validation and comprehensive error messages
- Complete serialization and deserialization between Dart objects and RDF triples
- Support for complex object graphs
- Mustache templates for code generation
- Regular expression-based IRI parsing and creation
- Auto-generated mapper documentation
- Nested resource serialization and deserialization

### Engineering

- Multi-layered architecture with model and resolved model layers
- Structured code generation system with separate processors for different annotation types
- Clean separation between parsing, analysis, and code generation
- Comprehensive test suite covering all generated mapper scenarios
- Advanced type inference system for property resolution
- Modular template system for code generation
- Performance optimizations for working with complex object graphs
- Code abstraction for better maintainability
