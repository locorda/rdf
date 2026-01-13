import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

// ============================================================================
// Global Resource Mappers
// ============================================================================

/// Test model for deserialize-only global resource mapper
@RdfGlobalResource.deserializeOnly(
  IriTerm('http://example.org/DeserializeOnlyClass'),
)
class DeserializeOnlyClass {
  @RdfProperty(IriTerm('http://example.org/name'))
  final String name;

  @RdfProperty(IriTerm('http://example.org/value'))
  final int value;

  DeserializeOnlyClass({required this.name, required this.value});
}

/// Test model for serialize-only global resource mapper
@RdfGlobalResource.serializeOnly(
  IriTerm('http://example.org/SerializeOnlyClass'),
  IriStrategy('http://example.org/items/{id}'),
)
class SerializeOnlyClass {
  @RdfIriPart('id')
  final String id;

  @RdfProperty(IriTerm('http://example.org/title'))
  final String title;

  SerializeOnlyClass({required this.id, required this.title});
}

/// Test model for bidirectional global resource mapper (default)
@RdfGlobalResource(
  IriTerm('http://example.org/BidirectionalClass'),
  IriStrategy('http://example.org/bidirectional/{id}'),
)
class BidirectionalClass {
  @RdfIriPart('id')
  final String id;

  @RdfProperty(IriTerm('http://example.org/description'))
  final String description;

  BidirectionalClass({required this.id, required this.description});
}
