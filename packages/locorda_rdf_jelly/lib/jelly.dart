/// Jelly RDF Binary Codec for locorda_rdf_core
///
/// This library provides encoding and decoding support for the Jelly RDF binary
/// serialization format. Jelly is a high-performance, streaming binary format
/// for RDF data based on Protocol Buffers, achieving significantly better
/// compression and throughput than text-based formats like Turtle or N-Triples.
///
/// Key features:
/// - Frame-level streaming via [JellyTripleFrameEncoder] / [JellyTripleFrameDecoder]
///   and the quad equivalents — idiomatic [StreamTransformerBase] composable with
///   `.bind()`, `.expand()` etc.
/// - Batch encode/decode via [RdfBinaryGraphCodec] / [RdfBinaryDatasetCodec]
/// - Lookup table compression for IRIs and datatypes
/// - Repeated-term compression for adjacent statements
/// - Multi-frame output respecting [JellyEncoderOptions.maxRowsPerFrame]
/// - Support for TRIPLES, QUADS, and GRAPHS physical stream types
///
/// ## Usage
///
/// ### Batch (non-streaming)
///
/// ```dart
/// import 'package:locorda_rdf_core/core.dart';
/// import 'package:locorda_rdf_jelly/jelly.dart';
///
/// // Use the global jelly codec directly
/// final graph = jellyGraph.decode(jellyBytes);
/// final bytes = jellyGraph.encode(graph);
///
/// // Or register with RdfCore
/// final rdfCore = RdfCore.withStandardCodecs(
///   additionalBinaryGraphCodecs: [JellyGraphCodec()],
///   additionalBinaryDatasetCodecs: [JellyDatasetCodec()],
/// );
/// ```
///
/// ### Frame-level streaming
///
/// ```dart
/// import 'package:locorda_rdf_jelly/jelly.dart';
///
/// // Encode a stream of frames (one List<Triple> per logical frame)
/// final encoded = JellyTripleFrameEncoder(options: opts).bind(frameStream);
/// await encoded.pipe(file.openWrite());
///
/// // Decode — one List<Triple> per physical frame
/// final frames = JellyTripleFrameDecoder().bind(byteStream);
/// // Flatten to individual triples
/// final triples = frames.expand((f) => f);
/// ```
///
/// ## Specification
///
/// This implementation follows the Jelly RDF serialization specification:
/// https://jelly-rdf.github.io/dev/specification/serialization/
library locorda_rdf_jelly;

export 'src/jelly_codec.dart'
    show
        JellyTripleFrameEncoder,
        JellyQuadFrameEncoder,
        JellyTripleFrameDecoder,
        JellyQuadFrameDecoder,
        JellyGraphDecoder,
        JellyDatasetDecoder,
        JellyGraphEncoder,
        JellyDatasetEncoder,
        JellyGraphCodec,
        JellyDatasetCodec,
        jellyMimeType,
        jellyGraph,
        jelly;
export 'src/jelly_options.dart' show JellyEncoderOptions, JellyDecoderOptions;
