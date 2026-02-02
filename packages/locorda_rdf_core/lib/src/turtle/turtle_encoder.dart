import 'package:locorda_rdf_core/core.dart';

/// Configuration options for Turtle serialization.
///
/// This class provides configuration settings that control how RDF graphs
/// are serialized to the Turtle format, including namespace prefix handling
/// and automatic prefix generation.
///
/// Example:
/// ```dart
/// final options = TurtleEncoderOptions(
///   customPrefixes: {'ex': 'http://example.org/'},
///   generateMissingPrefixes: true
/// );
/// final encoder = TurtleEncoder(options: options);
/// ```
class TurtleEncoderOptions extends RdfGraphEncoderOptions {
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
  /// written as full IRIs in angle brackets (e.g., `<http://example.org/term>`).
  ///
  /// This option is particularly useful for:
  /// - Reducing the verbosity of the Turtle output
  /// - Making the serialized data more human-readable
  /// - Automatically handling unknown namespaces without manual prefix declaration
  final bool generateMissingPrefixes;

  /// Controls whether local names that start with a digit are written using prefix notation.
  ///
  /// According to the Turtle specification, local names that begin with a digit
  /// cannot be written directly in the prefixed notation, as this would produce
  /// invalid Turtle syntax.
  ///
  /// When set to `true`, the encoder will use prefixed notation for IRIs with
  /// local names that start with digits. This requires each of these local names
  /// to be escaped properly and is not recommended by default.
  ///
  /// When set to `false` (default), the encoder will always write IRIs with local
  /// names that start with a digit as full IRIs in angle brackets, regardless of
  /// whether a matching prefix exists.
  ///
  /// For example, with this option set to `false`:
  /// - The IRI `http://example.org/123` will be written as `<http://example.org/123>`
  ///   even if the prefix `ex:` is defined for `http://example.org/`
  ///
  /// This behavior ensures compliant Turtle output and improves readability
  /// while avoiding potential syntax errors.
  final bool useNumericLocalNames;

  /// Whether to include base URI declarations in the output
  ///
  /// This option only applies when a baseUri is provided during encoding.
  /// When true and a baseUri is provided, the serializer includes the base URI
  /// declaration in the format-specific way (e.g., @base in Turtle, @base in JSON-LD context).
  /// When false, the baseUri is still used for URI relativization but not declared in the output.
  /// Has no effect if no baseUri is provided during encoding.
  final bool includeBaseDeclaration;

  /// Controls how fragment IRIs are rendered in the output.
  ///
  /// When set to `true` (default), fragment IRIs from the current document are rendered
  /// as prefixed IRIs using an empty prefix declaration. For example:
  /// - `http://example.org/document#fragment` becomes `:fragment`
  /// - Requires an empty prefix declaration: `@prefix : <http://example.org/document#> .`
  ///
  /// When set to `false`, fragment IRIs are rendered as relative IRIs when they belong
  /// to the current document's namespace. For example:
  /// - `http://example.org/document#fragment` becomes `#fragment`
  /// - No empty prefix declaration is generated
  ///
  /// This setting only affects IRIs that have fragments and belong to a namespace
  /// that ends with '#'. Non-fragment IRIs are processed according to other
  /// compaction rules.
  ///
  /// Example with `renderFragmentsAsPrefixed: true` (default):
  /// ```turtle
  /// @prefix : <http://example.org/doc#> .
  ///
  /// :subject :property :object .
  /// ```
  ///
  /// Example with `renderFragmentsAsPrefixed: false`:
  /// ```turtle
  /// @base <http://example.org/doc> .
  ///
  /// <#subject> <#property> <#object> .
  /// ```
  final bool renderFragmentsAsPrefixed;

  /// Creates a new TurtleEncoderOptions instance.
  ///
  /// Parameters:
  /// - [customPrefixes] Custom namespace prefixes to use during encoding.
  ///   A mapping of prefix strings to namespace URIs that will be used
  ///   to generate compact prefix declarations in the Turtle output.
  /// - [generateMissingPrefixes] When true (default), the encoder will automatically
  ///   generate prefix declarations for IRIs that don't have a matching prefix.
  /// - [useNumericLocalNames] When false (default), IRIs with local names that start
  ///   with a digit will be written as full IRIs instead of using prefixed notation.
  /// - [includeBaseDeclaration] Whether to include base URI declarations in the output.
  ///   Defaults to true if not provided.
  /// - [renderFragmentsAsPrefixed] Whether to render fragment IRIs as prefixed IRIs (true, default)
  ///   or as relative IRIs (false).
  const TurtleEncoderOptions({
    super.customPrefixes = const {},
    super.iriRelativization = const IriRelativizationOptions.full(),
    this.generateMissingPrefixes = true,
    this.useNumericLocalNames = false,
    bool includeBaseDeclaration = true,
    this.renderFragmentsAsPrefixed = true,
  }) : includeBaseDeclaration = includeBaseDeclaration;

