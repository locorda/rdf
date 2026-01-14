import 'dart:convert';

import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:locorda_rdf_mapper_generator/source_builder.dart';
import 'package:test/test.dart';

void main() {
  group('RdfMapperSourceBuilder Tests', () {
    late RdfMapperSourceBuilder builder;

    setUp(() {
      builder = RdfMapperSourceBuilder();
    });

    test('constructor creates a valid builder instance', () {
      expect(builder, isA<RdfMapperSourceBuilder>());
      expect(builder, isA<Builder>());
    });

    test('buildExtensions returns correct mapping', () {
      final extensions = builder.buildExtensions;
      expect(extensions, isA<Map<String, List<String>>>());
      expect(extensions['.locorda_rdf_mapper.cache.json'],
          equals(['.locorda_rdf_mapper.g.dart']));
    });

    test('rdfMapperSourceBuilder factory returns correct instance', () {
      final builderOptions = BuilderOptions({});
      final factoryBuilder = rdfMapperSourceBuilder(builderOptions);
      expect(factoryBuilder, isA<RdfMapperSourceBuilder>());
    });

    test('build method exists and accepts BuildStep', () {
      // This test verifies the method signature without actually executing the build
      expect(builder.build, isA<Function>());
      expect(builder.buildExtensions, isNotEmpty);
    });

    test('build extensions configuration is correct', () {
      final extensions = builder.buildExtensions;
      expect(extensions.keys, contains('.locorda_rdf_mapper.cache.json'));
      expect(extensions['.locorda_rdf_mapper.cache.json'],
          contains('.locorda_rdf_mapper.g.dart'));
    });

    test('factory method creates builder with options', () {
      final options = BuilderOptions({'test': 'value'});
      final factoryBuilder = rdfMapperSourceBuilder(options);

      expect(factoryBuilder, isA<RdfMapperSourceBuilder>());
      expect(factoryBuilder.buildExtensions, equals(builder.buildExtensions));
    });

    test('builder has correct build extensions mapping', () {
      expect(builder.buildExtensions, hasLength(1));
      expect(builder.buildExtensions.keys.first,
          equals('.locorda_rdf_mapper.cache.json'));
      expect(builder.buildExtensions.values.first,
          equals(['.locorda_rdf_mapper.g.dart']));
    });

    test('builder properly processes cache file extension', () {
      final extensions = builder.buildExtensions;
      final inputExtension = extensions.keys.first;
      final outputExtensions = extensions.values.first;

      expect(inputExtension, equals('.locorda_rdf_mapper.cache.json'));
      expect(outputExtensions, hasLength(1));
      expect(outputExtensions.first, equals('.locorda_rdf_mapper.g.dart'));
    });

    test('multiple instances are independent', () {
      final builder1 = rdfMapperSourceBuilder(BuilderOptions({}));
      final builder2 = rdfMapperSourceBuilder(BuilderOptions({}));

      expect(builder1, isA<RdfMapperSourceBuilder>());
      expect(builder2, isA<RdfMapperSourceBuilder>());
      expect(builder1.buildExtensions, equals(builder2.buildExtensions));
    });

    test('build extensions are immutable', () {
      final extensions = builder.buildExtensions;

      // Try to modify the extensions map (should not affect the builder)
      expect(() => extensions.clear(), throwsUnsupportedError);
    });

    // Helper method to create valid cache data for integration tests
    Map<String, dynamic> _createValidCacheData() {
      return {
        'mappers': [
          {
            'className': 'PersonMapper',
            'targetClassName': 'Person',
            'importUri': 'package:test/models.dart',
            'properties': [
              {
                'fieldName': 'name',
                'propertyType': 'literal',
                'predicateIri': 'http://example.org/name',
                'dartType': 'String?',
              }
            ],
            'subjectInfo': {
              'fieldName': 'iri',
              'dartType': 'String?',
            }
          }
        ],
        'imports': ['package:locorda_rdf_mapper_annotations/annotations.dart'],
      };
    }

    test('cache data structure validation helper works', () {
      final cacheData = _createValidCacheData();

      expect(cacheData, isA<Map<String, dynamic>>());
      expect(cacheData['mappers'], isA<List>());
      expect(cacheData['imports'], isA<List>());

      final mappers = cacheData['mappers'] as List;
      expect(mappers, hasLength(1));

      final mapper = mappers.first as Map<String, dynamic>;
      expect(mapper['className'], equals('PersonMapper'));
      expect(mapper['targetClassName'], equals('Person'));
      expect(mapper['properties'], isA<List>());
      expect(mapper['subjectInfo'], isA<Map>());
    });

    test('JSON serialization works for cache data', () {
      final cacheData = _createValidCacheData();
      final jsonString = jsonEncode(cacheData);

      expect(jsonString, isA<String>());
      expect(jsonString, isNotEmpty);

      // Verify round-trip serialization
      final decoded = jsonDecode(jsonString);
      expect(decoded, equals(cacheData));
    });
  });

  group('buildIt method tests', () {
    late RdfMapperSourceBuilder builder;

    setUp(() {
      builder = RdfMapperSourceBuilder();
    });

    test('buildIt processes cache file and generates source code', () async {
      // Create simpler cache data that mimics the processed output after code resolution
      final cacheData = {
        'header': {
          'sourcePath':
              'test/fixtures/global_resource_processor_test_models.dart',
          'generatedOn': DateTime.now().toIso8601String(),
        },
        'broaderImports': <String, String>{},
        'imports': [
          'package:locorda_rdf_core/core.dart',
          'package:locorda_rdf_mapper/mapper.dart'
        ],
        'mappers': [
          {
            '__type__': 'ResourceMapperTemplateData',
            'className': 'Book',
            'mapperClassName': 'BookMapper',
            'mapperInterfaceName': 'GlobalResourceMapper<Book>',
            'termClass': 'IriTerm',
            'typeIri': 'SchemaBook.classIri',
            'hasTypeIri': true,
            'registerGlobally': true,
            'needsReader': true
          }
        ]
      };

      final inputPath =
          'test/fixtures/global_resource_processor_test_models.locorda_rdf_mapper.cache.json';
      final cacheJson = jsonEncode(cacheData);

      // Capture the written content
      String? writtenContent;
      AssetId? writtenAssetId;

      await builder.buildIt(
        AssetId('test', inputPath),
        (id, {Encoding? encoding}) async {
          // Return the cache file content
          expect(id.path, equals(inputPath));
          return cacheJson;
        },
        (id, contents, {Encoding? encoding}) async {
          // Capture what gets written
          writtenAssetId = id;
          writtenContent = await contents;
        },
        // Mock AssetReader for template rendering
        _MockAssetReader(),
      );

      // Verify the source file was written
      expect(writtenAssetId, isNotNull);
      expect(writtenAssetId!.path, endsWith('.locorda_rdf_mapper.g.dart'));
      expect(
          writtenAssetId!.path,
          equals(
              'test/fixtures/global_resource_processor_test_models.locorda_rdf_mapper.g.dart'));
      expect(writtenContent, isNotNull);
      expect(writtenContent!, isNotEmpty);

      // Verify the generated code contains expected elements
      expect(writtenContent!, contains('class BookMapper'));
      expect(
          writtenContent!, contains('implements GlobalResourceMapper<Book>'));
      expect(
          writtenContent!, contains('GENERATED CODE - DO NOT MODIFY BY HAND'));
      expect(
          writtenContent!,
          contains(
              'Source: test/fixtures/global_resource_processor_test_models.dart'));
    });

    test('buildIt skips non-cache files', () async {
      final builder = RdfMapperSourceBuilder();
      bool wasReadCalled = false;
      bool wasWriteCalled = false;

      await builder.buildIt(
        AssetId('test', 'some/other/file.dart'),
        (id, {Encoding? encoding}) async {
          wasReadCalled = true;
          return 'content';
        },
        (id, contents, {Encoding? encoding}) async {
          wasWriteCalled = true;
        },
        _MockAssetReader(),
      );

      expect(wasReadCalled, isFalse, reason: 'Should not read non-cache files');
      expect(wasWriteCalled, isFalse,
          reason: 'Should not write for non-cache files');
    });
  });
}

