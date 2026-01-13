import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:rdf_core/rdf_core.dart';

/// Beispiel Vokabular für die Demonstration von RDF-Mapping
class ExampleVocab {
  /// Basis-URI für das Beispiel-Vokabular
  static const String _baseUri = 'http://example.org/vocab#';

  /// Term für Parent-Konzept
  static const IriTerm Parent = IriTerm(_baseUri + 'Parent');

  /// Term für Child-Konzept
  static const IriTerm Child = IriTerm(_baseUri + 'Child');

  /// Term für die child-Eigenschaft
  static const IriTerm child = IriTerm(_baseUri + 'child');

  /// Term für die childName-Eigenschaft
  static const IriTerm childName = IriTerm(_baseUri + 'childName');

  /// Term für die sibling-Eigenschaft
  static const IriTerm sibling = IriTerm(_baseUri + 'sibling');
}

@RdfGlobalResource(
  ExampleVocab.Parent,
  IriStrategy('{+baseUri}/{id}.ttl'),
)
class Parent {
  @RdfIriPart()
  @RdfProvides("parentId")
  late String id;

  @RdfProperty(ExampleVocab.child)
  late Child child;

  @RdfProperty(ExampleVocab.sibling,
      iri: IriMapping('{+baseUri}/{parentId}/sibling/{siblingId}.ttl'))
  late String siblingId;
}

@RdfGlobalResource(
  ExampleVocab.Child,
  IriStrategy('{+baseUri}/{parentId}/child/{id}.ttl'),
  registerGlobally: false,
)
class Child {
  @RdfIriPart()
  late String id;

  @RdfProperty(ExampleVocab.childName)
  late String name;
}
