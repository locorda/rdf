/// JSON-LD Serializer Implementation
///
/// Implements the [JsonLdGraphEncoder] class to convert RDF graphs to JSON-LD format.
/// JSON-LD (JavaScript Object Notation for Linked Data) allows the representation
/// of RDF data in a human-readable and machine-processable format,
/// based on the widely used JSON standard.
///
/// This implementation supports:
/// - Compact JSON-LD documents with meaningful prefixes
/// - Automatic detection and generation of appropriate `@context` definitions
/// - Grouping of data by subjects for better readability
/// - Special handling of Blank Nodes with consistent identifiers
/// - Generation of `@graph` for graphs with multiple subjects
/// - Conversion of typed literals to appropriate JSON representations
///
/// ## Graph Structure Detection
///
/// The encoder automatically analyzes the structure of the input graph:
/// - For single-subject graphs, it creates a simple JSON-LD object
/// - For multi-subject graphs, it uses a top-level `@graph` array
///
/// The current implementation does not maintain named graph information
/// when serializing RDF graphs. The use of `@graph` in the output is purely
/// for structural organization, not for representing true RDF Dataset named graphs.
///
/// ## Example usage:
/// ```dart
/// import 'package:locorda_rdf_core/core.dart';
///
/// // Using the global encoder
/// final jsonld = jsonldGraph.encode(graph);
///
/// // Or directly with the encoder
/// final encoder = JsonLdEncoder();
/// final jsonld = encoder.convert(graph);
/// ```
///
/// See also:
/// - [JSON-LD 1.1 Specification](https://www.w3.org/TR/json-ld11/)
/// - [JSON-LD Website](https://json-ld.org/)
library jsonld_graph_serializer;

import 'package:locorda_rdf_core/core.dart';

/// Configuration options for JSON-LD encoding
///
/// This class provides configuration options for customizing the behavior of the
/// JSON-LD encoder. It extends the base RDF encoder options to add JSON-LD specific
/// functionality.
///
/// Currently, the main customization is the ability to provide custom prefixes
/// for the JSON-LD context, allowing for more readable and application-specific
/// compact IRIs in the output.
///
/// Potential future options might include:
/// - Control over formatting (compact vs. expanded form)
/// - Custom handling of complex datatypes
/// - Options for including/excluding @context
/// - Named graph serialization settings
///
/// Example usage:
/// ```dart
/// final options = JsonLdEncoderOptions(
///   customPrefixes: {
///     'ex': 'http://example.org/',
///     'app': 'http://myapp.com/terms#'
///   }
/// );
///
/// final encoder = JsonLdEncoder(options: options);
/// ```
class JsonLdGraphEncoderOptions extends RdfGraphEncoderOptions {
  /// Controls automatic generation of namespace prefixes for IRIs without matching prefixes.
  ///
  /// When set to `true` (default), the encoder will automatically generate namespace
  /// prefixes for IRIs that don't have a matching prefix in either the custom prefixes
  /// or the standard namespace mappings.
  ///
  /// The prefix generation process:
  /// 1. Attempts to extract a meaningful namespace from the IRI (splitting at '/' or '#')
  /// 2. Skips IRIs with only protocol specifiers (e.g., "http://")
  /// 3. Only generates prefixes for namespaces ending with '/' or '#'
  ///    (proper RDF namespace delimiters)
  /// 4. Uses RdfNamespaceMappings.getOrGeneratePrefix to create a compact, unique prefix
  ///
  /// Setting this to `false` will result in all IRIs without matching prefixes being
  /// written as full IRIs in the JSON-LD output.
  ///
  /// This option is particularly useful for:
  /// - Reducing the verbosity of the JSON-LD output
  /// - Making the serialized data more human-readable
  /// - Automatically handling unknown namespaces without manual prefix declaration
  final bool generateMissingPrefixes;

