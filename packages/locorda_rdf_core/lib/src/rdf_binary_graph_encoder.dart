/// RDF Binary Graph Encoder
///
/// Defines the interface for encoding RDF graphs to binary formats.
library;

import 'dart:typed_data';

import 'package:locorda_rdf_core/src/graph/rdf_graph.dart';
import 'package:locorda_rdf_core/src/rdf_binary_encoder.dart';

/// Base class for encoding RDF graphs to binary serialization formats.
///
/// This abstract class specializes [RdfBinaryEncoder] for the [RdfGraph] type.
/// Binary graph format encoders (such as Jelly for triple streams) should
/// extend this class.
abstract class RdfBinaryGraphEncoder extends RdfBinaryEncoder<RdfGraph> {
  const RdfBinaryGraphEncoder();

  @override
  Uint8List convert(RdfGraph graph);

  @override
  RdfBinaryGraphEncoder withOptions(RdfBinaryEncoderOptions options);
}
