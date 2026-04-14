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
/// - @vocab for default vocabulary expansion
/// - Complex term definitions with @type coercion (@id, @vocab, datatype IRIs)
/// - @container: @list for RDF collections
/// - @list and @set value objects
/// - @reverse properties
/// - Context arrays (merging multiple context objects)
/// - Default @language in context
///
/// This library is part of the RDF Core package and uses the common RDF data model
/// defined in the graph module.
///
/// See:
/// - [JSON-LD 1.1 Specification](https://www.w3.org/TR/json-ld11/)
/// - [JSON-LD 1.1 Processing Algorithms and API](https://www.w3.org/TR/json-ld11-api/)
library;

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_codec.dart';
import 'package:locorda_rdf_core/extend.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_context_processor.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_context_documents.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_utils.dart';

final _log = Logger("rdf.jsonld");

const _rdfValuePredicate = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#value';
const _rdfDirectionPredicate =
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#direction';
const _rdfLanguagePredicate =
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#language';
const _i18nDatatypeBase = 'https://www.w3.org/ns/i18n#';

class _ScopedNodeEntry {
  const _ScopedNodeEntry(this.key, this.value, this.context);

  final String key;
  final JsonValue value;
  final JsonLdContext context;
}

/// Configuration options for JSON-LD decoding
///
/// Configuration options for the JSON-LD decoder.
///
/// These options control context loading, base IRI handling, processing mode,
/// and error behavior during JSON-LD to RDF conversion.
///
/// Error handling defaults to fail-fast: invalid RDF terms (for example
/// malformed IRIs or invalid language tags) throw immediately.
///
/// To switch to best-effort conversion for compatibility scenarios,
/// set [skipInvalidRdfTerms] to `true`.
class JsonLdDecoderOptions extends RdfDatasetDecoderOptions {
  /// Preferred provider abstraction for external context resolution.
  final JsonLdContextDocumentProvider? contextDocumentProvider;

  /// Overrides the effective document base used for resolving relative IRIs.
  final String? baseIri;

  /// Applies an additional context before processing the input document.
  final JsonValue? expandContext;

  /// Optional RDF direction serialization mode for value objects containing
  /// `@direction`.
  final String? rdfDirection;

  /// JSON-LD processing mode used for version-gated features.
  final String processingMode;

  /// Loader used to resolve external context documents referenced by string
  /// values in `@context` (for example `"context.jsonld"`).
  ///
  /// Deprecated in favor of [contextDocumentProvider].
  @Deprecated('Use contextDocumentProvider instead.')
  final JsonLdContextDocumentLoader? contextDocumentLoader;

  /// Preloaded external context documents, keyed by resolved context IRI.
  ///
  /// This is primarily used by [AsyncJsonLdDecoder] to avoid duplicate loading
  /// and duplicate decoding.
  final JsonObject preloadedParsedContextDocuments;

  /// Optional parsed document cache shared across decode calls.
  final JsonLdContextDocumentCache? contextDocumentCache;

  /// Controls how invalid RDF terms produced during JSON-LD to RDF conversion
  /// are handled.
  ///
  /// When `false` (default), conversion is fail-fast and throws on invalid
  /// IRIs or invalid language tags.
  ///
  /// When `true`, invalid IRIs/language tags are skipped so processing can
  /// continue for the remaining statements.
  final bool skipInvalidRdfTerms;

  /// Creates a new JSON-LD decoder options object with default settings
  const JsonLdDecoderOptions({
    this.contextDocumentProvider,
    this.baseIri,
    this.expandContext,
    this.contextDocumentLoader,
    this.preloadedParsedContextDocuments = const {},
    this.contextDocumentCache,
    this.skipInvalidRdfTerms = false,
    this.rdfDirection,
    this.processingMode = 'json-ld-1.1',
  });

  /// Creates a JSON-LD decoder options object from generic RDF decoder options
  ///
  /// This factory method ensures that when generic [RdfGraphDecoderOptions] are provided
  /// to a method expecting JSON-LD-specific options, they are properly converted.
  ///
  /// If the provided options are already a [JsonLdDecoderOptions] instance, they are
  /// returned as-is. Otherwise, a new instance with default settings is created.
  static JsonLdDecoderOptions from(RdfGraphDecoderOptions options) =>
      switch (options) {
        JsonLdDecoderOptions _ => options,
        _ => JsonLdDecoderOptions(),
      };
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
class JsonLdDecoder extends RdfDatasetDecoder {
  final JsonLdDecoderOptions _options;
  final IriTermFactory _iriTermFactory;
  final String _format;

  const JsonLdDecoder({
    JsonLdDecoderOptions options = const JsonLdDecoderOptions(),
    IriTermFactory iriTermFactory = IriTerm.validated,
    String format = "JSON-LD",
  })  : _options = options,
        _iriTermFactory = iriTermFactory,
        _format = format;

  @override
  RdfDatasetDecoder withOptions(RdfGraphDecoderOptions options) {
    return JsonLdDecoder(
        options: JsonLdDecoderOptions.from(options),
        iriTermFactory: _iriTermFactory);
  }

  @override
  RdfDataset convert(String input, {String? documentUrl}) {
    final parsedInput = parseJsonValueOrThrow(input, format: _format);
    final effectiveInput = _options.expandContext == null
        ? input
        : jsonEncode(_applyExpandContext(parsedInput, _options.expandContext!));
    final parser = JsonLdParser(
      effectiveInput,
      baseUri: _options.baseIri ?? documentUrl,
      iriTermFactory: _iriTermFactory,
      format: _format,
      rdfDirection: _options.rdfDirection,
      processingMode: _options.processingMode,
      contextDocumentProvider: _options.contextDocumentProvider,
      // ignore: deprecated_member_use_from_same_package
      contextDocumentLoader: _options.contextDocumentLoader,
      preloadedParsedContextDocuments: _options.preloadedParsedContextDocuments,
      contextDocumentCache: _options.contextDocumentCache,
      skipInvalidRdfTerms: _options.skipInvalidRdfTerms,
    );
    return RdfDataset.fromQuads(parser.parse());
  }

  JsonValue _applyExpandContext(JsonValue input, JsonValue expandContext) {
    if (input is JsonObject) {
      final expanded = JsonObject.from(input);
      if (expanded.containsKey('@context')) {
        expanded['@context'] = [expandContext, expanded['@context']];
      } else {
        expanded['@context'] = expandContext;
      }
      return expanded;
    }

    if (input is JsonArray) {
      return input.map((item) {
        if (item is! JsonObject) {
          return item;
        }

        final expanded = JsonObject.from(item);
        if (expanded.containsKey('@context')) {
          expanded['@context'] = [expandContext, expanded['@context']];
        } else {
          expanded['@context'] = expandContext;
        }
        return expanded;
      }).toList(growable: false);
    }

    return input;
  }
}

/// A parser for JSON-LD (JSON for Linked Data) format.
///
/// JSON-LD is a lightweight Linked Data format based on JSON. It provides a way
/// to help JSON data interoperate at Web-scale by adding semantic context to JSON data.
/// This parser supports:
///
/// - Basic JSON-LD document parsing
/// - Subject-predicate-object triple extraction
/// - Context resolution for compact IRIs
/// - Graph structure parsing (@graph)
/// - Type coercion (@type: @id, @vocab, and datatype IRIs)
/// - Blank node handling
/// - @vocab (default vocabulary expansion)
/// - @language (default language for string literals)
/// - @list and @set value objects
/// - @container: @list (RDF collections)
/// - @reverse properties
/// - Context arrays (merging multiple context objects)
///
/// ## Named Graph Handling
///
/// When a JSON-LD document contains a top-level `@graph` property, this parser will
/// extract all triples from the named graph into a flat list of triples. The graph
/// name information itself is not preserved in the current implementation, as the
/// focus is on generating a single RDF Graph from the input.
///
/// ## Example usage:
/// ```dart
/// // Basic JSON-LD document
/// final parser = JsonLdParser('''
///   {
///     "@context": {
///       "name": "http://xmlns.com/foaf/0.1/name"
///     },
///     "@id": "http://example.com/me",
///     "name": "John Doe"
///   }
/// ''', baseUri: 'http://example.com/');
///
/// // JSON-LD document with @graph structure
/// final graphParser = JsonLdParser('''
///   {
///     "@context": {
///       "name": "http://xmlns.com/foaf/0.1/name"
///     },
///     "@graph": [
///       { "@id": "http://example.com/alice", "name": "Alice" },
///       { "@id": "http://example.com/bob", "name": "Bob" }
///     ]
///   }
/// ''', baseUri: 'http://example.com/');
///
/// // All triples from both objects in the @graph will be extracted into a
/// // single flat list and merged into one RDF Graph.
/// ```
///
/// See: [JSON-LD 1.1 Processing Algorithms and API](https://www.w3.org/TR/json-ld11-api/)
class JsonLdParser {
  final String _input;
  final String? _baseUri;
  final IriTermFactory _iriTermFactory;
  // Map to store consistent blank node instances across the parsing process
  final Map<String, BlankNodeTerm> _blankNodeCache = {};
  final String _format;
  final String? _rdfDirection;
  final String _processingMode;
  final bool _skipInvalidRdfTerms;

  /// Shared context processor for context parsing and IRI expansion.
  late final JsonLdContextProcessor _contextProcessor;

  /// Guard against infinite recursion when applying scoped contexts.
  int _contextApplicationDepth = 0;
  static const int _maxContextApplicationDepth = 256;

  /// Base URI extracted from @base in the current context
  /// This overrides _baseUri (document URL) when hasContextBase is true
  String? _contextBaseUri;

  /// Whether @base was explicitly set in the context
  /// This allows us to distinguish between "@base not set" and "@base: null"
  bool _hasContextBase = false;

  // IRI term interning cache: avoids repeated IriTermFactory calls for identical IRI strings.
  final Map<String, IriTerm> _iriTermCache = {};

  static const String _rdfType =
      'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';
  static const String _rdfFirst =
      'http://www.w3.org/1999/02/22-rdf-syntax-ns#first';
  static const String _rdfRest =
      'http://www.w3.org/1999/02/22-rdf-syntax-ns#rest';
  static const String _rdfNil =
      'http://www.w3.org/1999/02/22-rdf-syntax-ns#nil';

