/// JSON-LD Expanded Serializer (fromRdf / Serialize RDF as JSON-LD)
///
/// Implements the W3C "Serialize RDF as JSON-LD" algorithm, producing an
/// expanded JSON-LD document (no `@context`, all IRIs fully expanded) from
/// an [RdfDataset].
///
/// This is the canonical "fromRdf" direction described in the JSON-LD 1.1
/// Processing Algorithms specification
/// (https://www.w3.org/TR/json-ld11-api/#serialize-rdf-as-json-ld-algorithm).
///
/// The output is a `List<Map<String, Object?>>` suitable for direct JSON
/// serialisation or for further processing by compaction / framing algorithms.
library jsonld_expanded_serializer;

import 'dart:convert';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_utils.dart';

// ---------------------------------------------------------------------------
// Well-known IRI constants
// ---------------------------------------------------------------------------

const _rdfType = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';
const _rdfFirst = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#first';
const _rdfRest = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#rest';
const _rdfNil = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#nil';
const _rdfList = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#List';
const _rdfValue = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#value';
const _rdfLanguage = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#language';
const _rdfDirection = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#direction';

const _xsdString = 'http://www.w3.org/2001/XMLSchema#string';
const _xsdBoolean = 'http://www.w3.org/2001/XMLSchema#boolean';
const _xsdInteger = 'http://www.w3.org/2001/XMLSchema#integer';
const _xsdDouble = 'http://www.w3.org/2001/XMLSchema#double';

const _rdfLangString = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#langString';
const _i18nBase = 'https://www.w3.org/ns/i18n#';

// ---------------------------------------------------------------------------
// Public serializer class
// ---------------------------------------------------------------------------

/// Serializes an [RdfDataset] to expanded JSON-LD.
///
/// Expanded JSON-LD contains no `@context` and uses full IRIs everywhere.
/// The output format closely follows the W3C JSON-LD 1.1 "Serialize RDF as
/// JSON-LD" (fromRdf) algorithm.
///
/// ### Options
///
/// - [useNativeTypes] – when `true`, `xsd:boolean`, `xsd:integer` and
///   `xsd:double` literals are converted to native JSON booleans / numbers
///   instead of the `{"@value":"...","@type":"..."}` form.
/// - [useRdfType] – when `false` (default), `rdf:type` triples are rendered
///   as `@type` arrays.  When `true` they are treated as ordinary predicates.
/// - [rdfDirection] – controls how RDF text direction is represented:
///   - `null` (default): no special direction processing.
///   - `'i18n-datatype'`: detect `https://www.w3.org/ns/i18n#<lang>_<dir>`
///     datatypes and convert them to `{"@value":…,"@language":…,"@direction":…}`.
///   - `'compound-literal'`: detect blank nodes with `rdf:value`,
///     `rdf:language` and `rdf:direction` properties.
class JsonLdExpandedSerializer {
  final bool useNativeTypes;
  final bool useRdfType;
  final String? rdfDirection;

  const JsonLdExpandedSerializer({
    this.useNativeTypes = false,
    this.useRdfType = false,
    this.rdfDirection,
  });

  /// Serialize [dataset] to expanded JSON-LD.
  ///
  /// Returns a `List<Map<String, Object?>>` where each entry is an expanded
  /// JSON-LD node object.  Named-graph contents are wrapped in objects that
  /// carry both `@id` and `@graph`.
  List<Map<String, Object?>> serialize(RdfDataset dataset) {
    return _GraphSerializer(
      useNativeTypes: useNativeTypes,
      useRdfType: useRdfType,
      rdfDirection: rdfDirection,
    ).serialize(dataset);
  }
}

// ---------------------------------------------------------------------------
// Internal serializer state (one instance per call to serialize())
// ---------------------------------------------------------------------------

final class _GraphSerializer {
  final bool useNativeTypes;
  final bool useRdfType;
  final String? rdfDirection;

  /// Maps each blank node (by identity) to a stable label string, e.g. `_:b0`.
  final Map<BlankNodeTerm, String> _bnodeLabels = {};
  int _bnodeLabelCounter = 0;

  /// Blank nodes that are used as rdf:rest objects across multiple graphs,
  /// which prevents them from being inlined as @list.
  final Set<BlankNodeTerm> _crossGraphBnodes = {};

  _GraphSerializer({
    required this.useNativeTypes,
    required this.useRdfType,
    required this.rdfDirection,
  });

