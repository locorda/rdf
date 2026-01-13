import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

import 'root_document_annotations.dart';

/// Test class for child document that uses documentIri using annotation subclassing
@ChildResource()
class DocumentChild {
  @RdfIriPart()
  final String sectionId;

  DocumentChild(this.sectionId);
}
