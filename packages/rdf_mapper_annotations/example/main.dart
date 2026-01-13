import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_schema/schema.dart';

/// This file demonstrates how the annotations can be used to mark up model classes
/// for automatic mapper generation.

// --- Annotated Model Classes ---

@RdfGlobalResource(
    SchemaBook.classIri, IriStrategy('http://example.org/book/{id}'))
class Book {
  @RdfIriPart('id')
  final String id;

  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfProperty(SchemaBook.author,
      iri: IriMapping('http://example.org/author/{authorId}'))
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
  final BookFormat format;

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

// --- The mappers below demonstrate what would be generated ---
// --- See below the main() function for an example of how to use them ---
class BookAuthorIdMapper implements IriTermMapper<String> {
  static final RegExp _regex = RegExp(
    r'^http://example\.org/author/(?<authorId>[^/]*)$',
  );

  /// Constructor
  const BookAuthorIdMapper();

  @override
  String fromRdfTerm(IriTerm term, DeserializationContext context) {
    /// Parses IRI parts from a complete IRI using a template.
    final RegExpMatch? match = _regex.firstMatch(term.value);

    final iriParts = {
      for (var name in match?.groupNames ?? const <String>[])
        name: match?.namedGroup(name) ?? '',
    };
    return iriParts['authorId']!;
  }

  @override
  IriTerm toRdfTerm(
    String iriTermValue,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final authorId = iriTermValue.toString();
    return context.createIriTerm('http://example.org/author/${authorId}');
  }
}

/// Generated mapper for [Book] global resources.
///
/// This mapper handles serialization and deserialization between Dart objects
/// and RDF triples for resources of type Book.
class BookMapper implements GlobalResourceMapper<Book> {
  static final RegExp _regex = RegExp(
    r'^http://example\.org/book/(?<id>[^/]*)$',
  );

  final IriTermMapper<String> _authorIdMapper;

  /// Constructor
  const BookMapper({
    IriTermMapper<String> authorIdMapper = const BookAuthorIdMapper(),
  }) : _authorIdMapper = authorIdMapper;

  @override
  IriTerm? get typeIri => SchemaBook.classIri;

  @override
  Book fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);

    final RegExpMatch? match = _regex.firstMatch(subject.value);

    final iriParts = {
      for (var name in (match?.groupNames ?? const <String>[]))
        name: match?.namedGroup(name) ?? '',
    };

    final id = iriParts['id']!;
    final String title = reader.require(SchemaBook.name);
    final String authorId = reader.require(
      SchemaBook.author,
      deserializer: _authorIdMapper,
    );
    final DateTime published = reader.require(SchemaBook.datePublished);
    final ISBN isbn = reader.require(SchemaBook.isbn);
    final Rating rating = reader.require(SchemaBook.aggregateRating);
    final BookFormat format = reader.require(SchemaBook.bookFormat);
    final Iterable<Chapter> chapters = reader.getValues<Chapter>(
      SchemaBook.hasPart,
    );

    return Book(
      id: id,
      title: title,
      authorId: authorId,
      published: published,
      isbn: isbn,
      rating: rating,
      format: format,
      chapters: chapters,
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Book resource,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = context.createIriTerm(_buildIri(resource));

    return context
        .resourceBuilder(subject)
        .addValue(SchemaBook.name, resource.title)
        .addValue(
          SchemaBook.author,
          resource.authorId,
          serializer: _authorIdMapper,
        )
        .addValue(SchemaBook.datePublished, resource.published)
        .addValue(SchemaBook.isbn, resource.isbn)
        .addValue(SchemaBook.aggregateRating, resource.rating)
        .addValue(SchemaBook.bookFormat, resource.format)
        .addValues<Chapter>(SchemaBook.hasPart, resource.chapters)
        .build();
  }

  /// Builds the IRI for a resource instance using the IRI template.
  String _buildIri(Book resource) {
    final id = resource.id;
    return 'http://example.org/book/${id}';
  }
}

/// Generated mapper for [Chapter] global resources.
///
/// This mapper handles serialization and deserialization between Dart objects
/// and RDF triples for resources of type Chapter.
class ChapterMapper implements LocalResourceMapper<Chapter> {
  /// Constructor
  const ChapterMapper();

  @override
  IriTerm? get typeIri => SchemaChapter.classIri;

  @override
  Chapter fromRdfResource(
    BlankNodeTerm subject,
    DeserializationContext context,
  ) {
    final reader = context.reader(subject);

    final String title = reader.require(SchemaChapter.name);
    final int number = reader.require(SchemaChapter.position);

    return Chapter(title, number);
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
    Chapter resource,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = BlankNodeTerm();

    return context
        .resourceBuilder(subject)
        .addValue(SchemaChapter.name, resource.title)
        .addValue(SchemaChapter.position, resource.number)
        .build();
  }
}

/// Generated mapper for [ISBN] global resources.
///
/// This mapper handles serialization and deserialization between Dart objects
/// and RDF terms for iri terms of type ISBN.
class ISBNMapper implements IriTermMapper<ISBN> {
  static final RegExp _regex = RegExp(r'^urn:isbn:(?<value>[^/]*)$');

  /// Constructor
  const ISBNMapper();

