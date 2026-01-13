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

export 'src/property/collection_mapping_constants.dart';