  // --------------------------------------------------------------------------
  // Entry point
  // --------------------------------------------------------------------------

  List<Map<String, Object?>> serialize(RdfDataset dataset) {
    // Assign stable labels for every blank node across the whole dataset first.
    _assignBnodeLabels(dataset.defaultGraph.triples);
    for (final ng in dataset.namedGraphs) {
      _assignBnodeLabels(ng.graph.triples);
    }

    // Detect blank nodes that appear as objects in multiple graphs.
    _detectCrossGraphBnodes(dataset);

    // Top-level node map: subject-id → node object for the default graph.
    final Map<String, Map<String, Object?>> defaultNodes = {};
    _serializeGraph(dataset.defaultGraph.triples, defaultNodes);

    // Process named graphs.
    for (final ng in dataset.namedGraphs) {
      final graphId = _subjectToId(ng.name);

      final graphNode = defaultNodes.putIfAbsent(
          graphId, () => <String, Object?>{'@id': graphId});

      final Map<String, Map<String, Object?>> namedGraphNodes = {};
      _serializeGraph(ng.graph.triples, namedGraphNodes);

      if (namedGraphNodes.isNotEmpty) {
        final graphContents = _nodesToSortedList(namedGraphNodes);
        graphNode['@graph'] = graphContents;
      }
    }

    return _nodesToSortedList(defaultNodes);
  }

  // --------------------------------------------------------------------------
  // Cross-graph blank node detection
  // --------------------------------------------------------------------------

  /// Identifies blank nodes that appear as objects in more than one graph,
  /// preventing them from being inlined as @list nodes.
  void _detectCrossGraphBnodes(RdfDataset dataset) {
    // Map: blank node → set of graph identifiers where it appears as an object.
    final Map<BlankNodeTerm, Set<int>> bnodeGraphs = {};

    void scanGraph(List<Triple> triples, int graphIndex) {
      for (final t in triples) {
        if (t.object is BlankNodeTerm) {
          final bn = t.object as BlankNodeTerm;
          bnodeGraphs.putIfAbsent(bn, () => {}).add(graphIndex);
        }
      }
    }

    scanGraph(dataset.defaultGraph.triples, 0);
    var idx = 1;
    for (final ng in dataset.namedGraphs) {
      scanGraph(ng.graph.triples, idx++);
    }

    for (final entry in bnodeGraphs.entries) {
      if (entry.value.length > 1) {
        _crossGraphBnodes.add(entry.key);
      }
    }
  }

  // --------------------------------------------------------------------------
  // Graph serialization
  // --------------------------------------------------------------------------

  void _serializeGraph(
    List<Triple> triples,
    Map<String, Map<String, Object?>> nodeMap,
  ) {
    // Deduplicate triples.
    final deduped = _deduplicateTriples(triples);

    // Find valid RDF list nodes.
    final Set<BlankNodeTerm> validListNodes = _findValidListNodes(deduped);

    // For compound-literal mode, identify compound literal blank nodes.
    final Set<BlankNodeTerm> compoundLiteralNodes =
        rdfDirection == 'compound-literal'
            ? _findCompoundLiteralNodes(deduped)
            : const {};

    // Build the node objects.
    for (final triple in deduped) {
      final subject = triple.subject;
      final predicate = triple.predicate as IriTerm;
      final object = triple.object;

      // Skip triples whose subject is a valid list node (embedded in @list).
      if (subject is BlankNodeTerm && validListNodes.contains(subject)) {
        continue;
      }

      // Skip compound-literal blank node triples.
      if (subject is BlankNodeTerm && compoundLiteralNodes.contains(subject)) {
        continue;
      }

      final subjectId = _subjectToId(subject);
      final node = nodeMap.putIfAbsent(
          subjectId, () => <String, Object?>{'@id': subjectId});

      final predicateIri = predicate.value;

      // Handle rdf:type → @type (unless useRdfType is on).
      if (!useRdfType && predicateIri == _rdfType && object is IriTerm) {
        final types = node.putIfAbsent('@type', () => <String>[]) as List;
        if (!types.contains(object.value)) {
          types.add(object.value);
        }
        continue;
      }

      // Normal predicate — value is always an array in expanded form.
      final valueArray =
          node.putIfAbsent(predicateIri, () => <Object?>[]) as List<Object?>;

      final objectValue = _convertObject(
        object,
        predicateIri: predicateIri,
        validListNodes: validListNodes,
        compoundLiteralNodes: compoundLiteralNodes,
        triples: deduped,
      );
      if (objectValue != null) {
        valueArray.add(objectValue);
      }
    }
  }

