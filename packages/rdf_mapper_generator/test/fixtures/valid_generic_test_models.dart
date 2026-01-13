// Test fixture models for testing valid generic type support

import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_core/foaf.dart';
import 'package:rdf_vocabularies_schema/schema.dart';

/// Generic document class with single type parameter - valid with registerGlobally=false
@RdfGlobalResource(
  FoafDocument.classIri,
  IriStrategy('{+documentIri}'),
  registerGlobally: false,
)
class GenericDocument<T> {
  @RdfIriPart()
  final String documentIri;

  @RdfProperty(FoafDocument.primaryTopic)
  final T primaryTopic;

  @RdfProperty(FoafDocument.title)
  final String title;

  const GenericDocument({
    required this.documentIri,
    required this.primaryTopic,
    required this.title,
  });
}

/// Generic class with multiple type parameters - valid with registerGlobally=false
@RdfGlobalResource(
  FoafDocument.classIri,
  IriStrategy('{+documentIri}'),
  registerGlobally: false,
)
class MultiGenericDocument<T, U, V> {
  @RdfIriPart()
  final String documentIri;

  @RdfProperty(FoafDocument.primaryTopic)
  final T primaryTopic;

  @RdfProperty(SchemaCreativeWork.author)
  final U author;

  @RdfProperty(SchemaCreativeWork.about)
  final V metadata;

  const MultiGenericDocument({
    required this.documentIri,
    required this.primaryTopic,
    required this.author,
    required this.metadata,
  });
}

/// Non-generic class with registerGlobally=true - should be valid
@RdfGlobalResource(
  SchemaPerson.classIri,
  IriStrategy('http://example.org/persons/{id}'),
  registerGlobally: true,
)
class NonGenericPerson {
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaPerson.name)
  final String name;

  const NonGenericPerson({
    required this.id,
    required this.name,
  });
}

/// Generic local resource class - valid with registerGlobally=false
@RdfLocalResource(FoafDocument.classIri, false)
class GenericLocalResource<T> {
  @RdfProperty(FoafDocument.primaryTopic)
  final T value;

  @RdfProperty(SchemaThing.name)
  final String label;

  const GenericLocalResource({
    required this.value,
    required this.label,
  });
}
