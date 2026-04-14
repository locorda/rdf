/// JSON-LD 1.1 Compaction Algorithm.
///
/// Implements the W3C JSON-LD 1.1 Compaction Algorithm (section 6.1 of the
/// JSON-LD 1.1 Processing Algorithms and API specification).
///
/// The compaction processor takes expanded JSON-LD and a context, producing
/// compact JSON-LD with short property names, aliased keywords, and
/// simplified value representations.
///
/// See: https://www.w3.org/TR/json-ld11-api/#compaction-algorithm
library;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/extend.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_codec.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_utils.dart';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Implements the W3C JSON-LD 1.1 Compaction Algorithm.
///
/// Takes expanded JSON-LD (from expansion or `jsonDecode` of expanded form)
/// and a compaction context, producing compact JSON-LD.
class JsonLdCompactionProcessor {
  final String processingMode;
  final JsonLdContextDocumentProvider? contextDocumentProvider;
  final JsonLdContextDocumentCache? contextDocumentCache;
  final Map<String, Object?> preloadedParsedContextDocuments;
  final String? documentBaseUri;

  const JsonLdCompactionProcessor({
    this.processingMode = 'json-ld-1.1',
    this.contextDocumentProvider,
    this.contextDocumentCache,
    this.preloadedParsedContextDocuments = const {},
    this.documentBaseUri,
  });

  /// Compacts JSON-LD using the given context.
  ///
  /// Per the W3C spec, the input is first expanded, then compacted.
  Map<String, Object?> compact(
    Object? input, {
    required Object? context,
    String? documentUrl,
    bool compactArrays = true,
    bool ordered = false,
  }) {
    final effectiveBase = documentUrl ?? documentBaseUri;

    // Step 1: Expand the input first.
    final expansionProcessor = JsonLdExpansionProcessor(
      processingMode: processingMode,
      contextDocumentProvider: contextDocumentProvider,
      contextDocumentCache: contextDocumentCache,
      preloadedParsedContextDocuments: preloadedParsedContextDocuments,
      documentBaseUri: effectiveBase,
    );
    final expanded = expansionProcessor.expand(
      input,
      documentUrl: effectiveBase,
    );

    // Step 2: Compact the expanded result.
    return compactExpanded(
      expanded,
      context: context,
      documentUrl: effectiveBase,
      compactArrays: compactArrays,
      ordered: ordered,
    );
  }

