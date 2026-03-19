/// RDF Binary Dataset Decoder
///
/// Defines the interface for decoding RDF dataset data from binary formats.
library;

import 'dart:typed_data';

import 'package:locorda_rdf_core/src/dataset/rdf_dataset.dart';
import 'package:locorda_rdf_core/src/rdf_binary_decoder.dart';

/// Configuration options for RDF binary dataset decoders.
///
/// Extends the base binary decoder options for dataset-specific configuration.
class RdfBinaryDatasetDecoderOptions extends RdfBinaryDecoderOptions {
  /// Creates default decoder options with no special configurations.
  const RdfBinaryDatasetDecoderOptions();
}

/// Base class for decoding binary RDF documents into RDF datasets.
///
/// This abstract class specializes [RdfBinaryDecoder] for the [RdfDataset]
/// type. Binary dataset format decoders (such as Jelly for quad/graph streams)
/// should extend this class.
abstract class RdfBinaryDatasetDecoder extends RdfBinaryDecoder<RdfDataset> {
  const RdfBinaryDatasetDecoder();

  @override
  RdfDataset convert(Uint8List input);

  @override
  RdfBinaryDatasetDecoder withOptions(RdfBinaryDecoderOptions options);
}
