/// Example: Global RDF collections with persistent IRIs.
///
/// Standard Dart collections (List, Set) use anonymous blank nodes in RDF.
/// This example shows how to create collections with persistent IRI identity
/// that can be referenced by other resources.
///
/// Key differences:
/// - Standard: `List<String>` → anonymous blank node collection
/// - Global: `GList<String>` → collection with persistent IRI
///
/// Use cases: When collections need to be referenced, shared, or have metadata.
library;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_core/rdf.dart' show Rdf;

/// Example vocabulary for collection demonstrations
class CollectionVocab {
  static const _base = 'http://example.org/vocab#';

  static const Library = IriTerm(_base + 'Library');
  static const tags = IriTerm(_base + 'tags');
  static const collaborators = IriTerm(_base + 'collaborators');
}

/// Library with global collections that have persistent IRIs.
@RdfGlobalResource(
  CollectionVocab.Library,
  IriStrategy('{+baseUri}/library/{id}'),
)
class Library {
  @RdfIriPart()
  late final String id;

  /// Global rdf:List - collection itself has IRI and can be referenced
  @RdfProperty(CollectionVocab.collaborators, collection: glistRdfList)
  late final GList<String> collaborators;

  /// Global rdf:Seq - ordered sequence with persistent IRI
  @RdfProperty(CollectionVocab.tags, collection: glistRdfSeq)
  late final GList<String> tags;
}

/// Collection with persistent IRI identity.
///
/// Unlike `List<T>` which uses blank nodes, `GList<T>` has a persistent IRI
/// that allows the collection to be referenced by other resources.
class GList<T> {
  final IriTerm iri; // Persistent collection identifier
  final List<T> items; // Collection contents

  GList(this.iri, this.items);
}

const glistRdfList = CollectionMapping.withItemMappers(GListToRdfListMapper);

/// Mapper for `GList<T>` as rdf:List with persistent IRI.
class GListToRdfListMapper<T>
    with RdfListSerializerMixin<T>, RdfListDeserializerMixin<T>
    implements UnifiedResourceMapper<GList<T>> {
  final Mapper<T>? _itemMapper;

  GListToRdfListMapper([this._itemMapper]);

  @override
  (RdfSubject, Iterable<Triple>) toRdfResource(
      GList<T> globalList, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final (subject, triples) = buildRdfList(
        globalList.items, context, _itemMapper,
        parentSubject: parentSubject, headNode: globalList.iri);
    return (subject, triples.toList());
  }

  @override
  GList<T> fromRdfResource(RdfSubject subject, DeserializationContext context) {
    if (subject is! IriTerm) {
      throw ArgumentError('Expected IriTerm, got ${subject.runtimeType}');
    }
    final list = readRdfList(subject, context, _itemMapper).toList();
    return GList<T>(subject, list);
  }
}

const glistRdfSeq = CollectionMapping.withItemMappers(GListToRdfSeqMapper);

/// Mapper for `GList<T>` as rdf:Seq with persistent IRI.
class GListToRdfSeqMapper<T>
    with RdfContainerSerializerMixin<T>, RdfContainerDeserializerMixin<T>
    implements UnifiedResourceMapper<GList<T>> {
  final Mapper<T>? _itemMapper;

  @override
  final IriTerm typeIri = Rdf.Seq;

  GListToRdfSeqMapper([this._itemMapper]);

  @override
  (RdfSubject, Iterable<Triple>) toRdfResource(
      GList<T> globalList, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final (subject, triples) = buildRdfContainer(
        globalList.iri, globalList.items, context, typeIri, _itemMapper,
        parentSubject: parentSubject);
    return (subject, triples.toList());
  }

  @override
  GList<T> fromRdfResource(RdfSubject subject, DeserializationContext context) {
    if (subject is! IriTerm) {
      throw ArgumentError('Expected IriTerm, got ${subject.runtimeType}');
    }
    final list =
        readRdfContainer(subject, context, typeIri, _itemMapper).toList();
    return GList<T>(subject, list);
  }
}
