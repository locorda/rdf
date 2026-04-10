/// JSON-LD 1.1 Expansion Algorithm.
///
/// Implements the W3C JSON-LD 1.1 Expansion Algorithm (§ 4.1 of the
/// JSON-LD 1.1 Processing Algorithms and API specification).
///
/// The expansion processor takes a parsed JSON value and produces expanded
/// JSON-LD — a `List<Object?>` of node objects where all IRIs are absolute,
/// all values are explicit value objects, and no `@context` is present.
///
/// See: https://www.w3.org/TR/json-ld11-api/#expansion-algorithm
library jsonld_expansion_processor;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/iri_util.dart';
import 'package:locorda_rdf_core/src/jsonld/jsonld_context_documents.dart';
import 'package:logging/logging.dart';

final _log = Logger('rdf.jsonld.expansion');

// ---------------------------------------------------------------------------
// Well-known IRI constants
// ---------------------------------------------------------------------------

const _rdfJsonDatatype = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#JSON';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Implements the W3C JSON-LD 1.1 Expansion Algorithm.
///
/// Takes a parsed JSON value (from `jsonDecode`) and returns expanded JSON-LD
/// as a `List<Object?>` of node objects with no `@context`, all IRIs absolute,
/// and all values in explicit object form.
class JsonLdExpansionProcessor {
  final String processingMode;
  final JsonLdContextDocumentProvider? contextDocumentProvider;
  final JsonLdContextDocumentCache? contextDocumentCache;
  final Map<String, Object?> preloadedParsedContextDocuments;
  final String? documentBaseUri;

  const JsonLdExpansionProcessor({
    this.processingMode = 'json-ld-1.1',
    this.contextDocumentProvider,
    this.contextDocumentCache,
    this.preloadedParsedContextDocuments = const {},
    this.documentBaseUri,
  });

  /// Expands a parsed JSON-LD document to expanded form.
  ///
  /// [input] is the result of `jsonDecode(jsonString)`.
  /// [documentUrl] is the URL of the document (for resolving relative IRIs).
  /// [expandContext] is an optional context to apply before the document's own.
  List<Object?> expand(
    Object? input, {
    String? documentUrl,
    Object? expandContext,
    bool ordered = false,
  }) {
    final effectiveBase = documentUrl ?? documentBaseUri;
    final contextProcessor = JsonLdContextProcessor(
      processingMode: processingMode,
      contextDocumentProvider: contextDocumentProvider,
      contextDocumentCache: contextDocumentCache,
      preloadedParsedContextDocuments: preloadedParsedContextDocuments,
      format: 'JSON-LD',
      documentBaseUri: effectiveBase,
    );

    // Build initial context — apply expandContext if provided.
    var initialContext = JsonLdContext(
      base: effectiveBase,
      hasBase: effectiveBase != null,
    );

    if (expandContext != null) {
      // expandContext may itself be wrapped as {"@context": ...}
      Object? contextValue = expandContext;
      if (contextValue is Map<String, Object?> &&
          contextValue.containsKey('@context')) {
        contextValue = contextValue['@context'];
      }
      initialContext = contextProcessor.mergeContext(
        initialContext,
        contextValue,
        seenContextIris: <String>{},
        contextDocumentBaseIri: effectiveBase,
      );
    }

    final expander = _Expander(
      contextProcessor: contextProcessor,
      processingMode: processingMode,
      documentBaseUri: effectiveBase,
      ordered: ordered,
    );

    return expander.expandDocument(input, initialContext);
  }
}

// ---------------------------------------------------------------------------
// Internal expander implementation
// ---------------------------------------------------------------------------

/// Internal expansion engine.  One instance is created per [expand] call.
class _Expander {
  final JsonLdContextProcessor contextProcessor;
  final String processingMode;
  final String? documentBaseUri;
  final bool ordered;

  static const String _format = 'JSON-LD';

  /// Guard against deeply recursive scoped-context application.
  int _contextApplicationDepth = 0;
  static const int _maxContextApplicationDepth = 256;

  _Expander({
    required this.contextProcessor,
    required this.processingMode,
    required this.documentBaseUri,
    this.ordered = false,
  });

  // -------------------------------------------------------------------------
  // Top-level document expansion
  // -------------------------------------------------------------------------

  /// Entry point: expand a whole document.
  List<Object?> expandDocument(Object? input, JsonLdContext activeContext) {
    if (input == null) return [];

    if (input is List) {
      final result = <Object?>[];
      for (final item in input) {
        final expanded =
            _expandElement(item, activeContext, null, fromMap: false);
        if (expanded is List) {
          result.addAll(expanded);
        } else if (expanded != null) {
          result.add(expanded);
        }
      }
      return result;
    }

    if (input is Map<String, Object?>) {
      final expanded =
          _expandElement(input, activeContext, null, fromMap: false);
      if (expanded == null) return [];
      if (expanded is List) return expanded;

      // W3C spec § 4.1 step 7: if the expanded result is a map that contains
      // only @graph (no @id, no other properties), return the @graph contents.
      if (expanded is Map<String, Object?>) {
        if (expanded.containsKey('@graph') &&
            !expanded.containsKey('@id') &&
            expanded.keys.every((k) => k == '@graph' || k == '@context')) {
          final graph = expanded['@graph'];
          if (graph is List) return graph;
          if (graph != null) return [graph];
          return [];
        }
      }
      return [expanded];
    }

    return [];
  }

  // -------------------------------------------------------------------------
  // Core expansion algorithm
  // -------------------------------------------------------------------------

  /// Expand a single element within [activeContext].
  ///
  /// Returns `null` to drop the element, a `List<Object?>` for multiple
  /// values, or a single node/value object.
  Object? _expandElement(
    Object? element,
    JsonLdContext activeContext,
    String? activeProperty, {
    required bool fromMap,
    bool propertyScoped = false,
  }) {
    if (element == null) {
      return null;
    }

    // Non-string scalar: wrap as {@value: v} when inside a property.
    if (element is num || element is bool) {
      if (activeProperty == null || activeProperty == '@graph') return null;
      return _expandScalar(element, activeContext, activeProperty);
    }

    // String scalar.
    if (element is String) {
      if (activeProperty == null || activeProperty == '@graph') return null;
      return _expandStringScalar(element, activeContext, activeProperty);
    }

    // Array.
    if (element is List) {
      return _expandArray(
          element.cast<Object?>(), activeContext, activeProperty,
          fromMap: fromMap);
    }

    // Object / map.
    if (element is Map<String, Object?>) {
      return _expandObject(element, activeContext, activeProperty,
          fromMap: fromMap, propertyScoped: propertyScoped);
    }

    return null;
  }

  // -------------------------------------------------------------------------
  // Scalar expansion
  // -------------------------------------------------------------------------

  /// Expand a non-string scalar (bool / num).
  ///
  /// Per the expansion spec: non-string scalars simply become
  /// `{"@value": value}` — type coercion is applied when the active
  /// term definition has a typeMapping that overrides the native type.
  JsonObject _expandScalar(
    Object value,
    JsonLdContext context,
    String activeProperty,
  ) {
    final termDef = context.terms[activeProperty];

    // If the term has @type: @json, wrap as JSON literal.
    if (termDef?.typeMapping == _rdfJsonDatatype) {
      return {'@value': value, '@type': '@json'};
    }

    // If the term has an explicit @type coercion (not @id, @vocab, @none),
    // apply it to the native value.
    if (termDef?.typeMapping != null &&
        termDef!.typeMapping != '@id' &&
        termDef.typeMapping != '@vocab' &&
        termDef.typeMapping != '@none') {
      return {'@value': value, '@type': termDef.typeMapping};
    }

    // All other native scalars become plain @value objects with no @type.
    return {'@value': value};
  }

