import 'package:rdf_canonicalization/rdf_canonicalization.dart';
import 'package:rdf_core/rdf_core.dart';

void main() {
  print('=== RDF Canonicalization Examples ===\n');

  // Example 1: The core problem - different N-Quads, same meaning
  demonstrateNQuadsProblem();

  print('\n${'=' * 50}\n');

  // Example 2: Different triple ordering
  demonstrateOrderingProblem();

  print('\n${'=' * 50}\n');

  // Example 3: Dataset canonicalization
  datasetCanonicalization();

  print('\n${'=' * 50}\n');

  // Example 4: Custom options
  customOptions();

  print('\n${'=' * 50}\n');

  // Example 5: Performance with canonical classes
  performanceExample();
}

void demonstrateNQuadsProblem() {
  print('1. The Core Problem: Different N-Quads, Same Meaning');
  print('====================================================');

  // Two N-Quads documents with identical semantic content but different blank node labels
  // This simulates what happens when the same RDF data comes from different sources
  final nquadsDoc1 = '''
_:alice <http://xmlns.com/foaf/0.1/name> "Alice" .
_:alice <http://xmlns.com/foaf/0.1/knows> _:bob .
_:bob <http://xmlns.com/foaf/0.1/name> "Bob" .
''';

  final nquadsDoc2 = '''
_:person1 <http://xmlns.com/foaf/0.1/name> "Alice" .
_:person1 <http://xmlns.com/foaf/0.1/knows> _:person2 .
_:person2 <http://xmlns.com/foaf/0.1/name> "Bob" .
''';

  print('Document 1:\n$nquadsDoc1');
  print('Document 2:\n$nquadsDoc2');

  // Parse both documents
  final dataset1 = nquads.decode(nquadsDoc1);
  final dataset2 = nquads.decode(nquadsDoc2);

  // Show the problem: identical meaning, different representations
  print(
      'Documents are string-identical: ${nquadsDoc1.trim() == nquadsDoc2.trim()}'); // false
  print('Parsed datasets are equal: ${dataset1 == dataset2}'); // false

  // But they represent the same information!
  print(
      'But datasets are isomorphic: ${isIsomorphic(dataset1, dataset2)}'); // true

  // Canonicalization solves this
  final canonical1 = canonicalize(dataset1);
  final canonical2 = canonicalize(dataset2);

  print('\nCanonical form (both produce identical result):');
  print(canonical1.trim());
  print('\nCanonical forms are identical: ${canonical1 == canonical2}'); // true
}

void demonstrateOrderingProblem() {
  print('2. Triple Ordering Creates Different Serializations');
  print('===================================================');

  // Same triples, different order
  final dataset1 = RdfDataset.fromQuads([
    Quad(BlankNodeTerm(), const IriTerm('http://example.org/name'),
        LiteralTerm.string('Alice')),
    Quad(BlankNodeTerm(), const IriTerm('http://example.org/age'),
        LiteralTerm.integer(30)),
  ]);

  final dataset2 = RdfDataset.fromQuads([
    Quad(BlankNodeTerm(), const IriTerm('http://example.org/age'),
        LiteralTerm.integer(30)),
    Quad(BlankNodeTerm(), const IriTerm('http://example.org/name'),
        LiteralTerm.string('Alice')),
  ]);

  // Normal encoding preserves input order, creating different outputs
  final encoder = NQuadsEncoder();
  final encoded1 = encoder.encode(dataset1);
  final encoded2 = encoder.encode(dataset2);

  print('Encoded dataset 1:\n${encoded1.trim()}\n');
  print('Encoded dataset 2:\n${encoded2.trim()}\n');
  print('Encoded forms are identical: ${encoded1 == encoded2}'); // likely false

  // But RDF canonicalization produces identical results
  final canonical1 = canonicalize(dataset1);
  final canonical2 = canonicalize(dataset2);

  print('Datasets are isomorphic: ${isIsomorphic(dataset1, dataset2)}'); // true
  print('Canonical forms are identical: ${canonical1 == canonical2}'); // true
  print('\nCanonical form dataset 1:\n${canonical1.trim()}');
  print('\nCanonical form dataset 2:\n${canonical2.trim()}');
}

