import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';

import '../fixtures/rdf_mapper_annotations/examples/collection_examples.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
  group('Collection Examples Mappers Tests (Precise Pattern Validation)', () {
    late RdfMapper mapper;

    setUp(() {
      mapper = defaultInitTestRdfMapper(
          rdfMapper: RdfMapper.withMappers(
              (r) => r..registerMapper(_DurationMapper())));
    });

    test('should generate correct default collection pattern for Library books',
        () {
      final book1 = Book(title: 'Clean Code', author: 'Robert C. Martin');
      final book2 = Book(title: 'Effective Dart', author: 'Dart Team');

      final library = Library(
        id: 'lib:test',
        books: [book1, book2],
        collaborators: [], // Focus on books collection
      );

      final rdfContent =
          mapper.encodeObject(library, contentType: 'application/n-triples');

      // Default collection behavior: multiple triples with same predicate, no containers
      expect(
          rdfContent,
          contains(
              '<http://example.org/library/lib:test> <http://example.org/vocab#books>'));
      expect(rdfContent, contains('"Clean Code"'));
      expect(rdfContent, contains('"Effective Dart"'));
      expect(rdfContent, contains('"Robert C. Martin"'));
      expect(rdfContent, contains('"Dart Team"'));

      // Should NOT use any RDF container structures for default collections
      expect(
          rdfContent,
          isNot(contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#List>')));
      expect(
          rdfContent,
          isNot(contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Seq>')));
      expect(
          rdfContent,
          isNot(contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Bag>')));
      expect(
          rdfContent,
          isNot(
              contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#first>')));
      expect(rdfContent,
          isNot(contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_1>')));

      // Count books property assertions - should have 2 book triples (one per book)
      final bookTriples = RegExp(
              r'<http://example\.org/library/lib:test> <http://example\.org/vocab#books> _:b\d+')
          .allMatches(rdfContent);
      expect(bookTriples.length, equals(2),
          reason: 'Should have exactly 2 book triples');
    });

    test(
        'should generate correct default collection pattern for Library collaborators',
        () {
      final library = Library(
        id: 'lib:test',
        books: [], // Focus on collaborators
        collaborators: ['Alice', 'Bob', 'Charlie'],
      );

      final rdfContent =
          mapper.encodeObject(library, contentType: 'application/n-triples');

      // Default collection behavior: multiple triples with same predicate for string literals
      expect(rdfContent,
          contains('<http://example.org/vocab#collaborators> "Alice"'));
      expect(rdfContent,
          contains('<http://example.org/vocab#collaborators> "Bob"'));
      expect(rdfContent,
          contains('<http://example.org/vocab#collaborators> "Charlie"'));

      // Should NOT use RDF container structures
      expect(
          rdfContent,
          isNot(
              contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#first>')));
      expect(rdfContent,
          isNot(contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_1>')));

      // Count collaborator property assertions
      final collaboratorTriples = RegExp(
              r'<http://example\.org/library/lib:test> <http://example\.org/vocab#collaborators> "[\w]+"')
          .allMatches(rdfContent);
      expect(collaboratorTriples.length, equals(3),
          reason: 'Should have exactly 3 collaborator triples');
    });

    test('should generate correct RDF List pattern for Playlist orderedTracks',
        () {
      // Skip Duration serialization issues by using simple tracks
      final track1 = Track(
          title: 'Bohemian Rhapsody',
          duration: Duration(minutes: 5, seconds: 55));
      final track2 = Track(
          title: 'Stairway to Heaven',
          duration: Duration(minutes: 8, seconds: 2));

      final playlist = Playlist(
        id: 'playlist:test',
        orderedTracks: [track1, track2],
      );

      final rdfContent =
          mapper.encodeObject(playlist, contentType: 'application/n-triples');

      // RDF List structure for ordered tracks
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#List>'));
      expect(rdfContent,
          contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#first>'));
      expect(rdfContent,
          contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#rest>'));
      expect(rdfContent,
          contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#nil>'));

      // Track data should be present
      expect(rdfContent, contains('"Bohemian Rhapsody"'));
      expect(rdfContent, contains('"Stairway to Heaven"'));

      // Should NOT use other container types
      expect(
          rdfContent,
          isNot(contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Seq>')));
      expect(rdfContent,
          isNot(contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_1>')));

      // Verify RDF List chain structure
      final restTriples =
          RegExp(r'<http://www\.w3\.org/1999/02/22-rdf-syntax-ns#rest>')
              .allMatches(rdfContent);
      expect(restTriples.length, greaterThanOrEqualTo(2),
          reason: 'Should have rest properties in List chain');
    });

    test('should generate correct RDF Seq pattern for Course modules', () {
      final module1 = Module(name: 'Introduction', position: 1);
      final module2 = Module(name: 'Advanced Topics', position: 2);
      final module3 = Module(name: 'Conclusion', position: 3);

      final course = Course(
        id: 'course:test',
        modules: [module1, module2, module3],
        prerequisites: [], // Focus on modules
        alternatives: [],
      );

      final rdfContent =
          mapper.encodeObject(course, contentType: 'application/n-triples');

      // RDF Seq structure for modules
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Seq>'));
      expect(rdfContent,
          contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_1>'));
      expect(rdfContent,
          contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_2>'));
      expect(rdfContent,
          contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_3>'));

      // Module data should be present
      expect(rdfContent, contains('"Introduction"'));
      expect(rdfContent, contains('"Advanced Topics"'));
      expect(rdfContent, contains('"Conclusion"'));

      // Should NOT use RDF List patterns
      expect(
          rdfContent,
          isNot(
              contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#first>')));
      expect(rdfContent,
          isNot(contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#rest>')));

      // Verify ordered sequence structure
      final seqPattern = RegExp(
          r'(_:b\d+) <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#_(\d+)>');
      final matches = seqPattern.allMatches(rdfContent);
      expect(matches.length, equals(3),
          reason: 'Should have exactly 3 numbered sequence items');

      // Verify all items use same container node
      final seqNodes = matches.map((m) => m.group(1)).toSet();
      expect(seqNodes.length, equals(1),
          reason: 'All sequence items should use same container node');
    });

    test('should generate correct RDF Bag pattern for Course prerequisites',
        () {
      final course = Course(
        id: 'course:test',
        modules: [], // Focus on prerequisites
        prerequisites: ['math101', 'logic101', 'intro101'],
        alternatives: [],
      );

      final rdfContent =
          mapper.encodeObject(course, contentType: 'application/n-triples');

      // RDF Bag structure for prerequisites
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Bag>'));
      expect(rdfContent, contains('"math101"'));
      expect(rdfContent, contains('"logic101"'));
      expect(rdfContent, contains('"intro101"'));

      // Should use numbered properties like Seq (Bag uses same structure)
      expect(
          rdfContent,
          anyOf([
            contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_1>'),
            contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_2>'),
            contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_3>')
          ]));

      // Should NOT use RDF List patterns
      expect(
          rdfContent,
          isNot(
              contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#first>')));
      expect(rdfContent,
          isNot(contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#rest>')));
    });

    test('should generate correct RDF Alt pattern for Course alternatives', () {
      final course = Course(
        id: 'course:test',
        modules: [],
        prerequisites: [], // Focus on alternatives
        alternatives: ['cs102', 'cs103', 'math201'],
      );

      final rdfContent =
          mapper.encodeObject(course, contentType: 'application/n-triples');

      // RDF Alt structure for alternatives
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Alt>'));
      expect(rdfContent, contains('"cs102"'));
      expect(rdfContent, contains('"cs103"'));
      expect(rdfContent, contains('"math201"'));

      // Should use numbered properties like Seq/Bag
      expect(
          rdfContent,
          anyOf([
            contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_1>'),
            contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_2>'),
            contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_3>')
          ]));

      // Should NOT use RDF List patterns
      expect(
          rdfContent,
          isNot(
              contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#first>')));
      expect(rdfContent,
          isNot(contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#rest>')));
    });

    test(
        'should generate distinct patterns for different collection types in same Course',
        () {
      final module1 = Module(name: 'Module1', position: 1);
      final course = Course(
        id: 'course:comprehensive',
        modules: [module1], // RDF Seq
        prerequisites: ['math101'], // RDF Bag
        alternatives: ['cs102'], // RDF Alt
      );

      final rdfContent =
          mapper.encodeObject(course, contentType: 'application/n-triples');

      // Should have all three container types
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Seq>'));
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Bag>'));
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Alt>'));

      // Verify each uses different container nodes
      final seqNodes = RegExp(
              r'(_:b\d+) <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#type> <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#Seq>')
          .allMatches(rdfContent)
          .map((m) => m.group(1))
          .toSet();
      final bagNodes = RegExp(
              r'(_:b\d+) <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#type> <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#Bag>')
          .allMatches(rdfContent)
          .map((m) => m.group(1))
          .toSet();
      final altNodes = RegExp(
              r'(_:b\d+) <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#type> <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#Alt>')
          .allMatches(rdfContent)
          .map((m) => m.group(1))
          .toSet();

      expect(seqNodes.length, equals(1));
      expect(bagNodes.length, equals(1));
      expect(altNodes.length, equals(1));
      expect(seqNodes.intersection(bagNodes).isEmpty, isTrue);
      expect(seqNodes.intersection(altNodes).isEmpty, isTrue);
      expect(bagNodes.intersection(altNodes).isEmpty, isTrue);
    });

    test('should handle BookCollection item mappings correctly', () {
      final bookCollection = BookCollection(
        authorIds: ['author1', 'author2'],
        keywords: ['science', 'technology'],
        publicationDates: [DateTime(2020, 1, 1), DateTime(2021, 6, 15)],
      );

      final rdfContent = mapper.encodeObject(bookCollection,
          contentType: 'application/n-triples');

      // AuthorIds are mapped as IRIs, not string literals
      expect(rdfContent, contains('<http://example.org/author/author1>'));
      expect(rdfContent, contains('<http://example.org/author/author2>'));
      expect(rdfContent, contains('<https://schema.org/author>'));

      // Keywords are string literals with language tags
      expect(rdfContent, contains('"science"@en'));
      expect(rdfContent, contains('"technology"@en'));
      expect(rdfContent, contains('<https://schema.org/keywords>'));

      // Publication dates are in RDF List structure with xsd:date types
      expect(rdfContent, contains('<https://schema.org/datePublished>'));
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#List>'));
      expect(rdfContent,
          contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#first>'));
      expect(rdfContent, contains('^^<http://www.w3.org/2001/XMLSchema#date>'));

      // Date values (UTC converted)
      expect(
          rdfContent,
          anyOf([
            contains('2020-01-01'),
            contains('2019-12-31T23:00:00.000Z'),
          ]));
      expect(
          rdfContent,
          anyOf([
            contains('2021-06-15'),
            contains('2021-06-14T22:00:00.000Z'),
          ]));
    });

    test(
        'should handle empty collections with correct empty container patterns',
        () {
      final library = Library(id: 'lib:empty', books: [], collaborators: []);
      final course = Course(
          id: 'course:empty', modules: [], prerequisites: [], alternatives: []);

      final libraryRdf =
          mapper.encodeObject(library, contentType: 'application/n-triples');
      final courseRdf =
          mapper.encodeObject(course, contentType: 'application/n-triples');

      // Empty default collections (Library) should not appear in RDF
      expect(libraryRdf, isNot(contains('<http://example.org/vocab#books>')));
      expect(libraryRdf,
          isNot(contains('<http://example.org/vocab#collaborators>')));

      // Empty structured collections (Course) should still create empty containers
      expect(courseRdf, contains('<http://example.org/vocab#modules>'));
      expect(courseRdf, contains('<http://example.org/vocab#prerequisites>'));
      expect(courseRdf, contains('<http://example.org/vocab#alternatives>'));
      expect(
          courseRdf,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Seq>'));
      expect(
          courseRdf,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Bag>'));
      expect(
          courseRdf,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Alt>'));

      // Should not contain any data values
      expect(courseRdf, isNot(contains('"')),
          reason: 'Empty collections should not contain string literals');
    });

    test('should preserve order in RDF List but not in default collections',
        () {
      final track1 = Track(title: 'First', duration: Duration(minutes: 3));
      final track2 = Track(title: 'Second', duration: Duration(minutes: 4));
      final track3 = Track(title: 'Third', duration: Duration(minutes: 5));

      final playlist = Playlist(
        id: 'playlist:order',
        orderedTracks: [track1, track2, track3],
      );

      final rdfContent =
          mapper.encodeObject(playlist, contentType: 'application/n-triples');

      // Round-trip test to verify order preservation
      final deserialized = mapper.decodeObject<Playlist>(rdfContent,
          contentType: 'application/n-triples');
      expect(deserialized, isNotNull);
      expect(deserialized.orderedTracks, hasLength(3));
      expect(deserialized.orderedTracks[0].title, equals('First'));
      expect(deserialized.orderedTracks[1].title, equals('Second'));
      expect(deserialized.orderedTracks[2].title, equals('Third'));
    });
  });
}

/// A mapper for Dart Duration to/from RDF literal terms.
///
/// Serializes Duration as microseconds in an XSD integer format.
final class _DurationMapper extends BaseRdfLiteralTermMapper<Duration> {
  const _DurationMapper() : super(datatype: Xsd.integer);

  @override
  Duration convertFromLiteral(LiteralTerm term, _) =>
      Duration(microseconds: int.parse(term.value));

  @override
  String convertToString(Duration duration) =>
      duration.inMicroseconds.toString();
}
