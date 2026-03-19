/// RDF Binary Decoder Interface & Utilities
///
/// Defines the interface and utilities for decoding RDF data from binary formats.
///
/// See: [RDF 1.1 Concepts - Syntax](https://www.w3.org/TR/rdf11-concepts/#section-syntax)
library;

import 'dart:convert';
import 'dart:typed_data';

/// Configuration options for RDF binary decoders.
///
/// This class provides configuration options that can be passed to RDF binary
/// decoders to modify their parsing behavior. Concrete implementations may
/// extend this class to provide format-specific options.
///
/// The base implementation provides no options, but serves as an extension
/// point for format-specific configuration.
class RdfBinaryDecoderOptions {
  /// Creates default decoder options with no special configurations.
  const RdfBinaryDecoderOptions();
}

/// Base class for decoding RDF documents from binary serialization formats.
///
/// This abstract class extends the standard `Converter` interface to provide
/// a common API for decoding binary RDF serializations (such as Jelly, HDT,
/// etc.). Each format implements this interface to handle its specific binary
/// encoding rules.
///
/// Format-specific decoders should implement this base class to be compatible
/// with the RDF library's parsing framework and to ensure consistent behavior
/// across different binary formats.
abstract class RdfBinaryDecoder<G> extends Converter<Uint8List, G> {
  const RdfBinaryDecoder();

  /// Decodes a binary RDF document and returns the appropriate RDF data
  /// structure.
  ///
  /// This method transforms a binary RDF document into a structured RDF data
  /// object (graph, dataset, etc.) containing the parsed data from the input.
  ///
  /// The [input] parameter is the binary RDF data to decode.
  @override
  G convert(Uint8List input);

  /// Creates a new decoder with the specified options.
  ///
  /// Returns a new instance of the decoder configured with the provided
  /// options. The original decoder instance remains unchanged.
  RdfBinaryDecoder<G> withOptions(RdfBinaryDecoderOptions options);
}
