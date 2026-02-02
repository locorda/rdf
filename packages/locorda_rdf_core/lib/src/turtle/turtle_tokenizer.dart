/// Turtle Tokenizer Implementation
///
/// Implements the [TurtleTokenizer] class for lexical analysis of Turtle syntax.
///
/// Example usage:
/// ```dart
/// import 'package:locorda_rdf_core/src/turtle/turtle_tokenizer.dart';
/// final tokenizer = TurtleTokenizer(input);
/// final token = tokenizer.nextToken();
/// ```
/// The tokenizer is responsible for:
/// 1. Identifying the basic lexical elements of Turtle (IRIs, literals, etc.)
/// 2. Handling whitespace, comments, and line breaks
/// 3. Providing position information for error reporting
/// 4. Managing escape sequences in strings and IRIs
///
/// See: https://www.w3.org/TR/turtle/ for the Turtle specification.
library turtle_tokenizer;

import 'package:locorda_rdf_core/src/trig/trig_tokenizer.dart';

/// Flags for non-standard Turtle parsing behavior.
///
/// These flags allow for more granular control over how relaxed the parser should be
/// when encountering various non-standard Turtle syntax patterns. Each flag represents
/// a specific deviation from the standard Turtle specification.
///
/// Use these flags when parsing real-world Turtle files that don't strictly follow
/// the W3C Turtle specification but are still semantically meaningful.
enum TurtleParsingFlag {
  /// Allows prefixed names to have local names that start with digits.
  /// E.g., allows `schema:3DModel` which is not valid in standard Turtle.
  allowDigitInLocalName,

  /// Allows prefix declarations without a trailing dot.
  /// E.g., allows `@prefix ex: <http://example.com/>`
  allowMissingDotAfterPrefix,

  /// Auto-adds common prefixes (rdf, rdfs, xsd, etc.) when not explicitly defined.
  /// This can help parse documents that use standard prefixes without declaring them.
  autoAddCommonPrefixes,

  /// Allows prefix declarations without the @ symbol (case-insensitive).
  /// E.g., allows `prefix ex: <http://example.com/>`, `PREFIX ex: <http://example.com/>`,
  /// `base <http://example.org/>`, or `BASE <http://example.org/>`
  allowPrefixWithoutAtSign,

  /// Handles missing dots at the end of triple statements more gracefully.
  allowMissingFinalDot,

  /// Allows simple identifiers without colons to be treated as prefixed names.
  /// E.g., allows `abc` to be treated as an IRI that is resolved against the base URI.
  ///
  /// Note: This requires that a base URI is set, either through an @base directive
  /// in the document or provided as the documentUrl parameter when decoding.
  ///
  /// Example:
  /// ```
  /// @base <http://example.org/> .
  /// <http://example.org/subject> a Type .
  /// ```
  /// Here "Type" will be resolved to <http://example.org/Type>
  allowIdentifiersWithoutColon,
}

TurtleParsingFlag toTurtleParsingFlag(TriGParsingFlag flag) => switch (flag) {
      TriGParsingFlag.allowDigitInLocalName =>
        TurtleParsingFlag.allowDigitInLocalName,
      TriGParsingFlag.allowMissingDotAfterPrefix =>
        TurtleParsingFlag.allowMissingDotAfterPrefix,
      TriGParsingFlag.autoAddCommonPrefixes =>
        TurtleParsingFlag.autoAddCommonPrefixes,
      TriGParsingFlag.allowPrefixWithoutAtSign =>
        TurtleParsingFlag.allowPrefixWithoutAtSign,
      TriGParsingFlag.allowMissingFinalDot =>
        TurtleParsingFlag.allowMissingFinalDot,
      TriGParsingFlag.allowIdentifiersWithoutColon =>
        TurtleParsingFlag.allowIdentifiersWithoutColon,
    };
TriGParsingFlag toTriGParsingFlag(TurtleParsingFlag flag) => switch (flag) {
      TurtleParsingFlag.allowDigitInLocalName =>
        TriGParsingFlag.allowDigitInLocalName,
      TurtleParsingFlag.allowMissingDotAfterPrefix =>
        TriGParsingFlag.allowMissingDotAfterPrefix,
      TurtleParsingFlag.autoAddCommonPrefixes =>
        TriGParsingFlag.autoAddCommonPrefixes,
      TurtleParsingFlag.allowPrefixWithoutAtSign =>
        TriGParsingFlag.allowPrefixWithoutAtSign,
      TurtleParsingFlag.allowMissingFinalDot =>
        TriGParsingFlag.allowMissingFinalDot,
      TurtleParsingFlag.allowIdentifiersWithoutColon =>
        TriGParsingFlag.allowIdentifiersWithoutColon,
    };
