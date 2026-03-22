part of 'jsonld_decoder.dart';

// JSON type aliases for clearer parser contracts.
typedef JsonValue = Object?;
typedef JsonObject = Map<String, JsonValue>;
typedef JsonArray = List<JsonValue>;

JsonValue _parseJsonValueOrThrow(
  String source, {
  required String format,
  String? location,
}) {
  try {
    return json.decode(source) as JsonValue;
  } catch (e) {
    final locationSuffix = location == null ? '' : ' at $location';
    throw RdfSyntaxException(
      'Invalid JSON syntax$locationSuffix: ${e.toString()}',
      format: format,
      cause: e,
    );
  }
}

/// Loads an external JSON-LD context document.
///
/// Return either a parsed JSON value (`Map`/`List`) or raw JSON string.
/// Returning `null` indicates that the context cannot be resolved.
typedef JsonLdContextDocumentLoader = JsonValue Function(
  JsonLdContextDocumentRequest request,
);

/// Async variant for loading external context documents.
typedef AsyncJsonLdContextDocumentLoader = Future<JsonValue> Function(
  JsonLdContextDocumentRequest request,
);

/// Full input for loading an external JSON-LD context.
class JsonLdContextDocumentRequest {
  /// Raw `@context` entry value from the JSON-LD document.
  final String contextReference;

  /// Effective base IRI used to resolve [contextReference].
  final String? baseIri;

  /// Fully resolved context IRI.
  final String resolvedContextIri;

  const JsonLdContextDocumentRequest({
    required this.contextReference,
    required this.baseIri,
    required this.resolvedContextIri,
  });
}

/// Sync provider abstraction for external JSON-LD context documents.
abstract interface class JsonLdContextDocumentProvider {
  JsonValue loadContextDocument(JsonLdContextDocumentRequest request);
}

/// Async provider abstraction for external JSON-LD context documents.
abstract interface class AsyncJsonLdContextDocumentProvider {
  Future<JsonValue> loadContextDocumentAsync(
      JsonLdContextDocumentRequest request);
}

/// Built-in provider that maps canonical IRI prefixes to local filesystem
/// locations and loads/decodes context documents from disk.
class MappedFileJsonLdContextDocumentProvider
    implements
        JsonLdContextDocumentProvider,
        AsyncJsonLdContextDocumentProvider {
  final Map<String, String> iriPrefixMappings;

  const MappedFileJsonLdContextDocumentProvider({
    this.iriPrefixMappings = const {},
  });

  @override
  JsonValue loadContextDocument(JsonLdContextDocumentRequest request) {
    final mappedIri = _applyMappings(request.resolvedContextIri);
    final uri = Uri.tryParse(mappedIri);

    if (uri != null && uri.scheme == 'file') {
      final file = File.fromUri(uri);
      if (!file.existsSync()) return null;
      return _decodeDocument(file.readAsStringSync(), mappedIri);
    }

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return null;
    }

    final file = File(mappedIri);
    if (!file.existsSync()) return null;
    return _decodeDocument(file.readAsStringSync(), mappedIri);
  }

  @override
  Future<JsonValue> loadContextDocumentAsync(
    JsonLdContextDocumentRequest request,
  ) async {
    final mappedIri = _applyMappings(request.resolvedContextIri);
    final uri = Uri.tryParse(mappedIri);

    if (uri != null && uri.scheme == 'file') {
      final file = File.fromUri(uri);
      if (!file.existsSync()) return null;
      return _decodeDocument(await file.readAsString(), mappedIri);
    }

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return null;
    }

    final file = File(mappedIri);
    if (!file.existsSync()) return null;
    return _decodeDocument(await file.readAsString(), mappedIri);
  }

  String _applyMappings(String iri) {
    if (iriPrefixMappings.isEmpty) return iri;

    final sortedKeys = iriPrefixMappings.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final sourcePrefix in sortedKeys) {
      if (iri.startsWith(sourcePrefix)) {
        final targetPrefix = iriPrefixMappings[sourcePrefix]!;
        final suffix = iri.substring(sourcePrefix.length);
        return '$targetPrefix$suffix';
      }
    }

    return iri;
  }

  JsonValue _decodeDocument(String content, String location) {
    try {
      return json.decode(content);
    } catch (_) {
      // Return raw content for custom processing in decoder fallback path.
      return content;
    }
  }
}

/// Cross-request cache for parsed external context documents.
abstract interface class JsonLdContextDocumentCache {
  JsonValue getParsed(String resolvedContextIri);

  void putParsed(String resolvedContextIri, JsonValue parsedContextDocument);
}

/// In-memory cache implementation for parsed external context documents.
class InMemoryJsonLdContextDocumentCache implements JsonLdContextDocumentCache {
  final JsonObject _parsedDocuments = {};

  @override
  JsonValue getParsed(String resolvedContextIri) =>
      _parsedDocuments[resolvedContextIri];

