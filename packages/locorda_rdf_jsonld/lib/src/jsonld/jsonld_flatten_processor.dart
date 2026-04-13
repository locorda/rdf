/// JSON-LD 1.1 Flattening Algorithm.
///
/// Implements the W3C JSON-LD 1.1 Flattening Algorithm (section 7.1 of the
/// JSON-LD 1.1 Processing Algorithms and API specification).
///
/// The flattening processor takes a JSON-LD document, expands it, collects
/// all nodes into a flat list, and optionally compacts the result with a
/// provided context.
///
/// See: https://www.w3.org/TR/json-ld11-api/#flattening-algorithm
library jsonld_flatten_processor;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_codec.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_utils.dart';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Implements the W3C JSON-LD 1.1 Flattening Algorithm.
///
/// Takes a JSON-LD document (or already-expanded JSON-LD), flattens it by
/// collecting all node definitions into a single flat array, and optionally
/// compacts the result with a provided context.
class JsonLdFlattenProcessor {
  final String processingMode;
  final JsonLdContextDocumentProvider? contextDocumentProvider;
  final JsonLdContextDocumentCache? contextDocumentCache;
  final Map<String, Object?> preloadedParsedContextDocuments;
  final String? documentBaseUri;

  const JsonLdFlattenProcessor({
    this.processingMode = 'json-ld-1.1',
    this.contextDocumentProvider,
    this.contextDocumentCache,
    this.preloadedParsedContextDocuments = const {},
    this.documentBaseUri,
  });

  /// Flattens a JSON-LD document.
  ///
  /// The input is first expanded, then flattened. If [context] is provided,
  /// the result is compacted with that context.
  ///
  /// Returns a flat list of node objects (when no context is provided) or
  /// a compacted document with `@graph` (when context is provided).
  Object flatten(
    Object? input, {
    Object? context,
    String? documentUrl,
    bool ordered = true,
    bool compactArrays = true,
  }) {
    final effectiveBase = documentUrl ?? documentBaseUri;

    // Step 1: Expand the input.
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
      ordered: ordered,
    );