  // --------------------------------------------------------------------------
  // Triple deduplication
  // --------------------------------------------------------------------------

  /// Deduplicates triples by (subject identity, predicate IRI, object identity/value).
  List<Triple> _deduplicateTriples(List<Triple> triples) {
    final seen = <String>{};
    final result = <Triple>[];

    for (final t in triples) {
      final key = _tripleKey(t);
      if (seen.add(key)) {
        result.add(t);
      }
    }

    return result;
  }

  String _tripleKey(Triple t) {
    final s = _termKey(t.subject);
    final p = (t.predicate as IriTerm).value;
    final o = _termKey(t.object);
    return '$s\t$p\t$o';
  }

  String _termKey(RdfTerm term) {
    return switch (term) {
      IriTerm iri => '<${iri.value}>',
      BlankNodeTerm bn => _bnodeLabel(bn),
      LiteralTerm lit =>
        '"${lit.value}"^^<${lit.datatype.value}>${lit.language != null ? "@${lit.language}" : ""}',
    };
  }

  // --------------------------------------------------------------------------
  // RDF list detection
  // --------------------------------------------------------------------------

  Set<BlankNodeTerm> _findValidListNodes(List<Triple> triples) {
    final Map<BlankNodeTerm, int> objectRefCount = {};
    final Map<BlankNodeTerm, Map<String, int>> subjectPredicateCounts = {};
    final Map<BlankNodeTerm, RdfObject?> firstValues = {};
    final Map<BlankNodeTerm, RdfObject?> restValues = {};

    for (final triple in triples) {
      if (triple.object is BlankNodeTerm) {
        final bn = triple.object as BlankNodeTerm;
        objectRefCount[bn] = (objectRefCount[bn] ?? 0) + 1;
      }

      if (triple.subject is BlankNodeTerm) {
        final bn = triple.subject as BlankNodeTerm;
        final pred = (triple.predicate as IriTerm).value;
        final counts = subjectPredicateCounts.putIfAbsent(bn, () => {});
        counts[pred] = (counts[pred] ?? 0) + 1;

        if (pred == _rdfFirst) {
          if (firstValues.containsKey(bn)) {
            firstValues[bn] = null; // duplicate → invalid
          } else {
            firstValues[bn] = triple.object;
          }
        }
        if (pred == _rdfRest) {
          if (restValues.containsKey(bn)) {
            restValues[bn] = null; // duplicate → invalid
          } else {
            restValues[bn] = triple.object;
          }
        }
      }
    }

    // Candidates: blank nodes with predicates being exactly {rdf:first, rdf:rest}
    // or {rdf:first, rdf:rest, rdf:type} where rdf:type is rdf:List.
    // Each of rdf:first and rdf:rest must appear exactly once.
    final candidates = <BlankNodeTerm>{};

    for (final entry in subjectPredicateCounts.entries) {
      final bn = entry.key;
      final counts = entry.value;
      final preds = counts.keys.toSet();

      final hasFirst = preds.contains(_rdfFirst) && counts[_rdfFirst] == 1;
      final hasRest = preds.contains(_rdfRest) && counts[_rdfRest] == 1;
      if (!hasFirst || !hasRest) continue;

      // Allowed extra predicate: rdf:type rdf:List only.
      final extraPreds = preds.difference({_rdfFirst, _rdfRest});
      if (extraPreds.isEmpty) {
        candidates.add(bn);
      } else if (extraPreds.length == 1 && extraPreds.first == _rdfType) {
        // Verify that all rdf:type values are rdf:List.
        final typeTriples = triples.where((t) =>
            t.subject == bn && (t.predicate as IriTerm).value == _rdfType);
        final allList = typeTriples.every((t) =>
            t.object is IriTerm && (t.object as IriTerm).value == _rdfList);
        if (allList) candidates.add(bn);
      }
    }

    // Keep only candidates referenced exactly once as an object,
    // and not shared across graphs.
    final singleRef = candidates
        .where((bn) =>
            (objectRefCount[bn] ?? 0) == 1 && !_crossGraphBnodes.contains(bn))
        .toSet();

    // Verify chain termination at rdf:nil.
    final Set<BlankNodeTerm> valid = {};

    bool isValidChain(BlankNodeTerm node) {
      if (valid.contains(node)) return true;

      final seen = <BlankNodeTerm>{};
      BlankNodeTerm? current = node;
      while (current != null) {
        if (seen.contains(current)) return false;
        seen.add(current);

        if (!singleRef.contains(current)) return false;

        final rest = restValues[current];
        if (rest == null) return false;

        if (rest is IriTerm && rest.value == _rdfNil) {
          valid.addAll(seen);
          return true;
        }
        if (rest is BlankNodeTerm) {
          current = rest;
        } else {
          return false;
        }
      }
      return false;
    }

    for (final candidate in singleRef) {
      isValidChain(candidate);
    }

    return valid;
  }

