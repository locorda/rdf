import 'package:locorda_rdf_mapper/src/api/deserialization_strictness.dart';

/// Configuration for the RDF mapper's runtime behavior.
///
/// Groups all behavioral settings that control how the mapper handles
/// edge cases during serialization and deserialization. Using a settings
/// object allows adding new knobs without changing constructor signatures.
///
/// Example:
/// ```dart
/// // Lenient mapper that recovers from corrupted data
/// final mapper = RdfMapper.withMappers(
///   (r) => r.registerMapper<Person>(PersonMapper()),
///   settings: RdfMapperSettings.warnOnly(),
/// );
/// ```
class RdfMapperSettings {
  /// Controls how data integrity issues are handled during deserialization.
  final DeserializationStrictness strictness;

  /// Creates settings with explicit values.
  const RdfMapperSettings({
    this.strictness = DeserializationStrictness.strict,
  });

  /// Default strict settings — all data issues throw exceptions.
  const RdfMapperSettings.strict()
      : strictness = DeserializationStrictness.strict;

  /// Warn-only settings — recoverable issues are logged as warnings.
  const RdfMapperSettings.warnOnly()
      : strictness = DeserializationStrictness.warnOnly;

  /// Lenient settings — recoverable issues are silently handled.
  const RdfMapperSettings.lenient()
      : strictness = DeserializationStrictness.lenient;

  /// Returns a copy with the given fields replaced.
  RdfMapperSettings copyWith({
    DeserializationStrictness? strictness,
  }) {
    return RdfMapperSettings(
      strictness: strictness ?? this.strictness,
    );
  }
}
