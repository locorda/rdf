/// RDF Binary Codec Base
///
/// Defines the base codec abstraction for binary RDF serialization formats.
/// This parallels [RdfCodec] but operates on [Uint8List] instead of [String].
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:locorda_rdf_core/src/rdf_binary_decoder.dart';
import 'package:locorda_rdf_core/src/rdf_binary_encoder.dart';

/// Base class for binary RDF codecs.
///
/// A binary codec pairs a [RdfBinaryDecoder] and [RdfBinaryEncoder] for a
/// specific binary RDF serialization format. It extends `Codec<G, Uint8List>`
/// (rather than `Codec<G, String>` like text codecs) to preserve type safety.
///
/// Implementations should provide:
/// - A [primaryMimeType] for format identification
/// - [supportedMimeTypes] for all recognized MIME types
/// - [decoder] and [encoder] instances for the format
/// - [canParseBytes] for heuristic binary format detection
abstract class RdfBinaryCodec<G> extends Codec<G, Uint8List> {
  /// The primary MIME type for this codec.
  ///
  /// This is the canonical MIME type used to identify the codec,
  /// typically the one registered with IANA.
  String get primaryMimeType;

  /// All MIME types supported by this codec.
  ///
  /// Some codecs may have multiple MIME types associated with them.
  /// This set should include all MIME types that the codec implementation
  /// can handle.
  Set<String> get supportedMimeTypes;

  @override
  RdfBinaryDecoder<G> get decoder;

  @override
  RdfBinaryEncoder<G> get encoder;

  const RdfBinaryCodec();

  /// Creates a new codec instance with the specified options.
  ///
  /// Returns a new instance of the codec configured with the provided
  /// encoder and decoder options. The original codec instance remains
  /// unchanged.
  RdfBinaryCodec<G> withOptions({
    RdfBinaryEncoderOptions? encoder,
    RdfBinaryDecoderOptions? decoder,
  });

  /// Encodes an RDF data structure to binary.
  ///
  /// Convenience method that delegates to the codec's encoder, optionally
  /// applying the given [options].
  Uint8List encode(
    G input, {
    RdfBinaryEncoderOptions? options,
  }) {
    return (options == null ? encoder : encoder.withOptions(options))
        .convert(input);
  }

  /// Decodes binary RDF data into an RDF data structure.
  ///
  /// Convenience method that delegates to the codec's decoder, optionally
  /// applying the given [options].
  G decode(
    Uint8List input, {
    RdfBinaryDecoderOptions? options,
  }) {
    return (options == null ? decoder : decoder.withOptions(options))
        .convert(input);
  }

  /// Tests if the provided binary content is likely in this codec's format.
  ///
  /// Used for codec auto-detection when no explicit MIME type is available.
  /// Should perform quick heuristic checks (e.g., magic bytes) without
  /// attempting a full parse.
  bool canParseBytes(Uint8List content);
}
