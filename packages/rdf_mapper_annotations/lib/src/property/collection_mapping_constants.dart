/// Pre-defined collection mapping constants for common RDF collection strategies.
///
/// This file provides convenient, well-documented constants for the most common
/// collection mapping strategies used in RDF serialization. These constants serve
/// as the primary entry point for users to configure how Dart collections are
/// mapped to different RDF structures.
///
/// ## Quick Reference
///
/// **Structured RDF Collections** (single collection object):
/// - `rdfList` - Ordered linked list with rdf:first/rdf:rest/rdf:nil
/// - `rdfSeq` - Numbered sequence with rdf:_1, rdf:_2, rdf:_3...
/// - `rdfBag` - Unordered collection for when order doesn't matter
/// - `rdfAlt` - Alternative values (first is preferred)
///
/// **Multiple Triples** (separate triple per item):
/// - `unorderedItems` - Generic multiple triples for any Iterable
/// - `unorderedItemsList` - Multiple triples specifically for `List<T>`
/// - `unorderedItemsSet` - Multiple triples specifically for `Set<T>`
///
/// ## Usage Example
///
/// ```dart
/// class Book {
///   // Ordered chapters as RDF List (preserves order)
///   @RdfProperty(SchemaBook.chapters, collection: rdfList)
///   final List<Chapter> chapters;
///
///   // Authors as numbered sequence
///   @RdfProperty(SchemaBook.authors, collection: rdfSeq)
///   final List<Person> authors;
///
///   // Keywords as separate triples (default behavior)
///   @RdfProperty(SchemaBook.keywords, collection: unorderedItems)
///   final List<String> keywords;
/// }
/// ```
///
/// ## Dart Type to RDF Strategy Mapping
///
/// Each constant maps Dart collection types to specific RDF serialization strategies:
///
/// ### Structured Collections (Single RDF Object)
/// - `List<T>` + `rdfList` → rdf:List structure
/// - `List<T>` + `rdfSeq` → rdf:Seq structure
/// - `List<T>` + `rdfBag` → rdf:Bag structure
/// - `List<T>` + `rdfAlt` → rdf:Alt structure
///
/// ### Multiple Triples (Separate Triple Per Item)
/// - `List<T>` + `unorderedItemsList` → Multiple triples with same predicate
/// - `Set<T>` + `unorderedItemsSet` → Multiple triples with same predicate
/// - `Iterable<T>` + `unorderedItems` → Multiple triples with same predicate
///
/// ## When to Use Each Strategy
///
/// **Use `rdfList`** when:
/// - Order is important and must be preserved
/// - RDF consumers understand rdf:List structures
/// - You need a linked list representation
///
/// **Use `rdfSeq`** when:
/// - Order is important with clear numbering
/// - You want indexed access (rdf:_1, rdf:_2, etc.)
/// - RDF consumers prefer numbered sequences
///
/// **Use `rdfBag`** when:
/// - Order doesn't matter
/// - You want to explicitly indicate unordered collection
/// - RDF consumers expect rdf:Bag structures
///
/// **Use `rdfAlt`** when:
/// - Representing alternative values
/// - First item is the preferred choice
/// - RDF consumers need to pick one alternative
///
/// **Use `unorderedItems*`** when:
/// - Maximum compatibility with RDF consumers
/// - Order doesn't matter
/// - You prefer simple triple structure - this is the default behavior
library;

import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/src/property/collection.dart';

/// Maps Dart collections to RDF List structures (rdf:first/rdf:rest/rdf:nil).
///
/// **RDF Structure**: Creates an ordered linked list using rdf:first/rdf:rest/rdf:nil
/// **Dart Type**: Works with `List<T>` - will lead to compile errors in generated mappers if used with other types like `Set<T>` or `Iterable<T>`.
/// **Order**: Preserved - items appear in RDF in the same order as in the Dart List
/// **Use Case**: When order matters and RDF consumers understand rdf:List structures
///
/// ## Example Usage
/// ```dart
/// @RdfProperty(SchemaBook.chapters, collection: rdfList)
/// final List<Chapter> chapters;
/// ```
///
/// ## Generated RDF
/// ```turtle
/// <book> schema:chapters _:list1 .
/// _:list1 rdf:first <chapter1> ;
///         rdf:rest _:list2 .
/// _:list2 rdf:first <chapter2> ;
///         rdf:rest rdf:nil .
/// ```
///
/// **Underlying Mapper**: `RdfListMapper<T>` from rdf_mapper package
const rdfList = CollectionMapping.withItemMappers(RdfListMapper);

/// Maps Dart collections to RDF Sequence structures (rdf:_1, rdf:_2, rdf:_3...).
///
/// **RDF Structure**: Creates numbered properties for ordered sequences
/// **Dart Type**: Works with `List<T>` - will lead to compile errors in generated mappers if used with other types like `Set<T>` or `Iterable<T>`.
/// **Order**: Preserved - items are numbered consecutively starting from rdf:_1
/// **Use Case**: When order matters and you want clear indexing/numbering
///
/// ## Example Usage
/// ```dart
/// @RdfProperty(SchemaBook.authors, collection: rdfSeq)
/// final List<Person> authors;
/// ```
///
/// ## Generated RDF
/// ```turtle
/// <book> schema:authors _:seq1 .
/// _:seq1 rdf:type rdf:Seq ;
///        rdf:_1 <person1> ;
///        rdf:_2 <person2> ;
///        rdf:_3 <person3> .
/// ```
///
/// **Underlying Mapper**: `RdfSeqMapper<T>` from rdf_mapper package
const rdfSeq = CollectionMapping.withItemMappers(RdfSeqMapper);