  /// Creates a new JSON-LD parser for the given input string.
  ///
  /// [input] is the JSON-LD document to parse.
  /// [baseUri] is the base URI against which relative IRIs should be resolved.
  /// If not provided, relative IRIs will be kept as-is.
  JsonLdParser(String input,
      {String? baseUri,
      IriTermFactory iriTermFactory = IriTerm.validated,
      String format = "JSON-LD",
      String? rdfDirection,
      String processingMode = 'json-ld-1.1',
      JsonLdContextDocumentProvider? contextDocumentProvider,
      JsonLdContextDocumentLoader? contextDocumentLoader,
      JsonObject preloadedParsedContextDocuments = const {},
      JsonLdContextDocumentCache? contextDocumentCache,
      bool skipInvalidRdfTerms = false})
      : _input = input,
        _baseUri = baseUri,
        _iriTermFactory = iriTermFactory,
        _rdfDirection = rdfDirection,
        _processingMode = processingMode,
        _skipInvalidRdfTerms = skipInvalidRdfTerms,
        _format = format {
    // Wrap the deprecated contextDocumentLoader as a provider if needed.
    final effectiveProvider = contextDocumentProvider ??
        (contextDocumentLoader != null
            ? _LegacyLoaderProvider(contextDocumentLoader)
            : null);
    _contextProcessor = JsonLdContextProcessor(
      processingMode: processingMode,
      contextDocumentProvider: effectiveProvider,
      contextDocumentCache: contextDocumentCache,
      preloadedParsedContextDocuments: preloadedParsedContextDocuments,
      format: format,
      documentBaseUri: baseUri,
    );
  }

  /// Parses the JSON-LD input and returns a list of quads.
  ///
  /// This method processes the input by:
  /// 1. Parsing the JSON document
  /// 2. Extracting the @context if present
  /// 3. Processing the document structure to generate RDF triples
  ///
  /// The method handles both single JSON objects and arrays of JSON objects.
  /// It also processes the `@graph` property if present, extracting all contained
  /// nodes as separate entities in the resulting RDF graph.
  ///
  /// Throws [RdfSyntaxException] if the input is not valid JSON-LD.
  List<Quad> parse() {
    try {
      _log.fine('Starting JSON-LD parsing');
      final jsonData = parseJsonValueOrThrow(_input, format: _format);

      final triples = <Quad>[];

      if (jsonData is JsonArray) {
        _log.fine('Parsing JSON-LD array');
        for (final item in jsonData) {
          if (item is JsonObject) {
            _processNode(item, triples);
          } else {
            _log.warning('Skipping non-object item in JSON-LD array');
            throw RdfSyntaxException(
              'Array item must be a JSON object',
              format: _format,
            );
          }
        }
      } else if (jsonData is JsonObject) {
        _log.fine('Parsing JSON-LD object');
        _processNode(jsonData, triples);
      } else {
        _log.severe('JSON-LD must be an object or array at the top level');
        throw RdfSyntaxException(
          'Invalid JSON-LD: must be an object or array at the top level',
          format: _format,
        );
      }

      // RDF graphs are sets — deduplicate quads that reference the same
      // subject via multiple paths (e.g. @included + inline data objects).
      final deduped = triples.toSet().toList();
      _log.fine('JSON-LD parsing complete. Found ${deduped.length} triples');
      return deduped;
    } catch (e, stack) {
      if (e is RdfException) {
        rethrow;
      }

      _log.severe('Failed to parse JSON-LD', e, stack);
      throw RdfSyntaxException(
        'JSON-LD parsing error: $e',
        format: _format,
        cause: e,
      );
    }
  }

  /// Process a JSON-LD node and extract triples.
  void _processNode(
    JsonObject node,
    List<Quad> triples, {
    RdfGraphName? graphName,
    JsonLdContext? inheritedContext,
  }) {
    final context = _extractContext(
      node,
      baseContext: inheritedContext ?? const JsonLdContext(),
    );
    final graphValue = _getKeywordValue(node, '@graph', context);
    final idValue = _getKeywordValue(node, '@id', context);

    final previousContextBaseUri = _contextBaseUri;
    final previousHasContextBase = _hasContextBase;

    try {
      if (context.hasBase) {
        if (context.base != null) {
          // Absolute @base must remain unchanged; only relative @base is resolved.
          final baseValue = context.base!;
          _contextBaseUri = _looksLikeAbsoluteIri(baseValue)
              ? baseValue
              : resolveIri(baseValue, _getEffectiveBaseUri());
        } else {
          _contextBaseUri = null;
        }
        // Set AFTER resolving against previous base
        _hasContextBase = true;
        _log.fine('Updated context base URI to: $_contextBaseUri');
      } else if (node.containsKey('@context') && node['@context'] == null) {
        // @context: null resets ALL context state; base reverts to document URL.
        _contextBaseUri = null;
        _hasContextBase = false;
      }

      // Handle @graph property if present
      if (graphValue != null) {
        _log.fine('Processing @graph structure');
        final graph = graphValue;

        final hasNodeProperties = node.keys.any((key) =>
            !_isKeywordKey(key, context, '@context') &&
            !_isKeywordKey(key, context, '@id') &&
            !_isKeywordKey(key, context, '@graph'));

        if (hasNodeProperties) {
          _extractTriples(node, context, triples, graphName: graphName);
        }

        RdfGraphName? nestedGraphName = graphName;
        if (idValue != null) {
          final graphId = idValue;
          if (graphId is String) {
            final expandedId = _expandIriForId(graphId, context);
            final subjectTerm = _tryCreateSubjectTerm(expandedId);
            if (subjectTerm == null && _skipInvalidRdfTerms) {
              return;
            }
            if (subjectTerm is RdfGraphName) {
              nestedGraphName = subjectTerm;
              _log.fine('Processing named graph: $nestedGraphName');
            }
          }
        } else if (hasNodeProperties) {
          final subjectId = _getSubjectId(node, context);
          final subjectTerm =
              subjectId != null ? _tryCreateSubjectTerm(subjectId) : null;
          if (subjectTerm is RdfGraphName) {
            nestedGraphName = subjectTerm;
            _log.fine('Processing generated named graph: $nestedGraphName');
          }
        }

        final graphItems = <JsonObject>[];
        if (graph is JsonArray) {
          for (final item in graph) {
            if (item is JsonObject) {
              // Unwrap @set objects in @graph
              if (item.containsKey('@set')) {
                final setItems = item['@set'];
                if (setItems is List) {
                  for (final si in setItems) {
                    if (si is JsonObject) graphItems.add(si);
                  }
                }
                continue;
              }
              // Skip free-floating @list objects in @graph
              if (item.containsKey('@list')) continue;
              // Skip free-floating value objects
              if (item.containsKey('@value')) continue;
              graphItems.add(item);
            }
            // Skip non-object items (strings, numbers, booleans, nulls)
          }
        } else if (graph is JsonObject) {
          graphItems.add(graph);
        }

        for (final item in graphItems) {
          // Skip free-floating nodes (only @id, no properties)
          final isFreeFloating = !item.keys.any((key) {
            final resolved = _resolveKeywordAlias(key, context);
            return resolved != '@id' &&
                resolved != '@context' &&
                resolved != '@index';
          });
          if (isFreeFloating) continue;

          if (item.containsKey('@graph')) {
            // Pass the already-parsed context via inheritedContext; no need to
            // re-inject the raw @context value, which would force a redundant
            // _mergeContextDefinition call for every nested @graph node.
            _processNode(
              item,
              triples,
              graphName: nestedGraphName,
              inheritedContext: context,
            );
          } else {
            _extractTriples(item, context, triples, graphName: nestedGraphName);
          }
        }
        return;
      }

      // Process regular node
      _extractTriples(node, context, triples, graphName: graphName);
    } finally {
      _contextBaseUri = previousContextBaseUri;
      _hasContextBase = previousHasContextBase;
    }
  }

  /// Extract and build the active context from a JSON-LD node.
  ///
  /// Handles single context objects, context arrays, and the special
  /// keywords `@base`, `@vocab`, and `@language`. Common well-known
  /// prefixes are included as defaults.
  JsonLdContext _extractContext(
    JsonObject node, {
    JsonLdContext baseContext = const JsonLdContext(),
  }) {
    return _contextProcessor.extractContext(node,
        baseContext: baseContext, effectiveBaseUri: _baseUri);
  }

  /// Delegates to shared [JsonLdContextProcessor.mergeContext].
  JsonLdContext _mergeContextDefinition(
    JsonLdContext baseContext,
    JsonValue definition, {
    required Set<String> seenContextIris,
    String? contextDocumentBaseIri,
    bool allowProtectedNullification = false,
    bool allowProtectedOverride = false,
    bool allowContextWrapper = false,
  }) {
    return _contextProcessor.mergeContext(baseContext, definition,
        seenContextIris: seenContextIris,
        contextDocumentBaseIri: contextDocumentBaseIri,
        allowProtectedNullification: allowProtectedNullification,
        allowProtectedOverride: allowProtectedOverride,
        allowContextWrapper: allowContextWrapper);
  }

  // _mergeExternalContext — handled by _contextProcessor

  /// Delegates to shared [JsonLdContextProcessor.expandIri].
  String _expandPredicate(String key, JsonLdContext context) {
    return _contextProcessor.expandIri(key, context);
  }

