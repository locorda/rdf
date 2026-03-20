/// Regression tests for specific bugs in the Jelly codec.
library;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jelly/jelly.dart';
import 'package:test/test.dart';

void main() {
  group('JellyFrameWriter multi-frame regression', () {
    // Regression: BytesBuilder.toBytes() was used instead of takeBytes(),
    // causing frame bytes to accumulate. For streams requiring >1 frame
    // (>256 rows), the second frame contained a copy of frame 0's bytes,
    // making the decoder see duplicate frames. The duplicated options rows
    // caused subsequent name-table delta IDs to be resolved against the
    // *end* of frame 0's state rather than 0, producing IDs >maxSize.
    test(
        'encodes/decodes graph with >256 rows (>128 unique name-table entries)',
        () {
      // 85 triples × (subj + obj) + pred = 171 unique local names.
      // With maxNameTableSize=128 the encoder needs multi-frame output;
      // the bug caused frame duplication across the 256-row frame boundary.
      final triples = <Triple>[];
      for (var i = 0; i < 85; i++) {
        triples.add(Triple(
          IriTerm('https://example.org/subj$i'),
          IriTerm('https://example.org/pred'),
          IriTerm('https://example.org/obj$i'),
        ));
      }
      final graph = RdfGraph.fromTriples(triples);
      final encoded = jellyGraph.encode(graph);
      final decoded = jellyGraph.decode(encoded);
      expect(decoded.size, equals(graph.size));
    });

    test('round-trips a graph with 300 unique local names', () {
      final triples = <Triple>[];
      for (var i = 0; i < 150; i++) {
        triples.add(Triple(
          IriTerm('https://example.org/s$i'),
          IriTerm('https://example.org/p'),
          IriTerm('https://example.org/o$i'),
        ));
      }
      final graph = RdfGraph.fromTriples(triples);
      final decoded = jellyGraph.decode(jellyGraph.encode(graph));
      expect(decoded.size, equals(graph.size));
    });
  });

  group('JellyDatasetCodec physicalType regression', () {
    // Regression: JellyDatasetEncoder defaulted to PHYSICAL_STREAM_TYPE_TRIPLES
    // but emitted quad rows, causing a mismatch that the decoder rejected with
    // "quad row not allowed in PHYSICAL_STREAM_TYPE_TRIPLES stream".
    test('encodes/decodes a default-graph-only dataset', () {
      final graph = RdfGraph.fromTriples([
        Triple(
          IriTerm('https://example.org/s'),
          IriTerm('https://example.org/p'),
          IriTerm('https://example.org/o'),
        ),
      ]);
      final dataset = RdfDataset.fromDefaultGraph(graph);
      final encoded = jelly.encode(dataset);
      final decoded = jelly.decode(encoded);
      expect(decoded.quads.length, equals(1));
    });

    test('encodes/decodes a multi-named-graph dataset', () {
      final g1 = RdfGraph.fromTriples([
        Triple(
          IriTerm('https://example.org/s1'),
          IriTerm('https://example.org/p'),
          IriTerm('https://example.org/o1'),
        ),
      ]);
      final g2 = RdfGraph.fromTriples([
        Triple(
          IriTerm('https://example.org/s2'),
          IriTerm('https://example.org/p'),
          IriTerm('https://example.org/o2'),
        ),
      ]);
      final dataset = RdfDataset(
        defaultGraph: RdfGraph(),
        namedGraphs: {
          IriTerm('https://example.org/g1'): g1,
          IriTerm('https://example.org/g2'): g2,
        },
      );
      final encoded = jelly.encode(dataset);
      final decoded = jelly.decode(encoded);
      expect(decoded.quads.length, equals(2));
    });
  });
}
