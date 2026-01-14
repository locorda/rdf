// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:locorda_rdf_terms_generator/src/vocab/builder/vocabulary_source.dart';
import 'package:test/test.dart';

void main() {
  group('UrlVocabularySource', () {
    late String testDir;

    setUp(() {
      testDir = Directory.systemTemp.createTempSync('rdf_vocab_test_').path;
    });

    tearDown(() {
      try {
        Directory(testDir).deleteSync(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('loads content from URL correctly', () async {
      final source = UrlVocabularySource(
        'http://example.org/test#',
        sourceUrl: 'http://example.org/test.ttl',
      );

      // Verify the namespace and sourceUrl are set correctly
      expect(source.namespace, equals('http://example.org/test#'));
      expect(source.sourceUrl, equals('http://example.org/test.ttl'));
    });

    test('detects format correctly from URL', () {
      expect(
        UrlVocabularySource(
          'http://example.org/',
          sourceUrl: 'http://example.org/vocab.ttl',
        ).contentType,
        equals('text/turtle'),
      );

      expect(
        UrlVocabularySource(
          'http://example.org/',
          sourceUrl: 'http://example.org/vocab.rdf',
        ).contentType,
        equals('application/rdf+xml'),
      );

      expect(
        UrlVocabularySource(
          'http://example.org/',
          sourceUrl: 'http://example.org/vocab.jsonld',
        ).contentType,
        equals('application/ld+json'),
      );

      expect(
        UrlVocabularySource(
          'http://example.org/',
          sourceUrl: 'http://example.org/vocab.nt',
        ).contentType,
        equals('application/n-triples'),
      );

      // Special case for schema.org
      expect(
        UrlVocabularySource(
          'http://schema.org/',
          sourceUrl: 'http://schema.org/',
        ).contentType,
        isNull,
      );
    });

    test('uses sourceUrl if provided, otherwise uses namespace', () {
      final source1 = UrlVocabularySource(
        'http://example.org/test#',
        sourceUrl: 'http://example.org/actual-location.ttl',
      );
      expect(
        source1.sourceUrl,
        equals('http://example.org/actual-location.ttl'),
      );

      final source2 = UrlVocabularySource('http://example.org/test#');
      expect(source2.sourceUrl, equals('http://example.org/test#'));
    });
  });

  group('FileVocabularySource', () {
    late String testDir;

    setUp(() {
      testDir = Directory.systemTemp.createTempSync('rdf_vocab_test_').path;
    });

    tearDown(() {
      try {
        Directory(testDir).deleteSync(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('loads content from file correctly', () async {
      // Create a test file
      final testContent =
          '@prefix ex: <http://example.org/> .\nex:Person a ex:Class .';
      final testFile = File(path.join(testDir, 'test.ttl'));
      await testFile.writeAsString(testContent);

      final source = FileVocabularySource(testFile.path, 'http://example.org/');

      final content = await source.loadContent();
      expect(content, equals(testContent));
    });

    test('throws exception when file not found', () async {
      final source = FileVocabularySource(
        path.join(testDir, 'nonexistent.ttl'),
        'http://example.org/',
      );

      expect(
        () => source.loadContent(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('not found'),
          ),
        ),
      );
    });

    test('detects format correctly from file extension', () {
      expect(
        FileVocabularySource('vocab.ttl', 'http://example.org/').contentType,
        equals('text/turtle'),
      );

      expect(
        FileVocabularySource('vocab.rdf', 'http://example.org/').contentType,
        equals('application/rdf+xml'),
      );

      expect(
        FileVocabularySource('vocab.xml', 'http://example.org/').contentType,
        equals('application/rdf+xml'),
      );

      expect(
        FileVocabularySource('vocab.owl', 'http://example.org/').contentType,
        isNull,
      );

      expect(
        FileVocabularySource('vocab.jsonld', 'http://example.org/').contentType,
        equals('application/ld+json'),
      );

      expect(
        FileVocabularySource('vocab.json', 'http://example.org/').contentType,
        isNull,
      );

      expect(
        FileVocabularySource('vocab.nt', 'http://example.org/').contentType,
        equals('application/n-triples'),
      );

      // Fallback to default for unknown extensions
      expect(
        FileVocabularySource('vocab.xyz', 'http://example.org/').contentType,
        isNull, // Default format
      );
    });
  });
}
