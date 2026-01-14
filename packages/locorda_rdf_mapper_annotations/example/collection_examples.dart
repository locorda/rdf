/// Comprehensive examples demonstrating different collection mapping strategies
/// using RDF Mapper Annotations.
///
/// This file showcases usage patterns for:
/// 1. Default collection behavior (multiple triples)
/// 2. Structured RDF collections
/// 3. Custom collection handling
/// 4. Item mapping within collections
///
/// **Quick Reference:**
/// - For most collections: Use default behavior (multiple triples)
/// - For ordered lists: Use collection: rdfList
/// - For numbered sequences: Use collection: rdfSeq
/// - For unordered collections: Use collection: rdfBag
/// - For alternatives: Use collection: rdfAlt
/// - For custom handling: Implement your own collection mapper
/// - For item-specific mapping: Use iri/literal/globalResource/localResource parameters
library;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

/// Example vocabulary for collection demonstrations
class CollectionVocab {
  static const _base = 'http://example.org/vocab#';

  static const Library = IriTerm(_base + 'Library');
  static const Playlist = IriTerm(_base + 'Playlist');
  static const Course = IriTerm(_base + 'Course');

  static const books = IriTerm(_base + 'books');
  static const orderedTracks = IriTerm(_base + 'orderedTracks');
  static const modules = IriTerm(_base + 'modules');
  static const prerequisites = IriTerm(_base + 'prerequisites');
  static const alternatives = IriTerm(_base + 'alternatives');
  static const tags = IriTerm(_base + 'tags');
  static const collaborators = IriTerm(_base + 'collaborators');
}

/// Example 1: Default collection behavior (multiple triples)
@RdfGlobalResource(
  CollectionVocab.Library,
  IriStrategy('{+baseUri}/library/{id}'),
)
class Library {
  @RdfIriPart()
  final String id;

  /// Default behavior: Creates multiple triples with same predicate
  /// Each book generates: `<library> vocab:books <book_resource>`
  @RdfProperty(CollectionVocab.books)
  final List<Book> books;

  /// Using Iterable for semantic clarity (order not preserved)
  @RdfProperty(CollectionVocab.collaborators)
  final Iterable<String> collaborators;

  Library({
    required this.id,
    required this.books,
    required this.collaborators,
  });
}

/// Example 2: Structured RDF collections using specific mappers
@RdfGlobalResource(
  CollectionVocab.Playlist,
  IriStrategy('{+baseUri}/playlist/{id}'),
)
class Playlist {
  @RdfIriPart()
  final String id;

  /// Creates ordered rdf:List structure (rdf:first/rdf:rest/rdf:nil)
  /// Preserves order in RDF representation
  @RdfProperty(CollectionVocab.orderedTracks, collection: rdfList)
  final List<Track> orderedTracks;

  Playlist({
    required this.id,
    required this.orderedTracks,
  });
}

/// Example 3: Different RDF collection structures
@RdfGlobalResource(
  CollectionVocab.Course,
  IriStrategy('{+baseUri}/course/{id}'),
)
class Course {
  @RdfIriPart()
  final String id;

  /// RDF Sequence - ordered collection with numeric properties
  @RdfProperty(CollectionVocab.modules, collection: rdfSeq)
  final List<Module> modules;

  /// RDF Bag - unordered collection allowing duplicates
  @RdfProperty(CollectionVocab.prerequisites, collection: rdfBag)
  final List<String> prerequisites;

  /// RDF Alternative - represents alternative values
  @RdfProperty(CollectionVocab.alternatives, collection: rdfAlt)
  final List<String> alternatives;

  Course({
    required this.id,
    required this.modules,
    required this.prerequisites,
    required this.alternatives,
  });
}

/// Example 4: Item mapping within collections
@RdfLocalResource()
class BookCollection {
  /// Default collection with custom IRI mapping for each item
  @RdfProperty(
    SchemaBook.author,
    iri: IriMapping('{+baseUri}/author/{authorIds}'),
  )
  final List<String> authorIds;

