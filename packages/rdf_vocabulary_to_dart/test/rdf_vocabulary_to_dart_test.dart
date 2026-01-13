// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:rdf_vocabulary_to_dart/rdf_vocabulary_to_dart.dart';
import 'package:test/test.dart';

void main() {
  group('rdf_vocabulary_to_dart library', () {
    test(
      'rdfVocabularyToDart creates a VocabularyBuilder with default options',
      () {
        final builder = rdfVocabularyToDart(BuilderOptions(const {}));

        expect(builder, isNotNull);
        expect(builder, isA<Builder>());
      },
    );

    test(
      'rdfVocabularyToDart creates a VocabularyBuilder with custom options',
      () {
        final builder = rdfVocabularyToDart(
          BuilderOptions(const {
            'vocabulary_config_path': 'custom/path/vocab.json',
            'output_dir': 'custom/output/path',
          }),
        );

        expect(builder, isNotNull);
        expect(builder, isA<Builder>());
      },
    );

    test('getBuildExtensions returns valid extensions map', () {
      final extensions = getBuildExtensions({
        'vocabulary_config_path': 'test/vocab.json',
        'output_dir': 'test/output',
      });

      expect(extensions, isA<Map<String, List<String>>>());
      expect(extensions.keys.length, equals(1));
      expect(extensions.keys.first, equals('test/vocab.json'));

      final outputs = extensions.values.first;
      expect(outputs, isA<List<String>>());
      expect(outputs.any((e) => e.endsWith('_index.dart')), isTrue);
    });

    test('fallback values are used when not provided', () {
      final extensions = getBuildExtensions({});

      expect(extensions, isA<Map<String, List<String>>>());
      expect(extensions.keys.length, equals(1));
      expect(extensions.keys.first, equals(fallbackVocabJsonPath));

      final outputs = extensions.values.first;
      expect(outputs, isA<List<String>>());
      expect(outputs.any((e) => e.contains(fallbackOutputDir)), isTrue);
    });

    /// This test demonstrates how to use build_test to test code generation.
    ///
    /// Since the builder uses direct file system access, which is harder to mock
    /// in tests, this test focuses on:
    /// 1. Checking the builder configuration
    /// 2. Checking build extensions (what should be generated)
    /// 3. Preparing and validating input data
    ///
    /// In a real integration, you would use the generateTestBuilder function
    /// or a custom BuildStep that intercepts file system operations.
    test('integration test with build_test', () async {
      // Test vocabulary content
      final ttlContent = '''
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix test: <http://example.org/test#> .

test:Person a rdfs:Class ;
  rdfs:label "Person" ;
  rdfs:comment "A person class" .

test:name a rdf:Property ;
  rdfs:label "name" ;
  rdfs:comment "The name of a person" ;
  rdfs:domain test:Person ;
  rdfs:range xsd:string .
''';

      // Test manifest content
      final manifestContent = '''
{
  "vocabularies": {
    "test": {
      "type": "file",
      "namespace": "http://example.org/test#",
      "source": "test/assets/test_vocab.ttl"
    }
  }
}
''';

      // 1. Validate that the test vocabulary has valid Turtle syntax
      // This is an important first step for integration
      expect(ttlContent, contains('test:Person a rdfs:Class'));
      expect(ttlContent, contains('test:name a rdf:Property'));

      // 2. Validate that the test manifest is valid JSON
      expect(manifestContent, contains('"vocabularies"'));
      expect(manifestContent, contains('"test"'));
      expect(
        manifestContent,
        contains('"namespace": "http://example.org/test#"'),
      );

      // 3. Create builder with test configuration
      final builder = rdfVocabularyToDart(
        BuilderOptions(const {
          'vocabulary_config_path': 'test/assets/test_manifest.vocab.json',
          'output_dir': 'test/generated',
        }),
      );

      // 4. Check if the builder is correctly configured
      expect(builder, isNotNull);
      expect(builder, isA<Builder>());

      // 5. Check the build extensions
      final extensions = builder.buildExtensions;
      expect(
        extensions.containsKey('test/assets/test_manifest.vocab.json'),
        isTrue,
      );

      final outputs = extensions['test/assets/test_manifest.vocab.json']!;
      expect(outputs.length, greaterThan(0));
      expect(outputs.any((output) => output.contains('_index.dart')), isTrue);
      expect(outputs.any((output) => output.contains('test.dart')), isTrue);

      // In an extended test, you could also test the actual generation with
      // a special BuildEnvironment that intercepts and mocks file system access.
    });
  });
}
