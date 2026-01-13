import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';

// Import test models and their generated mappers
import '../fixtures/with_fragment_test_models.dart';
import '../fixtures/with_fragment_test_models.rdf_mapper.g.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
  late RdfMapper mapper;

  setUp(() {
    mapper = defaultInitTestRdfMapper();
  });

  group('Fragment Template Mappers', () {
    group('SectionReference (@RdfIri.withFragment) mapping', () {
      test('should not be registered globally (registerGlobally: false)', () {
        final isRegisteredGlobally = mapper.registry
            .hasGlobalResourceDeserializerFor<SectionReference>();
        expect(isRegisteredGlobally, isFalse,
            reason:
                'SectionReference should not be registered globally due to registerGlobally: false');
      });

      // Note: SectionReference is an IriTermMapper, not a resource mapper.
      // It cannot be serialized directly with encodeObject().
      // It is tested through its parent resource (Document) below.
    });

    group('Document (using SectionReference with context) mapping', () {
      test('should be registered globally', () {
        final isRegistered =
            mapper.registry.hasGlobalResourceDeserializerFor<Document>();
        expect(isRegistered, isTrue,
            reason: 'Document should be registered globally');
      });

      test(
          'should serialize with nested SectionReference using documentIri context',
          () {
        final section = SectionReference('abstract');
        final document = Document('doc123', section);

        // Serialize the document using n-triples for clear output
        final graph = mapper.encodeObject(document,
            contentType: ntriples.primaryMimeType);

        expect(graph, isNotNull);

        // Should contain the document IRI
        expect(graph, contains('tag:example.org,2025:document-doc123'));

        // Should contain the section reference with fragment
        expect(graph,
            contains('tag:example.org,2025:document-doc123#section-abstract'));

        // Verify RDF structure
        expect(graph, contains('http://example.org/currentSection'));
      });

      test('should deserialize with nested SectionReference', () {
        final section = SectionReference('methods');
        final document = Document('doc456', section);

        // Serialize first
        final graph = mapper.encodeObject(document);

        // Deserialize
        final deserialized = mapper.decodeObject<Document>(graph);

        expect(deserialized, isNotNull);
        expect(deserialized.id, equals(document.id));
        expect(deserialized.section, isNotNull);
        expect(deserialized.section.sectionId, equals(section.sectionId));
      });

      test('should maintain context variable across nested serialization', () {
        final section1 = SectionReference('intro');
        final section2 = SectionReference('conclusion');
        final document1 = Document('doc1', section1);
        final document2 = Document('doc2', section2);

        // Serialize both documents
        final graph1 = mapper.encodeObject(document1,
            contentType: ntriples.primaryMimeType);
        final graph2 = mapper.encodeObject(document2,
            contentType: ntriples.primaryMimeType);

        // Each should use its own document IRI as context
        expect(graph1,
            contains('tag:example.org,2025:document-doc1#section-intro'));
        expect(graph2,
            contains('tag:example.org,2025:document-doc2#section-conclusion'));

        // Make sure they don't mix contexts
        expect(graph1, isNot(contains('doc2')));
        expect(graph2, isNot(contains('doc1')));
      });
    });

    group('Article (IriMapping.withFragment at property level) mapping', () {
      test('should be registered globally', () {
        final isRegistered =
            mapper.registry.hasGlobalResourceDeserializerFor<Article>();
        expect(isRegistered, isTrue,
            reason: 'Article should be registered globally');
      });

      test('should serialize with fragment at property level', () {
        final article = Article('article-001', 'section-3');

        final graph =
            mapper.encodeObject(article, contentType: ntriples.primaryMimeType);

        expect(graph, isNotNull);

        // Should contain the article IRI
        expect(graph, contains('http://example.org/articles/article-001'));

        // Should contain the related section with fragment using article IRI as base
        expect(
            graph,
            contains(
                'http://example.org/articles/article-001#section-section-3'));

        // Verify property is present
        expect(graph, contains('http://example.org/relatedSection'));
      });

      test('should deserialize with fragment at property level', () {
        final article = Article('article-002', 'section-5');

        // Serialize
        final graph = mapper.encodeObject(article);

        // Deserialize
        final deserialized = mapper.decodeObject<Article>(graph);

        expect(deserialized, isNotNull);
        expect(deserialized.articleId, equals(article.articleId));
        expect(deserialized.refId, equals(article.refId));
      });

      test('should handle empty refId', () {
        final article = Article('article-003', '');

        final graph =
            mapper.encodeObject(article, contentType: ntriples.primaryMimeType);

        expect(graph, isNotNull);

        // Should still have base IRI with fragment marker
        expect(graph,
            contains('http://example.org/articles/article-003#section-'));
      });

      test('should perform round-trip with complex refId', () {
        final article = Article('article-999', 'complex_ref-123.45');

        // Serialize
        final graph = mapper.encodeObject(article);

        // Deserialize
        final deserialized = mapper.decodeObject<Article>(graph);

        expect(deserialized, isNotNull);
        expect(deserialized.articleId, equals(article.articleId));
        expect(deserialized.refId, equals(article.refId));
      });
    });

    group('Page (IriStrategy.withFragment at class level) mapping', () {
      test('should be registered globally but requires baseUriProvider', () {
        // Page mapper is generated but requires baseUriProvider context
        // It cannot be used directly without the provider
        final isRegistered =
            mapper.registry.hasGlobalResourceDeserializerFor<Page>();
        // The mapper is registered but will fail at runtime without provider
        expect(isRegistered, isTrue,
            reason: 'Page mapper should be registered');
      });

      test(
          'should serialize with fragment when used with explicit registration',
          () {
        final page = Page('page-home', 'Home Page');

        final graph = mapper.encodeObject(
          page,
          contentType: ntriples.primaryMimeType,
          register: (registry) => registry.registerMapper(
            PageMapper(baseUriProvider: () => 'http://example.org'),
          ),
        );

        expect(graph, isNotNull);

        // The IRI strategy base template is: '{+baseUri}/pages/overview#intro'
        // The fragment template is: '{pageId}'
        // The generator strips '#intro' from base and adds '#{pageId}'
        // So with baseUri='http://example.org' and pageId='page-home', it produces:
        // http://example.org/pages/overview#page-home
        expect(graph, contains('http://example.org/pages/overview#page-home'));

        // Should contain the title property
        expect(graph, contains('Home Page'));
        expect(graph, contains('http://example.org/title'));
      });

      test('should deserialize with fragment in IRI strategy', () {
        final page = Page('page-about', 'About Us');

        final pageMapper =
            PageMapper(baseUriProvider: () => 'http://example.org');

        // Serialize
        final graph = mapper.encodeObject(
          page,
          contentType: ntriples.primaryMimeType,
          register: (registry) => registry.registerMapper(pageMapper),
        );

        // Deserialize - provider not called during deserialization
        final deserialized = mapper.decodeObject<Page>(
          graph,
          register: (registry) => registry.registerMapper(
            PageMapper(
                baseUriProvider: () =>
                    throw Exception('Not called during deserialization')),
          ),
        );

        expect(deserialized, isNotNull);
        expect(deserialized.pageId, equals(page.pageId));
        expect(deserialized.title, equals(page.title));
      });

      test('should handle round-trip with numeric pageId', () {
        final page = Page('12345', 'Numeric Page');

        final pageMapper =
            PageMapper(baseUriProvider: () => 'http://example.org');

        // Serialize
        final graph = mapper.encodeObject(
          page,
          contentType: ntriples.primaryMimeType,
          register: (registry) => registry.registerMapper(pageMapper),
        );

        expect(graph, isNotNull);

        // Deserialize
        final deserialized = mapper.decodeObject<Page>(
          graph,
          register: (registry) => registry.registerMapper(
            PageMapper(baseUriProvider: () => throw Exception('Not called')),
          ),
        );

        expect(deserialized, isNotNull);
        expect(deserialized.pageId, equals(page.pageId));
        expect(deserialized.title, equals(page.title));
      });

      test('should preserve all properties through serialization', () {
        final page = Page('complex-page-id', 'A Complex Title with Spaces');

        final pageMapper =
            PageMapper(baseUriProvider: () => 'http://example.org');

        final graph = mapper.encodeObject(
          page,
          contentType: ntriples.primaryMimeType,
          register: (registry) => registry.registerMapper(pageMapper),
        );

        expect(graph, isNotNull);

        final deserialized = mapper.decodeObject<Page>(
          graph,
          register: (registry) => registry.registerMapper(
            PageMapper(baseUriProvider: () => throw Exception('Not called')),
          ),
        );

        expect(deserialized, isNotNull);
        expect(deserialized.pageId, equals(page.pageId));
        expect(deserialized.title, equals(page.title));
      });
    });

    group('Integration Tests', () {
      test('should handle multiple types with fragments in same graph', () {
        // Create instances of multiple types
        final section = SectionReference('intro');
        final document = Document('multi-doc', section);
        final article = Article('multi-article', 'ref-1');
        final page = Page('multi-page', 'Multi Page');

        final pageMapper =
            PageMapper(baseUriProvider: () => 'http://example.org');

        // Serialize all
        final documentGraph = mapper.encodeObject(document,
            contentType: ntriples.primaryMimeType);
        final articleGraph =
            mapper.encodeObject(article, contentType: ntriples.primaryMimeType);
        final pageGraph = mapper.encodeObject(
          page,
          contentType: ntriples.primaryMimeType,
          register: (registry) => registry.registerMapper(pageMapper),
        );

        // All should be valid
        expect(documentGraph, isNotNull);
        expect(articleGraph, isNotNull);
        expect(pageGraph, isNotNull);

        // Deserialize all
        final deserializedDoc = mapper.decodeObject<Document>(documentGraph);
        final deserializedArticle = mapper.decodeObject<Article>(articleGraph);
        final deserializedPage = mapper.decodeObject<Page>(
          pageGraph,
          register: (registry) => registry.registerMapper(
            PageMapper(baseUriProvider: () => throw Exception('Not called')),
          ),
        );

        // All should preserve data
        expect(deserializedDoc.id, equals(document.id));
        expect(deserializedDoc.section.sectionId, equals(section.sectionId));
        expect(deserializedArticle.articleId, equals(article.articleId));
        expect(deserializedArticle.refId, equals(article.refId));
        expect(deserializedPage.pageId, equals(page.pageId));
        expect(deserializedPage.title, equals(page.title));
      });

      test('should handle fragments with special characters', () {
        // Test with characters commonly found in fragments (no spaces - IRIs don't allow them)
        final article = Article('test-article', 'section_with-special.chars');

        final graph =
            mapper.encodeObject(article, contentType: ntriples.primaryMimeType);
        expect(graph, isNotNull);

        final deserialized = mapper.decodeObject<Article>(graph);
        expect(deserialized, isNotNull);
        // The refId should be preserved with special characters
        expect(deserialized.refId, equals(article.refId));
      });

      test(
          'should differentiate between same base IRI with different fragments',
          () {
        final article1 = Article('same-base', 'fragment-1');
        final article2 = Article('same-base', 'fragment-2');

        final graph1 = mapper.encodeObject(article1,
            contentType: ntriples.primaryMimeType);
        final graph2 = mapper.encodeObject(article2,
            contentType: ntriples.primaryMimeType);

        // Both graphs should use the same base IRI
        expect(graph1, contains('http://example.org/articles/same-base'));
        expect(graph2, contains('http://example.org/articles/same-base'));

        // But different fragments (in n-triples format, fragments are part of full IRI)
        expect(
            graph1,
            contains(
                'http://example.org/articles/same-base#section-fragment-1'));
        expect(
            graph2,
            contains(
                'http://example.org/articles/same-base#section-fragment-2'));

        // Deserialize to verify they remain distinct
        final deserialized1 = mapper.decodeObject<Article>(graph1);
        final deserialized2 = mapper.decodeObject<Article>(graph2);

        expect(deserialized1.refId, equals('fragment-1'));
        expect(deserialized2.refId, equals('fragment-2'));
      });
    });

    group('Error Handling', () {
      test(
          'should handle invalid Article IRI gracefully during deserialization',
          () {
        // N-triples with Article IRI that doesn't match the expected pattern
        // The regex pattern expects: ^http://example\.org/articles/(?<articleId>[^/]*)$
        final ntriples =
            '<http://wrong-pattern> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/Article> .';

        // When pattern doesn't match, should throw an appropriate error
        expect(
          () => mapper.decodeObject<Article>(ntriples),
          throwsA(isA<DeserializationException>()),
          reason: 'Should throw error when IRI pattern does not match',
        );
      });
    });
  });
}
