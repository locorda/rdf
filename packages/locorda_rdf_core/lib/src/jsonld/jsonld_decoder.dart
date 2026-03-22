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
library jsonld_parser;

import 'dart:convert';
import 'dart:io';

import 'package:locorda_rdf_core/src/rdf_dataset_decoder.dart';
import 'package:logging/logging.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/iri_util.dart';

part 'jsonld_context_documents.dart';
part 'jsonld_async_decoder.dart';

final _log = Logger("rdf.jsonld");

const _rdfValuePredicate = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#value';
const _rdfDirectionPredicate =
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#direction';
const _rdfLanguagePredicate =
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#language';
const _rdfJsonDatatype = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#JSON';
const _i18nDatatypeBase = 'https://www.w3.org/ns/i18n#';

class _ScopedNodeEntry {
  const _ScopedNodeEntry(this.key, this.value, this.context);

  final String key;
  final JsonValue value;
  final _JsonLdContext context;
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
  // Decoders are always expected to have options, even if they are not used at
  // the moment. But maybe the JsonLdDecoder will have options in the future.
  //
  // ignore: unused_field
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
    final parsedInput = _parseJsonValueOrThrow(input, format: _format);
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
  final JsonLdContextDocumentProvider? _contextDocumentProvider;
  final JsonLdContextDocumentLoader? _contextDocumentLoader;
  final JsonObject _preloadedParsedContextDocuments;
  final JsonLdContextDocumentCache? _contextDocumentCache;
  // Map to store consistent blank node instances across the parsing process
  final Map<String, BlankNodeTerm> _blankNodeCache = {};
  final String _format;
  final String? _rdfDirection;
  final String _processingMode;
  final bool _skipInvalidRdfTerms;

  /// Guard against infinite recursion when applying scoped contexts
  /// that reference themselves (directly or indirectly).
  int _contextApplicationDepth = 0;
  static const int _maxContextApplicationDepth = 256;

  /// Base URI extracted from @base in the current context
  /// This overrides _baseUri (document URL) when hasContextBase is true
  String? _contextBaseUri;

  /// Whether @base was explicitly set in the context
  /// This allows us to distinguish between "@base not set" and "@base: null"
  bool _hasContextBase = false;

  static const String _rdfType =
      'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';
  static const String _rdfFirst =
      'http://www.w3.org/1999/02/22-rdf-syntax-ns#first';
  static const String _rdfRest =
      'http://www.w3.org/1999/02/22-rdf-syntax-ns#rest';
  static const String _rdfNil =
      'http://www.w3.org/1999/02/22-rdf-syntax-ns#nil';

  static const Set<String> _jsonLdKeywords = {
    '@base',
    '@container',
    '@context',
    '@direction',
    '@graph',
    '@id',
    '@import',
    '@included',
    '@index',
    '@json',
    '@language',
    '@list',
    '@nest',
    '@none',
    '@prefix',
    '@propagate',
    '@protected',
    '@reverse',
    '@set',
    '@type',
    '@value',
    '@version',
    '@vocab',
  };

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
        _contextDocumentProvider = contextDocumentProvider,
        _contextDocumentLoader = contextDocumentLoader,
        _preloadedParsedContextDocuments = preloadedParsedContextDocuments,
        _contextDocumentCache = contextDocumentCache,
        _format = format;

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
      final jsonData = _parseJsonValueOrThrow(_input, format: _format);

      final triples = <Quad>[];

      if (jsonData is JsonArray) {
        _log.fine('Parsing JSON-LD array');
        for (final item in jsonData) {
          if (item is JsonObject) {
            triples.addAll(_processNode(item));
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
        triples.addAll(_processNode(jsonData));
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
        'JSON-LD parsing error: ${e.toString()}',
        format: _format,
        cause: e,
      );
    }
  }

  /// Process a JSON-LD node and extract triples.
  List<Quad> _processNode(
    JsonObject node, {
    RdfGraphName? graphName,
    _JsonLdContext? inheritedContext,
  }) {
    final triples = <Quad>[];
    final context = _extractContext(
      node,
      baseContext: inheritedContext ?? const _JsonLdContext(),
    );
    final graphValue = _getKeywordValue(node, '@graph', context);
    final idValue = _getKeywordValue(node, '@id', context);
    final contextValue = _getKeywordValue(node, '@context', context);

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
          triples.addAll(_extractTriples(node, context, graphName: graphName));
        }

        RdfGraphName? nestedGraphName = graphName;
        if (idValue != null) {
          final graphId = idValue;
          if (graphId is String) {
            final expandedId = _expandIriForId(graphId, context);
            final subjectTerm = _tryCreateSubjectTerm(expandedId);
            if (subjectTerm == null && _skipInvalidRdfTerms) {
              return triples;
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
            final itemWithContext = JsonObject.from(item);
            if (!itemWithContext.containsKey('@context') &&
                contextValue != null) {
              itemWithContext['@context'] = contextValue;
            }
            triples.addAll(
              _processNode(
                itemWithContext,
                graphName: nestedGraphName,
                inheritedContext: context,
              ),
            );
          } else {
            triples.addAll(
              _extractTriples(item, context, graphName: nestedGraphName),
            );
          }
        }
        return triples;
      }

      // Process regular node
      triples.addAll(_extractTriples(node, context, graphName: graphName));

      return triples;
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
  _JsonLdContext _extractContext(
    JsonObject node, {
    _JsonLdContext baseContext = const _JsonLdContext(),
  }) {
    var context = baseContext;

    if (!node.containsKey('@context')) {
      return context;
    }

    final nodeContext = node['@context'];

    context = _mergeContextDefinition(context, nodeContext,
        seenContextIris: <String>{}, contextDocumentBaseIri: _baseUri);

    return context;
  }

