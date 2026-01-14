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

  static const Library = const IriTerm(_base + 'Library');
  static const Playlist = const IriTerm(_base + 'Playlist');
  static const Course = const IriTerm(_base + 'Course');

  static const books = const IriTerm(_base + 'books');
  static const orderedTracks = const IriTerm(_base + 'orderedTracks');
  static const modules = const IriTerm(_base + 'modules');
  static const prerequisites = const IriTerm(_base + 'prerequisites');
  static const alternatives = const IriTerm(_base + 'alternatives');
  static const tags = const IriTerm(_base + 'tags');
  static const collaborators = const IriTerm(_base + 'collaborators');
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
        const IriTerm('http://www.w3.org/2001/XMLSchema#date')),
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
