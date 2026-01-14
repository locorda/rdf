/// Test file to validate smart inference for all RDF annotation types
/// with registerGlobally: false
library;

import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

// Test models with different RDF annotations and registerGlobally: false

@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('http://example.org/global/{id}'),
  registerGlobally: false,
)
class TestGlobalResource {
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaBook.name)
  final String title;

  const TestGlobalResource({required this.id, required this.title});
}

@RdfLocalResource(SchemaBook.classIri, false)
class TestLocalResource {
  @RdfProperty(SchemaBook.name)
  final String title;

  const TestLocalResource({required this.title});
}

@RdfIri('http://example.org/items/{id}', false)
class TestIri {
  @RdfIriPart()
  final String id;

  const TestIri({required this.id});
}

// Container class that has properties of each inferred type
@RdfLocalResource(SchemaBook.classIri)
class InferenceTestContainer {
  @RdfProperty(SchemaBook.author)
  final TestGlobalResource? globalResource;

  @RdfProperty(SchemaBook.publisher)
  final TestLocalResource? localResource;

  @RdfProperty(SchemaBook.identifier)
  final TestIri? iri;

  const InferenceTestContainer({
    this.globalResource,
    this.localResource,
    this.iri,
  });
}
