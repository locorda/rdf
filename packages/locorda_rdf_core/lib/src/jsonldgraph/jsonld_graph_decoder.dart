/// JSON-LD Parser Implementation
///
/// This library provides the implementation for parsing JSON-LD (JavaScript Object Notation
/// for Linked Data) into RDF graphs. It includes a complete JSON-LD parser that handles
/// the core features of the JSON-LD 1.1 specification.
///
/// The implementation provides:
/// - Parsing of JSON-LD documents into RDF triples
/// - Support for JSON-LD context resolution and compact IRIs
/// - Handling of nested objects and arrays
/// - Blank node normalization and consistent identity
/// - Processing of typed literals and language-tagged strings
/// - Support for @graph structures (without preserving graph names)
///
/// This library is part of the RDF Core package and uses the common RDF data model
/// defined in the graph module.
///
/// See:
/// - [JSON-LD 1.1 Specification](https://www.w3.org/TR/json-ld11/)
/// - [JSON-LD 1.1 Processing Algorithms and API](https://www.w3.org/TR/json-ld11-api/)
library jsonld_graph_parser;

import 'package:locorda_rdf_core/core.dart';

const _format = "JSON-LD (graph)";

/// Configuration options for JSON-LD decoding
///
/// This class provides configuration options for customizing the behavior of the
/// JSON-LD decoder. While the current implementation doesn't define specific options,
/// this class serves as an extension point for future enhancements to the JSON-LD parser.
///
/// Potential future options might include:
/// - Controlling how JSON-LD @graph structures are processed
/// - Customizing blank node generation behavior
/// - Specifying custom datatype handling
///
/// This class follows the pattern used throughout the RDF Core library
/// where decoders accept options objects to configure their behavior.
class JsonLdGraphDecoderOptions extends RdfGraphDecoderOptions {
  /// Creates a new JSON-LD decoder options object with default settings
  const JsonLdGraphDecoderOptions();

  /// Creates a JSON-LD decoder options object from generic RDF decoder options
  ///
  /// This factory method ensures that when generic [RdfGraphDecoderOptions] are provided
  /// to a method expecting JSON-LD-specific options, they are properly converted.
  ///
  /// If the provided options are already a [JsonLdGraphDecoderOptions] instance, they are
  /// returned as-is. Otherwise, a new instance with default settings is created.
  static JsonLdGraphDecoderOptions from(RdfGraphDecoderOptions options) =>
      switch (options) {
        JsonLdGraphDecoderOptions _ => options,
        _ => JsonLdGraphDecoderOptions(),
      };
}

/// Converts [JsonLdGraphDecoderOptions] to [JsonLdDecoderOptions].
///
/// This helper function enables converting graph-level JSON-LD decoding options
/// to dataset-level options, similar to how `toTriGDecoderOptions` converts
/// Turtle options to TriG options.
///
/// Example:
/// ```dart
/// final graphOptions = JsonLdGraphDecoderOptions();
/// final datasetOptions = toJsonLdDecoderOptions(graphOptions);
/// ```
JsonLdDecoderOptions toJsonLdDecoderOptions(JsonLdGraphDecoderOptions options) {
  return JsonLdDecoderOptions();
}

/// Decoder for JSON-LD format
///
/// Adapter that bridges the RdfDecoder base class to the
/// implementation-specific JsonLdParser. This class is responsible for:
///
/// 1. Adapting the RDF Core decoder interface to the JSON-LD parser
/// 2. Converting parsed triples into an RdfGraph
/// 3. Managing configuration options for the parsing process
///
/// The decoder creates a flat RDF Graph from the JSON-LD input. When the
/// input contains a top-level `@graph` property (representing a named graph
/// in JSON-LD), all triples from the graph are extracted into the same RDF Graph,
/// losing the graph name information but preserving the triple data.
///
/// Example usage:
/// ```dart
/// final decoder = JsonLdDecoder();
/// final graph = decoder.convert(jsonLdString);
/// ```
class JsonLdGraphDecoder extends RdfGraphDecoder {
  // Decoders are always expected to have options, even if they are not used at
  // the moment. But maybe the JsonLdDecoder will have options in the future.
  //
  // ignore: unused_field
  final JsonLdDecoder _decoder;
  final IriTermFactory _iriTermFactory;

  JsonLdGraphDecoder({
    JsonLdGraphDecoderOptions options = const JsonLdGraphDecoderOptions(),
    IriTermFactory iriTermFactory = IriTerm.validated,
  })  : _decoder = JsonLdDecoder(
          options: toJsonLdDecoderOptions(options),
          iriTermFactory: iriTermFactory,
          format: _format,
        ),
        _iriTermFactory = iriTermFactory;

  @override
  RdfGraphDecoder withOptions(RdfGraphDecoderOptions options) {
    return JsonLdGraphDecoder(
        options: JsonLdGraphDecoderOptions.from(options),
        iriTermFactory: _iriTermFactory);
  }

  @override
  RdfGraph convert(String input, {String? documentUrl}) {
    final dataset = _decoder.convert(input, documentUrl: documentUrl);
    if (dataset.namedGraphs.isNotEmpty) {
      throw RdfDecoderException(
          "JSON-LD graph decoder does not support named graphs",
          format: _format);
    }
    return dataset.defaultGraph;
  }
}
