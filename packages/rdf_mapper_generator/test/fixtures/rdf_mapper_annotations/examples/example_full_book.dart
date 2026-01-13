import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_schema/schema.dart';

/// This file demonstrates how the annotations can be used to mark up model classes
/// for automatic mapper generation.

// --- Annotated Model Classes ---

@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('http://example.org/book/{id}'),
)
class Book {
  @RdfIriPart('id')
  final String id;

  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfProperty(
    SchemaBook.author,
    iri: IriMapping('http://example.org/author/{authorId}'),
  )
  final String authorId;

  @RdfProperty(SchemaBook.datePublished)
  final DateTime published;

  // The mode is automatically detected from the @RdfIri annotation on the ISBN class, we do not need to
  // know here that it is actually mapped to a IriTerm and not a LiteralTerm.
  @RdfProperty(SchemaBook.isbn)
  final ISBN isbn;

  // Note how we use an (annotated) custom class for the rating which essentially is an int.
  @RdfProperty(SchemaBook.aggregateRating)
  final Rating rating;

  // And even an enum can be used here, serialized as IRI in this case.
  @RdfProperty(SchemaBook.bookFormat)
  final BookFormat? format;

  // Iterable type is automatically detected, Chapter is also automatically detected.
  @RdfProperty(SchemaBook.hasPart)
  final Iterable<Chapter> chapters;

  Book({
    required this.id,
    required this.title,
    required this.authorId,
    required this.published,
    required this.isbn,
    required this.rating,
    required this.format,
    required this.chapters,
  });
}

@RdfLocalResource(SchemaChapter.classIri)
class Chapter {
  @RdfProperty(SchemaChapter.name)
  final String title;

  @RdfProperty(SchemaChapter.position)
  final int number;

  Chapter(this.title, this.number);
}

@RdfIri('urn:isbn:{value}')
class ISBN {
  @RdfIriPart() // marks this property as the value source
  final String value;

  ISBN(this.value);
}

@RdfLiteral()
class Rating {
  @RdfValue()
  final int stars;

  Rating(this.stars) {
    if (stars < 0 || stars > 5) {
      throw ArgumentError('Rating must be between 0 and 5 stars');
    }
  }
}

@RdfIri("https://schema.org/{value}")
enum BookFormat {
  @RdfEnumValue("AudiobookFormat")
  audiobook,
  @RdfEnumValue("Hardcover")
  hardcover,
  @RdfEnumValue("Paperback")
  paperback,
  @RdfEnumValue("Ebook")
  ebook,
  @RdfEnumValue("GraphicNovel")
  graphicNovel,
}
