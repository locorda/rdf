/// Controls how the RDF mapper handles data integrity issues during deserialization.
///
/// This enum governs behavior when the mapper encounters structural problems
/// in the RDF data, such as multiple values for a single-valued property or
/// datatype mismatches. This is separate from [CompletenessMode], which controls
/// how *unmapped* triples are handled after deserialization completes.
///
/// [DeserializationStrictness] addresses *corrupted or unexpected data* encountered
/// during the deserialization process itself.
enum DeserializationStrictness {
  /// Throw exceptions on any data integrity issue (default).
  ///
  /// This is the safest mode and ensures that no corrupted data
  /// silently enters the application.
  strict,

  /// Log warnings for recoverable data issues but continue deserialization.
  ///
  /// Recovery strategies:
  /// - Multiple values for single-valued property: uses the first value
  /// - Datatype mismatch on literal: skips the value (returns null from optional)
  warnOnly,

  /// Silently recover from data integrity issues without logging.
  ///
  /// Same recovery strategies as [warnOnly] but without log output.
  /// Use with caution — data issues will be completely invisible.
  lenient;

  /// Whether this mode should throw on recoverable data issues.
  bool get shouldThrow => this == DeserializationStrictness.strict;

  /// Whether this mode should log recoverable data issues.
  bool get shouldLog => this == DeserializationStrictness.warnOnly;
}
