/// RDF Binary Dataset Encoder
///
/// Defines the interface for encoding RDF datasets to binary formats.
library;

import 'dart:typed_data';

import 'package:locorda_rdf_core/src/dataset/rdf_dataset.dart';
import 'package:locorda_rdf_core/src/rdf_binary_encoder.dart';

/// Configuration options for RDF binary dataset encoders.
///
/// Extends the base binary encoder options for dataset-specific configuration.
class RdfBinaryDatasetEncoderOptions extends RdfBinaryEncoderOptions {
  /// Creates default encoder options with no special configurations.
  const RdfBinaryDatasetEncoderOptions();
}

/// Base class for encoding RDF datasets to binary serialization formats.
///
/// This abstract class specializes [RdfBinaryEncoder] for the [RdfDataset]
/// type. Binary dataset format encoders (such as Jelly for quad/graph streams)
/// should extend this class.
abstract class RdfBinaryDatasetEncoder extends RdfBinaryEncoder<RdfDataset> {
  const RdfBinaryDatasetEncoder();

  @override
  Uint8List convert(RdfDataset dataset);

  @override
  RdfBinaryDatasetEncoder withOptions(RdfBinaryEncoderOptions options);
}
