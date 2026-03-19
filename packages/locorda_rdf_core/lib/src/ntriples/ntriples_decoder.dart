/// N-Triples parser - Implementation of the RdfParser interface for N-Triples format
///
/// This file provides the parser implementation for the N-Triples format,
/// which is a line-based serialization of RDF.
library ntriples_parser;

import 'dart:async';

import 'package:locorda_rdf_core/core.dart';

/// Options for configuring the N-Triples decoder behavior.
///
/// N-Triples has a straightforward format with minimal configuration options
/// compared to more complex RDF serialization formats. This class provides a
/// placeholder for future extension points if needed.
///
/// The current implementation uses default parsing behavior as defined by
/// the N-Triples specification, without additional configuration options.
class NTriplesDecoderOptions extends RdfGraphDecoderOptions {
  /// Creates a new instance of NTriplesDecoderOptions with default settings.
  ///
  /// Since N-Triples is a simple format, there are currently no configurable options.
  const NTriplesDecoderOptions();

  /// Creates an instance of NTriplesDecoderOptions from generic decoder options.
  ///
  /// This factory method ensures that when generic [RdfGraphDecoderOptions] are provided
  /// to a method expecting N-Triples-specific options, they are properly converted.
  ///
  /// The [options] parameter contains the generic decoder options to convert.
  /// Returns an instance of NTriplesDecoderOptions.
  static NTriplesDecoderOptions from(RdfGraphDecoderOptions options) =>
      switch (options) {
        NTriplesDecoderOptions _ => options,
        _ => NTriplesDecoderOptions(),
      };
}

/// Decoder for the N-Triples format.
///
/// N-Triples is a line-based, plain text serialization for RDF data.
/// Each line contains exactly one triple and ends with a period.
/// This decoder implements the N-Triples format as specified in the
/// [RDF 1.1 N-Triples specification](https://www.w3.org/TR/n-triples/).
///
/// The parser processes the input line by line, ignoring comment lines
/// (starting with '#') and empty lines, and parses each remaining line
/// as a separate triple.
///
/// This decoder is the list-level API and owns chunk-to-chunk parser
/// continuity for stream processing.
final class NTriplesToTriplesDecoder extends RdfTriplesDecoder {
  final NQuadsToQuadsDecoder _decoder;

  NTriplesToTriplesDecoder({
    NTriplesDecoderOptions options = const NTriplesDecoderOptions(),
    IriTermFactory iriTermFactory = IriTerm.validated,
  }) : _decoder = NQuadsToQuadsDecoder(
          options: NQuadsDecoderOptions.from(_toNQuadsOptions(options)),
          iriTermFactory: iriTermFactory,
        );

  NTriplesToTriplesDecoder._(NQuadsToQuadsDecoder decoder) : _decoder = decoder;

  static NQuadsDecoderOptions _toNQuadsOptions(
          NTriplesDecoderOptions options) =>
      NQuadsDecoderOptions();

  @override
  RdfTriplesDecoder withOptions(RdfGraphDecoderOptions options) =>
      NTriplesToTriplesDecoder._(
        _decoder.withOptions(options is NTriplesDecoderOptions
            ? _toNQuadsOptions(options)
            : options) as NQuadsToQuadsDecoder,
      );

  @override
  Iterable<Triple> convert(String input, {String? documentUrl}) {
    return decode(input, documentUrl: documentUrl).triples;
  }

  /// Decodes streamed N-Triples chunks while preserving blank-node identity
  /// across chunk boundaries at triple-list level.
  @override
  Stream<Iterable<Triple>> bind(Stream<String> stream) async* {
    final bnodeMap = <String, BlankNodeTerm>{};
    await for (final chunk in stream) {
      yield decode(chunk, bnodeMap: bnodeMap).triples;
    }
  }

  ({Iterable<Triple> triples, Map<BlankNodeTerm, String> blankNodeLabels})
      decode(
    String input, {
    String? documentUrl,
    Map<String, BlankNodeTerm>? bnodeMap,
  }) {
    final result = _decoder.decode(
      input,
      documentUrl: documentUrl,
      bnodeMap: bnodeMap,
    );

    return (
      triples: result.quads.map((q) => q.triple),
      blankNodeLabels: result.blankNodeLabels,
    );
  }
}

/// Decoder for the N-Triples format yielding [RdfGraph] value objects.
///
/// For list-level streaming semantics use [NTriplesToTriplesDecoder].
///
/// This wrapper intentionally focuses on value-object materialization and does
/// not define additional stream continuity semantics beyond its delegate.
final class NTriplesDecoder extends RdfGraphDecoder {
  final NTriplesToTriplesDecoder _decoder;

  /// Creates a new N-Triples parser
  NTriplesDecoder({
    NTriplesDecoderOptions options = const NTriplesDecoderOptions(),
    IriTermFactory iriTermFactory = IriTerm.validated,
  }) : _decoder = NTriplesToTriplesDecoder(
          options: options,
          iriTermFactory: iriTermFactory,
        );

  NTriplesDecoder._(NTriplesToTriplesDecoder decoder) : _decoder = decoder;

  @override
  RdfGraphDecoder withOptions(RdfGraphDecoderOptions options) =>
      NTriplesDecoder._(
          _decoder.withOptions(options) as NTriplesToTriplesDecoder);

  @override
  RdfGraph convert(String input, {String? documentUrl}) {
    final triples = _decoder.convert(input, documentUrl: documentUrl);
    return RdfGraph.fromTriples(triples);
  }
}
