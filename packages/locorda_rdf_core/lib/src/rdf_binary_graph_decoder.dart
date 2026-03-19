/// RDF Binary Graph Decoder
///
/// Defines the interface for decoding RDF graph data from binary formats.
library;

import 'dart:typed_data';

import 'package:locorda_rdf_core/src/graph/rdf_graph.dart';
import 'package:locorda_rdf_core/src/rdf_binary_decoder.dart';

/// Base class for decoding binary RDF documents into RDF graphs.
///
/// This abstract class specializes [RdfBinaryDecoder] for the [RdfGraph] type.
/// Binary graph format decoders (such as Jelly for triple streams) should
/// extend this class.
abstract class RdfBinaryGraphDecoder extends RdfBinaryDecoder<RdfGraph> {
  const RdfBinaryGraphDecoder();

  @override
  RdfGraph convert(Uint8List input);

  @override
  RdfBinaryGraphDecoder withOptions(RdfBinaryDecoderOptions options);
}