  /// Merges an arbitrary JSON-LD context definition (`Map`, `List`, `String`)
  /// into [baseContext].
  _JsonLdContext _mergeContextDefinition(
    _JsonLdContext baseContext,
    JsonValue definition, {
    required Set<String> seenContextIris,
    String? contextDocumentBaseIri,
    bool allowProtectedNullification = false,
    bool allowProtectedOverride = false,
    bool allowContextWrapper = false,
  }) {
    if (definition is JsonObject) {
      // Remote context documents are often wrapped as {"@context": ...}.
      if (allowContextWrapper &&
          definition.length == 1 &&
          definition.containsKey('@context')) {
        return _mergeContextDefinition(baseContext, definition['@context'],
            seenContextIris: seenContextIris,
            contextDocumentBaseIri: contextDocumentBaseIri,
            allowProtectedNullification: allowProtectedNullification,
            allowProtectedOverride: allowProtectedOverride,
            allowContextWrapper: allowContextWrapper);
      }
      return _extractSingleContext(definition, baseContext,
          seenContextIris: seenContextIris,
          contextDocumentBaseIri: contextDocumentBaseIri,
          allowProtectedOverride: allowProtectedOverride);
    }

    if (definition is List) {
      var merged = baseContext;
      for (final item in definition) {
        merged = _mergeContextDefinition(merged, item,
            seenContextIris: seenContextIris,
            contextDocumentBaseIri: contextDocumentBaseIri,
            allowProtectedNullification: allowProtectedNullification,
            allowProtectedOverride: allowProtectedOverride,
            allowContextWrapper: allowContextWrapper);
      }
      return merged;
    }

    if (definition is String) {
      return _mergeExternalContext(baseContext, definition,
          seenContextIris: seenContextIris,
          contextDocumentBaseIri: contextDocumentBaseIri);
    }

    if (definition == null) {
      if (!allowProtectedNullification &&
          baseContext.terms.values.any((term) => term.isProtected)) {
        throw RdfSyntaxException(
          'invalid context nullification',
          format: _format,
        );
      }
      return const _JsonLdContext();
    }

    throw RdfSyntaxException(
      'Invalid @context entry: ${definition.runtimeType}',
      format: _format,
    );
  }

  /// Resolves and merges an external context document.
  _JsonLdContext _mergeExternalContext(
    _JsonLdContext baseContext,
    String contextRef, {
    required Set<String> seenContextIris,
    String? contextDocumentBaseIri,
  }) {
    final resolvedContextIri = resolveIri(
      contextRef,
      contextDocumentBaseIri ?? _getEffectiveBaseUri(),
    );
    final decoded = _loadExternalContextDocument(
      contextRef,
      baseIri: contextDocumentBaseIri,
      seenContextIris: seenContextIris,
    );

    return _mergeContextDefinition(baseContext, decoded,
        seenContextIris: seenContextIris,
        contextDocumentBaseIri: resolvedContextIri,
        allowContextWrapper: true);
  }

  JsonValue _loadExternalContextDocument(
    String contextRef, {
    String? baseIri,
    required Set<String> seenContextIris,
    bool failOnCycle = false,
  }) {
    final effectiveBaseIri = baseIri ?? _getEffectiveBaseUri();
    final resolvedContextIri = resolveIri(contextRef, effectiveBaseIri);

    if (seenContextIris.contains(resolvedContextIri)) {
      if (failOnCycle) {
        throw RdfSyntaxException(
          'invalid context entry',
          format: _format,
        );
      }
      return <String, Object?>{};
    }
    seenContextIris.add(resolvedContextIri);

    final request = JsonLdContextDocumentRequest(
      contextReference: contextRef,
      baseIri: effectiveBaseIri,
      resolvedContextIri: resolvedContextIri,
    );

    final cachedParsed = _contextDocumentCache?.getParsed(resolvedContextIri);
    if (cachedParsed != null) {
      return cachedParsed;
    }

    final preloadedParsed =
        _preloadedParsedContextDocuments[resolvedContextIri];
    JsonValue loaded = preloadedParsed;

    if (loaded == null) {
      if (_contextDocumentProvider != null) {
        loaded = _contextDocumentProvider.loadContextDocument(request);
      } else if (_contextDocumentLoader != null) {
        loaded = _contextDocumentLoader(request);
      }
    }

    if (loaded == null) {
      throw RdfSyntaxException(
        'Unable to resolve external context: $resolvedContextIri',
        format: _format,
      );
    }

    JsonValue decoded;
    if (loaded is String) {
      try {
        decoded = json.decode(loaded);
      } catch (e) {
        throw RdfSyntaxException(
          'Invalid external context JSON at $resolvedContextIri: ${e.toString()}',
          format: _format,
          cause: e,
        );
      }
    } else {
      decoded = loaded;
    }

    _contextDocumentCache?.putParsed(resolvedContextIri, decoded);

    return decoded;
  }

  JsonObject _extractImportedContextDefinition(
    JsonValue importValue, {
    required Set<String> seenContextIris,
    String? contextDocumentBaseIri,
  }) {
    if (_processingMode == 'json-ld-1.0') {
      throw RdfSyntaxException('invalid context entry', format: _format);
    }
    if (importValue is! String) {
      throw RdfSyntaxException('invalid @import value', format: _format);
    }

    final importedDocument = _loadExternalContextDocument(
      importValue,
      baseIri: contextDocumentBaseIri,
      seenContextIris: seenContextIris,
      failOnCycle: true,
    );
    if (importedDocument is! JsonObject ||
        !importedDocument.containsKey('@context')) {
      throw RdfSyntaxException('invalid remote context', format: _format);
    }

    final importedContext = importedDocument['@context'];
    if (importedContext is! JsonObject) {
      throw RdfSyntaxException('invalid remote context', format: _format);
    }
    if (importedContext.containsKey('@import')) {
      throw RdfSyntaxException('invalid context entry', format: _format);
    }

    return importedContext;
  }

