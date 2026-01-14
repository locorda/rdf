import 'dart:convert';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';

// Helper function for comparing maps in == operator
bool mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == b) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;

  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) {
      return false;
    }
  }
  return true;
}

@RdfLocalResource()
class SimplePropertyTest {
  @RdfProperty(SchemaBook.name)
  final String name;

  SimplePropertyTest({required this.name});
}

@RdfGlobalResource(
  const IriTerm('http://example.org/types/Book'),
  IriStrategy('http://example.org/books/{name}'),
)
class SimpleCustomPropertyTest {
  @RdfProperty(const IriTerm('http://example.org/types/Book/name'))
  @RdfIriPart()
  final String name;

  SimpleCustomPropertyTest({required this.name});
}

@RdfLocalResource()
class DeserializationOnlyPropertyTest {
  @RdfProperty(SchemaBook.name, include: false)
  final String name;

  DeserializationOnlyPropertyTest({required this.name});
}

@RdfLocalResource(SchemaBook.classIri)
class OptionalPropertyTest {
  @RdfProperty(SchemaBook.name)
  final String? name;

  OptionalPropertyTest({required this.name});
}

@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('http://example.org/books/singleton'),
)
class DefaultValueTest {
  @RdfProperty(SchemaBook.isbn, defaultValue: 'default-isbn')
  final String isbn;

  DefaultValueTest({required this.isbn});
}

@RdfLocalResource()
class IncludeDefaultsTest {
  @RdfProperty(
    SchemaBook.numberOfPages,
    defaultValue: 5,
    includeDefaultsInSerialization: true,
  )
  final int rating;

  IncludeDefaultsTest({required this.rating});
}

@RdfLocalResource()
class IriMappingTest {
  @RdfProperty(
    SchemaBook.author,
    iri: IriMapping('http://example.org/authors/{authorId}'),
  )
  final String authorId;

  IriMappingTest({required this.authorId});
}

@RdfLocalResource()
class IriMappingWithBaseUriTest {
  @RdfProperty(
    SchemaBook.author,
    iri: IriMapping('{+baseUri}/authors/{authorId}'),
  )
  final String authorId;

  IriMappingWithBaseUriTest({required this.authorId});
}

@RdfLocalResource()
class IriMappingFullIriTest {
  @RdfProperty(SchemaBook.author, iri: IriMapping('{+authorIri}'))
  final String authorIri;

  IriMappingFullIriTest({required this.authorIri});
}

@RdfLocalResource()
class IriMappingFullIriSimpleTest {
  @RdfProperty(SchemaBook.author, iri: IriMapping())
  final String authorIri;

  IriMappingFullIriSimpleTest({required this.authorIri});
}

@RdfLocalResource()
class IriMappingWithProviderTest {
  @RdfProvides()
  String get category => 'fiction';

  @RdfProperty(
    SchemaBook.author,
    iri: IriMapping('http://example.org/{category}/{authorId}'),
  )
  final String authorId;

  IriMappingWithProviderTest({required this.authorId});
}

@RdfLocalResource()
class IriMappingWithBaseUriProviderTest {
  @RdfProvides()
  String get baseUri => 'http://foo.example.org';

  @RdfProperty(SchemaBook.author, iri: IriMapping('{+baseUri}/{authorId}'))
  final String authorId;

  IriMappingWithBaseUriProviderTest({required this.authorId});
}

@RdfLocalResource()
class IriMappingWithProviderPropertyTest {
  @RdfProvides()
  @RdfProperty(SchemaBook.genre)
  final String genre;

  @RdfProperty(
    SchemaBook.author,
    iri: IriMapping('http://example.org/{genre}/{authorId}'),
  )
  final String authorId;

  IriMappingWithProviderPropertyTest({
    required this.authorId,
    required this.genre,
  });
}

@RdfLocalResource()
class IriMappingWithProvidersAndBaseUriPropertyTest {
  @RdfProvides()
  @RdfProperty(SchemaBook.genre)
  final String genre;

  @RdfProvides()
  @RdfProperty(SchemaBook.version)
  final String version;

  @RdfProperty(
    SchemaBook.author,
    iri: IriMapping('{+baseUri}/{genre}/{version}/{authorId}'),
  )
  final String authorId;

  IriMappingWithProvidersAndBaseUriPropertyTest({
    required this.authorId,
    required this.genre,
    required this.version,
  });
}

@RdfLocalResource()
class IriMappingNamedMapperTest {
  @RdfProperty(SchemaBook.author, iri: IriMapping.namedMapper('iriMapper'))
  final String authorId;

  IriMappingNamedMapperTest({required this.authorId});
}

@RdfLocalResource()
class IriMappingMapperTest {
  @RdfProperty(SchemaBook.author, iri: IriMapping.mapper(IriMapperImpl))
  final String authorId;

