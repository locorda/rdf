import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:test/test.dart';
// import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/processors/enum_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import '../test_helper.dart';

/// Tests for enum mapper generation functionality
void main() {
  group('EnumProcessor', () {
    late LibraryElem library;

    setUpAll(() async {
      (library, _) = await analyzeTestFile('enum_test_models.dart');
    });

    test('should identify and process all annotated enums', () async {
      final validationContext = ValidationContext();

      // Get all enums from the library
      final enums = library.enums;

      expect(enums.length, equals(6), reason: 'Should find all 6 test enums');

      // Process each enum
      final results = <MappableClassInfo>[];
      for (final enumElement in enums) {
        final result =
            EnumProcessor.processEnum(validationContext, enumElement);
        if (result != null) {
          results.add(result);
        }
      }

      // Should find all 6 annotated enums
      expect(results.length, equals(6),
          reason: 'All enums should be annotated and processed');

      // Verify expected enum names are processed
      final enumNames =
          results.map((r) => r.className.codeWithoutAlias).toSet();
      expect(
          enumNames,
          containsAll([
            'Priority',
            'Status',
            'DocumentType',
            'CategoryType',
            'FileFormat',
            'ItemType'
          ]));

      // Check that no validation errors occurred
      expect(validationContext.errors.isEmpty, isTrue,
          reason: 'Processing should not produce validation errors');
    });

    test('should process RdfLiteral enums correctly', () async {
      final validationContext = ValidationContext();

      // Test Priority enum (simple literal)
      final priorityEnum =
          library.enums.firstWhere((e) => e.name == 'Priority');

      final priorityResult =
          EnumProcessor.processEnum(validationContext, priorityEnum);
      expect(priorityResult, isNotNull);
      expect(priorityResult!.className.codeWithoutAlias, equals('Priority'));

      // Test Status enum (literal with custom values)
      final statusEnum = library.enums.firstWhere((e) => e.name == 'Status');

      final statusResult =
          EnumProcessor.processEnum(validationContext, statusEnum);
      expect(statusResult, isNotNull);
      expect(statusResult!.className.codeWithoutAlias, equals('Status'));
    });

    test('should process RdfIri enums correctly', () async {
      final validationContext = ValidationContext();

      // Test DocumentType enum (IRI without template)
      final docTypeEnum =
          library.enums.firstWhere((e) => e.name == 'DocumentType');

      final docTypeResult =
          EnumProcessor.processEnum(validationContext, docTypeEnum);
      expect(docTypeResult, isNotNull);
      expect(docTypeResult!.className.codeWithoutAlias, equals('DocumentType'));

      // Test CategoryType enum (IRI with simple template)
      final categoryEnum =
          library.enums.firstWhere((e) => e.name == 'CategoryType');

      final categoryResult =
          EnumProcessor.processEnum(validationContext, categoryEnum);
      expect(categoryResult, isNotNull);
      expect(
          categoryResult!.className.codeWithoutAlias, equals('CategoryType'));

      // Test FileFormat enum (IRI with context variable)
      final fileFormatEnum =
          library.enums.firstWhere((e) => e.name == 'FileFormat');

      final fileFormatResult =
          EnumProcessor.processEnum(validationContext, fileFormatEnum);
      expect(fileFormatResult, isNotNull);
      expect(
          fileFormatResult!.className.codeWithoutAlias, equals('FileFormat'));

      // Test ItemType enum (IRI with multiple context variables)
      final itemTypeEnum =
          library.enums.firstWhere((e) => e.name == 'ItemType');

      final itemTypeResult =
          EnumProcessor.processEnum(validationContext, itemTypeEnum);
      expect(itemTypeResult, isNotNull);
      expect(itemTypeResult!.className.codeWithoutAlias, equals('ItemType'));
    });
  });
}
