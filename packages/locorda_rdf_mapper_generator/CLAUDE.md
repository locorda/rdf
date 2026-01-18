# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Build and Code Generation
```bash
# Generate RDF mappers from annotations (primary command)
dart run build_runner build

# Watch mode for continuous code generation during development
dart run build_runner watch

# Clean generated files
dart run build_runner clean
```

### Testing
```bash
# Run all tests
dart test

# Run tests with coverage (generates HTML report if lcov installed)
dart tool/run_tests.dart

# Run specific test file
dart test test/specific_test.dart

# Run tests matching a pattern
dart test --name="pattern"
```

### Code Quality
```bash
# Run static analysis
dart analyze

# Format code
dart format .
```

## Architecture Overview

This is a Dart code generator that creates type-safe RDF mappers from annotated classes. The generator follows a three-phase build pipeline:

### Three-Phase Build System

1. **Cache Builder** (`lib/cache_builder.dart`)
   - Analyzes `.dart` files for RDF annotations
   - Generates `.rdf_mapper.cache.json` files containing template data
   - Uses analyzer wrapper for cross-version compatibility with Dart analyzer

2. **Source Builder** (`lib/source_builder.dart`) 
   - Processes `.rdf_mapper.cache.json` files
   - Generates `.rdf_mapper.g.dart` files with actual mapper code
   - Uses Mustache templates for code generation

3. **Init File Builder** (`lib/init_file_builder.dart`)
   - Consolidates all mappers into initialization files
   - Generates `init_rdf_mapper.g.dart` and `init_test_rdf_mapper.g.dart`
   - Provides single entry point for mapper registration

### Core Components

**Processors** (`lib/src/processors/`)
- `resource_processor.dart` - Handles `@RdfGlobalResource` and `@RdfLocalResource` annotations
- `property_processor.dart` - Processes `@RdfProperty` annotations on class fields
- `enum_processor.dart` - Manages enum mappings with `@RdfIri` and `@RdfLiteral`
- `literal_processor.dart` - Handles custom literal types with `@RdfLiteral`
- `iri_processor.dart` - Processes IRI-based mappings

**Mappers** (`lib/src/mappers/`)
- `mapper_model_builder.dart` - Builds internal representation of mappers
- `resolved_mapper_model.dart` - Contains resolved mapper definitions
- Template data structures for code generation

**Templates** (`lib/src/templates/`)
- Mustache templates for generating different mapper types
- `template_renderer.dart` - Renders templates with data
- Code generation utilities

**Analyzer Wrapper** (`lib/src/analyzer_wrapper/`)
- Abstracts different analyzer versions (v6, v7.4)
- Provides unified interface for AST analysis
- Handles version compatibility issues

### Key Files for Understanding

- `lib/builder_helper.dart` - Main orchestration logic
- `lib/src/templates/template_data_builder.dart` - Converts analyzed classes to template data
- `build.yaml` - Build system configuration with three builders
- Test fixtures in `test/fixtures/` contain comprehensive examples of all annotation patterns

The generator supports complex RDF mapping scenarios including IRI templates, custom collections, enum mappings, lossless round-trip mapping, multi-language literals, and generic type parameters.

## Testing Standards

This project follows a comprehensive testing approach that ensures code generation quality at multiple levels:

### Test File Organization

For each feature area, tests should be organized as follows:

1. **Model Files** (`test/fixtures/feature_test_models.dart`)
   - Contains test classes with RDF annotations
   - Should cover both valid and edge cases for the feature
   - Gets automatically built to generate `.rdf_mapper.g.dart` companion files
   - Used by both processor and mapper tests

2. **Processor Tests** (`test/processors/feature_processor_test.dart`)
   - Tests the **processing logic** that analyzes classes and extracts information
   - Uses `ResourceProcessor.processClass()` or similar to test annotation processing
   - Tests validation logic and error cases
   - Should test type parameter extraction, validation rules, etc.
   - Example: `global_resource_processor_test.dart`, `generic_resource_processor_test.dart`

3. **Mapper Tests** (`test/mappers/feature_mappers_test.dart`)
   - Tests the **generated mappers** themselves
   - Imports both the model file and its generated `.rdf_mapper.g.dart`
   - Tests serialization/deserialization functionality
   - Tests that the generated code compiles and works correctly
   - **MUST follow the high-quality pattern from `global_resource_processor_mappers_test.dart`**
   - Example: `global_resource_processor_mappers_test.dart`, `valid_generic_mappers_test.dart`

### Additional Test Types

4. **Integration Tests** (`test/integration/feature_integration_test.dart`)
   - Tests end-to-end build process
   - Verifies that `dart run build_runner build` succeeds
   - Tests that generated files exist and contain expected content
   - Example: `generic_types_integration_test.dart`