  /// Extract triples from a JSON-LD node.
  void _extractTriples(
    JsonObject node,
    JsonLdContext context,
    List<Quad> triples, {
    RdfGraphName? graphName,
  }) {
    final effectiveContext = _applyTypeScopedContexts(node, context);
    final entries = _flattenNestEntries(node, effectiveContext);

    final previousContextBaseUri = _contextBaseUri;
    final previousHasContextBase = _hasContextBase;

    if (effectiveContext.hasBase) {
      if (effectiveContext.base != null) {
        final baseValue = effectiveContext.base!;
        _contextBaseUri = _looksLikeAbsoluteIri(baseValue)
            ? baseValue
            : resolveIri(baseValue, _getEffectiveBaseUri());
      } else {
        _contextBaseUri = null;
      }
      _hasContextBase = true;
    }

    try {
      // Look for @id in the flattened entries (may come from @nest).
      final subjectStr =
          _getSubjectIdFromEntries(node, entries, effectiveContext);
      if (subjectStr == null) {
        if (_skipInvalidRdfTerms) {
          _log.fine('Skipping node with unresolvable relative IRI');
          return;
        }
        throw RdfSyntaxException(
          'Unable to resolve relative IRI for subject',
          format: _format,
        );
      }
      final subject = _tryCreateSubjectTerm(subjectStr);
      if (subject == null) {
        if (_skipInvalidRdfTerms) {
          _log.fine('Skipping node with invalid subject IRI: $subjectStr');
          return;
        }
        throw RdfSyntaxException(
          'Invalid subject IRI: $subjectStr',
          format: _format,
        );
      }
      _log.fine('Processing node with subject: $subject');

      for (final entry in entries) {
        final key = entry.key;
        final value = entry.value;
        final entryContext = entry.context;
        final resolvedKey = _resolveKeywordAlias(key, entryContext);

        // Handle JSON-LD keywords
        if (resolvedKey.startsWith('@') &&
            jsonLdKeywords.contains(resolvedKey)) {
          if (resolvedKey == '@type') {
            _processType(subject, value, triples, context,
                graphName: graphName);
          } else if (resolvedKey == '@reverse') {
            _processReverse(subject, value, triples, entryContext,
                graphName: graphName);
          } else if (resolvedKey == '@included') {
            if (_processingMode == 'json-ld-1.0') {
              throw RdfSyntaxException('invalid @included value',
                  format: _format);
            }
            if (value is JsonArray) {
              for (final included in value) {
                if (included is! JsonObject ||
                    included.containsKey('@value') ||
                    included.containsKey('@list')) {
                  throw RdfSyntaxException(
                    'invalid @included value',
                    format: _format,
                  );
                }
                _extractTriples(included, entryContext, triples,
                    graphName: graphName);
              }
            } else if (value is JsonObject) {
              if (value.containsKey('@value') || value.containsKey('@list')) {
                throw RdfSyntaxException(
                  'invalid @included value',
                  format: _format,
                );
              }
              _extractTriples(value, entryContext, triples,
                  graphName: graphName);
            } else {
              throw RdfSyntaxException('invalid @included value',
                  format: _format);
            }
          }
          continue;
        }

        // Skip keyword-like @-forms that aren't actual keywords
        if (resolvedKey.startsWith('@') && _isKeywordLikeAtForm(resolvedKey)) {
          continue;
        }

        final termDef = entryContext.terms[key];
        final valueContext = _applyTermScopedContext(entryContext, termDef);
        // Compute child context: strip type-scoped modifications (which have
        // propagate: false) but keep property-scoped terms from nest flattening.
        var childBase = entryContext;
        if (entryContext.hasPropagate && !entryContext.propagate) {
          childBase = entryContext.nonPropagatedParent ?? context;
        }
        final childInheritedContext =
            _applyTermScopedContext(childBase, termDef);
        final predicateStr = _expandPredicate(key, entryContext);
        final predicate = _tryCreateIriTerm(predicateStr);
        if (predicate == null) {
          _log.fine(
              'Skipping property with non-absolute predicate: $predicateStr');
          continue;
        }
        _log.fine('Processing property: $key -> $predicate');

        // Handle reverse term definitions (subject and object are swapped)
        if (termDef?.isReverse == true) {
          // If the reverse term also has @container: @index, unwrap the
          // index map and process each value as a reverse triple.
          if (termDef?.hasContainer('@index') == true && value is JsonObject) {
            for (final indexEntry in value.entries) {
              final indexValues = indexEntry.value is JsonArray
                  ? indexEntry.value as JsonArray
                  : [indexEntry.value];
              _addReverseTriples(
                  subject, predicate, indexValues, triples, valueContext,
                  graphName: graphName);
            }
          } else {
            _addReverseTriples(subject, predicate, value, triples, valueContext,
                graphName: graphName);
          }
          continue;
        }

        if (termDef?.hasContainer('@graph') == true) {
          _addGraphContainerTriples(
            subject,
            predicate,
            value,
            triples,
            valueContext,
            termDef: termDef,
            graphName: graphName,
            inheritedContextForNode: childInheritedContext,
          );
          continue;
        }

        if (termDef?.hasContainer('@id') == true &&
            termDef?.hasContainer('@graph') != true) {
          _addIdContainerTriples(
            subject,
            predicate,
            value,
            triples,
            valueContext,
            termDef: termDef,
            graphName: graphName,
            inheritedContextForNode: childInheritedContext,
          );
          continue;
        }

        if (termDef?.hasContainer('@type') == true) {
          _addTypeContainerTriples(
            subject,
            predicate,
            value,
            triples,
            valueContext,
            termDef: termDef,
            graphName: graphName,
            inheritedContextForNode: childInheritedContext,
          );
          continue;
        }

        if (termDef?.hasContainer('@index') == true) {
          _addIndexContainerTriples(
            subject,
            predicate,
            value,
            triples,
            valueContext,
            termDef: termDef,
            graphName: graphName,
            inheritedContextForNode: childInheritedContext,
          );
          continue;
        }

        if (termDef?.hasContainer('@language') == true) {
          _addLanguageContainerTriples(
            subject,
            predicate,
            value,
            triples,
            valueContext,
            termDef: termDef,
            graphName: graphName,
            inheritedContextForNode: childInheritedContext,
          );
          continue;
        }

        if (termDef?.typeMapping == rdfJsonDatatype) {
          // @type: @json — the entire value (including arrays) is a single
          // JSON literal; do not iterate array items.
          _addTripleForValue(subject, predicate, value, triples, valueContext,
              termDef: termDef,
              graphName: graphName,
              inheritedContextForNode: childInheritedContext);
        } else if (termDef?.hasContainer('@list') == true) {
          // @container: @list always represents values as an RDF collection,
          // including scalar values.
          _addListTriples(
              subject, predicate, value, triples, valueContext, termDef,
              graphName: graphName);
        } else if (value is List) {
          for (final item in value) {
            _addTripleForValue(subject, predicate, item, triples, valueContext,
                termDef: termDef,
                graphName: graphName,
                inheritedContextForNode: childInheritedContext);
          }
        } else {
          _addTripleForValue(subject, predicate, value, triples, valueContext,
              termDef: termDef,
              graphName: graphName,
              inheritedContextForNode: childInheritedContext);
        }
      }
    } finally {
      _contextBaseUri = previousContextBaseUri;
      _hasContextBase = previousHasContextBase;
    }
  }

  /// Create appropriate RDF term for a subject
  RdfSubject _createSubjectTerm(String subject) {
    if (subject.startsWith('_:')) {
      return _getOrCreateBlankNode(subject);
    } else {
      return _iriTermFactory(subject);
    }
  }

  /// Gets an existing BlankNodeTerm or creates a new one with consistent identity
  BlankNodeTerm _getOrCreateBlankNode(String label) {
    return _blankNodeCache.putIfAbsent(label, () {
      final blankNode = BlankNodeTerm();
      _log.fine('Created blank node for label $label: $blankNode');
      return blankNode;
    });
  }

  /// Get the effective base URI for resolving relative IRIs.
  String? _getEffectiveBaseUri() {
    if (_hasContextBase) {
      return _contextBaseUri;
    }
    return _baseUri;
  }

  /// Get the subject identifier from a node.
  ///
  /// Per the JSON-LD spec, `@id` values are NOT expanded through plain term
  /// definitions — only compact IRIs (prefix:suffix) and blank node
  /// identifiers (_:label) are expanded. Relative IRIs are resolved against
  /// Like [_getSubjectId] but also checks flattened entries for @id
  /// that may come from @nest properties.
  String? _getSubjectIdFromEntries(
    JsonObject node,
    List<_ScopedNodeEntry> entries,
    JsonLdContext context,
  ) {
    // First check the node directly (handles canonical @id).
    final directId = _getKeywordValue(node, '@id', context);
    if (directId != null) {
      return _getSubjectId(node, context);
    }
    // Check flattened entries for @id from @nest.
    for (final entry in entries) {
      final resolved = _resolveKeywordAlias(entry.key, entry.context);
      if (resolved == '@id') {
        final id = entry.value;
        if (id is! String) {
          throw RdfSyntaxException('@id value must be a string',
              format: _format);
        }
        if (id.startsWith('@') &&
            _isKeywordLikeAtForm(id) &&
            !jsonLdKeywords.contains(id)) {
          return '_:b${node.hashCode.abs()}';
        }
        final expandedId = _expandIriForId(id, entry.context);
        if (!expandedId.startsWith('_:')) {
          return _tryResolveIriFromContext(expandedId, entry.context);
        }
        return expandedId;
      }
    }
    return '_:b${node.hashCode.abs()}';
  }

  /// Peeks into an object's @nest entries to find an @id, returning the
  /// resolved subject term if found. Returns null if no @id is found.
  RdfObject? _peekSubjectFromNest(JsonObject node, JsonLdContext context) {
    final entries = _flattenNestEntries(node, context);
    for (final entry in entries) {
      final resolved = _resolveKeywordAlias(entry.key, entry.context);
      if (resolved == '@id' && entry.value is String) {
        final id = entry.value as String;
        final expanded = _expandIriForId(id, entry.context);
        final resolvedIri = expanded.startsWith('_:')
            ? expanded
            : _tryResolveIriFromContext(expanded, entry.context);
        if (resolvedIri == null) return null;
        return _tryCreateSubjectTerm(resolvedIri);
      }
    }
    return null;
  }

  /// Returns the subject identifier for a node, resolving relative IRIs against
  /// the effective base.
  String? _getSubjectId(JsonObject node, JsonLdContext context) {
    final id = _getKeywordValue(node, '@id', context);
    if (id != null) {
      if (id is! String) {
        throw RdfSyntaxException('@id value must be a string', format: _format);
      }

      // Keyword-like @-forms that aren't actual keywords are ignored in @id.
      if (id.startsWith('@') &&
          _isKeywordLikeAtForm(id) &&
          !jsonLdKeywords.contains(id)) {
        return '_:b${node.hashCode.abs()}';
      }

      final expandedId = _expandIriForId(id, context);

      if (!expandedId.startsWith('_:')) {
        return _tryResolveIriFromContext(expandedId, context);
      }

      return expandedId;
    }

    return '_:b${node.hashCode.abs()}';
  }

  /// Expands an IRI used as `@id` value.
  ///
  /// Unlike [_expandPrefixedIri], this does NOT resolve plain terms — only
  /// compact IRIs (prefix:suffix) and blank node identifiers.
  String _expandIriForId(String iri, JsonLdContext context) {
    if (iri.startsWith('http://') ||
        iri.startsWith('https://') ||
        iri.startsWith('_:')) {
      return iri;
    }

    // Only expand compact IRIs (containing ':')
    if (iri.contains(':')) {
      final colonIndex = iri.indexOf(':');
      final prefix = iri.substring(0, colonIndex);
      final localName = iri.substring(colonIndex + 1);
      final prefixDef = context.terms[prefix];
      if (prefixDef != null &&
          !prefixDef.isNullMapping &&
          prefixDef.iri != null &&
          canUseAsPrefixStrict(prefixDef, processingMode: _processingMode)) {
        return '${prefixDef.iri}$localName';
      }
    }

    // Plain terms are NOT expanded for @id values — return as-is
    return iri;
  }

  /// Expand a prefixed IRI using the active context's term definitions.
  String _expandPrefixedIri(String iri, JsonLdContext context) {
    if (iri.startsWith('http://') ||
        iri.startsWith('https://') ||
        iri.startsWith('_:')) {
      return iri;
    }

    // Handle prefixed name (e.g., foaf:name)
    if (iri.contains(':')) {
      final colonIndex = iri.indexOf(':');
      final prefix = iri.substring(0, colonIndex);
      final localName = iri.substring(colonIndex + 1);
      final prefixDef = context.terms[prefix];
      if (prefixDef != null &&
          !prefixDef.isNullMapping &&
          prefixDef.iri != null &&
          canUseAsPrefixStrict(prefixDef, processingMode: _processingMode)) {
        return '${prefixDef.iri}$localName';
      }
    }

    // Direct match in terms
    final termDef = context.terms[iri];
    if (termDef != null && !termDef.isNullMapping && termDef.iri != null) {
      return termDef.iri!;
    }

    _log.warning('Could not expand prefixed IRI: $iri');
    return iri;
  }