  /// Processes a single context object into a [_JsonLdContext].
  _JsonLdContext _extractSingleContext(
    JsonObject contextMap,
    _JsonLdContext baseContext, {
    required Set<String> seenContextIris,
    String? contextDocumentBaseIri,
    bool allowProtectedOverride = false,
  }) {
    final preImportBaseContext = baseContext;
    var effectiveContextMap = contextMap;
    if (contextMap.containsKey('@import')) {
      final importedContext = _extractImportedContextDefinition(
        contextMap['@import'],
        seenContextIris: seenContextIris,
        contextDocumentBaseIri: contextDocumentBaseIri,
      );
      effectiveContextMap = {
        ...importedContext,
        ...contextMap,
      };
      effectiveContextMap.remove('@import');
    }
    final workingBase = baseContext;

    final terms = <String, _TermDefinition>{};
    final keywordAliases = <String, String>{};
    String? vocab;
    bool hasVocab = false;
    String? language;
    bool hasLanguage = false;
    String? base;
    bool hasBase = false;
    bool propagate = true;
    bool hasPropagate = false;
    final defaultProtected = effectiveContextMap['@protected'] == true;

    if (effectiveContextMap.containsKey('@base')) {
      final baseValue = effectiveContextMap['@base'];
      if (baseValue != null && baseValue is! String) {
        throw RdfSyntaxException('invalid base IRI', format: _format);
      }
      hasBase = true;
      if (baseValue is String && _containsInvalidIriChars(baseValue)) {
        base = null;
      } else {
        base = baseValue is String ? baseValue : null;
      }
      _log.fine('Found @base: $base');
    }

    final baseForResolution = hasBase
        ? (base == null
            ? null
            : (_looksLikeAbsoluteIri(base)
                ? base
                : resolveIri(base, _getEffectiveBaseFromContext(workingBase))))
        : _getEffectiveBaseFromContext(workingBase);

    // First pass: collect context-wide keyword settings independent of order.
    for (final entry in effectiveContextMap.entries) {
      switch (entry.key) {
        case '@base':
          continue;
        case '@vocab':
          hasVocab = true;
          if (entry.value != null && entry.value is! String) {
            throw RdfSyntaxException('invalid vocab mapping', format: _format);
          }
          if (entry.value is String) {
            final vocabValue = entry.value as String;
            if (_processingMode == 'json-ld-1.0' &&
                !_looksLikeAbsoluteIri(vocabValue)) {
              throw RdfSyntaxException(
                'invalid vocab mapping',
                format: _format,
              );
            }
            if (vocabValue.isEmpty) {
              vocab = baseForResolution;
            } else {
              // Try expanding @vocab as a compact IRI first (e.g. "ex:ns/")
              // This must happen before _looksLikeAbsoluteIri because compact
              // IRIs like "ex:ns/" match the absolute IRI regex.
              var expanded = false;
              if (vocabValue.contains(':')) {
                final expandedValue =
                    _expandPrefixedIri(vocabValue, workingBase);
                if (expandedValue != vocabValue) {
                  vocab = expandedValue;
                  expanded = true;
                }
              }
              if (!expanded) {
                if (_looksLikeAbsoluteIri(vocabValue)) {
                  vocab = vocabValue;
                } else {
                  // Try expanding @vocab as a term reference (e.g. "ex")
                  final termDef = workingBase.terms[vocabValue];
                  if (termDef != null &&
                      !termDef.isNullMapping &&
                      termDef.iri != null) {
                    vocab = termDef.iri!;
                  } else if (workingBase.hasVocab &&
                      workingBase.vocab != null) {
                    vocab = '${workingBase.vocab}$vocabValue';
                  } else {
                    vocab = baseForResolution == null
                        ? vocabValue
                        : resolveIri(vocabValue, baseForResolution);
                  }
                }
              }
            }
          } else {
            vocab = null;
          }
          _log.fine('Found @vocab: $vocab');
        case '@language':
          hasLanguage = true;
          if (entry.value != null && entry.value is! String) {
            throw RdfSyntaxException('invalid default language',
                format: _format);
          }
          language = entry.value is String ? entry.value as String : null;
          _log.fine('Found @language: $language');
        case '@direction':
          if (entry.value != null &&
              (entry.value is! String ||
                  (entry.value != 'ltr' && entry.value != 'rtl'))) {
            throw RdfSyntaxException('invalid base direction', format: _format);
          }
          continue;
        case '@propagate':
          if (_processingMode == 'json-ld-1.0') {
            throw RdfSyntaxException('invalid context entry', format: _format);
          }
          if (entry.value is! bool) {
            throw RdfSyntaxException('invalid @propagate value',
                format: _format);
          }
          hasPropagate = true;
          propagate = entry.value as bool;
        case '@protected':
        case '@version':
          continue;
        default:
          continue;
      }
    }

    for (final entry in effectiveContextMap.entries) {
      switch (entry.key) {
        case '@version':
          final version = entry.value;
          if (version is! num || version != 1.1) {
            throw RdfSyntaxException('invalid @version value', format: _format);
          }
          if (_processingMode == 'json-ld-1.0') {
            throw RdfSyntaxException('processing mode conflict',
                format: _format);
          }
          continue;
        default:
          continue;
      }
    }

    final normalizedBase = hasBase ? baseForResolution : base;

    var termResolutionContext = workingBase.merge(_JsonLdContext(
      vocab: vocab,
      hasVocab: hasVocab,
      language: language,
      hasLanguage: hasLanguage,
      base: normalizedBase,
      hasBase: hasBase,
      propagate: propagate,
      hasPropagate: hasPropagate,
    ));

    // Second pass: parse aliases and term definitions using the resolved
    // context-wide settings so implicit term IRIs are scoped correctly.
    for (final entry in effectiveContextMap.entries) {
      switch (entry.key) {
        case '@base':
        case '@vocab':
        case '@language':
        case '@direction':
        case '@propagate':
        case '@protected':
        case '@version':
          continue;
        default:
          if (_jsonLdKeywords.contains(entry.key)) {
            // In JSON-LD 1.1, @type can be redefined with @container: @set
            // and/or @protected.
            if (entry.key == '@type' &&
                _processingMode != 'json-ld-1.0' &&
                entry.value is JsonObject) {
              final typeDef = entry.value as JsonObject;
              final containers = _parseContainerMappings(typeDef['@container']);
              if (containers.contains('@set')) {
                final isProtected =
                    typeDef['@protected'] == true || defaultProtected;
                // Register @type with @container: @set
                final termDef = _TermDefinition(
                  iri: '@type',
                  containers: containers,
                  isProtected: isProtected,
                );
                terms[entry.key] = termDef;
                continue;
              }
            }
            throw RdfSyntaxException(
              'keyword redefinition',
              format: _format,
            );
          }

          // Skip @-prefixed term keys that look like keywords but aren't
          // actual JSON-LD keywords (e.g. "@ignoreMe"). Non-keyword-like
          // forms (e.g. "@", "@foo.bar") are valid term names.
          if (entry.key.startsWith('@') && _isKeywordLikeAtForm(entry.key)) {
            continue;
          }

          final aliasTarget = entry.value;
          // Check if the value is a direct keyword or resolves to a keyword
          // through an existing alias chain (e.g. "url" → "id" → "@id").
          String? resolvedKeyword;
          if (aliasTarget is String) {
            if (_jsonLdKeywords.contains(aliasTarget)) {
              resolvedKeyword = aliasTarget;
            } else {
              final chained = termResolutionContext.keywordAliases[aliasTarget];
              if (chained != null) {
                resolvedKeyword = chained;
              }
            }
          }
          if (resolvedKeyword != null) {
            if (resolvedKeyword == '@context') {
              throw RdfSyntaxException('invalid keyword alias',
                  format: _format);
            }
            final aliasDefinition = _validatedProtectedRedefinition(
              entry.key,
              termResolutionContext.terms[entry.key],
              _TermDefinition(
                iri: resolvedKeyword,
                isProtected: defaultProtected,
              ),
              allowProtectedOverride: allowProtectedOverride,
            );
            keywordAliases[entry.key] = resolvedKeyword;
            terms[entry.key] = aliasDefinition;
            termResolutionContext = termResolutionContext.merge(
              _JsonLdContext(
                terms: {entry.key: aliasDefinition},
                keywordAliases: {entry.key: resolvedKeyword},
              ),
            );
            continue;
          }

          var termDef = _parseTermDefinition(
            entry.key,
            entry.value,
            termResolutionContext,
            contextDocumentBaseIri: contextDocumentBaseIri,
            defaultProtected: defaultProtected,
          );
          if (termDef != null) {
            _validateTermDefinition(
              entry.key,
              termDef,
              termResolutionContext,
            );
            if (termDef.hasLocalContext &&
                _contextApplicationDepth < _maxContextApplicationDepth) {
              _contextApplicationDepth++;
              try {
                _mergeContextDefinition(
                  termResolutionContext,
                  termDef.localContext,
                  seenContextIris: <String>{},
                  contextDocumentBaseIri: contextDocumentBaseIri,
                  allowProtectedNullification: true,
                  allowProtectedOverride: true,
                );
              } on RdfSyntaxException {
                throw RdfSyntaxException('invalid scoped context',
                    format: _format);
              } finally {
                _contextApplicationDepth--;
              }
            }
            termDef = _validatedProtectedRedefinition(
              entry.key,
              termResolutionContext.terms[entry.key],
              termDef,
              allowProtectedOverride: allowProtectedOverride,
            );
            if (termDef.isPrefix &&
                termDef.iri != null &&
                _jsonLdKeywords.contains(termDef.iri)) {
              throw RdfSyntaxException(
                'invalid term definition',
                format: _format,
              );
            }
            terms[entry.key] = termDef;
            // If the term's IRI is a keyword, register it as a keyword alias
            // (e.g. "type": {"@id": "@type", "@container": "@set"})
            if (termDef.isNullMapping) {
              // Null mappings remove previous keyword aliases for this term.
              keywordAliases.remove(entry.key);
            }
            final termKeywordAlias =
                termDef.iri != null && _jsonLdKeywords.contains(termDef.iri)
                    ? {entry.key: termDef.iri!}
                    : <String, String>{};
            if (termKeywordAlias.isNotEmpty) {
              keywordAliases.addAll(termKeywordAlias);
            }
            termResolutionContext = termResolutionContext.merge(
              _JsonLdContext(
                terms: {entry.key: termDef},
                keywordAliases: termKeywordAlias,
              ),
            );
          }
      }
    }

    var merged = workingBase.merge(_JsonLdContext(
      terms: terms,
      keywordAliases: keywordAliases,
      vocab: vocab,
      hasVocab: hasVocab,
      language: language,
      hasLanguage: hasLanguage,
      base: normalizedBase,
      hasBase: hasBase,
      propagate: propagate,
      hasPropagate: hasPropagate,
    ));

    // Remove keyword aliases for terms that were null-mapped in this context,
    // since null mappings decouple the term from any previous keyword binding.
    final mergedAliases = merged.keywordAliases;
    var aliasesChanged = false;
    for (final entry in terms.entries) {
      if (entry.value.isNullMapping && mergedAliases.containsKey(entry.key)) {
        if (!aliasesChanged) {
          aliasesChanged = true;
        }
      }
    }
    if (aliasesChanged) {
      final cleanedAliases = Map<String, String>.from(mergedAliases);
      for (final entry in terms.entries) {
        if (entry.value.isNullMapping) {
          cleanedAliases.remove(entry.key);
        }
      }
      merged = merged.copyWith(keywordAliases: cleanedAliases);
    }

    if (hasPropagate && !propagate) {
      merged = merged.copyWith(nonPropagatedParent: preImportBaseContext);
    }

    return merged;
  }

