import 'package:locorda_rdf_mapper_annotations/src/base/rdf_annotation.dart';

/// Marks a property to be completely excluded from RDF mapping in generated vocabulary mode.
///
/// This annotation is primarily useful when using [RdfGlobalResource.define] or
/// [RdfLocalResource.define], where unannotated fields are implicitly treated as
/// `@RdfProperty.define()`. Use `@RdfIgnore()` to explicitly exclude fields from both
/// RDF serialization/deserialization AND vocabulary generation.
///
/// **When to use `@RdfIgnore()`:**
/// - Application-specific state that should not be persisted to RDF (e.g., UI state, loading flags)
/// - Computed properties that are derived from other RDF properties
/// - Temporary or cached values that don't belong in the RDF graph
///
/// **Difference from `@RdfProperty.define(include: false)`:**
/// - `@RdfIgnore()` → Field is completely excluded from RDF (no vocab entry, not serialized, not deserialized)
/// - `@RdfProperty.define(include: false)` → Field IS in vocabulary and deserialized, but NOT serialized (read-only from RDF perspective)
///
/// **In non-define mode (using explicit `@RdfProperty(predicate)`):**
/// This annotation has no effect since fields are only mapped when explicitly annotated.
/// Simply omit the `@RdfProperty` annotation to exclude a field.
///
/// ## Examples
///
/// ### Basic usage in define mode
/// ```dart
/// @RdfGlobalResource.define(myVocab, IriStrategy('https://my.app.de/books/{id}'))
/// class Book {
///   // Implicit @RdfProperty.define() - included in vocab
///   final String title;
///
///   // Explicit external vocabulary - no vocab entry generated
///   @RdfProperty(SchemaBook.author)
///   final String author;
///
///   // Completely excluded from RDF
///   @RdfIgnore()
///   final bool isExpanded; // UI state, not persisted
///
///   // Also excluded
///   @RdfIgnore()
///   bool get isModified => _dirty; // Computed property
///
///   // Read-only RDF property (in vocab, deserialize only)
///   @RdfProperty.define(include: false)
///   final DateTime lastModified;
/// }
/// ```
///
/// ### With local resources
/// ```dart
/// @RdfLocalResource.define(myVocab)
/// class Address {
///   final String street; // Implicit @RdfProperty.define()
///   final String city;   // Implicit @RdfProperty.define()
///
///   @RdfIgnore()
///   String? validationError; // Transient validation state
/// }
/// ```
///
/// ### Common use cases
/// ```dart
/// @RdfGlobalResource.define(myVocab, IriStrategy('https://my.app.de/tasks/{id}'))
/// class Task {
///   final String title;
///   final String description;
///
///   // UI state - not part of domain model
///   @RdfIgnore()
///   bool isSelected = false;
///
///   // Cached computation
///   @RdfIgnore()
///   DateTime? _cachedDueDate;
///
///   // Derived property
///   @RdfIgnore()
///   bool get isOverdue => dueDate.isBefore(DateTime.now());
/// }
/// ```
class RdfIgnore implements RdfAnnotation {
  /// Creates an annotation that excludes a field from RDF mapping.
  const RdfIgnore();
}