  /// Process @type value and add rdf:type triples.
  void _processType(
    RdfSubject subject,
    JsonValue typeValue,
    List<Quad> quads,
    JsonLdContext context, {
    RdfGraphName? graphName,
  }) {
    final typePredicate = _iriTermFactory(_rdfType);

    if (typeValue is List) {
      for (final type in typeValue) {
        if (type is String) {
          final expandedType = _expandTypedIriValue(type, context);
          final RdfObject? typeTerm;
          if (expandedType.startsWith('_:')) {
            typeTerm = _getOrCreateBlankNode(expandedType);
          } else {
            typeTerm = _tryCreateIriTerm(expandedType);
          }
          if (typeTerm == null) {
            continue;
          }
          quads.add(Quad(subject, typePredicate, typeTerm, graphName));
          _log.fine(
            'Added type triple: $subject -> $typePredicate -> $expandedType',
          );
        }
      }
    } else if (typeValue is String) {
      final expandedType = _expandTypedIriValue(typeValue, context);
      final RdfObject? typeTerm;
      if (expandedType.startsWith('_:')) {
        typeTerm = _getOrCreateBlankNode(expandedType);
      } else {
        typeTerm = _tryCreateIriTerm(expandedType);
      }
      if (typeTerm == null) {
        return;
      }
      quads.add(Quad(subject, typePredicate, typeTerm, graphName));
      _log.fine(
        'Added type triple: $subject -> $typePredicate -> $expandedType',
      );
    } else if (typeValue is JsonObject) {
      if (typeValue.containsKey('@id')) {
        final typeId = typeValue['@id'];
        if (typeId is String) {
          final expandedType = _expandTypedIriValue(typeId, context);
          final typeTerm = _tryCreateIriTerm(expandedType);
          if (typeTerm == null) {
            return;
          }
          quads.add(Quad(subject, typePredicate, typeTerm, graphName));
          _log.fine(
            'Added type triple from object: $subject -> $typePredicate -> $expandedType',
          );
        }
      }
    } else {
      throw RdfSyntaxException('invalid type value', format: _format);
    }
  }

  String _expandTypedIriValue(String value, JsonLdContext context) {
    final expanded = _expandPredicate(value, context);
    if (expanded.startsWith('_:') || _looksLikeAbsoluteIri(expanded)) {
      return expanded;
    }
    final base = _getEffectiveBaseFromContext(context);
    if (base == null) {
      return expanded;
    }
    return resolveIri(expanded, base);
  }

  /// Add a triple for a given value, respecting type coercion and
  /// default language from the active context.
  void _addTripleForValue(
    RdfSubject subject,
    RdfPredicate predicate,
    JsonValue value,
    List<Quad> triples,
    JsonLdContext context, {
    TermDefinition? termDef,
    RdfGraphName? graphName,
    JsonLdContext? inheritedContextForNode,
  }) {
    // Handle @type: @json — any value (including null) becomes an rdf:JSON literal.
    if (termDef?.typeMapping == rdfJsonDatatype) {
      triples.add(
        Quad(
          subject,
          predicate,
          LiteralTerm(
            _canonicalizeJsonLiteralValue(value),
            datatype: _iriTermFactory(rdfJsonDatatype),
          ),
          graphName,
        ),
      );
      return;
    }

    // Handle @type: @none — native types keep their natural RDF form,
    // string values become plain literals (no language, no vocab expansion).
    if (termDef?.typeMapping == '@none') {
      if (value is String) {
        triples.add(
            Quad(subject, predicate, LiteralTerm.string(value), graphName));
        return;
      }
      // For non-string natives, fall through to normal native handling below.
    }

    if (value is String) {
      // Type coercion: @type → @id
      // Only compact IRIs (prefix:suffix) are expanded, plain terms are NOT.
      if (termDef?.typeMapping == '@id') {
        final expanded = _expandIriForId(value, context);
        final String resolved;
        if (expanded.startsWith('_:') || _looksLikeAbsoluteIri(expanded)) {
          resolved = expanded;
        } else {
          final base = _getEffectiveBaseFromContext(context);
          if (base == null) {
            if (_skipInvalidRdfTerms) return;
            throw RdfSyntaxException(
              'Cannot resolve relative IRI without base: $expanded',
              format: _format,
            );
          }
          try {
            resolved = resolveIri(expanded, base);
          } catch (_) {
            if (_skipInvalidRdfTerms) return;
            rethrow;
          }
        }
        final RdfObject? objectTerm;
        if (resolved.startsWith('_:')) {
          objectTerm = _getOrCreateBlankNode(resolved);
        } else {
          objectTerm = _tryCreateIriTermFromAbsolute(resolved);
        }
        if (objectTerm == null) {
          return;
        }
        triples.add(Quad(subject, predicate, objectTerm, graphName));
        return;
      }
      // Type coercion: @type → @vocab
      if (termDef?.typeMapping == '@vocab') {
        final expanded = _expandTypedIriValue(value, context);
        final objectTerm = _tryCreateIriTermFromAbsolute(expanded);
        if (objectTerm == null) {
          return;
        }
        triples.add(Quad(subject, predicate, objectTerm, graphName));
        return;
      }

      // Without explicit type coercion, string values are always literals
      // (JSON-LD spec: compact IRIs in values are NOT auto-expanded)
      final literal = _createLiteral(value, context, termDef);
      if (literal == null) {
        return;
      }
      triples.add(Quad(subject, predicate, literal, graphName));
      _log.fine('Added literal triple: $subject -> $predicate -> "$value"');
    } else if (value is num) {
      const xsdDouble = 'http://www.w3.org/2001/XMLSchema#double';

      // Custom datatype coercion for numeric values
      if (termDef?.typeMapping != null &&
          termDef!.typeMapping != '@id' &&
          termDef.typeMapping != '@vocab' &&
          termDef.typeMapping != '@none') {
        final expandedDatatype =
            _expandPrefixedIri(termDef.typeMapping!, context);
        final datatype = _iriTermFactory(expandedDatatype);
        // When coerced to xsd:double, use canonical double form even for ints.
        // When coerced to xsd:integer, doubles use canonical double form.
        // For other datatypes, stringify the native value.
        final String lexical;
        if (datatype.value == xsdDouble) {
          lexical = _canonicalDouble(value.toDouble());
        } else if (value is int) {
          lexical = value.toString();
        } else {
          lexical = _canonicalDouble(value.toDouble());
        }
        triples.add(
          Quad(subject, predicate, LiteralTerm(lexical, datatype: datatype),
              graphName),
        );
        return;
      }

      // Determine if the value should be xsd:integer or xsd:double.
      // Dart may parse JSON integers as int or double depending on magnitude.
      // Whole-valued doubles within safe integer range are treated as integers.
      final double dv = value.toDouble();
      final bool isWholeNumber = dv == dv.truncateToDouble() &&
          !dv.isNaN &&
          !dv.isInfinite &&
          dv.abs() < 1e21;
      final bool treatAsInteger = value is int || isWholeNumber;
      final fallbackDatatype = treatAsInteger
          ? 'http://www.w3.org/2001/XMLSchema#integer'
          : xsdDouble;
      final datatype = _iriTermFactory(fallbackDatatype);

      final lexical =
          treatAsInteger ? dv.toInt().toString() : _canonicalDouble(dv);

      triples.add(
        Quad(
          subject,
          predicate,
          LiteralTerm(lexical, datatype: datatype),
          graphName,
        ),
      );
      _log.fine(
        'Added numeric literal triple: $subject -> $predicate -> $value',
      );
    } else if (value is bool) {
      // Custom datatype coercion for boolean values
      if (termDef?.typeMapping != null &&
          termDef!.typeMapping != '@id' &&
          termDef.typeMapping != '@vocab' &&
          termDef.typeMapping != '@none') {
        final expandedDatatype =
            _expandPrefixedIri(termDef.typeMapping!, context);
        final datatype = _iriTermFactory(expandedDatatype);
        triples.add(
          Quad(subject, predicate,
              LiteralTerm(value.toString(), datatype: datatype), graphName),
        );
        return;
      }
      triples.add(
        Quad(
          subject,
          predicate,
          LiteralTerm.typed(value.toString(), 'boolean'),
          graphName,
        ),
      );
      _log.fine(
        'Added boolean literal triple: $subject -> $predicate -> $value',
      );
    } else if (value is JsonObject) {
      value = _canonicalizeAliasedKeywords(value, context);

      _validateObjectValueShape(value, context);

      // Handle @list
      if (value.containsKey('@list')) {
        _addListTriples(
            subject, predicate, value['@list'], triples, context, termDef,
            graphName: graphName);
        return;
      }

      // Handle @set (just unwrap as array)
      if (value.containsKey('@set')) {
        final items = value['@set'];
        if (items is List) {
          for (final item in items) {
            _addTripleForValue(subject, predicate, item, triples, context,
                termDef: termDef,
                graphName: graphName,
                inheritedContextForNode: inheritedContextForNode ?? context);
          }
        }
        return;
      }

      if (value.containsKey('@id')) {
        // Reference to another resource
        final objectId = value['@id'] as String;

        // Keyword-like @-forms that aren't actual keywords are dropped.
        if (objectId.startsWith('@') &&
            _isKeywordLikeAtForm(objectId) &&
            !jsonLdKeywords.contains(objectId)) {
          return;
        }

        final hasNestedProperties = value.keys.any((k) => !k.startsWith('@'));
        final idContext = hasNestedProperties
            ? _applyTypeScopedContexts(
                value,
                _extractContext(
                  value,
                  baseContext: inheritedContextForNode ?? context,
                ),
              )
            : context;

        // Temporarily update instance base state for @id resolution when the
        // child node has its own @context that changes the base.
        final previousContextBaseUri = _contextBaseUri;
        final previousHasContextBase = _hasContextBase;
        if (idContext.hasBase) {
          if (idContext.base != null) {
            final baseValue = idContext.base!;
            _contextBaseUri = _looksLikeAbsoluteIri(baseValue)
                ? baseValue
                : resolveIri(baseValue, previousContextBaseUri ?? _baseUri);
          } else {
            _contextBaseUri = null;
          }
          _hasContextBase = true;
        } else if (value.containsKey('@context') && value['@context'] == null) {
          _contextBaseUri = null;
          _hasContextBase = false;
        }

        // @id values do NOT expand through plain terms
        final expandedIri = _expandIriForId(objectId, idContext);
        final resolvedIri = expandedIri.startsWith('_:')
            ? expandedIri
            : _tryResolveIriFromContext(expandedIri, idContext);
        // Restore base state
        _contextBaseUri = previousContextBaseUri;
        _hasContextBase = previousHasContextBase;
        if (resolvedIri == null) return;
        final RdfObject? objectTerm = resolvedIri.startsWith('_:')
            ? _getOrCreateBlankNode(resolvedIri)
            : _tryCreateIriTermFromAbsolute(resolvedIri);
        if (objectTerm == null) {
          return;
        }

        triples.add(Quad(subject, predicate, objectTerm, graphName));
        _log.fine(
          'Added object reference triple: $subject -> $predicate -> $resolvedIri',
        );

        if (!hasNestedProperties &&
            value.containsKey('@type') &&
            objectTerm is RdfSubject) {
          _processType(
            objectTerm,
            value['@type'],
            triples,
            idContext,
            graphName: graphName,
          );
        }

        // If the object has more properties, process it recursively
        if (hasNestedProperties) {
          _processNode(
            value,
            triples,
            graphName: graphName,
            inheritedContext: inheritedContextForNode ?? context,
          );
        }
      } else if (value.containsKey('@value')) {
        // Resolve the @type value: handle @json keyword and aliases.
        final rawType = value['@type'];
        final resolvedType = rawType is String
            ? _resolveKeywordAlias(rawType, context)
            : rawType;
        final isJsonType =
            resolvedType == '@json' || resolvedType == rdfJsonDatatype;
        if (value['@value'] == null && !isJsonType) {
          return;
        }

        // Typed or language-tagged literal
        final rawLiteralValue = value['@value'];
        final literalValue = rawLiteralValue.toString();
        final direction = _extractDirection(value);
        final hasLanguageKeyword = value.containsKey('@language');
        final language = _extractLanguage(value);
        LiteralTerm objectTerm;

        if (value.containsKey('@type')) {
          final typeIri = value['@type'] as String;
          final resolvedTypeIri = _resolveKeywordAlias(typeIri, context);
          if (resolvedTypeIri == '@json' ||
              resolvedTypeIri == rdfJsonDatatype) {
            objectTerm = LiteralTerm(
              _canonicalizeJsonLiteralValue(rawLiteralValue),
              datatype: _iriTermFactory(rdfJsonDatatype),
            );
          } else {
            final expandedType = _expandTypedIriValue(typeIri, context);
            if (expandedType == rdfJsonDatatype) {
              objectTerm = LiteralTerm(
                _canonicalizeJsonLiteralValue(rawLiteralValue),
                datatype: _iriTermFactory(rdfJsonDatatype),
              );
            } else {
              objectTerm = LiteralTerm(literalValue,
                  datatype: _iriTermFactory(expandedType));
            }
          }
        } else if (direction != null && _rdfDirection == 'compound-literal') {
          _addCompoundDirectionLiteral(
            subject,
            predicate,
            literalValue,
            direction,
            triples,
            graphName: graphName,
            language: language,
          );
          return;
        } else if (direction != null && _rdfDirection == 'i18n-datatype') {
          objectTerm = LiteralTerm(
            literalValue,
            datatype: _iriTermFactory(_createI18nDatatype(language, direction)),
          );
        } else if (hasLanguageKeyword) {
          if (language == null) {
            return;
          }
          final languageLiteral =
              _createLanguageLiteralOrNull(literalValue, language);
          if (languageLiteral == null) {
            return;
          }
          objectTerm = languageLiteral;
        } else if (rawLiteralValue is bool) {
          objectTerm = LiteralTerm.typed(rawLiteralValue.toString(), 'boolean');
        } else if (rawLiteralValue is int) {
          objectTerm = LiteralTerm.typed(rawLiteralValue.toString(), 'integer');
        } else if (rawLiteralValue is num) {
          objectTerm = LiteralTerm.typed(
            _canonicalDouble(rawLiteralValue.toDouble()),
            'double',
          );
        } else {
          objectTerm = LiteralTerm.string(literalValue);
        }

        triples.add(Quad(subject, predicate, objectTerm, graphName));
        _log.fine(
          'Added complex literal triple: $subject -> $predicate -> $objectTerm',
        );
      } else if (value.keys.every((k) => k.startsWith('@'))) {
        const ignorableKeywordOnly = {'@language', '@direction', '@index'};
        if (value.keys.every(ignorableKeywordOnly.contains)) {
          // Objects carrying only metadata keywords and no value/node payload
          // do not produce RDF triples in toRdf expansion.
          return;
        }

        const nodeKeywords = {
          '@id',
          '@type',
          '@graph',
          '@included',
          '@reverse',
          '@nest',
        };
        if (value.keys.any(nodeKeywords.contains)) {
          // Use inherited context for nested node objects — this strips
          // non-propagating type-scoped contexts while preserving
          // property-scoped terms from nest flattening.
          final nodeContext = inheritedContextForNode ?? context;
          final nestSubject = _peekSubjectFromNest(value, nodeContext);
          if (nestSubject != null) {
            triples.add(Quad(subject, predicate, nestSubject, graphName));
            _processNode(
              value,
              triples,
              graphName: graphName,
              inheritedContext: nodeContext,
            );
          } else {
            final blankNodeId = '_:b${value.hashCode.abs()}';
            final blankNode = _getOrCreateBlankNode(blankNodeId);
            triples.add(Quad(subject, predicate, blankNode, graphName));
            final recursiveNode = JsonObject.from(value);
            recursiveNode['@id'] = blankNodeId;
            _processNode(
              recursiveNode,
              triples,
              graphName: graphName,
              inheritedContext: nodeContext,
            );
          }
          return;
        }
      } else {
        // Use inherited context for nested node objects.
        final nodeContext = inheritedContextForNode ?? context;
        final nestSubject = _peekSubjectFromNest(value, nodeContext);
        if (nestSubject != null) {
          triples.add(Quad(subject, predicate, nestSubject, graphName));
          _processNode(
            value,
            triples,
            graphName: graphName,
            inheritedContext: nodeContext,
          );
        } else {
          // Blank node
          final blankNodeId = '_:b${value.hashCode.abs()}';
          final blankNode = _getOrCreateBlankNode(blankNodeId);

          triples.add(Quad(subject, predicate, blankNode, graphName));
          _log.fine(
            'Added blank node triple: $subject -> $predicate -> $blankNodeId',
          );

          // Process the blank node recursively
          value['@id'] = blankNodeId;
          _processNode(
            value,
            triples,
            graphName: graphName,
            inheritedContext: nodeContext,
          );
        }
      }
    }
  }