  IriMappingMapperTest({required this.authorId});
}

@RdfLocalResource()
class IriMappingMapperInstanceTest {
  @RdfProperty(
    SchemaBook.author,
    iri: IriMapping.mapperInstance(IriMapperImpl()),
  )
  final String authorId;

  IriMappingMapperInstanceTest({required this.authorId});
}

class IriMapperImpl implements IriTermMapper<String> {
  const IriMapperImpl();

  @override
  String fromRdfTerm(IriTerm term, DeserializationContext context) {
    // Extract authorId from IRI like 'http://example.org/authors/{authorId}'
    final iriValue = term.value;
    const prefix = 'http://example.org/authors/';

    if (iriValue.startsWith(prefix)) {
      return iriValue.substring(prefix.length);
    }

    throw ArgumentError(
      'Invalid IRI format: $iriValue. Expected format: ${prefix}{authorId}',
    );
  }

  @override
  IriTerm toRdfTerm(String value, SerializationContext context) {
    // Generate IRI from authorId using template
    final iriValue = 'http://example.org/authors/$value';
    return context.createIriTerm(iriValue);
  }
}

@RdfLocalResource()
class LocalResourceMappingTest {
  @RdfProperty(
    SchemaBook.author,
    localResource: LocalResourceMapping.namedMapper('testLocalMapper'),
  )
  final Object author;

  LocalResourceMappingTest({required this.author});
}

@RdfLocalResource()
class GlobalResourceMappingTest {
  @RdfProperty(
    SchemaBook.publisher,
    globalResource: GlobalResourceMapping.namedMapper('testGlobalMapper'),
  )
  final Object publisher;

  GlobalResourceMappingTest({required this.publisher});
}

@RdfLocalResource()
class LiteralMappingTest {
  @RdfProperty(
    const IriTerm('http://example.org/book/price'),
    literal: LiteralMapping.namedMapper('testLiteralPriceMapper'),
  )
  final double price;

  LiteralMappingTest({required this.price});
}

@RdfLocalResource()
class LiteralMappingTestCustomDatatype {
  @RdfProperty(
    const IriTerm('http://example.org/book/price'),
    literal: LiteralMapping.mapperInstance(DoubleMapper(Xsd.double)),
  )
  final double price;

  LiteralMappingTestCustomDatatype({required this.price});
}

@RdfLocalResource()
class CollectionNoneTest {
  @RdfProperty(
    SchemaBook.author,
    collection: CollectionMapping.mapper(JsonLiteralStringListMapper),
  )
  final List<String> authors;

  CollectionNoneTest({required this.authors});
}

class JsonLiteralStringListMapper implements LiteralTermMapper<List<String>> {
  final IriTerm? datatype = null;
  const JsonLiteralStringListMapper(
      {Serializer<String>? itemSerializer,
      Deserializer<String>? itemDeserializer});

  @override
  List<String> fromRdfTerm(
    LiteralTerm term,
    DeserializationContext context, {
    bool bypassDatatypeCheck = false,
  }) {
    // Assuming the literal value is a JSON string
    return (json.decode(term.value) as List<dynamic>)
        .whereType<String>()
        .toList();
  }

  @override
  LiteralTerm toRdfTerm(List<String> value, SerializationContext context) {
    // Convert the value to a JSON string
    final jsonString = json.encode(value);
    return LiteralTerm(jsonString);
  }
}

@RdfLocalResource()
class CollectionAutoTest {
  @RdfProperty(SchemaBook.author)
  final List<String> authors;

  CollectionAutoTest({required this.authors});
}

@RdfLocalResource()
class CollectionTest {
  @RdfProperty(SchemaBook.author,
      collection: unorderedItemsList, defaultValue: [])
  final List<String> authors;

  CollectionTest({required this.authors});
}

@RdfLocalResource()
class CollectionIterableTest {
  @RdfProperty(SchemaBook.author)
  final Iterable<String> authors;

  CollectionIterableTest({required this.authors});
}

@RdfLocalResource()
class MapNoCollectionNoMapperTest {
  @RdfProperty(SchemaBook.reviews, collection: CollectionMapping.fromRegistry())
  final Map<String, String> reviews;

  MapNoCollectionNoMapperTest({required this.reviews});
}

@RdfLocalResource()
class MapLocalResourceMapperTest {
  @RdfProperty(
    SchemaBook.reviews,
    localResource: LocalResourceMapping.namedMapper("mapEntryMapper"),
  )
  final Map<String, String> reviews;

  MapLocalResourceMapperTest({required this.reviews});
}

@RdfLocalResource()
class SetTest {
  @RdfProperty(SchemaBook.keywords)
  final Set<String> keywords;

  SetTest({required this.keywords});
}

@RdfLocalResource()
class EnumTypeTest {
  @RdfProperty(SchemaBook.bookFormat)
  final BookFormatType format;

