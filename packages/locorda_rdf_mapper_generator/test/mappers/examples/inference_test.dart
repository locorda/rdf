import 'package:test/test.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';
import '../../fixtures/locorda_rdf_mapper_annotations/examples/inference.dart';
import '../../fixtures/locorda_rdf_mapper_annotations/examples/inference.locorda_rdf_mapper.g.dart';

void main() {
  group('Smart Inference Tests', () {
    test(
        'TestGlobalResourceMapper should be generated for registerGlobally: false',
        () {
      // Verify that the mapper class exists and is correctly typed
      final mapper = TestGlobalResourceMapper();
      expect(mapper, isA<GlobalResourceMapper<TestGlobalResource>>());
    });

    test(
        'TestLocalResourceMapper should be generated for registerGlobally: false',
        () {
      // Verify that the mapper class exists and is correctly typed
      final mapper = TestLocalResourceMapper();
      expect(mapper, isA<LocalResourceMapper<TestLocalResource>>());
    });

    test('TestIriMapper should be generated for registerGlobally: false', () {
      // Verify that the mapper class exists and is correctly typed
      final mapper = TestIriMapper();
      expect(mapper, isA<IriTermMapper<TestIri>>());
    });

    test(
        'InferenceTestContainerMapper should require inferred mappers in constructor',
        () {
      // Verify that the container mapper correctly infers and requires the individual mappers
      final globalResourceMapper = TestGlobalResourceMapper();
      final localResourceMapper = TestLocalResourceMapper();
      final iriMapper = TestIriMapper();

      final containerMapper = InferenceTestContainerMapper(
        globalResourceMapper: globalResourceMapper,
        localResourceMapper: localResourceMapper,
        iriMapper: iriMapper,
      );

      expect(
          containerMapper, isA<LocalResourceMapper<InferenceTestContainer>>());
    });

    test('Smart inference should work for all supported annotation types', () {
      // This test verifies that inference works by ensuring we can construct
      // the container mapper with the inferred dependencies
      final globalResourceMapper = TestGlobalResourceMapper();
      final localResourceMapper = TestLocalResourceMapper();
      final iriMapper = TestIriMapper();

      // This should compile and work if inference is correct
      final containerMapper = InferenceTestContainerMapper(
        globalResourceMapper: globalResourceMapper,
        localResourceMapper: localResourceMapper,
        iriMapper: iriMapper,
      );

      // Verify the mapper is properly constructed
      expect(containerMapper, isNotNull);
      expect(containerMapper.typeIri, equals(SchemaBook.classIri));
    });
  });
}
