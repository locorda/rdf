import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

// A sample mapper class for testing
class TestMapper implements IriTermMapper<(String id,)> {
  final String prefix;

  const TestMapper({required this.prefix});

  @override
  IriTerm toRdfTerm((String id,) properties, SerializationContext context) {
    return context.createIriTerm('$prefix/${properties.$1}');
  }

  @override
  (String id,) fromRdfTerm(IriTerm term, DeserializationContext context) {
    // This is a simplified implementation for testing
    return (term.value.split('/').last,);
  }
}

// A test class with all possible annotation parameters
@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy.mapperInstance(
    const TestMapper(prefix: 'https://example.org/books'),
  ),
  registerGlobally: true,
)
class BookWithMapper {
  @RdfIriPart()
  @RdfProvides()
  final String id;

  @RdfProperty(
    SchemaBook.name,
    include: true,
    includeDefaultsInSerialization: false,
    defaultValue: 'Untitled',
    iri: IriMapping('https://example.org/books/{id}/{title}'),
  )
  final String title;

  BookWithMapper({required this.id, required this.title});
}

// A test class with mapper instance
@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy.mapperInstance(
    const TestMapper(prefix: 'https://example.org/books'),
  ),
  registerGlobally: false,
)
class BookWithMapperInstance {
  @RdfIriPart()
  final String id;

  BookWithMapperInstance(this.id);
}

// A test class with template strategy
@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('https://example.org/books/{id}'),
)
class BookWithTemplate {
  @RdfIriPart()
  final String id;

  BookWithTemplate(this.id);
}