  EnumTypeTest({required this.format});
}

@RdfLiteral()
enum BookFormatType { hardcover, paperback, ebook, audioBook }

@RdfLocalResource()
class ComplexDefaultValueTest {
  @RdfProperty(
    const IriTerm('http://example.org/test/complexValue'),
    defaultValue: const {'id': '1', 'name': 'Test'},
    collection: CollectionMapping.mapper(JsonLiteralMapMapper),
  )
  final Map<String, dynamic> complexValue;

  ComplexDefaultValueTest({required this.complexValue});
}

class JsonLiteralMapMapper implements LiteralTermMapper<Map<String, dynamic>> {
  final IriTerm? datatype = null;
  const JsonLiteralMapMapper();

  @override
  Map<String, dynamic> fromRdfTerm(
    LiteralTerm term,
    DeserializationContext context, {
    bool bypassDatatypeCheck = false,
  }) {
    // Assuming the literal value is a JSON string
    return json.decode(term.value);
  }

  @override
  LiteralTerm toRdfTerm(
    Map<String, dynamic> value,
    SerializationContext context,
  ) {
    // Convert the value to a JSON string
    final jsonString = json.encode(value);
    return LiteralTerm(jsonString);
  }
}

// FIXME: we also need tests with getters and setters?

@RdfLocalResource()
class FinalPropertyTest {
  @RdfProperty(SchemaBook.name)
  final String name;

  @RdfProperty(SchemaBook.description)
  final String? description;

  FinalPropertyTest({required this.name, required this.description});
}

@RdfLocalResource()
class LatePropertyTest {
  @RdfProperty(SchemaBook.name)
  late String name;

  @RdfProperty(SchemaBook.description)
  late String? description;

  LatePropertyTest();
}

@RdfLocalResource()
class MutablePropertyTest {
  @RdfProperty(SchemaBook.name)
  String name;

  @RdfProperty(SchemaBook.description)
  String? description;

  MutablePropertyTest({required this.name, this.description});
}

@RdfLocalResource()
class LanguageTagTest {
  @RdfProperty(
    SchemaBook.description,
    literal: const LiteralMapping.withLanguage('en'),
  )
  final String description;

  LanguageTagTest({required this.description});
}

@RdfLocalResource()
class DatatypeTest {
  @RdfProperty(
    SchemaBook.description,
    literal: const LiteralMapping.withType(Xsd.string),
  )
  final int count;

  @RdfProperty(
    SchemaBook.dateCreated,
    literal: const LiteralMapping.withType(Xsd.dateTime),
  )
  final String date;

  DatatypeTest({required this.count, required this.date});
}

class NoAnnotationTest {
  final String name;
  NoAnnotationTest({required this.name});
}

/// Test model for named mappers
@RdfLocalResource()
class GlobalResourceNamedMapperTest {
  @RdfProperty(
    SchemaBook.publisher,
    globalResource: GlobalResourceMapping.namedMapper('testNamedMapper'),
  )
  final Object publisher;

  const GlobalResourceNamedMapperTest({required this.publisher});
}

/// Test model for custom mapper with parameters
@RdfLocalResource()
class LiteralNamedMapperTest {
  @RdfProperty(
    SchemaBook.isbn,
    literal: LiteralMapping.namedMapper('testCustomMapper'),
  )
  final String isbn;

  const LiteralNamedMapperTest({required this.isbn});
}

/// Test model for type-based mappers
@RdfLocalResource()
class LiteralTypeMapperTest {
  @RdfProperty(
    SchemaBook.bookFormat,
    literal: LiteralMapping.mapper(LiteralDoubleMapperImpl),
  )
  final double price;

  const LiteralTypeMapperTest({required this.price});
}

/// Test model for type-based mappers using mapper() constructor
@RdfLocalResource(SchemaBook.classIri)
class GlobalResourceTypeMapperTest {
  @RdfProperty(
    SchemaBook.publisher,
    globalResource: GlobalResourceMapping.mapper(GlobalPublisherMapperImpl),
  )
  final Publisher publisher;

  const GlobalResourceTypeMapperTest({required this.publisher});
}

class Publisher {
  final String iri;
  final String name;
  Publisher({required this.name, required this.iri});
}

// Example implementation of GlobalResourceMapper
class GlobalPublisherMapperImpl implements GlobalResourceMapper<Publisher> {
  const GlobalPublisherMapperImpl();

  @override
  Publisher fromRdfResource(IriTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    return Publisher(iri: term.value, name: reader.require(SchemaPerson.name));
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Publisher publisher,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(context.createIriTerm(publisher.iri))
        .addValue(SchemaPerson.name, LiteralTerm(publisher.name))
        .build();
  }

  @override
  IriTerm? get typeIri => Schema.Person;
}

class Author {
  final String name;
  Author({required this.name});
}