  // --------------------------------------------------------------------------
  // Compound-literal blank node detection
  // --------------------------------------------------------------------------

  Set<BlankNodeTerm> _findCompoundLiteralNodes(List<Triple> triples) {
    final Map<BlankNodeTerm, Set<String>> subjectPredicates = {};

    for (final triple in triples) {
      if (triple.subject is BlankNodeTerm) {
        final bn = triple.subject as BlankNodeTerm;
        subjectPredicates
            .putIfAbsent(bn, () => {})
            .add((triple.predicate as IriTerm).value);
      }
    }

    return subjectPredicates.entries
        .where((e) {
          final preds = e.value;
          return preds.contains(_rdfValue) &&
              preds.every((p) =>
                  p == _rdfValue || p == _rdfLanguage || p == _rdfDirection);
        })
        .map((e) => e.key)
        .toSet();
  }

  // --------------------------------------------------------------------------
  // Object conversion
  // --------------------------------------------------------------------------

  Map<String, Object?>? _convertObject(
    RdfObject object, {
    required String predicateIri,
    required Set<BlankNodeTerm> validListNodes,
    required Set<BlankNodeTerm> compoundLiteralNodes,
    required List<Triple> triples,
  }) {
    switch (object) {
      case IriTerm iri:
        // rdf:nil as an object always produces an empty @list.
        // (When rdf:nil terminates a valid inlined list, that triple is
        // never reached here because _collectList handles it.)
        if (iri.value == _rdfNil) {
          return {'@list': <Object?>[]};
        }
        return {'@id': iri.value};

      case BlankNodeTerm bn:
        if (validListNodes.contains(bn)) {
          final items = _collectList(
            bn,
            validListNodes: validListNodes,
            compoundLiteralNodes: compoundLiteralNodes,
            triples: triples,
          );
          return {'@list': items};
        }
        if (compoundLiteralNodes.contains(bn)) {
          return _buildCompoundLiteralValue(bn, triples);
        }
        return {'@id': _bnodeLabel(bn)};

      case LiteralTerm literal:
        return _convertLiteral(literal);
    }
  }

  // --------------------------------------------------------------------------
  // RDF list inlining
  // --------------------------------------------------------------------------

  List<Object?> _collectList(
    BlankNodeTerm head, {
    required Set<BlankNodeTerm> validListNodes,
    required Set<BlankNodeTerm> compoundLiteralNodes,
    required List<Triple> triples,
  }) {
    final items = <Object?>[];
    BlankNodeTerm? current = head;

    while (current != null) {
      RdfObject? firstObj;
      RdfObject? restObj;
      for (final t in triples) {
        if (t.subject != current) continue;
        final pred = (t.predicate as IriTerm).value;
        if (pred == _rdfFirst) firstObj = t.object;
        if (pred == _rdfRest) restObj = t.object;
      }

      if (firstObj != null) {
        // rdf:nil as the first value of a list node → empty nested @list.
        if (firstObj is IriTerm && firstObj.value == _rdfNil) {
          items.add({'@list': <Object?>[]});
        } else {
          final item = _convertObject(
            firstObj,
            predicateIri: _rdfFirst,
            validListNodes: validListNodes,
            compoundLiteralNodes: compoundLiteralNodes,
            triples: triples,
          );
          if (item != null) items.add(item);
        }
      }

      if (restObj is IriTerm && restObj.value == _rdfNil) {
        break;
      } else if (restObj is BlankNodeTerm) {
        current = restObj;
      } else {
        break;
      }
    }

    return items;
  }

  // --------------------------------------------------------------------------
  // Literal conversion
  // --------------------------------------------------------------------------