  @override
  ISBN fromRdfTerm(IriTerm term, DeserializationContext context) {
    /// Parses IRI parts from a complete IRI using a template.
    final RegExpMatch? match = _regex.firstMatch(term.value);

    final iriParts = {
      for (var name in match?.groupNames ?? const <String>[])
        name: match?.namedGroup(name) ?? '',
    };
    final value = iriParts['value']!;

    return ISBN(value);
  }

  @override
  IriTerm toRdfTerm(
    ISBN iriTermValue,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final value = iriTermValue.value;
    return context.createIriTerm('urn:isbn:${value}');
  }
}

/// Generated mapper for [Rating] global resources.
///
/// This mapper handles serialization and deserialization between Dart objects
/// and RDF terms for iri terms of type Rating.
class RatingMapper implements LiteralTermMapper<Rating> {
  const RatingMapper();

  @override
  IriTerm? get datatype => null;

  @override
  Rating fromRdfTerm(
    LiteralTerm term,
    DeserializationContext context, {
    bool bypassDatatypeCheck = false,
  }) {
    final int stars = context.fromLiteralTerm(
      term,
      bypassDatatypeCheck: bypassDatatypeCheck,
    );

    return Rating(stars);
  }

  @override
  LiteralTerm toRdfTerm(
    Rating value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context.toLiteralTerm(value.stars);
  }
}

/// Generated mapper for [BookFormat] enum IRIs.
///
/// This mapper handles serialization and deserialization between enum constants
/// and RDF IRI terms for enum type BookFormat.
class BookFormatMapper implements IriTermMapper<BookFormat> {
  static final RegExp _regex = RegExp(r'^https://schema\.org/(?<value>[^/]*)$');

  /// Constructor
  const BookFormatMapper();

  @override
  BookFormat fromRdfTerm(IriTerm term, DeserializationContext context) {
    /// Parses IRI parts from a complete IRI using a template.
    final RegExpMatch? match = _regex.firstMatch(term.value);

    if (match == null) {
      throw DeserializationException('Unknown BookFormat IRI: ${term.value}');
    }

    final iriParts = {
      for (var name in match.groupNames) name: match.namedGroup(name) ?? '',
    };
    final enumValue = iriParts['value']!;

    return switch (enumValue) {
      'AudiobookFormat' => BookFormat.audiobook,
      'Hardcover' => BookFormat.hardcover,
      'Paperback' => BookFormat.paperback,
      'Ebook' => BookFormat.ebook,
      'GraphicNovel' => BookFormat.graphicNovel,
      _ => throw DeserializationException(
          'Unknown BookFormat IRI: ${term.value}',
        ),
    };
  }

  @override
  IriTerm toRdfTerm(
    BookFormat value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) =>
      switch (value) {
        BookFormat.audiobook =>
          context.createIriTerm(_buildIri('AudiobookFormat')),
        BookFormat.hardcover => context.createIriTerm(_buildIri('Hardcover')),
        BookFormat.paperback => context.createIriTerm(_buildIri('Paperback')),
        BookFormat.ebook => context.createIriTerm(_buildIri('Ebook')),
        BookFormat.graphicNovel =>
          context.createIriTerm(_buildIri('GraphicNovel')),
      };

  /// Generates the complete IRI for a given enum value
  String _buildIri(String value) {
    return 'https://schema.org/${value}';
  }
}

// This would normally happen at build time via code generation
// Register all the generated mappers
RdfMapper initRdfMapper() {
  final rdfMapper = RdfMapper.withDefaultRegistry();

  var registry = rdfMapper.registry;

  registry.registerMapper<Book>(BookMapper());
  registry.registerMapper<Chapter>(ChapterMapper());
  registry.registerMapper<ISBN>(ISBNMapper());
  registry.registerMapper<Rating>(RatingMapper());
  registry.registerMapper<BookFormat>(BookFormatMapper());

  return rdfMapper;
}

// --- The code below demonstrates how you work with the generated code ---

void main() {
  // Initialize the RDF mapper with the generated initRdfMapper function
  final rdfMapper = initRdfMapper();

  // Create a sample book
  final book = Book(
    id: 'hobbit',
    title: 'The Hobbit',
    authorId: 'J.R.R. Tolkien',
    published: DateTime(1937, 9, 21),
    isbn: ISBN('9780618260300'),
    rating: Rating(5),
    format: BookFormat.hardcover,
    chapters: [
      Chapter('An Unexpected Party', 1),
      Chapter('Roast Mutton', 2),
      Chapter('A Short Rest', 3),
    ],
  );

  // Convert to RDF and print
  final turtle = rdfMapper.encodeObject(
    book,
    baseUri: 'http://example.org/book/',
  );
  print('Book as RDF Turtle:');
  print(turtle);

  // Deserialize back to a Book object
  final deserializedBook = rdfMapper.decodeObject<Book>(turtle);

  // Verify it worked correctly
  print('\nDeserialized book:');
  print('Title: ${deserializedBook.title}');
  print('Author: ${deserializedBook.authorId}');
  print('Chapters:');
  for (final chapter in deserializedBook.chapters) {
    print('- ${chapter.title} (${chapter.number})');
  }
}
