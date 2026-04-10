/// JSON-LD Serializer Implementation
///
/// Implements the [JsonLdEncoder] class to convert RDF graphs to JSON-LD format.
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
/// final jsonld = jsonld.encode(graph);
///
/// // Or directly with the encoder
/// final encoder = JsonLdEncoder();
/// final jsonld = encoder.convert(graph);
/// ```
///
/// See also:
/// - [JSON-LD 1.1 Specification](https://www.w3.org/TR/json-ld11/)
/// - [JSON-LD Website](https://json-ld.org/)
library jsonld_serializer;

import 'dart:convert';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/jsonld/jsonld_expanded_serializer.dart';
import 'package:locorda_rdf_core/src/jsonld/jsonld_flatten_processor.dart';
import 'package:locorda_rdf_core/src/rdf_dataset_encoder.dart';
import 'package:locorda_rdf_core/src/vocab/rdf.dart';
import 'package:locorda_rdf_core/src/vocab/xsd.dart';
import 'package:logging/logging.dart';

/// Output mode for JSON-LD encoding.
///
/// - [expanded]: Produces expanded JSON-LD with no `@context`, all IRIs fully
///   expanded, all values in arrays, and all strings wrapped in `{"@value": ...}`.
///   This is the canonical output of the W3C "Serialize RDF as JSON-LD" (fromRdf)
///   algorithm.
/// - [compact]: Produces compact JSON-LD with a `@context` and abbreviated IRIs
///   (the current default behaviour).
enum JsonLdOutputMode { expanded, compact, flattened }

final _log = Logger("rdf.jsonld");

/// Configuration options for JSON-LD encoding
///
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
class JsonLdEncoderOptions extends RdfDatasetEncoderOptions {
  /// The output mode for JSON-LD encoding.
  ///
  /// - [JsonLdOutputMode.expanded]: Produces expanded JSON-LD (no `@context`,
  ///   full IRIs, all values in arrays).
  /// - [JsonLdOutputMode.compact]: Produces compact JSON-LD with a `@context`
  ///   and abbreviated IRIs (the default).
  final JsonLdOutputMode outputMode;

  /// Controls automatic generation of namespace prefixes for IRIs without matching prefixes.
  ///
  /// When set to `true` (default), the encoder will automatically generate namespace
  /// prefixes for IRIs that don't have a matching prefix in either the custom prefixes
  /// or the standard namespace mappings.
  ///
  /// Only applies when [outputMode] is [JsonLdOutputMode.compact].
  final bool generateMissingPrefixes;

  /// Whether to include base URI declarations in the output.
  ///
  /// Only applies when [outputMode] is [JsonLdOutputMode.compact].
  final bool includeBaseDeclaration;

  /// When `true`, `xsd:boolean`, `xsd:integer` and `xsd:double` literals are
  /// converted to native JSON values instead of the expanded
  /// `{"@value":"…","@type":"…"}` form.
  ///
  /// Only applies when [outputMode] is [JsonLdOutputMode.expanded].
  final bool useNativeTypes;

  /// When `true`, `rdf:type` triples are rendered as ordinary predicates
  /// instead of being converted to `@type`.
  ///
  /// Only applies when [outputMode] is [JsonLdOutputMode.expanded].
  final bool useRdfType;

  /// Controls how RDF text direction is represented in expanded output.
  ///
  /// - `null` (default): no special direction processing.
  /// - `'i18n-datatype'`: detect `https://www.w3.org/ns/i18n#` datatypes.
  /// - `'compound-literal'`: detect blank nodes with `rdf:value`/`rdf:language`/`rdf:direction`.
  ///
  /// Only applies when [outputMode] is [JsonLdOutputMode.expanded].
  final String? rdfDirection;

  /// Optional compaction context for [JsonLdOutputMode.compact].
  ///
  /// When provided, the encoder first produces expanded JSON-LD via the W3C
  /// "Serialize RDF as JSON-LD" (fromRdf) algorithm, then compacts it using
  /// the W3C JSON-LD 1.1 Compaction Algorithm with this context.
  ///
  /// The value should be a JSON-LD context document (a Map with `@context`
  /// key, or just the context value itself).
  ///
  /// When `null` (default), the encoder uses the built-in prefix-based
  /// compaction which auto-generates a context from namespace mappings.
  final Object? compactionContext;

  /// Creates a new JSON-LD encoder options object.
  const JsonLdEncoderOptions({
    this.outputMode = JsonLdOutputMode.compact,
    super.customPrefixes = const {},
    super.iriRelativization = const IriRelativizationOptions.full(),
    this.generateMissingPrefixes = true,
    this.includeBaseDeclaration = true,
    this.useNativeTypes = false,
    this.useRdfType = false,
    this.rdfDirection,
    this.compactionContext,
  }) : super();