  void _validateObjectValueShape(JsonObject value, [JsonLdContext? context]) {
    if (value.containsKey('@set')) {
      if (value.length != 1) {
        throw RdfSyntaxException('invalid set or list object', format: _format);
      }
      return;
    }

    if (value.containsKey('@list')) {
      final allowedListKeys = {'@list', '@index'};
      if (value.keys.any((key) => !allowedListKeys.contains(key))) {
        throw RdfSyntaxException('invalid set or list object', format: _format);
      }
      return;
    }

    if (!value.containsKey('@value')) {
      return;
    }

    const allowedValueKeys = {
      '@value',
      '@type',
      '@language',
      '@direction',
      '@index'
    };
    if (value.keys.any((key) => !allowedValueKeys.contains(key))) {
      throw RdfSyntaxException('invalid value object', format: _format);
    }

    final rawValue = value['@value'];
    final rawType = value['@type'];
    final resolvedType = (rawType is String && context != null)
        ? _resolveKeywordAlias(rawType, context)
        : rawType;
    final isJsonTypedValue =
        resolvedType == '@json' || resolvedType == rdfJsonDatatype;

    if ((rawValue is JsonObject || rawValue is JsonArray) &&
        !isJsonTypedValue) {
      throw RdfSyntaxException('invalid value object value', format: _format);
    }

    if (value.containsKey('@language') && value.containsKey('@type')) {
      throw RdfSyntaxException('invalid value object', format: _format);
    }

    if (value.containsKey('@language') && rawValue is! String) {
      throw RdfSyntaxException('invalid language-tagged value',
          format: _format);
    }

    if (value.containsKey('@type')) {
      final typeValue = value['@type'];
      if (typeValue != null && typeValue is! String) {
        throw RdfSyntaxException('invalid typed value', format: _format);
      }
      if (typeValue == '@json' && _processingMode == 'json-ld-1.0') {
        throw RdfSyntaxException('invalid type mapping', format: _format);
      }
      // In compacted form, @value can be bool/num with explicit @type
      // (it gets stringified when creating the literal).
      if (rawValue is! String &&
          rawValue != null &&
          !isJsonTypedValue &&
          rawValue is! bool &&
          rawValue is! num) {
        throw RdfSyntaxException('invalid typed value', format: _format);
      }
    }

    if (value.containsKey('@index')) {
      final indexValue = value['@index'];
      if (indexValue != null && indexValue is! String) {
        throw RdfSyntaxException('invalid @index value', format: _format);
      }
    }
  }

  String? _extractDirection(JsonObject valueObject) {
    if (!valueObject.containsKey('@direction')) {
      return null;
    }

    final directionValue = valueObject['@direction'];
    if (directionValue is! String ||
        (directionValue != 'ltr' && directionValue != 'rtl')) {
      throw RdfSyntaxException(
        '@direction must be one of ltr or rtl',
        format: _format,
      );
    }

    return directionValue;
  }

  String? _extractLanguage(JsonObject valueObject) {
    if (!valueObject.containsKey('@language')) {
      return null;
    }

    final languageValue = valueObject['@language'];
    if (languageValue is! String) {
      throw RdfSyntaxException(
        '@language value must be a string',
        format: _format,
      );
    }
    final normalized = languageValue.toLowerCase();
    if (!_isValidLanguageTag(normalized)) {
      if (_skipInvalidRdfTerms) {
        return null;
      }
      throw RdfSyntaxException('invalid language-tagged value',
          format: _format);
    }

    return normalized;
  }

  String _createI18nDatatype(String? language, String direction) {
    final suffix = language == null || language.isEmpty
        ? '_$direction'
        : '${language.toLowerCase()}_$direction';
    return '$_i18nDatatypeBase$suffix';
  }

  void _addCompoundDirectionLiteral(
    RdfSubject subject,
    RdfPredicate predicate,
    String literalValue,
    String direction,
    List<Quad> triples, {
    RdfGraphName? graphName,
    String? language,
  }) {
    final compoundNode = BlankNodeTerm();
    final rdfValue = _iriTermFactory(_rdfValuePredicate);
    final rdfDirection = _iriTermFactory(_rdfDirectionPredicate);
    final rdfLanguage = _iriTermFactory(_rdfLanguagePredicate);

    triples.add(Quad(subject, predicate, compoundNode, graphName));
    triples.add(
      Quad(
          compoundNode, rdfDirection, LiteralTerm.string(direction), graphName),
    );
    triples.add(
      Quad(compoundNode, rdfValue, LiteralTerm.string(literalValue), graphName),
    );
    if (language != null) {
      triples.add(
        Quad(
            compoundNode, rdfLanguage, LiteralTerm.string(language), graphName),
      );
    }
  }

