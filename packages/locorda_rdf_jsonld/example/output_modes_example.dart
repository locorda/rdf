/// JSON-LD Output Modes Example
///
/// Demonstrates the three output modes supported by [JsonLdGraphEncoder]:
///
/// - **compact** (default): emits a `@context` with abbreviated IRIs —
///   readable, web-friendly. Properties appear in serialization order.
/// - **expanded**: all IRIs fully spelled out, no `@context`, values wrapped in
///   `{"@value": ...}` — canonical W3C fromRdf output, useful for tooling.
/// - **flattened**: same compacted IRIs but the W3C Node Map Generation
///   algorithm normalises the graph — properties within each node are sorted
///   alphabetically by key.
///
/// When converting from RDF, compact and flattened are structurally similar
/// because the W3C fromRdf serializer already produces flat node objects.
/// Embedding (inlining referenced nodes) requires JSON-LD Framing, which is
/// a separate W3C spec not covered here.
library;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';
import 'package:locorda_rdf_terms_common/foaf.dart';
import 'package:locorda_rdf_terms_core/rdf.dart';

void main() {
  print('JSON-LD Output Modes Example');
  print('============================\n');

  final ex = 'http://example.org/';

  final alice = IriTerm('${ex}alice');
  final bob = IriTerm('${ex}bob');

  // Properties inserted in order: name, nick, knows (non-alphabetical).
  // Compact preserves this order; flattened sorts → knows, name, nick.
  final graph = RdfGraph(triples: [
    Triple(alice, Rdf.type, Foaf.Person),
    Triple(alice, Foaf.name, LiteralTerm.string('Alice')),
    Triple(alice, Foaf.nick, LiteralTerm.string('ally')),
    Triple(alice, Foaf.knows, bob),
    Triple(bob, Rdf.type, Foaf.Person),
    Triple(bob, Foaf.name, LiteralTerm.string('Bob')),
  ]);

  // --- compact (default) ---
  final compact = jsonldGraph.encode(graph);
  print('=== Compact (default) ===');
  print(compact);

  // --- expanded ---
  final expanded = jsonldGraph.encode(
    graph,
    options: const JsonLdGraphEncoderOptions(
      outputMode: JsonLdOutputMode.expanded,
    ),
  );
  print('\n=== Expanded ===');
  print(expanded);

  // --- flattened ---
  final flattened = jsonldGraph.encode(
    graph,
    options: const JsonLdGraphEncoderOptions(
      outputMode: JsonLdOutputMode.flattened,
    ),
  );
  print('\n=== Flattened ===');
  print(flattened);

  // Highlight the key differences
  print('\n=== Key Differences ===');
  print('Expanded : full IRIs, @value wrappers, no @context');
  print('Compact  : short IRIs via @context, properties in serialization '
      'order (name → nick → knows)');
  print('Flattened: short IRIs via @context, properties sorted '
      'alphabetically (knows → name → nick)');
  print('');
  print('Both compact and flattened produce flat node objects when encoding');
  print('from RDF. Node embedding (inlining) requires JSON-LD Framing.');
}