// Example implementation of LocalResourceMapper
class LocalResourceAuthorMapperImpl implements LocalResourceMapper<Author> {
  const LocalResourceAuthorMapperImpl();
  @override
  Author fromRdfResource(BlankNodeTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    return Author(name: reader.require(SchemaPerson.name));
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
    Author author,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final builder = context.resourceBuilder(BlankNodeTerm());
    return builder
        .addValue(SchemaPerson.name, LiteralTerm(author.name))
        .build();
  }

  @override
  IriTerm? get typeIri => SchemaPerson.classIri;
}

// Example implementation of LiteralTermMapper
class LiteralDoubleMapperImpl implements LiteralTermMapper<double> {
  final IriTerm? datatype = Xsd.double;
  const LiteralDoubleMapperImpl();

  @override
  double fromRdfTerm(
    LiteralTerm term,
    DeserializationContext context, {
    bool bypassDatatypeCheck = false,
  }) {
    // Parse double value from literal term
    final value = term.value;
    final parsed = double.tryParse(value);

    if (parsed == null) {
      throw FormatException(
        'Cannot parse "$value" as double from literal term: $term',
      );
    }

    return parsed;
  }

  @override
  LiteralTerm toRdfTerm(double value, SerializationContext context) {
    // Convert double to literal term with appropriate datatype
    return LiteralTerm(value.toString(), datatype: datatype);
  }
}

/// Test model for global resource mapper using mapper() constructor
@RdfLocalResource()
class GlobalResourceMapperTest {
  @RdfProperty(
    SchemaBook.publisher,
    globalResource: GlobalResourceMapping.mapper(GlobalPublisherMapperImpl),
  )
  final Object publisher;

  const GlobalResourceMapperTest({required this.publisher});
}

/// Test model for global resource mapper using mapperInstance() constructor
@RdfLocalResource()
class GlobalResourceInstanceMapperTest {
  @RdfProperty(
    SchemaBook.publisher,
    globalResource: GlobalResourceMapping.mapperInstance(
      GlobalPublisherMapperImpl(),
    ),
  )
  final Object publisher;

  const GlobalResourceInstanceMapperTest({required this.publisher});
}

/// Test model for local resource mapper using mapper() constructor
@RdfLocalResource()
class LocalResourceMapperTest {
  @RdfProperty(
    SchemaBook.author,
    localResource: LocalResourceMapping.mapper(LocalResourceAuthorMapperImpl),
  )
  final Author author;

  const LocalResourceMapperTest({required this.author});
}

/// Test model for local resource mapper using mapper() constructor
@RdfLocalResource()
class LocalResourceMapperObjectPropertyTest {
  @RdfProperty(
    SchemaBook.author,
    localResource: LocalResourceMapping.mapper(LocalResourceAuthorMapperImpl),
  )
  final Object author;

  const LocalResourceMapperObjectPropertyTest({required this.author});
}

/// Test model for local resource mapper using mapperInstance() constructor
@RdfLocalResource()
class LocalResourceInstanceMapperTest {
  @RdfProperty(
    SchemaBook.author,
    localResource: LocalResourceMapping.mapperInstance(
      LocalResourceAuthorMapperImpl(),
    ),
  )
  final Author author;

  const LocalResourceInstanceMapperTest({required this.author});
}

@RdfLocalResource()
class LocalResourceInstanceMapperObjectPropertyTest {
  @RdfProperty(
    SchemaBook.author,
    localResource: LocalResourceMapping.mapperInstance(
      LocalResourceAuthorMapperImpl(),
    ),
  )
  final Object author;

  const LocalResourceInstanceMapperObjectPropertyTest({required this.author});
}

/// Test model for literal mapper using mapper() constructor
@RdfLocalResource()
class LiteralMapperTest {
  @RdfProperty(
    SchemaBook.numberOfPages,
    literal: LiteralMapping.mapper(IntMapper),
  )
  final int pageCount;

  const LiteralMapperTest({required this.pageCount});
}

/// Test model for literal mapper using mapperInstance() constructor
@RdfLocalResource()
class LiteralInstanceMapperTest {
  @RdfProperty(
    SchemaBook.isbn,
    literal: LiteralMapping.mapperInstance(const LiteralStringMapperImpl()),
  )
  final String isbn;

  const LiteralInstanceMapperTest({required this.isbn});
}

// Additional mapper implementation for string literals
class LiteralStringMapperImpl implements LiteralTermMapper<String> {
  final IriTerm? datatype = null;
  const LiteralStringMapperImpl();

  @override
  String fromRdfTerm(
    LiteralTerm term,
    DeserializationContext context, {
    bool bypassDatatypeCheck = false,
  }) {
    return term.value;
  }

  @override
  LiteralTerm toRdfTerm(String value, SerializationContext context) {
    return LiteralTerm(value);
  }
}
