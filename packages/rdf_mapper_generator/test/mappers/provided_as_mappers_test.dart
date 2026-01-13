import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/provided_as_test_models.dart';
// Import generated mappers
import '../fixtures/provided_as_test_models.rdf_mapper.g.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
  late RdfMapper mapper;

  /// Helper to create serialization context
  SerializationContext createSerializationContext() {
    return SerializationContextImpl(registry: mapper.registry);
  }

  /// Helper to create deserialization context from triples
  DeserializationContext createDeserializationContext(List<Triple> triples) {
    final graph = RdfGraph.fromTriples(triples);
    return DeserializationContextImpl(graph: graph, registry: mapper.registry);
  }

  setUp(() {
    mapper = defaultInitTestRdfMapper();
  });

  group('ProvidedAs Feature - Mapper Tests', () {
    group('DocumentMapper (parent with providedAs)', () {
      test('serializes document with hierarchical section IRIs', () {
        final documentMapper = DocumentMapper(
          baseUriProvider: () => 'http://example.org/data',
        );
        final context = createSerializationContext();

        final section1 = Section()
          ..sectionId = 'intro'
          ..title = 'Introduction';

        final section2 = Section()
          ..sectionId = 'conclusion'
          ..title = 'Conclusion';

        final document = Document()
          ..docId = 'doc123'
          ..sections = [section1, section2]
          ..relatedDocRef = null;

        final (subject, triples) =
            documentMapper.toRdfResource(document, context);

        // Verify document IRI
        expect(
            subject.value, equals('http://example.org/data/documents/doc123'));

        // Verify sections are serialized with parent IRI as base
        final sectionTriples = triples
            .where(
              (t) => t.predicate == ProvidedAsVocab.hasSection,
            )
            .toList();

        expect(sectionTriples, hasLength(2));

        final sectionIris = sectionTriples
            .map((t) => (t.object as IriTerm).value)
            .toList()
          ..sort();

        expect(
          sectionIris[0],
          equals(
              'http://example.org/data/documents/doc123/sections/conclusion'),
        );
        expect(
          sectionIris[1],
          equals('http://example.org/data/documents/doc123/sections/intro'),
        );

        // Verify section titles are included
        final titleTriples = triples
            .where(
              (t) => t.predicate == ProvidedAsVocab.sectionTitle,
            )
            .toList();

        expect(titleTriples, hasLength(2));
      });

      test('deserializes document with hierarchical sections', () {
        final documentIri =
            const IriTerm('http://example.org/data/documents/doc456');
        final section1Iri = const IriTerm(
            'http://example.org/data/documents/doc456/sections/chapter1');
        final section2Iri = const IriTerm(
            'http://example.org/data/documents/doc456/sections/chapter2');

        final triples = [
          // Document sections
          Triple(documentIri, ProvidedAsVocab.hasSection, section1Iri),
          Triple(documentIri, ProvidedAsVocab.hasSection, section2Iri),

          // Section 1 data
          Triple(section1Iri, ProvidedAsVocab.sectionTitle,
              LiteralTerm('Chapter 1')),

          // Section 2 data
          Triple(section2Iri, ProvidedAsVocab.sectionTitle,
              LiteralTerm('Chapter 2')),
        ];

        final context = createDeserializationContext(triples);
        final documentMapper = DocumentMapper(
          baseUriProvider: () => 'http://example.org/data',
        );

        final document = documentMapper.fromRdfResource(documentIri, context);

        expect(document.docId, equals('doc456'));
        expect(document.sections, hasLength(2));

        // Sort sections by ID for predictable testing
        final sortedSections = document.sections
          ..sort((a, b) => a.sectionId.compareTo(b.sectionId));

        expect(sortedSections[0].sectionId, equals('chapter1'));
        expect(sortedSections[0].title, equals('Chapter 1'));

        expect(sortedSections[1].sectionId, equals('chapter2'));
        expect(sortedSections[1].title, equals('Chapter 2'));
      });

      test('round-trip serialization maintains hierarchical structure', () {
        final documentMapper = DocumentMapper(
          baseUriProvider: () => 'http://test.org',
        );
        final serContext = createSerializationContext();

        final originalSection1 = Section()
          ..sectionId = 'abstract'
          ..title = 'Abstract';

        final originalSection2 = Section()
          ..sectionId = 'methodology'
          ..title = 'Methodology';

        final originalDocument = Document()
          ..docId = 'paper789'
          ..sections = [originalSection1, originalSection2]
          ..relatedDocRef = null;

        // Serialize
        final (subject, triples) =
            documentMapper.toRdfResource(originalDocument, serContext);

        // Deserialize
        final deserContext = createDeserializationContext(triples.toList());
        final deserializedDocument =
            documentMapper.fromRdfResource(subject, deserContext);

        // Verify
        expect(deserializedDocument.docId, equals(originalDocument.docId));
        expect(deserializedDocument.sections,
            hasLength(originalDocument.sections.length));

        final sortedOriginal = [...originalDocument.sections]
          ..sort((a, b) => a.sectionId.compareTo(b.sectionId));
        final sortedDeserialized = [...deserializedDocument.sections]
          ..sort((a, b) => a.sectionId.compareTo(b.sectionId));

        for (int i = 0; i < sortedOriginal.length; i++) {
          expect(sortedDeserialized[i].sectionId,
              equals(sortedOriginal[i].sectionId));
          expect(sortedDeserialized[i].title, equals(sortedOriginal[i].title));
        }
      });

      test('handles different base URIs correctly', () {
        final baseUris = [
          'http://example.org/api',
          'https://secure.example.com/v1',
          'http://localhost:8080/data',
        ];

        final context = createSerializationContext();

        for (final baseUri in baseUris) {
          final documentMapper = DocumentMapper(
            baseUriProvider: () => baseUri,
          );

          final section = Section()
            ..sectionId = 'test'
            ..title = 'Test Section';

          final document = Document()
            ..docId = 'testdoc'
            ..sections = [section]
            ..relatedDocRef = null;

          final (subject, triples) =
              documentMapper.toRdfResource(document, context);

          // Verify document IRI uses base URI
          expect(subject.value, equals('$baseUri/documents/testdoc'));

          // Verify section IRI uses document IRI as base
          final sectionTriple = triples.firstWhere(
            (t) => t.predicate == ProvidedAsVocab.hasSection,
          );
          expect(
            (sectionTriple.object as IriTerm).value,
            equals('$baseUri/documents/testdoc/sections/test'),
          );
        }
      });

      test('handles special characters in IDs', () {
        final documentMapper = DocumentMapper(
          baseUriProvider: () => 'http://example.org',
        );
        final context = createSerializationContext();

        final section = Section()
          ..sectionId = 'section_with-special.chars'
          ..title = 'Special Section';

        final document = Document()
          ..docId = 'doc-with_special.chars'
          ..sections = [section]
          ..relatedDocRef = null;

        final (subject, triples) =
            documentMapper.toRdfResource(document, context);

        expect(
          subject.value,
          equals('http://example.org/documents/doc-with_special.chars'),
        );

        final sectionTriple = triples.firstWhere(
          (t) => t.predicate == ProvidedAsVocab.hasSection,
        );
        expect(
          (sectionTriple.object as IriTerm).value,
          equals(
              'http://example.org/documents/doc-with_special.chars/sections/section_with-special.chars'),
        );
      });

      test('handles empty sections list', () {
        final documentMapper = DocumentMapper(
          baseUriProvider: () => 'http://example.org',
        );
        final context = createSerializationContext();

        final document = Document()
          ..docId = 'emptydoc'
          ..sections = []
          ..relatedDocRef = null;

        final (subject, triples) =
            documentMapper.toRdfResource(document, context);

        expect(subject.value, equals('http://example.org/documents/emptydoc'));

        // No section triples should be present
        final sectionTriples = triples.where(
          (t) => t.predicate == ProvidedAsVocab.hasSection,
        );
        expect(sectionTriples, isEmpty);
      });

      test('handles unicode in document and section IDs', () {
        final documentMapper = DocumentMapper(
          baseUriProvider: () => 'http://example.org',
        );
        final context = createSerializationContext();

        final section = Section()
          ..sectionId = 'section日本語'
          ..title = 'Japanese Title 日本語';

        final document = Document()
          ..docId = 'doc日本語'
          ..sections = [section]
          ..relatedDocRef = null;

        final (subject, triples) =
            documentMapper.toRdfResource(document, context);

        expect(subject.value, equals('http://example.org/documents/doc日本語'));

        final sectionTriple = triples.firstWhere(
          (t) => t.predicate == ProvidedAsVocab.hasSection,
        );
        expect(
          (sectionTriple.object as IriTerm).value,
          equals('http://example.org/documents/doc日本語/sections/section日本語'),
        );
      });
    });

    group('SectionMapper (child with providedAs dependency)', () {
      test('is not registered globally', () {
        final isRegistered =
            mapper.registry.hasGlobalResourceDeserializerFor<Section>();
        expect(
          isRegistered,
          isFalse,
          reason:
              'Section should not be registered globally due to registerGlobally: false',
        );
      });

      test('requires document IRI provider during instantiation', () {
        // SectionMapper should require documentIriProvider
        final sectionMapper = SectionMapper(
          documentIriProvider: () => 'http://example.org/documents/doc123',
        );

        expect(sectionMapper, isNotNull);
      });
    });

    group('Integration and edge cases', () {
      test('validates hierarchical IRI construction', () {
        final documentMapper = DocumentMapper(
          baseUriProvider: () => 'http://api.example.com/v2',
        );
        final context = createSerializationContext();

        final testCases = [
          ('doc1', 'sec1', 'Section 1'),
          ('document-2', 'section-2', 'Section 2'),
          ('doc_3', 'sec_3', 'Section 3'),
        ];

        for (final (docId, secId, secTitle) in testCases) {
          final section = Section()
            ..sectionId = secId
            ..title = secTitle;

          final document = Document()
            ..docId = docId
            ..sections = [section]
            ..relatedDocRef = null;

          final (subject, triples) =
              documentMapper.toRdfResource(document, context);

          final expectedDocIri = 'http://api.example.com/v2/documents/$docId';
          final expectedSecIri = '$expectedDocIri/sections/$secId';

          expect(subject.value, equals(expectedDocIri));

          final sectionTriple = triples.firstWhere(
            (t) => t.predicate == ProvidedAsVocab.hasSection,
          );
          expect(
            (sectionTriple.object as IriTerm).value,
            equals(expectedSecIri),
          );
        }
      });

      test('handles multiple sections with different IDs', () {
        final documentMapper = DocumentMapper(
          baseUriProvider: () => 'http://example.org',
        );
        final context = createSerializationContext();

        final sections = List.generate(
          5,
          (i) => Section()
            ..sectionId = 'section$i'
            ..title = 'Title $i',
        );

        final document = Document()
          ..docId = 'multisection'
          ..sections = sections
          ..relatedDocRef = null;

        final (subject, triples) =
            documentMapper.toRdfResource(document, context);

        final sectionTriples = triples
            .where(
              (t) => t.predicate == ProvidedAsVocab.hasSection,
            )
            .toList();

        expect(sectionTriples, hasLength(5));

        final sectionIris =
            sectionTriples.map((t) => (t.object as IriTerm).value).toSet();

        // All section IRIs should be unique
        expect(sectionIris, hasLength(5));

        // All section IRIs should start with document IRI
        for (final iri in sectionIris) {
          expect(iri, startsWith(subject.value));
        }
      });
    });
  });
}