/// Mock AssetReader for testing template rendering
class _MockAssetReader implements AssetReader {
  @override
  Future<bool> canRead(AssetId id) async => true;

  @override
  Future<List<int>> readAsBytes(AssetId id) async {
    final content = await readAsString(id);
    return content.codeUnits;
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async {
    // Return actual template content based on the file name
    if (id.path.endsWith('file_template.mustache')) {
      return '''{{#header}}
// GENERATED CODE - DO NOT MODIFY BY HAND
// 
// This file was generated by the RDF Mapper Generator.
// Source: {{sourcePath}}

{{/header}}
{{#imports}}
import '{{{.}}}';
{{/imports}}

{{#mappers}}
{{{mapperCode}}}

{{/mappers}}
''';
    } else if (id.path.endsWith('resource_mapper.mustache')) {
      return '''/// Generated mapper for [{{className}}] global resources.
class {{mapperClassName}} implements {{mapperInterfaceName}} {
  // Generated resource mapper implementation
  @override
  {{className}} fromRdfResource({{termClass}} subject, DeserializationContext context) {
    // Implementation details...
    throw UnimplementedError();
  }
}
''';
    } else if (id.path.endsWith('iri_mapper.mustache')) {
      return '''/// Generated mapper for [{{className}}] iri terms.
class {{mapperClassName}} implements {{mapperInterfaceName}} {
  // Generated IRI mapper implementation
}
''';
    } else if (id.path.endsWith('literal_mapper.mustache')) {
      return '''/// Generated mapper for [{{className}}] literal terms.
class {{mapperClassName}} implements {{mapperInterfaceName}} {
  // Generated literal mapper implementation
}
''';
    }
    return '';
  }

  @override
  Future<Digest> digest(AssetId id) async {
    final content = await readAsString(id);
    final hash = md5.convert(utf8.encode(content));
    return Digest(hash.bytes);
  }

  @override
  Stream<AssetId> findAssets(Glob glob) async* {
    // Return empty stream for testing
  }
}
