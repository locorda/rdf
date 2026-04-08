/// Describes the encoding and data-shape capabilities of a content type
/// registered with [RdfCore].
///
/// Returned by [RdfCore.contentTypeInfo] when the queried MIME type is known
/// to at least one registered codec. The combination of flags fully describes
/// which [RdfCore] codec families can be used for the type:
///
/// | [isBinary] | [supportsGraph] | [supportsDataset] | Example          |
/// |:----------:|:---------------:|:-----------------:|:-----------------|
/// | false      | true            | false             | text/turtle      |
/// | false      | false           | true              | application/trig |
/// | false      | true            | true              | application/ld+json (both registries) |
/// | true       | true            | true              | application/x-jelly-rdf |
///
/// Note that it is possible for a content type to be registered in both the
/// graph and the dataset codec families simultaneously (e.g., a format that
/// can serialise both shapes).
final class RdfContentTypeInfo {
  /// The canonical primary MIME type of the codec that handles this content
  /// type.
  ///
  /// When the queried MIME type is an alias (e.g., `application/x-turtle`),
  /// this field reveals the canonical form (e.g., `text/turtle`), making it
  /// easy to detect alias usage and understand the true format capabilities.
  final String primaryMimeType;

  /// Whether the content type is a binary encoding (not text-based).
  final bool isBinary;

  /// Whether this content type can be used with the RDF graph codec family
  /// ([RdfCore.decode] / [RdfCore.encode] or the binary equivalents).
  final bool supportsGraph;

  /// Whether this content type can be used with the RDF dataset codec family
  /// ([RdfCore.decodeDataset] / [RdfCore.encodeDataset] or the binary equivalents).
  final bool supportsDataset;

  const RdfContentTypeInfo({
    required this.primaryMimeType,
    required this.isBinary,
    required this.supportsGraph,
    required this.supportsDataset,
  });

  @override
  bool operator ==(Object other) =>
      other is RdfContentTypeInfo &&
      primaryMimeType == other.primaryMimeType &&
      isBinary == other.isBinary &&
      supportsGraph == other.supportsGraph &&
      supportsDataset == other.supportsDataset;

  @override
  int get hashCode =>
      Object.hash(primaryMimeType, isBinary, supportsGraph, supportsDataset);

  @override
  String toString() =>
      'RdfContentTypeInfo(primaryMimeType: $primaryMimeType, isBinary: $isBinary, '
      'supportsGraph: $supportsGraph, supportsDataset: $supportsDataset)';
}