  String _resolveKeywordAlias(String key, JsonLdContext context) {
    final directAlias = context.keywordAliases[key];
    if (directAlias != null) {
      return directAlias;
    }

    final termDef = context.terms[key];
    if (termDef != null &&
        !termDef.isNullMapping &&
        termDef.iri != null &&
        jsonLdKeywords.contains(termDef.iri)) {
      return termDef.iri!;
    }

    return key;
  }

  bool _isKeywordKey(String key, JsonLdContext context, String keyword) {
    return _resolveKeywordAlias(key, context) == keyword;
  }

  JsonValue _getKeywordValue(
    JsonObject node,
    String keyword,
    JsonLdContext context,
  ) {
    node = _canonicalizeAliasedKeywords(node, context);

    if (node.containsKey(keyword)) {
      return node[keyword];
    }

    for (final entry in context.keywordAliases.entries) {
      if (entry.value == keyword && node.containsKey(entry.key)) {
        return node[entry.key];
      }
    }

    return null;
  }

  JsonLdContext _applyTypeScopedContexts(
    JsonObject node,
    JsonLdContext context,
  ) {
    final typeValue = _getKeywordValue(node, '@type', context);
    if (typeValue == null) return context;

    final typeTerms = <String>[];
    if (typeValue is String) {
      typeTerms.add(typeValue);
    } else if (typeValue is JsonArray) {
      for (final item in typeValue) {
        if (item is String) typeTerms.add(item);
      }
    }

    var merged = context;
    typeTerms.sort((a, b) {
      final aExpanded = _expandPredicate(a, merged);
      final bExpanded = _expandPredicate(b, merged);
      return aExpanded.compareTo(bExpanded);
    });

    if (_contextApplicationDepth >= _maxContextApplicationDepth) {
      return context;
    }

    var applied = false;
    for (final typeTerm in typeTerms) {
      final termDef = context.terms[typeTerm];
      if (termDef != null && termDef.hasLocalContext) {
        _contextApplicationDepth++;
        try {
          merged = _mergeContextDefinition(
            merged,
            termDef.localContext,
            seenContextIris: <String>{},
            allowProtectedOverride: true,
          );
          applied = true;
        } finally {
          _contextApplicationDepth--;
        }
      }
    }

    // Type-scoped contexts default to propagate: false per JSON-LD 1.1 spec.
    // This ensures they apply to the current node but not to nested nodes.
    if (applied && !merged.hasPropagate) {
      merged = merged.copyWith(
        propagate: false,
        hasPropagate: true,
        nonPropagatedParent: context,
      );
    }

    return merged;
  }

  JsonLdContext _applyTermScopedContext(
    JsonLdContext context,
    TermDefinition? termDef,
  ) {
    if (termDef == null || !termDef.hasLocalContext) {
      return context;
    }
    if (_contextApplicationDepth >= _maxContextApplicationDepth) {
      return context;
    }
    _contextApplicationDepth++;
    try {
      return _mergeContextDefinition(
        context,
        termDef.localContext,
        seenContextIris: <String>{},
        allowProtectedNullification: true,
        allowProtectedOverride: true,
      );
    } finally {
      _contextApplicationDepth--;
    }
  }

  List<_ScopedNodeEntry> _flattenNestEntries(
    JsonObject node,
    JsonLdContext context,
  ) {
    final entries = <_ScopedNodeEntry>[];

    void addFromNest(JsonValue nestValue, JsonLdContext nestContext) {
      if (nestValue is JsonObject) {
        // Validate: @value and @list are not allowed inside @nest objects.
        for (final nestedEntry in nestValue.entries) {
          final nestedResolved =
              _resolveKeywordAlias(nestedEntry.key, nestContext);
          if (nestedResolved == '@value' || nestedResolved == '@list') {
            throw RdfSyntaxException('invalid @nest value', format: _format);
          }
        }
        final nested = _flattenNestEntries(nestValue, nestContext);
        entries.addAll(nested);
      } else if (nestValue is JsonArray) {
        for (final item in nestValue) {
          addFromNest(item, nestContext);
        }
      } else {
        throw RdfSyntaxException('invalid @nest value', format: _format);
      }
    }

    for (final entry in node.entries) {
      final resolved = _resolveKeywordAlias(entry.key, context);
      final nestTermDef = context.terms[entry.key];
      final isNestTerm = resolved == '@nest' || nestTermDef?.iri == '@nest';
      if (isNestTerm) {
        final nestContext = _applyTermScopedContext(context, nestTermDef);
        addFromNest(entry.value, nestContext);
      } else {
        entries.add(_ScopedNodeEntry(entry.key, entry.value, context));
      }
    }

    return entries;
  }

  JsonObject _canonicalizeAliasedKeywords(
    JsonObject input,
    JsonLdContext context,
  ) {
    final normalized = JsonObject.from(input);
    final aliasKeysToRemove = <String>[];
    final aliasCountsForId = <int>[];
    var hasCanonicalId = false;
    for (final entry in input.entries) {
      final resolved = _resolveKeywordAlias(entry.key, context);
      if (!jsonLdKeywords.contains(resolved)) continue;
      // @nest aliases are handled by _flattenNestEntries; skip here to avoid
      // destructively merging multiple @nest entries into one key.
      if (resolved == '@nest') continue;
      // Skip entries where the key is already the canonical keyword
      if (entry.key == resolved) {
        if (resolved == '@id') {
          hasCanonicalId = true;
        }
        continue;
      }

      if (resolved == '@id') {
        aliasCountsForId.add(1);
      }

      if (normalized.containsKey(resolved)) {
        // @type values from multiple aliases are merged into an array.
        if (resolved == '@type') {
          final existing = normalized[resolved];
          final newValue = entry.value;
          final merged = <Object?>[
            if (existing is List) ...existing else existing,
            if (newValue is List) ...newValue else newValue,
          ];
          normalized[resolved] = merged;
        }
        // Other keywords: first one wins (already set).
      } else {
        normalized[resolved] = entry.value;
      }
      aliasKeysToRemove.add(entry.key);
    }

    // Only @id must not collide from multiple aliases.
    if (aliasCountsForId.length > 1 && !hasCanonicalId) {
      throw RdfSyntaxException('colliding keywords', format: _format);
    }

    for (final aliasKey in aliasKeysToRemove) {
      normalized.remove(aliasKey);
    }
    return normalized;
  }

  void _addGraphContainerTriples(
    RdfSubject subject,
    RdfPredicate predicate,
    JsonValue value,
    List<Quad> triples,
    JsonLdContext context, {
    TermDefinition? termDef,
    RdfGraphName? graphName,
    JsonLdContext? inheritedContextForNode,
  }) {
    final hasIdContainer = termDef?.hasContainer('@id') == true;
    final hasIndexContainer = termDef?.hasContainer('@index') == true;

    if (hasIdContainer && value is JsonObject) {
      for (final entry in value.entries) {
        final resolvedMapKey = _resolveKeywordAlias(entry.key, context);
        final isNoneKey = resolvedMapKey == '@none';

        RdfGraphName containerGraphName;
        if (isNoneKey) {
          containerGraphName = BlankNodeTerm();
        } else {
          final expanded = _expandPrefixedIri(entry.key, context);
          final resolved = expanded.startsWith('_:')
              ? expanded
              : _tryResolveIriFromContext(expanded, context);
          if (resolved == null) continue;
          final subjectTerm = _tryCreateSubjectTerm(resolved);
          if (subjectTerm is! RdfGraphName) {
            continue;
          }
          containerGraphName = subjectTerm;
        }

        triples.add(Quad(subject, predicate, containerGraphName, graphName));

        final graphValue = entry.value;
        final graphContent = graphValue is JsonObject
            ? (_getKeywordValue(graphValue, '@graph', context) ?? graphValue)
            : graphValue;
        _addGraphContainerContent(
            graphContent, triples, context, containerGraphName);
      }
      return;
    }

    if (hasIndexContainer && value is JsonObject) {
      final propertyValuedIndex = termDef?.indexMapping;
      for (final entry in value.entries) {
        final rawItems =
            entry.value is JsonArray ? entry.value as JsonArray : [entry.value];
        for (final rawItem in rawItems) {
          final containerGraphName = BlankNodeTerm();
          triples.add(Quad(subject, predicate, containerGraphName, graphName));

          // Emit property-valued index triple if @index maps to a property.
          if (propertyValuedIndex != null) {
            final expandedIndex =
                _expandPredicate(propertyValuedIndex, context);
            final indexPredicate = _tryCreateIriTerm(expandedIndex);
            if (indexPredicate != null) {
              triples.add(Quad(
                containerGraphName,
                indexPredicate,
                LiteralTerm.string(entry.key),
                graphName,
              ));
            }
          }

          final graphContent = rawItem is JsonObject
              ? (_getKeywordValue(rawItem, '@graph', context) ?? rawItem)
              : rawItem;
          _addGraphContainerContent(
            graphContent,
            triples,
            context,
            containerGraphName,
          );
        }
      }
      return;
    }

    final values = value is JsonArray ? value : [value];
    for (final rawItem in values) {
      if (rawItem is! JsonObject) {
        continue;
      }

      final item = rawItem;

      final itemContext = _extractContext(
        item,
        baseContext: inheritedContextForNode ?? context,
      );

      // For plain @container: @graph, always use a blank node as graph name.
      // The @id inside the value (if any) becomes the subject within the
      // named graph, not the graph name itself.
      final graphTerm = BlankNodeTerm();
      triples.add(Quad(subject, predicate, graphTerm, graphName));

      final graphContent = _getKeywordValue(item, '@graph', itemContext);
      if (graphContent != null) {
        // When value already has @graph, use a separate blank node for the
        // content graph (distinct from graphTerm in the default triple).
        final contentGraphName = BlankNodeTerm();
        _addGraphContainerContent(
          graphContent,
          triples,
          itemContext,
          contentGraphName,
        );
      } else {
        _extractTriples(
          item,
          itemContext,
          triples,
          graphName: graphTerm,
        );
      }
    }
  }

  void _addGraphContainerContent(
    JsonValue graphContainerValue,
    List<Quad> triples,
    JsonLdContext context,
    RdfGraphName graphName,
  ) {
    final values = graphContainerValue is JsonArray
        ? graphContainerValue
        : [graphContainerValue];

    for (final item in values) {
      if (item is! JsonObject) {
        continue;
      }
      if (_getKeywordValue(item, '@graph', context) != null) {
        _processNode(
          item,
          triples,
          graphName: graphName,
          inheritedContext: context,
        );
      } else {
        _extractTriples(
          item,
          context,
          triples,
          graphName: graphName,
        );
      }
    }
  }