void datasetCanonicalization() {
  print('3. Dataset Canonicalization');
  print('===========================');

  // Create dataset with named graphs and blank nodes
  final person = BlankNodeTerm();
  final org = BlankNodeTerm();
  final orgGraph = const IriTerm('http://example.org/graphs/organizations');

  final dataset = RdfDataset.fromQuads([
    // Default graph
    Quad(person, const IriTerm('http://xmlns.com/foaf/0.1/name'),
        LiteralTerm.string('Alice')),
    Quad(person, const IriTerm('http://xmlns.com/foaf/0.1/worksFor'), org),

    // Named graph
    Quad(org, const IriTerm('http://xmlns.com/foaf/0.1/name'),
        LiteralTerm.string('ACME Corp'), orgGraph),
    Quad(org, const IriTerm('http://example.org/type'),
        LiteralTerm.string('Corporation'), orgGraph),
  ]);

  print(
      'Dataset has ${dataset.defaultGraph.triples.length} triples in default graph');
  print('Dataset has ${dataset.namedGraphs.length} named graphs');

  // Canonicalize the entire dataset
  final canonical = canonicalize(dataset);
  print('\nCanonical dataset representation:');
  print(canonical.trim());
}

void customOptions() {
  print('4. Custom Canonicalization Options');
  print('==================================');

  final graph = RdfGraph(triples: [
    Triple(BlankNodeTerm(), const IriTerm('http://example.org/property'),
        LiteralTerm.string('value1')),
    Triple(BlankNodeTerm(), const IriTerm('http://example.org/property'),
        LiteralTerm.string('value2')),
  ]);

  // Default SHA-256
  final defaultCanonical = canonicalizeGraph(graph);
  print('With default SHA-256:');
  print(defaultCanonical.trim());

  // Use SHA-384 with custom prefix
  final options = const CanonicalizationOptions(
      hashAlgorithm: CanonicalHashAlgorithm.sha384, blankNodePrefix: 'custom');

  final customCanonical = canonicalizeGraph(graph, options: options);
  print('\nWith SHA-384 and custom prefix:');
  print(customCanonical.trim());
}

void performanceExample() {
  print('5. Performance with Canonical Classes');
  print('=====================================');

  // Create multiple similar graphs
  final graphs = <RdfGraph>[];
  for (int i = 0; i < 5; i++) {
    final graph = RdfGraph(triples: [
      Triple(BlankNodeTerm(), const IriTerm('http://example.org/id'),
          LiteralTerm.string('$i')),
      Triple(BlankNodeTerm(), const IriTerm('http://example.org/type'),
          LiteralTerm.string('TestNode')),
    ]);
    graphs.add(graph);
  }

  print('Created ${graphs.length} graphs for comparison');

  // Convert to canonical forms for efficient comparison
  final canonicalGraphs = graphs.map((g) => CanonicalRdfGraph(g)).toList();

  print('Converted to canonical forms for O(1) equality comparison');

  // Now comparisons are fast string comparisons
  var isomorphicPairs = 0;
  for (int i = 0; i < canonicalGraphs.length; i++) {
    for (int j = i + 1; j < canonicalGraphs.length; j++) {
      if (canonicalGraphs[i] == canonicalGraphs[j]) {
        isomorphicPairs++;
        print('Graphs $i and $j are isomorphic');
      }
    }
  }

  if (isomorphicPairs == 0) {
    print(
        'No isomorphic pairs found (as expected - each graph has different content)');
  }

  // Show canonical form of first graph
  print('\nCanonical form of first graph:');
  print(canonicalGraphs[0].canonicalNQuads.trim());
}
