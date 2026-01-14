// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:locorda_rdf_terms_generator/src/vocab/builder/class_generator.dart';
import 'package:locorda_rdf_terms_generator/src/vocab/builder/cross_vocabulary_resolver.dart';
import 'package:locorda_rdf_terms_generator/src/vocab/builder/model/vocabulary_model.dart';
import 'package:test/test.dart';

import 'class_generator_test.mocks.dart';
import '../test_vocabulary_source.dart';

Future<AssetReader> createTestAssetReader() async {
  final readerWriter = TestReaderWriter();
  await readerWriter.testing.loadIsolateSources();
  return readerWriter;
}

@GenerateMocks([CrossVocabularyResolver])
void main() {
  group('VocabularyClassGenerator', () {
    late MockCrossVocabularyResolver mockResolver;
    late VocabularyClassGenerator generator;
    late VocabularyModel testModel;
    late AssetReader assetReader;
    late TestVocabularySource source;
    setUp(() async {
      mockResolver = MockCrossVocabularyResolver();
      assetReader = await createTestAssetReader();
      source = TestVocabularySource('http://example.org/test#');
      generator = VocabularyClassGenerator(
        resolver: mockResolver,
        outputDir: 'lib/src/vocab/generated',
      );

      // Create a basic test model
      testModel = VocabularyModel(
        name: 'Test',
        namespace: 'http://example.org/test#',
        prefix: 'test',
        classes: [
          VocabularyClass(
            localName: 'Person',
            iri: 'http://example.org/test#Person',
            label: 'Person',
            comment: 'A person class for testing',
            superClasses: ['http://example.org/test#Agent'],
            seeAlso: ['http://example.org/docs/Person'],
          ),
        ],
        properties: [
          VocabularyProperty(
            localName: 'name',
            iri: 'http://example.org/test#name',
            label: 'name',
            comment: 'The name of a person',
            domains: ['http://example.org/test#Person'],
            ranges: ['http://www.w3.org/2001/XMLSchema#string'],
          ),
          VocabularyProperty(
            localName: 'universalProp',
            iri: 'http://example.org/test#universalProp',
            label: 'Universal Property',
            comment: 'A property with no domain constraints',
            domains: [],
            ranges: ['http://www.w3.org/2001/XMLSchema#string'],
          ),
        ],
        datatypes: [
          VocabularyDatatype(
            localName: 'EmailAddress',
            iri: 'http://example.org/test#EmailAddress',
            label: 'Email Address',
            comment: 'An email address datatype',
          ),
        ],
        otherTerms: [
          VocabularyTerm(
            localName: 'OtherTerm',
            iri: 'http://example.org/test#OtherTerm',
            label: 'Other Term',
            comment:
                'Some other term that is not a class, property, or datatype',
          ),
        ],
        source: source,
      );

      // Set up resolver behavior
      when(
        mockResolver.getPropertiesForClass(
          'http://example.org/test#Person',
          'http://example.org/test#',
        ),
      ).thenReturn([
        testModel.properties[0], // name property
      ]);
      when(
        mockResolver.getAllClassTypes('http://example.org/test#Person'),
      ).thenReturn({
        testModel.classes[0].iri,
        ...testModel.classes[0].superClasses,
      });
      when(
        mockResolver.getAllSuperClasses('http://example.org/test#Person'),
      ).thenReturn({...testModel.classes[0].superClasses});
      when(
        mockResolver.getAllEquivalentClasses('http://example.org/test#Person'),
      ).thenReturn(<String>{});
      when(
        mockResolver.getAllEquivalentClassSuperClasses(
          'http://example.org/test#Person',
        ),
      ).thenReturn(<String>{});
    });

    test('generates primary vocabulary class correctly', () async {
      final code = await generator.generate(testModel, assetReader);

      // Verify the code contains the class definition
      expect(code, contains('class Test {'));
      expect(
        code,
        contains("static const String namespace = 'http://example.org/test#';"),
      );
      expect(code, contains("static const String prefix = 'test';"));

      // Verify class constants
      expect(
        code,
        contains(
          "static const Person = IriTerm('http://example.org/test#Person')",
        ),
      );

      // Verify property constants
      expect(
        code,
        contains("static const name = IriTerm('http://example.org/test#name')"),
      );

      // Verify datatype constants
      expect(
        code,
        contains(
          "static const EmailAddress = IriTerm('http://example.org/test#EmailAddress')",
        ),
      );

      // Verify other term constants
      expect(
        code,
        contains(
          "static const OtherTerm = IriTerm('http://example.org/test#OtherTerm')",
        ),
      );
    });

    test('generates RDF class-specific classes correctly', () async {
      final code = await generator.generate(testModel, assetReader);

      // Verify Person class is generated
      expect(code, contains('class TestPerson {'));
      expect(
        code,
        contains(
          "static const classIri = IriTerm('http://example.org/test#Person');",
        ),
      );

      // Verify class contains properties from resolver
      expect(
        code,
        contains(
          "static const name = IriTerm('http://example.org/test#name');",
        ),
      );

      // Verify the resolver was called correctly
      verify(
        mockResolver.getPropertiesForClass(
          'http://example.org/test#Person',
          'http://example.org/test#',
        ),
      ).called(1);
    });

    test(
      'generates UniversalProperties class when properties with no domains exist',
      () async {
        final code = await generator.generate(testModel, assetReader);

        // Verify UniversalProperties class is generated
        expect(code, contains('class TestUniversalProperties {'));
        expect(
          code,
          contains(
            "static const universalProp = IriTerm('http://example.org/test#universalProp');",
          ),
        );
      },
    );

    test('throws error for empty vocabulary', () {
      final emptyModel = VocabularyModel(
        name: 'Empty',
        namespace: 'http://example.org/empty#',
        prefix: 'empty',
        classes: [],
        properties: [],
        datatypes: [],
        otherTerms: [],
        source: source,
      );

      expect(
        () async => await generator.generate(emptyModel, assetReader),
        throwsStateError,
      );
    });

    test('properly handles comments and documentation', () async {
      final code = await generator.generate(testModel, assetReader);

      // Check class documentation
      expect(code, contains('/// A person class for testing'));

      // Check property documentation
      expect(code, contains('/// The name of a person'));

      // Check datatype documentation
      expect(code, contains('/// An email address datatype'));
    });

    test('properly formats documentation with See Also references', () async {
      final code = await generator.generate(testModel, assetReader);

      // Check for seeAlso references
      expect(code, contains('[See also](http://example.org/docs/Person)'));
    });

    test('adds domain and range documentation for properties', () async {
      final code = await generator.generate(testModel, assetReader);

      // Check for domain information
      expect(code, contains('Can be used on: http://example.org/test#Person'));

      // Check for range information
      expect(
        code,
        contains('Expects: http://www.w3.org/2001/XMLSchema#string'),
      );
    });
  });
}
