// import 'package:analyzer/dart/element/element2.dart';
import 'package:build/build.dart';
import 'package:locorda_rdf_mapper_generator/builder_helper.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:test/test.dart';

import 'test_helper.dart' as test_helper;

void main() {
  group('BuilderHelper', () {
    late LibraryElem globalResourceLibrary;
    late LibraryElem localResourceLibrary;
    late LibraryElem iriLibrary;
    late LibraryElem literalLibrary;
    late LibraryElem propertyLibrary;
    late AssetReader assetReader;

    setUpAll(() async {
      assetReader = await test_helper.createTestAssetReader();

      // Initialize test environments for all test files
      final globalResult = await test_helper
          .analyzeTestFile('global_resource_processor_test_models.dart');
      globalResourceLibrary = globalResult.$1;

      final localResult = await test_helper
          .analyzeTestFile('local_resource_processor_test_models.dart');
      localResourceLibrary = localResult.$1;

      final iriResult =
          await test_helper.analyzeTestFile('iri_processor_test_models.dart');
      iriLibrary = iriResult.$1;

      final literalResult = await test_helper
          .analyzeTestFile('literal_processor_test_models.dart');
      literalLibrary = literalResult.$1;

      final propertyResult = await test_helper
          .analyzeTestFile('property_processor_test_models.dart');
      propertyLibrary = propertyResult.$1;
    });

    group('Global Resource Mappers', () {
      test('should generate mapper for Book class', () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [globalResourceLibrary.getClass('Book')!],
            [], // No enums
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class BookMapper'));
        expect(result, contains('implements GlobalResourceMapper<grptm.Book>'));

        // Book has IRI template, so should use complex implementation
        expect(result, contains('_buildIri'));
        expect(result, contains('RegExp'));
        expect(result, contains('iriParts'));
      });

      test('should generate mapper for class with empty IRI strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [globalResourceLibrary.getClass('ClassWithEmptyIriStrategy')!],
            [], // No enums
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithEmptyIriStrategyMapper'));

        // Should use simple implementation with direct IRI access
        expect(result, contains('final iri = subject.value;'));
        expect(result,
            contains('final subject = context.createIriTerm(resource.iri);'));

        // Should NOT contain complex IRI processing methods
        expect(result, isNot(contains('_buildIri')));
        expect(result, isNot(contains('RegExp')));
        expect(result, isNot(contains('iriParts')));
      });

      test('should generate mapper for class with IRI template strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [globalResourceLibrary.getClass('ClassWithIriTemplateStrategy')!],
            [], // No enums
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithIriTemplateStrategyMapper'));

        // Should use complex implementation with IRI template processing
        expect(result, contains('_buildIri'));
        expect(result, contains('RegExp'));
        expect(result, contains('iriParts'));

        // Should NOT use simple direct IRI access
        expect(result, isNot(contains('final iri = subject.iri;')));
        expect(result,
            isNot(contains('final subject = const IriTerm(resource.iri);')));
      });

      test(
          'should generate mapper for class with IRI template strategy and context variable',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [
              globalResourceLibrary
                  .getClass('ClassWithIriTemplateAndContextVariableStrategy')!
            ],
            [], // No enums
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result,
            contains('class ClassWithIriTemplateAndContextVariableStrategy'));
      });

      test('should generate mapper for class with named IRI mapper strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [
              globalResourceLibrary.getClass('ClassWithIriNamedMapperStrategy')!
            ],
            [], // No enums
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithIriNamedMapperStrategyMapper'));
      });

      test('should generate mapper for class with IRI mapper strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [globalResourceLibrary.getClass('ClassWithIriMapperStrategy')!],
            [], // No enums
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithIriMapperStrategyMapper'));
      });

      test('should generate mapper for class with IRI mapper instance strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [
              globalResourceLibrary
                  .getClass('ClassWithIriMapperInstanceStrategy')!
            ],
            [], // No enums
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(
            result, contains('class ClassWithIriMapperInstanceStrategyMapper'));
      });

      test('should NOT generate mapper for class with named mapper strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [
              globalResourceLibrary
                  .getClass('ClassWithMapperNamedMapperStrategy')!
            ],
            [], // No enums
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result,
            isNot(contains('class ClassWithMapperNamedMapperStrategyMapper')));
      });

      test('should NOT generate mapper for class with mapper strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [globalResourceLibrary.getClass('ClassWithMapperStrategy')!],
            [], // No enums
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result, isNot(contains('class ClassWithMapperStrategyMapper')));
      });

      test('should NOT generate mapper for class with mapper instance strategy',
          () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [
              globalResourceLibrary.getClass('ClassWithMapperInstanceStrategy')!
            ],
            [], // No enums
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNotNull);
        expect(result,
            isNot(contains('class ClassWithMapperInstanceStrategyMapper')));
      });

      test('should return null for non-annotated class', () async {
        final result = await BuilderHelper().build(
            'global_resource_processor_test_models.dart',
            [globalResourceLibrary.getClass('NotAnnotated')!],
            [], // No enums
            assetReader,
            BroaderImports.create(globalResourceLibrary));
        expect(result, isNull);
      });
    });

    group('Local Resource Mappers', () {
      test('should generate mapper for Book class', () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass('Book')!],
            [], // No enums
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class BookMapper'));
        expect(result, contains('implements LocalResourceMapper<lrptm.Book>'));
      });

      test('should generate mapper for ClassNoRegisterGlobally', () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass('ClassNoRegisterGlobally')!],
            [], // No enums
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassNoRegisterGloballyMapper'));
        expect(
            result,
            contains(
                'implements LocalResourceMapper<lrptm.ClassNoRegisterGlobally>'));
      });

      test('should generate mapper for ClassWithNoRdfType', () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass('ClassWithNoRdfType')!],
            [], // No enums
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithNoRdfTypeMapper'));
      });

      test('should generate mapper for ClassWithPositionalProperty', () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass('ClassWithPositionalProperty')!],
            [], // No enums
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithPositionalPropertyMapper'));
      });

      test('should generate mapper for ClassWithNonFinalProperty', () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass('ClassWithNonFinalProperty')!],
            [], // No enums
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithNonFinalPropertyMapper'));
      });

      test('should generate mapper for ClassWithNonFinalPropertyWithDefault',
          () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [
              localResourceLibrary
                  .getClass('ClassWithNonFinalPropertyWithDefault')!
            ],
            [], // No enums
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result,
            contains('class ClassWithNonFinalPropertyWithDefaultMapper'));
      });

      test('should generate mapper for ClassWithNonFinalOptionalProperty',
          () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [
              localResourceLibrary
                  .getClass('ClassWithNonFinalOptionalProperty')!
            ],
            [], // No enums
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(
            result, contains('class ClassWithNonFinalOptionalPropertyMapper'));
      });

      test('should generate mapper for ClassWithLateNonFinalProperty',
          () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass('ClassWithLateNonFinalProperty')!],
            [], // No enums
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithLateNonFinalPropertyMapper'));
      });

      test('should generate mapper for ClassWithLateFinalProperty', () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass('ClassWithLateFinalProperty')!],
            [], // No enums
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, contains('class ClassWithLateFinalPropertyMapper'));
      });

      test('should generate mapper for ClassWithMixedFinalAndLateFinalProperty',
          () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [
              localResourceLibrary
                  .getClass('ClassWithMixedFinalAndLateFinalProperty')!
            ],
            [], // No enums
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result,
            contains('class ClassWithMixedFinalAndLateFinalPropertyMapper'));
      });

      test('should NOT generate mapper for ClassWithMapperNamedMapperStrategy',
          () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [
              localResourceLibrary
                  .getClass('ClassWithMapperNamedMapperStrategy')!
            ],
            [], // No enums
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result,
            isNot(contains('class ClassWithMapperNamedMapperStrategyMapper')));
      });

      test('should NOT generate mapper for ClassWithMapperStrategy', () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass('ClassWithMapperStrategy')!],
            [], // No enums
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result, isNot(contains('class ClassWithMapperStrategyMapper')));
      });

      test('should NOT generate mapper for ClassWithMapperInstanceStrategy',
          () async {
        final result = await BuilderHelper().build(
            'local_resource_processor_test_models.dart',
            [localResourceLibrary.getClass('ClassWithMapperInstanceStrategy')!],
            [], // No enums
            assetReader,
            BroaderImports.create(localResourceLibrary));
        expect(result, isNotNull);
        expect(result,
            isNot(contains('class ClassWithMapperInstanceStrategyMapper')));
      });
    });

    group('IRI Mappers', () {
      test('should generate mapper for IriWithOnePart', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass('IriWithOnePart')!],
            [], // No enums
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithOnePartMapper'));
        expect(
            result, contains('implements IriTermMapper<iptm.IriWithOnePart>'));
      });

      test('should generate mapper for IriWithOnePartExplicitlyGlobal',
          () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass('IriWithOnePartExplicitlyGlobal')!],
            [], // No enums
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithOnePartExplicitlyGlobalMapper'));
      });

      test('should generate mapper for IriWithOnePartNamed', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass('IriWithOnePartNamed')!],
            [], // No enums
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithOnePartNamedMapper'));
      });

      test('should generate mapper for IriWithTwoParts', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass('IriWithTwoParts')!],
            [], // No enums
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithTwoPartsMapper'));
      });

      test('should generate mapper for IriWithBaseUriAndTwoParts', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass('IriWithBaseUriAndTwoParts')!],
            [], // No enums
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithBaseUriAndTwoPartsMapper'));
      });

      test('should generate mapper for IriWithBaseUri', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass('IriWithBaseUri')!],
            [], // No enums
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithBaseUriMapper'));
      });

      test('should generate mapper for IriWithBaseUriNoGlobal', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass('IriWithBaseUriNoGlobal')!],
            [], // No enums
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithBaseUriNoGlobalMapper'));
      });

      test('should generate mapper for IriWithNonConstructorFields', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass('IriWithNonConstructorFields')!],
            [], // No enums
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithNonConstructorFieldsMapper'));
      });

      test(
          'should generate mapper for IriWithNonConstructorFieldsAndBaseUriNonGlobal',
          () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [
              iriLibrary
                  .getClass('IriWithNonConstructorFieldsAndBaseUriNonGlobal')!
            ],
            [], // No enums
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(
            result,
            contains(
                'class IriWithNonConstructorFieldsAndBaseUriNonGlobalMapper'));
      });

      test('should generate mapper for IriWithMixedFields', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass('IriWithMixedFields')!],
            [], // No enums
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriWithMixedFieldsMapper'));
      });

      test('should NOT generate mapper for IriWithNamedMapper', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass('IriWithNamedMapper')!],
            [], // No enums
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, isNot(contains('class IriWithNamedMapperMapper')));
      });

      test('should NOT generate mapper for IriWithMapper', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass('IriWithMapper')!],
            [], // No enums
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, isNot(contains('class IriWithMapperMapper')));
      });

      test('should NOT generate mapper for IriWithMapperInstance', () async {
        final result = await BuilderHelper().build(
            'iri_processor_test_models.dart',
            [iriLibrary.getClass('IriWithMapperInstance')!],
            [], // No enums
            assetReader,
            BroaderImports.create(iriLibrary));
        expect(result, isNotNull);
        expect(result, isNot(contains('class IriWithMapperInstanceMapper')));
      });
    });

    group('Literal Mappers', () {
      test('should generate mapper for LiteralString', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass('LiteralString')!],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class LiteralStringMapper'));
        expect(result,
            contains('implements LiteralTermMapper<lptm.LiteralString>'));
      });

      test('should generate mapper for Rating', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass('Rating')!],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class RatingMapper'));
      });

      test('should generate mapper for LocalizedText', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass('LocalizedText')!],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class LocalizedTextMapper'));
      });

      test('should generate mapper for LiteralDouble', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass('LiteralDouble')!],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class LiteralDoubleMapper'));
      });

      test('should generate mapper for LiteralInteger', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass('LiteralInteger')!],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class LiteralIntegerMapper'));
      });

      test('should generate mapper for Temperature with custom methods',
          () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass('Temperature')!],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class TemperatureMapper'));
        expect(result, contains('formatCelsius'));
        expect(result, contains('parse'));
      });

      test('should generate mapper for CustomLocalizedText', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass('CustomLocalizedText')!],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class CustomLocalizedTextMapper'));
        expect(result, contains('toRdf'));
        expect(result, contains('fromRdf'));
      });

      test('should generate mapper for DoubleAsMilliunit', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass('DoubleAsMilliunit')!],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class DoubleAsMilliunitMapper'));
        expect(result, contains('toMilliunit'));
        expect(result, contains('fromMilliunit'));
      });

      test('should generate mapper for LiteralWithNonConstructorValue',
          () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass('LiteralWithNonConstructorValue')!],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class LiteralWithNonConstructorValueMapper'));
      });

      test('should generate mapper for LocalizedTextWithNonConstructorLanguage',
          () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [
              literalLibrary
                  .getClass('LocalizedTextWithNonConstructorLanguage')!
            ],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result,
            contains('class LocalizedTextWithNonConstructorLanguageMapper'));
      });

      test('should generate mapper for LiteralLateFinalLocalizedText',
          () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass('LiteralLateFinalLocalizedText')!],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class LiteralLateFinalLocalizedTextMapper'));
      });

      test('should NOT generate mapper for LiteralWithNamedMapper', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass('LiteralWithNamedMapper')!],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, isNot(contains('class LiteralWithNamedMapperMapper')));
      });

      test('should NOT generate mapper for LiteralWithMapper', () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass('LiteralWithMapper')!],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, isNot(contains('class LiteralWithMapperMapper')));
      });

      test('should NOT generate mapper for LiteralWithMapperInstance',
          () async {
        final result = await BuilderHelper().build(
            'literal_processor_test_models.dart',
            [literalLibrary.getClass('LiteralWithMapperInstance')!],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(
            result, isNot(contains('class LiteralWithMapperInstanceMapper')));
      });
    });

    test(
        'should generate different implementations for empty vs template IRI strategies',
        () async {
      // Test empty IRI strategy (simple implementation)
      final emptyIriResult = await BuilderHelper().build(
          'global_resource_processor_test_models.dart',
          [globalResourceLibrary.getClass('ClassWithEmptyIriStrategy')!],
          [], // No enums
          assetReader,
          BroaderImports.create(globalResourceLibrary));

      // Test template IRI strategy (complex implementation)
      final templateIriResult = await BuilderHelper().build(
          'global_resource_processor_test_models.dart',
          [globalResourceLibrary.getClass('ClassWithIriTemplateStrategy')!],
          [], // No enums
          assetReader,
          BroaderImports.create(globalResourceLibrary));

      // Empty IRI strategy should be simple
      expect(emptyIriResult, contains('final iri = subject.value;'));
      expect(emptyIriResult,
          contains('final subject = context.createIriTerm(resource.iri);'));
      expect(emptyIriResult, isNot(contains('_buildIri')));

      // Template IRI strategy should be complex
      expect(templateIriResult, contains('_buildIri'));
      expect(templateIriResult, contains('RegExp'));
      expect(templateIriResult, isNot(contains('final iri = subject.value;')));
      expect(templateIriResult,
          isNot(contains('final subject = const IriTerm(resource.iri);')));
    });
    test('should generate correct method structure for empty IRI strategy',
        () async {
      final result = await BuilderHelper().build(
          'global_resource_processor_test_models.dart',
          [globalResourceLibrary.getClass('ClassWithEmptyIriStrategy')!],
          [], // No enums
          assetReader,
          BroaderImports.create(globalResourceLibrary));

      // Verify constructor is simple
      expect(result, contains('const ClassWithEmptyIriStrategyMapper();'));

      // Verify fromRdfResource method uses direct IRI access
      expect(
          result, contains('grptm.ClassWithEmptyIriStrategy fromRdfResource('));
      expect(result, contains('IriTerm subject,'));
      expect(result, contains('final iri = subject.value;'));
      expect(result,
          contains('return grptm.ClassWithEmptyIriStrategy(iri: iri);'));

      // Verify toRdfResource method uses direct IRI access
      expect(result, contains('(IriTerm, Iterable<Triple>) toRdfResource('));
      expect(result, contains('grptm.ClassWithEmptyIriStrategy resource,'));
      expect(result,
          contains('final subject = context.createIriTerm(resource.iri);'));
      expect(
          result, contains('return context.resourceBuilder(subject).build();'));

      // Verify no helper methods are generated
      expect(result,
          isNot(contains('/// Builds the IRI for a resource instance')));
      expect(
          result, isNot(contains('/// Parses IRI parts from a complete IRI')));
      expect(result, isNot(contains('String _buildIri(')));
    });

    group('Property Test Mappers', () {
      test('should generate mapper for IriMappingNamedMapperTestMapper',
          () async {
        final result = await BuilderHelper().build(
            'property_processor_test_models.dart',
            [propertyLibrary.getClass('IriMappingNamedMapperTest')!],
            [], // No enums
            assetReader,
            BroaderImports.create(literalLibrary));
        expect(result, isNotNull);
        expect(result, contains('class IriMappingNamedMapperTestMapper\n'));
        expect(
            result,
            contains(
                'implements LocalResourceMapper<pptm.IriMappingNamedMapperTest>'));
      });
    });
  });
}
