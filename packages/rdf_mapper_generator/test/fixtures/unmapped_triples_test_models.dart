import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_vocabularies_schema/schema.dart';

/// Test model with unmapped triples support for lossless mapping
@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('https://example.org/books/{id}'),
)
class BookWithUnmappedTriples {
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfProperty(SchemaBook.author)
  final String author;

  /// Field to capture all unmapped triples for lossless round-trip mapping
  @RdfUnmappedTriples()
  final RdfGraph unmappedTriples;

  const BookWithUnmappedTriples({
    required this.id,
    required this.title,
    required this.author,
    required this.unmappedTriples,
  });
}

@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('https://example.org/books/{id}'),
)
class BookWithUnmappedTriplesLateFields {
  @RdfIriPart()
  late final String id;

  @RdfProperty(SchemaBook.name)
  late final String title;

  @RdfProperty(SchemaBook.author)
  late final String author;

  /// Field to capture all unmapped triples for lossless round-trip mapping
  @RdfUnmappedTriples()
  late final RdfGraph unmappedTriples;
}

/*
// FIXME: we need to find a way to test classes that should lead to validation
// errors, but currently they make the entire build fail. Maybe we can just 
// supply them as a string to the code generator, or at least to the first parts
// of the code generation process, so that we can test the validation logic?
//
/// Test model with multiple unmapped triples fields (should be invalid)
@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('https://example.org/books/{id}'),
)
class BookWithMultipleUnmappedTriples {
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfUnmappedTriples()
  final RdfGraph unmappedTriples1;

  @RdfUnmappedTriples()
  final RdfGraph unmappedTriples2;

  const BookWithMultipleUnmappedTriples({
    required this.id,
    required this.title,
    required this.unmappedTriples1,
    required this.unmappedTriples2,
  });
}
*/

/// Test model with unmapped triples having wrong type (should be invalid)
@RdfGlobalResource(
  SchemaBook.classIri,
  IriStrategy('https://example.org/books/{id}'),
)
class BookWithInvalidUnmappedTriplesType {
  @RdfIriPart()
  final String id;

  @RdfProperty(SchemaBook.name)
  final String title;

  @RdfUnmappedTriples()
  final String invalidField; // Should be RdfGraph

  const BookWithInvalidUnmappedTriplesType({
    required this.id,
    required this.title,
    required this.invalidField,
  });
}
