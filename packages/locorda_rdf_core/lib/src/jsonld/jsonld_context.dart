/// JSON-LD context model classes.
///
/// This library provides the core data types for representing JSON-LD
/// active contexts and term definitions. These types are shared between
/// the decoder, expansion processor, and compaction processor.
library jsonld_context;

/// A term definition in a JSON-LD context, holding the expanded IRI
/// and optional type coercion, container, and language settings.
class TermDefinition {
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

  /// Per-term direction override
  final String? direction;

  /// Whether `@direction` was explicitly set on this term.
  final bool hasDirection;

  /// Whether this is a reverse property
  final bool isReverse;

  /// Term-scoped local context (`@context` in term definition).
  final Object? localContext;

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

  /// The `@nest` value for this term definition.
  /// When set (typically to `"@nest"`), the compacted property is placed
  /// under a nesting container rather than directly in the node object.
  final String? nestValue;

  /// Whether this term was defined as a simple string mapping
  /// (e.g. `"ex": "http://example.org/"`) as opposed to an expanded
  /// term definition object (e.g. `"ex": {"@id": "http://example.org/"}`).
  /// Simple definitions can be used as prefixes for compact IRI creation
  /// even without `@prefix: true`.
  final bool isSimpleTermDefinition;

  const TermDefinition({
    required this.iri,
    this.indexMapping,
    this.typeMapping,
    this.containers = const <String>{},
    this.language,
    this.hasLanguage = false,
    this.direction,
    this.hasDirection = false,
    this.isReverse = false,
    this.localContext,
    this.hasLocalContext = false,
    this.isProtected = false,
    this.isPrefix = false,
    this.hasPrefix = false,
    this.isNullMapping = false,
    this.isKeywordLikeNull = false,
    this.nestValue,
    this.isSimpleTermDefinition = false,
  });

  bool hasContainer(String value) => containers.contains(value);
}

/// Active JSON-LD context holding term definitions and keyword settings.
class JsonLdContext {
  final Map<String, TermDefinition> terms;
  final Map<String, String> keywordAliases;
  final String? vocab;
  final bool hasVocab;
  final String? language;
  final bool hasLanguage;
  final String? direction;
  final bool hasDirection;
  final String? base;
  final bool hasBase;
  final bool propagate;
  final bool hasPropagate;
  final JsonLdContext? nonPropagatedParent;

  const JsonLdContext({
    this.terms = const {},
    this.keywordAliases = const {},
    this.vocab,
    this.hasVocab = false,
    this.language,
    this.hasLanguage = false,
    this.direction,
    this.hasDirection = false,
    this.base,
    this.hasBase = false,
    this.propagate = true,
    this.hasPropagate = false,
    this.nonPropagatedParent,
  });

  /// Merges [other] on top of this context (later context wins).
  JsonLdContext merge(JsonLdContext other) {
    return JsonLdContext(
      terms: {...terms, ...other.terms},
      keywordAliases: {...keywordAliases, ...other.keywordAliases},
      vocab: other.hasVocab ? other.vocab : vocab,
      hasVocab: other.hasVocab || hasVocab,
      language: other.hasLanguage ? other.language : language,
      hasLanguage: other.hasLanguage || hasLanguage,
      direction: other.hasDirection ? other.direction : direction,
      hasDirection: other.hasDirection || hasDirection,
      base: other.hasBase ? other.base : base,
      hasBase: other.hasBase || hasBase,
      propagate: other.hasPropagate ? other.propagate : propagate,
      hasPropagate: other.hasPropagate || hasPropagate,
      nonPropagatedParent: other.hasPropagate
          ? (other.propagate ? nonPropagatedParent : this)
          : (other.nonPropagatedParent ?? nonPropagatedParent),
    );
  }

  JsonLdContext copyWith({
    Map<String, TermDefinition>? terms,
    Map<String, String>? keywordAliases,
    String? vocab,
    bool? hasVocab,
    String? language,
    bool? hasLanguage,
    String? direction,
    bool? hasDirection,
    String? base,
    bool? hasBase,
    bool? propagate,
    bool? hasPropagate,
    JsonLdContext? nonPropagatedParent,
  }) {
    return JsonLdContext(
      terms: terms ?? this.terms,
      keywordAliases: keywordAliases ?? this.keywordAliases,
      vocab: vocab ?? this.vocab,
      hasVocab: hasVocab ?? this.hasVocab,
      language: language ?? this.language,
      hasLanguage: hasLanguage ?? this.hasLanguage,
      direction: direction ?? this.direction,
      hasDirection: hasDirection ?? this.hasDirection,
      base: base ?? this.base,
      hasBase: hasBase ?? this.hasBase,
      propagate: propagate ?? this.propagate,
      hasPropagate: hasPropagate ?? this.hasPropagate,
      nonPropagatedParent: nonPropagatedParent ?? this.nonPropagatedParent,
    );
  }
}