  @override
  void putParsed(String resolvedContextIri, JsonValue parsedContextDocument) {
    _parsedDocuments[resolvedContextIri] = parsedContextDocument;
  }
}

/// A term definition in a JSON-LD context, holding the expanded IRI
/// and optional type coercion, container, and language settings.
class _TermDefinition {
  final String? iri;

  /// Property-valued index mapping from `@index` in term definition.
  ///
  /// When present with `@container: @index`, map keys are injected as the
  /// value of this property instead of `@index`.
  final String? indexMapping;

  /// Type coercion: `"@id"`, `"@vocab"`, or a datatype IRI
  final String? typeMapping;

  /// Container mapping entries such as `"@list"`, `"@set"`,
  /// `"@language"`, `"@graph"`, etc.
  final Set<String> containers;

  /// Per-term language override
  final String? language;

  /// Whether `@language` was explicitly set on this term (distinguishes
  /// `@language: null` from absent)
  final bool hasLanguage;

  /// Whether this is a reverse property
  final bool isReverse;

  /// Term-scoped local context (`@context` in term definition).
  final JsonValue localContext;

  /// Whether `@context` was explicitly set on this term.
  final bool hasLocalContext;

  /// Whether this term is protected from redefinition.
  final bool isProtected;

  /// Whether this term can be used as a prefix (`@prefix: true`).
  final bool isPrefix;

  /// Whether `@prefix` was explicitly set on this term definition.
  final bool hasPrefix;

  /// Whether the term explicitly maps to `null`.
  final bool isNullMapping;

  /// Whether this null mapping was created from a keyword-like @-form
  /// (e.g. `"term": "@ignoreMe"`) rather than explicit `null`.
  /// Keyword-like null mappings allow @vocab fallback.
  final bool isKeywordLikeNull;

  const _TermDefinition({
    required this.iri,
    this.indexMapping,
    this.typeMapping,
    this.containers = const <String>{},
    this.language,
    this.hasLanguage = false,
    this.isReverse = false,
    this.localContext,
    this.hasLocalContext = false,
    this.isProtected = false,
    this.isPrefix = false,
    this.hasPrefix = false,
    this.isNullMapping = false,
    this.isKeywordLikeNull = false,
  });

  bool hasContainer(String value) => containers.contains(value);
}

/// Active JSON-LD context holding term definitions and keyword settings.
class _JsonLdContext {
  final Map<String, _TermDefinition> terms;
  final Map<String, String> keywordAliases;
  final String? vocab;
  final bool hasVocab;
  final String? language;
  final bool hasLanguage;
  final String? base;
  final bool hasBase;
  final bool propagate;
  final bool hasPropagate;
  final _JsonLdContext? nonPropagatedParent;

  const _JsonLdContext({
    this.terms = const {},
    this.keywordAliases = const {},
    this.vocab,
    this.hasVocab = false,
    this.language,
    this.hasLanguage = false,
    this.base,
    this.hasBase = false,
    this.propagate = true,
    this.hasPropagate = false,
    this.nonPropagatedParent,
  });

  /// Merges [other] on top of this context (later context wins).
  _JsonLdContext merge(_JsonLdContext other) {
    return _JsonLdContext(
      terms: {...terms, ...other.terms},
      keywordAliases: {...keywordAliases, ...other.keywordAliases},
      vocab: other.hasVocab ? other.vocab : vocab,
      hasVocab: other.hasVocab || hasVocab,
      language: other.hasLanguage ? other.language : language,
      hasLanguage: other.hasLanguage || hasLanguage,
      base: other.hasBase ? other.base : base,
      hasBase: other.hasBase || hasBase,
      propagate: other.hasPropagate ? other.propagate : propagate,
      hasPropagate: other.hasPropagate || hasPropagate,
      nonPropagatedParent: other.hasPropagate
          ? (other.propagate ? nonPropagatedParent : this)
          : (other.nonPropagatedParent ?? nonPropagatedParent),
    );
  }

  _JsonLdContext copyWith({
    Map<String, _TermDefinition>? terms,
    Map<String, String>? keywordAliases,
    String? vocab,
    bool? hasVocab,
    String? language,
    bool? hasLanguage,
    String? base,
    bool? hasBase,
    bool? propagate,
    bool? hasPropagate,
    _JsonLdContext? nonPropagatedParent,
  }) {
    return _JsonLdContext(
      terms: terms ?? this.terms,
      keywordAliases: keywordAliases ?? this.keywordAliases,
      vocab: vocab ?? this.vocab,
      hasVocab: hasVocab ?? this.hasVocab,
      language: language ?? this.language,
      hasLanguage: hasLanguage ?? this.hasLanguage,
      base: base ?? this.base,
      hasBase: hasBase ?? this.hasBase,
      propagate: propagate ?? this.propagate,
      hasPropagate: hasPropagate ?? this.hasPropagate,
      nonPropagatedParent: nonPropagatedParent ?? this.nonPropagatedParent,
    );
  }
}
