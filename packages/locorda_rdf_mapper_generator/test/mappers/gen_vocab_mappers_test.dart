import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:test/test.dart';

import '../fixtures/gen_vocab_processor_test_models.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
  group('GenVocab mapper integration', () {
    late RdfMapper mapper;

    setUp(() {
      mapper = defaultInitTestRdfMapper();
    });

    test('registers all define global resource mappers', () {
      expect(mapper.registry.hasGlobalResourceDeserializerFor<GenVocabBook>(),
          isTrue);
      expect(
          mapper.registry
              .hasGlobalResourceDeserializerFor<GenVocabLibraryItem>(),
          isTrue);
      expect(
          mapper.registry.hasGlobalResourceDeserializerFor<GenVocabContract>(),
          isTrue);
    });

    test('roundtrip for GenVocabBook uses vocab predicates', () {
      final book = GenVocabBook(
        id: 'book-1',
        title: 'Domain-Driven Design',
        displayTitle: 'DDD',
        isbn: '978-0321125217',
      );

      final rdfContent = mapper.encodeObject(book);
      final graph = rdf.decode(rdfContent, contentType: 'text/turtle');
      final subject = IriTerm('https://example.com/books/book-1');

      expect(
        graph.findTriples(
          subject: subject,
          predicate: IriTerm('http://purl.org/dc/terms/title'),
          object: LiteralTerm('Domain-Driven Design'),
        ),
        isNotEmpty,
      );
      expect(
        graph.findTriples(
          subject: subject,
          predicate: IriTerm('https://example.com/vocab#displayTitle'),
          object: LiteralTerm('DDD'),
        ),
        isNotEmpty,
      );
      expect(
        graph.findTriples(
          subject: subject,
          predicate: IriTerm('https://example.com/vocab#isbn'),
          object: LiteralTerm('978-0321125217'),
        ),
        isNotEmpty,
      );

      final decoded = mapper.decodeObject<GenVocabBook>(rdfContent);
      expect(decoded.id, equals(book.id));
      expect(decoded.title, equals(book.title));
      expect(decoded.displayTitle, equals(book.displayTitle));
      expect(decoded.isbn, equals(book.isbn));
    });

    test('roundtrip for GenVocabLibraryItem supports explicit fragment', () {
      final item = GenVocabLibraryItem(
        id: 'item-1',
        title: 'Research Notes',
        publicationDate: '2026-01-05',
      );

      final rdfContent = mapper.encodeObject(item);
      final graph = rdf.decode(rdfContent, contentType: 'text/turtle');
      final subject = IriTerm('https://example.com/library-items/item-1');

      expect(
        graph.findTriples(
          subject: subject,
          predicate: IriTerm('https://example.com/vocab#publicationDate'),
          object: LiteralTerm('2026-01-05'),
        ),
        isNotEmpty,
      );

      final decoded = mapper.decodeObject<GenVocabLibraryItem>(rdfContent);
      expect(decoded.id, equals(item.id));
      expect(decoded.title, equals(item.title));
      expect(decoded.publicationDate, equals(item.publicationDate));
    });

    test('roundtrip for GenVocabContract uses contracts vocabulary predicates',
        () {
      final contract = GenVocabContract(
        id: 'contract-1',
        title: 'Service Agreement',
        signedAt: '2026-02-01',
      );

      final rdfContent = mapper.encodeObject(contract);
      final graph = rdf.decode(rdfContent, contentType: 'text/turtle');
      final subject = IriTerm('https://example.com/contracts/contract-1');

      expect(
        graph.findTriples(
          subject: subject,
          predicate: IriTerm('http://purl.org/dc/terms/title'),
          object: LiteralTerm('Service Agreement'),
        ),
        isNotEmpty,
      );
      expect(
        graph.findTriples(
          subject: subject,
          predicate: IriTerm('https://example.com/contracts#signedAt'),
          object: LiteralTerm('2026-02-01'),
        ),
        isNotEmpty,
      );

      final decoded = mapper.decodeObject<GenVocabContract>(rdfContent);
      expect(decoded.id, equals(contract.id));
      expect(decoded.title, equals(contract.title));
      expect(decoded.signedAt, equals(contract.signedAt));
    });
  });
}