  /// Default collection with custom literal mapping for each item
  @RdfProperty(
    SchemaBook.keywords,
    literal: LiteralMapping.withLanguage('en'),
  )
  final List<String> keywords;

  /// Structured collection with custom item mapping
  @RdfProperty(
    SchemaBook.datePublished,
    collection: rdfList,
    literal: LiteralMapping.withType(
        IriTerm('http://www.w3.org/2001/XMLSchema#date')),
  )
  final List<DateTime> publicationDates;

  BookCollection({
    required this.authorIds,
    required this.keywords,
    required this.publicationDates,
  });
}

/// Supporting classes for examples
@RdfLocalResource()
class Book {
  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfProperty(SchemaBook.author)
  final String author;

  Book({required this.title, required this.author});
}

@RdfLocalResource()
class Track {
  @RdfProperty(SchemaMediaObject.name)
  final String title;

  /// Duration property - using appropriate schema term
  @RdfProperty(
      SchemaMediaObject.duration) // Placeholder for actual duration property
  final Duration duration;

  Track({required this.title, required this.duration});
}

@RdfLocalResource()
class Module {
  @RdfProperty(SchemaCreativeWork.name)
  final String name;

  @RdfProperty(SchemaCreativeWork.position)
  final int position;

  Module({required this.name, required this.position});
}

/// Example usage patterns (working examples)
void demonstrateCollectionMapping() {
  // Example 1: Default behavior - multiple triples
  final library = Library(
    id: 'main',
    books: [
      Book(title: 'Book 1', author: 'Author A'),
      Book(title: 'Book 2', author: 'Author B'),
    ],
    collaborators: ['Alice', 'Bob', 'Charlie'],
  );

  // Conceptual RDF output for default collections:
  // <library:main> vocab:books <_:book1> .
  // <library:main> vocab:books <_:book2> .
  // <library:main> vocab:collaborators "Alice" .
  // <library:main> vocab:collaborators "Bob" .
  // <library:main> vocab:collaborators "Charlie" .

  // Example 2: Ordered RDF List (when using RdfListMapper)
  final playlist = Playlist(
    id: 'rock-classics',
    orderedTracks: [
      Track(
          title: 'Bohemian Rhapsody',
          duration: Duration(minutes: 5, seconds: 55)),
      Track(
          title: 'Stairway to Heaven',
          duration: Duration(minutes: 8, seconds: 2)),
    ],
  );

  // Conceptual RDF output with RdfListMapper:
  // <playlist:rock-classics> vocab:orderedTracks _:list1 .
  // _:list1 rdf:first <_:track1> .
  // _:list1 rdf:rest _:list2 .
  // _:list2 rdf:first <_:track2> .
  // _:list2 rdf:rest rdf:nil .

  // Demonstrate different collection mappers conceptually
  print('Library has ${library.books.length} books');
  print('Playlist has ${playlist.orderedTracks.length} tracks');
}

/*
Collection Mapping Strategy Summary:

1. DEFAULT COLLECTIONS (List, Set, Iterable):
   - Creates multiple triples with same predicate
   - Order not preserved in RDF
   - Each item handled separately
   - Uses UnorderedItemsListMapper, UnorderedItemsSetMapper, etc.

2. STRUCTURED RDF COLLECTIONS:
   - collection: rdfList → ordered rdf:List with rdf:first/rdf:rest/rdf:nil
   - collection: rdfSeq → rdf:Seq with numeric properties
   - collection: rdfBag → rdf:Bag for unordered collections
   - collection: rdfAlt → rdf:Alt for alternative values

3. CUSTOM COLLECTION HANDLING:
   - Implement custom mapper for specific collection behavior
   - Can treat entire collection as single value
   - Full control over RDF representation

4. ITEM MAPPING:
   - Use iri/literal/globalResource/localResource for individual items
   - Applies to each collection element separately
   - Works with both default and structured collections
*/
