// ignore_for_file: unnecessary_const

import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

/// Test enum with @RdfLiteral annotation
@RdfLiteral()
enum Priority { low, medium, high }

/// Test enum with @RdfLiteral annotation and custom values
@RdfLiteral()
enum Status {
  @RdfEnumValue('new')
  newItem,

  @RdfEnumValue('in-progress')
  inProgress,

  @RdfEnumValue('completed')
  completed,

  canceled, // Uses default name
}

/// Test enum with @RdfIri annotation
@RdfIri()
enum DocumentType {
  @RdfEnumValue('https://www.iana.org/assignments/media-types/text/plain')
  plainText,

  @RdfEnumValue('https://www.iana.org/assignments/media-types/text/html')
  html,

  @RdfEnumValue('https://www.iana.org/assignments/media-types/application/pdf')
  pdf,
}

/// Test enum with @RdfIri annotation and template
@RdfIri('https://example.org/types/{value}')
enum CategoryType {
  books,

  music,

  electronics, // Uses default name
}

/// Test enum with @RdfIri annotation using baseUri context variable
@RdfIri('{+baseUri}/formats/{value}')
enum FileFormat {
  @RdfEnumValue('text')
  text,

  @RdfEnumValue('binary')
  binary,

  xml, // Uses default name
}

/// Test enum with @RdfIri annotation using multiple context variables
@RdfIri('{+baseUri}/types/{category}/{value}', false)
enum ItemType {
  @RdfEnumValue('book')
  book,

  @RdfEnumValue('magazine')
  magazine,

  newspaper, // Uses default name
}
