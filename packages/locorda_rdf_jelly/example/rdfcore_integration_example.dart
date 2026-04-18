/// Jelly RDF — RdfCore Integration Example
///
/// Demonstrates how to register [JellyGraphCodec] and [JellyDatasetCodec]
/// with [RdfCore] so that Jelly can be used via the codec-agnostic facade.
///
/// With Jelly registered, you can use [RdfCore.encodeBinary] /
/// [RdfCore.decodeBinary] with `contentType: jellyMimeType` — or let RdfCore
/// auto-detect the format from the binary content.
library;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';

void main() {
  print('Jelly RDF — RdfCore Integration Example');
  print('=======================================\n');

  // Register Jelly alongside the standard text codecs (Turtle, N-Triples, …)
  final rdfCore = RdfCore.withStandardCodecs(
    additionalBinaryGraphCodecs: [jellyGraph],
    additionalBinaryDatasetCodecs: [jelly],
  );

  final ex = 'http://example.org/';
  final foaf = 'http://xmlns.com/foaf/0.1/';

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

  // --- Encode via content type ---
  final jellyBytes = rdfCore.encodeBinary(
    graph,
    contentType: jellyMimeType,
  );
  print('Encoded ${graph.triples.length} triples to '
      '${jellyBytes.length} bytes via RdfCore (content type: $jellyMimeType)');

  // --- Decode via content type ---
  final decoded = rdfCore.decodeBinary(
    jellyBytes,
    contentType: jellyMimeType,
  );
  print('Decoded ${decoded.triples.length} triples via RdfCore');

  // --- Auto-detection (no content type) ---
  // RdfCore probes registered binary codecs and picks the first one that
  // recognises the bytes — no explicit content type needed.
  final autoDecoded = rdfCore.decodeBinary(jellyBytes);
  print('Auto-detected and decoded ${autoDecoded.triples.length} triples');

  // --- Compare with text format ---
  final turtle = rdfCore.encode(graph, contentType: 'text/turtle');
  print('\nSame graph as Turtle (${turtle.length} chars):');
  print(turtle);

  print('Jelly binary: ${jellyBytes.length} bytes — '
      '${(100 * jellyBytes.length / turtle.length).toStringAsFixed(0)}% '
      'of Turtle text size');
}
