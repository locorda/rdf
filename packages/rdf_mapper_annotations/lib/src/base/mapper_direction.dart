/// Specifies whether a mapper should handle serialization, deserialization, or both.
///
/// This enum is used to control the directionality of mappers when using custom
/// mapper constructors (`.namedMapper()`, `.mapper()`, `.mapperInstance()`).
///
/// The generated code will create appropriate serializer-only, deserializer-only,
/// or bidirectional mapper implementations based on this setting.
enum MapperDirection {
  /// Mapper handles both serialization and deserialization (default).
  ///
  /// This is the standard mode where the mapper can convert objects to RDF
  /// and back from RDF to objects.
  both,

  /// Mapper only handles serialization to RDF.
  ///
  /// Use this when you only need to write RDF data and never need to
  /// reconstruct objects from RDF.
  serializeOnly,

  /// Mapper only handles deserialization from RDF.
  ///
  /// Use this when you only need to read RDF data and construct objects,
  /// but never need to serialize objects back to RDF. This is particularly
  /// useful when the IRI construction strategy is not needed or cannot be
  /// determined from the object properties alone.
  deserializeOnly,
}
