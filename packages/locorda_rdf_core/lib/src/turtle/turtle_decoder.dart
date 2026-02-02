import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/trig/trig_codec.dart';

import 'turtle_tokenizer.dart';

const _format = "Turtle";

/// Configuration options for the Turtle decoder
///
/// This class provides configuration options for the Turtle decoder,
/// allowing customization of parsing behavior.
///
/// Parameters:
/// - [parsingFlags] A set of parsing flags that modify the parser's behavior,
///   such as allowing non-standard Turtle syntax extensions or being more
///   lenient with certain syntax requirements.
class TurtleDecoderOptions extends RdfGraphDecoderOptions {
  /// Flags that modify the parsing behavior
  final Set<TurtleParsingFlag> parsingFlags;

  /// Creates a new set of Turtle decoder options
  ///
  /// Parameters:
  /// - [parsingFlags] Optional set of parsing flags to customize parsing behavior.
  ///   By default, strict Turtle parsing is used with no special flags.
  const TurtleDecoderOptions({this.parsingFlags = const {}});

  /// Creates TurtleDecoderOptions from generic RdfGraphDecoderOptions
  ///
  /// This factory method enables proper type conversion when using the
  /// generic codec/decoder API with Turtle-specific options.
  ///
  /// Parameters:
  /// - [options] The options object to convert, which may or may not be
  ///   already a TurtleDecoderOptions instance.
  ///
  /// Returns:
  /// - The input as-is if it's already a TurtleDecoderOptions instance,
  ///   or a new instance with default settings otherwise.
  static TurtleDecoderOptions from(RdfGraphDecoderOptions options) =>
      switch (options) {
        TurtleDecoderOptions _ => options,
        _ => TurtleDecoderOptions(),
      };
}

TriGDecoderOptions toTriGDecoderOptions(TurtleDecoderOptions options) {
  return TriGDecoderOptions(
    parsingFlags: options.parsingFlags.map(toTriGParsingFlag).toSet(),
  );
}

/// Decoder for Turtle format RDF documents
///
/// This decoder implements the RdfGraphDecoder interface for parsing Turtle syntax
/// into RDF graphs. It acts as an adapter that bridges the RdfDecoder interface
/// to the implementation-specific TurtleParser.
///
/// The Turtle format (Terse RDF Triple Language) is a textual syntax for RDF that allows
/// writing down RDF graphs in a compact and natural text form. This decoder
/// handles standard Turtle syntax as specified in the W3C recommendation.
///
/// Example:
/// ```dart
/// final decoder = TurtleDecoder(namespaceMappings: defaultNamespaces);
/// final graph = decoder.convert('@prefix ex: <http://example.org/> . ex:subject ex:predicate "object" .');
/// ```
class TurtleDecoder extends RdfGraphDecoder {
  final TriGDecoder _decoder;
  final RdfNamespaceMappings _namespaceMappings;

  /// Creates a new Turtle decoder
  ///
  /// Parameters:
  /// - [options] Configuration options that control parsing behavior.
  ///   Default is standard Turtle parsing with no special settings.
  /// - [namespaceMappings] Required namespace mappings to use when expanding
  ///   prefixed names encountered during parsing.
  TurtleDecoder({
    TurtleDecoderOptions options = const TurtleDecoderOptions(),
    required RdfNamespaceMappings namespaceMappings,
    IriTermFactory iriTermFactory = IriTerm.validated,
  })  : _decoder = TriGDecoder(
          format: _format,
          options: toTriGDecoderOptions(options),
          namespaceMappings: namespaceMappings,
          iriTermFactory: iriTermFactory,
        ),
        _namespaceMappings = namespaceMappings;

  /// Decodes a Turtle document into an RDF graph
  ///
  /// This method parses a string containing Turtle syntax into an
  /// RDF graph structure. It delegates to the internal TurtleParser
  /// implementation to handle the actual parsing.
  ///
  /// Parameters:
  /// - [input] The Turtle document to decode as a string.
  /// - [documentUrl] Optional base URI for the document, used for resolving
  ///   relative IRIs in the Turtle content. If not provided, relative IRIs
  ///   will result in an error unless there's a @base directive in the content.
  ///
  /// Returns:
  /// - An [RdfGraph] containing the parsed triples.
  ///
  /// Throws:
  /// - [RdfSyntaxException] if the syntax is invalid or cannot be parsed.
  /// - [RdfInvalidIriException] if relative IRIs are used without a base URI.
  @override
  RdfGraph convert(String input, {String? documentUrl}) {
    final dataset = _decoder.convert(input, documentUrl: documentUrl);
    if (dataset.namedGraphs.isNotEmpty) {
      throw RdfSyntaxException(
        'Turtle documents cannot contain named graphs',
        format: _format,
      );
    }
    return dataset.defaultGraph;
  }

  /// Creates a new instance with the specified options
  ///
  /// This method returns a new Turtle decoder configured with the provided
  /// options. The original decoder instance remains unchanged.
  ///
  /// Parameters:
  /// - [options] Decoder options to customize decoding behavior.
  ///   Will be properly cast to TurtleDecoderOptions if possible, else we will use the default options instead.
  ///
  /// Returns:
  /// - A new [TurtleDecoder] instance with the specified options applied,
  ///   while preserving the original namespace mappings.
  @override
  RdfGraphDecoder withOptions(RdfGraphDecoderOptions options) => TurtleDecoder(
        options: TurtleDecoderOptions.from(options),
        namespaceMappings: _namespaceMappings,
      );
}
