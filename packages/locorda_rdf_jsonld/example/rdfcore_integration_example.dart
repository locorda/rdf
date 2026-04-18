/// JSON-LD — RdfCore Integration Example
///
/// Demonstrates how to register [JsonLdGraphCodec] and [JsonLdCodec] with
/// [RdfCore] to enable JSON-LD via the codec-agnostic facade, and highlights
/// the structural difference between single-graph and dataset encoding.
///
/// **Single graph** ([JsonLdGraphCodec]): flat `@context` + `@graph` array of
/// node objects.
///
/// **Dataset** ([JsonLdCodec]): `@graph` array of *named-graph objects*, each
/// carrying its own nested `@graph`. Default-graph statements about a named
/// graph's IRI are merged into that graph's outer object — this is the
/// idiomatic JSON-LD way to annotate named graphs with provenance metadata.
library;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';
import 'package:locorda_rdf_terms_common/dcterms.dart';
import 'package:locorda_rdf_terms_common/foaf.dart';

const _jsonLdMimeType = 'application/ld+json';

void main() {
  print('JSON-LD — RdfCore Integration Example');
  print('=====================================\n');

  // Register JSON-LD alongside the standard text-based codecs.
  // jsonldGraph → RdfGraph (additionalCodecs)
  // jsonld      → RdfDataset with named graphs (additionalDatasetCodecs)
  final rdfCore = RdfCore.withStandardCodecs(
    additionalCodecs: [jsonldGraph],
    additionalDatasetCodecs: [jsonld],
  );

  const ex = 'http://example.org/';

  // -------------------------------------------------------------------------
  // Part 1: single RdfGraph → flat JSON-LD
  // -------------------------------------------------------------------------
  final peopleGraph = RdfGraph(triples: [
    Triple(IriTerm('${ex}alice'), Foaf.name, LiteralTerm.string('Alice')),
    Triple(IriTerm('${ex}alice'), Foaf.knows, IriTerm('${ex}bob')),
    Triple(IriTerm('${ex}bob'), Foaf.name, LiteralTerm.string('Bob')),
  ]);

  final graphJsonLd = rdfCore.encode(peopleGraph, contentType: _jsonLdMimeType);
  print('=== 1. Single RdfGraph → flat JSON-LD ===');
  print(graphJsonLd);

  final decodedGraph =
      rdfCore.decode(graphJsonLd, contentType: _jsonLdMimeType);
  print('Decoded ${decodedGraph.triples.length} triples\n');

  // -------------------------------------------------------------------------
  // Part 2: RdfDataset with multiple named graphs + default graph → nested
  // -------------------------------------------------------------------------
  // Two named graphs: people and places.
  final placesGraph = RdfGraph(triples: [
    Triple(IriTerm('${ex}berlin'), Foaf.name, LiteralTerm.string('Berlin')),
    Triple(IriTerm('${ex}alice'), IriTerm('${ex}livesIn'), IriTerm('${ex}berlin')),
  ]);

  // Default graph holds provenance metadata about the named graphs.
  // In JSON-LD output these statements are merged into each named graph's
  // outer object, co-locating the graph IRI, its metadata, and its triples.
  final defaultGraph = RdfGraph(triples: [
    Triple(IriTerm('${ex}people'), Dcterms.title, LiteralTerm.string('People Graph')),
    Triple(IriTerm('${ex}places'), Dcterms.title, LiteralTerm.string('Places Graph')),
  ]);

  final dataset = RdfDataset(
    defaultGraph: defaultGraph,
    namedGraphs: {
      IriTerm('${ex}people'): peopleGraph,
      IriTerm('${ex}places'): placesGraph,
    },
  );

  final datasetJsonLd =
      rdfCore.encodeDataset(dataset, contentType: _jsonLdMimeType);
  print(
      '=== 2. RdfDataset (2 named graphs + default graph) → nested JSON-LD ===');
  print(datasetJsonLd);

  // Roundtrip: decode back and verify graph contents
  final decodedDataset =
      rdfCore.decodeDataset(datasetJsonLd, contentType: _jsonLdMimeType);
  final decodedPeople = decodedDataset.graph(IriTerm('${ex}people'));
  final decodedPlaces = decodedDataset.graph(IriTerm('${ex}places'));
  final decodedDefault = decodedDataset.defaultGraph;
  print('Decoded dataset:');
  print('  default graph : ${decodedDefault.triples.length} triples '
      '(provenance metadata)');
  print('  ex:people     : ${decodedPeople?.triples.length ?? 0} triples');
  print('  ex:places     : ${decodedPlaces?.triples.length ?? 0} triples');
}