  /// Creates a TurtleEncoderOptions instance from generic RdfGraphEncoderOptions.
  ///
  /// This factory method enables proper type conversion when using the
  /// generic codec/encoder API with Turtle-specific options.
  ///
  /// Parameters:
  /// - [options] The options object to convert, which may or may not be
  ///   already a TurtleEncoderOptions instance.
  ///
  /// Returns:
  /// - The input as-is if it's already a TurtleEncoderOptions instance,
  ///   or a new instance with the input's customPrefixes and includeBaseDeclaration
  ///   flag, using default Turtle-specific settings for other options.
  static TurtleEncoderOptions from(RdfGraphEncoderOptions options) =>
      switch (options) {
        TurtleEncoderOptions _ => options,
        _ => TurtleEncoderOptions(
            customPrefixes: options.customPrefixes,
            iriRelativization: options.iriRelativization,
          ),
      };

  ///
  /// This method allows creating a new TurtleEncoderOptions instance based on
  /// the current options, selectively overriding specific fields while keeping
  /// all other settings unchanged.
  ///
  /// Parameters:
  /// - [customPrefixes] Optional replacement for the custom namespace prefixes
  /// - [generateMissingPrefixes] Optional replacement for the automatic prefix generation setting
  /// - [useNumericLocalNames] Optional replacement for the numeric local names handling setting
  /// - [includeBaseDeclaration] Optional replacement for the base declaration inclusion setting
  /// - [renderFragmentsAsPrefixed] Optional replacement for the fragment rendering setting
  ///
  /// Returns:
  /// - A new TurtleEncoderOptions instance with the specified changes applied
  ///
  /// Example:
  /// ```dart
  /// final originalOptions = TurtleEncoderOptions(
  ///   generateMissingPrefixes: true,
  ///   useNumericLocalNames: false
  /// );
  ///
  /// final modifiedOptions = originalOptions.copyWith(
  ///   generateMissingPrefixes: false,
  ///   customPrefixes: {'ex': 'http://example.org/'}
  /// );
  /// ```
  @override
  TurtleEncoderOptions copyWith(
          {Map<String, String>? customPrefixes,
          bool? generateMissingPrefixes,
          bool? useNumericLocalNames,
          bool? includeBaseDeclaration,
          bool? renderFragmentsAsPrefixed,
          IriRelativizationOptions? iriRelativization}) =>
      TurtleEncoderOptions(
        customPrefixes: customPrefixes ?? this.customPrefixes,
        generateMissingPrefixes:
            generateMissingPrefixes ?? this.generateMissingPrefixes,
        useNumericLocalNames: useNumericLocalNames ?? this.useNumericLocalNames,
        includeBaseDeclaration:
            includeBaseDeclaration ?? this.includeBaseDeclaration,
        renderFragmentsAsPrefixed:
            renderFragmentsAsPrefixed ?? this.renderFragmentsAsPrefixed,
        iriRelativization: iriRelativization ?? this.iriRelativization,
      );
}

TriGEncoderOptions toTriGEncoderOptions(TurtleEncoderOptions options) {
  return TriGEncoderOptions(
    customPrefixes: options.customPrefixes,
    generateMissingPrefixes: options.generateMissingPrefixes,
    useNumericLocalNames: options.useNumericLocalNames,
    includeBaseDeclaration: options.includeBaseDeclaration,
    renderFragmentsAsPrefixed: options.renderFragmentsAsPrefixed,
    iriRelativization: options.iriRelativization,
  );
}

/// Encoder for serializing RDF graphs to Turtle syntax.
///
/// The Turtle format (Terse RDF Triple Language) is a textual syntax for RDF that allows
/// writing down RDF graphs in a compact and natural text form. This encoder implements
/// the W3C Turtle recommendation, with additional optimizations for readability and compactness.
///
/// Features:
/// - Automatic namespace prefix generation
/// - Compact representation for blank nodes and collections
/// - Proper indentation and formatting for readability
/// - Support for base URI relative references
/// - Special handling for common datatypes (integers, decimals, booleans)
///
/// Example usage:
/// ```dart
/// import 'package:locorda_rdf_core/core.dart';
///
/// final graph = RdfGraph();
/// graph.add(Triple(
///   const IriTerm('http://example.org/subject'),
///   const IriTerm('http://example.org/predicate'),
///   LiteralTerm('object')
/// ));
///
/// final encoder = TurtleEncoder();
/// final turtle = encoder.convert(graph);
/// // Outputs: @prefix ex: <http://example.org/> .
/// //
/// // ex:subject ex:predicate "object" .
/// ```
///
/// See: [Turtle - Terse RDF Triple Language](https://www.w3.org/TR/turtle/)
///
/// NOTE: Always use canonical RDF vocabularies (e.g., http://xmlns.com/foaf/0.1/) with http://, not https://
/// This encoder will warn if it detects use of https:// for a namespace that is canonical as http://.
class TurtleEncoder extends RdfGraphEncoder {
  /// Standard namespace mappings used to resolve well-known prefixes.
  ///
  /// These mappings provide a collection of commonly used RDF namespaces
  /// (like rdf, rdfs, xsd, etc.) that can be used to create more compact
  /// and readable Turtle output. They also serve as a source for
  /// automatic prefix generation.
  final RdfNamespaceMappings _namespaceMappings;