  /// Compacts already-expanded JSON-LD using the given context.
  Map<String, Object?> compactExpanded(
    Object? input, {
    required Object? context,
    String? documentUrl,
    bool compactArrays = true,
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

    // Build active context from the provided context.
    var activeContext = JsonLdContext(
      base: effectiveBase,
      hasBase: effectiveBase != null,
    );

    // Process the compaction context.
    Object? contextValue = context;
    if (contextValue is Map && contextValue.containsKey('@context')) {
      contextValue = contextValue['@context'];
    }

    if (contextValue != null) {
      activeContext = contextProcessor.mergeContext(
        activeContext,
        contextValue,
        seenContextIris: <String>{},
      );
    }

    // Build inverse context for IRI compaction.
    final inverseContext = _buildInverseContext(activeContext);

    // Compact the input.
    final compacted = _compact(
      activeContext: activeContext,
      inverseContext: inverseContext,
      activeProperty: null,
      element: input,
      compactArrays: compactArrays,
      ordered: ordered,
      contextProcessor: contextProcessor,
    );

    // Wrap result with @context.
    final result = <String, Object?>{};

    if (compacted is Map<String, Object?>) {
      if (contextValue != null &&
          compacted.isNotEmpty &&
          !_isEmptyContext(contextValue)) {
        result['@context'] = contextValue;
      }
      result.addAll(compacted);
    } else if (compacted is List) {
      if (compacted.isEmpty) {
        // Empty result.
      } else {
        if (contextValue != null && !_isEmptyContext(contextValue)) {
          result['@context'] = contextValue;
        }
        final graphAlias = _compactIri(
          activeContext: activeContext,
          inverseContext: inverseContext,
          iri: '@graph',
          vocab: true,
        );
        result[graphAlias] = compacted;
      }
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Core Compaction Algorithm
  // ---------------------------------------------------------------------------

  Object? _compact({
    required JsonLdContext activeContext,
    required _InverseContext inverseContext,
    required String? activeProperty,
    required Object? element,
    required bool compactArrays,
    required bool ordered,
    required JsonLdContextProcessor contextProcessor,
    bool insideReverse = false,
  }) {
    // 1. Scalar — return as-is.
    if (element == null ||
        element is String ||
        element is num ||
        element is bool) {
      return element;
    }

    // 2. Array.
    if (element is List) {
      final result = <Object?>[];
      for (final item in element) {
        final compactedItem = _compact(
          activeContext: activeContext,
          inverseContext: inverseContext,
          activeProperty: activeProperty,
          element: item,
          compactArrays: compactArrays,
          ordered: ordered,
          contextProcessor: contextProcessor,
          insideReverse: insideReverse,
        );
        if (compactedItem != null) {
          result.add(compactedItem);
        }
      }

      if (result.length == 1 && compactArrays) {
        final termDef = activeProperty != null
            ? _lookupTermByCompactIri(activeContext, activeProperty)
            : null;
        final containers = termDef?.containers ?? const <String>{};
        if (!containers.contains('@set') && !containers.contains('@list')) {
          return result[0];
        }
      }
      return result;
    }

    // 3. Element is a map.
    if (element is! Map<String, Object?>) {
      return element;
    }

    final expandedMap = element;

    // Handle nested @list inside a @list container — unwrap to bare array.
    if (expandedMap.containsKey('@list') && activeProperty != null) {
      final apTermDef = _lookupTermByCompactIri(activeContext, activeProperty);
      if (apTermDef != null && apTermDef.containers.contains('@list')) {
        final listContent = expandedMap['@list'];
        final compacted = _compact(
          activeContext: activeContext,
          inverseContext: inverseContext,
          activeProperty: activeProperty,
          element: listContent,
          compactArrays: compactArrays,
          ordered: ordered,
          contextProcessor: contextProcessor,
        );
        return compacted is List ? compacted : [compacted];
      }
    }

    // Handle value objects first.
    if (expandedMap.containsKey('@value')) {
      final compactedValue = _compactValue(
        activeContext: activeContext,
        inverseContext: inverseContext,
        activeProperty: activeProperty,
        value: expandedMap,
      );
      // If value compaction produced a simplified result (not a value object
      // with keywords), return it directly. This includes scalars, arrays,
      // and JSON literal objects (which are Maps but not keyword maps).
      if (compactedValue is! Map<String, Object?> ||
          !compactedValue.keys.any(
              (k) => k.startsWith('@') || _isKeywordAlias(activeContext, k))) {
        return compactedValue;
      }
      // Fall through to process as a map (for value objects that couldn't
      // be simplified, the keywords will be compacted below).
    }

    // Handle node references (only @id).
    if (expandedMap.length == 1 && expandedMap.containsKey('@id')) {
      final termDef = activeProperty != null
          ? _lookupTermByCompactIri(activeContext, activeProperty)
          : null;
      if (termDef?.typeMapping == '@id') {
        return _compactIri(
          activeContext: activeContext,
          inverseContext: inverseContext,
          iri: expandedMap['@id'] as String,
        );
      }
      if (termDef?.typeMapping == '@vocab') {
        return _compactIri(
          activeContext: activeContext,
          inverseContext: inverseContext,
          iri: expandedMap['@id'] as String,
          vocab: true,
        );
      }
    }

    // Process type-scoped contexts.
    // Type-scoped contexts apply to the typed node's direct properties but
    // do NOT propagate into nested nodes (unless @propagate: true is set).
    var typeScopedContext = activeContext;
    var typeScopedInverse = inverseContext;
    var hasTypeScope = false;
    if (expandedMap.containsKey('@type')) {
      final types = expandedMap['@type'];
      final typeList = types is List ? types.cast<String>() : [types as String];
      final sortedTypes = typeList.toList()..sort();
      for (final type in sortedTypes) {
        final termDef =
            activeContext.terms[type] ?? _findTermByIri(activeContext, type);
        if (termDef != null && termDef.hasLocalContext) {
          typeScopedContext = contextProcessor.mergeContext(
            typeScopedContext,
            termDef.localContext,
            seenContextIris: <String>{},
          );
        }
      }
      if (!identical(typeScopedContext, activeContext)) {
        hasTypeScope = true;
        // Check if the type-scoped context explicitly has @propagate: true.
        if (typeScopedContext.hasPropagate && typeScopedContext.propagate) {
          hasTypeScope = false; // Propagates normally.
        }
        typeScopedInverse = _buildInverseContext(typeScopedContext);
      }
    }

    final result = <String, Object?>{};

    final keys = expandedMap.keys.toList();
    if (ordered) {
      keys.sort();
    }

    for (final expandedProperty in keys) {
      final expandedValue = expandedMap[expandedProperty];

      if (expandedProperty == '@id') {
        final idValue = expandedValue as String;
        final compactedId = _compactIri(
          activeContext: typeScopedContext,
          inverseContext: typeScopedInverse,
          iri: idValue,
        );
        final alias = _compactIri(
          activeContext: typeScopedContext,
          inverseContext: typeScopedInverse,
          iri: '@id',
          vocab: true,
        );
        result[alias] = compactedId;
        continue;
      }

      if (expandedProperty == '@type') {
        final typeValues = expandedValue is List
            ? expandedValue.cast<String>()
            : [expandedValue as String];

        // Per spec, @type values should be compacted using the context
        // BEFORE type-scoped contexts are applied.
        final compactedTypes = typeValues.map((t) => _compactIri(
              activeContext: activeContext,
              inverseContext: inverseContext,
              iri: t,
              vocab: true,
            ));
        final alias = _compactIri(
          activeContext: typeScopedContext,
          inverseContext: typeScopedInverse,
          iri: '@type',
          vocab: true,
        );
        final typeResult = compactedTypes.toList();
        final typeTermDef = _lookupTermByCompactIri(typeScopedContext, alias);
        final typeHasSetContainer =
            typeTermDef?.containers.contains('@set') ?? false;
        // In 1.1, @container: @set on @type forces single values to array.
        // In 1.0, single values are always strings.
        final forceArray =
            typeHasSetContainer && processingMode != 'json-ld-1.0';
        if (typeResult.length == 1 && !forceArray) {
          result[alias] = typeResult[0];
        } else {
          result[alias] = typeResult;
        }
        continue;
      }

      if (expandedProperty == '@reverse') {
        final reverseMap = expandedValue as Map<String, Object?>;
        final compactedReverse = _compact(
          activeContext: typeScopedContext,
          inverseContext: typeScopedInverse,
          activeProperty: '@reverse',
          element: reverseMap,
          compactArrays: compactArrays,
          ordered: ordered,
          contextProcessor: contextProcessor,
          insideReverse: true,
        );
        if (compactedReverse is Map<String, Object?>) {
          final toRemove = <String>[];
          for (final entry in compactedReverse.entries) {
            final termDef =
                _lookupTermByCompactIri(typeScopedContext, entry.key);
            if (termDef?.isReverse == true) {
              _addValue(result, entry.key, entry.value,
                  asArray: _hasSetContainer(typeScopedContext, entry.key));
              toRemove.add(entry.key);
            }
          }
          for (final key in toRemove) {
            compactedReverse.remove(key);
          }
          if (compactedReverse.isNotEmpty) {
            final reverseAlias = _compactIri(
              activeContext: typeScopedContext,
              inverseContext: typeScopedInverse,
              iri: '@reverse',
              vocab: true,
            );
            result[reverseAlias] = compactedReverse;
          }
        }
        continue;
      }

      if (expandedProperty == '@preserve') {
        final compactedPreserve = _compact(
          activeContext: typeScopedContext,
          inverseContext: typeScopedInverse,
          activeProperty: activeProperty,
          element: expandedValue,
          compactArrays: compactArrays,
          ordered: ordered,
          contextProcessor: contextProcessor,
        );
        if (compactedPreserve is! List || (compactedPreserve).isNotEmpty) {
          result['@preserve'] = compactedPreserve;
        }
        continue;
      }

      if (expandedProperty == '@index') {
        final termDef = activeProperty != null
            ? _lookupTermByCompactIri(typeScopedContext, activeProperty)
            : null;
        if (termDef == null || !termDef.containers.contains('@index')) {
          final alias = _compactIri(
            activeContext: typeScopedContext,
            inverseContext: typeScopedInverse,
            iri: '@index',
            vocab: true,
          );
          result[alias] = expandedValue;
        }
        continue;
      }

      // Handle other keywords (@graph, @list, @included, @value, etc.)
      if (expandedProperty == '@graph' ||
          expandedProperty == '@list' ||
          expandedProperty == '@included' ||
          expandedProperty == '@value' ||
          expandedProperty == '@language' ||
          expandedProperty == '@direction') {
        final alias = _compactIri(
          activeContext: typeScopedContext,
          inverseContext: typeScopedInverse,
          iri: expandedProperty,
          vocab: true,
        );
        var compactedVal = _compact(
          activeContext: typeScopedContext,
          inverseContext: typeScopedInverse,
          activeProperty: alias,
          element: expandedValue,
          compactArrays: compactArrays,
          ordered: ordered,
          contextProcessor: contextProcessor,
        );
        // Ensure @graph value is always an array.
        if (expandedProperty == '@graph') {
          if (compactedVal is! List) {
            compactedVal = [compactedVal];
          }
        }
        result[alias] = compactedVal;
        continue;
      }

      // Regular property — empty array.
      if (expandedValue is List && expandedValue.isEmpty) {
        final compactedProp = _compactIri(
          activeContext: typeScopedContext,
          inverseContext: typeScopedInverse,
          iri: expandedProperty,
          value: expandedValue,
          vocab: true,
          reverse: insideReverse,
        );
        final nestResult = _getNestTarget(
            result, typeScopedContext, typeScopedInverse, compactedProp);
        _addValue(nestResult, compactedProp, <Object?>[], asArray: true);
        continue;
      }

      // Process each expanded value.
      final valueList = expandedValue is List ? expandedValue : [expandedValue];

      for (final expandedItem in valueList) {
        final compactedProp = _compactIri(
          activeContext: typeScopedContext,
          inverseContext: typeScopedInverse,
          iri: expandedProperty,
          value: expandedItem,
          vocab: true,
          reverse: insideReverse,
        );

        final termDef =
            _lookupTermByCompactIri(typeScopedContext, compactedProp);

        // Apply property-scoped context if present.
        var itemContext = typeScopedContext;
        var itemInverse = typeScopedInverse;
        if (termDef != null && termDef.hasLocalContext) {
          itemContext = contextProcessor.mergeContext(
            typeScopedContext,
            termDef.localContext,
            seenContextIris: <String>{},
            allowProtectedOverride: true,
          );
          itemInverse = _buildInverseContext(itemContext);
        }

        final container = termDef?.containers ?? const <String>{};
        final hasSetContainer = container.contains('@set');

        final expandedItemMap =
            expandedItem is Map<String, Object?> ? expandedItem : null;
        final isList =
            expandedItemMap != null && expandedItemMap.containsKey('@list');

        Object? compactedItem;

        if (isList) {
          final listValue = expandedItemMap['@list'];
          compactedItem = _compact(
            activeContext: itemContext,
            inverseContext: itemInverse,
            activeProperty: compactedProp,
            element: listValue,
            compactArrays: compactArrays,
            ordered: ordered,
            contextProcessor: contextProcessor,
          );
          if (compactedItem is! List) {
            compactedItem = [compactedItem];
          }
          if (!container.contains('@list')) {
            final listAlias = _compactIri(
              activeContext: itemContext,
              inverseContext: itemInverse,
              iri: '@list',
              vocab: true,
            );
            compactedItem = <String, Object?>{listAlias: compactedItem};
            if (expandedItemMap.containsKey('@index')) {
              final indexAlias = _compactIri(
                activeContext: itemContext,
                inverseContext: itemInverse,
                iri: '@index',
                vocab: true,
              );
              (compactedItem as Map<String, Object?>)[indexAlias] =
                  expandedItemMap['@index'];
            }
          }
        } else if (expandedItem is Map<String, Object?> &&
            expandedItem.containsKey('@graph')) {
          // Use @graph container only if the graph's @id is compatible
          // with the container mapping. Named graphs require @id in container.
          final graphHasId = expandedItem.containsKey('@id');
          final useGraphContainer = container.contains('@graph') &&
              (!graphHasId || container.contains('@id'));
          if (useGraphContainer) {
            // @graph container — extract graph content.
            compactedItem = _compactGraphContainer(
              itemContext: itemContext,
              itemInverse: itemInverse,
              compactedProp: compactedProp,
              expandedItem: expandedItem,
              container: container,
              hasSetContainer: hasSetContainer,
              compactArrays: compactArrays,
              ordered: ordered,
              contextProcessor: contextProcessor,
              result: result,
              typeScopedContext: typeScopedContext,
              typeScopedInverse: typeScopedInverse,
            );
            // _compactGraphContainer handles adding to result directly.
            if (compactedItem == null) continue;
          } else {
            // No @graph container — produce a full graph node object.
            compactedItem = _compactGraphValue(
              activeContext: itemContext,
              inverseContext: itemInverse,
              activeProperty: compactedProp,
              expandedItem: expandedItem,
              compactArrays: compactArrays,
              ordered: ordered,
              contextProcessor: contextProcessor,
            );
          }
        } else {
          // For nested node objects (not simple @id refs or value objects),
          // revert type-scoped context (doesn't propagate by default).
          var nestedContext = itemContext;
          var nestedInverse = itemInverse;
          if (hasTypeScope &&
              expandedItem is Map<String, Object?> &&
              !expandedItem.containsKey('@value') &&
              !(expandedItem.length == 1 && expandedItem.containsKey('@id'))) {
            // Revert to the pre-type-scoped context, but apply any
            // property-scoped context on top.
            if (termDef != null && termDef.hasLocalContext) {
              nestedContext = contextProcessor.mergeContext(
                activeContext,
                termDef.localContext,
                seenContextIris: <String>{},
              );
            } else {
              nestedContext = activeContext;
            }
            nestedInverse = _buildInverseContext(nestedContext);
          }

          compactedItem = _compact(
            activeContext: nestedContext,
            inverseContext: nestedInverse,
            activeProperty: compactedProp,
            element: expandedItem,
            compactArrays: compactArrays,
            ordered: ordered,
            contextProcessor: contextProcessor,
          );
        }

        // Handle container mappings.
        final nestResult = _getNestTarget(
            result, typeScopedContext, typeScopedInverse, compactedProp);

        if (container.contains('@language') &&
            expandedItem is Map<String, Object?> &&
            expandedItem.containsKey('@value') &&
            (!expandedItem.containsKey('@index') ||
                container.contains('@index'))) {
          // Check direction compatibility: if the term has @direction,
          // the value's @direction must match.
          final termDir = termDef?.direction;
          final hasTermDir = termDef?.hasDirection ?? false;
          final valueDir = expandedItem['@direction'] as String?;
          final directionOk = !hasTermDir || termDir == valueDir;

          if (directionOk) {
            final langKey = (expandedItem['@language'] as String?) ?? '@none';
            final mapValue = compactedItem is Map<String, Object?> &&
                    compactedItem.containsKey('@value')
                ? compactedItem['@value']
                : compactedItem;
            _addToContainerMap(
              result: nestResult,
              compactedProp: compactedProp,
              mapKey: langKey,
              value: mapValue,
              activeContext: itemContext,
              inverseContext: itemInverse,
              asArray: hasSetContainer,
            );
            continue;
          }
          // Direction mismatch — fall through to default handling.
        }

        if (container.contains('@index') &&
            !container.contains('@graph') &&
            expandedItem is Map<String, Object?>) {
          final indexProperty = termDef?.indexMapping;
          String mapKey;
          if (indexProperty != null && indexProperty != '@index') {
            // Property-valued index: find the index property in the
            // compacted item. Try the raw indexMapping first (it may
            // already match the compacted key), then try compacting
            // the expanded IRI.
            String compactedIndexProp = indexProperty;
            if (compactedItem is Map<String, Object?> &&
                !compactedItem.containsKey(indexProperty)) {
              // The raw indexMapping didn't match — try expanding and
              // re-compacting to find the correct key.
              try {
                compactedIndexProp = _compactIri(
                  activeContext: itemContext,
                  inverseContext: itemInverse,
                  iri: indexProperty,
                  vocab: true,
                );
              } catch (_) {
                // If compaction fails (e.g., IRI confusion), keep the raw form.
              }
            }
            mapKey = _extractPropertyIndex(compactedItem, compactedIndexProp) ??
                '@none';
          } else {
            mapKey = expandedItem.containsKey('@index')
                ? expandedItem['@index'] as String
                : '@none';
          }
          // Simplify value objects that only have @value left
          // (the @index was removed by _compact).
          final simplifiedItem =
              _simplifyValueObject(compactedItem, itemContext);
          _addToContainerMap(
            result: nestResult,
            compactedProp: compactedProp,
            mapKey: mapKey,
            value: simplifiedItem,
            activeContext: itemContext,
            inverseContext: itemInverse,
            asArray: hasSetContainer,
          );
          continue;
        }

        if (container.contains('@id') && expandedItem is Map<String, Object?>) {
          final idValue = expandedItem['@id'] as String?;
          final mapKey = idValue != null
              ? _compactIri(
                  activeContext: itemContext,
                  inverseContext: itemInverse,
                  iri: idValue,
                )
              : '@none';
          if (compactedItem is Map<String, Object?> &&
              !container.contains('@graph')) {
            final idAlias = _compactIri(
              activeContext: itemContext,
              inverseContext: itemInverse,
              iri: '@id',
              vocab: true,
            );
            compactedItem.remove(idAlias);
          }
          final simplifiedItem =
              _simplifyValueObject(compactedItem, itemContext);
          _addToContainerMap(
            result: nestResult,
            compactedProp: compactedProp,
            mapKey: mapKey,
            value: simplifiedItem,
            activeContext: itemContext,
            inverseContext: itemInverse,
            asArray: hasSetContainer,
          );
          continue;
        }

        if (container.contains('@type') &&
            expandedItem is Map<String, Object?>) {
          final types = expandedItem['@type'];
          String mapKey;
          if (types is List && types.isNotEmpty) {
            mapKey = _compactIri(
              activeContext: itemContext,
              inverseContext: itemInverse,
              iri: types.first as String,
              vocab: true,
            );
            if (compactedItem is Map<String, Object?>) {
              final typeAlias = _compactIri(
                activeContext: itemContext,
                inverseContext: itemInverse,
                iri: '@type',
                vocab: true,
              );
              final currentTypes = compactedItem[typeAlias];
              if (currentTypes is List) {
                final remaining =
                    currentTypes.where((t) => t != mapKey).toList();
                if (remaining.isEmpty) {
                  compactedItem.remove(typeAlias);
                } else if (remaining.length == 1) {
                  compactedItem[typeAlias] = remaining[0];
                } else {
                  compactedItem[typeAlias] = remaining;
                }
              } else if (currentTypes == mapKey) {
                compactedItem.remove(typeAlias);
              }
            }
          } else if (types is String) {
            mapKey = _compactIri(
              activeContext: itemContext,
              inverseContext: itemInverse,
              iri: types,
              vocab: true,
            );
            if (compactedItem is Map<String, Object?>) {
              final typeAlias = _compactIri(
                activeContext: itemContext,
                inverseContext: itemInverse,
                iri: '@type',
                vocab: true,
              );
              compactedItem.remove(typeAlias);
            }
          } else {
            mapKey = '@none';
          }
          // Simplify: if only @id remains, compact to string.
          var typeContainerValue = compactedItem;
          if (typeContainerValue is Map<String, Object?> &&
              typeContainerValue.length == 1) {
            final idAlias = _compactIri(
              activeContext: itemContext,
              inverseContext: itemInverse,
              iri: '@id',
              vocab: true,
            );
            if (typeContainerValue.containsKey(idAlias)) {
              // Re-compact the @id using @vocab if the term has @type: @vocab.
              var idVal = typeContainerValue[idAlias];
              if (termDef?.typeMapping == '@vocab' && idVal is String) {
                idVal = _compactIri(
                  activeContext: itemContext,
                  inverseContext: itemInverse,
                  iri: expandedItem['@id'] as String,
                  vocab: true,
                );
              }
              typeContainerValue = idVal;
            }
          }
          _addToContainerMap(
            result: nestResult,
            compactedProp: compactedProp,
            mapKey: mapKey,
            value: typeContainerValue,
            activeContext: itemContext,
            inverseContext: itemInverse,
            asArray: hasSetContainer,
          );
          continue;
        }

        // Default: add to result.
        final asArray = !compactArrays ||
            container.contains('@set') ||
            container.contains('@list') ||
            expandedProperty == '@list' ||
            expandedProperty == '@graph';
        _addValue(nestResult, compactedProp, compactedItem, asArray: asArray);
      }
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // @graph container compaction
  // ---------------------------------------------------------------------------

  /// Handles @graph container — adds to result directly and returns null,
  /// or returns the compacted item to be added normally.
  Object? _compactGraphContainer({
    required JsonLdContext itemContext,
    required _InverseContext itemInverse,
    required String compactedProp,
    required Map<String, Object?> expandedItem,
    required Set<String> container,
    required bool hasSetContainer,
    required bool compactArrays,
    required bool ordered,
    required JsonLdContextProcessor contextProcessor,
    required Map<String, Object?> result,
    required JsonLdContext typeScopedContext,
    required _InverseContext typeScopedInverse,
  }) {
    final graphContent = _compact(
      activeContext: itemContext,
      inverseContext: itemInverse,
      activeProperty: compactedProp,
      element: expandedItem['@graph'],
      compactArrays: compactArrays,
      ordered: ordered,
      contextProcessor: contextProcessor,
    );

    final graphArray = graphContent is List ? graphContent : [graphContent];
    final nestResult = _getNestTarget(
        result, typeScopedContext, typeScopedInverse, compactedProp);

    if (container.contains('@id')) {
      final idValue = expandedItem['@id'] as String?;
      final mapKey = idValue != null
          ? _compactIri(
              activeContext: itemContext,
              inverseContext: itemInverse,
              iri: idValue)
          : _compactIri(
              activeContext: itemContext,
              inverseContext: itemInverse,
              iri: '@none',
              vocab: true);
      final graphValue = hasSetContainer || graphArray.length != 1
          ? graphArray
          : (compactArrays ? graphArray[0] : graphArray);
      _addToContainerMap(
        result: nestResult,
        compactedProp: compactedProp,
        mapKey: mapKey,
        value: graphValue,
        activeContext: itemContext,
        inverseContext: itemInverse,
        asArray: hasSetContainer,
      );
    } else if (container.contains('@index')) {
      final mapKey = expandedItem.containsKey('@index')
          ? expandedItem['@index'] as String
          : _compactIri(
              activeContext: itemContext,
              inverseContext: itemInverse,
              iri: '@none',
              vocab: true);
      final graphValue = hasSetContainer || graphArray.length != 1
          ? graphArray
          : (compactArrays ? graphArray[0] : graphArray);
      _addToContainerMap(
        result: nestResult,
        compactedProp: compactedProp,
        mapKey: mapKey,
        value: graphValue,
        activeContext: itemContext,
        inverseContext: itemInverse,
        asArray: hasSetContainer,
      );
    } else {
      // Simple @graph container.
      Object? graphValue;
      if (graphArray.length == 1) {
        graphValue =
            compactArrays && !hasSetContainer ? graphArray[0] : graphArray;
      } else {
        // Multiple graph nodes — wrap with @included.
        final includedAlias = _compactIri(
          activeContext: itemContext,
          inverseContext: itemInverse,
          iri: '@included',
          vocab: true,
        );
        graphValue = <String, Object?>{includedAlias: graphArray};
      }
      _addValue(nestResult, compactedProp, graphValue,
          asArray: hasSetContainer);
    }

    return null; // Signal that result was handled.
  }

  /// Produces a graph node object for values with @graph but no @graph container.
  Object? _compactGraphValue({
    required JsonLdContext activeContext,
    required _InverseContext inverseContext,
    required String? activeProperty,
    required Map<String, Object?> expandedItem,
    required bool compactArrays,
    required bool ordered,
    required JsonLdContextProcessor contextProcessor,
  }) {
    Object? compactedItem = _compact(
      activeContext: activeContext,
      inverseContext: inverseContext,
      activeProperty: activeProperty,
      element: expandedItem['@graph'],
      compactArrays: compactArrays,
      ordered: ordered,
      contextProcessor: contextProcessor,
    );

    // Ensure @graph value is an array, but apply compactArrays for single items.
    Object? graphContent;
    if (compactedItem is List) {
      graphContent = (compactArrays && compactedItem.length == 1)
          ? compactedItem[0]
          : compactedItem;
    } else {
      graphContent = compactedItem;
    }
    final graphAlias = _compactIri(
      activeContext: activeContext,
      inverseContext: inverseContext,
      iri: '@graph',
      vocab: true,
    );
    final graphObject = <String, Object?>{graphAlias: graphContent};

    if (expandedItem.containsKey('@id')) {
      final idAlias = _compactIri(
        activeContext: activeContext,
        inverseContext: inverseContext,
        iri: '@id',
        vocab: true,
      );
      graphObject[idAlias] = _compactIri(
        activeContext: activeContext,
        inverseContext: inverseContext,
        iri: expandedItem['@id'] as String,
      );
    }

    if (expandedItem.containsKey('@index')) {
      final indexAlias = _compactIri(
        activeContext: activeContext,
        inverseContext: inverseContext,
        iri: '@index',
        vocab: true,
      );
      graphObject[indexAlias] = expandedItem['@index'];
    }

    return graphObject;
  }

  // ---------------------------------------------------------------------------
  // Value Compaction (section 6.3)
  // ---------------------------------------------------------------------------

  Object? _compactValue({
    required JsonLdContext activeContext,
    required _InverseContext inverseContext,
    required String? activeProperty,
    required Map<String, Object?> value,
  }) {
    final termDef = activeProperty != null
        ? _lookupTermByCompactIri(activeContext, activeProperty)
        : null;

    final rawTypeMapping = termDef?.typeMapping;
    // Normalize rdf:JSON → @json.
    final typeMapping =
        rawTypeMapping == rdfJsonDatatype ? '@json' : rawTypeMapping;
    final languageMapping = termDef?.language;
    final hasLanguageMapping = termDef?.hasLanguage ?? false;
    final directionMapping = termDef?.direction;
    final hasDirectionMapping = termDef?.hasDirection ?? false;

    final valueValue = value['@value'];
    final valueType = value['@type'] as String?;
    final valueLanguage = value['@language'] as String?;
    final valueDirection = value['@direction'] as String?;
    final hasValueIndex = value.containsKey('@index');

    // If @type is @json.
    if (valueType == '@json') {
      if (typeMapping == '@json') {
        return valueValue;
      }
      return _compactValueObject(
        activeContext: activeContext,
        inverseContext: inverseContext,
        value: value,
      );
    }

    // If the type mapping matches the value's @type, return bare value.
    if (typeMapping != null && typeMapping == valueType) {
      return valueValue;
    }

    // If @type: @id and value has @id (value object with type @id).
    if (typeMapping == '@id' && value.containsKey('@id')) {
      return _compactIri(
        activeContext: activeContext,
        inverseContext: inverseContext,
        iri: value['@id'] as String,
      );
    }

    // If type mapping is @none, always keep the value object as-is.
    if (typeMapping == '@none') {
      return _compactValueObject(
        activeContext: activeContext,
        inverseContext: inverseContext,
        value: value,
      );
    }

    // If the value has @language and it matches the term's language mapping.
    if (valueLanguage != null &&
        hasLanguageMapping &&
        _languageMatches(valueLanguage, languageMapping)) {
      if (!hasDirectionMapping ||
          _directionMatches(valueDirection, directionMapping)) {
        if (valueType == null && !hasValueIndex) {
          return valueValue;
        }
      }
    }

    // If direction matches.
    if (valueDirection != null &&
        hasDirectionMapping &&
        _directionMatches(valueDirection, directionMapping)) {
      if (!hasLanguageMapping ||
          _languageMatches(valueLanguage, languageMapping)) {
        if (valueType == null && !hasValueIndex) {
          return valueValue;
        }
      }
    }

    // If value has @language matching context default, and term has no
    // explicit language/type coercion, simplify to bare value.
    if (valueLanguage != null &&
        valueType == null &&
        !hasValueIndex &&
        !hasLanguageMapping &&
        !hasDirectionMapping &&
        typeMapping == null) {
      // Term has no coercion — check if value language matches context default.
      if (_languageMatches(valueLanguage, activeContext.language) &&
          (valueDirection == null ||
              valueDirection == activeContext.direction)) {
        return valueValue;
      }
    }

    // If value is a simple value (no type, no language, no direction).
    if (valueType == null && valueLanguage == null && valueDirection == null) {
      // Non-string values (numbers, booleans) are never affected by
      // @language settings — simplify them to bare values when there's
      // no type coercion conflict.
      final isNonString = valueValue is num || valueValue is bool;

      if (hasLanguageMapping &&
          languageMapping == null &&
          !hasDirectionMapping) {
        if (!hasValueIndex) {
          return valueValue;
        }
      }
      if (hasDirectionMapping &&
          directionMapping == null &&
          !hasLanguageMapping) {
        if (!hasValueIndex) {
          return valueValue;
        }
      }
      if (hasLanguageMapping &&
          languageMapping == null &&
          hasDirectionMapping &&
          directionMapping == null) {
        if (!hasValueIndex) {
          return valueValue;
        }
      }
      // If no language mapping on term and no context default language/direction.
      if (!hasLanguageMapping &&
          activeContext.language == null &&
          !hasDirectionMapping &&
          activeContext.direction == null) {
        if (!hasValueIndex) {
          return valueValue;
        }
      }
      // Non-string values can always be simplified when term has no type coercion.
      if (isNonString && typeMapping == null && !hasValueIndex) {
        return valueValue;
      }
    }

    // Return the full value object with compacted keywords.
    return _compactValueObject(
      activeContext: activeContext,
      inverseContext: inverseContext,
      value: value,
    );
  }

  Map<String, Object?> _compactValueObject({
    required JsonLdContext activeContext,
    required _InverseContext inverseContext,
    required Map<String, Object?> value,
  }) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final alias = _compactIri(
        activeContext: activeContext,
        inverseContext: inverseContext,
        iri: entry.key,
        vocab: true,
      );
      Object? val = entry.value;
      if (entry.key == '@type' && val is String) {
        val = _compactIri(
          activeContext: activeContext,
          inverseContext: inverseContext,
          iri: val,
          vocab: true,
        );
      }
      result[alias] = val;
    }
    return result;
  }

  bool _languageMatches(String? valueLang, String? termLang) {
    if (valueLang == null && termLang == null) return true;
    if (valueLang == null || termLang == null) return false;
    return valueLang.toLowerCase() == termLang.toLowerCase();
  }

  bool _directionMatches(String? valueDir, String? termDir) {
    return valueDir == termDir;
  }

  // ---------------------------------------------------------------------------
  // IRI Compaction (section 6.2)
  // ---------------------------------------------------------------------------

  String _compactIri({
    required JsonLdContext activeContext,
    required _InverseContext inverseContext,
    required String iri,
    Object? value,
    bool vocab = false,
    bool reverse = false,
  }) {
    if (iri.isEmpty) return iri;

    // Check for keyword aliases.
    if (vocab && jsonLdKeywords.contains(iri)) {
      final term = _selectTerm(
        activeContext: activeContext,
        inverseContext: inverseContext,
        iri: iri,
        value: value,
        reverse: reverse,
      );
      if (term != null) return term;

      // Direct keyword alias lookup: keywordAliases is {term: keyword}.
      for (final entry in activeContext.keywordAliases.entries) {
        if (entry.value == iri) return entry.key;
      }
      return iri;
    }

    if (!vocab && jsonLdKeywords.contains(iri)) {
      return iri;
    }

    // If vocab is true, try the inverse context.
    if (vocab) {
      final term = _selectTerm(
        activeContext: activeContext,
        inverseContext: inverseContext,
        iri: iri,
        value: value,
        reverse: reverse,
      );
      if (term != null) return term;
    }

    // If vocab mode, try removing the @vocab prefix first (preferred over
    // compact IRI prefix:suffix form per spec).
    if (vocab &&
        activeContext.vocab != null &&
        activeContext.vocab!.isNotEmpty) {
      if (iri.startsWith(activeContext.vocab!) &&
          iri.length > activeContext.vocab!.length) {
        final localName = iri.substring(activeContext.vocab!.length);
        if (!localName.contains(':')) {
          final existingDef = activeContext.terms[localName];
          if (existingDef == null ||
              existingDef.isNullMapping ||
              existingDef.iri == iri) {
            return localName;
          }
        }
      }
    }

    // Try compact IRIs (prefix:suffix).
    final compactIri =
        _tryCompactIriWithPrefix(activeContext, inverseContext, iri, value);
    if (compactIri != null) return compactIri;

    // Check for IRI confusion: if the IRI looks like it uses a prefix
    // that is defined in the context but with a different IRI, it would
    // be misinterpreted when re-parsed.
    if (vocab) {
      final colonIdx = iri.indexOf(':');
      if (colonIdx > 0) {
        final prefix = iri.substring(0, colonIdx);
        final prefixDef = activeContext.terms[prefix];
        if (prefixDef != null &&
            !prefixDef.isNullMapping &&
            prefixDef.iri != null &&
            canUseAsPrefixStrict(prefixDef, processingMode: processingMode) &&
            !iri.startsWith(prefixDef.iri!)) {
          throw RdfSyntaxException(
            'IRI confused with prefix',
            format: 'JSON-LD',
          );
        }
      }
    }

    // If not vocab mode, try to make it relative to @base.
    if (!vocab) {
      return _compactIriRelativeToBase(activeContext, iri);
    }

    return iri;
  }

  String? _selectTerm({
    required JsonLdContext activeContext,
    required _InverseContext inverseContext,
    required String iri,
    Object? value,
    bool reverse = false,
  }) {
    final entry = inverseContext.entries[iri];
    if (entry == null) return null;

    // Determine containers to prefer based on value.
    final preferredContainers = <String>[];
    String typeOrLanguage = '@language';
    String typeOrLanguageValue = '@null';

    if (value is Map<String, Object?>) {
      if (value.containsKey('@preserve')) {
        // For @preserve, unwrap and use the inner value.
        value = value['@preserve'];
        if (value is List && value.isNotEmpty) {
          value = value[0] as Map<String, Object?>?;
        }
      }

      if (value is Map<String, Object?> && value.containsKey('@list')) {
        // @list container cannot preserve @index, so don't prefer it
        // when the value also has @index.
        if (!value.containsKey('@index')) {
          preferredContainers.add('@list');
        }
        final listValue = value['@list'];
        if (listValue is List && listValue.isEmpty) {
          typeOrLanguage = '@any';
          typeOrLanguageValue = '@any';
        } else if (listValue is List) {
          // Scan list items to determine common type/language.
          String? commonType;
          String? commonLanguage;
          bool allSameType = true;
          bool allSameLanguage = true;
          for (final item in listValue) {
            if (item is Map<String, Object?>) {
              if (item.containsKey('@value')) {
                final itemType = item['@type'] as String?;
                final itemLang = item['@language'] as String?;
                final itemDir = item['@direction'] as String?;

                String langKey;
                if (itemLang != null) {
                  langKey = itemDir != null ? '${itemLang}_$itemDir' : itemLang;
                } else if (itemDir != null) {
                  langKey = '_$itemDir';
                } else if (itemType == null) {
                  langKey = '@null';
                } else {
                  langKey = '@none';
                }

                if (commonLanguage == null) {
                  commonLanguage = langKey;
                } else if (commonLanguage != langKey) {
                  allSameLanguage = false;
                }
                if (commonType == null) {
                  commonType = itemType ?? '@none';
                } else if (commonType != (itemType ?? '@none')) {
                  allSameType = false;
                }
              } else {
                // Node reference.
                if (commonType == null) {
                  commonType = '@id';
                } else if (commonType != '@id') {
                  allSameType = false;
                }
                if (commonLanguage == null) {
                  commonLanguage = '@none';
                } else if (commonLanguage != '@none') {
                  allSameLanguage = false;
                }
              }
            } else {
              // Scalar in list.
              if (commonLanguage == null) {
                commonLanguage = '@null';
              } else if (commonLanguage != '@null') {
                allSameLanguage = false;
              }
              if (commonType == null) {
                commonType = '@none';
              } else if (commonType != '@none') {
                allSameType = false;
              }
            }
          }

          // Per spec: if all items share a common type (other than @none),
          // prefer @type; otherwise prefer @language.
          final effectiveType =
              (allSameType && commonType != null) ? commonType : '@none';
          final effectiveLang = (allSameLanguage && commonLanguage != null)
              ? commonLanguage
              : '@none';
          if (effectiveType != '@none') {
            typeOrLanguage = '@type';
            typeOrLanguageValue = effectiveType;
          } else if (effectiveLang != '@none') {
            typeOrLanguage = '@language';
            typeOrLanguageValue = effectiveLang;
          } else {
            typeOrLanguage = '@any';
            typeOrLanguageValue = '@any';
          }
        }
      } else if (value is Map<String, Object?> && value.containsKey('@graph')) {
        if (value.containsKey('@id')) {
          preferredContainers.addAll([
            '@graph@id@set',
            '@graph@id',
            '@graph@set',
            '@graph',
          ]);
        }
        if (value.containsKey('@index')) {
          preferredContainers.addAll([
            '@graph@index@set',
            '@graph@index',
            '@graph@set',
            '@graph',
          ]);
        }
        if (!value.containsKey('@id') && !value.containsKey('@index')) {
          preferredContainers.addAll(['@graph@set', '@graph']);
        }
      }

      if (value is Map<String, Object?> &&
          !value.containsKey('@list') &&
          !value.containsKey('@graph') &&
          value.containsKey('@value')) {
        final valueType = value['@type'] as String?;
        final valueLang = value['@language'] as String?;
        final valueDir = value['@direction'] as String?;
        // Always add @index containers — values without @index use @none key.
        preferredContainers.addAll(['@index', '@index@set']);
        if (valueType == '@json') {
          preferredContainers.addAll(['@json', '@none', '@any']);
          typeOrLanguage = '@type';
          typeOrLanguageValue = '@json';
        } else if (valueType != null) {
          typeOrLanguage = '@type';
          typeOrLanguageValue = valueType;
        } else if (valueLang != null) {
          // @language containers can't preserve @index, so only prefer
          // them when the value has no @index.
          if (!value.containsKey('@index')) {
            preferredContainers.addAll(['@language', '@language@set']);
          }
          typeOrLanguage = '@language';
          typeOrLanguageValue = valueLang;
          if (valueDir != null) {
            typeOrLanguageValue = '${valueLang}_$valueDir';
          }
        } else if (valueDir != null) {
          typeOrLanguage = '@language';
          typeOrLanguageValue = '_$valueDir';
        } else {
          // Plain value (no type, no language, no direction).
          // @language containers can't preserve @index.
          if (!value.containsKey('@index')) {
            preferredContainers.addAll(['@language', '@language@set']);
          }
          typeOrLanguage = '@language';
          typeOrLanguageValue = '@null';
        }
      } else if (value is Map<String, Object?> &&
          !value.containsKey('@list') &&
          !value.containsKey('@graph')) {
        // Node object (not a value object, list, or graph).
        // Always add @index containers — values without @index use @none key.
        preferredContainers.addAll(['@index', '@index@set']);
        if (value.containsKey('@id')) {
          preferredContainers.addAll(['@id', '@id@set']);
        }
        if (value.containsKey('@type')) {
          preferredContainers.addAll(['@type', '@set@type']);
          final types = value['@type'];
          if (types is List && types.isNotEmpty) {
            typeOrLanguage = '@type';
            typeOrLanguageValue = types.first as String;
          } else if (types is String) {
            typeOrLanguage = '@type';
            typeOrLanguageValue = types;
          } else {
            typeOrLanguage = '@type';
            typeOrLanguageValue = '@id';
          }
        } else {
          typeOrLanguage = '@type';
          typeOrLanguageValue = '@id';
        }
      }
    } else if (value is List) {
      if ((value).isEmpty) {
        typeOrLanguage = '@any';
        typeOrLanguageValue = '@any';
      }
    }

    preferredContainers.addAll(['@set', '@none']);

    // If value is not a map or list, prefer no constraint.
    if (value is! Map && value is! List) {
      typeOrLanguage = '@any';
      typeOrLanguageValue = '@any';
    }

    // Build preferred values list per spec §6.2.2.
    final preferredValues = <String>[];
    if (typeOrLanguageValue == '@reverse') {
      preferredValues.addAll(['@reverse', '@none']);
    } else if ((typeOrLanguageValue == '@id' ||
            typeOrLanguageValue == '@reverse') &&
        value is Map<String, Object?> &&
        value.containsKey('@id')) {
      // Check if the value's @id can be compacted via @vocab to a term.
      final valueId = value['@id'] as String;
      final vocabCompacted = _compactIri(
        activeContext: activeContext,
        inverseContext: inverseContext,
        iri: valueId,
        vocab: true,
      );
      // If vocab-compacted form matches a term, prefer @vocab before @id.
      if (activeContext.terms.containsKey(vocabCompacted)) {
        preferredValues.addAll(['@vocab', '@id', '@none']);
      } else {
        preferredValues.addAll(['@id', '@vocab', '@none']);
      }
    } else {
      preferredValues.addAll([typeOrLanguageValue, '@none']);
    }
    preferredValues.add('@any');

    // When not looking for @reverse, skip reverse terms.
    final wantReverse = reverse;

    // Search through preferred containers and type/language values.
    for (final container in preferredContainers) {
      final containerEntry = entry.containers[container];
      if (containerEntry == null) continue;

      final langOrTypeMap = containerEntry[typeOrLanguage];
      if (langOrTypeMap != null) {
        for (final prefVal in preferredValues) {
          final term = langOrTypeMap[prefVal];
          if (term != null) {
            if (!wantReverse) {
              final def = activeContext.terms[term];
              if (def != null && def.isReverse) continue;
            }
            return term;
          }
        }
      }

      // Try @any map for each preferred value.
      final anyMap = containerEntry['@any'];
      if (anyMap != null) {
        for (final prefVal in preferredValues) {
          final anyTerm = anyMap[prefVal];
          if (anyTerm != null) {
            final anyDef = activeContext.terms[anyTerm];
            if (anyDef != null &&
                value is Map<String, Object?> &&
                value.containsKey('@value')) {
              // Skip terms whose @direction constraint doesn't match.
              if (anyDef.hasDirection && anyDef.direction != null) {
                final valDir = value['@direction'] as String?;
                if (valDir != anyDef.direction) continue;
              }
              // Skip @language container terms for values with no
              // language — prefer more specific terms (e.g., @language: null).
              if (anyDef.containers.contains('@language') &&
                  typeOrLanguageValue == '@null') {
                continue;
              }
              // Skip @type: @id/@vocab terms for plain string values
              // (not node references) — the term expects IRI values.
              if ((anyDef.typeMapping == '@id' ||
                      anyDef.typeMapping == '@vocab') &&
                  !value.containsKey('@id') &&
                  value['@type'] == null) {
                continue;
              }
            }
            return anyTerm;
          }
        }
      }
    }

    return null;
  }

  String? _tryCompactIriWithPrefix(JsonLdContext context,
      _InverseContext inverseContext, String iri, Object? value) {
    String? bestCompactIri;

    // Fast path: scan the IRI for gen-delim split points and look up
    // candidate namespaces in the pre-built index (O(IRI_length) instead
    // of O(context_terms)).
    for (var i = iri.length - 1; i >= 0; i--) {
      if (!_isGenDelim(iri.codeUnitAt(i))) continue;

      final candidatePrefix = iri.substring(0, i + 1);
      final term = inverseContext.genDelimPrefixIndex[candidatePrefix];
      if (term == null) continue;
      if (candidatePrefix == iri) continue;

      final candidate =
          _validateCompactCandidate(context, iri, candidatePrefix, term, value);
      if (candidate != null &&
          (bestCompactIri == null ||
              candidate.length < bestCompactIri.length)) {
        bestCompactIri = candidate;
      }
    }

    // Slow path: check non-gen-delim prefixes (those with explicit
    // @prefix: true). These are typically very few (0-2 entries).
    for (final (term, prefixIri) in inverseContext.nonGenDelimPrefixes) {
      if (prefixIri == iri) continue;
      if (!iri.startsWith(prefixIri) || iri.length <= prefixIri.length) {
        continue;
      }

      final candidate =
          _validateCompactCandidate(context, iri, prefixIri, term, value);
      if (candidate != null &&
          (bestCompactIri == null ||
              candidate.length < bestCompactIri.length)) {
        bestCompactIri = candidate;
      }
    }

    return bestCompactIri;
  }

  /// Validates and returns a compact IRI candidate, or `null` if it would
  /// cause a conflict.
  String? _validateCompactCandidate(
    JsonLdContext context,
    String iri,
    String prefixIri,
    String term,
    Object? value,
  ) {
    final suffix = iri.substring(prefixIri.length);
    final candidate = '$term:$suffix';

    final existingDef = context.terms[candidate];
    if (existingDef != null &&
        !existingDef.isNullMapping &&
        existingDef.iri != iri) {
      return null;
    }

    if (existingDef != null &&
        (existingDef.typeMapping == '@id' ||
            existingDef.typeMapping == '@vocab') &&
        value is Map<String, Object?> &&
        value.containsKey('@value') &&
        !value.containsKey('@id') &&
        value['@type'] == null) {
      return null;
    }

    return candidate;
  }

  bool _isEmptyContext(Object? contextValue) {
    if (contextValue == null) return true;
    if (contextValue is Map && contextValue.isEmpty) return true;
    if (contextValue is List && contextValue.isEmpty) return true;
    return false;
  }

  static const _jsonLdRelativizeOptions = IriRelativizationOptions(
    maxUpLevels: null,
    maxAdditionalLength: null,
    allowSiblingDirectories: true,
    allowAbsolutePath: false,
  );

  String _compactIriRelativeToBase(JsonLdContext context, String iri) {
    String? base;
    if (context.hasBase) {
      base = context.base;
    } else {
      base = documentBaseUri;
    }

    if (base != null) {
      try {
        // Check for query-only or fragment-only differences first.
        final baseUri = Uri.parse(base);
        final iriUri = Uri.parse(iri);
        if (baseUri.scheme == iriUri.scheme &&
            baseUri.authority == iriUri.authority &&
            baseUri.path == iriUri.path) {
          if (iriUri.hasQuery) {
            final q = '?${iriUri.query}';
            return iriUri.hasFragment ? '$q#${iriUri.fragment}' : q;
          }
          if (iriUri.hasFragment) {
            return '#${iriUri.fragment}';
          }
        }

        final relative =
            relativizeIri(iri, base, options: _jsonLdRelativizeOptions);
        if (relative != iri) {
          // When relativizeIri returns empty string (IRI equals base),
          // use the last path segment instead per JSON-LD convention.
          if (relative.isEmpty) {
            final segments = iriUri.pathSegments;
            if (segments.isNotEmpty && segments.last.isNotEmpty) {
              return segments.last;
            }
          }
          return _sanitizeRelativeIri(relative);
        }
      } catch (_) {
        // Ignore errors.
      }
    }

    return iri;
  }

  /// Ensures a relative IRI doesn't look like a JSON-LD keyword or
  /// a compact IRI by prepending "./" if needed.
  String _sanitizeRelativeIri(String relative) {
    if (relative.isEmpty) return relative;
    // Relative IRIs starting with @ look like keywords — prefix with ./
    if (relative.startsWith('@')) {
      return './$relative';
    }
    // Relative IRIs containing : before / look like compact IRIs.
    final colonIdx = relative.indexOf(':');
    final slashIdx = relative.indexOf('/');
    if (colonIdx >= 0 && (slashIdx < 0 || colonIdx < slashIdx)) {
      // Has colon before any slash — could be confused with compact IRI.
      if (!relative.startsWith('#') &&
          !relative.startsWith('?') &&
          !relative.startsWith('/')) {
        return './$relative';
      }
    }
    return relative;
  }

  // ---------------------------------------------------------------------------
  // Inverse Context Creation (section 4.3)
  // ---------------------------------------------------------------------------

  _InverseContext _buildInverseContext(JsonLdContext context) {
    final entries = <String, _InverseContextEntry>{};

    // Sort terms for deterministic selection (shorter first, then alphabetical).
    final sortedTerms = context.terms.keys.toList()
      ..sort((a, b) {
        final lenCmp = a.length.compareTo(b.length);
        return lenCmp != 0 ? lenCmp : a.compareTo(b);
      });

    for (final term in sortedTerms) {
      final def = context.terms[term]!;
      if (def.isNullMapping) continue;

      final iri = def.iri;
      if (iri == null) continue;

      final entry = entries.putIfAbsent(
        iri,
        () => _InverseContextEntry(),
      );

      // Determine container key.
      String containerKey;
      if (def.containers.isEmpty) {
        containerKey = '@none';
      } else {
        final sorted = def.containers.toList()..sort();
        containerKey = sorted.join('');
        if (containerKey.isEmpty) containerKey = '@none';
      }

      final containerMap = entry.containers.putIfAbsent(
        containerKey,
        () => <String, Map<String, String>>{},
      );

      final typeMapping = def.typeMapping;
      final languageMapping = def.language;
      final hasLanguage = def.hasLanguage;
      final directionMapping = def.direction;
      final hasDirection = def.hasDirection;

      if (def.isReverse) {
        containerMap
            .putIfAbsent('@type', () => <String, String>{})
            .putIfAbsent('@reverse', () => term);
      }

      // Normalize rdf:JSON → @json for consistent matching.
      final normalizedType =
          typeMapping == rdfJsonDatatype ? '@json' : typeMapping;

      if (normalizedType != null) {
        containerMap
            .putIfAbsent('@type', () => <String, String>{})
            .putIfAbsent(normalizedType, () => term);
      }

      if (hasLanguage && hasDirection) {
        final normalizedLang = languageMapping?.toLowerCase();
        final key = normalizedLang != null && directionMapping != null
            ? '${normalizedLang}_$directionMapping'
            : normalizedLang ??
                (directionMapping != null ? '_$directionMapping' : '@null');
        containerMap
            .putIfAbsent('@language', () => <String, String>{})
            .putIfAbsent(key, () => term);
      } else if (hasLanguage) {
        containerMap
            .putIfAbsent('@language', () => <String, String>{})
            .putIfAbsent(languageMapping?.toLowerCase() ?? '@null', () => term);
      } else if (hasDirection) {
        containerMap
            .putIfAbsent('@language', () => <String, String>{})
            .putIfAbsent(
                directionMapping != null ? '_$directionMapping' : '@null',
                () => term);
      } else if (typeMapping == null) {
        // No type, no language — register under both default language and @type @none.
        containerMap
            .putIfAbsent('@language', () => <String, String>{})
            .putIfAbsent(_activeContextLanguageKey(context), () => term);
        containerMap
            .putIfAbsent('@type', () => <String, String>{})
            .putIfAbsent('@none', () => term);
      }

      // Add @any for terms that can serve as catch-all matches.
      // Reverse terms, terms with specific datatype IRIs (not keyword types
      // like @id, @vocab, @none, @json), or specific language mappings should
      // NOT serve as @any.
      if (!def.isReverse) {
        final isKeywordType = normalizedType == '@id' ||
            normalizedType == '@vocab' ||
            normalizedType == '@none' ||
            normalizedType == '@json';
        final hasSpecificConstraint = (typeMapping != null && !isKeywordType) ||
            (hasLanguage && languageMapping != null);
        if (!hasSpecificConstraint) {
          containerMap
              .putIfAbsent('@any', () => <String, String>{})
              .putIfAbsent('@any', () => term);
        }
      }
    }

    // Build prefix indices for O(1) lookups in _tryCompactIriWithPrefix.
    // The sortedTerms iteration order (shortest first) ensures the first
    // prefix-capable term wins via putIfAbsent.
    final genDelimPrefixIndex = <String, String>{};
    final nonGenDelimPrefixes = <(String, String)>[];
    final nonGenDelimSeen = <String>{};

    for (final term in sortedTerms) {
      final def = context.terms[term]!;
      if (def.isNullMapping || def.iri == null) continue;
      if (!canUseAsPrefixStrict(def, processingMode: processingMode)) continue;
      final iri = def.iri!;
      if (iri.isNotEmpty && _isGenDelim(iri.codeUnitAt(iri.length - 1))) {
        genDelimPrefixIndex.putIfAbsent(iri, () => term);
      } else if (nonGenDelimSeen.add(iri)) {
        nonGenDelimPrefixes.add((term, iri));
      }
    }

    return _InverseContext(
      entries: entries,
      genDelimPrefixIndex: genDelimPrefixIndex,
      nonGenDelimPrefixes: nonGenDelimPrefixes,
    );
  }

  String _activeContextLanguageKey(JsonLdContext context) {
    if (context.language != null && context.direction != null) {
      return '${context.language!.toLowerCase()}_${context.direction}';
    }
    if (context.language != null) {
      return context.language!.toLowerCase();
    }
    if (context.direction != null) {
      return '_${context.direction}';
    }
    return '@none';
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _isKeywordAlias(JsonLdContext context, String key) {
    return context.keywordAliases.containsKey(key);
  }

  /// Simplifies a compacted value object to a bare value if only @value remains.
  Object? _simplifyValueObject(Object? item, JsonLdContext context) {
    if (item is Map<String, Object?> && item.length == 1) {
      // Check if the single key is @value or an alias of @value.
      final key = item.keys.first;
      if (key == '@value') return item['@value'];
      // Check keyword aliases.
      if (context.keywordAliases[key] == '@value') return item[key];
    }
    return item;
  }

  TermDefinition? _lookupTermByCompactIri(
      JsonLdContext context, String compactIri) {
    final direct = context.terms[compactIri];
    if (direct != null) return direct;
    return null;
  }

  TermDefinition? _findTermByIri(JsonLdContext context, String iri) {
    for (final entry in context.terms.entries) {
      if (entry.value.iri == iri && !entry.value.isNullMapping) {
        return entry.value;
      }
    }
    return null;
  }

  bool _hasSetContainer(JsonLdContext context, String compactProp) {
    final def = _lookupTermByCompactIri(context, compactProp);
    return def?.containers.contains('@set') ?? false;
  }

  /// Gets the nest target map for a compacted property.
  /// If the term has @nest, returns (or creates) the sub-map for nesting.
  Map<String, Object?> _getNestTarget(
    Map<String, Object?> result,
    JsonLdContext context,
    _InverseContext inverseContext,
    String compactedProp,
  ) {
    final termDef = _lookupTermByCompactIri(context, compactedProp);
    if (termDef?.nestValue != null) {
      final nestKey = termDef!.nestValue!;
      // Validate that the nest key is @nest or a defined term.
      if (nestKey != '@nest') {
        final nestTermDef = context.terms[nestKey];
        if (nestTermDef == null) {
          throw RdfSyntaxException(
            'invalid @nest value',
            format: 'JSON-LD',
          );
        }
      }
      // Compact the nest key if it's @nest.
      final compactedNestKey = nestKey == '@nest'
          ? _compactIri(
              activeContext: context,
              inverseContext: inverseContext,
              iri: '@nest',
              vocab: true,
            )
          : nestKey;
      final existing = result[compactedNestKey];
      if (existing is Map<String, Object?>) {
        return existing;
      }
      final nestMap = <String, Object?>{};
      result[compactedNestKey] = nestMap;
      return nestMap;
    }
    return result;
  }

  /// Extracts a property-valued index from a compacted item.
  String? _extractPropertyIndex(Object? compactedItem, String indexProperty) {
    if (compactedItem is Map<String, Object?>) {
      final val = compactedItem[indexProperty];
      if (val is String) {
        compactedItem.remove(indexProperty);
        return val;
      }
      if (val is List && val.isNotEmpty) {
        final first = val.first;
        if (first is String) {
          if (val.length == 1) {
            compactedItem.remove(indexProperty);
          } else {
            final remaining = val.sublist(1);
            // Unwrap single remaining value.
            compactedItem[indexProperty] =
                remaining.length == 1 ? remaining[0] : remaining;
          }
          return first;
        }
      }
    }
    return null;
  }

  void _addValue(
    Map<String, Object?> map,
    String key,
    Object? value, {
    bool asArray = false,
  }) {
    final existing = map[key];
    if (existing == null) {
      if (asArray && value is! List) {
        map[key] = [value];
      } else {
        map[key] = value;
      }
    } else if (existing is List) {
      if (value is List) {
        existing.addAll(value);
      } else {
        existing.add(value);
      }
    } else {
      if (value is List) {
        map[key] = [existing, ...value];
      } else {
        map[key] = [existing, value];
      }
    }
  }

  void _addToContainerMap({
    required Map<String, Object?> result,
    required String compactedProp,
    required String mapKey,
    required Object? value,
    required JsonLdContext activeContext,
    required _InverseContext inverseContext,
    bool asArray = false,
  }) {
    String compactedMapKey;
    if (mapKey == '@none') {
      compactedMapKey = _compactIri(
        activeContext: activeContext,
        inverseContext: inverseContext,
        iri: '@none',
        vocab: true,
      );
    } else {
      compactedMapKey = mapKey;
    }

    final existing = result[compactedProp];
    if (existing is Map<String, Object?>) {
      _addValue(existing, compactedMapKey, value, asArray: asArray);
    } else {
      if (asArray) {
        result[compactedProp] = <String, Object?>{
          compactedMapKey: value is List ? value : [value],
        };
      } else {
        result[compactedProp] = <String, Object?>{
          compactedMapKey: value,
        };
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Inverse Context data structures
// ---------------------------------------------------------------------------

/// Returns `true` if [ch] is an RFC 3986 gen-delim character.
bool _isGenDelim(int ch) =>
    ch == 0x3A || // ':'
    ch == 0x2F || // '/'
    ch == 0x3F || // '?'
    ch == 0x23 || // '#'
    ch == 0x5B || // '['
    ch == 0x5D || // ']'
    ch == 0x40; // '@'

class _InverseContext {
  final Map<String, _InverseContextEntry> entries;

  /// Pre-built index from namespace IRI → term name for prefix-capable terms
  /// whose IRI ends with a gen-delim character. Used for O(1) lookups by
  /// scanning the target IRI for gen-delim split points.
  final Map<String, String> genDelimPrefixIndex;

  /// Prefix-capable terms whose IRI does NOT end with a gen-delim character
  /// (typically terms with explicit `@prefix: true`). These are rare and
  /// scanned linearly as a fallback.
  final List<(String term, String prefixIri)> nonGenDelimPrefixes;

  const _InverseContext({
    required this.entries,
    required this.genDelimPrefixIndex,
    required this.nonGenDelimPrefixes,
  });
}

class _InverseContextEntry {
  final Map<String, Map<String, Map<String, String>>> containers = {};
}
