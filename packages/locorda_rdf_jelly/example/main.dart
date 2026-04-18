/// Jelly RDF Batch Encode/Decode Example
///
/// Demonstrates the batch API for encoding an [RdfGraph] to Jelly binary
/// format and decoding it back, using the global [jellyGraph] codec.
///
/// The Jelly format uses Protocol Buffers wire format with IRI lookup-table
/// compression, achieving significantly smaller output than text-based RDF
/// formats like Turtle or N-Triples.
library;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';

void main() {
  print('Jelly RDF Batch Encode/Decode Example');
  print('=====================================\n');

  final ex = 'http://example.org/';
  final foaf = 'http://xmlns.com/foaf/0.1/';

  // Build a small RDF graph
  final graph = RdfGraph(triples: [
    Triple(
      IriTerm('${ex}alice'),
      IriTerm('${foaf}name'),
      LiteralTerm.string('Alice'),
    ),
    Triple(
      IriTerm('${ex}alice'),
      IriTerm('${foaf}knows'),
      IriTerm('${ex}bob'),
    ),
    Triple(
      IriTerm('${ex}bob'),
      IriTerm('${foaf}name'),
      LiteralTerm.string('Bob'),
    ),
  ]);

  print('Original graph: ${graph.triples.length} triples');
  for (final t in graph.triples) {
    print('  $t');
  }

  // Encode to Jelly binary format
  final bytes = jellyGraph.encode(graph);
  print('\nEncoded to ${bytes.length} bytes (Jelly binary)');

  // Decode back to an RdfGraph
  final decoded = jellyGraph.decode(bytes);
  print('Decoded graph: ${decoded.triples.length} triples');
  for (final t in decoded.triples) {
    print('  $t');
  }

  // Verify roundtrip
  final originalSet = graph.triples.toSet();
  final decodedSet = decoded.triples.toSet();
  print(
      '\nRoundtrip OK: ${originalSet.length == decodedSet.length && originalSet.containsAll(decodedSet)}');
}
