/// Jelly RDF codec configuration options.
library;

import 'package:locorda_rdf_core/core.dart';

import 'proto/rdf.pbenum.dart';

/// Configuration options for the Jelly RDF decoder.
class JellyDecoderOptions extends RdfBinaryDecoderOptions {
  const JellyDecoderOptions();
}

/// Configuration options for the Jelly RDF encoder.
class JellyEncoderOptions extends RdfBinaryEncoderOptions {
  /// Maximum size of the name lookup table.
  ///
  /// Must be >= 8 per the Jelly specification. Larger tables allow more
  /// IRI name entries to be cached, reducing output size at the cost of
  /// memory.
  final int maxNameTableSize;

  /// Maximum size of the prefix lookup table.
  ///
  /// Larger tables allow more IRI prefix entries to be cached.
  final int maxPrefixTableSize;

  /// Maximum size of the datatype lookup table.
  final int maxDatatypeTableSize;

  /// The physical stream type to use when encoding.
  ///
  /// - [PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES] for graph encoding
  /// - [PhysicalStreamType.PHYSICAL_STREAM_TYPE_QUADS] for dataset encoding
  /// - [PhysicalStreamType.PHYSICAL_STREAM_TYPE_GRAPHS] for dataset encoding
  ///   with graph boundaries
  final PhysicalStreamType physicalType;

  /// Optional logical stream type annotation (purely informational).
  final LogicalStreamType logicalType;

  /// Maximum number of rows per frame.
  ///
  /// Smaller frames allow more incremental processing but add overhead.
  /// The Jelly specification recommends frames stay under 1 MB.
  final int maxRowsPerFrame;

  /// Optional stream name (purely informational).
  final String? streamName;

  const JellyEncoderOptions({
    this.maxNameTableSize = 128,
    this.maxPrefixTableSize = 32,
    this.maxDatatypeTableSize = 16,
    this.physicalType = PhysicalStreamType.PHYSICAL_STREAM_TYPE_TRIPLES,
    this.logicalType = LogicalStreamType.LOGICAL_STREAM_TYPE_UNSPECIFIED,
    this.maxRowsPerFrame = 256,
    this.streamName,
  }) : assert(maxNameTableSize >= 8,
            'maxNameTableSize must be >= 8 per the Jelly specification');

  JellyEncoderOptions copyWith({
    int? maxNameTableSize,
    int? maxPrefixTableSize,
    int? maxDatatypeTableSize,
    PhysicalStreamType? physicalType,
    LogicalStreamType? logicalType,
    int? maxRowsPerFrame,
    String? streamName,
  }) =>
      JellyEncoderOptions(
        maxNameTableSize: maxNameTableSize ?? this.maxNameTableSize,
        maxPrefixTableSize: maxPrefixTableSize ?? this.maxPrefixTableSize,
        maxDatatypeTableSize: maxDatatypeTableSize ?? this.maxDatatypeTableSize,
        physicalType: physicalType ?? this.physicalType,
        logicalType: logicalType ?? this.logicalType,
        maxRowsPerFrame: maxRowsPerFrame ?? this.maxRowsPerFrame,
        streamName: streamName ?? this.streamName,
      );
}
