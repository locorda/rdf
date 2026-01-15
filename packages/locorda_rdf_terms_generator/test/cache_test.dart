// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:io';
import 'package:test/test.dart';
import 'package:locorda_rdf_terms_generator/src/vocab/builder/vocabulary_source.dart';

void main() {
  group('CachedVocabularySource', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('vocab_cache_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should cache downloaded content', () async {
      final cacheDir = tempDir.path;
      const namespace = 'http://example.org/vocab#';

      // Create a mock UrlVocabularySource that returns test content
      final mockSource = _MockVocabularySource(
        namespace,
        content:
            '@prefix ex: <http://example.org/vocab#> .\nex:TestClass a rdfs:Class .',
      );

      final cachedSource = CachedVocabularySource(
        mockSource,
        cacheDir,
        'test_vocab',
      );

      // First load should call the inner source
      final content1 = await cachedSource.loadContent();
      expect(content1, contains('TestClass'));
      expect(mockSource.loadCount, equals(1));

      // Check that cache file was created
      final cacheFile = File('$cacheDir/test_vocab.ttl');
      expect(cacheFile.existsSync(), isTrue);
      expect(await cacheFile.readAsString(), equals(content1));

      // Second load should read from cache
      final cachedSource2 = CachedVocabularySource(
        mockSource,
        cacheDir,
        'test_vocab',
      );
      final content2 = await cachedSource2.loadContent();
      expect(content2, equals(content1));
      expect(
        mockSource.loadCount,
        equals(1),
        reason: 'Should not load again from source',
      );
    });

    test('should handle cache miss correctly', () async {
      final cacheDir = tempDir.path;
      const namespace = 'http://example.org/vocab#';

      final mockSource = _MockVocabularySource(
        namespace,
        content: 'test content',
      );
      final cachedSource = CachedVocabularySource(
        mockSource,
        cacheDir,
        'test_vocab',
      );

      // First load with empty cache
      final content = await cachedSource.loadContent();
      expect(content, equals('test content'));
      expect(mockSource.loadCount, equals(1));
    });

    test('should use correct cache file name pattern', () async {
      final cacheDir = tempDir.path;
      const namespace = 'http://schema.org/';

      final mockSource = _MockVocabularySource(namespace, content: 'test');
      final cachedSource = CachedVocabularySource(
        mockSource,
        cacheDir,
        'schema_org',
      );

      await cachedSource.loadContent();

      // Check that file follows {name}.{extension} pattern
      final expectedFile = File('$cacheDir/schema_org.ttl');
      expect(expectedFile.existsSync(), isTrue);
    });

    test('should delegate properties to inner source', () {
      final cacheDir = tempDir.path;
      const namespace = 'http://example.org/vocab#';

      final mockSource = _MockVocabularySource(
        namespace,
        content: 'test',
        parsingFlags: ['flag1', 'flag2'],
      );

      final cachedSource = CachedVocabularySource(
        mockSource,
        cacheDir,
        'test_vocab',
      );

      expect(cachedSource.namespace, equals(namespace));
      expect(cachedSource.parsingFlags, equals(['flag1', 'flag2']));
      expect(cachedSource.extension, equals('.ttl'));
    });
  });
}

/// Mock vocabulary source for testing
class _MockVocabularySource extends VocabularySource {
  final String content;
  int loadCount = 0;

  _MockVocabularySource(
    String namespace, {
    required this.content,
    List<String>? parsingFlags,
  }) : super(namespace, parsingFlags: parsingFlags);

  @override
  Future<String> loadContent() async {
    loadCount++;
    return content;
  }

  @override
  String get extension => '.ttl';
}
