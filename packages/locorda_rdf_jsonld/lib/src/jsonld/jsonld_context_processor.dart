/// JSON-LD Context Processing Algorithm.
///
/// Implements the shared context processing logic used by the decoder,
/// expansion processor, and compaction processor.
library jsonld_context_processor;

import 'dart:convert';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_codec.dart';
import 'package:locorda_rdf_core/extend.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_utils.dart';
import 'package:logging/logging.dart';

export 'package:locorda_rdf_jsonld/src/jsonld/jsonld_utils.dart'
    show rdfJsonDatatype;

final _log = Logger("rdf.jsonld.context");

/// The set of all JSON-LD keywords.
const jsonLdKeywords = {
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

/// Processes JSON-LD context definitions into active contexts.
///
/// This class encapsulates the W3C JSON-LD Context Processing Algorithm,
/// providing reusable context handling for the decoder, expansion processor,
/// and compaction processor.
class JsonLdContextProcessor {
  final String processingMode;
  final JsonLdContextDocumentProvider? contextDocumentProvider;
  final JsonLdContextDocumentCache? contextDocumentCache;
  final Map<String, Object?> preloadedParsedContextDocuments;
  final String format;

  /// Base URI from the document (document URL).
  final String? documentBaseUri;

  /// Guard against infinite recursion when applying scoped contexts.
  int _contextApplicationDepth = 0;
  static const int _maxContextApplicationDepth = 256;

  JsonLdContextProcessor({
    this.processingMode = 'json-ld-1.1',
    this.contextDocumentProvider,
    this.contextDocumentCache,
    this.preloadedParsedContextDocuments = const {},
    this.format = 'JSON-LD',
    this.documentBaseUri,
  });

  /// Extracts the `@context` from a JSON-LD node and merges it into
  /// [baseContext].
  JsonLdContext extractContext(
    Map<String, Object?> node, {
    JsonLdContext baseContext = const JsonLdContext(),
    String? effectiveBaseUri,
  }) {
    if (!node.containsKey('@context')) {
      return baseContext;
    }

    final nodeContext = node['@context'];
    return mergeContext(baseContext, nodeContext,
        seenContextIris: <String>{},
        contextDocumentBaseIri: effectiveBaseUri ?? documentBaseUri);
  }

  /// Merges an arbitrary JSON-LD context definition (`Map`, `List`, `String`)
  /// into [baseContext].
  JsonLdContext mergeContext(
    JsonLdContext baseContext,
    Object? definition, {
    required Set<String> seenContextIris,
    String? contextDocumentBaseIri,
    bool allowProtectedNullification = false,
    bool allowProtectedOverride = false,
    bool allowContextWrapper = false,
  }) {
    if (definition is Map) {
      final typedDef = (definition is Map<String, Object?>)
          ? definition
          : definition.cast<String, Object?>();
      // Remote context documents are often wrapped as {"@context": ...}.
      if (allowContextWrapper &&
          typedDef.length == 1 &&
          typedDef.containsKey('@context')) {
        return mergeContext(baseContext, typedDef['@context'],
            seenContextIris: seenContextIris,
            contextDocumentBaseIri: contextDocumentBaseIri,
            allowProtectedNullification: allowProtectedNullification,
            allowProtectedOverride: allowProtectedOverride,
            allowContextWrapper: allowContextWrapper);
      }
      return processSingleContext(typedDef, baseContext,
          seenContextIris: seenContextIris,
          contextDocumentBaseIri: contextDocumentBaseIri,
          allowProtectedOverride: allowProtectedOverride);
    }

    if (definition is List) {
      var merged = baseContext;
      for (final item in definition) {
        merged = mergeContext(merged, item,
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
          format: format,
        );
      }
      return const JsonLdContext();
    }

    throw RdfSyntaxException(
      'Invalid @context entry: ${definition.runtimeType}',
      format: format,
    );
  }

  /// Resolves and merges an external context document.
  JsonLdContext _mergeExternalContext(
    JsonLdContext baseContext,
    String contextRef, {
    required Set<String> seenContextIris,
    String? contextDocumentBaseIri,
  }) {
    final resolvedContextIri = resolveIri(
      contextRef,
      contextDocumentBaseIri ?? documentBaseUri ?? '',
    );
    final decoded = _loadExternalContextDocument(
      contextRef,
      baseIri: contextDocumentBaseIri,
      seenContextIris: seenContextIris,
    );

    return mergeContext(baseContext, decoded,
        seenContextIris: seenContextIris,
        contextDocumentBaseIri: resolvedContextIri,
        allowContextWrapper: true);
  }

  Object? _loadExternalContextDocument(
    String contextRef, {
    String? baseIri,
    required Set<String> seenContextIris,
    bool failOnCycle = false,
  }) {
    final effectiveBaseIri = baseIri ?? documentBaseUri ?? '';
    final resolvedContextIri = resolveIri(contextRef, effectiveBaseIri);

    if (seenContextIris.contains(resolvedContextIri)) {
      if (failOnCycle) {
        throw RdfSyntaxException(
          'invalid context entry',
          format: format,
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

    final cachedParsed = contextDocumentCache?.getParsed(resolvedContextIri);
    if (cachedParsed != null) {
      return cachedParsed;
    }

    final preloadedParsed = preloadedParsedContextDocuments[resolvedContextIri];
    Object? loaded = preloadedParsed;

    if (loaded == null && contextDocumentProvider != null) {
      loaded = contextDocumentProvider!.loadContextDocument(request);
    }

    if (loaded == null) {
      throw RdfSyntaxException(
        'Unable to resolve external context: $resolvedContextIri',
        format: format,
      );
    }

    Object? decoded;
    if (loaded is String) {
      try {
        decoded = json.decode(loaded);
      } catch (e) {
        throw RdfSyntaxException(
          'Invalid external context JSON at $resolvedContextIri: ${e.toString()}',
          format: format,
          cause: e,
        );
      }
    } else {
      decoded = loaded;
    }

    contextDocumentCache?.putParsed(resolvedContextIri, decoded);

    return decoded;
  }

  Map<String, Object?> _extractImportedContextDefinition(
    Object? importValue, {
    required Set<String> seenContextIris,
    String? contextDocumentBaseIri,
  }) {
    if (processingMode == 'json-ld-1.0') {
      throw RdfSyntaxException('invalid context entry', format: format);
    }
    if (importValue is! String) {
      throw RdfSyntaxException('invalid @import value', format: format);
    }

    final importedDocument = _loadExternalContextDocument(
      importValue,
      baseIri: contextDocumentBaseIri,
      seenContextIris: seenContextIris,
      failOnCycle: true,
    );
    if (importedDocument is! Map<String, Object?> ||
        !importedDocument.containsKey('@context')) {
      throw RdfSyntaxException('invalid remote context', format: format);
    }

    final importedContext = importedDocument['@context'];
    if (importedContext is! Map<String, Object?>) {
      throw RdfSyntaxException('invalid remote context', format: format);
    }
    if (importedContext.containsKey('@import')) {
      throw RdfSyntaxException('invalid context entry', format: format);
    }

    return importedContext;
  }

  /// Processes a single context object into a [JsonLdContext].
  JsonLdContext processSingleContext(
    Map<String, Object?> contextMap,
    JsonLdContext baseContext, {
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

    final terms = <String, TermDefinition>{};
    final keywordAliases = <String, String>{};
    String? vocab;
    bool hasVocab = false;
    String? language;
    bool hasLanguage = false;
    String? direction;
    bool hasDirection = false;
    String? base;
    bool hasBase = false;
    bool propagate = true;
    bool hasPropagate = false;
    final defaultProtected = effectiveContextMap['@protected'] == true;

    if (effectiveContextMap.containsKey('@base')) {
      final baseValue = effectiveContextMap['@base'];
      if (baseValue != null && baseValue is! String) {
        throw RdfSyntaxException('invalid base IRI', format: format);
      }
      hasBase = true;
      if (baseValue is String && containsInvalidIriChars(baseValue)) {
        base = null;
      } else {
        base = baseValue is String ? baseValue : null;
      }
      _log.fine('Found @base: $base');
    }

    final effectiveBase = _getEffectiveBaseFromContext(workingBase);
    final baseForResolution = hasBase
        ? (base == null
            ? null
            : (looksLikeAbsoluteIri(base)
                ? base
                : resolveIri(base, effectiveBase ?? '')))
        : effectiveBase;

    // First pass: collect context-wide keyword settings independent of order.
    for (final entry in effectiveContextMap.entries) {
      switch (entry.key) {
        case '@base':
          continue;
        case '@vocab':
          hasVocab = true;
          if (entry.value != null && entry.value is! String) {
            throw RdfSyntaxException('invalid vocab mapping', format: format);
          }
          if (entry.value is String) {
            final vocabValue = entry.value as String;
            if (processingMode == 'json-ld-1.0' &&
                !looksLikeAbsoluteIri(vocabValue) &&
                !vocabValue.startsWith('_:')) {
              throw RdfSyntaxException(
                'invalid vocab mapping',
                format: format,
              );
            }
            if (vocabValue.isEmpty) {
              vocab = baseForResolution;
            } else {
              // Try expanding @vocab as a compact IRI first (e.g. "ex:ns/")
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
                if (looksLikeAbsoluteIri(vocabValue) ||
                    vocabValue.startsWith('_:')) {
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
                format: format);
          }
          language = entry.value is String ? entry.value as String : null;
          _log.fine('Found @language: $language');
        case '@direction':
          hasDirection = true;
          if (entry.value != null &&
              (entry.value is! String ||
                  (entry.value != 'ltr' && entry.value != 'rtl'))) {
            throw RdfSyntaxException('invalid base direction', format: format);
          }
          direction = entry.value as String?;
          continue;
        case '@propagate':
          if (processingMode == 'json-ld-1.0') {
            throw RdfSyntaxException('invalid context entry', format: format);
          }
          if (entry.value is! bool) {
            throw RdfSyntaxException('invalid @propagate value',
                format: format);
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
            throw RdfSyntaxException('invalid @version value', format: format);
          }
          if (processingMode == 'json-ld-1.0') {
            throw RdfSyntaxException('processing mode conflict',
                format: format);
          }
          continue;
        default:
          continue;
      }
    }

    final normalizedBase = hasBase ? baseForResolution : base;

    var termResolutionContext = workingBase.merge(JsonLdContext(
      vocab: vocab,
      hasVocab: hasVocab,
      language: language,
      hasLanguage: hasLanguage,
      direction: direction,
      hasDirection: hasDirection,
      base: normalizedBase,
      hasBase: hasBase,
      propagate: propagate,
      hasPropagate: hasPropagate,
    ));

    // Second pass: parse aliases and term definitions using the resolved
    // context-wide settings so implicit term IRIs are scoped correctly.
    //
    // Process entries in dependency order: simple string values (prefix/alias
    // definitions) first, then complex object definitions (which may reference
    // those prefixes in @type, @id, etc.).
    final sortedEntries = effectiveContextMap.entries.toList()
      ..sort((a, b) {
        final aIsSimple = a.value is String || a.value == null;
        final bIsSimple = b.value is String || b.value == null;
        if (aIsSimple && !bIsSimple) return -1;
        if (!aIsSimple && bIsSimple) return 1;
        return 0;
      });
    for (final entry in sortedEntries) {
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
          if (jsonLdKeywords.contains(entry.key)) {
            // In JSON-LD 1.1, @type can be redefined with @container: @set
            // and/or @protected.
            if (entry.key == '@type' &&
                processingMode != 'json-ld-1.0' &&
                entry.value is Map<String, Object?>) {
              final typeDef = entry.value as Map<String, Object?>;
              final containers = parseContainerMappings(typeDef['@container']);
              if (containers.contains('@set')) {
                final isProtected =
                    typeDef['@protected'] == true || defaultProtected;
                final termDef = TermDefinition(
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
              format: format,
            );
          }

          // Skip @-prefixed term keys that look like keywords but aren't
          // actual JSON-LD keywords (e.g. "@ignoreMe"). Non-keyword-like
          // forms (e.g. "@", "@foo.bar") are valid term names.
          if (entry.key.startsWith('@') && isKeywordLikeAtForm(entry.key)) {
            continue;
          }

          final aliasTarget = entry.value;
          // Check if the value is a direct keyword or resolves to a keyword
          // through an existing alias chain (e.g. "url" → "id" → "@id").
          String? resolvedKeyword;
          if (aliasTarget is String) {
            if (jsonLdKeywords.contains(aliasTarget)) {
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
              throw RdfSyntaxException('invalid keyword alias', format: format);
            }
            final aliasDefinition = _validatedProtectedRedefinition(
              entry.key,
              termResolutionContext.terms[entry.key],
              TermDefinition(
                iri: resolvedKeyword,
                isProtected: defaultProtected,
              ),
              allowProtectedOverride: allowProtectedOverride,
            );
            keywordAliases[entry.key] = resolvedKeyword;
            terms[entry.key] = aliasDefinition;
            termResolutionContext = termResolutionContext.merge(
              JsonLdContext(
                terms: {entry.key: aliasDefinition},
                keywordAliases: {entry.key: resolvedKeyword},
              ),
            );
            continue;
          }

          var termDef = parseTermDefinition(
            entry.key,
            entry.value,
            termResolutionContext,
            contextDocumentBaseIri: contextDocumentBaseIri,
            defaultProtected: defaultProtected,
          );
          if (termDef != null) {
            validateTermDefinition(
              entry.key,
              termDef,
              termResolutionContext,
            );
            if (termDef.hasLocalContext &&
                _contextApplicationDepth < _maxContextApplicationDepth) {
              _contextApplicationDepth++;
              try {
                mergeContext(
                  termResolutionContext,
                  termDef.localContext,
                  seenContextIris: <String>{},
                  contextDocumentBaseIri: contextDocumentBaseIri,
                  allowProtectedNullification: true,
                  allowProtectedOverride: true,
                );
              } on RdfSyntaxException {
                throw RdfSyntaxException('invalid scoped context',
                    format: format);
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
                jsonLdKeywords.contains(termDef.iri)) {
              throw RdfSyntaxException(
                'invalid term definition',
                format: format,
              );
            }
            terms[entry.key] = termDef;
            // If the term's IRI is a keyword, register it as a keyword alias
            if (termDef.isNullMapping) {
              keywordAliases.remove(entry.key);
            }
            final termKeywordAlias =
                termDef.iri != null && jsonLdKeywords.contains(termDef.iri)
                    ? {entry.key: termDef.iri!}
                    : <String, String>{};
            if (termKeywordAlias.isNotEmpty) {
              keywordAliases.addAll(termKeywordAlias);
            }
            termResolutionContext = termResolutionContext.merge(
              JsonLdContext(
                terms: {entry.key: termDef},
                keywordAliases: termKeywordAlias,
              ),
            );
          }
      }
    }

    var merged = workingBase.merge(JsonLdContext(
      terms: terms,
      keywordAliases: keywordAliases,
      vocab: vocab,
      hasVocab: hasVocab,
      language: language,
      hasLanguage: hasLanguage,
      direction: direction,
      hasDirection: hasDirection,
      base: normalizedBase,
      hasBase: hasBase,
      propagate: propagate,
      hasPropagate: hasPropagate,
    ));

    // Remove keyword aliases for terms that were null-mapped in this context.
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

  /// Parses a single context entry value into a [TermDefinition].
  TermDefinition? parseTermDefinition(
      String key, Object? value, JsonLdContext resolutionContext,
      {String? contextDocumentBaseIri, required bool defaultProtected}) {
    if (key.isEmpty) {
      throw RdfSyntaxException('invalid term definition', format: format);
    }

    if (_isRelativeIriLikeTermKey(key)) {
      if (value is Map<String, Object?> && value['@prefix'] == true) {
        throw RdfSyntaxException('invalid term definition', format: format);
      }
      throw RdfSyntaxException('invalid IRI mapping', format: format);
    }

    if (value == null) {
      return TermDefinition(
        iri: null,
        isProtected: defaultProtected,
        isNullMapping: true,
      );
    }

    if (value is String) {
      // Keyword-like @-forms that aren't actual keywords produce null mappings.
      if (value.startsWith('@') &&
          isKeywordLikeAtForm(value) &&
          !jsonLdKeywords.contains(value)) {
        return TermDefinition(
          iri: null,
          isProtected: defaultProtected,
          isNullMapping: true,
          isKeywordLikeNull: true,
        );
      }
      final expandedValue = jsonLdKeywords.contains(value)
          ? value
          : expandTermIri(value, key, resolutionContext);
      _log.fine('Found term: $key -> $expandedValue');
      return TermDefinition(
        iri: expandedValue,
        isProtected: defaultProtected,
        isSimpleTermDefinition: true,
      );
    }

    if (value is Map<String, Object?>) {
      String? typeMapping;
      if (value.containsKey('@type')) {
        final rawTypeMapping = value['@type'];
        if (rawTypeMapping != null && rawTypeMapping is! String) {
          throw RdfSyntaxException('invalid type mapping', format: format);
        }
        if (rawTypeMapping is String) {
          typeMapping = rawTypeMapping;
          if (typeMapping == '@json') {
            if (processingMode == 'json-ld-1.0') {
              throw RdfSyntaxException('invalid type mapping', format: format);
            }
            typeMapping = rdfJsonDatatype;
          }
          if (typeMapping == '@none' && processingMode == 'json-ld-1.0') {
            throw RdfSyntaxException('invalid type mapping', format: format);
          }
          if (typeMapping != '@id' &&
              typeMapping != '@vocab' &&
              typeMapping != '@none' &&
              typeMapping != rdfJsonDatatype) {
            final expandedType = expandIri(typeMapping, resolutionContext);
            if (!looksLikeAbsoluteIri(expandedType)) {
              throw RdfSyntaxException('invalid type mapping', format: format);
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

      if (value.containsKey('@prefix')) {
        if (processingMode == 'json-ld-1.0') {
          throw RdfSyntaxException('invalid term definition', format: format);
        }
        if (value['@prefix'] is! bool) {
          throw RdfSyntaxException('invalid @prefix value', format: format);
        }
      }
      final hasPrefix = value.containsKey('@prefix');
      final isPrefix = value['@prefix'] == true;

      // @prefix: true is not allowed on compact IRI terms.
      if (isPrefix && key.contains(':')) {
        throw RdfSyntaxException('invalid term definition', format: format);
      }

      final hasNestMapping = value.containsKey('@nest');
      if (hasNestMapping) {
        if (processingMode == 'json-ld-1.0') {
          throw RdfSyntaxException('invalid term definition', format: format);
        }
        final nestVal = value['@nest'];
        if (nestVal is! String) {
          throw RdfSyntaxException('invalid @nest value', format: format);
        }
        // @nest value must be @nest or a term that is not a keyword.
        if (nestVal != '@nest' && jsonLdKeywords.contains(nestVal)) {
          throw RdfSyntaxException('invalid @nest value', format: format);
        }
      }

      // @context in term definition not allowed in 1.0.
      if (value.containsKey('@context') && processingMode == 'json-ld-1.0') {
        throw RdfSyntaxException('invalid term definition', format: format);
      }

      String? indexMapping;
      if (value.containsKey('@index')) {
        if (processingMode == 'json-ld-1.0') {
          throw RdfSyntaxException('invalid term definition', format: format);
        }
        final rawIndexMapping = value['@index'];
        if (rawIndexMapping is! String) {
          throw RdfSyntaxException('invalid term definition', format: format);
        }
        if (rawIndexMapping.startsWith('@')) {
          throw RdfSyntaxException('invalid term definition', format: format);
        }
        indexMapping = rawIndexMapping;
      }

      if (value.containsKey('@reverse')) {
        if (value.containsKey('@id')) {
          throw RdfSyntaxException('invalid reverse property', format: format);
        }
        if (value.containsKey('@nest')) {
          throw RdfSyntaxException('invalid reverse property', format: format);
        }
        final reverseIri = value['@reverse'];
        if (reverseIri is! String) {
          throw RdfSyntaxException('invalid IRI mapping', format: format);
        }
        // Keyword-like @-form that isn't a real keyword → null mapping
        if (reverseIri.startsWith('@') &&
            isKeywordLikeAtForm(reverseIri) &&
            !jsonLdKeywords.contains(reverseIri)) {
          return TermDefinition(
            iri: null,
            isNullMapping: true,
            isKeywordLikeNull: true,
            isProtected: isProtected,
          );
        }
        final expandedReverseIri = expandIri(reverseIri, resolutionContext);
        if (!looksLikeAbsoluteIri(expandedReverseIri)) {
          throw RdfSyntaxException('invalid IRI mapping', format: format);
        }
        final containers = parseContainerMappings(value['@container']);
        if (containers.contains('@list')) {
          throw RdfSyntaxException('invalid reverse property', format: format);
        }
        _log.fine('Found reverse term: $key -> $expandedReverseIri');
        return TermDefinition(
          iri: expandedReverseIri,
          isReverse: true,
          typeMapping: typeMapping,
          containers: containers,
          indexMapping: indexMapping,
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
          return TermDefinition(
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
          throw RdfSyntaxException('invalid IRI mapping', format: format);
        }
        if (idValue.startsWith('@') && !jsonLdKeywords.contains(idValue)) {
          if (isKeywordLikeAtForm(idValue)) {
            return TermDefinition(
              iri: null,
              isNullMapping: true,
              isKeywordLikeNull: true,
              isProtected: isProtected,
              isPrefix: isPrefix,
              hasPrefix: hasPrefix,
            );
          }
        }
        if (idValue == '@context') {
          throw RdfSyntaxException('invalid keyword alias', format: format);
        }
        if (idValue == '@type') {
          if (processingMode != 'json-ld-1.0') {
            // In JSON-LD 1.1, aliasing @type requires @container: @set
            // UNLESS it's a simple term alias (short key, not keyword/IRI).
            final containers = parseContainerMappings(value['@container']);
            if (!containers.contains('@set') &&
                (key.contains(':') || key.startsWith('@'))) {
              throw RdfSyntaxException('invalid IRI mapping', format: format);
            }
          }
        }
        final colonIndex = idValue.indexOf(':');
        if (colonIndex > 0 && idValue.substring(0, colonIndex) == key) {
          throw RdfSyntaxException('cyclic IRI mapping', format: format);
        }
        final expandedIdValue = jsonLdKeywords.contains(idValue)
            ? idValue
            : expandTermIri(idValue, key, resolutionContext);
        final containers = parseContainerMappings(value['@container']);
        if (indexMapping != null && !containers.contains('@index')) {
          throw RdfSyntaxException('invalid term definition', format: format);
        }
        // @container: @type requires @type to be @id or @vocab (or absent).
        if (containers.contains('@type') &&
            typeMapping != null &&
            typeMapping != '@id' &&
            typeMapping != '@vocab') {
          throw RdfSyntaxException('invalid type mapping', format: format);
        }
        _log.fine('Found complex term: $key -> $expandedIdValue');
        final langVal1 = value['@language'];
        if (langVal1 != null && langVal1 is! String) {
          throw RdfSyntaxException('invalid language mapping', format: format);
        }
        return TermDefinition(
          iri: expandedIdValue,
          indexMapping: indexMapping,
          typeMapping: typeMapping,
          containers: containers,
          language: langVal1 as String?,
          hasLanguage: value.containsKey('@language'),
          direction: value['@direction'] as String?,
          hasDirection: value.containsKey('@direction'),
          localContext: localContext,
          hasLocalContext: hasLocalContext,
          isProtected: isProtected,
          isPrefix: isPrefix,
          hasPrefix: hasPrefix,
          nestValue: hasNestMapping ? (value['@nest'] as String?) : null,
        );
      }

      // No @id — the term name itself is the IRI (expanded via vocab/prefix)
      if (value.containsKey('@type') ||
          value.containsKey('@container') ||
          value.containsKey('@language') ||
          value.containsKey('@direction') ||
          hasNestMapping) {
        _log.fine('Found type-only term: $key');
        final expandedKey = expandIri(key, resolutionContext);
        if (!resolutionContext.hasVocab &&
            expandedKey == key &&
            !key.contains(':')) {
          throw RdfSyntaxException('invalid IRI mapping', format: format);
        }
        final containers = parseContainerMappings(value['@container']);
        if (indexMapping != null && !containers.contains('@index')) {
          throw RdfSyntaxException('invalid term definition', format: format);
        }
        if (containers.contains('@type') &&
            typeMapping != null &&
            typeMapping != '@id' &&
            typeMapping != '@vocab') {
          throw RdfSyntaxException('invalid type mapping', format: format);
        }
        final langVal2 = value['@language'];
        if (langVal2 != null && langVal2 is! String) {
          throw RdfSyntaxException('invalid language mapping', format: format);
        }
        return TermDefinition(
          iri: expandedKey,
          indexMapping: indexMapping,
          typeMapping: typeMapping,
          containers: containers,
          language: langVal2 as String?,
          hasLanguage: value.containsKey('@language'),
          direction: value['@direction'] as String?,
          hasDirection: value.containsKey('@direction'),
          localContext: localContext,
          hasLocalContext: hasLocalContext,
          isProtected: isProtected,
          isPrefix: isPrefix,
          hasPrefix: hasPrefix,
          nestValue: hasNestMapping ? (value['@nest'] as String?) : null,
        );
      }

      if (hasLocalContext) {
        if (indexMapping != null) {
          throw RdfSyntaxException('invalid term definition', format: format);
        }
        final expandedKey = expandIri(key, resolutionContext);
        if (!resolutionContext.hasVocab &&
            expandedKey == key &&
            !key.contains(':')) {
          throw RdfSyntaxException('invalid IRI mapping', format: format);
        }
        return TermDefinition(
          iri: expandedKey,
          localContext: localContext,
          hasLocalContext: true,
          isProtected: isProtected,
          isPrefix: isPrefix,
          hasPrefix: hasPrefix,
        );
      }

      // Empty object term definitions
      if (indexMapping != null) {
        throw RdfSyntaxException('invalid term definition', format: format);
      }
      final expandedKey = expandIri(key, resolutionContext);
      return TermDefinition(
        iri: expandedKey,
        isProtected: isProtected,
        isPrefix: isPrefix,
        hasPrefix: hasPrefix,
      );
    }

    throw RdfSyntaxException('invalid term definition', format: format);
  }

  void validateTermDefinition(
    String key,
    TermDefinition termDef,
    JsonLdContext resolutionContext,
  ) {
    if (processingMode == 'json-ld-1.0') {
      return;
    }

    if (termDef.iri != null && key.contains(':')) {
      final colonIndex = key.indexOf(':');
      final prefix = key.substring(0, colonIndex);
      if (prefix != '_' && !key.substring(colonIndex + 1).startsWith('//')) {
        final prefixDef = resolutionContext.terms[prefix];
        if (prefixDef != null &&
            prefixDef.iri != null &&
            checkCanUseAsPrefix(prefixDef)) {
          final expandedPrefixIri =
              expandIri(prefixDef.iri!, resolutionContext);
          final expectedIri =
              '$expandedPrefixIri${key.substring(colonIndex + 1)}';
          final expandedTermIri = expandIri(termDef.iri!, resolutionContext);
          if (expandedTermIri != expectedIri) {
            throw RdfSyntaxException(
              'invalid IRI mapping',
              format: format,
            );
          }
        }
      }
    }
  }

  Object? _normalizeLocalContextReferences(
      Object? localContext, String? baseIri) {
    if (localContext == null || baseIri == null) {
      return localContext;
    }
    if (localContext is String) {
      return resolveIri(localContext, baseIri);
    }
    if (localContext is List) {
      return localContext
          .map((item) => _normalizeLocalContextReferences(item, baseIri))
          .toList(growable: false);
    }
    return localContext;
  }

  TermDefinition _validatedProtectedRedefinition(
      String key, TermDefinition? existing, TermDefinition replacement,
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
        format: format,
      );
    }

    return TermDefinition(
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
      isSimpleTermDefinition: replacement.isSimpleTermDefinition,
    );
  }

  bool _termDefinitionsEquivalent(
    TermDefinition left,
    TermDefinition right,
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
        jsonValueDeepEquals(left.localContext, right.localContext);
  }

  Set<String> parseContainerMappings(Object? containerValue) {
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
        throw RdfSyntaxException('invalid container mapping', format: format);
      }
      if (processingMode == 'json-ld-1.0' &&
          (value == '@id' ||
              value == '@type' ||
              value == '@graph' ||
              value == '@nest')) {
        throw RdfSyntaxException('invalid container mapping', format: format);
      }
    }

    if (containerValue is String) {
      validateContainer(containerValue);
      return {containerValue};
    }
    if (containerValue is List) {
      // Array-form @container is only allowed in JSON-LD 1.1.
      if (processingMode == 'json-ld-1.0') {
        throw RdfSyntaxException('invalid container mapping', format: format);
      }
      final mapped = <String>{};
      for (final item in containerValue) {
        if (item is! String) {
          throw RdfSyntaxException('invalid container mapping', format: format);
        }
        validateContainer(item);
        mapped.add(item);
      }
      // @list may not be combined with other container keywords.
      if (mapped.contains('@list') && mapped.length > 1) {
        throw RdfSyntaxException('invalid container mapping', format: format);
      }
      return mapped;
    }
    if (containerValue != null) {
      throw RdfSyntaxException('invalid container mapping', format: format);
    }
    return const <String>{};
  }

  /// Expand an IRI from a term definition's @id value.
  ///
  /// Like [expandIri] but skips looking up [excludeTerm] to avoid
  /// resolving the value through the term's own previous definition.
  String expandTermIri(
      String value, String excludeTerm, JsonLdContext context) {
    if (value == excludeTerm) {
      // Self-referencing term: only try compact IRI (colon) expansion,
      // NOT term lookup, to avoid resolving through the previous definition.
      if (value.contains(':')) {
        final colonIndex = value.indexOf(':');
        final prefix = value.substring(0, colonIndex);
        final localName = value.substring(colonIndex + 1);
        final prefixDef = context.terms[prefix];
        if (prefixDef != null &&
            !prefixDef.isNullMapping &&
            prefixDef.iri != null &&
            checkCanUseAsPrefix(prefixDef)) {
          return '${prefixDef.iri}$localName';
        }
      }
      if (value.startsWith('_:') || looksLikeAbsoluteIri(value)) {
        return value;
      }
      if (context.vocab != null) {
        return '${context.vocab}$value';
      }
      return value;
    }
    return expandIri(value, context);
  }

  /// Expand a predicate/IRI using term definitions, prefix expansion,
  /// and @vocab fallback.
  String expandIri(String key, JsonLdContext context) {
    // Check term definitions first
    final termDef = context.terms[key];
    if (termDef != null && !termDef.isKeywordLikeNull) {
      if (termDef.isNullMapping) {
        return key;
      }
      if (termDef.iri == null) {
        return key;
      }
      final iri = termDef.iri!;
      if (iri.startsWith('http://') || iri.startsWith('https://')) {
        return iri;
      }
      if (iri.contains(':')) {
        final expanded = _expandPrefixedIri(iri, context);
        if (expanded != iri) return expanded;
      }
      if (context.vocab != null && !iri.contains(':')) {
        return '${context.vocab}$iri';
      }
      return iri;
    }

    // Not in terms (or keyword-like null mapping) — try prefix expansion
    final expanded = _expandPrefixedIri(key, context);
    if (expanded != key) return expanded;

    // Keep blank node identifiers and absolute IRIs unchanged.
    if (key.startsWith('_:') || looksLikeAbsoluteIri(key)) {
      return key;
    }

    // Vocab fallback
    if (context.vocab != null) {
      return '${context.vocab}$key';
    }

    _log.warning('Could not expand predicate: $key');
    return key;
  }

  /// Expand a prefixed IRI using the active context's term definitions.
  String _expandPrefixedIri(String iri, JsonLdContext context) {
    if (iri.startsWith('http://') ||
        iri.startsWith('https://') ||
        iri.startsWith('_:')) {
      return iri;
    }

    if (iri.contains(':')) {
      final colonIndex = iri.indexOf(':');
      final prefix = iri.substring(0, colonIndex);
      final localName = iri.substring(colonIndex + 1);
      final prefixDef = context.terms[prefix];
      if (prefixDef != null &&
          !prefixDef.isNullMapping &&
          prefixDef.iri != null &&
          checkCanUseAsPrefix(prefixDef)) {
        return '${prefixDef.iri}$localName';
      }
    }

    final termDef = context.terms[iri];
    if (termDef != null && !termDef.isNullMapping && termDef.iri != null) {
      return termDef.iri!;
    }

    _log.warning('Could not expand prefixed IRI: $iri');
    return iri;
  }

  /// Delegates to shared [canUseAsPrefix] with this processor's mode.
  bool checkCanUseAsPrefix(TermDefinition def) =>
      canUseAsPrefix(def, processingMode: processingMode);

  /// Delegates to shared [canUseAsPrefixStrict] with this processor's mode.
  bool checkCanUseAsPrefixStrict(TermDefinition def) =>
      canUseAsPrefixStrict(def, processingMode: processingMode);

  /// Resolves the keyword alias for a key in the given context.
  String resolveKeywordAlias(String key, JsonLdContext context) {
    return context.keywordAliases[key] ?? key;
  }

  /// Returns the effective base URI from the context, falling back to
  /// the document base URI.
  String? _getEffectiveBaseFromContext(JsonLdContext context) {
    if (context.hasBase) {
      if (context.base == null) {
        return null;
      }
      final baseValue = context.base!;
      return looksLikeAbsoluteIri(baseValue)
          ? baseValue
          : resolveIri(baseValue, documentBaseUri ?? '');
    }
    return documentBaseUri;
  }

  /// Returns the effective base URI for a given context, considering
  /// both the context's @base and the document base URI.
  String? getEffectiveBase(JsonLdContext context) {
    return _getEffectiveBaseFromContext(context);
  }

  // --- Static utility methods ---

  static final _absoluteIriPrefixPattern = RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*:');

  /// Returns `true` if [value] looks like an absolute IRI.
  static bool looksLikeAbsoluteIri(String value) =>
      _absoluteIriPrefixPattern.hasMatch(value);

  static final _invalidIriCharsPattern = RegExp(r'[<>{}\|\\^\s`]');

  static bool containsInvalidIriChars(String value) {
    return _invalidIriCharsPattern.hasMatch(value);
  }

  static bool hasMultipleFragmentDelimiters(String iri) {
    return '#'.allMatches(iri).length > 1;
  }

  static final _keywordLikeAtFormPattern = RegExp(r'^@[a-zA-Z]+$');

  /// Returns `true` if [value] looks like a JSON-LD keyword form:
  /// `@` followed by one or more ASCII alphabetic characters.
  static bool isKeywordLikeAtForm(String value) {
    if (value.length <= 1) return false;
    return _keywordLikeAtFormPattern.hasMatch(value);
  }

  static bool _isRelativeIriLikeTermKey(String key) {
    return key.startsWith('./') ||
        key.startsWith('../') ||
        key.startsWith('/') ||
        key.startsWith('?') ||
        key.startsWith('#');
  }
}
