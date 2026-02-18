// ignore_for_file: unused_element

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';

/// Example demonstrating vocabulary generation with the `.define()` constructor.
///
/// This example shows how to use the `.define()` constructor to automatically
/// generate a vocabulary (Turtle/RDF file) from your Dart class structure.
///
/// The vocabulary generation happens at build time and produces a `.ttl` file
/// containing:
/// - Class definitions (owl:Class)
/// - Property definitions (rdf:Property)
/// - Metadata (labels, comments, custom predicates)
/// - Class hierarchies (rdfs:subClassOf)
///
/// Note: All properties are typed as rdf:Property by default. If you need more
/// specific types (owl:ObjectProperty or owl:DatatypeProperty), add them via
/// the metadata parameter on @RdfProperty.define()
///
/// To trigger vocabulary generation:
/// 1. Add the locorda_rdf_mapper_generator dependency to dev_dependencies
/// 2. Add locorda_rdf_terms_generator dependency to dev_dependencies
/// 3. Configure build.yaml with the vocab_generator builder
/// 4. Run: dart run build_runner build
///
/// The generated vocabulary file will be placed according to your build.yaml
/// configuration.

// ============================================================================
// Step 1: Define Application Vocabulary Configuration
// ============================================================================

/// Application vocabulary configuration.
///
/// This defines where your vocabulary will be published and how it's structured.
const appVocab = AppVocab(
  appBaseUri: 'https://example.org',
  vocabPath: '/vocab/library',
);

// ============================================================================
// Step 2: Define Global Resources with Vocabulary Generation
// ============================================================================

/// A book resource with comprehensive vocabulary metadata.
///
/// Generated vocabulary will include:
/// - Class IRI: https://example.org/vocab/library#Book
/// - rdfs:subClassOf: http://schema.org/Book
/// - rdfs:label: "Book"
/// - rdfs:comment: "A published book with bibliographic metadata"
/// - Custom metadata predicates
@RdfGlobalResource.define(
  appVocab,
  IriStrategy('https://example.org/books/{isbn}'),
  subClassOf: SchemaBook.classIri,
  label: 'Book',
  comment: 'A published book with bibliographic metadata',
  metadata: [
    // Version information
    (
      IriTerm('http://www.w3.org/2002/07/owl#versionInfo'),
      LiteralTerm('1.0.0')
    ),
    // Creation date
    (
      IriTerm('http://purl.org/dc/terms/created'),
      LiteralTerm.withDatatype('2026-02-18', Xsd.date)
    ),
  ],
)
class Book {
  /// The ISBN uniquely identifies the book and is used in the IRI strategy.
  @RdfIriPart('isbn')
  final String isbn;

  /// Book title - will be automatically included in vocabulary.
  ///
  /// Generated property IRI: https://example.org/vocab/library#title
  /// Since no @RdfProperty.define() is specified, the property name is used
  /// as the fragment identifier.
  final String title;

  /// Author name with custom fragment identifier.
  ///
  /// Generated property IRI: https://example.org/vocab/library#bookAuthor
  /// The custom fragment 'bookAuthor' overrides the default field name 'author'.
  @RdfProperty.define(fragment: 'bookAuthor')
  final String author;

  /// Publication date with label and comment.
  ///
  /// Generated property will include:
  /// - Property IRI: https://example.org/vocab/library#publicationDate
  /// - rdfs:label: "Publication Date"
  /// - rdfs:comment: "The date when the book was first published"
  @RdfProperty.define(
    fragment: 'publicationDate',
    label: 'Publication Date',
    comment: 'The date when the book was first published',
  )
  final DateTime publishedDate;

  /// Publisher relationship with comprehensive metadata.
  ///
  /// Demonstrates:
  /// - Object property (references another resource)
  /// - Custom metadata predicates
  /// - Relationship to external vocabulary
  /// - Overriding property type to owl:ObjectProperty
  @RdfProperty.define(
    fragment: 'publisher',
    label: 'Publisher',
    comment: 'The organization that published the book',
    metadata: [
      // Override default rdf:Property to be more specific
      (
        IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
        IriTerm('http://www.w3.org/2002/07/owl#ObjectProperty')
      ),
      (
        IriTerm('http://www.w3.org/2000/01/rdf-schema#range'),
        IriTerm('https://example.org/vocab/library#Publisher')
      ),
    ],
  )
  final Publisher publisher;

  /// Chapters as a collection of local resources.
  ///
  /// Generated property IRI: https://example.org/vocab/library#chapters
  /// The range will be the Chapter class defined below.
  final Iterable<Chapter> chapters;

  Book({
    required this.isbn,
    required this.title,
    required this.author,
    required this.publishedDate,
    required this.publisher,
    required this.chapters,
  });
}

