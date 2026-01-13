import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:test/test.dart';
import '../fixtures/rdf_mapper_annotations/examples/custom_collection_type_example.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
  group(
      'Custom Collection Type Example Mappers Tests (Precise Pattern Validation)',
      () {
    late RdfMapper mapper;

    setUp(() {
      mapper = defaultInitTestRdfMapper();
    });

    test('should generate correct RDF List pattern for collaborators', () {
      final library = Library();
      library.id = 'lib:test';
      library.collaborators = ImmutableList(['Alice', 'Bob', 'Charlie']);
      library.tags =
          ImmutableList<String>([]); // Empty to focus on collaborators
      library.members = ImmutableList<String>([]);

      final rdfContent =
          mapper.encodeObject(library, contentType: 'application/n-triples');

      // Verify RDF List structure - should have proper chain with rdf:first/rdf:rest
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "Alice"'));
      expect(rdfContent,
          contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "Bob"'));
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "Charlie"'));

      // Should have rdf:rest chain
      expect(rdfContent,
          contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#rest>'));

      // Last element should point to rdf:nil
      expect(rdfContent,
          contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#nil>'));

      // Should have rdf:List type declaration
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#List>'));

      // Verify proper linking pattern: count blank nodes
      final restMatches =
          RegExp(r'<http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> _:b\d+')
              .allMatches(rdfContent);
      expect(restMatches.length,
          equals(2)); // Two intermediate nodes (Alice->Bob, Bob->Charlie)

      final nilMatches = RegExp(
              r'<http://www.w3.org/1999/02/22-rdf-syntax-ns#rest> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil>')
          .allMatches(rdfContent);
      expect(nilMatches.length, equals(1)); // One termination
    });

    test('should generate correct RDF Seq pattern for tags', () {
      final library = Library();
      library.id = 'lib:test';
      library.collaborators = ImmutableList<String>([]);
      library.tags = ImmutableList(['science', 'technology', 'research']);
      library.members = ImmutableList<String>([]);

      final rdfContent =
          mapper.encodeObject(library, contentType: 'application/n-triples');

      // Verify RDF Seq structure - should use numbered properties
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#_1> "science"'));
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#_2> "technology"'));
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#_3> "research"'));

      // Should have rdf:Seq type declaration
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Seq>'));

      // Should NOT contain rdf:first, rdf:rest for tags (those are for Lists)
      // Note: rdf:nil might appear for empty collaborators collection
      expect(
          rdfContent,
          isNot(
              contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#first>')));
      expect(rdfContent,
          isNot(contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#rest>')));

      // Verify exact pattern: each item should be on a numbered property of a single blank node
      final seqPattern = RegExp(
          r'(_:b\d+) <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#_(\d+)> "(\w+)"');
      final matches = seqPattern.allMatches(rdfContent);
      expect(matches.length, equals(3));

      // Extract and verify sequence
      final items = <int, String>{};
      String? seqNode;
      for (final match in matches) {
        final node = match.group(1)!;
        final index = int.parse(match.group(2)!);
        final value = match.group(3)!;

        if (seqNode == null) {
          seqNode = node;
        } else {
          expect(node, equals(seqNode),
              reason: 'All items should be on the same sequence node');
        }

        items[index] = value;
      }

      expect(items[1], equals('science'));
      expect(items[2], equals('technology'));
      expect(items[3], equals('research'));
    });

    test('should generate correct unordered items pattern for members', () {
      final library = Library();
      library.id = 'lib:test';
      library.collaborators = ImmutableList<String>([]);
      library.tags = ImmutableList<String>([]);
      library.members = ImmutableList(['member1', 'member2', 'member3']);

      final rdfContent =
          mapper.encodeObject(library, contentType: 'application/n-triples');

      // Verify unordered items pattern - multiple triples with same predicate
      expect(
          rdfContent, contains('<http://example.org/vocab#members> "member1"'));
      expect(
          rdfContent, contains('<http://example.org/vocab#members> "member2"'));
      expect(
          rdfContent, contains('<http://example.org/vocab#members> "member3"'));

      // Should NOT contain RDF List or Seq patterns for the members collection specifically
      // Note: Other collections (collaborators/tags) might have their own patterns
      expect(
          rdfContent,
          isNot(
              contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#first>')));
      expect(rdfContent,
          isNot(contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_1>')));

      // Count exact occurrences of the members predicate
      final memberPattern = RegExp(
          r'<http://example\.org/library/lib:test> <http://example\.org/vocab#members> "member\d+"');
      final matches = memberPattern.allMatches(rdfContent);
      expect(matches.length, equals(3),
          reason: 'Should have exactly 3 member triples');

      // Verify no blank nodes are used for members (direct property assertions)
      final memberWithBlankNode =
          RegExp(r'<http://example\.org/vocab#members> _:b\d+');
      expect(memberWithBlankNode.hasMatch(rdfContent), isFalse,
          reason: 'Unordered items should not use blank nodes');
    });

    test(
        'should generate distinct patterns for each collection type in same object',
        () {
      final library = Library();
      library.id = 'lib:comprehensive';
      library.collaborators = ImmutableList(['Alice', 'Bob']); // RDF List
      library.tags = ImmutableList(['tag1', 'tag2']); // RDF Seq
      library.members =
          ImmutableList(['member1', 'member2']); // Unordered items

      final rdfContent =
          mapper.encodeObject(library, contentType: 'application/n-triples');

      // RDF List patterns for collaborators
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#List>'));
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "Alice"'));
      expect(rdfContent,
          contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#first> "Bob"'));

      // RDF Seq patterns for tags
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Seq>'));
      expect(rdfContent,
          contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_1> "tag1"'));
      expect(rdfContent,
          contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#_2> "tag2"'));

      // Unordered items patterns for members (no collections, direct assertions)
      final memberPattern = RegExp(
          r'<http://example\.org/library/lib:comprehensive> <http://example\.org/vocab#members> "member\d+"');
      final memberMatches = memberPattern.allMatches(rdfContent);
      expect(memberMatches.length, equals(2));

      // Verify structure isolation: each collection type should use different blank nodes
      final listNodes = RegExp(
              r'(_:b\d+) <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#type> <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#List>')
          .allMatches(rdfContent)
          .map((m) => m.group(1))
          .toSet();
      final seqNodes = RegExp(
              r'(_:b\d+) <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#type> <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#Seq>')
          .allMatches(rdfContent)
          .map((m) => m.group(1))
          .toSet();

      expect(listNodes.length, equals(1),
          reason: 'Should have exactly one List container');
      expect(seqNodes.length, equals(1),
          reason: 'Should have exactly one Seq container');
      expect(listNodes.intersection(seqNodes).isEmpty, isTrue,
          reason: 'List and Seq should use different blank nodes');
    });

    test(
        'should handle empty collections with correct empty collection patterns',
        () {
      final library = Library();
      library.id = 'lib:empty';
      library.collaborators = ImmutableList<String>([]);
      library.tags = ImmutableList<String>([]);
      library.members = ImmutableList<String>([]);

      final rdfContent =
          mapper.encodeObject(library, contentType: 'application/n-triples');

      // Should contain the basic resource declaration
      expect(rdfContent, contains('<http://example.org/library/lib:empty>'));
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://example.org/vocab#Library>'));

      // Empty collections are still serialized with their structure:
      // - Empty RDF List points to rdf:nil
      expect(
          rdfContent,
          contains(
              '<http://example.org/vocab#collaborators> <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil>'));
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#nil> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#List>'));

      // - Empty RDF Seq creates empty container
      expect(rdfContent, contains('<http://example.org/vocab#tags>'));
      expect(
          rdfContent,
          contains(
              '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Seq>'));

      // - Empty unordered items collection should NOT appear (no triples for members)
      expect(rdfContent, isNot(contains('<http://example.org/vocab#members>')));

      // Should NOT contain any actual data values
      expect(rdfContent, isNot(contains('"'))); // No string literals
    });
  });
}
