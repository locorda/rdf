import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

/// Test class for withFragment on RdfIri
@RdfIri.withFragment('{+documentIri}', 'section-{sectionId}',
    registerGlobally: false)
class SectionReference {
  @RdfIriPart()
  final String sectionId;

  SectionReference(this.sectionId);
}

/// Test class for parent document that provides documentIri
@RdfGlobalResource(
  IriTerm('http://example.org/Document'),
  IriStrategy('tag:example.org,2025:document-{id}', 'documentIri'),
)
class Document {
  @RdfIriPart()
  final String id;

  @RdfProperty(IriTerm('http://example.org/currentSection'))
  final SectionReference section;

  Document(this.id, this.section);
}

/// Test class for withFragment on IriMapping at property level
@RdfGlobalResource(
  IriTerm('http://example.org/Article'),
  IriStrategy('http://example.org/articles/{articleId}', 'articleIri'),
)
class Article {
  @RdfIriPart()
  final String articleId;

  @RdfProperty(
    IriTerm('http://example.org/relatedSection'),
    iri: IriMapping.withFragment('{+articleIri}', 'section-{refId}'),
  )
  final String refId;

  Article(this.articleId, this.refId);
}

/// Test class for withFragment on IriStrategy in RdfGlobalResource
@RdfGlobalResource(
  IriTerm('http://example.org/Page'),
  IriStrategy.withFragment('{+baseUri}/pages/overview#intro', '{pageId}'),
)
class Page {
  @RdfIriPart()
  final String pageId;

  @RdfProperty(IriTerm('http://example.org/title'))
  final String title;

  Page(this.pageId, this.title);
}
