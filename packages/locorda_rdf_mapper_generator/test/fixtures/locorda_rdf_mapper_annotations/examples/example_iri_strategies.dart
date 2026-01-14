import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

// -- Iri as Term --
// A class that demonstrates standard IRI construction with prefix/suffix
@RdfIri('urn:isbn:{value}')
class StandardIsbn {
  @RdfIriPart()
  final String value;

  StandardIsbn(this.value);

  // When serialized, this will become: urn:isbn:{value}
}

// A class that demonstrates complete IRI construction (using the value as-is)
@RdfIri()
class AbsoluteUri {
  @RdfIriPart()
  final String uri;

  AbsoluteUri(this.uri) {
    if (!uri.contains('://')) {
      throw ArgumentError('Not a valid absolute URI: $uri');
    }
  }

  // When serialized, this will use the uri value directly as the IRI
}

// A class that requires custom IRI construction logic
// Requires a custom mapper to be provided at runtime
@RdfIri.namedMapper('userReferenceMapper')
class UserReference {
  final String username;

  UserReference(this.username);
}

// This represents a custom mapper implementation for UserProfile that needs
// to be provided by the developer at runtime.
class UserReferenceMapper implements IriTermMapper<UserReference> {
  final String baseUrl;

  UserReferenceMapper({required this.baseUrl});

  @override
  IriTerm toRdfTerm(UserReference value, SerializationContext context) {
    return context.createIriTerm('$baseUrl/users/${value.username}');
  }

  @override
  UserReference fromRdfTerm(IriTerm term, DeserializationContext context) {
    final uri = Uri.parse(term.value);
    final segments = uri.pathSegments;

    if (segments.length >= 2 && segments[0] == 'users') {
      final username = segments[1];
      return UserReference(username);
    }

    throw FormatException('Invalid UserProfile IRI format: ${term.value}');
  }
}

// -- Resource Iri --

// A resource class with static IRI construction from template
@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('https://library.example.org/books/{id}.ttl'),
)
class SimpleBook {
  // ID will be extracted from: https://library.example.org/books/{id}.ttl,
  // where {id} is the value of this field - e.g., 'hobbit'
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaBook.name)
  final String title;

  SimpleBook(this.id, this.title);
}

// A resource class with the IRI as Id property.
@RdfGlobalResource(SchemaPerson.classIri, IriStrategy())
class Person {
  // The field will contain the full IRI as Id, e.g.: https://example.org/person/43
  @RdfIriPart()
  final String iri;

  @RdfProperty(SchemaPerson.givenName)
  final String givenName;

  Person(this.iri, this.givenName);
}

// A resource class with multi-field ID mapping
@RdfGlobalResource(
  SchemaChapter.classIri,
  // Note: just using a template here would be most simple and convenient
  // RdfIri('https://example.org/books/{bookId}/chapters/{chapterId}'),
  //
  // but we want to demonstrate the use of a custom mapper. Note that
  // we allow mapping multiple parts of the IRI to different fields and the
  // mapper will be an IriTermMapper, but for a record type with all fields
  // annotated with `@RdfIriPart.position()`.
  IriStrategy.namedMapper('chapterIdMapper'),
)
class Chapter {
  // Note that you can use both @RdfIriPart and @RdfProperty annotations on the same field.
  // This is useful if one or more RDF Properties are Predicates in their own rights,
  // but also used for Iri construction.
  @RdfIriPart.position(1)
  @RdfProperty(SchemaChapter.isPartOf)
  final String bookId;

  // Note the use of position to specify the order of the IRI parts - this is important
  // since it controls the position in the record type used for the IriTermMapper.
  @RdfIriPart.position(2)
  @RdfProperty(SchemaChapter.position)
  final int chapterNumber;

  @RdfProperty(SchemaChapter.name)
  final String title;

  Chapter(this.bookId, this.chapterNumber, this.title);
}

// This represents a custom mapper implementation for the IRI of the Chapter class
class ChapterIdMapper implements IriTermMapper<(String bookId, int chapterId)> {
  final String baseUrl;

  ChapterIdMapper({required this.baseUrl});

  @override
  (String, int) fromRdfTerm(IriTerm term, DeserializationContext context) {
    final uri = Uri.parse(term.value);
    final segments = uri.pathSegments;

    // Expected path: /books/{bookId}/chapters/{chapterId}
    if (segments.length >= 4 &&
        segments[0] == 'books' &&
        segments[2] == 'chapters') {
      var bookId = segments[1];
      var chapterId = int.parse(segments[3]);
      return (bookId, chapterId);
    }

    throw FormatException('Invalid Chapter/Section IRI format: ${term.value}');
  }

  @override
  IriTerm toRdfTerm(
    (String bookId, int chapterNumber) value,
    SerializationContext context,
  ) {
    return context
        .createIriTerm('$baseUrl/books/${value.$1}/chapters/${value.$2}');
  }
}