  @override
  JsonLdEncoderOptions copyWith({
    JsonLdOutputMode? outputMode,
    Map<String, String>? customPrefixes,
    bool? generateMissingPrefixes,
    bool? includeBaseDeclaration,
    IriRelativizationOptions? iriRelativization,
    bool? useNativeTypes,
    bool? useRdfType,
    String? rdfDirection,
    Object? compactionContext,
  }) =>
      JsonLdEncoderOptions(
        outputMode: outputMode ?? this.outputMode,
        customPrefixes: customPrefixes ?? this.customPrefixes,
        generateMissingPrefixes:
            generateMissingPrefixes ?? this.generateMissingPrefixes,
        includeBaseDeclaration:
            includeBaseDeclaration ?? this.includeBaseDeclaration,
        iriRelativization: iriRelativization ?? this.iriRelativization,
        useNativeTypes: useNativeTypes ?? this.useNativeTypes,
        useRdfType: useRdfType ?? this.useRdfType,
        rdfDirection: rdfDirection ?? this.rdfDirection,
        compactionContext: compactionContext ?? this.compactionContext,
      );

  /// Creates a JSON-LD encoder options object from generic RDF encoder options.
  static JsonLdEncoderOptions from(RdfGraphEncoderOptions options) =>
      switch (options) {
        JsonLdEncoderOptions _ => options,
        _ => JsonLdEncoderOptions(
            customPrefixes: options.customPrefixes,
            iriRelativization: options.iriRelativization,
          ),
      };
}

const _stringDatatype = Xsd.string;
const _integerDatatype = Xsd.integer;
const _doubleDatatype = Xsd.double;
const _decimalDatatype = Xsd.decimal;
const _booleanDatatype = Xsd.boolean;

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
final class JsonLdEncoder extends RdfDatasetEncoder {
  /// Well-known common prefixes used for more readable JSON-LD output.
  final RdfNamespaceMappings _namespaceMappings;
  final JsonLdEncoderOptions _options;
  late final IriCompaction _iriCompaction;
  final _useNumericLocalNames = true;

  /// Creates a new JSON-LD serializer.
  JsonLdEncoder({
    RdfNamespaceMappings? namespaceMappings,
    JsonLdEncoderOptions options = const JsonLdEncoderOptions(),
  })  : _options = options,
        _namespaceMappings = namespaceMappings ?? const RdfNamespaceMappings() {
    _iriCompaction = IriCompaction(
        _namespaceMappings,
        IriCompactionSettings(
            generateMissingPrefixes: options.generateMissingPrefixes,
            iriRelativization: options.iriRelativization,
            allowedCompactionTypes: {
              ...allowedCompactionTypesAll,
              IriRole.predicate: {
                IriCompactionType.full,
                // relative IRIs are not allowed for predicates in jsonld
                IriCompactionType.prefixed
              },
              IriRole.type: {
                IriCompactionType.full,
                IriCompactionType.prefixed,
              },
            },
            specialPredicates: {
              Rdf.type,
            },
            specialDatatypes: {
              _booleanDatatype,
              _decimalDatatype,
              _doubleDatatype,
              _integerDatatype,
              _stringDatatype,
              Rdf.langString,
            }),
        (String localPart) => RdfNamespaceMappings.isValidLocalPart(localPart,
            allowNumericLocalNames: _useNumericLocalNames));
  }

  @override
  RdfDatasetEncoder withOptions(RdfGraphEncoderOptions options) =>
      JsonLdEncoder(
        namespaceMappings: _namespaceMappings,
        options: JsonLdEncoderOptions.from(options),
      );

  /// Produces expanded JSON-LD output using [JsonLdExpandedSerializer].
  String _convertExpanded(RdfDataset dataset) {
    final serializer = JsonLdExpandedSerializer(
      useNativeTypes: _options.useNativeTypes,
      useRdfType: _options.useRdfType,
      rdfDirection: _options.rdfDirection,
    );
    final expanded = serializer.serialize(dataset);
    return const JsonEncoder.withIndent('  ').convert(expanded);
  }

  /// Produces compact JSON-LD via W3C expand-then-compact pipeline.
  ///
  /// 1. Serializes the dataset to expanded JSON-LD (fromRdf algorithm).
  /// 2. Compacts the expanded output using [JsonLdCompactionProcessor].
  ///
  /// When [context] is provided, it is used directly as the compaction context.
  /// Otherwise, a prefix-based context is auto-generated from namespace mappings.
  String _convertCompactSpec(RdfDataset dataset, {String? baseUri}) {
    // Default to useNativeTypes for compact output so that xsd:integer,
    // xsd:boolean, and xsd:double become native JSON values.
    final serializer = JsonLdExpandedSerializer(
      useNativeTypes: true,
      useRdfType: _options.useRdfType,
      rdfDirection: _options.rdfDirection,
    );
    final expanded = serializer.serialize(dataset);

    final context = _options.compactionContext ??
        _buildPrefixContext(dataset, baseUri: baseUri);

    final processor = JsonLdCompactionProcessor(
      processingMode: 'json-ld-1.1',
      documentBaseUri: baseUri,
    );
    final compacted = processor.compactExpanded(
      expanded,
      context: context,
    );

    return const JsonEncoder.withIndent('  ').convert(compacted);
  }

