/// RDF Binary Dataset Codec Plugin System
///
/// Defines the plugin architecture for binary RDF dataset serialization
/// formats. This parallels [RdfDatasetCodec] but operates on [Uint8List]
/// instead of [String].
library;

import 'dart:typed_data';

import 'package:locorda_rdf_core/src/dataset/rdf_dataset.dart';
import 'package:locorda_rdf_core/src/plugin/rdf_binary_base_codec.dart';
import 'package:locorda_rdf_core/src/plugin/rdf_binary_codec_registry.dart';
import 'package:locorda_rdf_core/src/rdf_binary_dataset_decoder.dart';
import 'package:locorda_rdf_core/src/rdf_binary_dataset_encoder.dart';
import 'package:locorda_rdf_core/src/rdf_binary_decoder.dart';
import 'package:locorda_rdf_core/src/rdf_binary_encoder.dart';

/// A binary codec for RDF dataset serialization formats.
///
/// Extends [RdfBinaryCodec] specialized for [RdfDataset]. Implementations
/// provide binary encoding and decoding of RDF datasets (e.g., Jelly QUADS
/// or GRAPHS streams).
///
/// To add support for a new binary dataset format, extend this class and
/// register an instance with [RdfBinaryDatasetCodecRegistry].
abstract class RdfBinaryDatasetCodec extends RdfBinaryCodec<RdfDataset> {
  @override
  RdfBinaryDatasetDecoder get decoder;

  @override
  RdfBinaryDatasetEncoder get encoder;

  const RdfBinaryDatasetCodec();

  @override
  RdfBinaryDatasetCodec withOptions({
    RdfBinaryEncoderOptions? encoder,
    RdfBinaryDecoderOptions? decoder,
  });
}

/// Manages registration and discovery of binary RDF dataset codec plugins.
///
/// Mirrors [RdfDatasetCodecRegistry] for binary formats.
final class RdfBinaryDatasetCodecRegistry
    extends BaseRdfBinaryCodecRegistry<RdfDataset> {
  /// Creates a new binary dataset codec registry.
  ///
  /// Optionally accepts a list of codecs to register immediately.
  RdfBinaryDatasetCodecRegistry(
      [List<RdfBinaryDatasetCodec> initialCodecs = const []])
      : super() {
    for (final codec in initialCodecs) {
      registerCodec(codec);
    }
  }
}