  void _addIdContainerTriples(
    RdfSubject subject,
    RdfPredicate predicate,
    JsonValue value,
    List<Quad> triples,
    JsonLdContext context, {
    TermDefinition? termDef,
    RdfGraphName? graphName,
    JsonLdContext? inheritedContextForNode,
  }) {
    if (value is! JsonObject) {
      _addTripleForValue(
        subject,
        predicate,
        value,
        triples,
        context,
        termDef: termDef,
        graphName: graphName,
        inheritedContextForNode: inheritedContextForNode,
      );
      return;
    }

    for (final entry in value.entries) {
      final idIndex = entry.key;
      final containerValue = entry.value;
      final values =
          containerValue is JsonArray ? containerValue : [containerValue];

      final resolvedIdIndex = _resolveKeywordAlias(idIndex, context);
      final isNoneKey = resolvedIdIndex == '@none';

      for (final item in values) {
        JsonObject? expandedItem;
        if (item is JsonObject) {
          expandedItem = JsonObject.from(item);
        } else if (item is String) {
          final mapping = termDef?.typeMapping;
          if (mapping == '@id' || mapping == '@vocab') {
            final idValue = mapping == '@vocab'
                ? _expandTypedIriValue(item, context)
                : item;
            expandedItem = {'@id': idValue};
          } else {
            expandedItem = {'@value': item};
          }
        }

        if (expandedItem == null) {
          continue;
        }

        // Inject @id from map key unless key is @none (or alias of @none)
        if (!isNoneKey && !expandedItem.containsKey('@id')) {
          expandedItem['@id'] = idIndex;
        }

        _addTripleForValue(
          subject,
          predicate,
          expandedItem,
          triples,
          context,
          termDef: termDef,
          graphName: graphName,
          inheritedContextForNode: inheritedContextForNode,
        );
      }
    }
  }

  void _addTypeContainerTriples(
    RdfSubject subject,
    RdfPredicate predicate,
    JsonValue value,
    List<Quad> triples,
    JsonLdContext context, {
    TermDefinition? termDef,
    RdfGraphName? graphName,
    JsonLdContext? inheritedContextForNode,
  }) {
    if (value is! JsonObject) {
      _addTripleForValue(
        subject,
        predicate,
        value,
        triples,
        context,
        termDef: termDef,
        graphName: graphName,
        inheritedContextForNode: inheritedContextForNode,
      );
      return;
    }

    final baseContextForTypeScope = inheritedContextForNode ?? context;

    for (final entry in value.entries) {
      final typeIndex = entry.key;
      final containerValue = entry.value;
      final values =
          containerValue is JsonArray ? containerValue : [containerValue];

      var typeScopedContext = baseContextForTypeScope;
      final typeTermDef = baseContextForTypeScope.terms[typeIndex];
      if (typeTermDef != null && typeTermDef.hasLocalContext) {
        typeScopedContext = _mergeContextDefinition(
          baseContextForTypeScope,
          typeTermDef.localContext,
          seenContextIris: <String>{},
        );
      }

      for (final item in values) {
        JsonObject? expandedItem;
        if (item is JsonObject) {
          expandedItem = JsonObject.from(item);
        } else if (item is String) {
          final mapping = termDef?.typeMapping;
          if (mapping != null && mapping != '@id' && mapping != '@vocab') {
            throw RdfSyntaxException('invalid type mapping', format: _format);
          }
          final idValue = mapping == '@vocab'
              ? _expandTypedIriValue(item, typeScopedContext)
              : item;
          expandedItem = {'@id': idValue};
        }

        if (expandedItem == null) {
          continue;
        }

        // Only inject @type from map key if the key is not @none
        final resolvedTypeIndex =
            _resolveKeywordAlias(typeIndex, baseContextForTypeScope);
        final isNoneType = resolvedTypeIndex == '@none';

        if (!isNoneType) {
          final existingType = expandedItem['@type'];
          if (existingType == null) {
            expandedItem['@type'] = typeIndex;
          } else if (existingType is String) {
            expandedItem['@type'] = [existingType, typeIndex];
          } else if (existingType is JsonArray) {
            expandedItem['@type'] = [...existingType, typeIndex];
          }
        }

        _addTripleForValue(
          subject,
          predicate,
          expandedItem,
          triples,
          typeScopedContext,
          termDef: termDef,
          graphName: graphName,
          inheritedContextForNode: typeScopedContext,
        );
      }
    }
  }

  void _addIndexContainerTriples(
    RdfSubject subject,
    RdfPredicate predicate,
    JsonValue value,
    List<Quad> triples,
    JsonLdContext context, {
    TermDefinition? termDef,
    RdfGraphName? graphName,
    JsonLdContext? inheritedContextForNode,
  }) {
    if (value is! JsonObject) {
      if (value is List) {
        for (final item in value) {
          _addTripleForValue(subject, predicate, item, triples, context,
              termDef: termDef,
              graphName: graphName,
              inheritedContextForNode: inheritedContextForNode);
        }
      } else {
        _addTripleForValue(subject, predicate, value, triples, context,
            termDef: termDef,
            graphName: graphName,
            inheritedContextForNode: inheritedContextForNode);
      }
      return;
    }

    for (final entry in value.entries) {
      final propertyValuedIndex = termDef?.indexMapping;
      final containerValue = entry.value;
      final values =
          containerValue is JsonArray ? containerValue : [containerValue];
      for (final item in values) {
        final indexedItem = propertyValuedIndex == null
            ? item
            : _applyPropertyValuedIndex(
                item,
                indexKey: entry.key,
                indexProperty: propertyValuedIndex,
                termDef: termDef,
              );
        _addTripleForValue(
          subject,
          predicate,
          indexedItem,
          triples,
          context,
          termDef: termDef,
          graphName: graphName,
          inheritedContextForNode: inheritedContextForNode,
        );
      }
    }
  }

  JsonValue _applyPropertyValuedIndex(
    JsonValue item, {
    required String indexKey,
    required String indexProperty,
    TermDefinition? termDef,
  }) {
    if (indexKey == '@none') {
      return item;
    }

    if (item is JsonObject) {
      if (item.containsKey('@value')) {
        throw RdfSyntaxException('invalid value object', format: _format);
      }

      final expandedItem = JsonObject.from(item);
      final existingValue = expandedItem[indexProperty];
      if (existingValue == null) {
        expandedItem[indexProperty] = indexKey;
      } else if (existingValue is JsonArray) {
        expandedItem[indexProperty] = [...existingValue, indexKey];
      } else {
        expandedItem[indexProperty] = [existingValue, indexKey];
      }
      return expandedItem;
    }

    if (item is String) {
      if (termDef?.typeMapping == '@id' || termDef?.typeMapping == '@vocab') {
        return {'@id': item, indexProperty: indexKey};
      }
      throw RdfSyntaxException('invalid value object', format: _format);
    }

    throw RdfSyntaxException('invalid value object', format: _format);
  }

  void _addLanguageContainerTriples(
    RdfSubject subject,
    RdfPredicate predicate,
    JsonValue value,
    List<Quad> triples,
    JsonLdContext context, {
    TermDefinition? termDef,
    RdfGraphName? graphName,
    JsonLdContext? inheritedContextForNode,
  }) {
    if (value is! JsonObject) {
      // Non-map values fall through to standard value handling.
      // Arrays are iterated item by item.
      if (value is List) {
        for (final item in value) {
          _addTripleForValue(subject, predicate, item, triples, context,
              termDef: termDef,
              graphName: graphName,
              inheritedContextForNode: inheritedContextForNode);
        }
      } else {
        _addTripleForValue(subject, predicate, value, triples, context,
            termDef: termDef,
            graphName: graphName,
            inheritedContextForNode: inheritedContextForNode);
      }
      return;
    }

    for (final entry in value.entries) {
      final langKey = entry.key;
      final resolvedLangKey = _resolveKeywordAlias(langKey, context);
      final values =
          entry.value is JsonArray ? entry.value as JsonArray : [entry.value];

      for (final item in values) {
        if (item == null) {
          continue;
        }

        if (item is! String) {
          throw RdfSyntaxException('invalid language map value',
              format: _format);
        }

        final useLang = resolvedLangKey != '@none';
        final literal = useLang
            ? _createLanguageLiteralOrNull(item, langKey.toLowerCase())
            : LiteralTerm.string(item);
        if (literal == null) {
          continue;
        }
        triples.add(Quad(subject, predicate, literal, graphName));
      }
    }
  }

  IriTerm? _tryCreateIriTerm(String iri) {
    if (!_looksLikeAbsoluteIri(iri) || _hasMultipleFragmentDelimiters(iri)) {
      return null;
    }
    final cached = _iriTermCache[iri];
    if (cached != null) return cached;
    try {
      final term = _iriTermFactory(iri);
      _iriTermCache[iri] = term;
      return term;
    } catch (_) {
      return null;
    }
  }

  IriTerm? _tryCreateIriTermFromAbsolute(String iri) {
    try {
      return _iriTermFactory(iri);
    } catch (_) {
      if (_skipInvalidRdfTerms) {
        return null;
      }
      rethrow;
    }
  }

  // Delegate static helpers to shared JsonLdContextProcessor.
  bool _looksLikeAbsoluteIri(String value) =>
      JsonLdContextProcessor.looksLikeAbsoluteIri(value);

  static bool _isKeywordLikeAtForm(String value) =>
      JsonLdContextProcessor.isKeywordLikeAtForm(value);

  static bool _hasMultipleFragmentDelimiters(String iri) =>
      JsonLdContextProcessor.hasMultipleFragmentDelimiters(iri);

  String? _getEffectiveBaseFromContext(JsonLdContext context) {
    if (context.hasBase) {
      if (context.base == null) {
        return null;
      }
      final baseValue = context.base!;
      return _looksLikeAbsoluteIri(baseValue)
          ? baseValue
          : resolveIri(baseValue, _getEffectiveBaseUri());
    }
    return _getEffectiveBaseUri();
  }

  /// Resolves [iri] against the effective base from [context].
  /// Returns `null` if [iri] is relative and no base is available.
  String? _tryResolveIriFromContext(String iri, JsonLdContext context) {
    if (_looksLikeAbsoluteIri(iri) || iri.startsWith('_:')) return iri;
    final base = _getEffectiveBaseFromContext(context);
    if (base == null) return null;
    try {
      return resolveIri(iri, base);
    } catch (_) {
      return null;
    }
  }

