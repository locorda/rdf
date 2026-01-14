import 'package:locorda_rdf_mapper_generator/src/mappers/mapper_model.dart';
import 'package:locorda_rdf_mapper_generator/src/mappers/resolved_mapper_model.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/template_data.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

void main() {
  group('ResourceResolvedMapperModel Generic Type Tests', () {
    group('appendTypeParameters Method', () {
      test('returns original code when no type parameters', () {
        final mapper = _createTestResourceMapper(typeParameters: []);
        final baseCode = Code.type('Document');

        final result = mapper.appendTypeParameters(baseCode);

        expect(result.code, equals('Document'));
      });

      test('appends single type parameter correctly', () {
        final mapper = _createTestResourceMapper(typeParameters: ['T']);
        final baseCode = Code.type('Document');

        final result = mapper.appendTypeParameters(baseCode);

        expect(result.code, equals('Document<T>'));
      });

      test('appends multiple type parameters with commas', () {
        final mapper =
            _createTestResourceMapper(typeParameters: ['T', 'U', 'V']);
        final baseCode = Code.type('Document');

        final result = mapper.appendTypeParameters(baseCode);

        expect(result.code, equals('Document<T, U, V>'));
      });

      test('handles two type parameters correctly', () {
        final mapper = _createTestResourceMapper(typeParameters: ['T', 'U']);
        final baseCode = Code.type('GenericClass');

        final result = mapper.appendTypeParameters(baseCode);

        expect(result.code, equals('GenericClass<T, U>'));
      });

      test('works with complex type parameter names', () {
        final mapper = _createTestResourceMapper(
            typeParameters: ['TData', 'UMetadata', 'VResult']);
        final baseCode = Code.type('ComplexDocument');

        final result = mapper.appendTypeParameters(baseCode);

        expect(
            result.code, equals('ComplexDocument<TData, UMetadata, VResult>'));
      });

      test('preserves code import information', () {
        final mapper = _createTestResourceMapper(typeParameters: ['T']);
        final baseCode =
            Code.type('Document', importUri: 'package:example/document.dart');

        final result = mapper.appendTypeParameters(baseCode);

        expect(result.code, contains('Document<T>'));
        expect(result.imports, contains('package:example/document.dart'));
      });
    });

    group('Template Data Generation', () {
      test('includes type parameters in template data', () {
        final context = ValidationContext();
        final mapper = _createTestResourceMapper(typeParameters: ['T', 'U']);

        final templateData = mapper.toTemplateData(context, 'test://mapper');

        expect(templateData, isA<ResourceMapperTemplateData>());
        final resourceTemplateData = templateData as ResourceMapperTemplateData;

        expect(resourceTemplateData.typeParameters, equals(['T', 'U']));
      });

      test('generates enhanced class names with type parameters', () {
        final context = ValidationContext();
        final mapper = _createTestResourceMapper(typeParameters: ['T']);

        final templateData = mapper.toTemplateData(context, 'test://mapper');
        final resourceTemplateData = templateData as ResourceMapperTemplateData;

        // The className should include type parameters
        expect(resourceTemplateData.className.code, contains('<T>'));
        expect(resourceTemplateData.mapperClassName.code, contains('<T>'));
      });

      test('generates correct interface names with type parameters', () {
        final context = ValidationContext();
        final mapper = _createTestResourceMapper(
            typeParameters: ['T', 'U'], isGlobalResource: true);

        final templateData = mapper.toTemplateData(context, 'test://mapper');
        final resourceTemplateData = templateData as ResourceMapperTemplateData;

        // The interface name should include the enhanced class name
        final interfaceName = resourceTemplateData.mapperInterfaceName.code;
        expect(interfaceName, contains('GlobalResourceMapper'));
        expect(interfaceName, contains('<'));
        expect(interfaceName, contains('>'));
      });

      test('handles no type parameters correctly in template data', () {
        final context = ValidationContext();
        final mapper = _createTestResourceMapper(typeParameters: []);

        final templateData = mapper.toTemplateData(context, 'test://mapper');
        final resourceTemplateData = templateData as ResourceMapperTemplateData;

        expect(resourceTemplateData.typeParameters, isEmpty);
        expect(resourceTemplateData.className.code, isNot(contains('<')));
        expect(resourceTemplateData.mapperClassName.code, isNot(contains('<')));
      });
    });

    group('Edge Cases', () {
      test('handles empty type parameter list', () {
        final mapper = _createTestResourceMapper(typeParameters: []);
        final baseCode = Code.type('Document');

        final result = mapper.appendTypeParameters(baseCode);

        expect(result.code, equals('Document'));
        expect(result.code, isNot(contains('<')));
        expect(result.code, isNot(contains('>')));
      });

      test('handles single character type parameters', () {
        final mapper =
            _createTestResourceMapper(typeParameters: ['A', 'B', 'C']);
        final baseCode = Code.type('Test');

        final result = mapper.appendTypeParameters(baseCode);

        expect(result.code, equals('Test<A, B, C>'));
      });

      test('maintains consistency across multiple calls', () {
        final mapper = _createTestResourceMapper(typeParameters: ['T', 'U']);
        final baseCode = Code.type('Document');

        final result1 = mapper.appendTypeParameters(baseCode);
        final result2 = mapper.appendTypeParameters(baseCode);

        expect(result1.code, equals(result2.code));
        expect(result1.code, equals('Document<T, U>'));
      });
    });
  });
}

/// Helper function to create a test ResourceResolvedMapperModel
ResourceResolvedMapperModel _createTestResourceMapper({
  List<String> typeParameters = const [],
  bool isGlobalResource = false,
}) {
  return ResourceResolvedMapperModel(
    id: MapperRef.fromImplementationClass(Code.type('TestMapper')),
    mappedClass: Code.type('TestClass'),
    mappedClassModel: _createTestMappedClassModel(),
    implementationClass: Code.type('TestMapper'),
    registerGlobally: false,
    typeIri: null,
    termClass:
        isGlobalResource ? Code.type('IriTerm') : Code.type('BlankNodeTerm'),
    iriStrategy: isGlobalResource ? _createTestIriStrategy() : null,
    needsReader: false,
    dependencies: const [],
    provides: const [],
    typeParameters: typeParameters,
    type:
        isGlobalResource ? MapperType.globalResource : MapperType.localResource,
  );
}

/// Helper to create a minimal IRI strategy for global resource tests
IriResolvedModel _createTestIriStrategy() {
  return IriResolvedModel(
    template: null,
    hasFullIriPartTemplate: false,
    hasMapper: false,
    iriMapperParts: const [],
  );
}

/// Helper function to create a minimal MappedClassResolvedModel
MappedClassResolvedModel _createTestMappedClassModel() {
  return MappedClassResolvedModel(
    className: Code.type('TestClass'),
    properties: const [],
    isRdfFieldFilter: (_) => true,
    isMapValue: false,
  );
}
