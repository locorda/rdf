import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';

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
