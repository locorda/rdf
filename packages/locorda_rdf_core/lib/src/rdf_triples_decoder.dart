/// RDF Triples Decoder Interface
///
/// Defines the interface for decoding RDF data into an iterable of triples,
/// preserving source order.
library;

import 'package:locorda_rdf_core/src/graph/triple.dart';
import 'package:locorda_rdf_core/src/rdf_decoder.dart';

/// Base class for decoding RDF documents into a sequence of triples.
///
/// This is the triple-level sibling of [RdfQuadsDecoder]. It is useful when
/// callers need row/batch-level control instead of materializing full graph
/// objects.
///
/// Implementations may provide a stateful [bind] to preserve parser continuity
/// across streamed chunks (for example blank-node label continuity). Callers
/// that require these semantics should rely on concrete decoder guarantees.
abstract class RdfTriplesDecoder extends RdfDecoder<Iterable<Triple>> {
  const RdfTriplesDecoder();

  @override
  Iterable<Triple> convert(String input, {String? documentUrl});

  RdfTriplesDecoder withOptions(RdfGraphDecoderOptions options);
}
