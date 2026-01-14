import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('http://example.org/books/{isbn}'),
  registerGlobally: true,
)
class Book {
  @RdfIriPart()
  final String isbn;

  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfProperty(
    SchemaBook.author,
    iri: IriMapping('http://example.org/authors/{authorId}'),
  )
  final String authorId;

  Book({required this.isbn, required this.title, required this.authorId});
}

@RdfGlobalResource(SchemaPerson.classIri, IriStrategy())
class ClassWithEmptyIriStrategy {
  @RdfIriPart()
  final String iri;

  ClassWithEmptyIriStrategy({required this.iri});
}

@RdfGlobalResource(null, IriStrategy())
class ClassWithNoRdfType {
  @RdfIriPart()
  late final String iri;

  @RdfProperty(SchemaPerson.name)
  final String name;

  @RdfProperty(SchemaPerson.foafAge)
  final int? age;

  ClassWithNoRdfType(this.name, {this.age});
}

@RdfGlobalResource(
  SchemaPerson.classIri,
  IriStrategy(),
  registerGlobally: false,
)
class ClassWithEmptyIriStrategyNoRegisterGlobally {
  @RdfIriPart()
  final String iri;

  ClassWithEmptyIriStrategyNoRegisterGlobally({required this.iri});
}

@RdfGlobalResource(
  SchemaPerson.classIri,
  IriStrategy('http://example.org/persons/{id}'),
)
class ClassWithIriTemplateStrategy {
  @RdfIriPart()
  final String id;

  ClassWithIriTemplateStrategy({required this.id});
}

@RdfGlobalResource(
  SchemaPerson.classIri,
  IriStrategy('{+baseUri}/persons/{thisId}'),
)
class ClassWithIriTemplateAndContextVariableStrategy {
  @RdfIriPart('thisId')
  final String id;

  ClassWithIriTemplateAndContextVariableStrategy({required this.id});
}

@RdfGlobalResource(
  SchemaPerson.classIri,
  IriStrategy('{+otherBaseUri}/persons/{thisId}'),
  registerGlobally: false,
)
class ClassWithOtherBaseUriNonGlobal {
  @RdfIriPart('thisId')
  final String id;

  ClassWithOtherBaseUriNonGlobal({required this.id});
}

@RdfGlobalResource(SchemaPerson.classIri, IriStrategy.namedMapper('testMapper'))
class ClassWithIriNamedMapperStrategy {}

@RdfGlobalResource(
  SchemaPerson.classIri,
  IriStrategy.namedMapper('testMapper1Part'),
  registerGlobally: false,
)
class ClassWithIriNamedMapperStrategy1Part {
  @RdfIriPart()
  final String id;

  ClassWithIriNamedMapperStrategy1Part({required this.id});
}

@RdfGlobalResource(
  SchemaPerson.classIri,
  IriStrategy.namedMapper('testMapper2Parts'),
  registerGlobally: false,
)
class ClassWithIriNamedMapperStrategy2Parts {
  @RdfIriPart.position(1)
  final String id;
  @RdfIriPart.position(2)
  final int version;

  ClassWithIriNamedMapperStrategy2Parts({
    required this.id,
    required this.version,
  });
}

@RdfGlobalResource(
  SchemaPerson.classIri,
  IriStrategy.namedMapper('testMapper2PartsSwapped'),
  registerGlobally: false,
)
class ClassWithIriNamedMapperStrategy2PartsSwapped {
  @RdfIriPart.position(2)
  final String id;
  @RdfIriPart.position(1)
  final int version;

  ClassWithIriNamedMapperStrategy2PartsSwapped({
    required this.id,
    required this.version,
  });
}

@RdfGlobalResource(
  SchemaPerson.classIri,
  IriStrategy.namedMapper('testMapper3'),
)
class ClassWithIriNamedMapperStrategy2PartsWithProperties {
  @RdfIriPart.position(1)
  late final String id;

  @RdfIriPart.position(3)
  late int version;

  @RdfProperty(SchemaPerson.givenName)
  late String givenName;

  @RdfIriPart.position(2)
  @RdfProperty(SchemaPerson.foafSurname)
  late String surname;

  @RdfProperty(SchemaPerson.foafAge)
  int? age;
}

@RdfGlobalResource(SchemaPerson.classIri, IriStrategy.mapper(TestIriMapper))
class ClassWithIriMapperStrategy {}

@RdfGlobalResource(
  SchemaPerson.classIri,
  IriStrategy.mapperInstance(TestIriMapper2()),
)
class ClassWithIriMapperInstanceStrategy {
  @RdfProperty(SchemaPerson.name)
  final String name;

  ClassWithIriMapperInstanceStrategy({required this.name});
}

@RdfGlobalResource.namedMapper('testGlobalResourceMapper')
class ClassWithMapperNamedMapperStrategy {}

@RdfGlobalResource.mapper(TestGlobalResourceMapper)
class ClassWithMapperStrategy {}

@RdfGlobalResource.mapperInstance(TestGlobalResourceMapper2())
class ClassWithMapperInstanceStrategy {}

class TestGlobalResourceMapper
    implements GlobalResourceMapper<ClassWithMapperStrategy> {
  const TestGlobalResourceMapper();

  @override
  fromRdfResource(IriTerm term, DeserializationContext context) {
    return ClassWithMapperStrategy();
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(
          const IriTerm('http://example.org/instance/ClassWithMapperStrategy'),
        )
        .build();
  }

  @override
  IriTerm? get typeIri =>
      const IriTerm('http://example.org/g/ClassWithMapperStrategy');
}

class TestGlobalResourceMapper2
    implements GlobalResourceMapper<ClassWithMapperInstanceStrategy> {
  const TestGlobalResourceMapper2();

  @override
  fromRdfResource(IriTerm term, DeserializationContext context) {
    return ClassWithMapperInstanceStrategy();
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(
          const IriTerm(
            'http://example.org/instance/ClassWithMapperInstanceStrategy',
          ),
        )
        .build();
  }

  @override
  IriTerm? get typeIri =>
      const IriTerm('http://example.org/g/ClassWithMapperInstanceStrategy');
}

class TestIriMapper implements IriTermMapper<ClassWithIriMapperStrategy> {
  const TestIriMapper();

  @override
  ClassWithIriMapperStrategy fromRdfTerm(
    IriTerm term,
    DeserializationContext context,
  ) {
    throw UnimplementedError(
      'fromRdfTerm cannot be implemented for TestIriMapper',
    );
  }

  @override
  IriTerm toRdfTerm(value, SerializationContext context) {
    // this of course is pretty nonsensical, but just for testing
    return context
        .createIriTerm('http://example.org/persons/${value.hashCode}');
  }
}

class TestIriMapper2
    implements IriTermMapper<ClassWithIriMapperInstanceStrategy> {
  const TestIriMapper2();

  @override
  fromRdfTerm(IriTerm term, DeserializationContext context) {
    throw UnimplementedError(
      'fromRdfTerm cannot be implemented for TestIriMapper2',
    );
  }

  @override
  IriTerm toRdfTerm(value, SerializationContext context) {
    // this of course is pretty nonsensical, but just for testing
    return context
        .createIriTerm('http://example.org/persons2/${value.hashCode}');
  }
}

// This class is not annotated with @RdfGlobalResource
class NotAnnotated {
  final String name;

  NotAnnotated(this.name);
}
