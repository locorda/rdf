/// RDF Binary Encoding Framework
///
/// Defines interfaces for encoding RDF data structures to binary serialization
/// formats. Complements the binary decoder framework by providing the reverse
/// operation.
library;

import 'dart:convert';
import 'dart:typed_data';

/// Configuration options for RDF binary encoders.
///
/// This class provides configuration parameters that can be used to customize
/// the behavior of RDF binary encoders. It follows the Options pattern to
/// encapsulate encoder-specific settings.
///
/// Concrete implementations may extend this class to provide format-specific
/// options (e.g., compression level, table sizes).
class RdfBinaryEncoderOptions {
  /// Creates default encoder options with no special configurations.
  const RdfBinaryEncoderOptions();
}

/// Base class for encoding RDF data structures to binary serialization formats.
///
/// This abstract class extends the standard `Converter` interface to provide
/// a common API for encoding RDF data structures into binary representations.
/// Each format implements this interface to handle its specific binary encoding.
///
/// Format-specific encoders should extend this base class to be registered
/// with the RDF library's binary codec framework.
abstract class RdfBinaryEncoder<G> extends Converter<G, Uint8List> {
  const RdfBinaryEncoder();

  /// Encodes an RDF data structure to a binary representation.
  ///
  /// Transforms an in-memory RDF data structure into an encoded binary format
  /// that can be stored or transmitted.
  ///
  /// The [data] parameter is the RDF data structure to encode.
  @override
  Uint8List convert(G data);

  /// Creates a new encoder instance with the specified options.
  ///
  /// Returns a new encoder configured with the given options. The original
  /// encoder instance remains unchanged.
  RdfBinaryEncoder<G> withOptions(RdfBinaryEncoderOptions options);
}
