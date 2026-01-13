import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

import 'root_document_annotations.dart';
import 'root_document_child.dart';

/// Test class for parent document that provides documentIri using annotation subclassing
@RootResource()
class RootDocument {
  @RdfIriPart()
  final String id;

  @RdfProperty(IriTerm('http://example.org/hasChild'))
  final Set<DocumentChild> children;

  RootDocument(this.id, this.children);
}
