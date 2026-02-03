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
import 'package:logging/logging.dart';

const _format = "JSON-LD (graph)";

final _logger = Logger('rdf.jsonld.graph');

/// Defines how to handle named graphs when decoding JSON-LD to RdfGraph
///
/// Since [RdfGraph] does not support named graphs (only [RdfDataset] does),
/// this enum controls what happens when the JSON-LD document contains named graphs.
enum NamedGraphHandling {
  /// Throw an exception if any named graphs are encountered
  ///
  /// This is the safest default mode as it prevents silent data loss or
  /// misinterpretation. Use this when you need to ensure you're only working
  /// with simple graphs without named graph structures.
  ///
  /// Example:
  /// ```dart
  /// final decoder = JsonLdGraphDecoder(
  ///   options: JsonLdGraphDecoderOptions(
  ///     namedGraphHandling: NamedGraphHandling.strict,
  ///   ),
  /// );
  /// // Will throw RdfDecoderException if named graphs are present
  /// ```
  strict,

  /// Ignore named graphs and only return the default graph
  ///
  /// When named graphs are present, they are silently ignored and only
  /// triples from the default graph are returned. This is useful when you
  /// know the document might contain named graphs but you only care about
  /// the default graph content.
  ///
  /// By default, this logs at `fine` (debug) level when named graphs are ignored.
  ///
  /// Example:
  /// ```dart
  /// final decoder = JsonLdGraphDecoder(
  ///   options: JsonLdGraphDecoderOptions(
  ///     namedGraphHandling: NamedGraphHandling.ignoreNamedGraphs,
  ///   ),
  /// );
  /// // Named graphs will be silently ignored
  /// ```
  ignoreNamedGraphs,

  /// Merge all triples from named graphs into the default graph
  ///
  /// All triples from all named graphs are merged into the default graph,
  /// losing the graph name information but preserving all triple data.
  /// This is semantically valid in RDF - you're just losing the graph
  /// boundary context.
  ///
  /// By default, this logs at `warning` level as it represents a significant
  /// semantic change (loss of graph boundaries).
  ///
  /// Example:
  /// ```dart
  /// final decoder = JsonLdGraphDecoder(
  ///   options: JsonLdGraphDecoderOptions(
  ///     namedGraphHandling: NamedGraphHandling.mergeIntoDefault,
  ///   ),
  /// );
  /// // All triples from all graphs will be merged together
  /// ```
  mergeIntoDefault,
}

/// Controls the logging level when named graphs are handled
///
/// This enum allows fine-grained control over how verbose the decoder should be
/// when processing named graphs according to the [NamedGraphHandling] mode.
enum NamedGraphLogLevel {
  /// No logging output
  ///
  /// Use this when you're intentionally handling named graphs in a specific way
  /// and don't want any log noise in production.
  silent,

  /// Log at fine/debug level
  ///
  /// Suitable for development and debugging. These messages typically won't
  /// appear in production logs unless debug logging is explicitly enabled.
  fine,

  /// Log at info level
  ///
  /// Use this when you want to be notified about named graph handling in
  /// normal operation, but it's not a concern.
  info,

  /// Log at warning level
  ///
  /// Use this when named graph handling represents a potential issue or
  /// semantic change that should be visible in production logs.
  warning,
}

/// Configuration options for JSON-LD graph decoding
///
/// This class provides configuration options for customizing the behavior of the
/// JSON-LD graph decoder, particularly around handling named graphs.
///
/// Since [JsonLdGraphDecoder] produces an [RdfGraph] (which doesn't support named graphs)
/// from JSON-LD input (which may contain named graphs), this class allows you to
/// configure how that mismatch is handled.
///
/// Example:
/// ```dart
/// // Strict mode - throw exception on named graphs
/// final strictDecoder = JsonLdGraphDecoder(
///   options: JsonLdGraphDecoderOptions(
///     namedGraphHandling: NamedGraphHandling.strict,
///   ),
/// );
///
/// // Merge mode with custom logging
/// final mergeDecoder = JsonLdGraphDecoder(
///   options: JsonLdGraphDecoderOptions(
///     namedGraphHandling: NamedGraphHandling.mergeIntoDefault,
///     logLevel: NamedGraphLogLevel.info,
///   ),
/// );
/// ```
class JsonLdGraphDecoderOptions extends RdfGraphDecoderOptions {
  /// How to handle named graphs when decoding to RdfGraph
  ///
  /// Defaults to [NamedGraphHandling.strict] to prevent silent data loss.
  final NamedGraphHandling namedGraphHandling;