  /// Whether to include base URI declarations in the output
  ///
  /// This option only applies when a baseUri is provided during encoding.
  /// When true and a baseUri is provided, the serializer includes the base URI
  /// declaration in the format-specific way (e.g., @base in Turtle, @base in JSON-LD context).
  /// When false, the baseUri is still used for URI relativization but not declared in the output.
  /// Has no effect if no baseUri is provided during encoding.
  final bool includeBaseDeclaration;

  /// Creates a new JSON-LD encoder options object
  ///
  /// [customPrefixes] A map of prefix to namespace URI pairs that will be used
  /// in the JSON-LD @context. These prefixes take precedence over standard prefixes
  /// if there are conflicts.
  /// [generateMissingPrefixes] When true (default), the encoder will automatically
  /// generate prefix declarations for IRIs that don't have a matching prefix.
  /// [includeBaseDeclaration] Whether to include base URI declarations in the output.
  /// Defaults to true if not provided.
  const JsonLdGraphEncoderOptions({
    super.customPrefixes = const {},
    super.iriRelativization = const IriRelativizationOptions.full(),
    bool generateMissingPrefixes = true,
    bool includeBaseDeclaration = true,
  })  : generateMissingPrefixes = generateMissingPrefixes,
        includeBaseDeclaration = includeBaseDeclaration,
        super();

  @override
  JsonLdGraphEncoderOptions copyWith(
          {Map<String, String>? customPrefixes,
          bool? generateMissingPrefixes,
          bool? includeBaseDeclaration,
          IriRelativizationOptions? iriRelativization}) =>
      JsonLdGraphEncoderOptions(
        customPrefixes: customPrefixes ?? this.customPrefixes,
        generateMissingPrefixes:
            generateMissingPrefixes ?? this.generateMissingPrefixes,
        includeBaseDeclaration:
            includeBaseDeclaration ?? this.includeBaseDeclaration,
        iriRelativization: iriRelativization ?? this.iriRelativization,
      );

  /// Creates a JSON-LD encoder options object from generic RDF encoder options
  ///
  /// This factory method ensures that when generic [RdfGraphEncoderOptions] are provided
  /// to a method expecting JSON-LD-specific options, they are properly converted.
  ///
  /// If the provided options are already a [JsonLdGraphEncoderOptions] instance, they are
  /// returned as-is. Otherwise, a new instance is created with the custom prefixes
  /// and default values for generateMissingPrefixes and includeBaseDeclaration.
  static JsonLdGraphEncoderOptions from(RdfGraphEncoderOptions options) =>
      switch (options) {
        JsonLdGraphEncoderOptions _ => options,
        _ => JsonLdGraphEncoderOptions(
            customPrefixes: options.customPrefixes,
            iriRelativization: options.iriRelativization,
          ),
      };
}

/// Converts [JsonLdGraphEncoderOptions] to [JsonLdEncoderOptions].
///
/// This helper function enables converting graph-level JSON-LD encoding options
/// to dataset-level options, similar to how `toTriGEncoderOptions` converts
/// Turtle options to TriG options.
///
/// All common options are preserved during the conversion:
/// - customPrefixes
/// - generateMissingPrefixes
/// - includeBaseDeclaration
/// - iriRelativization
///
/// Example:
/// ```dart
/// final graphOptions = JsonLdGraphEncoderOptions(
///   customPrefixes: {'ex': 'http://example.org/'},
///   generateMissingPrefixes: true,
/// );
///
/// final datasetOptions = toJsonLdEncoderOptions(graphOptions);
/// ```
JsonLdEncoderOptions toJsonLdEncoderOptions(JsonLdGraphEncoderOptions options) {
  return JsonLdEncoderOptions(
    customPrefixes: options.customPrefixes,
    generateMissingPrefixes: options.generateMissingPrefixes,
    includeBaseDeclaration: options.includeBaseDeclaration,
    iriRelativization: options.iriRelativization,
  );
}

