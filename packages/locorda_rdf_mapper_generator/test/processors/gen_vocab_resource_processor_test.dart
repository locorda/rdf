import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/resource_processor.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('GenVocab Resource Processor', () {
    late LibraryElem libraryElement;

    setUpAll(() async {
      (libraryElement, _) =
          await analyzeTestFile('gen_vocab_processor_test_models.dart');
    });

    test('processes implicit and explicit define properties', () {
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
        validationContext,
        libraryElement.getClass('GenVocabBook')!,
      );
      validationContext.throwIfErrors();

      expect(result, isNotNull);
      final annotation = result!.annotation as RdfGlobalResourceInfo;
      expect(annotation.vocab, isNotNull);
      expect(annotation.vocab!.appBaseUri, equals('https://example.com'));
      expect(annotation.vocab!.vocabPath, equals('/vocab'));
      expect(annotation.vocab!.label, equals('Example Vocabulary'));
      expect(annotation.vocab!.comment, equals('Vocabulary for tests'));
      expect(annotation.vocab!.metadata, hasLength(3));
      expect(
        annotation.vocab!.metadata,
        containsPair(
          const IriTerm('http://www.w3.org/2002/07/owl#versionInfo'),
          [const LiteralTerm('1.2.3')],
        ),
      );

      final title = result.properties.firstWhere((p) => p.name == 'title');
      expect(title.propertyInfo, isNotNull);
      expect(title.propertyInfo!.annotation.predicate, isNull);

      final id = result.properties.firstWhere((p) => p.name == 'id');
      expect(id.iriPart, isNotNull);
      expect(id.propertyInfo, isNull);

      final isbn = result.properties.firstWhere((p) => p.name == 'isbn');
      expect(isbn.propertyInfo, isNotNull);
      expect(isbn.propertyInfo!.annotation.predicate, isNull);
    });

    test(
        'excludes well-known fields, @RdfUnmappedTriples, and @RdfIgnore in .define() mode',
        () {
      final validationContext = ValidationContext();
      final result = ResourceProcessor.processClass(
        validationContext,
        libraryElement.getClass('GenVocabExcludedFields')!,
      );
      validationContext.throwIfErrors();

      expect(result, isNotNull);
      final annotation = result!.annotation as RdfGlobalResourceInfo;
      expect(annotation.vocab, isNotNull);

      // Should have: id (IriPart), title (property), unmappedTriples (special), internalState (ignored), hashCode (getter)
      // Only 'title' should have propertyInfo
      final titleProp = result.properties.firstWhere((p) => p.name == 'title');
      expect(titleProp.propertyInfo, isNotNull,
          reason: 'title should be processed as a property');
      expect(titleProp.propertyInfo!.annotation.predicate, isNull,
          reason: 'title should use implicit .define() predicate');

      // id should be IriPart, not a property
      final idProp = result.properties.firstWhere((p) => p.name == 'id');
      expect(idProp.iriPart, isNotNull, reason: 'id should be an IRI part');
      expect(idProp.propertyInfo, isNull,
          reason: 'id should not be a property');

      // unmappedTriples should exist as PropertyInfo but without propertyInfo
      final unmappedProp =
          result.properties.firstWhere((p) => p.name == 'unmappedTriples');
      expect(unmappedProp.unmappedTriples, isNotNull,
          reason: 'unmappedTriples should have unmappedTriples annotation');
      expect(unmappedProp.propertyInfo, isNull,
          reason:
              'unmappedTriples should not be treated as a property in .define() mode');

      // internalState should NOT exist in properties due to @RdfIgnore
      final internalProps =
          result.properties.where((p) => p.name == 'internalState');
      expect(internalProps, isEmpty,
          reason:
              'internalState should be completely excluded due to @RdfIgnore');

      // hashCode is a getter, may or may not be in properties - if present, should not have propertyInfo
      final hashCodeProps =
          result.properties.where((p) => p.name == 'hashCode');
      if (hashCodeProps.isNotEmpty) {
        expect(hashCodeProps.first.propertyInfo, isNull,
            reason: 'hashCode should not be treated as a property');
      }
    });
  });
}
