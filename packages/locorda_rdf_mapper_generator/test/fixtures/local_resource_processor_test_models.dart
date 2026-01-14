import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

@RdfLocalResource(SchemaBook.classIri)
class Book {
  @RdfProperty(SchemaBook.isbn)
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

@RdfLocalResource(SchemaPerson.classIri, false)
class ClassNoRegisterGlobally {
  @RdfProperty(SchemaPerson.name)
  final String name;

  ClassNoRegisterGlobally({required this.name});
}

@RdfLocalResource()
class ClassWithNoRdfType {
  @RdfProperty(SchemaPerson.name)
  final String name;
  @RdfProperty(SchemaPerson.foafAge)
  final int age;

  ClassWithNoRdfType(this.name, {required this.age});
}

@RdfLocalResource(SchemaPerson.classIri)
class ClassWithPositionalProperty {
  @RdfProperty(SchemaPerson.name)
  final String name;

  ClassWithPositionalProperty(this.name);
}

@RdfLocalResource(SchemaPerson.classIri)
class ClassWithNonFinalProperty {
  @RdfProperty(SchemaPerson.name)
  String name;

  ClassWithNonFinalProperty({required this.name});
}

@RdfLocalResource(SchemaPerson.classIri)
class ClassWithNonFinalPropertyWithDefault {
  @RdfProperty(SchemaPerson.name)
  String name = 'me myself and I';
}

@RdfLocalResource(SchemaPerson.classIri)
class ClassWithNonFinalOptionalProperty {
  @RdfProperty(SchemaPerson.name)
  String? name = null;
}

@RdfLocalResource(SchemaPerson.classIri)
class ClassWithLateNonFinalProperty {
  @RdfProperty(SchemaPerson.name)
  late String name;
}

@RdfLocalResource(SchemaPerson.classIri)
class ClassWithLateFinalProperty {
  @RdfProperty(SchemaPerson.name)
  late final String name;
}

@RdfLocalResource(SchemaPerson.classIri)
class ClassWithMixedFinalAndLateFinalProperty {
  @RdfProperty(SchemaPerson.name)
  final String name;
  @RdfProperty(SchemaPerson.foafAge)
  late final int age;

  ClassWithMixedFinalAndLateFinalProperty({required this.name});
}

@RdfLocalResource.namedMapper('testLocalResourceMapper')
class ClassWithMapperNamedMapperStrategy {}

@RdfLocalResource.mapper(TestLocalResourceMapper)
class ClassWithMapperStrategy {}

@RdfLocalResource.mapperInstance(TestLocalResourceMapper2())
class ClassWithMapperInstanceStrategy {}

class TestLocalResourceMapper
    implements LocalResourceMapper<ClassWithMapperStrategy> {
  const TestLocalResourceMapper();

  @override
  fromRdfResource(BlankNodeTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
    value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    throw UnimplementedError();
  }

  @override
  IriTerm? get typeIri =>
      const IriTerm('http://example.org/l/ClassWithMapperStrategy');
}

class TestLocalResourceMapper2
    implements LocalResourceMapper<ClassWithMapperInstanceStrategy> {
  const TestLocalResourceMapper2();

  @override
  fromRdfResource(BlankNodeTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
    value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    throw UnimplementedError();
  }

  @override
  IriTerm? get typeIri =>
      const IriTerm('http://example.org/l/ClassWithMapperInstanceStrategy');
}