/// Encoder for converting RDF graphs to JSON-LD format.
///
/// JSON-LD is a lightweight Linked Data format that is easy for humans to read
/// and write and easy for machines to parse and generate. This serializer
/// transforms RDF data into compact, structured JSON documents by:
///
/// - Grouping triples by subject
/// - Creating a @context section for namespace prefixes
/// - Nesting objects for more readable representation
/// - Handling different RDF term types appropriately
///
/// ## Graph Structure Handling
///
/// The encoder automatically detects the structure of the input graph:
///
/// - **Single Subject**: When the graph contains triples with only one subject,
///   the output is a single JSON-LD object with properties representing predicates.
///
/// - **Multiple Subjects**: When the graph contains triples with multiple subjects,
///   the encoder generates a JSON-LD document with a top-level `@graph` array
///   containing all subject nodes. This produces more readable output by
///   structuring the data naturally.
///
/// ## @graph and Named Graphs
///
/// Note that the current implementation does not support true RDF Datasets with
/// named graphs. When outputting a graph with multiple subjects as `@graph`,
/// this does not represent different named graphs but rather is a structural
/// device for organizing multiple nodes in the default graph.
///
/// In JSON-LD, a top-level `@graph` array can be used for two different purposes:
/// 1. As a way to organize multiple unrelated nodes (current implementation)
/// 2. As a way to represent named graphs in an RDF dataset (future enhancement)
///
/// ## Datatype Handling
///
/// The encoder handles various RDF literal types and automatically converts them
/// to appropriate JSON representations:
///
/// - String literals are represented as JSON strings
/// - Integer literals are converted to JSON numbers when possible
/// - Boolean literals are converted to JSON booleans when possible
/// - Other datatypes use the `@value` and `@type` syntax
///
/// ## Configuration Options
///
/// The serializer produces compacted JSON-LD by default, using prefixes
/// to make property names more readable. Customizations are possible
/// through namespace mappings and encoder options.
final class JsonLdGraphEncoder extends RdfGraphEncoder {
  /// Well-known common prefixes used for more readable JSON-LD output.
  final RdfNamespaceMappings _namespaceMappings;
  final JsonLdEncoder _encoder;

  /// Creates a new JSON-LD serializer.
  JsonLdGraphEncoder({
    RdfNamespaceMappings? namespaceMappings,
    JsonLdGraphEncoderOptions options = const JsonLdGraphEncoderOptions(),
  })  : _encoder = JsonLdEncoder(
            options: toJsonLdEncoderOptions(options),
            namespaceMappings: namespaceMappings),
        _namespaceMappings = namespaceMappings ?? const RdfNamespaceMappings();

  @override
  RdfGraphEncoder withOptions(RdfGraphEncoderOptions options) =>
      JsonLdGraphEncoder(
        namespaceMappings: _namespaceMappings,
        options: JsonLdGraphEncoderOptions.from(options),
      );

  /// Converts an RDF graph to a JSON-LD string representation.
  ///
  /// This method analyzes the graph structure and automatically determines
  /// the most appropriate JSON-LD representation:
  ///
  /// - For empty graphs, it returns an empty JSON object `{}`
  /// - For graphs with a single subject, it creates a single JSON-LD object
  ///   with all properties of that subject
  /// - For graphs with multiple subjects, it creates a JSON-LD document with
  ///   a top-level `@graph` array containing all subject nodes
  ///
  /// The method also:
  /// - Generates consistent labels for blank nodes
  /// - Creates a `@context` object with meaningful prefixes based on the graph content
  /// - Groups triples by subject for better structure
  /// - Handles typed literals appropriately
  ///
  /// [graph] The RDF graph to convert to JSON-LD.
  /// [baseUri] Optional base URI for relative IRIs. When provided and
  /// includeBaseDeclaration is true, it will be included in the @context.
  ///
  /// Returns a formatted JSON-LD string with 2-space indentation.
  @override
  String convert(RdfGraph graph, {String? baseUri}) {
    return _encoder.convert(RdfDataset.fromDefaultGraph(graph),
        baseUri: baseUri);
  }
}