  /// Parses a single context entry value into a [_TermDefinition].
  _TermDefinition? _parseTermDefinition(
      String key, JsonValue value, _JsonLdContext resolutionContext,
      {String? contextDocumentBaseIri, required bool defaultProtected}) {
    if (key.isEmpty) {
      throw RdfSyntaxException('invalid term definition', format: _format);
    }

    if (_isRelativeIriLikeTermKey(key)) {
      if (value is JsonObject && value['@prefix'] == true) {
        throw RdfSyntaxException('invalid term definition', format: _format);
      }
      throw RdfSyntaxException('invalid IRI mapping', format: _format);
    }

    if (value == null) {
      return _TermDefinition(
        iri: null,
        isProtected: defaultProtected,
        isNullMapping: true,
      );
    }

    if (value is String) {
      // Keyword-like @-forms that aren't actual keywords produce null mappings.
      if (value.startsWith('@') &&
          _isKeywordLikeAtForm(value) &&
          !_jsonLdKeywords.contains(value)) {
        return _TermDefinition(
          iri: null,
          isProtected: defaultProtected,
          isNullMapping: true,
          isKeywordLikeNull: true,
        );
      }
      _log.fine('Found term: $key -> $value');
      return _TermDefinition(iri: value, isProtected: defaultProtected);
    }

    if (value is JsonObject) {
      String? typeMapping;
      if (value.containsKey('@type')) {
        final rawTypeMapping = value['@type'];
        if (rawTypeMapping != null && rawTypeMapping is! String) {
          throw RdfSyntaxException('invalid type mapping', format: _format);
        }
        if (rawTypeMapping is String) {
          typeMapping = rawTypeMapping;
          if (typeMapping == '@json') {
            if (_processingMode == 'json-ld-1.0') {
              throw RdfSyntaxException('invalid type mapping', format: _format);
            }
            typeMapping = _rdfJsonDatatype;
          }
          if (typeMapping == '@none' && _processingMode == 'json-ld-1.0') {
            throw RdfSyntaxException('invalid type mapping', format: _format);
          }
          if (typeMapping != '@id' &&
              typeMapping != '@vocab' &&
              typeMapping != '@none' &&
              typeMapping != _rdfJsonDatatype) {
            final expandedType =
                _expandPredicate(typeMapping, resolutionContext);
            if (!_looksLikeAbsoluteIri(expandedType)) {
              throw RdfSyntaxException('invalid type mapping', format: _format);
            }
            typeMapping = expandedType;
          }
        }
      }

      final localContext = _normalizeLocalContextReferences(
        value['@context'],
        contextDocumentBaseIri,
      );
      final hasLocalContext = value.containsKey('@context');
      final isProtected = value.containsKey('@protected')
          ? value['@protected'] == true
          : defaultProtected;

      if (value.containsKey('@prefix') && value['@prefix'] is! bool) {
        throw RdfSyntaxException('invalid @prefix value', format: _format);
      }
      final hasPrefix = value.containsKey('@prefix');
      final isPrefix = value['@prefix'] == true;

      final hasNestMapping = value.containsKey('@nest');
      if (hasNestMapping &&
          (value['@nest'] is! String || value['@nest'] != '@nest')) {
        throw RdfSyntaxException('invalid @nest value', format: _format);
      }

      String? indexMapping;
      if (value.containsKey('@index')) {
        if (_processingMode == 'json-ld-1.0') {
          throw RdfSyntaxException('invalid term definition', format: _format);
        }
        final rawIndexMapping = value['@index'];
        if (rawIndexMapping is! String) {
          throw RdfSyntaxException('invalid term definition', format: _format);
        }
        if (rawIndexMapping.startsWith('@')) {
          throw RdfSyntaxException('invalid term definition', format: _format);
        }
        indexMapping = rawIndexMapping;
      }

      if (value.containsKey('@reverse')) {
        if (value.containsKey('@id')) {
          throw RdfSyntaxException('invalid reverse property', format: _format);
        }
        if (value.containsKey('@nest')) {
          throw RdfSyntaxException('invalid reverse property', format: _format);
        }
        final reverseIri = value['@reverse'];
        if (reverseIri is! String) {
          throw RdfSyntaxException('invalid IRI mapping', format: _format);
        }
        // Keyword-like @-form that isn't a real keyword → null mapping
        if (reverseIri.startsWith('@') &&
            _isKeywordLikeAtForm(reverseIri) &&
            !_jsonLdKeywords.contains(reverseIri)) {
          return _TermDefinition(
            iri: null,
            isNullMapping: true,
            isKeywordLikeNull: true,
            isProtected: isProtected,
          );
        }
        final expandedReverseIri =
            _expandPredicate(reverseIri, resolutionContext);
        if (!_looksLikeAbsoluteIri(expandedReverseIri)) {
          throw RdfSyntaxException('invalid IRI mapping', format: _format);
        }
        final containers = _parseContainerMappings(value['@container']);
        if (containers.contains('@list')) {
          throw RdfSyntaxException('invalid reverse property', format: _format);
        }
        if (indexMapping != null) {
          throw RdfSyntaxException('invalid term definition', format: _format);
        }
        _log.fine('Found reverse term: $key -> $expandedReverseIri');
        return _TermDefinition(
          iri: expandedReverseIri,
          isReverse: true,
          typeMapping: typeMapping,
          containers: containers,
          localContext: localContext,
          hasLocalContext: hasLocalContext,
          isProtected: isProtected,
          isPrefix: isPrefix,
          hasPrefix: hasPrefix,
        );
      }

      if (value.containsKey('@id')) {
        final idValue = value['@id'];
        if (idValue == null) {
          return _TermDefinition(
            iri: null,
            localContext: localContext,
            hasLocalContext: hasLocalContext,
            isProtected: isProtected,
            isPrefix: isPrefix,
            hasPrefix: hasPrefix,
            isNullMapping: true,
          );
        }
        if (idValue is! String) {
          throw RdfSyntaxException('invalid IRI mapping', format: _format);
        }
        if (idValue.startsWith('@') && !_jsonLdKeywords.contains(idValue)) {
          // In JSON-LD 1.1, @-prefixed values that look like keywords
          // (@ followed by only ASCII alpha) but aren't actual keywords
          // should produce a null mapping (silently ignored).
          // Non-keyword-like forms (e.g. "@", "@foo.bar") are valid IRIs.
          if (_isKeywordLikeAtForm(idValue)) {
            return _TermDefinition(
              iri: null,
              isNullMapping: true,
              isKeywordLikeNull: true,
              isProtected: isProtected,
              isPrefix: isPrefix,
              hasPrefix: hasPrefix,
            );
          }
          // Non-keyword-like @-prefixed forms are treated as IRIs
        }
        if (idValue == '@context') {
          throw RdfSyntaxException('invalid keyword alias', format: _format);
        }
        // In JSON-LD 1.1, {"@id": "@type"} is only allowed when the term
        // being defined is @type itself, or the definition includes
        // @container containing @set.
        if (idValue == '@type') {
          if (_processingMode != 'json-ld-1.0' && key != '@type') {
            final containers = _parseContainerMappings(value['@container']);
            if (!containers.contains('@set')) {
              throw RdfSyntaxException('invalid IRI mapping', format: _format);
            }
          }
        }
        final colonIndex = idValue.indexOf(':');
        if (colonIndex > 0 && idValue.substring(0, colonIndex) == key) {
          throw RdfSyntaxException('cyclic IRI mapping', format: _format);
        }
        // Expand the @id value if it's a compact IRI or term.
        // When the @id value equals the term being defined, skip self-lookup
        // to avoid resolving the value through the term's previous definition.
        final expandedIdValue = _jsonLdKeywords.contains(idValue)
            ? idValue
            : _expandTermIri(idValue, key, resolutionContext);
        final containers = _parseContainerMappings(value['@container']);
        if (indexMapping != null && !containers.contains('@index')) {
          throw RdfSyntaxException('invalid term definition', format: _format);
        }
        _log.fine('Found complex term: $key -> $expandedIdValue');
        return _TermDefinition(
          iri: expandedIdValue,
          indexMapping: indexMapping,
          typeMapping: typeMapping,
          containers: containers,
          language: value['@language'] as String?,
          hasLanguage: value.containsKey('@language'),
          localContext: localContext,
          hasLocalContext: hasLocalContext,
          isProtected: isProtected,
          isPrefix: isPrefix,
          hasPrefix: hasPrefix,
        );
      }

      // No @id — the term name itself is the IRI (expanded via vocab/prefix)
      if (value.containsKey('@type') ||
          value.containsKey('@container') ||
          value.containsKey('@language') ||
          value.containsKey('@direction')) {
        _log.fine('Found type-only term: $key');
        final expandedKey = _expandPredicate(key, resolutionContext);
        if (!resolutionContext.hasVocab &&
            expandedKey == key &&
            !key.contains(':')) {
          throw RdfSyntaxException('invalid IRI mapping', format: _format);
        }
        final containers = _parseContainerMappings(value['@container']);
        if (indexMapping != null && !containers.contains('@index')) {
          throw RdfSyntaxException('invalid term definition', format: _format);
        }
        return _TermDefinition(
          iri: expandedKey,
          indexMapping: indexMapping,
          typeMapping: typeMapping,
          containers: containers,
          language: value['@language'] as String?,
          hasLanguage: value.containsKey('@language'),
          localContext: localContext,
          hasLocalContext: hasLocalContext,
          isProtected: isProtected,
          isPrefix: isPrefix,
          hasPrefix: hasPrefix,
        );
      }

      if (hasLocalContext) {
        if (indexMapping != null) {
          throw RdfSyntaxException('invalid term definition', format: _format);
        }
        final expandedKey = _expandPredicate(key, resolutionContext);
        if (!resolutionContext.hasVocab &&
            expandedKey == key &&
            !key.contains(':')) {
          throw RdfSyntaxException('invalid IRI mapping', format: _format);
        }
        return _TermDefinition(
          iri: expandedKey,
          localContext: localContext,
          hasLocalContext: true,
          isProtected: isProtected,
          isPrefix: isPrefix,
          hasPrefix: hasPrefix,
        );
      }

      // Empty object term definitions (e.g. "term": {}) still define a term
      // in the context where the definition appears.
      if (indexMapping != null) {
        throw RdfSyntaxException('invalid term definition', format: _format);
      }
      final expandedKey = _expandPredicate(key, resolutionContext);
      return _TermDefinition(
        iri: expandedKey,
        isProtected: isProtected,
        isPrefix: isPrefix,
        hasPrefix: hasPrefix,
      );
    }

    throw RdfSyntaxException('invalid term definition', format: _format);
  }

