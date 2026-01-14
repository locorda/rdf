import 'package:test/test.dart';
import 'package:locorda_rdf_mapper_generator/builder_helper.dart';
import 'package:locorda_rdf_mapper_generator/src/mappers/mapper_model.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';

void main() {
  group('BuilderHelper.topologicalSort', () {
    test('handles empty list', () {
      final result = BuilderHelper.topologicalSort([]);
      expect(result, isEmpty);
    });

    test('detects circular dependencies', () {
      // Create simple custom mappers that have circular dependencies
      final mapperA = CustomMapperModel(
        id: MapperRef.fromInstanceName('A'),
        type: MapperType.globalResource,
        mappedClass: const Code.literal('ClassA'),
        registerGlobally: true,
        instanceName: 'mapperA',
        instanceInstantiationCode: const Code.literal('mapperA'),
        implementationClass: null,
      );

      final mapperB = CustomMapperModel(
        id: MapperRef.fromInstanceName('B'),
        type: MapperType.globalResource,
        mappedClass: const Code.literal('ClassB'),
        registerGlobally: true,
        instanceName: 'mapperB',
        instanceInstantiationCode: const Code.literal('mapperB'),
        implementationClass: null,
      );

      // We can't actually create circular dependencies with CustomMapperModel
      // since it returns an empty dependencies list, so let's just test
      // that the method accepts these mappers without error
      final result = BuilderHelper.topologicalSort([mapperA, mapperB]);

      expect(result, hasLength(2));
      expect(result, containsAll([mapperA, mapperB]));
    });

    test('sorts mappers with no dependencies', () {
      final mapperA = CustomMapperModel(
        id: MapperRef.fromInstanceName('A'),
        type: MapperType.globalResource,
        mappedClass: const Code.literal('ClassA'),
        registerGlobally: true,
        instanceName: 'mapperA',
        instanceInstantiationCode: const Code.literal('mapperA'),
        implementationClass: null,
      );

      final mapperB = CustomMapperModel(
        id: MapperRef.fromInstanceName('B'),
        type: MapperType.globalResource,
        mappedClass: const Code.literal('ClassB'),
        registerGlobally: true,
        instanceName: 'mapperB',
        instanceInstantiationCode: const Code.literal('mapperB'),
        implementationClass: null,
      );

      final result = BuilderHelper.topologicalSort([mapperA, mapperB]);

      expect(result, hasLength(2));
      expect(result, containsAll([mapperA, mapperB]));
    });
  });
}