    return flattenExpanded(
      expanded,
      context: context,
      documentUrl: effectiveBase,
      ordered: ordered,
      compactArrays: compactArrays,
    );
  }

  /// Flattens already-expanded JSON-LD.
  Object flattenExpanded(
    Object? input, {
    Object? context,
    String? documentUrl,
    bool ordered = true,
    bool compactArrays = true,
  }) {
    // Run the flattening algorithm on expanded input.
    final flattened = _flatten(input, ordered: ordered);

    // If context is provided, compact the result.
    if (context != null) {
      final compactionProcessor = JsonLdCompactionProcessor(
        processingMode: processingMode,
        contextDocumentProvider: contextDocumentProvider,
        contextDocumentCache: contextDocumentCache,
        preloadedParsedContextDocuments: preloadedParsedContextDocuments,
        documentBaseUri: documentUrl ?? documentBaseUri,
      );
      return compactionProcessor.compactExpanded(
        flattened,
        context: context,
        documentUrl: documentUrl ?? documentBaseUri,
        compactArrays: compactArrays,
        ordered: ordered,
      );
    }

    return flattened;
  }

  // ---------------------------------------------------------------------------
  // Flattening Algorithm (§ 7.1)
  // ---------------------------------------------------------------------------

  /// Core flattening algorithm.
  ///
  /// 1. Build a node map via the Node Map Generation algorithm.
  /// 2. Merge named graphs into the default graph.
  /// 3. Collect all substantive nodes into a flat array.
  List<Map<String, Object?>> _flatten(Object? element,
      {required bool ordered}) {
    // Step 1: Initialize node map with @default entry.
    final nodeMap = <String, Map<String, Map<String, Object?>>>{
      '@default': {},
    };
    final blankNodeState = _BlankNodeState();

    // Step 2: Generate the node map.
    _generateNodeMap(
      element: element,
      nodeMap: nodeMap,
      activeGraph: '@default',
      blankNodeState: blankNodeState,
    );

    // Step 3: Initialize default graph.
    final defaultGraph = nodeMap['@default']!;

    // Step 4: For each named graph, merge into default graph.
    final graphNames = nodeMap.keys.where((k) => k != '@default').toList();
    if (ordered) graphNames.sort();

    for (final graphName in graphNames) {
      final graph = nodeMap[graphName]!;

      // If default graph doesn't have this graph name, create an entry.
      if (!defaultGraph.containsKey(graphName)) {
        defaultGraph[graphName] = <String, Object?>{'@id': graphName};
      }

      final entry = defaultGraph[graphName]!;
      // Add @graph entry.
      final graphArray = <Map<String, Object?>>[];
      entry['@graph'] = graphArray;

      // Add all substantive nodes.
      final ids = graph.keys.toList();
      if (ordered) ids.sort();

      for (final id in ids) {
        final node = graph[id]!;
        // Skip nodes with only @id.
        if (node.length == 1 && node.containsKey('@id')) continue;
        graphArray.add(node);
      }
    }

    // Steps 5-6: Collect all substantive nodes from the default graph.
    final flattened = <Map<String, Object?>>[];
    final ids = defaultGraph.keys.toList();
    if (ordered) ids.sort();

    for (final id in ids) {
      final node = defaultGraph[id]!;
      // Skip nodes with only @id.
      if (node.length == 1 && node.containsKey('@id')) continue;
      flattened.add(node);
    }

    return flattened;
  }

  // ---------------------------------------------------------------------------
  // Node Map Generation Algorithm (§ 7.2)
  // ---------------------------------------------------------------------------

  void _generateNodeMap({
    required Object? element,
    required Map<String, Map<String, Map<String, Object?>>> nodeMap,
    required String activeGraph,
    Object? activeSubject,
    String? activeProperty,
    Map<String, Object?>? list,
    required _BlankNodeState blankNodeState,
  }) {
    // Step 1: If element is an array, process each item.
    if (element is List) {
      for (final item in element) {
        _generateNodeMap(
          element: item,
          nodeMap: nodeMap,
          activeGraph: activeGraph,
          activeSubject: activeSubject,
          activeProperty: activeProperty,
          list: list,
          blankNodeState: blankNodeState,
        );
      }
      return;
    }

    // Step 2: Element must be a map.
    if (element is! Map<String, Object?>) return;

    final elem = Map<String, Object?>.from(element);

    // Ensure graph entry exists.
    nodeMap.putIfAbsent(activeGraph, () => <String, Map<String, Object?>>{});
    final graph = nodeMap[activeGraph]!;

    Map<String, Object?>? subjectNode;
    if (activeSubject is String) {
      subjectNode = graph[activeSubject];
    }

    // Step 3: Replace blank node identifiers in @type.
    if (elem.containsKey('@type')) {
      final typeVal = elem['@type'];
      if (typeVal is List) {
        final newTypes = <Object?>[];
        for (final item in typeVal) {
          if (item is String && item.startsWith('_:')) {
            newTypes.add(blankNodeState.generate(item));
          } else {
            newTypes.add(item);
          }
        }
        elem['@type'] = newTypes;
      } else if (typeVal is String && typeVal.startsWith('_:')) {
        elem['@type'] = [blankNodeState.generate(typeVal)];
      }
    }

    // Step 4: Value object.
    if (elem.containsKey('@value')) {
      if (list != null) {
        (list['@list'] as List).add(elem);
      } else if (activeSubject != null &&
          activeProperty != null &&
          subjectNode != null) {
        _addValue(subjectNode, activeProperty, elem);
      }
      return;
    }

    // Step 5: List object.
    if (elem.containsKey('@list')) {
      final result = <String, Object?>{'@list': <Object?>[]};
      _generateNodeMap(
        element: elem['@list'],
        nodeMap: nodeMap,
        activeGraph: activeGraph,
        activeSubject: activeSubject,
        activeProperty: activeProperty,
        list: result,
        blankNodeState: blankNodeState,
      );
      if (list != null) {
        (list['@list'] as List).add(result);
      } else if (subjectNode != null && activeProperty != null) {
        subjectNode.putIfAbsent(activeProperty, () => <Object?>[]);
        (subjectNode[activeProperty] as List).add(result);
      }
      return;
    }

    // Step 6: Node object.
    String id;
    if (elem.containsKey('@id')) {
      id = elem.remove('@id') as String;
      if (id.startsWith('_:')) {
        id = blankNodeState.generate(id);
      }
    } else {
      id = blankNodeState.generate(null);
    }

    // Ensure node exists in graph.
    if (!graph.containsKey(id)) {
      graph[id] = <String, Object?>{'@id': id};
    }
    final node = graph[id]!;

    // If activeSubject is a map, we're processing a reverse property.
    if (activeSubject is Map<String, Object?>) {
      // Add a reference to the active subject under activeProperty.
      if (activeProperty != null) {
        _addValue(node, activeProperty, activeSubject);
      }
    } else if (activeProperty != null) {
      // Create a node reference.
      final reference = <String, Object?>{'@id': id};
      if (list != null) {
        (list['@list'] as List).add(reference);
      } else if (subjectNode != null) {
        _addValue(subjectNode, activeProperty, reference);
      }
    }

    // Merge @type entries.
    if (elem.containsKey('@type')) {
      final types = elem.remove('@type');
      final typeList = types is List ? types : [types];
      for (final type in typeList) {
        _addValue(node, '@type', type);
      }
    }

    // Handle @index.
    if (elem.containsKey('@index')) {
      final index = elem.remove('@index');
      if (node.containsKey('@index')) {
        if (node['@index'] != index) {
          throw RdfSyntaxException(
            'conflicting indexes',
            format: 'JSON-LD',
          );
        }
      } else {
        node['@index'] = index;
      }
    }

    // Handle @reverse.
    if (elem.containsKey('@reverse')) {
      final referencedNode = <String, Object?>{'@id': id};
      final reverseMap = elem.remove('@reverse') as Map<String, Object?>;

      for (final entry in reverseMap.entries) {
        final property = entry.key;
        final values = entry.value;
        final valueList = values is List ? values : [values];
        for (final value in valueList) {
          _generateNodeMap(
            element: value,
            nodeMap: nodeMap,
            activeGraph: activeGraph,
            activeSubject: referencedNode,
            activeProperty: property,
            blankNodeState: blankNodeState,
          );
        }
      }
    }

    // Handle @graph.
    if (elem.containsKey('@graph')) {
      final graphValue = elem.remove('@graph');
      _generateNodeMap(
        element: graphValue,
        nodeMap: nodeMap,
        activeGraph: id,
        blankNodeState: blankNodeState,
      );
    }

    // Handle @included.
    if (elem.containsKey('@included')) {
      final includedValue = elem.remove('@included');
      _generateNodeMap(
        element: includedValue,
        nodeMap: nodeMap,
        activeGraph: activeGraph,
        blankNodeState: blankNodeState,
      );
    }

    // Process remaining properties.
    final properties = elem.keys.toList()..sort();
    for (final property in properties) {
      final value = elem[property];
      // Skip keywords already handled.
      if (property.startsWith('@')) continue;

      var effectiveProperty = property;
      if (effectiveProperty.startsWith('_:')) {
        effectiveProperty = blankNodeState.generate(effectiveProperty);
      }

      node.putIfAbsent(effectiveProperty, () => <Object?>[]);
      _generateNodeMap(
        element: value,
        nodeMap: nodeMap,
        activeGraph: activeGraph,
        activeSubject: id,
        activeProperty: effectiveProperty,
        blankNodeState: blankNodeState,
      );
    }
  }

  /// Adds [value] to the array at [node][property], creating the array if
  /// needed. Deduplicates by deep equality.
  void _addValue(Map<String, Object?> node, String property, Object? value) {
    node.putIfAbsent(property, () => <Object?>[]);
    final arr = node[property] as List;

    // Deduplicate: check if value already exists.
    for (final existing in arr) {
      if (jsonValueDeepEquals(existing, value)) return;
    }
    arr.add(value);
  }
}

// ---------------------------------------------------------------------------
// Blank Node Identifier Generation (§ 7.4)
// ---------------------------------------------------------------------------

class _BlankNodeState {
  final Map<String, String> _identifierMap = {};
  int _counter = 0;

  /// Generates a blank node identifier.
  ///
  /// If [identifier] is not null and has been seen before, returns the
  /// previously mapped identifier. Otherwise generates a new one.
  String generate(String? identifier) {
    if (identifier != null && _identifierMap.containsKey(identifier)) {
      return _identifierMap[identifier]!;
    }
    final newId = '_:b${_counter++}';
    if (identifier != null) {
      _identifierMap[identifier] = newId;
    }
    return newId;
  }
}