  void _validateTermDefinition(
    String key,
    _TermDefinition termDef,
    _JsonLdContext resolutionContext,
  ) {
    if (_processingMode == 'json-ld-1.0') {
      return;
    }

    // In 1.1 mode, terms that look like compact IRIs (prefix:suffix) must
    // map to their expected compact IRI expansion.
    if (termDef.iri != null && key.contains(':')) {
      final colonIndex = key.indexOf(':');
      final prefix = key.substring(0, colonIndex);
      if (prefix != '_' && !key.substring(colonIndex + 1).startsWith('//')) {
        final prefixDef = resolutionContext.terms[prefix];
        if (prefixDef != null &&
            prefixDef.iri != null &&
            _canUseAsPrefix(prefixDef)) {
          final expandedPrefixIri =
              _expandPredicate(prefixDef.iri!, resolutionContext);
          final expectedIri =
              '$expandedPrefixIri${key.substring(colonIndex + 1)}';
          // Expand the term's IRI too, since it may be stored as a compact IRI
          final expandedTermIri =
              _expandPredicate(termDef.iri!, resolutionContext);
          if (expandedTermIri != expectedIri) {
            throw RdfSyntaxException(
              'invalid IRI mapping',
              format: _format,
            );
          }
        }
      }
    }
  }

