import 'package:locorda_rdf_core/core.dart';

/// Example demonstrating TriG format support for RDF datasets with named graphs.
///
/// TriG is an extension of Turtle that supports named graphs, allowing you to
/// organize triples into multiple graphs within a single document.
void main() {
  print('=== TriG Example: Named Graphs ===\n');

  // Create a dataset with default graph and named graphs
  final alice = const IriTerm('http://example.org/alice');
  final bob = const IriTerm('http://example.org/bob');
  final charlie = const IriTerm('http://example.org/charlie');
  final foafName = const IriTerm('http://xmlns.com/foaf/0.1/name');
  final foafKnows = const IriTerm('http://xmlns.com/foaf/0.1/knows');
  final foafAge = const IriTerm('http://xmlns.com/foaf/0.1/age');

  // Named graph IRIs
  final peopleGraph = const IriTerm('http://example.org/graphs/people');
  final relationshipsGraph =
      const IriTerm('http://example.org/graphs/relationships');

  final dataset = RdfDataset.fromQuads([
    // Default graph - general information
    Quad(alice, foafName, LiteralTerm.string('Alice')),
    Quad(bob, foafName, LiteralTerm.string('Bob')),

    // Named graph: people details
    Quad(alice, foafAge, LiteralTerm.integer(30), peopleGraph),
    Quad(bob, foafAge, LiteralTerm.integer(25), peopleGraph),
    Quad(charlie, foafName, LiteralTerm.string('Charlie'), peopleGraph),
    Quad(charlie, foafAge, LiteralTerm.integer(35), peopleGraph),

    // Named graph: relationships
    Quad(alice, foafKnows, bob, relationshipsGraph),
    Quad(alice, foafKnows, charlie, relationshipsGraph),
    Quad(bob, foafKnows, charlie, relationshipsGraph),
  ]);

  // Encode the dataset to TriG format
  print('Encoding dataset to TriG format...\n');
  final trigData = trig.encode(dataset);
  print(trigData);
  print('\n${'=' * 50}\n');

  // Decode the TriG data back to a dataset
  print('Decoding TriG data back to dataset...\n');
  final decodedDataset = trig.decode(trigData);

  // Access default graph
  print(
      'Default graph has ${decodedDataset.defaultGraph.triples.length} triples:');
  for (final triple in decodedDataset.defaultGraph.triples) {
    print('  ${triple.subject} ${triple.predicate} ${triple.object}');
  }

  // Access named graphs
  print('\nDataset has ${decodedDataset.namedGraphs.length} named graphs:');
  for (final namedGraph in decodedDataset.namedGraphs) {
    print('\nNamed graph: ${namedGraph.name}');
    print('  Contains ${namedGraph.graph.triples.length} triples:');
    for (final triple in namedGraph.graph.triples) {
      print('    ${triple.subject} ${triple.predicate} ${triple.object}');
    }
  }

  // You can also use RdfCore for more flexibility
  print('\n${'=' * 50}\n');
  print('Using RdfCore for encoding/decoding...\n');

  final rdf = RdfCore.withStandardCodecs();
  final trigViaRdfCore =
      rdf.encodeDataset(dataset, contentType: 'application/trig');
  print('Encoded via RdfCore:');
  print(trigViaRdfCore);

  final decodedViaRdfCore =
      rdf.decodeDataset(trigViaRdfCore, contentType: 'application/trig');
  print('\nDecoded dataset has:');
  print(
      '  - ${decodedViaRdfCore.defaultGraph.triples.length} triples in default graph');
  print('  - ${decodedViaRdfCore.namedGraphs.length} named graphs');
}
