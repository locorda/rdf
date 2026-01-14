import 'package:locorda_rdf_mapper_annotations/annotations.dart';

import 'root_document_annotations.dart';

/// Test class for child document that uses documentIri using annotation subclassing
@ChildResource()
class DocumentChild {
  @RdfIriPart()
  final String sectionId;

  DocumentChild(this.sectionId);
}
