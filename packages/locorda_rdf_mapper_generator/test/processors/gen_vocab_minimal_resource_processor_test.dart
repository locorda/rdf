import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/resource_processor.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('GenVocab Minimal Resource Processor', () {
    late LibraryElem libraryElement;

    setUpAll(() async {
      (libraryElement, _) =
          await analyzeTestFile('gen_vocab_minimal_test_models.dart');
    });

    test('processes minimal define resource with defaults only', () {
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
        validationContext,
        libraryElement.getClass('GenVocabMinimalEntity')!,
      );
      validationContext.throwIfErrors();

      expect(result, isNotNull);
      final annotation = result!.annotation as RdfGlobalResourceInfo;
      expect(annotation.vocab, isNotNull);
      expect(
          annotation.vocab!.appBaseUri, equals('https://minimal.example.com'));
      expect(annotation.vocab!.vocabPath, equals('/vocab'));
      expect(annotation.vocab!.label, isNull);
      expect(annotation.vocab!.comment, isNull);
      expect(annotation.vocab!.metadata, isEmpty);

      final id = result.properties.firstWhere((p) => p.name == 'id');
      expect(id.iriPart, isNotNull);
      expect(id.propertyInfo, isNull);

      final minimalName =
          result.properties.firstWhere((p) => p.name == 'minimalName');
      expect(minimalName.propertyInfo, isNotNull);
      expect(minimalName.propertyInfo!.annotation.predicate, isNull);

      // Field with @RdfIgnore should be completely excluded
      expect(result.properties.any((p) => p.name == 'isExpanded'), isFalse,
          reason: '@RdfIgnore field should not be in properties list');

      // Field with include: false should be in properties but not serialized
      final lastModified =
          result.properties.firstWhere((p) => p.name == 'lastModified');
      expect(lastModified.propertyInfo, isNotNull);
      expect(lastModified.propertyInfo!.annotation.include, isFalse,
          reason: 'include: false should be preserved');
      expect(lastModified.propertyInfo!.annotation.predicate, isNull,
          reason: '.define() mode should have null predicate');
    });

    test('verifies @RdfIgnore field is completely excluded from processing',
        () {
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
        validationContext,
        libraryElement.getClass('GenVocabMinimalEntity')!,
      );
      validationContext.throwIfErrors();

      expect(result, isNotNull);

      // Count properties - should be 3: id (IriPart), minimalName, lastModified
      // isExpanded should NOT be present
      expect(result!.properties.length, equals(3),
          reason:
              'Should have exactly 3 properties (id, minimalName, lastModified), not including @RdfIgnore field');

      final propertyNames = result.properties.map((p) => p.name).toList();
      expect(propertyNames, contains('id'));
      expect(propertyNames, contains('minimalName'));
      expect(propertyNames, contains('lastModified'));
      expect(propertyNames, isNot(contains('isExpanded')),
          reason: '@RdfIgnore field should be completely excluded');
    });
  });
}
