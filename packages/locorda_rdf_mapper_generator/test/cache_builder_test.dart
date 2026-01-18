import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:locorda_rdf_mapper_generator/cache_builder.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

void main() {
  group('RdfMapperCacheBuilder Tests', () {
    late RdfMapperCacheBuilder builder;

    setUp(() {
      builder = RdfMapperCacheBuilder();
    });

    test('constructor creates a valid builder instance', () {
      expect(builder, isA<RdfMapperCacheBuilder>());
      expect(builder, isA<Builder>());
    });

    test('buildExtensions returns correct mapping', () {
      final extensions = builder.buildExtensions;
      expect(extensions, isA<Map<String, List<String>>>());
      expect(extensions['.dart'], equals(['.rdf_mapper.cache.json']));
    });

    test('rdfMapperCacheBuilder factory returns correct instance', () {
      final builderOptions = BuilderOptions({});
      final factoryBuilder = rdfMapperCacheBuilder(builderOptions);
      expect(factoryBuilder, isA<RdfMapperCacheBuilder>());
    });

    // The following tests use actual file analysis which requires full build environment
    // These can be considered integration tests and may need proper build configuration

    test('build method exists and accepts BuildStep', () {
      // This test verifies the method signature without actually executing the build
      expect(builder.build, isA<Function>());
      expect(builder.buildExtensions, isNotEmpty);
    });

    test('build extensions configuration is correct', () {
      final extensions = builder.buildExtensions;
      expect(extensions.keys, contains('.dart'));
      expect(extensions['.dart'], contains('.rdf_mapper.cache.json'));
    });

    test('factory method creates builder with options', () {
      final options = BuilderOptions({'test': 'value'});
      final factoryBuilder = rdfMapperCacheBuilder(options);

      expect(factoryBuilder, isA<RdfMapperCacheBuilder>());
      expect(factoryBuilder.buildExtensions, equals(builder.buildExtensions));
    });

    test('builder has correct build extensions mapping', () {
      expect(builder.buildExtensions, hasLength(1));
      expect(builder.buildExtensions.keys.first, equals('.dart'));
      expect(builder.buildExtensions.values.first,
          equals(['.rdf_mapper.cache.json']));
    });
  });
  group('buildIt method tests', () {
    late RdfMapperCacheBuilder builder;

    setUp(() {
      builder = RdfMapperCacheBuilder();
    });

    test('buildIt processes test file and generates cache', () async {
      final (libraryElement, testFilePath) =
          await analyzeTestFile('global_resource_processor_test_models.dart');

      // Convert absolute path to relative path for AssetId
      final relativePath = testFilePath.contains('test/fixtures/')
          ? testFilePath.substring(testFilePath.indexOf('test/fixtures/'))
          : 'test/fixtures/global_resource_processor_test_models.dart';

      // Mock readAsString to return the actual file content
      final sourceFile = File(testFilePath);
      final actualContent = await sourceFile.readAsString();

      // Capture the written content
      String? writtenContent;
      AssetId? writtenAssetId;

      await builder.buildIt(
        AssetId('test', relativePath),
        (id, {Encoding? encoding}) async {
          // Return the actual source file content for analysis
          expect(id.path, equals(relativePath));
          return actualContent;
        },
        (id, contents, {Encoding? encoding}) async {
          // Capture what gets written
          writtenAssetId = id;
          writtenContent = await contents;
        },
        (assetId, {allowSyntaxErrors = false}) async {
          expect(assetId.path, equals(relativePath));
          return libraryElement;
        },
      );

      // Verify the cache file was written
      expect(writtenAssetId, isNotNull);
      expect(writtenAssetId!.path, endsWith('.rdf_mapper.cache.json'));
      expect(writtenContent, isNotNull);

      // Parse and validate the JSON content
      final jsonData = jsonDecode(writtenContent!) as Map<String, dynamic>;

      // Verify basic structure of cache data
      expect(jsonData, isA<Map<String, dynamic>>());
      expect(jsonData.keys, contains('header'));
      expect(jsonData.keys, contains('mappers'));
      expect(jsonData.keys, contains('broaderImports'));

      // Verify header information
      final header = jsonData['header'] as Map<String, dynamic>;
      expect(header['sourcePath'], isA<String>());
      expect(header['generatedOn'], isA<String>());

      // Verify mappers were generated for the test classes
      final mappers = jsonData['mappers'] as List;
      expect(mappers, isNotEmpty,
          reason: 'Should generate mappers for RDF annotated classes');

      // Verify mapper data structure
      for (final mapper in mappers) {
        final mapperData = mapper as Map<String, dynamic>;
        expect(mapperData.keys, contains('__type__'));
        expect(mapperData.keys, contains('className'));
        expect(mapperData.keys, contains('registerGlobally'));

        final mapperType = mapperData['__type__'] as String;
        expect([
          'ResourceMapperTemplateData',
          'IriMapperTemplateData',
          'LiteralMapperTemplateData',
          'CustomMapperTemplateData'
        ], contains(mapperType));

        // Different mapper types have different required fields
        if (mapperType == 'CustomMapperTemplateData') {
          expect(mapperData.keys, contains('mapperInterfaceType'));
        } else {
          expect(mapperData.keys, contains('mapperClassName'));
        }
      }
    });
  });
}