/// Maps Dart collections to RDF Bag structures (unordered collections).
///
/// **RDF Structure**: Creates an unordered collection with rdf:Bag type
/// **Dart Type**: Works with `List<T>` - will lead to compile errors in generated mappers if used with other types like `Set<T>` or `Iterable<T>`.
/// **Order**: NOT preserved - explicitly indicates order is not significant
/// **Use Case**: When order doesn't matter and you want to be explicit about it
///
/// ## Example Usage
/// ```dart
/// @RdfProperty(SchemaBook.keywords, collection: rdfBag)
/// final Set<String> keywords;
/// ```
///
/// ## Generated RDF
/// ```turtle
/// <book> schema:keywords _:bag1 .
/// _:bag1 rdf:type rdf:Bag ;
///        rdf:_1 "keyword1" ;
///        rdf:_2 "keyword2" ;
///        rdf:_3 "keyword3" .
/// ```
///
/// **Underlying Mapper**: `RdfBagMapper<T>` from rdf_mapper package
const rdfBag = CollectionMapping.withItemMappers(RdfBagMapper);

/// Maps Dart collections to RDF Alternative structures (first is preferred).
///
/// **RDF Structure**: Creates an alternative collection with rdf:Alt type
/// **Dart Type**: Works with `List<T>` - will lead to compile errors in generated mappers if used with other types like `Set<T>` or `Iterable<T>`.
/// **Order**: First item is considered the preferred/default choice
/// **Use Case**: Representing alternative values where first is preferred
///
/// ## Example Usage
/// ```dart
/// @RdfProperty(SchemaBook.availableFormats, collection: rdfAlt)
/// final List<String> formats; // ["PDF", "EPUB", "HTML"]
/// ```
///
/// ## Generated RDF
/// ```turtle
/// <book> schema:availableFormats _:alt1 .
/// _:alt1 rdf:type rdf:Alt ;
///        rdf:_1 "PDF" ;      # Preferred format
///        rdf:_2 "EPUB" ;
///        rdf:_3 "HTML" .
/// ```
///
/// **Underlying Mapper**: `RdfAltMapper<T>` from rdf_mapper package
const rdfAlt = CollectionMapping.withItemMappers(RdfAltMapper);

/// Maps Dart Iterable collections to multiple separate triples.
///
/// **RDF Structure**: Creates multiple triples with the same predicate
/// **Dart Type**: Works with `Iterable<T>` - will lead to compile errors in generated mappers if used with other types like `Set<T>` or `List<T>`.
/// **Order**: NOT preserved - each item becomes a separate triple
/// **Use Case**: Generic collections where order doesn't matter, maximum compatibility
///
/// ## Example Usage
/// ```dart
/// @RdfProperty(SchemaBook.contributors, collection: unorderedItems)
/// final Iterable<Person> contributors;
/// ```
///
/// ## Generated RDF
/// ```turtle
/// <book> schema:contributors <person1> .
/// <book> schema:contributors <person2> .
/// <book> schema:contributors <person3> .
/// ```
///
/// **Underlying Mapper**: `UnorderedItemsMapper<T>` from rdf_mapper package
const unorderedItems = CollectionMapping.withItemMappers(UnorderedItemsMapper);

/// Maps Dart List collections to multiple separate triples.
///
/// **RDF Structure**: Creates multiple triples with the same predicate
/// **Dart Type**: Works with `List<T>` - will lead to compile errors in generated mappers if used with other types like `Set<T>` or `Iterable<T>`.
/// **Order**: NOT preserved - each item becomes a separate triple
/// **Use Case**: When you want explicit control over List serialization as multiple triples
///
/// ## Example Usage
/// ```dart
/// @RdfProperty(SchemaBook.tags, collection: unorderedItemsList)
/// final List<String> tags;
/// ```
///
/// ## Generated RDF
/// ```turtle
/// <book> schema:tags "tag1" .
/// <book> schema:tags "tag2" .
/// <book> schema:tags "tag3" .
/// ```
///
/// **Note**: This is the default behavior for `List<T>` when no collection is specified.
/// Only use explicitly when you need to override other collection mapping defaults.
///
/// **Underlying Mapper**: `UnorderedItemsListMapper<T>` from rdf_mapper package
const unorderedItemsList =
    CollectionMapping.withItemMappers(UnorderedItemsListMapper);

/// Maps Dart Set collections to multiple separate triples.
///
/// **RDF Structure**: Creates multiple triples with the same predicate
/// **Dart Type**: Works with `Set<T>` - will lead to compile errors in generated mappers if used with other types like `List<T>` or `Iterable<T>`.
/// **Order**: NOT preserved - each item becomes a separate triple
/// **Use Case**: When you want explicit control over Set serialization as multiple triples
///
/// ## Example Usage
/// ```dart
/// @RdfProperty(SchemaBook.genres, collection: unorderedItemsSet)
/// final Set<String> genres;
/// ```
///
/// ## Generated RDF
/// ```turtle
/// <book> schema:genres "Fiction" .
/// <book> schema:genres "Mystery" .
/// <book> schema:genres "Thriller" .
/// ```
///
/// **Note**: This is the default behavior for `Set<T>` when no collection is specified.
/// Only use explicitly when you need to override other collection mapping defaults.
///
/// **Underlying Mapper**: `UnorderedItemsSetMapper<T>` from rdf_mapper package
const unorderedItemsSet =
    CollectionMapping.withItemMappers(UnorderedItemsSetMapper);
