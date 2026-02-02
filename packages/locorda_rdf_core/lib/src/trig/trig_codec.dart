/// TriG RDF Format - RDF dataset serialization with named graphs
///
/// This file defines the implementation of the TriG (TriG RDF Graph)
/// serialization format for RDF data. TriG extends Turtle to support named graphs,
/// providing a compact and human-readable syntax for encoding RDF datasets as text.
library trig_format;

import 'package:locorda_rdf_core/src/graph/rdf_term.dart';
import 'package:locorda_rdf_core/src/plugin/rdf_dataset_codec.dart';
import 'package:locorda_rdf_core/src/rdf_dataset_decoder.dart';
import 'package:locorda_rdf_core/src/rdf_dataset_encoder.dart';
import 'package:locorda_rdf_core/src/rdf_decoder.dart';
import 'package:locorda_rdf_core/src/rdf_encoder.dart';
import 'package:locorda_rdf_core/src/vocab/namespaces.dart';

import 'trig_decoder.dart';
import 'trig_encoder.dart';

export 'trig_decoder.dart' show TriGDecoderOptions, TriGDecoder;
export 'trig_encoder.dart' show TriGEncoderOptions, TriGEncoder;

/// RDF Codec implementation for the TriG serialization format.
///
/// TriG is an extension of Turtle that adds support for named graphs, allowing
/// multiple RDF graphs to be represented in a single document. It is both
/// readable by humans and parsable by machines.
///
/// ## TriG Syntax Overview
///
/// TriG supports all Turtle features plus named graphs:
///
/// - **All Turtle features**: Prefixed names, lists, predicate lists, object lists, blank nodes
///
/// - **Named graphs with GRAPH keyword**:
///   ```trig
///   @prefix ex: <http://example.org/> .
///   GRAPH ex:graph1 {
///     ex:subject ex:predicate "object" .
///   }
///   ```
///
/// - **Named graph shorthand**:
///   ```trig
///   ex:graph1 {
///     ex:subject ex:predicate "object" .
///   }
///   ```
///
/// - **Default graph**: Triples outside graph blocks
///   ```trig
///   ex:subject ex:predicate "object" .
///   ```
///
/// - **Blank node graph names**:
///   ```trig
///   _:graph1 {
///     ex:subject ex:predicate "object" .
///   }
///   ```
///
/// ## File Extension and MIME Types
///
/// TriG files typically use the `.trig` file extension.
/// The primary MIME type is `application/trig`.
final class TriGCodec extends RdfDatasetCodec {
  static const _primaryMimeType = 'application/trig';

  /// All MIME types that this format implementation can handle
  static const _supportedMimeTypes = {
    _primaryMimeType,
    'application/x-trig',
  };

  final RdfNamespaceMappings _namespaceMappings;
  final TriGEncoderOptions _encoderOptions;
  final TriGDecoderOptions _decoderOptions;
  final IriTermFactory _iriTermFactory;

  /// Creates a new TriG codec
  ///
  /// Parameters:
  /// - [namespaceMappings] Optional namespace prefixes to use for encoding and decoding.
  ///   If not provided, defaults to standard RDF namespace mappings.
  /// - [encoderOptions] Configuration options for the TriG encoder.
  ///   Default settings use standard formatting with common prefixes.
  /// - [decoderOptions] Configuration options for the TriG decoder.
  ///   Default settings handle standard TriG syntax with no special configurations.
  const TriGCodec({
    RdfNamespaceMappings? namespaceMappings,
    TriGEncoderOptions encoderOptions = const TriGEncoderOptions(),
    TriGDecoderOptions decoderOptions = const TriGDecoderOptions(),
    IriTermFactory iriTermFactory = IriTerm.validated,
  })  : _namespaceMappings = namespaceMappings ?? const RdfNamespaceMappings(),
        _encoderOptions = encoderOptions,
        _decoderOptions = decoderOptions,
        _iriTermFactory = iriTermFactory;

  /// Creates a new instance with the specified options
  ///
  /// This method returns a new TriG codec configured with the provided
  /// encoder and decoder options. The original codec instance remains unchanged.
  ///
  /// Parameters:
  /// - [encoder] Optional encoder options to customize encoding behavior.
  ///   Will be properly cast to TriGEncoderOptions if possible, else we use
  ///   just the options from the [RdfGraphEncoderOptions] class.
  /// - [decoder] Optional decoder options to customize decoding behavior.
  ///   Will be properly cast to TriGDecoderOptions if possible, else we use
  ///   just the options from the [RdfGraphDecoderOptions] class.
  ///
  /// Returns:
  /// - A new [TriGCodec] instance with the specified options applied,
  ///   while preserving the original namespace mappings.
  @override
  TriGCodec withOptions({
    RdfGraphEncoderOptions? encoder,
    RdfGraphDecoderOptions? decoder,
    IriTermFactory? iriTermFactory,
  }) {
    return TriGCodec(
        namespaceMappings: _namespaceMappings,
        encoderOptions: TriGEncoderOptions.from(encoder ?? _encoderOptions),
        decoderOptions: TriGDecoderOptions.from(decoder ?? _decoderOptions),
        iriTermFactory: iriTermFactory ?? _iriTermFactory);
  }

