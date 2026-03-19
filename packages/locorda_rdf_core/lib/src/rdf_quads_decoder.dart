/// RDF Quads Decoder Interface
///
/// Defines the interface for decoding RDF data into an iterable of quads,
/// preserving the original order of statements in the serialization.
library;

import 'package:locorda_rdf_core/src/dataset/quad.dart';
import 'package:locorda_rdf_core/src/rdf_decoder.dart';

/// Base class for decoding RDF documents into a sequence of Quads
///
/// This abstract class extends the standard `Converter` interface to provide
/// a common API for decoding different RDF string serializations (like N-Quads)
/// into an `Iterable<Quad>`. Unlike `RdfDatasetDecoder`, this decoder preserves
/// the exact order of the quads as they appear in the source document, rather
/// than grouping them into a mathematical dataset graph structure.
///
/// Implementations may provide a stateful [bind] to preserve parser continuity
/// across streamed chunks (for example blank-node label continuity). Callers
/// that require these semantics should rely on concrete decoder guarantees.
abstract class RdfQuadsDecoder extends RdfDecoder<Iterable<Quad>> {
  const RdfQuadsDecoder();

  @override
  Iterable<Quad> convert(String input, {String? documentUrl});

  RdfQuadsDecoder withOptions(RdfGraphDecoderOptions options);
}
