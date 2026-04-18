/// Jelly RDF Streaming Example
///
/// Demonstrates the frame-level streaming API using [JellyTripleFrameEncoder]
/// and [JellyTripleFrameDecoder]. In streaming mode, lookup tables accumulate
/// across frames for better compression than independent per-frame encoding.
///
/// This example encodes two batches of triples (simulating incremental data
/// arrival), writes the frames to a byte buffer, then decodes them back.
library;

import 'dart:typed_data';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';
import 'package:locorda_rdf_terms_common/foaf.dart';

void main() async {
  print('Jelly RDF Streaming Example');
  print('===========================\n');

  final ex = 'http://example.org/';

  // Two batches of triples, as if arriving from a stream
  final batch1 = [
    Triple(IriTerm('${ex}alice'), Foaf.name, LiteralTerm.string('Alice')),
    Triple(IriTerm('${ex}alice'), Foaf.knows, IriTerm('${ex}bob')),
  ];
  final batch2 = [
    Triple(IriTerm('${ex}bob'), Foaf.name, LiteralTerm.string('Bob')),
    Triple(IriTerm('${ex}bob'), Foaf.knows, IriTerm('${ex}charlie')),
  ];

  // --- Encode via streaming ---
  // JellyTripleFrameEncoder.bind() shares lookup-table state across batches,
  // so repeated IRIs (e.g. foaf:name, foaf:knows) are only emitted once.
  final encoder = JellyTripleFrameEncoder(
    options: const JellyEncoderOptions(maxRowsPerFrame: 256),
  );

  final encodedFrames = <Uint8List>[];
  await for (final frame
      in encoder.bind(Stream.fromIterable([batch1, batch2]))) {
    encodedFrames.add(frame);
    print('Encoded frame: ${frame.length} bytes');
  }

  // Combine all frames into a single byte buffer (as if read from a file)
  final totalBytes = encodedFrames.fold<int>(0, (sum, f) => sum + f.length);
  final combined = Uint8List(totalBytes);
  var offset = 0;
  for (final frame in encodedFrames) {
    combined.setRange(offset, offset + frame.length, frame);
    offset += frame.length;
  }
  print('\nTotal encoded: $totalBytes bytes for '
      '${batch1.length + batch2.length} triples');

  // --- Decode via streaming ---
  final decoder = const JellyTripleFrameDecoder();
  final allTriples = <Triple>[];
  await for (final triples in decoder.bind(Stream.value(combined))) {
    allTriples.addAll(triples);
  }

  print('\nDecoded ${allTriples.length} triples:');
  for (final t in allTriples) {
    print('  $t');
  }
}
