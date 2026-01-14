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

// The actual document type that uses pod-coordinated IRI generation
// This demonstrates how solid-crdt-sync coordinates storage for actual entities
@RdfGlobalResource(
    SchemaBook.classIri, IriStrategy.namedFactory('podIriStrategyFactory'))
class Document {
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfProperty(SchemaBook.text)
  final String content;

  Document({required this.id, required this.title, required this.content});
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

// Factory function for pod IRI strategy - receives the target type
// Called when instantiating mappers for Document class
IriTermMapper<(String,)> createPodIriStrategyMapper<T>() {
  return IriStrategyMapper(targetType: T);
}

// Generic IRI strategy mapper - works with any target type
// Receives the target type (e.g., Document) as constructor parameter
class IriStrategyMapper implements IriTermMapper<(String,)> {
  final Type targetType;
  // In real implementation: final PodCoordinator coordinator; final Config config;

  IriStrategyMapper({required this.targetType});

  @override
  IriTerm toRdfTerm((String,) value, SerializationContext context) {
    final (id,) = value;
    // In a real solid-crdt-sync implementation, this would:
    // 1. Look up targetType (e.g., Document) in the pod's type index
    // 2. Apply storage policies specific to this type
    // 3. Coordinate with other instances to avoid conflicts
    // 4. Use pod-specific namespace strategies

    // For this example, simulate type-aware coordination:
    final typeName = targetType.toString().toLowerCase();
    return context.createIriTerm(
        'https://alice.pod.example.org/$typeName/${id.substring(0, 2)}/$id');
  }

  @override
  (String,) fromRdfTerm(IriTerm term, DeserializationContext context) {
    final uri = Uri.parse(term.value);
    final segments = uri.pathSegments;

    // Parse the pod-coordinated IRI structure for any type
    if (segments.length >= 3) {
      final id = segments[2];
      return (id,);
    }

    throw FormatException(
        'Invalid pod IRI format for ${targetType}: ${term.value}');
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

// -- generated code --

// all those mappers ...

// This would also be generated by the code generator
void initRdfMapper({
  required IriTermMapper<UserReference> userReferenceMapper,
  required IriTermMapper<(String bookId, int chapterId)> chapterIdMapper,
  required IriTermMapper<(String,)> Function<T>() podIriStrategyFactory,
}) {
  // Register the custom mappers with the RDF mapper system
  print('Registering UserReferenceMapper: $userReferenceMapper');
  print('Registering ChapterIdMapper: $chapterIdMapper');
  print('Registering PodIriStrategyFactory: $podIriStrategyFactory');

  // In a real implementation, these would be registered with a mapper registry
  // The Document class would use the strategy factory for its IRI generation
  final documentIriMapper = podIriStrategyFactory<Document>();
  print(
      'Created pod-coordinated Document IRI mapper for type ${Document}: $documentIriMapper');
}

// -- Back to your code --

// Example usage
void main() {
  // Initialize the mapper system with our custom mappers
  final baseUrl = 'https://example.org';

  initRdfMapper(
    userReferenceMapper: UserReferenceMapper(baseUrl: baseUrl),
    chapterIdMapper: ChapterIdMapper(baseUrl: baseUrl),
    podIriStrategyFactory:
        createPodIriStrategyMapper, // Pod-coordinated IRI strategy
  );

  // Create sample data
  final isbn = StandardIsbn('9780261102217');
  final uri = AbsoluteUri('https://example.org/resources/123');
  final user = UserReference('johndoe');
  final book = SimpleBook('hobbit', 'The Hobbit');
  final chapter = Chapter('hobbit', 3, 'Riddles in the Dark');
  final document =
      Document(id: 'abc123def', title: 'My Document', content: 'Some content');

  // Example IRIs that would be generated
  print('ISBN IRI: ${isbn.value} => urn:isbn:9780261102217');
  print('Absolute URI: ${uri.uri} => https://example.org/resources/123');
  print(
    'User Profile IRI: ${user.username} => https://example.org/users/johndoe',
  );
  print('Book IRI: ${book.id} => https://library.example.org/books/hobbit.ttl');
  print(
    'Chapter IRI: ${chapter.bookId}/${chapter.chapterNumber} => https://example.org/books/hobbit/chapters/3',
  );
  print(
    'Document IRI: ${document.id} => https://alice.pod.example.org/document/ab/abc123def (pod-coordinated)',
  );
}
