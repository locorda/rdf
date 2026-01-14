/// Example: Custom collection type with multiple RDF mapping strategies.
///
/// This example demonstrates how to create mappers for custom Dart collection types
/// that can be serialized to different RDF structures depending on your needs.
///
/// The same custom type (`ImmutableList<T>`) can be mapped to:
/// 1. **rdf:List** - Ordered linked list structure (rdf:first/rdf:rest/rdf:nil)
/// 2. **rdf:Seq** - Ordered sequence with numbered properties (_1, _2, _3...)
/// 3. **Unordered items** - Multiple separate triples (default behavior)
///
/// This flexibility allows you to choose the most appropriate RDF representation
/// based on your specific use case and RDF consumption requirements.
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
  static const members = IriTerm(_base + 'members');
}

/// Library demonstrating different RDF mapping strategies for the same custom collection type.
@RdfGlobalResource(
  CollectionVocab.Library,
  IriStrategy('{+baseUri}/library/{id}'),
)
class Library {
  @RdfIriPart()
  late final String id;

  /// Strategy 1: Map to rdf:List (ordered linked list structure)
  /// RDF: `<list> rdf:first "item1" ; rdf:rest <next>` .
  @RdfProperty(CollectionVocab.collaborators, collection: immutableListRdfList)
  late final ImmutableList<String> collaborators;

  /// Strategy 2: Map to rdf:Seq (ordered sequence with numbered properties)
  /// RDF: `<seq> rdf:type rdf:Seq ; rdf:_1 "item1" ; rdf:_2 "item2"` .
  @RdfProperty(CollectionVocab.tags, collection: immutableListRdfSeq)
  late final ImmutableList<String> tags;

  /// Strategy 3: Map to unordered items (multiple separate triples)
  /// RDF: `<subject> <predicate> "item1" . <subject> <predicate> "item2"` .
  @RdfProperty(CollectionVocab.members, collection: immutableListUnorderedItems)
  late final ImmutableList<String> members;
}

/// Custom immutable collection type.
///
/// This example collection type demonstrates how any custom Dart collection
/// can be mapped to RDF using different strategies. The key is implementing
/// the appropriate mixins and mapper interfaces.
class ImmutableList<T> with Iterable<T> {
  final List<T> _items;

  ImmutableList(this._items);

  @override
  Iterator<T> get iterator => _items.iterator;

  bool get isEmpty => _items.isEmpty;
  int get length => _items.length;
  T operator [](int index) => _items[index];
}

// =============================================================================
// MAPPING STRATEGY 1: RDF LIST (rdf:first/rdf:rest/rdf:nil)
// =============================================================================

const immutableListRdfList =
    CollectionMapping.withItemMappers(ImmutableListMapperRdfList);

/// Maps `ImmutableList<T>` to rdf:List structure.
///
/// Creates a linked list structure using rdf:first/rdf:rest/rdf:nil.
/// Best for: Preserving order when RDF consumers understand rdf:List.
class ImmutableListMapperRdfList<T>
    with RdfListSerializerMixin<T>, RdfListDeserializerMixin<T>
    implements UnifiedResourceMapper<ImmutableList<T>> {
  final Serializer<T>? _itemSerializer;
  final Deserializer<T>? _itemDeserializer;

  ImmutableListMapperRdfList(
      {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})
      : _itemSerializer = itemSerializer,
        _itemDeserializer = itemDeserializer;

  @override
  (RdfSubject, Iterable<Triple>) toRdfResource(
      ImmutableList<T> list, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final (subject, triples) = buildRdfList(list, context, _itemSerializer,
        parentSubject: parentSubject);
    return (subject, triples.toList());
  }

  @override
  ImmutableList<T> fromRdfResource(
      RdfSubject subject, DeserializationContext context) {
    if (subject != Rdf.nil && subject is! BlankNodeTerm) {
      throw ArgumentError('Expected BlankNodeTerm, got ${subject.runtimeType}');
    }
    final list = readRdfList(subject, context, _itemDeserializer).toList();
    return ImmutableList<T>(list);
  }
}

// =============================================================================
// MAPPING STRATEGY 2: RDF SEQUENCE (rdf:_1, rdf:_2, rdf:_3...)
// =============================================================================
const immutableListRdfSeq =
    CollectionMapping.withItemMappers(ImmutableListMapperRdfSeq);

/// Maps `ImmutableList<T>` to rdf:Seq structure.
///
/// Creates numbered properties (_1, _2, _3...) for ordered items.
/// Best for: When you need clear ordering with simple property access.
class ImmutableListMapperRdfSeq<T>
    with RdfContainerSerializerMixin<T>, RdfContainerDeserializerMixin<T>
    implements UnifiedResourceMapper<ImmutableList<T>> {
  final Serializer<T>? _itemSerializer;
  final Deserializer<T>? _itemDeserializer;

  @override
  final IriTerm typeIri = Rdf.Seq;

  ImmutableListMapperRdfSeq(
      {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})
      : _itemSerializer = itemSerializer,
        _itemDeserializer = itemDeserializer;

  @override
  (RdfSubject, Iterable<Triple>) toRdfResource(
      ImmutableList<T> list, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final (subject, triples) = buildRdfContainer(
        BlankNodeTerm(), list, context, typeIri, _itemSerializer,
        parentSubject: parentSubject);
    return (subject, triples.toList());
  }

  @override
  ImmutableList<T> fromRdfResource(
      RdfSubject subject, DeserializationContext context) {
    if (subject is! BlankNodeTerm) {
      throw ArgumentError('Expected BlankNodeTerm, got ${subject.runtimeType}');
    }
    final list =
        readRdfContainer(subject, context, typeIri, _itemDeserializer).toList();
    return ImmutableList<T>(list);
  }
}

// =============================================================================
// MAPPING STRATEGY 3: UNORDERED ITEMS (multiple separate triples)
// =============================================================================
const immutableListUnorderedItems =
    CollectionMapping.withItemMappers(ImmutableListMapperUnorderedItems);

/// Maps `ImmutableList<T>` to multiple separate triples.
///
/// Each item becomes a separate triple with the same predicate.
/// Best for: Maximum compatibility, when order doesn't matter.
class ImmutableListMapperUnorderedItems<T>
    with UnorderedItemsSerializerMixin<T>, UnorderedItemsDeserializerMixin<T>
    implements MultiObjectsMapper<ImmutableList<T>> {
  final Deserializer<T>? _itemDeserializer;
  final Serializer<T>? _itemSerializer;

  ImmutableListMapperUnorderedItems(
      {Deserializer<T>? itemDeserializer, Serializer<T>? itemSerializer})
      : _itemDeserializer = itemDeserializer,
        _itemSerializer = itemSerializer;

  @override
  (Iterable<RdfObject>, Iterable<Triple>) toRdfObjects(
          ImmutableList<T> value, SerializationContext context) =>
      buildRdfObjects(value, context, _itemSerializer);

  @override
  ImmutableList<T> fromRdfObjects(
          Iterable<RdfObject> objects, DeserializationContext context) =>
      ImmutableList<T>(
          readRdfObjects(objects, context, _itemDeserializer).toList());
}