5. **Validation Tests** (`test/validation/feature_validation_test.dart`)
   - Tests validation logic in isolation
   - Can use string-based testing with `buildTemplateDataFromString()`
   - Tests error scenarios and validation exceptions
   - Example: `generic_validation_test.dart`

### Example Pattern

For a feature called "MyFeature":
- `test/fixtures/my_feature_test_models.dart` - Model classes
- `test/processors/my_feature_processor_test.dart` - Processing logic tests  
- `test/mappers/my_feature_mappers_test.dart` - Generated mapper functionality tests
- `test/integration/my_feature_integration_test.dart` - End-to-end build tests (optional)
- `test/validation/my_feature_validation_test.dart` - Validation logic tests (optional)

This pattern ensures comprehensive coverage from low-level processing through generated code functionality to full integration testing.

### High-Quality Mapper Testing Standards

Mapper tests should follow the comprehensive pattern established in `global_resource_processor_mappers_test.dart`, which provides superior coverage compared to simpler approaches:

#### Required Test Structure

1. **Full Round-Trip Testing**
   - Create realistic model instances with comprehensive data
   - Test serialization to RDF graph/turtle
   - Test deserialization back to objects
   - Verify all properties are preserved exactly

2. **Registration Behavior Verification**
   - Explicitly test whether classes are registered globally vs locally
   - Use `mapper.registry.hasGlobalResourceDeserializerFor<T>()` to verify registration state
   - Test that `registerGlobally: false` classes throw exceptions without explicit registration
   - Test that `registerGlobally: true` classes work without explicit registration

3. **Explicit Mapper Registration Testing**
   - For classes with `registerGlobally: false`, test both serialization and deserialization with explicit registration using the `register:` parameter
   - Verify that temporary registration doesn't affect global state
   - Test complex registration scenarios (e.g., classes with dependencies)

4. **Realistic Data Testing**
   - Use realistic, comprehensive test data that exercises all properties
   - Test edge cases, empty values, and complex nested structures
   - Include actual turtle/RDF examples when available

5. **Type Safety and Generic Support**
   - For generic classes, test multiple type parameter combinations
   - Verify type safety is maintained through serialization/deserialization cycles
   - Test complex generic types (List<String>, Map<String, int>, etc.)

6. **Graph Content Verification**
   - Inspect generated RDF graphs for expected content
   - Verify proper IRI generation, property mapping, and namespace handling
   - Check for specific expected strings/patterns in the output

7. **Exception Handling Testing**
   - Test that appropriate exceptions are thrown when mappers are not registered
   - Verify specific exception types (`SerializerNotFoundException`, `DeserializerNotFoundException`)

#### Example High-Quality Test Pattern

```dart
test('ComplexClass mapping', () {
  // Verify registration state
  final isRegistered = mapper.registry.hasGlobalResourceDeserializerFor<ComplexClass>();
  expect(isRegistered, isFalse, reason: 'ComplexClass should not be registered globally');
  
  // Create realistic instance
  final instance = ComplexClass(
    id: 'test-id',
    property1: 'Complex Value',
    property2: 42,
    nestedObject: NestedClass(...),
  );
  
  // Test serialization with explicit registration
  final graph = mapper.encodeObject(instance,
      register: (registry) => registry.registerMapper(ComplexClassMapper()));
  expect(graph, isNotNull);
  expect(graph, contains('Complex Value'));
  expect(graph, contains('42'));
  
  // Test deserialization with explicit registration
  final deserialized = mapper.decodeObject<ComplexClass>(graph,
      register: (registry) => registry.registerMapper(ComplexClassMapper()));
  expect(deserialized, isNotNull);
  expect(deserialized.id, equals(instance.id));
  expect(deserialized.property1, equals(instance.property1));
  expect(deserialized.property2, equals(instance.property2));
  // ... verify all properties
});
```

This comprehensive approach ensures that generated mappers work correctly in real-world scenarios and helps catch integration issues that simpler tests might miss.

## Code Generation System

### The Code Class (`lib/src/templates/code.dart`)

The `Code` class is the foundation of the code generation system. It represents code snippets that will be rendered into the final generated Dart files. Understanding how `Code` works is essential when working on this codebase.

#### Key Concepts

**Code Objects vs Strings**: Instead of working with raw strings, the system uses `Code` objects that can:
- Track import dependencies automatically
- Combine multiple code fragments
- Handle type references and generic parameters
- Resolve to properly formatted code during template rendering

**Automatic String Resolution**: Code objects are automatically converted to strings during template rendering when `toMap()` is called on template data objects. You don't need to manually convert them.