  /// Returns the primary MIME type for Turtle format
  ///
  /// The canonical MIME type for Turtle is 'text/turtle'.
  @override
  String get primaryMimeType => _primaryMimeType;

  /// Returns all MIME types supported by this TriG codec
  ///
  /// Includes the primary MIME type 'application/trig' and other
  /// alternative MIME types.
  @override
  Set<String> get supportedMimeTypes => _supportedMimeTypes;

  /// Returns a TriG decoder instance
  ///
  /// Creates a new decoder that can parse TriG syntax into an RDF dataset.
  /// The decoder will be initialized with this codec's namespace mappings
  /// and decoder options.
  ///
  /// Returns:
  /// - A [TriGDecoder] configured with this codec's settings
  @override
  RdfDatasetDecoder get decoder => TriGDecoder(
      options: _decoderOptions,
      namespaceMappings: _namespaceMappings,
      iriTermFactory: _iriTermFactory);

  /// Returns a TriG encoder instance
  ///
  /// Creates a new encoder that can serialize an RDF dataset to TriG syntax.
  /// The encoder will be initialized with this codec's namespace mappings
  /// and encoder options.
  ///
  /// Returns:
  /// - A [TriGEncoder] configured with this codec's settings
  @override
  RdfDatasetEncoder get encoder => TriGEncoder(
        options: _encoderOptions,
        namespaceMappings: _namespaceMappings,
      );

  /// Determines if the content is likely in TriG format
  ///
  /// This method performs a heuristic analysis of the content to check if it
  /// appears to be in TriG format. It looks for common TriG syntax markers
  /// such as prefix declarations, GRAPH keywords, graph blocks, and triple patterns.
  ///
  /// The method uses a lightweight approach that balances accuracy with performance,
  /// avoiding a full parse while still providing reasonable detection capability.
  ///
  /// Parameters:
  /// - [content] The string content to analyze
  ///
  /// Returns:
  /// - true if the content appears to be in Turtle format
  @override
  bool canParse(String content) {
    // Simple heuristics for detecting Turtle format
    final trimmed = content.trim();

    // Early rejection: obvious HTML content
    if (_isObviouslyHtml(trimmed)) {
      return false;
    }

    // Check for explicit TriG directives
    if (trimmed.contains('@prefix') ||
        trimmed.contains('@base') ||
        trimmed.contains('GRAPH') ||
        trimmed.contains('prefix rdf:') ||
        trimmed.contains('prefix rdfs:') ||
        trimmed.contains('prefix owl:') ||
        trimmed.contains('prefix xsd:')) {
      return true;
    }

    // Look for Turtle-like triple patterns (more specific than before)
    // Must have angle brackets for IRIs or prefixed names
    final hasTriplePattern = RegExp(
      r'(<[^>]+>|\w+:\w+)\s+(<[^>]+>|\w+:\w+|a)\s+(<[^>]+>|\w+:\w+|"[^"]*"|\d+|true|false)\s*\.',
      multiLine: true,
    ).hasMatch(trimmed);

    if (hasTriplePattern) {
      return true;
    }

    // Check for blank node patterns
    final hasBlankNodes = RegExp(r'\[\s*\]|\[.*?\]').hasMatch(trimmed);
    if (hasBlankNodes && trimmed.contains('.')) {
      return true;
    }

    // Check for collection patterns
    final hasCollections = RegExp(r'\(\s*\)|\([^)]+\)').hasMatch(trimmed);
    if (hasCollections && trimmed.contains('.')) {
      return true;
    }

    // Check for TriG graph blocks
    final hasGraphBlocks =
        RegExp(r'GRAPH\s+<[^>]+>\s*\{|<[^>]+>\s*\{').hasMatch(trimmed);
    if (hasGraphBlocks) {
      return true;
    }

    return false;
  }

  /// Helper method to detect obvious HTML content that should be rejected
  bool _isObviouslyHtml(String content) {
    final lowerContent = content.toLowerCase();

    // Check for HTML doctype
    if (lowerContent.startsWith('<!doctype html')) {
      return true;
    }

    // Check for HTML opening tag
    if (lowerContent.startsWith('<html')) {
      return true;
    }

    // Single HTML tag might be coincidental, but DOCTYPE or <html> is definitive
    return false;
  }
}

/// Global convenience variable for working with TriG format
///
/// This variable provides direct access to a pre-configured TriG codec
/// for easy encoding and decoding of TriG data without needing to create
/// a codec instance manually.
///
/// Example:
/// ```dart
/// final dataset = trig.decode(trigString);
/// final serialized = trig.encode(dataset);
/// ```
///
/// For custom configuration, you can create a new codec with specific options:
/// ```dart
/// final customTrig = TriGCodec(
///   namespaceMappings: myNamespaces,
///   encoderOptions: TriGEncoderOptions(generateMissingPrefixes: false),
/// );
/// ```
final trig = TriGCodec();