  JsonValue _normalizeLocalContextReferences(
      JsonValue localContext, String? baseIri) {
    if (localContext == null || baseIri == null) {
      return localContext;
    }
    if (localContext is String) {
      return resolveIri(localContext, baseIri);
    }
    if (localContext is JsonArray) {
      return localContext
          .map((item) => _normalizeLocalContextReferences(item, baseIri))
          .toList(growable: false);
    }
    return localContext;
  }

  _TermDefinition _validatedProtectedRedefinition(
      String key, _TermDefinition? existing, _TermDefinition replacement,
      {bool allowProtectedOverride = false}) {
    if (existing == null || !existing.isProtected) {
      return replacement;
    }

    if (allowProtectedOverride) {
      return replacement;
    }

    if (!_termDefinitionsEquivalent(existing, replacement)) {
      throw RdfSyntaxException(
        'protected term redefinition',
        format: _format,
      );
    }

    return _TermDefinition(
      iri: replacement.iri,
      typeMapping: replacement.typeMapping,
      containers: replacement.containers,
      language: replacement.language,
      hasLanguage: replacement.hasLanguage,
      isReverse: replacement.isReverse,
      localContext: replacement.localContext,
      hasLocalContext: replacement.hasLocalContext,
      isProtected: true,
      isPrefix: replacement.isPrefix,
      isNullMapping: replacement.isNullMapping,
    );
  }

  bool _termDefinitionsEquivalent(
    _TermDefinition left,
    _TermDefinition right,
  ) {
    return left.iri == right.iri &&
        left.typeMapping == right.typeMapping &&
        left.language == right.language &&
        left.hasLanguage == right.hasLanguage &&
        left.isReverse == right.isReverse &&
        left.hasLocalContext == right.hasLocalContext &&
        left.isPrefix == right.isPrefix &&
        left.isNullMapping == right.isNullMapping &&
        left.containers.length == right.containers.length &&
        left.containers.containsAll(right.containers) &&
        _jsonValueDeepEquals(left.localContext, right.localContext);
  }

  bool _jsonValueDeepEquals(JsonValue left, JsonValue right) {
    if (identical(left, right)) {
      return true;
    }
    if (left == null || right == null) {
      return left == right;
    }
    if (left is JsonArray && right is JsonArray) {
      if (left.length != right.length) {
        return false;
      }
      for (var index = 0; index < left.length; index++) {
        if (!_jsonValueDeepEquals(left[index], right[index])) {
          return false;
        }
      }
      return true;
    }
    if (left is JsonObject && right is JsonObject) {
      if (left.length != right.length) {
        return false;
      }
      for (final entry in left.entries) {
        if (!right.containsKey(entry.key) ||
            !_jsonValueDeepEquals(entry.value, right[entry.key])) {
          return false;
        }
      }
      return true;
    }
    return left == right;
  }

  Set<String> _parseContainerMappings(JsonValue containerValue) {
    const allowedContainers = {
      '@list',
      '@set',
      '@index',
      '@language',
      '@graph',
      '@id',
      '@type',
      '@nest',
    };

    void validateContainer(String value) {
      if (!allowedContainers.contains(value)) {
        throw RdfSyntaxException('invalid container mapping', format: _format);
      }
      if (_processingMode == 'json-ld-1.0' &&
          (value == '@id' ||
              value == '@type' ||
              value == '@graph' ||
              value == '@nest')) {
        throw RdfSyntaxException('invalid container mapping', format: _format);
      }
    }

    if (containerValue is String) {
      validateContainer(containerValue);
      return {containerValue};
    }
    if (containerValue is JsonArray) {
      final mapped = <String>{};
      for (final item in containerValue) {
        if (item is! String) {
          throw RdfSyntaxException('invalid container mapping',
              format: _format);
        }
        validateContainer(item);
        mapped.add(item);
      }
      return mapped;
    }
    if (containerValue != null) {
      throw RdfSyntaxException('invalid container mapping', format: _format);
    }
    return const <String>{};
  }