  /// Expand a string scalar to a value or node-reference object.
  Object? _expandStringScalar(
    String value,
    JsonLdContext context,
    String activeProperty,
  ) {
    // Keyword-like @-form that isn't a real keyword → drop.
    if (_isUnknownKeywordLike(value)) return null;

    final termDef = context.terms[activeProperty];

    // @type coercion: @id → node reference.
    if (termDef?.typeMapping == '@id') {
      final expanded = _expandIriReference(value, context);
      if (expanded == null) return null;
      return {'@id': expanded};
    }

    // @type coercion: @vocab → node reference (using vocab expansion).
    if (termDef?.typeMapping == '@vocab') {
      var expanded = contextProcessor.expandIri(value, context);
      if (!_isUsableIri(expanded) && !expanded.startsWith('_:')) {
        // If vocab expansion didn't produce an absolute IRI, resolve
        // against the document base as a fallback.
        final resolved = _expandIriReference(expanded, context);
        if (resolved != null && _isUsableIri(resolved)) {
          expanded = resolved;
        } else {
          return null;
        }
      }
      return {'@id': expanded};
    }

    // @type coercion: explicit datatype (including @json).
    if (termDef?.typeMapping != null &&
        termDef!.typeMapping != '@none' &&
        termDef.typeMapping != '@id' &&
        termDef.typeMapping != '@vocab') {
      if (termDef.typeMapping == _rdfJsonDatatype) {
        return {'@value': value, '@type': '@json'};
      }
      return {'@value': value, '@type': termDef.typeMapping};
    }

    // Build value object with per-term / per-context language and direction.
    return _makeStringValueObject(value, context, termDef);
  }

  /// Build a `{"@value": ...}` object for a plain string, applying language
  /// and direction from the term definition or active context.
  JsonObject _makeStringValueObject(
    String value,
    JsonLdContext context,
    TermDefinition? termDef,
  ) {
    // Term-level language override (even null explicitly clears language).
    if (termDef?.hasLanguage == true) {
      if (termDef!.language == null) {
        // Explicit null language: plain string with no language.
        // Still apply direction from term or context.
        if (termDef.hasDirection) {
          if (termDef.direction != null) {
            return {'@value': value, '@direction': termDef.direction!};
          }
          // Explicit null direction: suppress context direction too.
          return {'@value': value};
        }
        if (context.hasDirection && context.direction != null) {
          return {'@value': value, '@direction': context.direction!};
        }
        return {'@value': value};
      }
      final result = <String, Object?>{
        '@value': value,
        '@language': termDef.language!.toLowerCase(),
      };
      if (termDef.hasDirection) {
        if (termDef.direction != null) {
          result['@direction'] = termDef.direction!;
        }
        // Explicit null direction: suppress context direction.
      } else if (context.hasDirection && context.direction != null) {
        result['@direction'] = context.direction!;
      }
      return result;
    }

    // Term-level direction override.
    if (termDef?.hasDirection == true) {
      if (termDef!.direction == null) {
        // Explicit null direction: clear direction.
        if (context.hasLanguage && context.language != null) {
          return {'@value': value, '@language': context.language!.toLowerCase()};
        }
        return {'@value': value};
      }
      final result = <String, Object?>{
        '@value': value,
        '@direction': termDef.direction!,
      };
      if (context.hasLanguage && context.language != null) {
        result['@language'] = context.language!.toLowerCase();
      }
      return result;
    }

    // Default language from context.
    if (context.hasLanguage) {
      if (context.language == null) {
        return {'@value': value};
      }
      final result = <String, Object?>{
        '@value': value,
        '@language': context.language!.toLowerCase(),
      };
      if (context.hasDirection && context.direction != null) {
        result['@direction'] = context.direction!;
      }
      return result;
    }

    // Default direction from context.
    if (context.hasDirection && context.direction != null) {
      return {'@value': value, '@direction': context.direction!};
    }

    return {'@value': value};
  }

  // -------------------------------------------------------------------------
  // Array expansion
  // -------------------------------------------------------------------------

  List<Object?> _expandArray(
    List<Object?> array,
    JsonLdContext context,
    String? activeProperty, {
    required bool fromMap,
  }) {
    final result = <Object?>[];
    for (final item in array) {
      final expanded = _expandElement(item, context, activeProperty,
          fromMap: fromMap);
      if (expanded is List) {
        result.addAll(expanded);
      } else if (expanded != null) {
        result.add(expanded);
      }
    }
    return result;
  }

  // -------------------------------------------------------------------------
  // Object expansion
  // -------------------------------------------------------------------------

