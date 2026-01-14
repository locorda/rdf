import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_core/core.dart';

/// Test vocabulary for providedAs feature
class ProvidedAsVocab {
  static const String _baseUri = 'http://example.org/vocab#';

  static const IriTerm Document = IriTerm(_baseUri + 'Document');
  static const IriTerm Section = IriTerm(_baseUri + 'Section');

  static const IriTerm hasSection = IriTerm(_baseUri + 'hasSection');
  static const IriTerm sectionTitle = IriTerm(_baseUri + 'sectionTitle');
  static const IriTerm relatedDocument = IriTerm(_baseUri + 'relatedDocument');
}

/// Parent document that provides its IRI to child sections
@RdfGlobalResource(
  ProvidedAsVocab.Document,
  IriStrategy('{+baseUri}/documents/{docId}', 'documentIri'),
)
class Document {
  @RdfIriPart()
  late String docId;

  @RdfProperty(ProvidedAsVocab.hasSection)
  late List<Section> sections;

  @RdfProperty(ProvidedAsVocab.relatedDocument)
  late String? relatedDocRef;
}

/// Section that uses parent document's IRI
@RdfGlobalResource(
  ProvidedAsVocab.Section,
  IriStrategy('{+documentIri}/sections/{sectionId}'),
  registerGlobally: false,
)
class Section {
  @RdfIriPart()
  late String sectionId;

  @RdfProperty(ProvidedAsVocab.sectionTitle)
  late String title;
}