  Map<String, Object?> _convertLiteral(LiteralTerm literal) {
    final lexical = literal.value;
    final datatypeIri = literal.datatype.value;
    final language = literal.language;

    // Language-tagged strings (rdf:langString).
    if (language != null && datatypeIri == _rdfLangString) {
      return {'@value': lexical, '@language': language};
    }

    // i18n-datatype direction handling.
    if (rdfDirection == 'i18n-datatype' && datatypeIri.startsWith(_i18nBase)) {
      final suffix = datatypeIri.substring(_i18nBase.length);
      final underscoreIdx = suffix.indexOf('_');
      if (underscoreIdx >= 0) {
        final lang = suffix.substring(0, underscoreIdx);
        final dir = suffix.substring(underscoreIdx + 1);
        final Map<String, Object?> result = {'@value': lexical};
        if (lang.isNotEmpty) result['@language'] = lang;
        if (dir.isNotEmpty) result['@direction'] = dir;
        return result;
      }
    }

    // rdf:JSON typed literals.
    if (datatypeIri == rdfJsonDatatype) {
      final parsed = jsonDecode(lexical);
      return {'@value': parsed, '@type': '@json'};
    }

    // xsd:string — no @type needed.
    if (datatypeIri == _xsdString) {
      return {'@value': lexical};
    }

    // useNativeTypes: convert xsd:boolean, xsd:integer, xsd:double to native.
    if (useNativeTypes) {
      if (datatypeIri == _xsdBoolean) {
        if (lexical == 'true' || lexical == '1') return {'@value': true};
        if (lexical == 'false' || lexical == '0') return {'@value': false};
      }
      if (datatypeIri == _xsdInteger) {
        final parsed = int.tryParse(lexical);
        if (parsed != null) return {'@value': parsed};
      }
      if (datatypeIri == _xsdDouble) {
        final parsed = double.tryParse(lexical);
        if (parsed != null && parsed.isFinite) return {'@value': parsed};
      }
    }

    // All other typed literals.
    return {'@value': lexical, '@type': datatypeIri};
  }

  // --------------------------------------------------------------------------
  // Compound literal (rdfDirection == 'compound-literal')
  // --------------------------------------------------------------------------

  Map<String, Object?>? _buildCompoundLiteralValue(
    BlankNodeTerm bn,
    List<Triple> triples,
  ) {
    String? value;
    String? language;
    String? direction;

    for (final t in triples) {
      if (t.subject != bn) continue;
      final pred = (t.predicate as IriTerm).value;
      switch (pred) {
        case _rdfValue:
          if (t.object is LiteralTerm) {
            value = (t.object as LiteralTerm).value;
          }
        case _rdfLanguage:
          if (t.object is LiteralTerm) {
            language = (t.object as LiteralTerm).value;
          }
        case _rdfDirection:
          if (t.object is LiteralTerm) {
            direction = (t.object as LiteralTerm).value;
          }
      }
    }

    if (value == null) return {'@id': _bnodeLabel(bn)};

    final Map<String, Object?> result = {'@value': value};
    if (language != null) result['@language'] = language;
    if (direction != null) result['@direction'] = direction;
    return result;
  }

  // --------------------------------------------------------------------------
  // Blank-node label management
  // --------------------------------------------------------------------------

  String _bnodeLabel(BlankNodeTerm bn) {
    return _bnodeLabels.putIfAbsent(bn, () {
      final label = '_:b${_bnodeLabelCounter}';
      _bnodeLabelCounter++;
      return label;
    });
  }

  void _assignBnodeLabels(List<Triple> triples) {
    for (final triple in triples) {
      if (triple.subject is BlankNodeTerm) {
        _bnodeLabel(triple.subject as BlankNodeTerm);
      }
      if (triple.object is BlankNodeTerm) {
        _bnodeLabel(triple.object as BlankNodeTerm);
      }
    }
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  String _subjectToId(RdfSubject subject) {
    return switch (subject) {
      IriTerm iri => iri.value,
      BlankNodeTerm bn => _bnodeLabel(bn),
    };
  }

  List<Map<String, Object?>> _nodesToSortedList(
    Map<String, Map<String, Object?>> nodeMap,
  ) {
    final entries = nodeMap.entries.toList()
      ..sort((a, b) {
        final aId = a.key;
        final bId = b.key;
        final aIsBlank = aId.startsWith('_:');
        final bIsBlank = bId.startsWith('_:');
        if (aIsBlank != bIsBlank) return aIsBlank ? 1 : -1;
        return aId.compareTo(bId);
      });
    return entries.map((e) => e.value).toList();
  }
}
