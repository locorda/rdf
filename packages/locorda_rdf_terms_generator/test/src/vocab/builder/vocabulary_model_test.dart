// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_terms_generator/src/vocab/builder/model/vocabulary_model.dart';
import 'package:test/test.dart';
import '../test_vocabulary_source.dart';

void main() {
  group('VocabularyModelExtractor', () {
    late RdfGraph testGraph;
    const testNamespace = 'http://example.org/test#';
    const testName = 'test';
    late TestVocabularySource source;
    setUp(() {
      source = TestVocabularySource(testNamespace);

      // Create a test graph with some common vocabulary patterns
      testGraph = RdfGraph(
        triples: [
          // Define a test class
          Triple(
            const IriTerm('${testNamespace}Person'),
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#Class'),
          ),
          Triple(
            const IriTerm('${testNamespace}Person'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#label'),
            LiteralTerm.string('Person'),
          ),
          Triple(
            const IriTerm('${testNamespace}Person'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#comment'),
            LiteralTerm.string('A person (alive, dead, undead, or fictional).'),
          ),
          Triple(
            const IriTerm('${testNamespace}Person'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#subClassOf'),
            const IriTerm('${testNamespace}Agent'),
          ),

          // Define a test property
          Triple(
            const IriTerm('${testNamespace}name'),
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            const IriTerm(
              'http://www.w3.org/1999/02/22-rdf-syntax-ns#Property',
            ),
          ),
          Triple(
            const IriTerm('${testNamespace}name'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#label'),
            LiteralTerm.string('name'),
          ),
          Triple(
            const IriTerm('${testNamespace}name'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#comment'),
            LiteralTerm.string('The name of the entity.'),
          ),
          Triple(
            const IriTerm('${testNamespace}name'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#domain'),
            const IriTerm('${testNamespace}Person'),
          ),
          Triple(
            const IriTerm('${testNamespace}name'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#range'),
            const IriTerm('http://www.w3.org/2001/XMLSchema#string'),
          ),

          // Define a test datatype
          Triple(
            const IriTerm('${testNamespace}EmailAddress'),
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#Datatype'),
          ),
          Triple(
            const IriTerm('${testNamespace}EmailAddress'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#label'),
            LiteralTerm.string('Email Address'),
          ),
          Triple(
            const IriTerm('${testNamespace}EmailAddress'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#comment'),
            LiteralTerm.string('An email address.'),
          ),

          // Define a reference using seeAlso
          Triple(
            const IriTerm('${testNamespace}Person'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#seeAlso'),
            const IriTerm('http://example.org/docs/Person'),
          ),
        ],
      );
    });

    test('extracts vocabulary model correctly from RDF graph', () {
      final model = VocabularyModelExtractor.extractFrom(
        testGraph,
        testNamespace,
        testName,
        source,
      );

      // Test basic properties
      expect(model.name, equals(testName));
      expect(model.namespace, equals(testNamespace));
      expect(model.prefix, equals(testName.toLowerCase()));

      // Test classes
      expect(model.classes.length, equals(1));
      final personClass = model.classes.first;
      expect(personClass.localName, equals('Person'));
      expect(personClass.iri, equals('${testNamespace}Person'));
      expect(personClass.label, equals('Person'));
      expect(
        personClass.comment,
        equals('A person (alive, dead, undead, or fictional).'),
      );
      expect(personClass.superClasses.length, equals(2));
      expect(
        personClass.superClasses.toSet(),
        equals({
          '${testNamespace}Agent',
          'http://www.w3.org/2000/01/rdf-schema#Resource',
        }),
      );
      expect(personClass.seeAlso.length, equals(1));
      expect(
        personClass.seeAlso.first,
        equals('http://example.org/docs/Person'),
      );

      // Test properties
      expect(model.properties.length, equals(1));
      final nameProperty = model.properties.first;
      expect(nameProperty.localName, equals('name'));
      expect(nameProperty.iri, equals('${testNamespace}name'));
      expect(nameProperty.label, equals('name'));
      expect(nameProperty.comment, equals('The name of the entity.'));
      expect(nameProperty.domains.length, equals(1));
      expect(nameProperty.domains.first, equals('${testNamespace}Person'));
      expect(nameProperty.ranges.length, equals(1));
      expect(
        nameProperty.ranges.first,
        equals('http://www.w3.org/2001/XMLSchema#string'),
      );

      // Test datatypes
      expect(model.datatypes.length, equals(1));
      final emailDatatype = model.datatypes.first;
      expect(emailDatatype.localName, equals('EmailAddress'));
      expect(emailDatatype.iri, equals('${testNamespace}EmailAddress'));
      expect(emailDatatype.label, equals('Email Address'));
      expect(emailDatatype.comment, equals('An email address.'));
    });

    test('correctly handles invalid identifiers', () {
      // Add a resource with an invalid identifier
      final graphWithInvalidIdentifier = RdfGraph(
        triples: [
          ...testGraph.triples,
          Triple(
            const IriTerm('${testNamespace}123-invalid'),
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#Class'),
          ),
        ],
      );

      final model = VocabularyModelExtractor.extractFrom(
        graphWithInvalidIdentifier,
        testNamespace,
        testName,
        source,
      );

      // Find the sanitized identifier (should start with 'n' to avoid starting with a number)
      final invalidClass = model.classes.where(
        (c) => c.iri == '${testNamespace}123-invalid',
      );

      // The sanitizer should either sanitize it properly or skip it if it can't be sanitized
      if (invalidClass.isNotEmpty) {
        expect(invalidClass.first.localName, equals('n123_invalid'));
      }
    });

    test('excludes URIs that match exclusion patterns', () {
      // Add resources that should be excluded
      final graphWithExcludedUris = RdfGraph(
        triples: [
          ...testGraph.triples,
          Triple(
            const IriTerm('${testNamespace}#'),
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#Class'),
          ),
          Triple(
            const IriTerm('${testNamespace}xml-syntax'),
            const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
            const IriTerm('http://www.w3.org/2000/01/rdf-schema#Class'),
          ),
        ],
      );

      final model = VocabularyModelExtractor.extractFrom(
        graphWithExcludedUris,
        testNamespace,
        testName,
        source,
      );

      // The excluded URIs should not appear in the model
      expect(model.classes.any((c) => c.iri == '${testNamespace}#'), isFalse);
      expect(
        model.classes.any((c) => c.iri == '${testNamespace}xml-syntax'),
        isFalse,
      );
    });
  });

  group('VocabularyTerm', () {
    test('constructs with required and optional parameters', () {
      const term = VocabularyTerm(
        localName: 'test',
        iri: 'http://example.org/test',
        label: 'Test Label',
        comment: 'Test Comment',
        seeAlso: ['http://example.org/docs/test'],
      );

      expect(term.localName, equals('test'));
      expect(term.iri, equals('http://example.org/test'));
      expect(term.label, equals('Test Label'));
      expect(term.comment, equals('Test Comment'));
      expect(term.seeAlso, equals(['http://example.org/docs/test']));
    });

    test('constructs with only required parameters', () {
      const term = VocabularyTerm(
        localName: 'test',
        iri: 'http://example.org/test',
      );

      expect(term.localName, equals('test'));
      expect(term.iri, equals('http://example.org/test'));
      expect(term.label, isNull);
      expect(term.comment, isNull);
      expect(term.seeAlso, isEmpty);
    });
  });

  group('VocabularyClass', () {
    test('constructs with superclasses', () {
      final vocabularyClass = VocabularyClass(
        localName: 'Person',
        iri: 'http://example.org/Person',
        superClasses: ['http://example.org/Agent', 'http://example.org/Thing'],
      );

      expect(vocabularyClass.localName, equals('Person'));
      expect(vocabularyClass.iri, equals('http://example.org/Person'));
      expect(
        vocabularyClass.superClasses,
        equals(['http://example.org/Agent', 'http://example.org/Thing']),
      );
    });
  });

  group('VocabularyProperty', () {
    test('constructs with domains and ranges', () {
      const property = VocabularyProperty(
        localName: 'name',
        iri: 'http://example.org/name',
        domains: ['http://example.org/Person'],
        ranges: ['http://www.w3.org/2001/XMLSchema#string'],
      );

      expect(property.localName, equals('name'));
      expect(property.iri, equals('http://example.org/name'));
      expect(property.domains, equals(['http://example.org/Person']));
      expect(
        property.ranges,
        equals(['http://www.w3.org/2001/XMLSchema#string']),
      );
    });
  });

  group('VocabularyDatatype', () {
    test('constructs correctly', () {
      const datatype = VocabularyDatatype(
        localName: 'EmailAddress',
        iri: 'http://example.org/EmailAddress',
      );

      expect(datatype.localName, equals('EmailAddress'));
      expect(datatype.iri, equals('http://example.org/EmailAddress'));
    });
  });
}