  final TriGEncoder _encoder;
  final TurtleEncoderOptions _options;

  /// Creates a new Turtle encoder with the specified options.
  ///
  /// Parameters:
  /// - [namespaceMappings] Optional custom namespace mappings to use for
  ///   resolving prefixes. If not provided, default RDF namespace mappings are used.
  /// - [options] Configuration options that control encoding behavior.
  ///   Default options include automatic prefix generation.
  ///
  /// Example:
  /// ```dart
  /// // Create an encoder with custom options
  /// final encoder = TurtleEncoder(
  ///   namespaceMappings: extendedNamespaces,
  ///   options: TurtleEncoderOptions(generateMissingPrefixes: false)
  TurtleEncoder({
    RdfNamespaceMappings? namespaceMappings,
    TurtleEncoderOptions options = const TurtleEncoderOptions(),
  })  : _encoder = TriGEncoder(
          options: toTriGEncoderOptions(options),
          namespaceMappings: namespaceMappings ?? RdfNamespaceMappings(),
        ),
        _options = options,
        // Use default namespace mappings if none provided
        _namespaceMappings = namespaceMappings ?? RdfNamespaceMappings();

  String writeTerm(RdfTerm term,
          {required IriRole iriRole,
          required IriCompactionResult compactedIris,
          required Map<BlankNodeTerm, String> blankNodeLabels}) =>
      _encoder.writeTerm(term,
          iriRole: iriRole,
          compactedIris: compactedIris,
          blankNodeLabels: blankNodeLabels);

  /// Creates a new encoder with the specified options, preserving the current namespace mappings.
  ///
  /// This method allows changing encoding options without creating a completely new
  /// encoder instance. It returns a new encoder that shares the same namespace mappings
  /// but uses the provided options.
  ///
  /// Parameters:
  /// - [options] New encoder options to use. If this is already a TurtleEncoderOptions
  ///   instance, it will be used directly. Otherwise, it will be converted to
  ///   TurtleEncoderOptions using the from() factory method.
  ///
  /// Returns:
  /// - A new TurtleEncoder instance with the updated options
  ///
  /// Example:
  /// ```dart
  /// // Create a new encoder with modified options
  /// final newEncoder = encoder.withOptions(
  ///   TurtleEncoderOptions(generateMissingPrefixes: false)
  /// );
  /// ```
  @override
  RdfGraphEncoder withOptions(RdfGraphEncoderOptions options) => TurtleEncoder(
        namespaceMappings: _namespaceMappings,
        options: TurtleEncoderOptions.from(options),
      );

  RdfGraphEncoderOptions get options => _options;

  /// Converts an RDF graph to a Turtle string representation.
  ///
  /// This method serializes the given RDF graph to the Turtle format with
  /// advanced formatting features including:
  /// - Automatically detecting and writing prefix declarations
  /// - Grouping triples by subject for more compact output
  /// - Proper indentation and formatting for readability
  /// - Optimizing blank nodes that appear only once as objects by inlining them
  /// - Serializing RDF collections (lists) in the compact Turtle '(item1 item2)' notation
  ///
  /// Parameters:
  /// - [graph] The RDF graph to serialize to Turtle
  /// - [baseUri] Optional base URI to use for resolving relative IRIs and
  ///   generating shorter references. When provided and includeBaseDeclaration
  ///   is true, a @base directive will be included in the output. When
  ///   includeBaseDeclaration is false, the baseUri is still used for URI
  ///   relativization but not declared in the output.
  ///
  /// Returns:
  /// - A properly formatted Turtle string representation of the input graph.
  ///
  /// Example:
  /// ```dart
  /// final graph = RdfGraph();
  /// // Add some triples to the graph
  @override
  String convert(RdfGraph graph, {String? baseUri}) =>
      _encoder.convert(RdfDataset.fromDefaultGraph(graph), baseUri: baseUri);
}
