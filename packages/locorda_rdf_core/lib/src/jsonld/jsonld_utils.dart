/// Shared JSON-LD utilities and constants.
///
/// This library provides common constants and helper functions used across
/// multiple JSON-LD processors (expansion, compaction, flattening, serialization).
library jsonld_utils;

// ---------------------------------------------------------------------------
// Well-known RDF/XSD IRI constants
// ---------------------------------------------------------------------------

/// Well-known RDF datatype for JSON literals.
const rdfJsonDatatype = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#JSON';

// ---------------------------------------------------------------------------
// JSON value utilities
// ---------------------------------------------------------------------------

/// Wraps a value in a list if it isn't already one.
///
/// Returns the value as-is if it is already a `List`, otherwise wraps it
/// in a single-element list. Useful for normalizing JSON-LD values that
/// may be a single item or an array.
List<T> ensureList<T>(Object? value) {
  if (value is List<T>) return value;
  if (value is List) return value.cast<T>();
  return [value as T];
}

/// Deep equality for JSON values (maps, lists, scalars, null).
///
/// Used by the context processor for comparing term definitions and by
/// the flatten processor for deduplicating node map entries.
bool jsonValueDeepEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;
  if (left == null || right == null) return left == right;

  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (!jsonValueDeepEquals(left[i], right[i])) return false;
    }
    return true;
  }

  if (left is Map<String, Object?> && right is Map<String, Object?>) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      if (!right.containsKey(entry.key) ||
          !jsonValueDeepEquals(entry.value, right[entry.key])) {
        return false;
      }
    }
    return true;
  }

  return left == right;
}
