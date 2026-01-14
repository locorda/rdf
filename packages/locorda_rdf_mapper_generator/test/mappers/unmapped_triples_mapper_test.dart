import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:test/test.dart';

import '../fixtures/unmapped_triples_test_models.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
  group('Unmapped Triples Mapper Tests', () {
    late RdfMapper rdfMapper;

    setUp(() {
      rdfMapper = defaultInitTestRdfMapper();
    });

    group('BookWithUnmappedTriples (constructor parameters)', () {
      test('serializes and deserializes correctly with unmapped triples', () {
        final originalBook = BookWithUnmappedTriples(
          id: 'test-book-123',
          title: 'Test Book',
          author: 'Test Author',
          unmappedTriples: RdfGraph(triples: [
            Triple(
              const IriTerm('https://example.org/books/test-book-123'),
              const IriTerm('https://example.org/publisher'),
              LiteralTerm('Test Publisher'),
            ),
            Triple(
              const IriTerm('https://example.org/books/test-book-123'),
              const IriTerm('https://example.org/isbn'),
              LiteralTerm('978-1234567890'),
            ),
          ]),
        );

        // Serialize to RDF
        final turtle = rdfMapper.encodeObject(originalBook);

        // Verify the generated RDF contains both mapped and unmapped triples
        expect(turtle, contains('Test Book'));
        expect(turtle, contains('Test Author'));
        expect(turtle, contains('Test Publisher'));
        expect(turtle, contains('978-1234567890'));

        // Deserialize back to object
        final deserializedBook =
            rdfMapper.decodeObject<BookWithUnmappedTriples>(turtle);

        // Verify all fields are correctly populated
        expect(deserializedBook.id, equals('test-book-123'));
        expect(deserializedBook.title, equals('Test Book'));
        expect(deserializedBook.author, equals('Test Author'));
        expect(deserializedBook.unmappedTriples.triples.length, equals(2));

        // Verify unmapped triples are preserved
        final unmappedTriples =
            deserializedBook.unmappedTriples.triples.toList();
        expect(
            unmappedTriples.any((t) =>
                t.predicate == const IriTerm('https://example.org/publisher') &&
                t.object == LiteralTerm('Test Publisher')),
            isTrue);
        expect(
            unmappedTriples.any((t) =>
                t.predicate == const IriTerm('https://example.org/isbn') &&
                t.object == LiteralTerm('978-1234567890')),
            isTrue);
      });

      test('handles empty unmapped triples', () {
        final book = BookWithUnmappedTriples(
          id: 'empty-book',
          title: 'Empty Book',
          author: 'Empty Author',
          unmappedTriples: RdfGraph(triples: []),
        );

        final turtle = rdfMapper.encodeObject(book);
        final deserializedBook =
            rdfMapper.decodeObject<BookWithUnmappedTriples>(turtle);

        expect(deserializedBook.id, equals('empty-book'));
        expect(deserializedBook.title, equals('Empty Book'));
        expect(deserializedBook.author, equals('Empty Author'));
        expect(deserializedBook.unmappedTriples.triples, isEmpty);
      });
    });

    group('BookWithUnmappedTriplesLateFields (late fields)', () {
      test('serializes and deserializes correctly with unmapped triples', () {
        final originalBook = BookWithUnmappedTriplesLateFields()
          ..id = 'test-book-456'
          ..title = 'Test Book Late'
          ..author = 'Test Author Late'
          ..unmappedTriples = RdfGraph(triples: [
            Triple(
              const IriTerm('https://example.org/books/test-book-456'),
              const IriTerm('https://example.org/series'),
              LiteralTerm('Test Series'),
            ),
            Triple(
              const IriTerm('https://example.org/books/test-book-456'),
              const IriTerm('https://example.org/edition'),
              LiteralTerm('First Edition'),
            ),
          ]);

        // Serialize to RDF
        final turtle = rdfMapper.encodeObject(originalBook);

        // Verify the generated RDF contains both mapped and unmapped triples
        expect(turtle, contains('Test Book Late'));
        expect(turtle, contains('Test Author Late'));
        expect(turtle, contains('Test Series'));
        expect(turtle, contains('First Edition'));

        // Deserialize back to object
        final deserializedBook =
            rdfMapper.decodeObject<BookWithUnmappedTriplesLateFields>(turtle);

        // Verify all fields are correctly populated
        expect(deserializedBook.id, equals('test-book-456'));
        expect(deserializedBook.title, equals('Test Book Late'));
        expect(deserializedBook.author, equals('Test Author Late'));
        expect(deserializedBook.unmappedTriples.triples.length, equals(2));

        // Verify unmapped triples are preserved
        final unmappedTriples =
            deserializedBook.unmappedTriples.triples.toList();
        expect(
            unmappedTriples.any((t) =>
                t.predicate == const IriTerm('https://example.org/series') &&
                t.object == LiteralTerm('Test Series')),
            isTrue);
        expect(
            unmappedTriples.any((t) =>
                t.predicate == const IriTerm('https://example.org/edition') &&
                t.object == LiteralTerm('First Edition')),
            isTrue);
      });

      test('handles empty unmapped triples with late fields', () {
        final book = BookWithUnmappedTriplesLateFields()
          ..id = 'empty-late-book'
          ..title = 'Empty Late Book'
          ..author = 'Empty Late Author'
          ..unmappedTriples = RdfGraph(triples: []);

        final turtle = rdfMapper.encodeObject(book);
        final deserializedBook =
            rdfMapper.decodeObject<BookWithUnmappedTriplesLateFields>(turtle);

        expect(deserializedBook.id, equals('empty-late-book'));
        expect(deserializedBook.title, equals('Empty Late Book'));
        expect(deserializedBook.author, equals('Empty Late Author'));
        expect(deserializedBook.unmappedTriples.triples, isEmpty);
      });

      test('deserializes from RDF with extra triples correctly', () {
        const turtle = '''
          @prefix schema: <https://schema.org/> .
          @prefix ex: <https://example.org/> .
          
          <https://example.org/books/rdf-book> a schema:Book ;
            schema:name "RDF Book" ;
            schema:author "RDF Author" ;
            ex:customProperty "Custom Value" ;
            ex:anotherProperty "Another Value" .
        ''';

        final book =
            rdfMapper.decodeObject<BookWithUnmappedTriplesLateFields>(turtle);

        expect(book.id, equals('rdf-book'));
        expect(book.title, equals('RDF Book'));
        expect(book.author, equals('RDF Author'));
        expect(book.unmappedTriples.triples.length, equals(2));

        // Verify the custom properties are in unmapped triples
        final unmappedTriples = book.unmappedTriples.triples.toList();
        expect(
            unmappedTriples.any((t) =>
                t.predicate ==
                    const IriTerm('https://example.org/customProperty') &&
                t.object == LiteralTerm('Custom Value')),
            isTrue);
        expect(
            unmappedTriples.any((t) =>
                t.predicate ==
                    const IriTerm('https://example.org/anotherProperty') &&
                t.object == LiteralTerm('Another Value')),
            isTrue);
      });
    });

    group('Lossless round-trip tests', () {
      test('complete round-trip preserves all data for constructor parameters',
          () {
        const originalTurtle = '''
          @prefix schema: <https://schema.org/> .
          @prefix ex: <https://example.org/> .
          
          <https://example.org/books/roundtrip-book> a schema:Book ;
            schema:name "Round Trip Book" ;
            schema:author "Round Trip Author" ;
            ex:publisher "Round Trip Publisher" ;
            ex:year "2023" ;
            ex:genre "Technical" .
        ''';

        // Decode from original RDF
        final book =
            rdfMapper.decodeObject<BookWithUnmappedTriples>(originalTurtle);

        // Encode back to RDF
        final regeneratedTurtle = rdfMapper.encodeObject(book);

        // Decode again to verify everything is preserved
        final finalBook =
            rdfMapper.decodeObject<BookWithUnmappedTriples>(regeneratedTurtle);

        expect(finalBook.id, equals('roundtrip-book'));
        expect(finalBook.title, equals('Round Trip Book'));
        expect(finalBook.author, equals('Round Trip Author'));
        expect(finalBook.unmappedTriples.triples.length, equals(3));

        // Verify all unmapped triples are preserved
        final unmappedTriples = finalBook.unmappedTriples.triples.toList();
        expect(
            unmappedTriples.any((t) =>
                t.predicate == const IriTerm('https://example.org/publisher') &&
                t.object == LiteralTerm('Round Trip Publisher')),
            isTrue);
        expect(
            unmappedTriples.any((t) =>
                t.predicate == const IriTerm('https://example.org/year') &&
                t.object == LiteralTerm('2023')),
            isTrue);
        expect(
            unmappedTriples.any((t) =>
                t.predicate == const IriTerm('https://example.org/genre') &&
                t.object == LiteralTerm('Technical')),
            isTrue);
      });

      test('complete round-trip preserves all data for late fields', () {
        const originalTurtle = '''
          @prefix schema: <https://schema.org/> .
          @prefix ex: <https://example.org/> .
          
          <https://example.org/books/late-roundtrip-book> a schema:Book ;
            schema:name "Late Round Trip Book" ;
            schema:author "Late Round Trip Author" ;
            ex:language "English" ;
            ex:pages 200 ;
            ex:format "Paperback" .
        ''';

        // Decode from original RDF
        final book = rdfMapper
            .decodeObject<BookWithUnmappedTriplesLateFields>(originalTurtle);

        // Encode back to RDF
        final regeneratedTurtle = rdfMapper.encodeObject(book);

        // Decode again to verify everything is preserved
        final finalBook = rdfMapper
            .decodeObject<BookWithUnmappedTriplesLateFields>(regeneratedTurtle);

        expect(finalBook.id, equals('late-roundtrip-book'));
        expect(finalBook.title, equals('Late Round Trip Book'));
        expect(finalBook.author, equals('Late Round Trip Author'));
        expect(finalBook.unmappedTriples.triples.length, equals(3));

        // Verify all unmapped triples are preserved
        final unmappedTriples = finalBook.unmappedTriples.triples.toList();
        expect(
            unmappedTriples.any((t) =>
                t.predicate == const IriTerm('https://example.org/language') &&
                t.object == LiteralTerm('English')),
            isTrue);
        expect(
            unmappedTriples.any((t) =>
                t.predicate == const IriTerm('https://example.org/pages') &&
                t.object == LiteralTerm.integer(200)),
            isTrue);
        expect(
            unmappedTriples.any((t) =>
                t.predicate == const IriTerm('https://example.org/format') &&
                t.object == LiteralTerm('Paperback')),
            isTrue);
      });
    });
  });
}
