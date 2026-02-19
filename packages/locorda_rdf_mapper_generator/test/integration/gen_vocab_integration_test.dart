import 'dart:io';
import 'dart:convert';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_terms_core/rdf.dart';
import 'package:locorda_rdf_terms_core/rdfs.dart';
import 'package:test/test.dart';

void main() {
  group('define end-to-end integration', () {
    test('build_runner generates mapper and vocabulary outputs',
        tags: ['build-runner', 'slow'], () async {
      final result = await Process.run(
        'dart',
        ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
        workingDirectory: Directory.current.path,
      );

      if (result.exitCode != 0) {
        fail(
            'build_runner failed:\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}');
      }

      expect(result.exitCode, equals(0));
    });

    test('generated mapper file contains all define mappers', () {
      final mapperFile = File(
          'test/fixtures/gen_vocab_processor_test_models.rdf_mapper.g.dart');
      expect(mapperFile.existsSync(), isTrue,
          reason: 'Expected generated mapper file after build_runner run');

      final content = mapperFile.readAsStringSync();
      expect(content, contains('class GenVocabBookMapper'));
      expect(content, contains('class GenVocabLibraryItemMapper'));
      expect(content, contains('class GenVocabContractMapper'));
      expect(content, contains('class GenVocabMultilingualProductMapper'));
      expect(content, contains('class GenVocabArticleMapper'));
      expect(content, contains('class GenVocabPropertyTypeOverrideMapper'));

      expect(content, contains('https://example.com/vocab#displayTitle'));
      expect(content, contains('https://example.com/vocab#publicationDate'));
      expect(content, contains('https://example.com/contracts#signedAt'));
      expect(content, contains('https://example.com/vocab#viewCount'));
      expect(content, contains('https://example.com/vocab#internalNotes'));
      expect(content, contains('https://example.com/vocab#wordCount'));
      expect(content, contains('https://example.com/vocab#primaryAuthor'));
      expect(content, contains('http://purl.org/dc/terms/title'));

      // Verify external vocabulary properties are referenced correctly (not custom)
      expect(content, contains('SchemaCreativeWork.name'));
      expect(content, contains('SchemaCreativeWork.dateCreated'));
      expect(content, contains('SchemaCreativeWork.author'));
    });

    test('writes .locorda_rdf_mapper.lock with type-based property sources',
        () {
      final lockFile = File('.locorda_rdf_mapper.lock');
      expect(lockFile.existsSync(), isTrue,
          reason: 'Expected lock file written in package root');

      final lockJson =
          jsonDecode(lockFile.readAsStringSync()) as Map<String, dynamic>;
      expect(lockJson['lockFileVersion'], equals(1));

      final types = lockJson['types'] as Map<String, dynamic>;
      final bookTypeEntry = types.entries.where((entry) {
        return entry.key.endsWith('#GenVocabBook');
      }).toList();
      expect(bookTypeEntry.length, equals(1));
      final bookType = bookTypeEntry.single.value as Map<String, dynamic>;
      final bookProperties = bookType['properties'] as Map<String, dynamic>;

      final hasBookWithMapper =
          types.keys.any((key) => key.endsWith('#BookWithMapper'));
      expect(hasBookWithMapper, isTrue,
          reason: 'Lock file should include non-vocab resource classes too');

      expect((bookProperties['title'] as Map<String, dynamic>)['source'],
          equals('auto'));
      expect((bookProperties['title'] as Map<String, dynamic>)['iri'],
          equals('http://purl.org/dc/terms/title'));

      expect((bookProperties['displayTitle'] as Map<String, dynamic>)['source'],
          equals('define'));
      expect((bookProperties['isbn'] as Map<String, dynamic>)['source'],
          equals('define'));
    });

    test('generated minimal mapper file contains minimal define mapper', () {
      final mapperFile =
          File('test/fixtures/gen_vocab_minimal_test_models.rdf_mapper.g.dart');
      expect(mapperFile.existsSync(), isTrue,
          reason:
              'Expected generated minimal mapper file after build_runner run');

      final content = mapperFile.readAsStringSync();
      expect(content, contains('class GenVocabMinimalEntityMapper'));
      expect(
          content, contains('https://minimal.example.com/vocab#minimalName'));
      expect(content,
          contains('https://minimal.example.com/vocab#GenVocabMinimalEntity'));
    });

    test(
        'generated vocab.g.ttl includes class/property/app metadata and extension',
        () {
      final vocabFile = File('lib/vocab.g.ttl');
      expect(vocabFile.existsSync(), isTrue,
          reason: 'Expected main vocabulary output file');

      final graph =
          rdf.decode(vocabFile.readAsStringSync(), contentType: 'text/turtle');
      final vocabIri = IriTerm('https://example.com/vocab#');

      expect(
        graph.findTriples(
          subject: vocabIri,
          predicate: IriTerm('http://www.w3.org/2002/07/owl#versionInfo'),
          object: LiteralTerm('1.2.3'),
        ),
        isNotEmpty,
      );
      expect(
        graph.findTriples(
          subject: vocabIri,
          predicate: IriTerm('http://purl.org/dc/terms/date'),
          object: LiteralTerm('2026-02-17',
              datatype: IriTerm('http://www.w3.org/2001/XMLSchema#date')),
        ),
        isNotEmpty,
      );
      expect(
        graph.findTriples(
          subject: vocabIri,
          predicate: IriTerm('http://purl.org/dc/terms/creator'),
          object: IriTerm('https://example.com/teams/core'),
        ),
        isNotEmpty,
      );

      final bookClass = IriTerm('https://example.com/vocab#GenVocabBook');
      expect(
        graph.findTriples(
          subject: bookClass,
          predicate: RdfsClass.label,
          object: LiteralTerm('Book Resource'),
        ),
        isNotEmpty,
      );
      expect(
        graph.findTriples(
          subject: bookClass,
          predicate: RdfsClass.comment,
          object: LiteralTerm('A globally identified book resource'),
        ),
        isNotEmpty,
      );

      final displayTitle = IriTerm('https://example.com/vocab#displayTitle');
      expect(
        graph.findTriples(
          subject: displayTitle,
          predicate: RdfsClass.label,
          object: LiteralTerm('Display Title Explicit'),
        ),
        isNotEmpty,
      );
      expect(
        graph.findTriples(
          subject: displayTitle,
          predicate: RdfsClass.comment,
          object: LiteralTerm('Title variant for UX rendering'),
        ),
        isNotEmpty,
      );

      final libraryItem =
          IriTerm('https://example.com/vocab#GenVocabLibraryItem');
      expect(
        graph.findTriples(
          subject: libraryItem,
          predicate: RdfsClass.comment,
          object: LiteralTerm('Library item extension note'),
        ),
        isNotEmpty,
      );

      final minimalClass =
          IriTerm('https://minimal.example.com/vocab#GenVocabMinimalEntity');
      expect(
        graph.findTriples(subject: minimalClass).isEmpty,
        isTrue,
        reason:
            'Minimal vocabulary entities must not be emitted into lib/vocab.g.ttl',
      );
    });

    test('generated minimal_vocab.g.ttl contains isolated minimal vocabulary',
        () {
      final minimalFile = File('lib/minimal_vocab.g.ttl');
      expect(minimalFile.existsSync(), isTrue,
          reason: 'Expected dedicated minimal vocabulary output file');

      final graph = rdf.decode(minimalFile.readAsStringSync(),
          contentType: 'text/turtle');
      final vocabIri = IriTerm('https://minimal.example.com/vocab#');
      final minimalClass =
          IriTerm('https://minimal.example.com/vocab#GenVocabMinimalEntity');
      final minimalProperty =
          IriTerm('https://minimal.example.com/vocab#minimalName');

      expect(
        graph.findTriples(
          subject: vocabIri,
          predicate: RdfProperty.type,
          object: IriTerm('http://www.w3.org/2002/07/owl#Ontology'),
        ),
        isNotEmpty,
      );
      expect(
        graph.findTriples(
          subject: minimalClass,
          predicate: RdfProperty.type,
          object: IriTerm('http://www.w3.org/2002/07/owl#Class'),
        ),
        isNotEmpty,
      );
      expect(
        graph.findTriples(
          subject: minimalClass,
          predicate: RdfsClass.label,
          object: LiteralTerm('Gen Vocab Minimal Entity'),
        ),
        isNotEmpty,
      );
      expect(
        graph.findTriples(
          subject: minimalProperty,
          predicate: RdfsClass.label,
          object: LiteralTerm('Minimal Name'),
        ),
        isNotEmpty,
      );

      final hasMainVocabSubjects = graph.triples.any((triple) {
        final subject = triple.subject;
        return subject is IriTerm &&
            subject.value.startsWith('https://example.com/vocab#');
      });
      expect(
        hasMainVocabSubjects,
        isFalse,
        reason:
            'Main vocabulary entities must not be emitted into lib/minimal_vocab.g.ttl',
      );

      // Verify @RdfIgnore field is NOT in the vocabulary
      final isExpandedProperty =
          IriTerm('https://minimal.example.com/vocab#isExpanded');
      expect(
        graph.findTriples(subject: isExpandedProperty),
        isEmpty,
        reason: '@RdfIgnore field should not generate any vocabulary entries',
      );

      // Verify include: false field IS in the vocabulary
      final lastModifiedProperty =
          IriTerm('https://minimal.example.com/vocab#lastModified');
      expect(
        graph.findTriples(
          subject: lastModifiedProperty,
          predicate: Rdf.type,
          object: Rdf.Property,
        ),
        isNotEmpty,
        reason: 'include: false field should still be in vocabulary',
      );
    });

    test('generated vocab.g.ttl includes multilingual labels and comments', () {
      final vocabFile = File('lib/vocab.g.ttl');
      expect(vocabFile.existsSync(), isTrue);

      final graph =
          rdf.decode(vocabFile.readAsStringSync(), contentType: 'text/turtle');

      final productClass =
          IriTerm('https://example.com/vocab#GenVocabMultilingualProduct');

      // Check English label
      expect(
        graph.findTriples(
          subject: productClass,
          predicate: RdfsClass.label,
          object: LiteralTerm.withLanguage('Product', 'en'),
        ),
        isNotEmpty,
        reason: 'Expected English label for Product class',
      );

      // Check German label
      expect(
        graph.findTriples(
          subject: productClass,
          predicate: RdfsClass.label,
          object: LiteralTerm.withLanguage('Produkt', 'de'),
        ),
        isNotEmpty,
        reason: 'Expected German label for Product class',
      );

      // Check French label
      expect(
        graph.findTriples(
          subject: productClass,
          predicate: RdfsClass.label,
          object: LiteralTerm.withLanguage('Produit', 'fr'),
        ),
        isNotEmpty,
        reason: 'Expected French label for Product class',
      );

      // Check English comment
      expect(
        graph.findTriples(
          subject: productClass,
          predicate: RdfsClass.comment,
          object: LiteralTerm.withLanguage('A product for sale', 'en'),
        ),
        isNotEmpty,
        reason: 'Expected English comment for Product class',
      );

      // Check German comment
      expect(
        graph.findTriples(
          subject: productClass,
          predicate: RdfsClass.comment,
          object: LiteralTerm.withLanguage('Ein Produkt zum Verkauf', 'de'),
        ),
        isNotEmpty,
        reason: 'Expected German comment for Product class',
      );

      // Check property multilingual labels
      final nameProperty = IriTerm('https://example.com/vocab#name');
      expect(
        graph.findTriples(
          subject: nameProperty,
          predicate: RdfsClass.label,
          object: LiteralTerm.withLanguage('Name', 'en'),
        ),
        isNotEmpty,
        reason: 'Expected English label for name property',
      );

      expect(
        graph.findTriples(
          subject: nameProperty,
          predicate: RdfsClass.label,
          object: LiteralTerm.withLanguage('Nom', 'fr'),
        ),
        isNotEmpty,
        reason: 'Expected French label for name property',
      );

      final priceProperty = IriTerm('https://example.com/vocab#price');
      expect(
        graph.findTriples(
          subject: priceProperty,
          predicate: RdfsClass.label,
          object: LiteralTerm.withLanguage('Price', 'en'),
        ),
        isNotEmpty,
        reason: 'Expected English label for price property',
      );

      expect(
        graph.findTriples(
          subject: priceProperty,
          predicate: RdfsClass.label,
          object: LiteralTerm.withLanguage('Preis', 'de'),
        ),
        isNotEmpty,
        reason: 'Expected German label for price property',
      );
    });

    test(
        'generated vocab.g.ttl excludes external vocabulary properties from subclassed types',
        () {
      final vocabFile = File('lib/vocab.g.ttl');
      expect(vocabFile.existsSync(), isTrue);

      final graph =
          rdf.decode(vocabFile.readAsStringSync(), contentType: 'text/turtle');

      final articleClass = IriTerm('https://example.com/vocab#GenVocabArticle');

      // Verify the class itself exists and is a subclass of schema:CreativeWork
      expect(
        graph.findTriples(
          subject: articleClass,
          predicate: RdfsClass.subClassOf,
          object: IriTerm('https://schema.org/CreativeWork'),
        ),
        isNotEmpty,
        reason: 'Expected Article to be declared as subclass of CreativeWork',
      );

      expect(
        graph.findTriples(
          subject: articleClass,
          predicate: RdfsClass.label,
          object: LiteralTerm('Article'),
        ),
        isNotEmpty,
        reason: 'Expected Article class to have label',
      );

      // Verify that external vocabulary properties (from Schema.org) are NOT in our vocabulary
      final schemaName = IriTerm('https://schema.org/name');
      expect(
        graph.findTriples(subject: schemaName),
        isEmpty,
        reason:
            'Schema.org name property should NOT be included in our vocabulary',
      );

      final schemaDateCreated = IriTerm('https://schema.org/dateCreated');
      expect(
        graph.findTriples(subject: schemaDateCreated),
        isEmpty,
        reason:
            'Schema.org dateCreated property should NOT be included in our vocabulary',
      );

      final schemaAuthor = IriTerm('https://schema.org/author');
      expect(
        graph.findTriples(subject: schemaAuthor),
        isEmpty,
        reason:
            'Schema.org author property should NOT be included in our vocabulary',
      );

      // Verify that custom properties ARE in our vocabulary
      final viewCount = IriTerm('https://example.com/vocab#viewCount');
      expect(
        graph.findTriples(
          subject: viewCount,
          predicate: RdfsClass.label,
          object: LiteralTerm('View Count'),
        ),
        isNotEmpty,
        reason: 'Custom viewCount property should be in our vocabulary',
      );

      expect(
        graph.findTriples(
          subject: viewCount,
          predicate: RdfsClass.comment,
          object: LiteralTerm('Number of times this article has been viewed'),
        ),
        isNotEmpty,
        reason: 'Custom viewCount property should have comment',
      );

      final internalNotes = IriTerm('https://example.com/vocab#internalNotes');
      expect(
        graph.findTriples(
          subject: internalNotes,
          predicate: RdfProperty.type,
          object: Rdf.Property,
        ),
        isNotEmpty,
        reason:
            'Custom internalNotes property (unannotated) should be in our vocabulary',
      );

      expect(
        graph.findTriples(
          subject: internalNotes,
          predicate: Rdfs.domain,
          object: articleClass,
        ),
        isNotEmpty,
        reason: 'Custom internalNotes property should declare Article domain',
      );
    });

    test(
        'generated contracts.g.ttl includes secondary vocabulary metadata and extension',
        () {
      final contractsFile = File('lib/contracts.g.ttl');
      expect(contractsFile.existsSync(), isTrue,
          reason: 'Expected contracts vocabulary output file');

      final graph = rdf.decode(contractsFile.readAsStringSync(),
          contentType: 'text/turtle');
      final vocabIri = IriTerm('https://example.com/contracts#');

      expect(
        graph.findTriples(
          subject: vocabIri,
          predicate: IriTerm('http://www.w3.org/2002/07/owl#versionInfo'),
          object: LiteralTerm('0.9.0'),
        ),
        isNotEmpty,
      );
      expect(
        graph.findTriples(
          subject: vocabIri,
          predicate: IriTerm('http://purl.org/dc/terms/creator'),
          object: LiteralTerm('Contracts Team'),
        ),
        isNotEmpty,
      );

      final contractClass =
          IriTerm('https://example.com/contracts#GenVocabContract');
      expect(
        graph.findTriples(
          subject: contractClass,
          predicate: RdfsClass.subClassOf,
          object: IriTerm('https://schema.org/CreativeWork'),
        ),
        isNotEmpty,
      );
      expect(
        graph.findTriples(
          subject: contractClass,
          predicate: RdfsClass.comment,
          object: LiteralTerm('Contract extension note'),
        ),
        isNotEmpty,
      );

      final signedAt = IriTerm('https://example.com/contracts#signedAt');
      expect(
        graph.findTriples(
          subject: signedAt,
          predicate: RdfsClass.label,
          object: LiteralTerm('Signed At'),
        ),
        isNotEmpty,
      );
      expect(
        graph.findTriples(
          subject: signedAt,
          predicate: RdfsClass.comment,
          object: LiteralTerm('Date when contract was signed'),
        ),
        isNotEmpty,
      );
    });

    test('respects user-specified rdf:type in property metadata', () {
      final vocabFile = File('lib/vocab.g.ttl');
      expect(vocabFile.existsSync(), isTrue);

      final graph =
          rdf.decode(vocabFile.readAsStringSync(), contentType: 'text/turtle');

      // Verify default rdf:Property for custom generated properties without type override
      final titleProp = IriTerm('https://example.com/vocab#isbn');
      expect(
        graph.findTriples(
          subject: titleProp,
          predicate: Rdf.type,
          object: Rdf.Property,
        ),
        isNotEmpty,
        reason: 'Default property should be typed as rdf:Property',
      );

      // Verify user-specified owl:DatatypeProperty
      final wordCount = IriTerm('https://example.com/vocab#wordCount');
      expect(
        graph.findTriples(
          subject: wordCount,
          predicate: Rdf.type,
          object: IriTerm('http://www.w3.org/2002/07/owl#DatatypeProperty'),
        ),
        isNotEmpty,
        reason:
            'Property with explicit owl:DatatypeProperty metadata should use that type',
      );

      // Verify it does NOT have rdf:Property when DatatypeProperty is specified
      expect(
        graph.findTriples(
          subject: wordCount,
          predicate: Rdf.type,
          object: Rdf.Property,
        ),
        isEmpty,
        reason:
            'User-specified type should replace default rdf:Property, not add to it',
      );

      // Verify user-specified owl:ObjectProperty
      final primaryAuthor = IriTerm('https://example.com/vocab#primaryAuthor');
      expect(
        graph.findTriples(
          subject: primaryAuthor,
          predicate: Rdf.type,
          object: IriTerm('http://www.w3.org/2002/07/owl#ObjectProperty'),
        ),
        isNotEmpty,
        reason:
            'Property with explicit owl:ObjectProperty metadata should use that type',
      );

      // Verify it does NOT have rdf:Property when ObjectProperty is specified
      expect(
        graph.findTriples(
          subject: primaryAuthor,
          predicate: Rdf.type,
          object: Rdf.Property,
        ),
        isEmpty,
        reason:
            'User-specified type should replace default rdf:Property, not add to it',
      );

      // Verify other metadata is preserved
      expect(
        graph.findTriples(
          subject: primaryAuthor,
          predicate: RdfsClass.label,
          object: LiteralTerm('Primary Author'),
        ),
        isNotEmpty,
        reason: 'Label metadata should be preserved alongside custom type',
      );

      expect(
        graph.findTriples(
          subject: primaryAuthor,
          predicate: Rdfs.range,
          object: IriTerm('https://example.com/vocab#Person'),
        ),
        isNotEmpty,
        reason: 'Range metadata should be preserved alongside custom type',
      );
    });
  });
}
