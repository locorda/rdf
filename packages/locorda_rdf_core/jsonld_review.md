# JSON-LD Implementation Code Review

## Summary

The JSON-LD implementation spans ~14 source files and passes all W3C test suites
(385 expansion, 246 compaction, 55 flatten, fromRdf tests). The architecture is
sound, following the W3C spec decomposition into distinct processors.

All findings below have been addressed. The codebase now has zero analyzer warnings.

---

## Findings and Resolutions

### 1. Code Duplication - FIXED

**1.1 Duplicate `rdfJsonDatatype` constant** - Was declared in 4 files.
Created `jsonld_utils.dart` as a shared utilities file. All files now import
from one source.

**1.2 Duplicate deep-equality helpers** - `_mapEquals`/`_listEquals` in
flatten processor duplicated `_jsonValueDeepEquals` from context processor.
Extracted `jsonValueDeepEquals` to `jsonld_utils.dart`. Flatten processor
now uses the shared version.

**1.3 Duplicate `_containsInvalidIriChars`** - Existed in both expansion
processor and context processor. Made the context processor's version public
(`containsInvalidIriChars`). Expansion processor now delegates to it.

**1.4 `_canUseAsPrefix` duplication** - Kept separate intentionally. The context
processor version (for IRI expansion) and compaction processor version (for IRI
compaction) have subtly different semantics: the compaction version additionally
checks `isSimpleTermDefinition`. Merging them would risk spec compliance.

### 2. Analyzer Issues - FIXED

- Removed unused `_log` declaration and `logging` import from compaction processor
- Removed unnecessary casts in compaction processor (2 instances)
- Removed 5 unnecessary imports across async_decoder, compaction_processor,
  context_processor, encoder, and flatten_processor
- Added curly braces to flow control statement in compaction processor

### 3. Stale Code - FIXED

- Removed stale "unused_field" comment and ignore annotation on `_options` in
  `JsonLdDecoder` (the field IS used in `convert()`)
- Made `_useNumericLocalNames` a `static const` in `JsonLdEncoder` (was a
  non-configurable `final` field always set to `true`)

### 4. Cleanup - DONE

- Deleted 8 debug test files (`test/debug_*.dart`)

### 5. Reviewed and Confirmed Correct (no changes needed)

- `_lookupTermByCompactIri` - Trivial method but used 11 times as
  self-documenting intent. Kept as-is.
- `Map<dynamic, dynamic>` handling in `mergeContext` - Correct for Dart JSON interop.
- `ordered` parameter threading through expansion - Correct per W3C spec.
- Blank node relabeling in flatten - Correct per W3C section 7.4.
- `@index` substantive entry fix - Correct per W3C section 14.2.1.
- Long methods (`_expandObject`, `_processProperty`, `_selectTerm`) - These
  follow the W3C spec structure closely. Splitting them would make spec
  correspondence harder to verify. Left as-is.

---

## Test Results

- **locorda_rdf_core**: 3135 passed, 3 skipped, 0 failed
- **locorda_rdf_mapper**: 703 passed, 0 failed
- **Dart analyzer**: 0 issues across all lib/ code