  /// Extract triples from a JSON-LD node.
  List<Quad> _extractTriples(
    JsonObject node,
    _JsonLdContext context, {
    RdfGraphName? graphName,
  }) {
    final triples = <Quad>[];
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
          return triples;
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
          return triples;
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
            _jsonLdKeywords.contains(resolvedKey)) {
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
                triples.addAll(_extractTriples(included, entryContext,
                    graphName: graphName));
              }
            } else if (value is JsonObject) {
              if (value.containsKey('@value') || value.containsKey('@list')) {
                throw RdfSyntaxException(
                  'invalid @included value',
                  format: _format,
                );
              }
              triples.addAll(
                  _extractTriples(value, entryContext, graphName: graphName));
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

        if (termDef?.typeMapping == _rdfJsonDatatype) {
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

      return triples;
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
    _JsonLdContext context,
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
            !_jsonLdKeywords.contains(id)) {
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
  RdfObject? _peekSubjectFromNest(JsonObject node, _JsonLdContext context) {
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

  /// the effective base.
  String? _getSubjectId(JsonObject node, _JsonLdContext context) {
    final id = _getKeywordValue(node, '@id', context);
    if (id != null) {
      if (id is! String) {
        throw RdfSyntaxException('@id value must be a string', format: _format);
      }

      // Keyword-like @-forms that aren't actual keywords are ignored in @id.
      if (id.startsWith('@') &&
          _isKeywordLikeAtForm(id) &&
          !_jsonLdKeywords.contains(id)) {
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
  String _expandIriForId(String iri, _JsonLdContext context) {
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
          _canUseAsPrefix(prefixDef)) {
        return '${prefixDef.iri}$localName';
      }
    }

    // Plain terms are NOT expanded for @id values — return as-is
    return iri;
  }

  /// Expand a prefixed IRI using the active context's term definitions.
  String _expandPrefixedIri(String iri, _JsonLdContext context) {
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
          _canUseAsPrefix(prefixDef)) {
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

  /// Returns `true` if a term definition can be used as a prefix for
  /// compact IRI expansion.
  ///
  /// In JSON-LD 1.1, a term defined with an expanded definition object
  /// can only be used as a prefix if `@prefix: true` is set or if the
  /// term IRI ends with a gen-delim character (indicating it was designed
  /// as a prefix). Simple string definitions always allow prefix use.
  bool _canUseAsPrefix(_TermDefinition def) {
    // If explicitly marked as prefix, always allow
    if (def.isPrefix) return true;
    // If @prefix was explicitly set to false, never allow
    if (def.hasPrefix && !def.isPrefix) return false;
    // In 1.0 mode, all terms can be used as prefixes
    if (_processingMode == 'json-ld-1.0') return true;
    // If the IRI ends with a gen-delim, it's implicitly a prefix
    if (def.iri != null && def.iri!.isNotEmpty) {
      final last = def.iri![def.iri!.length - 1];
      if ('/:?#[]@'.contains(last)) return true;
    }
    return false;
  }

  /// Process @type value and add rdf:type triples.
  void _processType(
    RdfSubject subject,
    JsonValue typeValue,
    List<Quad> quads,
    _JsonLdContext context, {
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

  String _expandTypedIriValue(String value, _JsonLdContext context) {
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
    _JsonLdContext context, {
    _TermDefinition? termDef,
    RdfGraphName? graphName,
    _JsonLdContext? inheritedContextForNode,
  }) {
    // Handle @type: @json — any value (including null) becomes an rdf:JSON literal.
    if (termDef?.typeMapping == _rdfJsonDatatype) {
      triples.add(
        Quad(
          subject,
          predicate,
          LiteralTerm(
            _canonicalizeJsonLiteralValue(value),
            datatype: _iriTermFactory(_rdfJsonDatatype),
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
            !_jsonLdKeywords.contains(objectId)) {
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
          triples.addAll(
            _processNode(
              value,
              graphName: graphName,
              inheritedContext: inheritedContextForNode ?? context,
            ),
          );
        }
      } else if (value.containsKey('@value')) {
        // Resolve the @type value: handle @json keyword and aliases.
        final rawType = value['@type'];
        final resolvedType = rawType is String
            ? _resolveKeywordAlias(rawType, context)
            : rawType;
        final isJsonType =
            resolvedType == '@json' || resolvedType == _rdfJsonDatatype;
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
              resolvedTypeIri == _rdfJsonDatatype) {
            objectTerm = LiteralTerm(
              _canonicalizeJsonLiteralValue(rawLiteralValue),
              datatype: _iriTermFactory(_rdfJsonDatatype),
            );
          } else {
            final expandedType = _expandTypedIriValue(typeIri, context);
            if (expandedType == _rdfJsonDatatype) {
              objectTerm = LiteralTerm(
                _canonicalizeJsonLiteralValue(rawLiteralValue),
                datatype: _iriTermFactory(_rdfJsonDatatype),
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
            triples.addAll(
              _processNode(
                value,
                graphName: graphName,
                inheritedContext: nodeContext,
              ),
            );
          } else {
            final blankNodeId = '_:b${value.hashCode.abs()}';
            final blankNode = _getOrCreateBlankNode(blankNodeId);
            triples.add(Quad(subject, predicate, blankNode, graphName));
            final recursiveNode = JsonObject.from(value);
            recursiveNode['@id'] = blankNodeId;
            triples.addAll(
              _processNode(
                recursiveNode,
                graphName: graphName,
                inheritedContext: nodeContext,
              ),
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
          triples.addAll(
            _processNode(
              value,
              graphName: graphName,
              inheritedContext: nodeContext,
            ),
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
          triples.addAll(
            _processNode(
              value,
              graphName: graphName,
              inheritedContext: nodeContext,
            ),
          );
        }
      }
    }
  }

  void _validateObjectValueShape(JsonObject value, [_JsonLdContext? context]) {
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
        resolvedType == '@json' || resolvedType == _rdfJsonDatatype;

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

  String _resolveKeywordAlias(String key, _JsonLdContext context) {
    final directAlias = context.keywordAliases[key];
    if (directAlias != null) {
      return directAlias;
    }

    final termDef = context.terms[key];
    if (termDef != null &&
        !termDef.isNullMapping &&
        termDef.iri != null &&
        _jsonLdKeywords.contains(termDef.iri)) {
      return termDef.iri!;
    }

    return key;
  }

  bool _isKeywordKey(String key, _JsonLdContext context, String keyword) {
    return _resolveKeywordAlias(key, context) == keyword;
  }

  JsonValue _getKeywordValue(
    JsonObject node,
    String keyword,
    _JsonLdContext context,
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

  _JsonLdContext _applyTypeScopedContexts(
    JsonObject node,
    _JsonLdContext context,
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

  _JsonLdContext _applyTermScopedContext(
    _JsonLdContext context,
    _TermDefinition? termDef,
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
    _JsonLdContext context,
  ) {
    final entries = <_ScopedNodeEntry>[];

    void addFromNest(JsonValue nestValue, _JsonLdContext nestContext) {
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
    _JsonLdContext context,
  ) {
    final normalized = JsonObject.from(input);
    final aliasKeysToRemove = <String>[];
    final aliasCountsForId = <int>[];
    var hasCanonicalId = false;
    for (final entry in input.entries) {
      final resolved = _resolveKeywordAlias(entry.key, context);
      if (!_jsonLdKeywords.contains(resolved)) continue;
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
    _JsonLdContext context, {
    _TermDefinition? termDef,
    RdfGraphName? graphName,
    _JsonLdContext? inheritedContextForNode,
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
        triples.addAll(
          _extractTriples(
            item,
            itemContext,
            graphName: graphTerm,
          ),
        );
      }
    }
  }

  void _addGraphContainerContent(
    JsonValue graphContainerValue,
    List<Quad> triples,
    _JsonLdContext context,
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
        triples.addAll(
          _processNode(
            item,
            graphName: graphName,
            inheritedContext: context,
          ),
        );
      } else {
        triples.addAll(
          _extractTriples(
            item,
            context,
            graphName: graphName,
          ),
        );
      }
    }
  }

  void _addIdContainerTriples(
    RdfSubject subject,
    RdfPredicate predicate,
    JsonValue value,
    List<Quad> triples,
    _JsonLdContext context, {
    _TermDefinition? termDef,
    RdfGraphName? graphName,
    _JsonLdContext? inheritedContextForNode,
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
    _JsonLdContext context, {
    _TermDefinition? termDef,
    RdfGraphName? graphName,
    _JsonLdContext? inheritedContextForNode,
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
    _JsonLdContext context, {
    _TermDefinition? termDef,
    RdfGraphName? graphName,
    _JsonLdContext? inheritedContextForNode,
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
    _TermDefinition? termDef,
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
    _JsonLdContext context, {
    _TermDefinition? termDef,
    RdfGraphName? graphName,
    _JsonLdContext? inheritedContextForNode,
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

  /// Expand an IRI from a term definition's @id value.
  ///
  /// Like [_expandPredicate] but skips looking up [excludeTerm] to avoid
  /// resolving the value through the term's own previous definition.
  String _expandTermIri(
      String value, String excludeTerm, _JsonLdContext context) {
    // If the value is the same as the term being defined, skip term lookup
    // and go straight to compact IRI / vocab expansion.
    if (value == excludeTerm) {
      final expanded = _expandPrefixedIri(value, context);
      if (expanded != value) return expanded;
      if (value.startsWith('_:') || _looksLikeAbsoluteIri(value)) {
        return value;
      }
      if (context.vocab != null) {
        return _appendToVocab(context.vocab!, value);
      }
      return value;
    }
    return _expandPredicate(value, context);
  }

  /// Expand a predicate using term definitions, prefix expansion,
  /// and @vocab fallback.
  String _expandPredicate(String key, _JsonLdContext context) {
    // Check term definitions first
    final termDef = context.terms[key];
    if (termDef != null && !termDef.isKeywordLikeNull) {
      // Explicit null mappings decouple the term from @vocab.
      if (termDef.isNullMapping) {
        return key;
      }
      if (termDef.iri == null) {
        return key;
      }
      final iri = termDef.iri!;
      // If already absolute, return it
      if (iri.startsWith('http://') || iri.startsWith('https://')) {
        return iri;
      }
      // Try prefix expansion on the term's IRI
      if (iri.contains(':')) {
        final expanded = _expandPrefixedIri(iri, context);
        if (expanded != iri) return expanded;
      }
      // Apply vocab to the term's IRI if it's just a plain name
      if (context.vocab != null && !iri.contains(':')) {
        return _appendToVocab(context.vocab!, iri);
      }
      return iri;
    }

    // Not in terms (or keyword-like null mapping) — try prefix expansion
    final expanded = _expandPrefixedIri(key, context);
    if (expanded != key) return expanded;

    // Keep blank node identifiers and absolute IRIs unchanged.
    if (key.startsWith('_:') || _looksLikeAbsoluteIri(key)) {
      return key;
    }

    // Vocab fallback
    if (context.vocab != null) {
      return _appendToVocab(context.vocab!, key);
    }

    _log.warning('Could not expand predicate: $key');
    return key;
  }

  IriTerm? _tryCreateIriTerm(String iri) {
    if (!_looksLikeAbsoluteIri(iri) || _hasMultipleFragmentDelimiters(iri)) {
      return null;
    }
    try {
      return _iriTermFactory(iri);
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

  static bool _looksLikeAbsoluteIri(String value) {
    return RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*:').hasMatch(value);
  }

  static final _invalidIriCharsPattern = RegExp(r'[<>{}\|\\^\s`]');

  static bool _containsInvalidIriChars(String value) {
    return _invalidIriCharsPattern.hasMatch(value);
  }

  static String _appendToVocab(String vocab, String suffix) {
    return '$vocab$suffix';
  }

  static bool _hasMultipleFragmentDelimiters(String iri) {
    return '#'.allMatches(iri).length > 1;
  }

  /// Returns `true` if [value] looks like a JSON-LD keyword form:
  /// `@` followed by one or more ASCII alphabetic characters (e.g. `@ignoreMe`).
  /// Non-keyword-like forms such as `@`, `@foo.bar`, `@123` return `false`.
  static bool _isKeywordLikeAtForm(String value) {
    if (value.length <= 1) return false;
    return RegExp(r'^@[a-zA-Z]+$').hasMatch(value);
  }

  static bool _isRelativeIriLikeTermKey(String key) {
    return key.startsWith('./') ||
        key.startsWith('../') ||
        key.startsWith('/') ||
        key.startsWith('?') ||
        key.startsWith('#');
  }

  String? _getEffectiveBaseFromContext(_JsonLdContext context) {
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
  String? _tryResolveIriFromContext(String iri, _JsonLdContext context) {
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
      String value, _JsonLdContext context, _TermDefinition? termDef) {
    // Datatype coercion (other than @id/@vocab/@none, which are handled earlier)
    if (termDef?.typeMapping != null &&
        termDef!.typeMapping != '@id' &&
        termDef.typeMapping != '@vocab' &&
        termDef.typeMapping != '@none') {
      if (termDef.typeMapping == _rdfJsonDatatype) {
        return LiteralTerm(
          _canonicalizeJsonLiteralValue(value),
          datatype: _iriTermFactory(_rdfJsonDatatype),
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
    _JsonLdContext context,
    _TermDefinition? termDef, {
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
    _JsonLdContext context, {
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
      if (resolvedKey.startsWith('@') &&
          _jsonLdKeywords.contains(resolvedKey)) {
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
          triples.addAll(
            _processNode(item, graphName: graphName, inheritedContext: context),
          );
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
    _JsonLdContext context, {
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
        triples.addAll(
          _processNode(item, graphName: graphName, inheritedContext: context),
        );
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