  /// The log level to use when handling named graphs
  ///
  /// If `null`, uses sensible defaults based on [namedGraphHandling]:
  /// - [NamedGraphHandling.strict]: No logging (throws exception anyway)
  /// - [NamedGraphHandling.ignoreNamedGraphs]: [NamedGraphLogLevel.fine] (debug)
  /// - [NamedGraphHandling.mergeIntoDefault]: [NamedGraphLogLevel.warning]
  final NamedGraphLogLevel? logLevel;

  /// Creates a new JSON-LD decoder options object
  ///
  /// [namedGraphHandling] controls what happens when named graphs are encountered.
  /// Defaults to [NamedGraphHandling.strict].
  ///
  /// [logLevel] controls logging verbosity. If `null`, uses sensible defaults
  /// based on the handling mode.
  const JsonLdGraphDecoderOptions({
    this.namedGraphHandling = NamedGraphHandling.strict,
    this.logLevel,
  });

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
        _ => const JsonLdGraphDecoderOptions(),
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
/// 4. Handling named graphs according to the configured mode
///
/// The decoder creates an RDF Graph from the JSON-LD input. How named graphs
/// are handled depends on the [JsonLdGraphDecoderOptions.namedGraphHandling] setting:
///
/// - [NamedGraphHandling.strict]: Throws an exception if named graphs are present
/// - [NamedGraphHandling.ignoreNamedGraphs]: Returns only the default graph
/// - [NamedGraphHandling.mergeIntoDefault]: Merges all graphs into one
///
/// Example usage:
/// ```dart
/// // Strict mode (default)
/// final decoder = JsonLdGraphDecoder();
/// final graph = decoder.convert(jsonLdString); // throws if named graphs present
///
/// // Merge mode
/// final mergeDecoder = JsonLdGraphDecoder(
///   options: JsonLdGraphDecoderOptions(
///     namedGraphHandling: NamedGraphHandling.mergeIntoDefault,
///   ),
/// );
/// final mergedGraph = mergeDecoder.convert(jsonLdString);
/// ```
class JsonLdGraphDecoder extends RdfGraphDecoder {
  final JsonLdDecoder _decoder;
  final JsonLdGraphDecoderOptions _options;
  final IriTermFactory _iriTermFactory;

  JsonLdGraphDecoder({
    JsonLdGraphDecoderOptions options = const JsonLdGraphDecoderOptions(),
    IriTermFactory iriTermFactory = IriTerm.validated,
  })  : _decoder = JsonLdDecoder(
          options: toJsonLdDecoderOptions(options),
          iriTermFactory: iriTermFactory,
          format: _format,
        ),
        _options = options,
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

    // If no named graphs, just return the default graph
    if (dataset.namedGraphs.isEmpty) {
      return dataset.defaultGraph;
    }

    // Handle named graphs according to the configured mode
    switch (_options.namedGraphHandling) {
      case NamedGraphHandling.strict:
        throw RdfDecoderException(
          "JSON-LD document contains ${dataset.namedGraphs.length} named graph(s), "
          "but JsonLdGraphDecoder only supports documents with a single default graph. "
          "Use JsonLdDecoder for full dataset support, or configure namedGraphHandling "
          "to ignoreNamedGraphs or mergeIntoDefault.",
          format: _format,
        );

      case NamedGraphHandling.ignoreNamedGraphs:
        _logNamedGraphHandling(
          NamedGraphLogLevel.fine,
          "Ignoring ${dataset.namedGraphs.length} named graph(s) and returning only the default graph "
          "with ${dataset.defaultGraph.triples.length} triple(s)",
        );
        return dataset.defaultGraph;

      case NamedGraphHandling.mergeIntoDefault:
        _logNamedGraphHandling(
          NamedGraphLogLevel.warning,
          "Merging ${dataset.namedGraphs.length} named graph(s) into the default graph. "
          "Graph name information will be lost.",
        );

        // Merge all triples from named graphs into the default graph
        final allTriples = <Triple>[
          ...dataset.defaultGraph.triples,
          for (final namedGraph in dataset.namedGraphs)
            ...namedGraph.graph.triples,
        ];

        return RdfGraph(triples: allTriples);
    }
  }

  /// Logs a message about named graph handling at the appropriate level
  void _logNamedGraphHandling(NamedGraphLogLevel defaultLevel, String message) {
    // Use custom log level if specified, otherwise use the default for this mode
    final effectiveLevel = _options.logLevel ?? defaultLevel;

    switch (effectiveLevel) {
      case NamedGraphLogLevel.silent:
        // No logging
        break;
      case NamedGraphLogLevel.fine:
        _logger.fine(message);
        break;
      case NamedGraphLogLevel.info:
        _logger.info(message);
        break;
      case NamedGraphLogLevel.warning:
        _logger.warning(message);
        break;
    }
  }
}