/// Publisher resource demonstrating minimal vocabulary metadata.
///
/// Generated vocabulary will include:
/// - Class IRI: https://example.org/vocab/library#Publisher
/// - rdfs:subClassOf: http://schema.org/Organization
@RdfGlobalResource.define(
  appVocab,
  IriStrategy('https://example.org/publishers/{id}'),
  subClassOf: IriTerm('http://schema.org/Organization'),
)
class Publisher {
  @RdfIriPart('id')
  final String id;

  /// Publisher name - automatically included in vocabulary.
  final String name;

  /// Foundation year with custom fragment.
  @RdfProperty.define(fragment: 'foundedYear')
  final int founded;

  Publisher({
    required this.id,
    required this.name,
    required this.founded,
  });
}

// ============================================================================
// Step 3: Define Local Resources (Blank Nodes) with Vocabulary Generation
// ============================================================================

/// Chapter as a local resource (blank node).
///
/// Local resources don't have unique IRIs in the RDF graph, but they still
/// contribute to the vocabulary with class and property definitions.
///
/// Generated vocabulary will include:
/// - Class IRI: https://example.org/vocab/library#Chapter
/// - rdfs:subClassOf: http://schema.org/Chapter
@RdfLocalResource.define(
  appVocab,
  subClassOf: IriTerm('http://schema.org/Chapter'),
  label: 'Chapter',
  comment: 'A chapter within a book',
)
class Chapter {
  /// Chapter title - automatically included.
  final String title;

  /// Chapter number with label and comment.
  @RdfProperty.define(
    fragment: 'chapterNumber',
    label: 'Chapter Number',
    comment: 'The sequential number of the chapter within the book',
  )
  final int number;

  /// Page count - demonstrates datatype property.
  @RdfProperty.define(fragment: 'pageCount')
  final int pages;

  Chapter({
    required this.title,
    required this.number,
    required this.pages,
  });
}

// ============================================================================
// Step 4: Combining with Runtime Mapping
// ============================================================================

/// The same classes can be used for both vocabulary generation and runtime
/// mapping. The generated mappers work alongside the vocabulary definitions.
///
/// When using `.define()`:
/// 1. Vocabulary generation: Creates .ttl file with class/property definitions
/// 2. Mapper generation: Creates runtime mappers (if registerGlobally: true)
///
/// You can control mapper generation with parameters:
/// - registerGlobally: true (default) - mapper is registered in initRdfMapper
/// - direction: both (default), toRdf, or fromRdf - controls mapping direction

/// Example with serialize-only mapper and vocabulary generation.
@RdfGlobalResource.define(
  appVocab,
  IriStrategy('https://example.org/reviews/{id}'),
  direction: MapperDirection.serializeOnly,
  label: 'Review',
  comment: 'A review of a book',
)
class Review {
  @RdfIriPart('id')
  final String id;

  /// Rating value (1-5).
  @RdfProperty.define(
    fragment: 'rating',
    label: 'Rating',
    comment: 'Numeric rating from 1 to 5',
  )
  final int rating;

  /// Review text.
  final String text;

  Review({
    required this.id,
    required this.rating,
    required this.text,
  });
}

// ============================================================================
// Expected Generated Vocabulary (Excerpt)
// ============================================================================

// The build process will generate a Turtle file similar to:
//
// @prefix : <https://example.org/vocab/library#> .
// @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
// @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
// @prefix owl: <http://www.w3.org/2002/07/owl#> .
// @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
// @prefix schema: <http://schema.org/> .
//
// :Book a owl:Class ;
//     rdfs:subClassOf schema:Book ;
//     rdfs:label "Book" ;
//     rdfs:comment "A published book with bibliographic metadata" ;
//     owl:versionInfo "1.0.0" ;
//     <http://purl.org/dc/terms/created> "2026-02-18"^^xsd:date .
//
// :title a rdf:Property ;
//     rdfs:domain :Book .
//
// :bookAuthor a rdf:Property ;
//     rdfs:domain :Book .
//
// :publicationDate a rdf:Property ;
//     rdfs:domain :Book ;
//     rdfs:label "Publication Date" ;
//     rdfs:comment "The date when the book was first published" .
//
// :publisher a owl:ObjectProperty ;  # Overridden via metadata
//     rdfs:domain :Book ;
//     rdfs:label "Publisher" ;
//     rdfs:comment "The organization that published the book" ;
//     rdfs:range :Publisher .
//
// :chapters a rdf:Property ;
//     rdfs:domain :Book .
//
// :Publisher a owl:Class ;
//     rdfs:subClassOf schema:Organization .
//
// :Chapter a owl:Class ;
//     rdfs:subClassOf schema:Chapter ;
//     rdfs:label "Chapter" ;
//     rdfs:comment "A chapter within a book" .
//
// (... and so on for all properties)
