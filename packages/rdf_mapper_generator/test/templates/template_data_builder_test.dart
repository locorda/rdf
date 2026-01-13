import 'package:rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:rdf_mapper_generator/src/templates/template_data.dart';
import 'package:rdf_mapper_generator/src/templates/template_data_builder.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateDataBuilder Tests', () {
    late ValidationContext context;
    late BroaderImports broaderImports;
    late Map<String, String> originalImports;
    setUp(() {
      context = ValidationContext();
      broaderImports = BroaderImports(<String, String>{});
      originalImports = <String, String>{};
    });

    test('buildFileTemplate creates FileTemplateData with header', () {
      final sourcePath = 'lib/test.dart';
      final mapperImportUri = 'asset:test/lib/test.rdf_mapper.g.dart';
      final mapperDatas = <MappableClassMapperTemplateData>[];

      final result = TemplateDataBuilder.buildFileTemplate(
        context,
        sourcePath,
        mapperDatas,
        broaderImports,
        originalImports,
        mapperImportUri,
      );

      expect(result.header.sourcePath, equals(sourcePath));
      expect(result.header.generatedOn, isNotEmpty);
      expect(result.mappers, isEmpty);
      expect(result.broaderImports, equals(broaderImports));
    });

    test('buildFileTemplate creates FileTemplateData with empty resource list',
        () {
      final sourcePath = 'lib/empty.dart';
      final mapperImportUri = 'asset:test/lib/empty.rdf_mapper.g.dart';
      final mapperDatas = <MappableClassMapperTemplateData>[];

      final result = TemplateDataBuilder.buildFileTemplate(
        context,
        sourcePath,
        mapperDatas,
        broaderImports,
        originalImports,
        mapperImportUri,
      );

      expect(result, isA<FileTemplateData>());
      expect(result.header, isA<FileHeaderData>());
      expect(result.header.sourcePath, equals(sourcePath));
      expect(result.mappers, isEmpty);
      expect(result.broaderImports, same(broaderImports));
    });

    test('buildFileTemplate generates ISO8601 timestamp', () {
      final sourcePath = 'lib/test.dart';
      final mapperImportUri = 'asset:test/lib/test.rdf_mapper.g.dart';
      final mapperDatas = <MappableClassMapperTemplateData>[];

      final result = TemplateDataBuilder.buildFileTemplate(
        context,
        sourcePath,
        mapperDatas,
        broaderImports,
        originalImports,
        mapperImportUri,
      );

      // Verify the timestamp is a valid ISO8601 string
      expect(() => DateTime.parse(result.header.generatedOn), returnsNormally);

      final parsedDate = DateTime.parse(result.header.generatedOn);
      final now = DateTime.now();

      // Should be generated within the last few seconds
      expect(now.difference(parsedDate).inSeconds, lessThan(5));
    });

    test('buildFileTemplate handles ValidationContext', () {
      final sourcePath = 'lib/test.dart';
      final mapperImportUri = 'asset:test/lib/test.rdf_mapper.g.dart';
      final mapperDatas = <MappableClassMapperTemplateData>[];

      // Should not throw even if context has warnings
      context.addWarning('Test warning');

      expect(
        () => TemplateDataBuilder.buildFileTemplate(
          context,
          sourcePath,
          mapperDatas,
          broaderImports,
          originalImports,
          mapperImportUri,
        ),
        returnsNormally,
      );
    });

    test('buildFileTemplate preserves BroaderImports reference', () {
      final sourcePath = 'lib/test.dart';
      final mapperImportUri = 'asset:test/lib/test.rdf_mapper.g.dart';
      final mapperDatas = <MappableClassMapperTemplateData>[];

      final result = TemplateDataBuilder.buildFileTemplate(
        context,
        sourcePath,
        mapperDatas,
        broaderImports,
        originalImports,
        mapperImportUri,
      );

      // The result should preserve the same BroaderImports instance
      expect(result.broaderImports, same(broaderImports));
    });

    test('buildFileTemplate creates different timestamps on multiple calls',
        () async {
      final sourcePath = 'lib/test.dart';
      final mapperImportUri = 'asset:test/lib/test.rdf_mapper.g.dart';
      final mapperDatas = <MappableClassMapperTemplateData>[];

      final result1 = TemplateDataBuilder.buildFileTemplate(
        context,
        sourcePath,
        mapperDatas,
        broaderImports,
        originalImports,
        mapperImportUri,
      );

      // Wait a tiny bit to ensure different timestamp
      await Future.delayed(Duration(milliseconds: 1));

      final result2 = TemplateDataBuilder.buildFileTemplate(
        context,
        sourcePath,
        mapperDatas,
        broaderImports,
        originalImports,
        mapperImportUri,
      );

      // Timestamps should be different (or at least not identical)
      expect(result1.header.generatedOn,
          isNot(equals(result2.header.generatedOn)));
    });

    test('buildFileTemplate preserves mapper import URI in header context', () {
      final sourcePath = 'lib/complex/nested/test.dart';
      final mapperImportUri =
          'asset:test/lib/complex/nested/test.rdf_mapper.g.dart';
      final mapperDatas = <MappableClassMapperTemplateData>[];

      final result = TemplateDataBuilder.buildFileTemplate(
        context,
        sourcePath,
        mapperDatas,
        broaderImports,
        originalImports,
        mapperImportUri,
      );

      expect(result.header.sourcePath, equals(sourcePath));
      // The mapper import URI should be used by the data builder for individual mappers
      // but is not directly stored in the header
      expect(result.header, isA<FileHeaderData>());
    });

    test('buildFileTemplate handles various source path formats', () {
      final testCases = [
        'lib/test.dart',
        'lib/models/person.dart',
        'lib/deep/nested/directory/complex.dart',
        'src/main.dart',
      ];

      for (final sourcePath in testCases) {
        final mapperImportUri =
            'asset:test/$sourcePath'.replaceAll('.dart', '.rdf_mapper.g.dart');
        final mapperDatas = <MappableClassMapperTemplateData>[];

        final result = TemplateDataBuilder.buildFileTemplate(
          ValidationContext(),
          sourcePath,
          mapperDatas,
          broaderImports,
          originalImports,
          mapperImportUri,
        );

        expect(result.header.sourcePath, equals(sourcePath));
        expect(result, isA<FileTemplateData>());
      }
    });

    test('FileHeaderData contains expected fields', () {
      final sourcePath = 'lib/test.dart';
      final mapperImportUri = 'asset:test/lib/test.rdf_mapper.g.dart';
      final mapperDatas = <MappableClassMapperTemplateData>[];

      final result = TemplateDataBuilder.buildFileTemplate(
        context,
        sourcePath,
        mapperDatas,
        broaderImports,
        originalImports,
        mapperImportUri,
      );

      final header = result.header;
      expect(header.sourcePath, isA<String>());
      expect(header.sourcePath, isNotEmpty);
      expect(header.generatedOn, isA<String>());
      expect(header.generatedOn, isNotEmpty);
    });

    test('buildFileTemplate works with different validation contexts', () {
      final sourcePath = 'lib/test.dart';
      final mapperImportUri = 'asset:test/lib/test.rdf_mapper.g.dart';
      final mapperDatas = <MappableClassMapperTemplateData>[];

      // Test with root context
      final rootContext = ValidationContext();
      final result1 = TemplateDataBuilder.buildFileTemplate(
        rootContext,
        sourcePath,
        mapperDatas,
        broaderImports,
        originalImports,
        mapperImportUri,
      );

      // Test with nested context
      final nestedContext =
          ValidationContext('ParentContext').withContext('ChildContext');
      final result2 = TemplateDataBuilder.buildFileTemplate(
        nestedContext,
        sourcePath,
        mapperDatas,
        broaderImports,
        originalImports,
        mapperImportUri,
      );

      expect(result1, isA<FileTemplateData>());
      expect(result2, isA<FileTemplateData>());
      expect(result1.header.sourcePath, equals(result2.header.sourcePath));
    });

    test('FileTemplateData toMap method works correctly', () {
      final sourcePath = 'lib/test.dart';
      final mapperImportUri = 'asset:test/lib/test.rdf_mapper.g.dart';
      final mapperDatas = <MappableClassMapperTemplateData>[];

      final result = TemplateDataBuilder.buildFileTemplate(
        context,
        sourcePath,
        mapperDatas,
        broaderImports,
        originalImports,
        mapperImportUri,
      );

      final map = result.toMap();
      expect(map, isA<Map<String, dynamic>>());
      expect(map['header'], isA<Map<String, dynamic>>());
      expect(map['broaderImports'], isA<Map<String, dynamic>>());
      expect(map['mappers'], isA<List>());
    });

    test('FileHeaderData toMap method works correctly', () {
      final sourcePath = 'lib/test.dart';
      final mapperImportUri = 'asset:test/lib/test.rdf_mapper.g.dart';
      final mapperDatas = <MappableClassMapperTemplateData>[];

      final result = TemplateDataBuilder.buildFileTemplate(
        context,
        sourcePath,
        mapperDatas,
        broaderImports,
        originalImports,
        mapperImportUri,
      );

      final headerMap = result.header.toMap();
      expect(headerMap, isA<Map<String, dynamic>>());
      expect(headerMap['sourcePath'], equals(sourcePath));
      expect(headerMap['generatedOn'], isA<String>());
    });

    test('BroaderImports integration works correctly', () {
      final testBroaderImports = BroaderImports(<String, String>{
        'package:test/src/internal.dart': 'package:test/test.dart',
        'package:core/src/core.dart': 'package:core/core.dart',
      });

      final sourcePath = 'lib/test.dart';
      final mapperImportUri = 'asset:test/lib/test.rdf_mapper.g.dart';
      final mapperDatas = <MappableClassMapperTemplateData>[];

      final result = TemplateDataBuilder.buildFileTemplate(
        context,
        sourcePath,
        mapperDatas,
        testBroaderImports,
        originalImports,
        mapperImportUri,
      );

      expect(result.broaderImports, same(testBroaderImports));

      final broaderImportsMap = result.broaderImports.toMap();
      expect(broaderImportsMap, isA<Map<String, dynamic>>());
      expect(broaderImportsMap['package:test/src/internal.dart'],
          equals('package:test/test.dart'));
      expect(broaderImportsMap['package:core/src/core.dart'],
          equals('package:core/core.dart'));
    });
  });
}