#### Code Factory Methods

**Basic Construction**:
```dart
// Type references (automatically handles imports)
Code.type('MyClass', importUri: 'package:example/my_class.dart')
Code.type('List<String>')  // Built-in types need no import
Code.coreType('String')    // Dart core types

// Literal code snippets (no imports)
Code.literal('const')
Code.value('42')  // Alias for literal, semantic clarity for values

```

**Specialized List Builders**:
```dart
// Parameter lists: (param1, param2, param3)
Code.paramsList([
  Code.literal('param1'),
  Code.literal('param2'),
  Code.literal('param3')
])

// Generic parameter lists: <T, U, V>
Code.genericParamsList([
  Code.literal('T'),
  Code.literal('U'), 
  Code.literal('V')
])

// General combining with custom separators
Code.combine([
  Code.type('List'),
  Code.literal('<'),
  Code.type('MyType'),
  Code.literal('>')
])

// Custom separator (default is empty string)
Code.combine(codes, separator: ', ')
```

#### Working with Code Objects

**In Processors**: Create and manipulate Code objects to represent class names, types, and code snippets:
```dart
final className = Code.type(classElement.name);
final mapperName = Code.literal('${classElement.name}Mapper');
```

**In Template Data**: Include Code objects in template data structures:
```dart
class MyTemplateData {
  final Code className;
  final Code interfaceType;
  
  Map<String, dynamic> toMap() => {
    'className': className.toMap(),  // Auto-converts to string + imports
    'interfaceType': interfaceType.toMap(),
  };
}
```

**In Templates**: Use the resolved strings directly in mustache templates:
```mustache
class {{className}}Mapper implements {{interfaceType}} {
  // Generated code here
}
```

#### Advanced Code Manipulation

**Import and Alias Management**: Code objects automatically track their import dependencies and handle alias generation to avoid naming conflicts:
```dart
// This automatically generates proper import aliases if needed
final myClass = Code.type('MyClass', importUri: 'package:example/my_class.dart');
final otherClass = Code.type('MyClass', importUri: 'package:other/my_class.dart');
// Result: example.MyClass and other.MyClass with appropriate imports
```

**Accessing Code Properties**:
```dart
final code = Code.type('MyClass', importUri: 'package:example/my_class.dart');

// Get resolved code with aliases: "example.MyClass"
final resolvedCode = code.code;

// Get just the class name without aliases: "MyClass" 
final className = code.codeWithoutAlias;

// Get import dependencies: {"package:example/my_class.dart"}
final imports = code.imports;
```

**Adding Type Parameters** (using built-in methods):
```dart
// Clean implementation using Code.genericParamsList
Code appendTypeParameters(Code baseClass, List<String> typeParams) {
  if (typeParams.isEmpty) return baseClass;
  
  return Code.combine([
    baseClass,
    Code.genericParamsList(typeParams.map(Code.literal))
  ]);
}

// Alternative: For more complex parameter handling
Code createGenericType(Code baseType, List<Code> typeArgs) {
  return Code.combine([
    baseType,
    Code.genericParamsList(typeArgs)
  ]);
}
```

#### Best Practices

1. **Use appropriate factory methods** - `Code.type()` for types, etc.
2. **Leverage specialized builders** - Use `Code.paramsList()` and `Code.genericParamsList()` instead of manual bracket handling
3. **Let the template system handle string conversion** - Don't call `toString()` or `.code` manually in data processing
4. **Access raw names with `codeWithoutAlias`** - When you need the pure type name without import prefixes
5. **Enhance Code objects at the source** - Modify Code objects in processors/mappers rather than in templates
6. **Test Code object behavior** - Write unit tests to verify Code objects generate expected output

#### Common Patterns

**Creating Generic Types**:
```dart
// Modern approach using built-in methods
final genericClass = Code.combine([
  Code.type('MyClass', importUri: 'package:example/my_class.dart'),
  Code.genericParamsList([Code.literal('T'), Code.literal('U')])
]);

// For method calls with parameters
final methodCall = Code.combine([
  Code.literal('myMethod'),
  Code.paramsList([Code.literal('arg1'), Code.literal('arg2')])
]);
```

**Conditional Code Generation**:
```dart
final code = hasTypeParameters 
  ? appendTypeParameters(baseClass, typeParameters)
  : baseClass;

// Or using the null-aware pattern
final finalCode = typeParameters.isNotEmpty
  ? Code.combine([baseClass, Code.genericParamsList(typeParameters.map(Code.literal))])
  : baseClass;
```

Understanding these patterns will help you work effectively with the code generation system and avoid common pitfalls like losing import information or generating malformed code.