  /// Creates a literal, applying per-term datatype coercion, per-term
  /// language, or default language from context as appropriate.
  LiteralTerm? _createLiteral(
      String value, JsonLdContext context, TermDefinition? termDef) {
    // Datatype coercion (other than @id/@vocab/@none, which are handled earlier)
    if (termDef?.typeMapping != null &&
        termDef!.typeMapping != '@id' &&
        termDef.typeMapping != '@vocab' &&
        termDef.typeMapping != '@none') {
      if (termDef.typeMapping == rdfJsonDatatype) {
        return LiteralTerm(
          _canonicalizeJsonLiteralValue(value),
          datatype: _iriTermFactory(rdfJsonDatatype),
        );
      }
      final datatypeIri = _expandTypedIriValue(termDef.typeMapping!, context);
      return LiteralTerm(value, datatype: _iriTermFactory(datatypeIri));
    }

    // @type: @none — always a plain string literal (no language tag)
    if (termDef?.typeMapping == '@none') {
      return LiteralTerm.string(value);
    }

    // Per-term language override
    if (termDef?.hasLanguage == true) {
      if (termDef!.language != null) {
        return _createLanguageLiteralOrNull(value, termDef.language!);
      } else {
        // @language: null — explicitly no language tag
        return LiteralTerm.string(value);
      }
    }

    // Default language from context
    if (context.language != null) {
      return _createLanguageLiteralOrNull(value, context.language!);
    }

    return LiteralTerm.string(value);
  }

  RdfSubject? _tryCreateSubjectTerm(String subject) {
    try {
      return _createSubjectTerm(subject);
    } catch (_) {
      if (_skipInvalidRdfTerms) {
        return null;
      }
      rethrow;
    }
  }

  LiteralTerm? _createLanguageLiteralOrNull(String value, String languageTag) {
    final normalized = languageTag.toLowerCase();
    if (!_isValidLanguageTag(normalized)) {
      if (_skipInvalidRdfTerms) {
        return null;
      }
      throw RdfSyntaxException('invalid language-tagged value',
          format: _format);
    }
    return LiteralTerm.withLanguage(value, normalized);
  }

  static bool _isValidLanguageTag(String lang) {
    return RegExp(r'^[A-Za-z]+(?:-[A-Za-z0-9]+)*$').hasMatch(lang);
  }

  /// Serializes a value as a JCS (RFC 8785) canonical JSON string for
  /// rdf:JSON literals.
  String _canonicalizeJsonLiteralValue(Object? value) {
    final buffer = StringBuffer();
    _writeJcsValue(buffer, value);
    return buffer.toString();
  }

  void _writeJcsValue(StringBuffer buffer, Object? value) {
    if (value == null) {
      buffer.write('null');
    } else if (value is bool) {
      buffer.write(value ? 'true' : 'false');
    } else if (value is num) {
      buffer.write(_jcsNumber(value));
    } else if (value is String) {
      buffer.write(jsonEncode(value));
    } else if (value is List) {
      buffer.write('[');
      for (var i = 0; i < value.length; i++) {
        if (i > 0) buffer.write(',');
        _writeJcsValue(buffer, value[i]);
      }
      buffer.write(']');
    } else if (value is Map) {
      final sortedKeys = value.keys.cast<String>().toList(growable: false)
        ..sort();
      buffer.write('{');
      var first = true;
      for (final key in sortedKeys) {
        if (!first) buffer.write(',');
        first = false;
        buffer.write(jsonEncode(key));
        buffer.write(':');
        _writeJcsValue(buffer, value[key]);
      }
      buffer.write('}');
    }
  }

  /// JCS number serialization (RFC 8785 / ES6 Number::toString).
  /// Whole-valued doubles become integers; otherwise use shortest
  /// representation matching ES6 `Number.prototype.toString()`.
  static String _jcsNumber(num value) {
    if (value is int) return value.toString();
    final d = value.toDouble();
    if (d.isNaN || d.isInfinite) return 'null';
    if (d == 0.0) return '0';
    // If the double is a whole number, serialize without fractional part.
    if (d == d.truncateToDouble() && d.abs() < 1e21) {
      return d.toInt().toString();
    }
    // Use Dart's default double toString which matches ES6 for most values.
    return d.toString();
  }

  /// Creates an RDF collection (rdf:first/rdf:rest chain) for `@list` or
  /// `@container: "@list"` values.
  void _addListTriples(
    RdfSubject subject,
    RdfPredicate predicate,
    JsonValue listValue,
    List<Quad> triples,
    JsonLdContext context,
    TermDefinition? termDef, {
    RdfGraphName? graphName,
  }) {
    final JsonArray rawItems;
    if (listValue is JsonObject && listValue.containsKey('@list')) {
      final nestedList = listValue['@list'];
      rawItems = nestedList is List ? nestedList : [nestedList];
    } else {
      rawItems = listValue is List ? listValue : [listValue];
    }
    final items = <JsonValue>[];
    for (final item in rawItems) {
      if (item == null) {
        continue;
      }
      if (item is JsonObject && item.containsKey('@list')) {
        if (_processingMode == 'json-ld-1.0') {
          throw RdfSyntaxException('list of lists', format: _format);
        }
        // JSON-LD 1.1 allows nested lists — wrap as a sub-list value.
        items.add(item);
        continue;
      }
      if (item is List) {
        if (_processingMode == 'json-ld-1.0') {
          throw RdfSyntaxException('list of lists', format: _format);
        }
        // Array inside a coerced @list becomes a nested list.
        items.add({'@list': item});
        continue;
      }
      if (item is JsonObject) {
        final normalized = _canonicalizeAliasedKeywords(item, context);
        if (normalized.containsKey('@value') && normalized['@value'] == null) {
          continue;
        }
      }
      items.add(item);
    }
    final rdfFirst = _iriTermFactory(_rdfFirst);
    final rdfRest = _iriTermFactory(_rdfRest);
    final rdfNil = _iriTermFactory(_rdfNil);

    if (items.isEmpty) {
      triples.add(Quad(subject, predicate, rdfNil, graphName));
      return;
    }

    BlankNodeTerm? firstNode;
    BlankNodeTerm? currentNode;

    for (var i = 0; i < items.length; i++) {
      final newNode = BlankNodeTerm();

      if (i == 0) {
        firstNode = newNode;
      } else {
        triples.add(Quad(currentNode!, rdfRest, newNode, graphName));
      }

      currentNode = newNode;

      _addTripleForValue(currentNode, rdfFirst, items[i], triples, context,
          termDef: termDef, graphName: graphName);
    }

    // Close the list with rdf:nil
    triples.add(Quad(currentNode!, rdfRest, rdfNil, graphName));

    // Link the subject to the head of the list
    triples.add(Quad(subject, predicate, firstNode!, graphName));
  }

  /// Processes a `@reverse` keyword in a node body.
  void _processReverse(
    RdfSubject subject,
    JsonValue reverseValue,
    List<Quad> triples,
    JsonLdContext context, {
    RdfGraphName? graphName,
  }) {
    if (reverseValue is! JsonObject) {
      throw RdfSyntaxException('invalid @reverse value', format: _format);
    }

    for (final entry in reverseValue.entries) {
      final resolvedKey = _resolveKeywordAlias(entry.key, context);
      // @id is not allowed inside @reverse
      if (resolvedKey == '@id') {
        throw RdfSyntaxException('invalid reverse property map',
            format: _format);
      }
      // Skip other keywords inside @reverse
      if (resolvedKey.startsWith('@') && jsonLdKeywords.contains(resolvedKey)) {
        continue;
      }

      final termDef = context.terms[entry.key];
      final predicateStr = _expandPredicate(entry.key, context);
      final predicate = _tryCreateIriTermFromAbsolute(predicateStr);
      if (predicate == null) {
        continue;
      }

      // Check if the term itself is a @reverse property:
      // reverse-of-reverse becomes a forward property.
      final isTermReverse = termDef?.isReverse == true;

      final values = entry.value is List ? entry.value as List : [entry.value];
      for (final item in values) {
        if (item is! JsonObject ||
            item.containsKey('@value') ||
            item.containsKey('@list')) {
          throw RdfSyntaxException(
            'invalid reverse property value',
            format: _format,
          );
        }

        final reverseSubjectStr = _getSubjectId(item, context);
        if (reverseSubjectStr == null) continue;
        final reverseSubject = _tryCreateSubjectTerm(reverseSubjectStr);
        if (reverseSubject == null) {
          continue;
        }

        if (isTermReverse) {
          // Reverse of reverse = forward
          triples.add(
              Quad(subject, predicate, reverseSubject as RdfObject, graphName));
        } else {
          triples.add(Quad(reverseSubject, predicate, subject, graphName));
        }

        // Process the reverse node's own properties
        if (item.keys.any((k) => !k.startsWith('@'))) {
          _processNode(item, triples,
              graphName: graphName, inheritedContext: context);
        }
      }
    }
  }

  /// Adds reverse triples for a term defined with `@reverse` in context.
  void _addReverseTriples(
    RdfSubject currentSubject,
    RdfPredicate predicate,
    JsonValue value,
    List<Quad> triples,
    JsonLdContext context, {
    RdfGraphName? graphName,
  }) {
    final values = value is List ? value : [value];
    for (final item in values) {
      if (item is String) {
        final expanded = _expandPrefixedIri(item, context);
        final resolved = expanded.startsWith('_:')
            ? expanded
            : _tryResolveIriFromContext(expanded, context);
        if (resolved == null) continue;
        final reverseSubject = resolved.startsWith('_:')
            ? _getOrCreateBlankNode(resolved)
            : _tryCreateIriTermFromAbsolute(resolved);
        if (reverseSubject == null) {
          continue;
        }
        triples.add(Quad(reverseSubject, predicate, currentSubject, graphName));
        continue;
      }

      if (item is! JsonObject ||
          item.containsKey('@value') ||
          item.containsKey('@list')) {
        throw RdfSyntaxException(
          'invalid reverse property value',
          format: _format,
        );
      }

      final reverseSubjectStr = _getSubjectId(item, context);
      if (reverseSubjectStr == null) continue;
      final reverseSubject = _tryCreateSubjectTerm(reverseSubjectStr);
      if (reverseSubject == null) {
        continue;
      }
      triples.add(Quad(reverseSubject, predicate, currentSubject, graphName));

      if (item.keys.any((k) => !k.startsWith('@'))) {
        _processNode(item, triples,
            graphName: graphName, inheritedContext: context);
      }
    }
  }

  /// Converts a double value to XSD canonical form (e.g. `5.3` → `"5.3E0"`).
  static String _canonicalDouble(double value) {
    if (value.isNaN) return 'NaN';
    if (value.isInfinite) return value.isNegative ? '-INF' : 'INF';

    // Use Dart's toStringAsExponential for scientific notation
    final str = value.toStringAsExponential();
    // Dart produces e.g. "5.3e+0", we need "5.3E0" (uppercase E, no +sign)
    final parts = str.split('e');
    final mantissa = parts[0].contains('.') ? parts[0] : '${parts[0]}.0';
    var exponent = int.parse(parts[1]);
    return '${mantissa}E$exponent';
  }
}

/// Adapter that wraps a deprecated [JsonLdContextDocumentLoader] function
/// as a [JsonLdContextDocumentProvider].
class _LegacyLoaderProvider implements JsonLdContextDocumentProvider {
  final JsonLdContextDocumentLoader _loader;
  const _LegacyLoaderProvider(this._loader);

  @override
  JsonValue loadContextDocument(JsonLdContextDocumentRequest request) {
    return _loader(request);
  }
}
