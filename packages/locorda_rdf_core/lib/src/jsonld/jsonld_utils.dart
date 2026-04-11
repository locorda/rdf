/// Shared JSON-LD utilities and constants.
///
/// This library provides common constants and helper functions used across
/// multiple JSON-LD processors (expansion, compaction, flattening, serialization).
library jsonld_utils;

import 'package:locorda_rdf_core/src/jsonld/jsonld_context.dart';

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

// ---------------------------------------------------------------------------
// Prefix checking utilities
// ---------------------------------------------------------------------------

/// Characters that indicate an IRI was designed as a namespace prefix.
///
/// These are the gen-delim characters from RFC 3986.
const _genDelimChars = '/:?#[]@';

/// Returns `true` if a term definition can be used as a prefix for
/// compact IRI expansion during context processing.
///
/// Per W3C JSON-LD 1.1 §4.2.2 step 15.2, Create Term Definition
/// concatenates the prefix IRI with the suffix without checking the
/// prefix flag. This function is used during context processing where
/// that rule applies.
///
/// For IRI expansion during data processing (§5.2 step 6.4), use
/// [canUseAsPrefixStrict] which additionally checks
/// [TermDefinition.isSimpleTermDefinition].
bool canUseAsPrefix(TermDefinition def, {required String processingMode}) {
  if (def.isPrefix) return true;
  if (def.hasPrefix && !def.isPrefix) return false;
  if (processingMode == 'json-ld-1.0') return true;
  if (def.iri != null && def.iri!.isNotEmpty) {
    final last = def.iri![def.iri!.length - 1];
    if (_genDelimChars.contains(last)) return true;
  }
  return false;
}

/// Returns `true` if a term definition can be used as a prefix for
/// compact IRI expansion during data processing.
///
/// Per W3C JSON-LD 1.1 §5.2 step 6.4 (IRI Expansion), the prefix flag
/// must be `true`. Per §4.2.2 step 14.5, the prefix flag is only
/// automatically set for simple term definitions (string values) whose
/// IRI ends in a gen-delim character. Expanded term definitions require
/// explicit `@prefix: true`.
bool canUseAsPrefixStrict(
    TermDefinition def, {required String processingMode}) {
  if (def.isPrefix) return true;
  if (def.hasPrefix && !def.isPrefix) return false;
  if (!def.isSimpleTermDefinition) return false;
  if (processingMode == 'json-ld-1.0') return true;
  if (def.iri != null && def.iri!.isNotEmpty) {
    final last = def.iri![def.iri!.length - 1];
    if (_genDelimChars.contains(last)) return true;
  }
  return false;
}

// ---------------------------------------------------------------------------
// JSON value utilities
// ---------------------------------------------------------------------------

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