  /// Produces flattened JSON-LD output.
  ///
  /// 1. Serializes the dataset to expanded JSON-LD (fromRdf algorithm).
  /// 2. Flattens the expanded output using [JsonLdFlattenProcessor].
  /// 3. If a compaction context is available, the processor compacts the result.
  String _convertFlattened(RdfDataset dataset, {String? baseUri}) {
    final serializer = JsonLdExpandedSerializer(
      useNativeTypes: true,
      useRdfType: _options.useRdfType,
      rdfDirection: _options.rdfDirection,
    );
    final expanded = serializer.serialize(dataset);

    final context = _options.compactionContext ??
        _buildPrefixContext(dataset, baseUri: baseUri);

    final processor = JsonLdFlattenProcessor(
      processingMode: 'json-ld-1.1',
      documentBaseUri: baseUri,
    );

    final flattened = processor.flattenExpanded(
      expanded,
      context: context,
    );

    return const JsonEncoder.withIndent('  ').convert(flattened);
  }

  /// Builds a `{"@context": {...}}` document from namespace mappings and
  /// custom prefixes by analyzing the IRIs in the dataset.
  Map<String, Object?> _buildPrefixContext(RdfDataset dataset,
      {String? baseUri}) {
    final allTriples = <Triple>[
      ...dataset.defaultGraph.triples,
      for (final graphName in dataset.graphNames)
        if (dataset.graph(graphName) case final graph?) ...graph.triples,
    ];
    final tempGraph = RdfGraph(triples: allTriples);

    final (context: contextMap, compactedIris: _) = _createContext(
      tempGraph,
      _options.customPrefixes,
      baseUri: baseUri,
      includeBaseDeclaration: _options.includeBaseDeclaration,
      generateMissingPrefixes: _options.generateMissingPrefixes,
    );

    return {'@context': contextMap};
  }

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
  String convert(RdfDataset dataset, {String? baseUri}) {
    _log.fine('Serializing dataset to JSON-LD');

    // Expanded mode: delegate to JsonLdExpandedSerializer.
    if (_options.outputMode == JsonLdOutputMode.expanded) {
      return _convertExpanded(dataset);
    }

    // Flattened mode: expand, then flatten, optionally compact.
    if (_options.outputMode == JsonLdOutputMode.flattened) {
      return _convertFlattened(dataset, baseUri: baseUri);
    }

    // Compact mode: W3C expand-then-compact pipeline.
    return _convertCompactSpec(dataset, baseUri: baseUri);
  }

  /// Creates the @context object with prefix mappings.
  ///
  /// The context is a key part of JSON-LD that defines how predicates and types
  /// are expanded to full IRIs. This method:
  ///
  /// 1. Starts with any custom prefixes provided by the user
  /// 2. Analyzes the graph to determine which standard prefixes are actually used
  /// 3. Adds only those namespaces that are referenced by IRIs in the graph
  /// 4. Optionally generates new prefixes for unknown namespaces when generateMissingPrefixes is true
  ///
  /// This produces a minimal, relevant context that makes the JSON-LD more compact
  /// and readable while still maintaining the complete semantic information.
  ///
  /// Custom prefixes always take precedence over standard ones if there's a conflict.
  ({Map<String, dynamic> context, IriCompactionResult compactedIris})
      _createContext(
    RdfGraph graph,
    Map<String, String> customPrefixes, {
    String? baseUri,
    bool includeBaseDeclaration = true,
    bool generateMissingPrefixes = true,
  }) {
    final context = <String, dynamic>{};

    // Add base URI if provided and includeBaseDeclaration is true
    if (baseUri != null && includeBaseDeclaration) {
      context['@base'] = baseUri;
    }

    // Add all custom prefixes
    context.addAll(customPrefixes);

    // Add common prefixes that are used in the graph
    final compactedIris = _iriCompaction.compactAllIris(
      graph,
      customPrefixes,
      baseUri: baseUri,
    );

    // Add prefixes that don't conflict with custom ones
    for (final entry in compactedIris.prefixes.entries) {
      if (!customPrefixes.containsKey(entry.key)) {
        context[entry.key] = entry.value;
      }
    }

    return (context: context, compactedIris: compactedIris);
  }

}
