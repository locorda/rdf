# Code Review: locorda_rdf_jsonld

Reviewed: 2026-04-13

## Summary

Overall the package is well-structured, well-documented, and implements the
JSON-LD specification thoroughly. The code is generally clean and
well-organized. The issues below are sorted by severity.

---

## Issues Found and Fixed

### 1. Cross-package `src/` import (high)

**File:** `lib/src/jsonld/jsonld_async_decoder.dart`

Imported `package:locorda_rdf_core/src/iri_util.dart` which violates the
Dart package convention. Replaced with `package:locorda_rdf_core/extend.dart`.

### 2. `analysis_options.yaml` uses `core.yaml` (medium)

Upgraded from `package:lints/core.yaml` to `package:lints/recommended.yaml`
which is the recommended lint set for published packages.

### 3. Truncated doc comment (medium)

Fixed incomplete doc comment on `_getSubjectId` in `jsonld_decoder.dart`.

### 4. Unnecessary `this.` member access (low)

Removed redundant `this.` prefix in `jsonld_codec.dart` and
`jsonld_graph_codec.dart`.

### 5. Redundant `.toString()` in string interpolation (low)

Fixed `${e.toString()}` to `$e` in three files.

### 6. Named `library` directives replaced with unnamed `library;` (low)

All files updated to use unnamed `library;` per modern Dart conventions.

### 7. Inconsistent logger variable naming (low)

Renamed `_logger` to `_log` in `jsonld_graph_decoder.dart` for consistency.

### 8. Additional lint fixes from `recommended.yaml` (low)

- `unnecessary_brace_in_string_interps` in `jsonld_expanded_serializer.dart`
- `prefer_initializing_formals` in `jsonld_graph_encoder.dart`
- `no_leading_underscores_for_local_identifiers` in test files
- `prefer_is_not_operator` in test file

## Positive Observations

- Clean public API surface with proper `show` clauses
- Good use of `final class` for codec and encoder classes
- Comprehensive W3C spec compliance
- Thorough test coverage (212+ tests)
- Proper deprecation handling for legacy APIs
