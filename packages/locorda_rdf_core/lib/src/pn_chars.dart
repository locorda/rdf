/// Shared SPARQL/Turtle PN_CHARS character class definitions per the W3C
/// grammar productions used by NTriples, NQuads, Turtle, and TriG parsers.
///
/// See: https://www.w3.org/TR/rdf12-turtle/#sec-grammar
library;

// ---------------------------------------------------------------------------
// Unicode range fragments (shared building blocks)
// ---------------------------------------------------------------------------

/// Unicode ranges for PN_CHARS_BASE (letters only, no underscore/colon).
const _pnCharsBaseRanges = r'\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF'
    r'\u0370-\u037D\u037F-\u1FFF\u200C-\u200D'
    r'\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF'
    r'\uF900-\uFDCF\uFDF0-\uFFFD';

/// Supplementary plane range (requires `unicode: true` flag).
const _supplementaryRange = '\\u{10000}-\\u{EFFFF}';

/// Extra ranges added by PN_CHARS on top of PN_CHARS_U:
/// '-' | [0-9] | #x00B7 | [#x0300-#x036F] | [#x203F-#x2040]
const _pnCharsExtraRanges = r'\u00B7\u0300-\u036F\u203F-\u2040';

// ---------------------------------------------------------------------------
// Character class RegExps
// ---------------------------------------------------------------------------

/// `PN_CHARS_U ::= PN_CHARS_BASE | '_'`
///
/// Matches a single character that is valid as the first character of a blank
/// node label (when combined with `[0-9]`).
final pnCharsU = RegExp(
  '[a-zA-Z_$_pnCharsBaseRanges$_supplementaryRange]',
  unicode: true,
);

/// `PN_CHARS ::= PN_CHARS_U | '-' | [0-9] | #x00B7 | [#x0300-#x036F] | [#x203F-#x2040]`
///
/// Matches a single PN_CHARS character — the set of characters allowed in the
/// body of blank node labels, prefixed names, and local names.
final pnChars = RegExp(
  '[a-zA-Z0-9_\\-$_pnCharsExtraRanges$_pnCharsBaseRanges$_supplementaryRange]',
  unicode: true,
);

/// `PN_CHARS | '.'`
///
/// Matches PN_CHARS or dot — used for scanning blank node label bodies where
/// dots are allowed in the middle but not at the end.
final pnCharsOrDot = RegExp(
  '[a-zA-Z0-9_\\.\\-$_pnCharsExtraRanges$_pnCharsBaseRanges$_supplementaryRange]',
  unicode: true,
);

/// `PN_CHARS_BASE | '_' | ':'` — name start chars for TriG/Turtle prefixed names.
final pnNameStartChar = RegExp(
  '[a-zA-Z_:$_pnCharsBaseRanges$_supplementaryRange]',
  unicode: true,
);

/// `PN_CHARS | '.' | ':'` — local name chars for TriG/Turtle.
final pnLocalNameChar = RegExp(
  '[a-zA-Z0-9_\\.:\\-$_pnCharsExtraRanges$_pnCharsBaseRanges$_supplementaryRange]',
  unicode: true,
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns the full Unicode character at [pos] in [input] (handling surrogate
/// pairs) and the number of UTF-16 code units it occupies (1 or 2).
(String char, int width) charAt(String input, int pos) {
  final code = input.codeUnitAt(pos);
  if (code >= 0xD800 && code <= 0xDBFF && pos + 1 < input.length) {
    final low = input.codeUnitAt(pos + 1);
    if (low >= 0xDC00 && low <= 0xDFFF) {
      return (input.substring(pos, pos + 2), 2);
    }
  }
  return (input[pos], 1);
}