  Object? _expandObject(
    Map<String, Object?> element,
    JsonLdContext activeContext,
    String? activeProperty, {
    required bool fromMap,
    bool propertyScoped = false,
  }) {
    // Step 2: Revert non-propagated type-scoped contexts.
    // Per W3C spec § 13.4.2: if the active context has a previous context
    // (propagate: false) and element has no @type, revert to previous.
    // However, pure keyword objects (like node references with only @id)
    // use the inherited context — reversion only applies to elements that
    // have non-keyword properties that would benefit from the reverted context.
    //
    // When propertyScoped is true, the propagate: false came from a
    // property-scoped context. Per § 9.16, property-scoped contexts apply
    // to the property's values but don't propagate across node objects.
    // So we skip reversion for the immediate value and instead let nested
    // node objects revert.
    var context = activeContext;
    if (!propertyScoped && context.hasPropagate && !context.propagate) {
      final hasType = _getKeywordValue(element, '@type', context) != null;
      if (!hasType) {
        // Check if element has any non-keyword properties.
        final hasNonKeywordProps = element.keys.any((k) {
          final resolved = _resolveAlias(k, context);
          return !jsonLdKeywords.contains(resolved);
        });
        if (hasNonKeywordProps) {
          context = context.nonPropagatedParent ?? context;
        }
      }
    }

    // Step 5: Process @context.
    if (element.containsKey('@context')) {
      context = contextProcessor.mergeContext(
        context,
        element['@context'],
        seenContextIris: <String>{},
        contextDocumentBaseIri:
            contextProcessor.getEffectiveBase(context) ?? documentBaseUri,
      );
    }

    // Step 8: Apply type-scoped contexts.
    // We need the "previous context" (before type-scoped merge) for type
    // value expansion per the spec.
    final previousContext = context;
    context = _applyTypeScopedContexts(element, context);

    // For property-scoped contexts with @propagate: false, re-introduce the
    // propagation flag now (after skipping the reversion at the top).
    // This ensures that nested node objects will see propagate: false and revert.
    if (propertyScoped && activeContext.hasPropagate && !activeContext.propagate) {
      if (!context.hasPropagate || context.propagate) {
        context = context.copyWith(
          propagate: false,
          hasPropagate: true,
          nonPropagatedParent: activeContext.nonPropagatedParent,
        );
      }
    }

    // Step 4: Canonicalize keyword aliases.
    final canonicalized = _canonicalizeKeywords(element, context);

    // Step 5: Validate the input object structure.
    _validateInput(canonicalized);

    // Step 6: Build the result by processing each key.
    final result = <String, Object?>{};

    final entries = ordered
        ? (canonicalized.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)))
        : canonicalized.entries.toList();
    for (final entry in entries) {
      final key = entry.key;
      final value = entry.value;
      final resolvedKey = _resolveAlias(key, context);

      // @context was already processed — skip.
      if (resolvedKey == '@context') continue;

      if (_isUnknownKeywordLike(resolvedKey)) continue;

      // @nest aliases are routed through _processProperty so their
      // property-scoped context is applied (the keyword handler doesn't
      // know the original term definition).
      if (resolvedKey == '@nest' && key != '@nest') {
        _processProperty(
          key, value, context, result, activeProperty: activeProperty);
        continue;
      }

      if (jsonLdKeywords.contains(resolvedKey)) {
        _processKeyword(
          resolvedKey,
          value,
          context,
          previousContext,
          result,
          activeProperty: activeProperty,
          activeContext: activeContext,
        );
        continue;
      }

      // Regular property.
      _processProperty(
        key,
        value,
        context,
        result,
        activeProperty: activeProperty,
      );
    }

    // Step 7: Finalize.
    return _finalizeObject(result, context, activeContext, activeProperty,
        fromMap: fromMap);
  }

  // -------------------------------------------------------------------------
  // Keyword processing
  // -------------------------------------------------------------------------

  void _processKeyword(
    String keyword,
    Object? value,
    JsonLdContext context,
    JsonLdContext previousContext,
    JsonObject result, {
    required String? activeProperty,
    required JsonLdContext activeContext,
  }) {
    switch (keyword) {
      case '@id':
        _processId(value, context, result);

      case '@type':
        // Type values are expanded using the context BEFORE type-scoped merge
        // (previousContext), per spec § 4.1.1 step 9.
        _processType(value, previousContext, result);

      case '@value':
        result['@value'] = value;

      case '@language':
        if (value != null && value is! String) {
          throw RdfSyntaxException(
            'invalid language-tagged value: @language must be a string',
            format: _format,
          );
        }
        result['@language'] = value is String ? value.toLowerCase() : null;

      case '@direction':
        if (value != null &&
            (value is! String || (value != 'ltr' && value != 'rtl'))) {
          throw RdfSyntaxException(
            '@direction must be "ltr" or "rtl"',
            format: _format,
          );
        }
        result['@direction'] = value;

      case '@index':
        if (value is! String) {
          throw RdfSyntaxException(
            '@index value must be a string',
            format: _format,
          );
        }
        result['@index'] = value;

      case '@graph':
        _processGraph(value, context, result);

      case '@reverse':
        _processReverse(value, context, result);

      case '@included':
        if (processingMode == 'json-ld-1.0') {
          throw RdfSyntaxException(
            'invalid keyword in 1.0 mode: @included',
            format: _format,
          );
        }
        _processIncluded(value, context, result);

      case '@nest':
        _processNest(value, context, result, activeProperty: activeProperty);

      case '@list':
        // Free-floating @list at the top level or inside @graph is dropped
        // per W3C spec (the entire node becomes invalid). We still process the
        // @list and add it to result so that _finalizeObject can drop the whole
        // node. For strict null activeProperty, also drop.
        if (activeProperty == null) {
          throw RdfSyntaxException(
            'invalid set or list object',
            format: _format,
          );
        }
        final listItems = _expandArray(
          value is List ? value.cast<Object?>() : [value],
          context,
          activeProperty == '@graph' ? '@graph' : activeProperty,
          fromMap: false,
        );
        if (activeProperty != '@graph') {
          _checkNoListOfLists(listItems);
        }
        result['@list'] = listItems;

      case '@set':
        final items = _expandArray(
          value is List ? value.cast<Object?>() : [value],
          context,
          activeProperty,
          fromMap: false,
        );
        _mergeValues(result, '@set', items);

      default:
        // Ignore other keywords (@base, @vocab, @version, etc.)
        break;
    }
  }

  void _processId(Object? value, JsonLdContext context, JsonObject result) {
    if (value is! String) {
      throw RdfSyntaxException('@id value must be a string', format: _format);
    }
    if (_isUnknownKeywordLike(value)) {
      // Unknown keyword-like @-forms produce null @id per the spec.
      result['@id'] = null;
      return;
    }
    final expanded = _expandIriReference(value, context);
    if (expanded != null) {
      result['@id'] = expanded;
    }
  }

  void _processType(Object? value, JsonLdContext context, JsonObject result) {
    final List<String> rawTypes;
    if (value is String) {
      rawTypes = [value];
    } else if (value is List) {
      rawTypes = value.whereType<String>().toList();
    } else if (value == null) {
      return;
    } else {
      throw RdfSyntaxException('invalid type value', format: _format);
    }

    final expanded = <String>[];
    for (final t in rawTypes) {
      if (_isUnknownKeywordLike(t)) continue;
      // Special JSON-LD 1.1 keywords allowed as @type values.
      if (t == '@json' || t == '@none') {
        expanded.add(t);
        continue;
      }
      // Type values are expanded using @vocab fallback first.
      var expandedT = contextProcessor.expandIri(t, context);
      // Preserve special type keywords after expansion.
      if (expandedT == '@json' || expandedT == '@none') {
        expanded.add(expandedT);
        continue;
      }
      // If expandIri didn't fully resolve (still relative or unchanged),
      // resolve against base IRI.
      if (!_isUsableIri(expandedT) && !expandedT.startsWith('_:')) {
        final resolved = _expandIriReference(expandedT, context);
        if (resolved != null) expandedT = resolved;
      }
      if (_isUsableIri(expandedT) || expandedT.startsWith('_:')) {
        expanded.add(expandedT);
      } else if (context.base == null && expandedT.isNotEmpty) {
        // When @base is explicitly set to null, relative IRIs cannot be
        // resolved — preserve them as-is per the spec.
        expanded.add(expandedT);
      }
    }

    if (expanded.isNotEmpty) {
      final existing = result['@type'];
      if (existing is List<String>) {
        result['@type'] = [...existing, ...expanded];
      } else {
        result['@type'] = expanded;
      }
    }
  }

  void _processGraph(Object? value, JsonLdContext context, JsonObject result) {
    final expanded =
        _expandElement(value, context, '@graph', fromMap: false);
    final List<Object?> items;
    if (expanded is List) {
      items = expanded;
    } else if (expanded != null) {
      items = [expanded];
    } else {
      items = [];
    }
    result['@graph'] = items;
  }

  void _processReverse(
      Object? value, JsonLdContext context, JsonObject result) {
    if (value is! Map<String, Object?>) {
      throw RdfSyntaxException(
        '@reverse value must be an object',
        format: _format,
      );
    }

    // Expand the reverse map as if it were a node object.
    final expanded = _expandObject(value, context, '@reverse', fromMap: false);

    if (expanded is! Map<String, Object?>) return;

    // Items inside @reverse.@reverse go to the top-level object.
    if (expanded.containsKey('@reverse')) {
      final reverseOfReverse = expanded['@reverse'];
      if (reverseOfReverse is Map<String, Object?>) {
        for (final entry in reverseOfReverse.entries) {
          _mergeValues(result, entry.key, entry.value);
        }
      }
    }

    // Collect remaining expanded reverse properties.
    final reverseMap =
        result['@reverse'] as Map<String, Object?>? ?? <String, Object?>{};
    for (final entry in expanded.entries) {
      if (entry.key == '@reverse') continue;
      // @id inside @reverse is invalid per the spec.
      if (entry.key == '@id') {
        throw RdfSyntaxException(
          'invalid reverse property map',
          format: _format,
        );
      }
      if (entry.key == '@type') continue;
      final vals =
          entry.value is List ? entry.value as List<Object?> : [entry.value];
      for (final v in vals) {
        if (v is Map<String, Object?> &&
            (v.containsKey('@value') || v.containsKey('@list'))) {
          throw RdfSyntaxException(
            'invalid reverse property value: value/list objects are not valid',
            format: _format,
          );
        }
      }
      _mergeValues(reverseMap, entry.key, vals);
    }

    if (reverseMap.isNotEmpty) {
      result['@reverse'] = reverseMap;
    }
  }

  void _processIncluded(
      Object? value, JsonLdContext context, JsonObject result) {
    // Validate raw input: @included values must be node objects (maps),
    // not scalars or value objects.
    final rawList = value is List ? value : [value];
    for (final raw in rawList) {
      if (raw is! Map<String, Object?>) {
        throw RdfSyntaxException(
          'invalid @included value',
          format: _format,
        );
      }
      // Value objects are not allowed in @included.
      if (raw.containsKey('@value')) {
        throw RdfSyntaxException(
          'invalid @included value',
          format: _format,
        );
      }
    }

    final expanded =
        _expandElement(value, context, null, fromMap: false);
    final List<Object?> items;
    if (expanded is List) {
      items = expanded;
    } else if (expanded != null) {
      items = [expanded];
    } else {
      items = [];
    }
    for (final item in items) {
      if (item is! Map<String, Object?>) {
        throw RdfSyntaxException(
          'invalid @included value: items must be node objects',
          format: _format,
        );
      }
      if (item.containsKey('@value') || item.containsKey('@list')) {
        throw RdfSyntaxException(
          'invalid @included value: value and list objects not allowed',
          format: _format,
        );
      }
    }
    if (items.isNotEmpty) {
      _mergeValues(result, '@included', items);
    }
  }

  void _processNest(
    Object? value,
    JsonLdContext context,
    JsonObject result, {
    required String? activeProperty,
  }) {
    final nestItems = value is List ? value.cast<Object?>() : [value];
    for (final nestItem in nestItems) {
      if (nestItem is! Map<String, Object?>) {
        throw RdfSyntaxException(
          'invalid @nest value: must be an object',
          format: _format,
        );
      }

      // Validate: @value and @list not allowed inside @nest.
      for (final k in nestItem.keys) {
        final r = _resolveAlias(k, context);
        if (r == '@value' || r == '@list') {
          throw RdfSyntaxException(
            'invalid @nest value: @value and @list not allowed',
            format: _format,
          );
        }
      }

      // Process the nest's @context.
      var nestContext = context;
      if (nestItem.containsKey('@context')) {
        nestContext = contextProcessor.mergeContext(
          context,
          nestItem['@context'],
          seenContextIris: <String>{},
          contextDocumentBaseIri:
              contextProcessor.getEffectiveBase(context) ?? documentBaseUri,
        );
      }

      // Apply type-scoped contexts.
      final prevCtx = nestContext;
      nestContext = _applyTypeScopedContexts(nestItem, nestContext);

      // Canonicalize.
      final nestCanon = _canonicalizeKeywords(nestItem, nestContext);

      // Expand each property of the nest into the parent result.
      for (final entry in nestCanon.entries) {
        final r = _resolveAlias(entry.key, nestContext);
        if (r == '@context') continue;
        if (_isUnknownKeywordLike(r)) continue;
        // Route @nest aliases through _processProperty so their
        // property-scoped context is applied.
        if (r == '@nest' && entry.key != '@nest') {
          _processProperty(entry.key, entry.value, nestContext, result,
              activeProperty: activeProperty);
        } else if (jsonLdKeywords.contains(r)) {
          _processKeyword(
            r,
            entry.value,
            nestContext,
            prevCtx,
            result,
            activeProperty: activeProperty,
            activeContext: context,
          );
        } else {
          _processProperty(entry.key, entry.value, nestContext, result,
              activeProperty: activeProperty);
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // Property expansion
  // -------------------------------------------------------------------------

  void _processProperty(
    String key,
    Object? value,
    JsonLdContext context,
    JsonObject result, {
    required String? activeProperty,
  }) {
    final termDef = context.terms[key];

    // @nest term: expand nest content into parent.
    // Check this BEFORE IRI expansion since @nest is a keyword, not an IRI.
    if (termDef?.iri == '@nest' ||
        _resolveAlias(key, context) == '@nest') {
      final nestContext = _applyTermScopedContext(context, termDef);
      _processNest(value, nestContext, result, activeProperty: activeProperty);
      return;
    }

    // Expand the property IRI.
    final expandedProperty = contextProcessor.expandIri(key, context);

    // Skip if cannot expand to an absolute IRI or valid identifier.
    if (!_isAbsoluteIriOrBlankNode(expandedProperty)) {
      _log.fine('Skipping unexpandable property: $key -> $expandedProperty');
      return;
    }

    // Skip keyword-like @-prefixed terms.
    if (expandedProperty.startsWith('@') &&
        !jsonLdKeywords.contains(expandedProperty)) {
      return;
    }

    // Get the context for expanding values of this property.
    final valueContext = _applyTermScopedContext(context, termDef);

    // Container-specific expansion.
    final containers = termDef?.containers ?? const <String>{};

    // Reverse property.
    if (termDef?.isReverse == true) {
      if (containers.contains('@index') && value is Map<String, Object?>) {
        // Reverse + index container: expand as index map first, then
        // route items to the reverse property.
        final List<Object?> indexItems;
        if (termDef!.indexMapping != null) {
          indexItems = _expandPropertyIndexMap(
              value, valueContext, key, termDef);
        } else {
          indexItems =
              _expandIndexMap(value, valueContext, key, termDef: termDef);
        }
        _addToReverse(expandedProperty, indexItems, result);
      } else {
        _processReverseProperty(
            expandedProperty, value, valueContext, context, result, termDef!,
            compactKey: key);
      }
      return;
    }

    Object expandedValue;

    if (containers.contains('@language') && value is Map<String, Object?>) {
      expandedValue =
          _expandLanguageMap(value, context, termDef);
    } else if (containers.contains('@graph') &&
        containers.contains('@index') &&
        value is Map<String, Object?> &&
        termDef?.indexMapping == null) {
      expandedValue =
          _expandGraphIndexMap(value, valueContext, context, termDef: termDef);
    } else if (containers.contains('@graph') &&
        containers.contains('@index') &&
        value is Map<String, Object?> &&
        termDef?.indexMapping != null) {
      expandedValue =
          _expandGraphIndexMap(value, valueContext, context, termDef: termDef);
    } else if (containers.contains('@graph') &&
        containers.contains('@id') &&
        value is Map<String, Object?>) {
      expandedValue =
          _expandGraphIdMap(value, valueContext, context, termDef: termDef);
    } else if (containers.contains('@graph') &&
        !containers.contains('@id') &&
        !containers.contains('@index')) {
      // Plain @graph container (no @id, no @index): wrap each value in @graph.
      expandedValue =
          _expandGraphContainer(value, valueContext, context, termDef: termDef);
    } else if (containers.contains('@index') &&
        value is Map<String, Object?> &&
        termDef?.indexMapping == null) {
      expandedValue =
          _expandIndexMap(value, valueContext, key, termDef: termDef);
    } else if (containers.contains('@index') &&
        value is Map<String, Object?> &&
        termDef?.indexMapping != null) {
      expandedValue = _expandPropertyIndexMap(
          value, valueContext, key, termDef!);
    } else if (containers.contains('@id') &&
        value is Map<String, Object?>) {
      expandedValue = _expandIdMap(value, valueContext, context, termDef: termDef);
    } else if (containers.contains('@type') &&
        value is Map<String, Object?>) {
      expandedValue = _expandTypeMap(value, valueContext, context, termDef: termDef);
    } else {
      // Detect property-scoped @propagate: false for deferred reversion.
      final isPropScoped = valueContext.hasPropagate &&
          !valueContext.propagate &&
          (!context.hasPropagate || context.propagate);
      expandedValue = _expandPropertyValue(
          value, valueContext, expandedProperty,
          termDef: termDef,
          activePropertyKey: key,
          propertyScoped: isPropScoped);
    }

    // @list container: wrap the value in a list object — UNLESS the
    // expanded value is already a list object (has '@list'), in which case
    // the container is redundant and we keep the inner list object as-is.
    if (containers.contains('@list')) {
      // If the expanded value is (or resolves to) a single list object,
      // keep it as-is — no double-wrapping. This happens when the original
      // JSON value was a Map like {"@list": [...]}, not from array coercion.
      final isSingleListObject = expandedValue is Map &&
          expandedValue.containsKey('@list');
      // Also check for a wrapped list object from Map → _expandObject path.
      // Only skip wrapping when the original value was a Map (not a List),
      // because List values need their outer @list wrapper from array coercion.
      final isWrappedListObject = value is! List &&
          expandedValue is List &&
          expandedValue.length == 1 &&
          expandedValue.first is Map &&
          (expandedValue.first as Map).containsKey('@list');

      if (isSingleListObject) {
        expandedValue = [expandedValue];
      } else if (isWrappedListObject) {
        // Already a single list object in an array from Map path — keep as-is.
      } else {
        final items = expandedValue is List
            ? expandedValue as List<Object?>
            : [expandedValue];
        _checkNoListOfLists(items);
        expandedValue = [<String, Object?>{'@list': items}];
      }
    }

    // Merge expanded value into result.
    // Empty arrays are preserved only when they came from explicit array or
    // @set/@list constructs, or when the term has a container mapping.
    // They are dropped when the value was null, or when an object value
    // resolved to nothing (e.g. {"@language": "en"} with no @value).
    if (expandedValue is List && expandedValue.isEmpty) {
      final hasContainer = containers.isNotEmpty;
      final isExplicitArray = value is List;
      final isExplicitSet = value is Map<String, Object?> &&
          (value.containsKey('@set') || value.containsKey('@list'));
      if (!hasContainer && !isExplicitArray && !isExplicitSet) {
        // Drop: value was null or resolved to nothing meaningful.
        return;
      }
    }
    _mergeValues(result, expandedProperty, expandedValue);
  }

  void _processReverseProperty(
    String expandedProperty,
    Object? value,
    JsonLdContext valueContext,
    JsonLdContext parentContext,
    JsonObject result,
    TermDefinition termDef, {
    required String compactKey,
  }) {
    final items = _expandArray(
      value is List ? value.cast<Object?>() : [value],
      valueContext,
      compactKey,
      fromMap: false,
    );

    _addToReverse(expandedProperty, items, result);
  }

  /// Add expanded items to the @reverse map in result.
  void _addToReverse(
    String expandedProperty,
    List<Object?> items,
    JsonObject result,
  ) {
    final reverseMap =
        result['@reverse'] as Map<String, Object?>? ?? <String, Object?>{};
    for (final item in items) {
      if (item is Map<String, Object?> &&
          (item.containsKey('@value') || item.containsKey('@list'))) {
        throw RdfSyntaxException(
          'invalid reverse property value: value/list objects are not valid',
          format: _format,
        );
      }
      final existing = reverseMap[expandedProperty];
      if (existing == null) {
        reverseMap[expandedProperty] = <Object?>[item];
      } else if (existing is List) {
        existing.add(item);
      } else {
        reverseMap[expandedProperty] = <Object?>[existing, item];
      }
    }
    if (reverseMap.isNotEmpty) {
      result['@reverse'] = reverseMap;
    }
  }

  // -------------------------------------------------------------------------
  // Container expansion
  // -------------------------------------------------------------------------

  List<Object?> _expandLanguageMap(
    Map<String, Object?> value,
    JsonLdContext context,
    TermDefinition? termDef,
  ) {
    final result = <Object?>[];
    final sortedKeys = value.keys.toList()..sort();

    for (final lang in sortedKeys) {
      final resolvedLang = _resolveAlias(lang, context);
      final langTag = resolvedLang == '@none' ? null : lang.toLowerCase();

      final items = value[lang];
      final langItems = items is List ? items.cast<Object?>() : [items];
      for (final item in langItems) {
        if (item is! String) {
          if (item == null) continue;
          throw RdfSyntaxException(
            'invalid language map value: must be a string',
            format: _format,
          );
        }
        if (langTag == null) {
          // @none: no language tag. Check for term-level or context direction.
          final valueObj = <String, Object?>{'@value': item};
          if (termDef?.hasDirection == true && termDef!.direction != null) {
            valueObj['@direction'] = termDef.direction!;
          } else if (context.hasDirection && context.direction != null) {
            valueObj['@direction'] = context.direction!;
          }
          result.add(valueObj);
        } else {
          final valueObj = <String, Object?>{
            '@value': item,
            '@language': langTag,
          };
          // Apply direction: term-level overrides context-level.
          if (termDef?.hasDirection == true) {
            if (termDef!.direction != null) {
              valueObj['@direction'] = termDef.direction!;
            }
            // else: explicit null direction on term → suppress context direction.
          } else if (context.hasDirection && context.direction != null) {
            valueObj['@direction'] = context.direction!;
          }
          result.add(valueObj);
        }
      }
    }
    return result;
  }

  List<Object?> _expandIndexMap(
    Map<String, Object?> value,
    JsonLdContext context,
    String activePropertyKey, {
    TermDefinition? termDef,
  }) {
    final result = <Object?>[];
    final sortedKeys = value.keys.toList()..sort();

    for (final index in sortedKeys) {
      final items = value[index];
      final expanded = _expandArray(
        items is List ? items.cast<Object?>() : [items],
        context,
        activePropertyKey,
        fromMap: true,
      );
      for (final item in expanded) {
        if (item is Map<String, Object?>) {
          if (!item.containsKey('@index') && index != '@none') {
            final mutable = Map<String, Object?>.from(item);
            mutable['@index'] = index;
            result.add(mutable);
          } else {
            result.add(item);
          }
        } else {
          result.add(item);
        }
      }
    }
    return result;
  }

  List<Object?> _expandPropertyIndexMap(
    Map<String, Object?> value,
    JsonLdContext context,
    String activePropertyKey,
    TermDefinition termDef,
  ) {
    final result = <Object?>[];
    final sortedKeys = value.keys.toList()..sort();
    final indexPropExpanded =
        contextProcessor.expandIri(termDef.indexMapping!, context);

    for (final index in sortedKeys) {
      var mapContext = context;
      final indexTermDef = context.terms[termDef.indexMapping!];
      if (indexTermDef != null && indexTermDef.hasLocalContext) {
        mapContext = _applyTermScopedContext(context, indexTermDef);
      }

      final items = value[index];
      final expanded = _expandArray(
        items is List ? items.cast<Object?>() : [items],
        mapContext,
        activePropertyKey,
        fromMap: true,
      );

      final resolvedIndex = _resolveAlias(index, context);

      for (final item in expanded) {
        if (item is Map<String, Object?>) {
          final mutable = Map<String, Object?>.from(item);
          if (resolvedIndex != '@none') {
            // Cannot add a property to a value object.
            if (mutable.containsKey('@value')) {
              throw RdfSyntaxException(
                'invalid value object',
                format: _format,
              );
            }
            // Expand the index value according to the index property's term
            // definition (e.g., @type: @vocab produces a node reference).
            final Map<String, Object?> indexVal;
            final indexTermDef = context.terms[termDef.indexMapping!];
            if (indexTermDef?.typeMapping == '@vocab' ||
                indexTermDef?.typeMapping == '@id') {
              final expandedIdx = contextProcessor.expandIri(index, context);
              final resolvedIdx =
                  _isUsableIri(expandedIdx) || expandedIdx.startsWith('_:')
                      ? expandedIdx
                      : (_expandIriReference(expandedIdx, context) ??
                          expandedIdx);
              indexVal = {'@id': resolvedIdx};
            } else {
              indexVal = {'@value': index};
            }
            final existing = mutable[indexPropExpanded];
            if (existing is List) {
              mutable[indexPropExpanded] = [indexVal, ...existing];
            } else if (existing != null) {
              mutable[indexPropExpanded] = [indexVal, existing];
            } else {
              mutable[indexPropExpanded] = [indexVal];
            }
          }
          result.add(mutable);
        } else {
          result.add(item);
        }
      }
    }
    return result;
  }

  List<Object?> _expandIdMap(
    Map<String, Object?> value,
    JsonLdContext context,
    JsonLdContext parentContext, {
    TermDefinition? termDef,
  }) {
    final result = <Object?>[];
    final sortedKeys = value.keys.toList()..sort();

    for (final mapKey in sortedKeys) {
      var mapContext = context;
      if (termDef != null && termDef.hasLocalContext) {
        mapContext = _applyTermScopedContext(context, termDef);
      }

      final items = value[mapKey];
      final rawItems = items is List ? items.cast<Object?>() : [items];

      for (final rawItem in rawItems) {
        final JsonObject nodeObj;
        if (rawItem is Map<String, Object?>) {
          nodeObj = Map<String, Object?>.from(rawItem);
        } else {
          // Non-object items: expand and add.
          final expanded =
              _expandElement(rawItem, mapContext, null, fromMap: true);
          if (expanded != null) result.add(expanded);
          continue;
        }

        // Inject @id from the map key if not already present.
        if (!nodeObj.containsKey('@id') &&
            !_hasKeywordAlias('@id', nodeObj, parentContext)) {
          final resolvedMapKey = _resolveAlias(mapKey, parentContext);
          if (resolvedMapKey != '@none') {
            final expandedId = _expandIriReference(mapKey, parentContext);
            if (expandedId != null) {
              nodeObj['@id'] = expandedId;
            }
          }
        }

        final expanded =
            _expandObject(nodeObj, mapContext, null, fromMap: true);
        if (expanded != null) result.add(expanded);
      }
    }
    return result;
  }

  List<Object?> _expandTypeMap(
    Map<String, Object?> value,
    JsonLdContext context,
    JsonLdContext parentContext, {
    TermDefinition? termDef,
  }) {
    final result = <Object?>[];
    final sortedKeys = value.keys.toList()..sort();

    for (final mapKey in sortedKeys) {
      var mapContext = context;
      if (termDef != null && termDef.hasLocalContext) {
        mapContext = _applyTermScopedContext(context, termDef);
      }

      final items = value[mapKey];
      final rawItems = items is List ? items.cast<Object?>() : [items];

      // Apply the type-scoped context for this map key's type.
      // Look up the compact type term in the context for its scoped context.
      final resolvedMapKey = _resolveAlias(mapKey, parentContext);
      String? expandedType;
      if (resolvedMapKey != '@none') {
        expandedType = contextProcessor.expandIri(mapKey, parentContext);
        if (!_isUsableIri(expandedType) && !expandedType.startsWith('_:')) {
          expandedType = null;
        }
      }

      // Apply the type-scoped context from the map key's type term.
      // Per the spec, type-scoped contexts from the type map key use the
      // non-propagated parent (before Outer's type-scoped context) as the base.
      final typeTermDef = parentContext.terms[mapKey];
      var itemContext = mapContext;
      if (typeTermDef != null && typeTermDef.hasLocalContext) {
        final baseForType =
            mapContext.nonPropagatedParent ?? mapContext;
        itemContext = _applyTermScopedContext(baseForType, typeTermDef);
      }

      for (final rawItem in rawItems) {
        final JsonObject nodeObj;
        if (rawItem is Map<String, Object?>) {
          nodeObj = Map<String, Object?>.from(rawItem);
        } else if (rawItem is String) {
          // String values in type maps become node references.
          // Expand according to the term's @type mapping.
          String? expandedId;
          if (termDef?.typeMapping == '@vocab') {
            // @type: @vocab — expand via vocab/term first, then base fallback.
            expandedId = contextProcessor.expandIri(rawItem, itemContext);
            if (!_isUsableIri(expandedId) && !expandedId.startsWith('_:')) {
              expandedId = _expandIriReference(rawItem, itemContext);
            }
          } else {
            expandedId = _expandIriReference(rawItem, itemContext);
          }
          if (expandedId == null) continue;
          nodeObj = <String, Object?>{'@id': expandedId};
        } else {
          continue;
        }

        // Inject the map key as @type.
        if (expandedType != null) {
          final existingTypes = nodeObj['@type'];
          if (existingTypes is List) {
            nodeObj['@type'] = [expandedType, ...existingTypes.cast<Object?>()];
          } else if (existingTypes != null) {
            nodeObj['@type'] = [expandedType, existingTypes];
          } else {
            nodeObj['@type'] = [expandedType];
          }
        }

        final expanded =
            _expandObject(nodeObj, itemContext, null, fromMap: true);
        if (expanded != null) result.add(expanded);
      }
    }
    return result;
  }

  /// Expand a plain @graph container (no @id, no @index).
  /// Each value (or array element) is expanded as a node and wrapped in
  /// {"@graph": [...]}.
  List<Object?> _expandGraphContainer(
    Object? value,
    JsonLdContext context,
    JsonLdContext parentContext, {
    TermDefinition? termDef,
  }) {
    var mapContext = context;
    if (termDef != null && termDef.hasLocalContext) {
      mapContext = _applyTermScopedContext(context, termDef);
    }

    final result = <Object?>[];
    final items = value is List ? value.cast<Object?>() : [value];

    for (final item in items) {
      // Expand each item as a node object, then wrap in @graph.
      // Use null as activeProperty so the expanded node is treated as a
      // full node (including preserving inner @graph).
      final expanded = _expandElement(item, mapContext, null, fromMap: true);
      final List<Object?> graphItems;
      if (expanded is List) {
        graphItems = expanded;
      } else if (expanded is Map<String, Object?> &&
          expanded.containsKey('@graph') &&
          expanded.keys.every((k) => k == '@graph' || k == '@context')) {
        // If expanded is a graph object with only @graph, use its contents
        // as the graph items and wrap again to produce the required nesting.
        graphItems = [expanded];
      } else if (expanded != null) {
        graphItems = [expanded];
      } else {
        graphItems = <Object?>[];
      }
      result.add(<String, Object?>{'@graph': graphItems});
    }
    return result;
  }

  /// Expand a @graph + @index container.
  /// The value is a map; each key becomes @index and the value becomes @graph.
  List<Object?> _expandGraphIndexMap(
    Map<String, Object?> value,
    JsonLdContext context,
    JsonLdContext parentContext, {
    TermDefinition? termDef,
  }) {
    final result = <Object?>[];
    final sortedKeys = value.keys.toList()..sort();

    for (final mapKey in sortedKeys) {
      var mapContext = context;
      if (termDef != null && termDef.hasLocalContext) {
        mapContext = _applyTermScopedContext(context, termDef);
      }

      final items = value[mapKey];
      // Each value may be a single object or an array of objects.
      // Each individual object becomes its own @graph entry.
      final rawItems = items is List ? items.cast<Object?>() : [items];

      for (final rawItem in rawItems) {
        final expanded =
            _expandElement(rawItem, mapContext, '@graph', fromMap: true);

        // If the expanded result is already a graph object (has @graph),
        // use it directly per the spec — don't double-wrap.
        final Map<String, Object?> graphObj;
        if (expanded is Map<String, Object?> &&
            expanded.containsKey('@graph')) {
          graphObj = Map<String, Object?>.from(expanded);
        } else {
          final graphItems = expanded is List
              ? expanded
              : (expanded != null ? [expanded] : <Object?>[]);
          graphObj = <String, Object?>{'@graph': graphItems};
        }

        final resolvedMapKey = _resolveAlias(mapKey, parentContext);
        if (resolvedMapKey != '@none') {
          if (termDef != null && termDef.indexMapping != null) {
            // Property-valued index: add index as a property value.
            final indexPropExpanded =
                contextProcessor.expandIri(termDef.indexMapping!, context);
            final indexTermDef = context.terms[termDef.indexMapping!];
            final Map<String, Object?> indexVal;
            if (indexTermDef?.typeMapping == '@vocab' ||
                indexTermDef?.typeMapping == '@id') {
              final expandedIdx =
                  contextProcessor.expandIri(mapKey, context);
              final resolvedIdx =
                  _isUsableIri(expandedIdx) || expandedIdx.startsWith('_:')
                      ? expandedIdx
                      : (_expandIriReference(expandedIdx, context) ??
                          expandedIdx);
              indexVal = {'@id': resolvedIdx};
            } else {
              indexVal = {'@value': mapKey};
            }
            final existing = graphObj[indexPropExpanded];
            if (existing is List) {
              graphObj[indexPropExpanded] = [indexVal, ...existing];
            } else if (existing != null) {
              graphObj[indexPropExpanded] = [indexVal, existing];
            } else {
              graphObj[indexPropExpanded] = [indexVal];
            }
          } else {
            graphObj['@index'] = mapKey;
          }
        }
        result.add(graphObj);
      }
    }
    return result;
  }

  /// Expand a @graph + @id container.
  /// The value is a map; each key becomes @id and the value becomes @graph.
  List<Object?> _expandGraphIdMap(
    Map<String, Object?> value,
    JsonLdContext context,
    JsonLdContext parentContext, {
    TermDefinition? termDef,
  }) {
    final result = <Object?>[];
    final sortedKeys = value.keys.toList()..sort();

    for (final mapKey in sortedKeys) {
      var mapContext = context;
      if (termDef != null && termDef.hasLocalContext) {
        mapContext = _applyTermScopedContext(context, termDef);
      }

      final items = value[mapKey];
      // Each value may be a single object or an array of objects.
      final rawItems = items is List ? items.cast<Object?>() : [items];

      for (final rawItem in rawItems) {
        final expanded =
            _expandElement(rawItem, mapContext, '@graph', fromMap: true);

        // If the expanded result is already a graph object (has @graph),
        // use it directly per the spec — don't double-wrap.
        final Map<String, Object?> graphObj;
        if (expanded is Map<String, Object?> &&
            expanded.containsKey('@graph')) {
          graphObj = Map<String, Object?>.from(expanded);
        } else {
          final graphItems = expanded is List
              ? expanded
              : (expanded != null ? [expanded] : <Object?>[]);
          graphObj = <String, Object?>{'@graph': graphItems};
        }

        final resolvedMapKey = _resolveAlias(mapKey, parentContext);
        if (resolvedMapKey != '@none') {
          final expandedId = _expandIriReference(mapKey, parentContext);
          if (expandedId != null) {
            graphObj['@id'] = expandedId;
          }
        }
        result.add(graphObj);
      }
    }
    return result;
  }

  // -------------------------------------------------------------------------
  // Property value expansion (default path)
  // -------------------------------------------------------------------------

  Object _expandPropertyValue(
    Object? value,
    JsonLdContext context,
    String expandedProperty, {
    TermDefinition? termDef,
    // The original compact key used for term lookup in _expandElement.
    // When provided, it is used as activeProperty in recursive expansion so
    // that type coercion (e.g. @type: @id) is correctly applied via the
    // compact key which is how terms are stored in the context.
    String? activePropertyKey,
    bool propertyScoped = false,
  }) {
    final containers = termDef?.containers ?? const <String>{};
    final isJsonType = termDef?.typeMapping == _rdfJsonDatatype;
    // The key to use as activeProperty for nested _expandElement calls.
    // If a compact key is provided, use it for term lookup; otherwise fall
    // back to the expanded property IRI.
    final activeKey = activePropertyKey ?? expandedProperty;

    // @type: @json — whole value (including arrays) is a single JSON literal.
    if (isJsonType) {
      return [
        {'@value': value, '@type': '@json'}
      ];
    }

    if (value is List) {
      // @container: @list — wrap in list object.
      if (containers.contains('@list')) {
        final items =
            _expandListContainerArray(value, context, activeKey);
        _checkNoListOfLists(items);
        return items;
      }
      // @container: @set or plain array.
      return _expandArray(value, context, activeKey, fromMap: false);
    }

    // Single value.
    final expanded = _expandElement(value, context, activeKey,
        fromMap: false, propertyScoped: propertyScoped);
    if (expanded == null) return <Object?>[];
    if (expanded is List) return expanded;
    return [expanded];
  }

  /// Expand an array value for a @list container.
  ///
  /// In JSON-LD 1.1, array elements that are themselves arrays become
  /// nested @list objects, enabling lists of lists. In 1.0 mode they are
  /// flattened as before.
  List<Object?> _expandListContainerArray(
    List<Object?> value,
    JsonLdContext context,
    String activeKey,
  ) {
    if (processingMode != 'json-ld-1.1') {
      return _expandArray(value, context, activeKey, fromMap: false);
    }
    final result = <Object?>[];
    for (final item in value) {
      if (item is List) {
        // In 1.1, a nested array becomes a nested @list object.
        final innerItems =
            _expandListContainerArray(item.cast<Object?>(), context, activeKey);
        result.add(<String, Object?>{'@list': innerItems});
      } else {
        final expanded = _expandElement(item, context, activeKey, fromMap: false);
        if (expanded is List) {
          result.addAll(expanded);
        } else if (expanded != null) {
          result.add(expanded);
        }
      }
    }
    return result;
  }

  // -------------------------------------------------------------------------
  // Object finalization
  // -------------------------------------------------------------------------

  Object? _finalizeObject(
    JsonObject result,
    JsonLdContext context,
    JsonLdContext activeContext,
    String? activeProperty, {
    required bool fromMap,
  }) {
    final resolvedActiveProperty =
        activeProperty != null ? _resolveAlias(activeProperty, activeContext) : null;

    // If result is a value object.
    if (result.containsKey('@value')) {
      // Value objects at the top level (activeProperty == null) or inside
      // @graph (activeProperty == '@graph') are dropped per W3C spec § 4.1.1.
      if (activeProperty == null ||
          resolvedActiveProperty == '@graph') {
        return null;
      }
      return _finalizeValueObject(result, context);
    }

    // If result has @type but no other substance.
    if (result.containsKey('@type')) {
      final types = result['@type'];
      if (types is List && types.isEmpty) {
        result.remove('@type');
      }
    }

    // Empty result: drop at top level or @graph, but preserve as nested value.
    if (result.isEmpty) {
      if (activeProperty != null &&
          resolvedActiveProperty != '@graph') {
        return result; // Preserve empty node objects as property values.
      }
      return null;
    }

    // If result has only metadata-only keywords, drop it.
    const metadataOnly = {'@language', '@direction', '@index'};
    if (result.keys.every(metadataOnly.contains)) return null;

    // @set unwrapping: result with only @set.
    if (result.containsKey('@set') && result.length == 1) {
      return result['@set'];
    }

    // @list objects: pass through normally, but drop when at the top level
    // or inside @graph (free-floating lists are removed per W3C spec).
    if (result.containsKey('@list')) {
      if (activeProperty == null || resolvedActiveProperty == '@graph') {
        return null;
      }
      return result;
    }

    // Free-floating node check: drop nodes that have no properties other
    // than @id (or @id + @graph). Per the spec (step 14.2.1), @index IS a
    // substantive entry that prevents a node from being free-floating.
    // This only applies at the top level (activeProperty == null) or inside
    // @graph (activeProperty == '@graph'), and only when not inside a map
    // container (fromMap is false).
    if (!fromMap &&
        (activeProperty == null || resolvedActiveProperty == '@graph')) {
      final otherKeys = result.keys.where((k) =>
          k != '@id' && k != '@type' && k != '@graph' && k != '@context');
      final hasGraph = result.containsKey('@graph');
      final hasId = result.containsKey('@id');
      final hasType = result.containsKey('@type');

      // Drop free-floating node with only @id.
      if (hasId && !hasType && !hasGraph && otherKeys.isEmpty) {
        return null;
      }
    }

    return result;
  }

  /// Validate and finalize a value object.
  Object? _finalizeValueObject(JsonObject result, JsonLdContext context) {
    // Allowed keys in a value object.
    const allowedKeys = {
      '@value', '@type', '@language', '@direction', '@index'
    };
    final invalidKey = result.keys.firstWhere(
        (k) => !allowedKeys.contains(k), orElse: () => '');
    if (invalidKey.isNotEmpty) {
      throw RdfSyntaxException('invalid value object', format: _format);
    }

    // In a value object, @type is a single string (the datatype IRI).
    // _processType stores it as a List — unwrap if needed.
    if (result.containsKey('@type')) {
      final rawType = result['@type'];
      if (rawType is List) {
        if (rawType.isEmpty) {
          result.remove('@type');
        } else if (rawType.length == 1) {
          result['@type'] = rawType.first;
        } else {
          // Multiple types in a value object are invalid.
          throw RdfSyntaxException(
            'invalid typed value: value objects may only have one @type',
            format: _format,
          );
        }
      }
    }

    final rawValue = result['@value'];
    var typeVal = result['@type'];

    // @language and @type are mutually exclusive.
    if (result.containsKey('@language') && result.containsKey('@type')) {
      throw RdfSyntaxException(
        'invalid value object: @language and @type are mutually exclusive',
        format: _format,
      );
    }

    // @direction and @type are mutually exclusive.
    if (result.containsKey('@direction') && result.containsKey('@type')) {
      throw RdfSyntaxException(
        'invalid value object',
        format: _format,
      );
    }

    // @value null → drop unless @type is @json.
    if (rawValue == null) {
      if (typeVal == '@json' || typeVal == _rdfJsonDatatype) {
        return result;
      }
      return null;
    }

    // @type must be a string.
    if (result.containsKey('@type')) {
      if (typeVal != null && typeVal is! String) {
        throw RdfSyntaxException(
          'invalid typed value: @type must be a string',
          format: _format,
        );
      }
      if (typeVal is String && typeVal != '@json' && typeVal != '@none') {
        // Must be a valid absolute IRI (no blank nodes, no spaces).
        if (!JsonLdContextProcessor.looksLikeAbsoluteIri(typeVal) ||
            typeVal.startsWith('_:') ||
            _containsInvalidIriChars(typeVal)) {
          throw RdfSyntaxException('invalid typed value', format: _format);
        }
      }
    }

    // @language requires string @value.
    if (result.containsKey('@language') && rawValue is! String) {
      throw RdfSyntaxException(
        'invalid language-tagged value: @value must be a string',
        format: _format,
      );
    }

    // Object/array @value only with @type: @json.
    if ((rawValue is Map || rawValue is List) &&
        typeVal != '@json' &&
        typeVal != _rdfJsonDatatype) {
      throw RdfSyntaxException(
        'invalid value object value: object/array @value requires @type: @json',
        format: _format,
      );
    }

    // Refresh typeVal after possible list unwrap.
    typeVal = result['@type'];

    // Expand @type IRI if it hasn't been expanded yet.
    if (typeVal is String &&
        typeVal != '@json' &&
        typeVal != '@none' &&
        typeVal != _rdfJsonDatatype) {
      // Already validated as absolute IRI above.
    }

    return result;
  }

  // -------------------------------------------------------------------------
  // Context application helpers
  // -------------------------------------------------------------------------

  JsonLdContext _applyTypeScopedContexts(
    Map<String, Object?> node,
    JsonLdContext context,
  ) {
    final typeValue = _getKeywordValue(node, '@type', context);
    if (typeValue == null) return context;

    final typeTerms = <String>[];
    if (typeValue is String) {
      typeTerms.add(typeValue);
    } else if (typeValue is List) {
      for (final item in typeValue) {
        if (item is String) typeTerms.add(item);
      }
    }
    if (typeTerms.isEmpty) return context;

    typeTerms.sort((a, b) {
      final aExp = contextProcessor.expandIri(a, context);
      final bExp = contextProcessor.expandIri(b, context);
      return aExp.compareTo(bExp);
    });

    if (_contextApplicationDepth >= _maxContextApplicationDepth) {
      return context;
    }

    var merged = context;
    var applied = false;
    for (final typeTerm in typeTerms) {
      final termDef = context.terms[typeTerm];
      if (termDef != null && termDef.hasLocalContext) {
        _contextApplicationDepth++;
        try {
          merged = contextProcessor.mergeContext(
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

    // Per W3C spec § 13.4.2: type-scoped contexts are processed with
    // propagate: false by default, meaning they don't propagate into
    // nested node objects. Set the previous context so _expandObject
    // can revert. However, if the type-scoped context explicitly sets
    // @propagate: true, respect that and allow propagation.
    if (applied) {
      if (merged.hasPropagate && merged.propagate) {
        // Context explicitly set @propagate: true — allow propagation.
        // Don't override with false.
      } else if (!merged.hasPropagate) {
        // No explicit @propagate — default for type-scoped is false.
        merged = merged.copyWith(
          propagate: false,
          hasPropagate: true,
          nonPropagatedParent: context,
        );
      } else if (merged.nonPropagatedParent == null) {
        // Already has propagate: false, just ensure nonPropagatedParent.
        merged = merged.copyWith(nonPropagatedParent: context);
      }
    }

    return merged;
  }

  JsonLdContext _applyTermScopedContext(
    JsonLdContext context,
    TermDefinition? termDef,
  ) {
    if (termDef == null || !termDef.hasLocalContext) return context;
    if (_contextApplicationDepth >= _maxContextApplicationDepth) return context;

    _contextApplicationDepth++;
    try {
      var result = contextProcessor.mergeContext(
        context,
        termDef.localContext,
        seenContextIris: <String>{},
        allowProtectedNullification: true,
        allowProtectedOverride: true,
      );
      // If the incoming context had propagate: false (from a type-scoped
      // context), also apply the property-scoped context to the
      // nonPropagatedParent so that when _expandObject reverts, the
      // property-scoped terms are still available.
      if (context.hasPropagate && !context.propagate &&
          context.nonPropagatedParent != null) {
        final updatedParent = contextProcessor.mergeContext(
          context.nonPropagatedParent!,
          termDef.localContext,
          seenContextIris: <String>{},
          allowProtectedNullification: true,
          allowProtectedOverride: true,
        );
        result = result.copyWith(nonPropagatedParent: updatedParent);
      }
      return result;
    } finally {
      _contextApplicationDepth--;
    }
  }

  // -------------------------------------------------------------------------
  // IRI expansion helpers
  // -------------------------------------------------------------------------

  /// Expand an IRI for use as an @id value.
  /// Compact IRI expansion but NOT @vocab fallback.
  /// Resolves relative IRIs against the effective base.
  String? _expandIriReference(String value, JsonLdContext context) {
    if (value.startsWith('@')) {
      if (jsonLdKeywords.contains(value)) return value;
      if (_isUnknownKeywordLike(value)) return null;
    }

    if (value.startsWith('_:')) return value;

    // Try compact IRI expansion (prefix:suffix) BEFORE absolute IRI check.
    // A value like "ex:node1" may look like an absolute IRI (scheme "ex:")
    // but if "ex" is a defined prefix, it must be expanded via that prefix.
    if (value.contains(':')) {
      final colonIdx = value.indexOf(':');
      final prefix = value.substring(0, colonIdx);
      final localName = value.substring(colonIdx + 1);
      // Only try prefix expansion if prefix doesn't look like a real scheme
      // (i.e. not "http", "https", "urn", etc.) OR if the prefix is a known
      // term in the context.
      final prefixDef = context.terms[prefix];
      if (prefixDef != null &&
          !prefixDef.isNullMapping &&
          prefixDef.iri != null &&
          contextProcessor.canUseAsPrefix(prefixDef)) {
        final expanded = '${prefixDef.iri}$localName';
        if (JsonLdContextProcessor.looksLikeAbsoluteIri(expanded) ||
            expanded.startsWith('_:')) {
          return expanded;
        }
      }
    }

    // Now check for absolute IRI (scheme not overridden by a prefix term).
    if (JsonLdContextProcessor.looksLikeAbsoluteIri(value)) {
      return value;
    }

    // Relative IRI: resolve against effective base.
    final base = contextProcessor.getEffectiveBase(context);
    if (base == null) {
      // No base available — relative IRIs cannot be resolved.
      // Return them as-is (including empty string, which is a valid
      // relative IRI reference per the spec).
      return value;
    }

    try {
      return resolveIri(value, base);
    } catch (_) {
      return value;
    }
  }

  // -------------------------------------------------------------------------
  // Keyword helpers
  // -------------------------------------------------------------------------

  String _resolveAlias(String key, JsonLdContext context) {
    return contextProcessor.resolveKeywordAlias(key, context);
  }

  Object? _getKeywordValue(
    Map<String, Object?> node,
    String keyword,
    JsonLdContext context,
  ) {
    if (node.containsKey(keyword)) return node[keyword];
    for (final alias in context.keywordAliases.entries) {
      if (alias.value == keyword && node.containsKey(alias.key)) {
        return node[alias.key];
      }
    }
    return null;
  }

  bool _hasKeywordAlias(
      String keyword, Map<String, Object?> node, JsonLdContext context) {
    if (node.containsKey(keyword)) return true;
    for (final alias in context.keywordAliases.entries) {
      if (alias.value == keyword && node.containsKey(alias.key)) return true;
    }
    return false;
  }

  // -------------------------------------------------------------------------
  // Validation helpers
  // -------------------------------------------------------------------------

  /// Canonicalize keyword aliases to their canonical forms.
  JsonObject _canonicalizeKeywords(
    JsonObject input,
    JsonLdContext context,
  ) {
    final normalized = JsonObject.from(input);
    final toRemove = <String>[];
    var idAliasCount = 0;
    var hasCanonicalId = false;

    for (final entry in input.entries) {
      final resolved = _resolveAlias(entry.key, context);
      if (!jsonLdKeywords.contains(resolved)) continue;
      if (resolved == '@nest') continue;
      if (resolved == '@context') continue;
      if (entry.key == resolved) {
        if (resolved == '@id') hasCanonicalId = true;
        continue;
      }

      if (resolved == '@id') idAliasCount++;

      if (normalized.containsKey(resolved)) {
        if (resolved == '@type' || resolved == '@included') {
          final existing = normalized[resolved];
          final newVal = entry.value;
          normalized[resolved] = [
            if (existing is List) ...existing else existing,
            if (newVal is List) ...newVal else newVal,
          ];
        }
        // Other keywords: first wins.
      } else {
        normalized[resolved] = entry.value;
      }
      toRemove.add(entry.key);
    }

    if (idAliasCount > 1 && !hasCanonicalId) {
      throw RdfSyntaxException('colliding keywords', format: _format);
    }

    for (final key in toRemove) {
      normalized.remove(key);
    }
    return normalized;
  }

  void _validateInput(JsonObject node) {
    final hasValue = node.containsKey('@value');
    final hasList = node.containsKey('@list');
    final hasSet = node.containsKey('@set');

    if (hasSet) {
      if (node.keys.any((k) => k != '@set' && k != '@index')) {
        throw RdfSyntaxException(
          'invalid set or list object',
          format: _format,
        );
      }
    }

    if (hasList) {
      if (node.keys.any((k) => k != '@list' && k != '@index')) {
        throw RdfSyntaxException(
          'invalid set or list object',
          format: _format,
        );
      }
    }

    if (hasValue) {
      const invalidWithValue = {
        '@id', '@graph', '@set', '@list', '@reverse', '@included'
      };
      if (node.keys.any(invalidWithValue.contains)) {
        throw RdfSyntaxException(
          'invalid value object',
          format: _format,
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // Utility
  // -------------------------------------------------------------------------

  bool _isAbsoluteIriOrBlankNode(String iri) {
    return iri.startsWith('_:') ||
        JsonLdContextProcessor.looksLikeAbsoluteIri(iri);
  }

  bool _isUsableIri(String iri) {
    return JsonLdContextProcessor.looksLikeAbsoluteIri(iri);
  }

  static final _invalidIriCharsRe = RegExp(r'[\s<>{}\|\\^\x60]');
  static bool _containsInvalidIriChars(String value) {
    return _invalidIriCharsRe.hasMatch(value);
  }

  bool _isUnknownKeywordLike(String value) {
    return value.startsWith('@') &&
        JsonLdContextProcessor.isKeywordLikeAtForm(value) &&
        !jsonLdKeywords.contains(value);
  }

  void _checkNoListOfLists(List<Object?> items) {
    // In JSON-LD 1.1, lists of lists are allowed.
    // Only enforce this restriction in 1.0 mode.
    if (processingMode == 'json-ld-1.1') return;
    for (final item in items) {
      if (item is Map && item.containsKey('@list')) {
        throw RdfSyntaxException('list of lists', format: _format);
      }
    }
  }

  void _mergeValues(JsonObject result, String key, Object? value) {
    if (value == null) return;
    final existing = result[key];
    if (existing == null) {
      result[key] = value is List ? List<Object?>.from(value) : value;
      return;
    }
    if (existing is List) {
      if (value is List) {
        existing.addAll(value);
      } else {
        existing.add(value);
      }
    } else {
      final merged = <Object?>[existing];
      if (value is List) {
        merged.addAll(value);
      } else {
        merged.add(value);
      }
      result[key] = merged;
    }
  }
}
