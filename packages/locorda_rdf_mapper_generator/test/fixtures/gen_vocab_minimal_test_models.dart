import 'package:locorda_rdf_mapper_annotations/annotations.dart';

@RdfGlobalResource.define(
  AppVocab(appBaseUri: 'https://minimal.example.com'),
  IriStrategy('https://example.com/minimal/{id}'),
)
class GenVocabMinimalEntity {
  @RdfIriPart('id')
  final String id;

  final String minimalName;

  // Should be completely excluded from RDF mapping
  @RdfIgnore()
  final bool isExpanded;

  // Should be in vocab but NOT serialized (read-only)
  @RdfProperty.define(include: false)
  final DateTime? lastModified;

  const GenVocabMinimalEntity({
    required this.id,
    required this.minimalName,
    this.isExpanded = false,
    this.lastModified,
  });
}
