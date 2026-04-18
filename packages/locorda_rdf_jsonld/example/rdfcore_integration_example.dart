/// JSON-LD — RdfCore Integration Example
///
/// Demonstrates how to register [JsonLdGraphCodec] and [JsonLdCodec] with
/// [RdfCore] to enable JSON-LD via the codec-agnostic facade.
///
/// Once registered, [RdfCore.encode] / [RdfCore.decode] dispatch by MIME type
/// (`application/ld+json`), alongside the standard text codecs (Turtle,
/// N-Triples, TriG, N-Quads).
library;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';

const _jsonLdMimeType = 'application/ld+json';

void main() {
  print('JSON-LD — RdfCore Integration Example');
  print('=====================================\n');

  // Register JSON-LD alongside the standard text-based codecs.
  // JsonLdGraphCodec handles RdfGraph (graph codec), JsonLdCodec handles
  // RdfDataset (dataset codec — supports named graphs via @graph).
  final rdfCore = RdfCore.withStandardCodecs(
    additionalCodecs: [JsonLdGraphCodec()],
    additionalDatasetCodecs: [JsonLdCodec()],
  );

  final ex = 'http://example.org/';
  final foaf = 'http://xmlns.com/foaf/0.1/';

  final graph = RdfGraph(triples: [
    Triple(
      IriTerm('${ex}alice'),
      IriTerm('${foaf}name'),
      LiteralTerm.string('Alice'),
    ),
    Triple(
      IriTerm('${ex}alice'),
      IriTerm('${foaf}knows'),
      IriTerm('${ex}bob'),
    ),
    Triple(
      IriTerm('${ex}bob'),
      IriTerm('${foaf}name'),
      LiteralTerm.string('Bob'),
    ),
  ]);

  // --- Encode via content type ---
  final jsonLdString = rdfCore.encode(graph, contentType: _jsonLdMimeType);
  print('=== Encoded as JSON-LD (content type: $_jsonLdMimeType) ===');
  print(jsonLdString);

  // --- Decode via content type ---
  final decoded = rdfCore.decode(jsonLdString, contentType: _jsonLdMimeType);
  print('Decoded ${decoded.triples.length} triples via RdfCore\n');

  // --- Compare with Turtle ---
  final turtle = rdfCore.encode(graph, contentType: 'text/turtle');
  print('=== Same graph as Turtle ===');
  print(turtle);

  // --- Dataset roundtrip (named graph) ---
  final namedGraphName = IriTerm('${ex}people');
  final dataset = RdfDataset(
    defaultGraph: RdfGraph(),
    namedGraphs: {namedGraphName: graph},
  );

  final datasetJsonLd =
      rdfCore.encodeDataset(dataset, contentType: _jsonLdMimeType);
  print('=== Dataset encoded as JSON-LD ===');
  print(datasetJsonLd);

  final decodedDataset =
      rdfCore.decodeDataset(datasetJsonLd, contentType: _jsonLdMimeType);
  final peopleGraph = decodedDataset.graph(namedGraphName);
  print('Named graph "${namedGraphName.value}" '
      'contains ${peopleGraph?.triples.length ?? 0} triples');
}
