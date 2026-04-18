/// JSON-LD Custom Context Example
///
/// Demonstrates two advanced context-related features:
///
/// 1. **Encoding with a custom compaction context** — supply your own
///    `@context` to drive the W3C compaction algorithm, giving you full
///    control over the term names and type coercions in the output.
///
/// 2. **Decoding with pre-loaded external contexts** — avoid network I/O by
///    providing context documents up-front via
///    [PreloadedJsonLdContextDocumentProvider], useful in offline or
///    server-side environments.
library;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';
import 'package:locorda_rdf_terms_core/rdf.dart';

// ---------------------------------------------------------------------------
// 1. Encoding with a custom compaction context
// ---------------------------------------------------------------------------

void _customCompactionContextExample() {
  print('=== Encoding with a custom compaction context ===\n');

  // A small graph with Schema.org properties
  final ex = 'http://example.org/';
  final alice = IriTerm('${ex}alice');

  final graph = RdfGraph(triples: [
    Triple(alice, Rdf.type, IriTerm('http://schema.org/Person')),
    Triple(
      alice,
      IriTerm('http://schema.org/name'),
      LiteralTerm.string('Alice'),
    ),
    Triple(
      alice,
      IriTerm('http://schema.org/email'),
      LiteralTerm.string('alice@example.org'),
    ),
    Triple(
      alice,
      IriTerm('http://schema.org/birthDate'),
      LiteralTerm.typed('1990-06-15', 'date'),
    ),
  ]);

  // Provide a hand-crafted context that maps Schema.org terms to short names
  // and declares @type coercions, so the compaction algorithm can produce a
  // clean, domain-specific JSON-LD document.
  final schemaContext = {
    '@context': {
      'schema': 'http://schema.org/',
      'xsd': 'http://www.w3.org/2001/XMLSchema#',
      'Person': 'schema:Person',
      'name': 'schema:name',
      'email': 'schema:email',
      'birthDate': {'@id': 'schema:birthDate', '@type': 'xsd:date'},
    }
  };

  final encoded = jsonldGraph.encode(
    graph,
    options: JsonLdGraphEncoderOptions(
      outputMode: JsonLdOutputMode.compact,
      compactionContext: schemaContext,
    ),
  );

  print(encoded);
}

// ---------------------------------------------------------------------------
// 2. Decoding JSON-LD that references an external context by URL
// ---------------------------------------------------------------------------

void _preloadedContextExample() {
  print('\n=== Decoding with a pre-loaded external context ===\n');

  // JSON-LD document that references an external context by URL.
  // In production this would be fetched over HTTP; here we supply it inline
  // so the example works offline.
  const jsonLd = '''
  {
    "@context": "https://schema.org/",
    "@type": "Person",
    "@id": "http://example.org/bob",
    "name": "Bob",
    "email": "bob@example.org"
  }
  ''';

  // Pre-populate the external context so the decoder never needs to perform
  // a network request.  The key is the URL the document uses in @context.
  final preloadedContexts = {
    'https://schema.org/': {
      '@context': {
        'schema': 'http://schema.org/',
        'name': 'schema:name',
        'email': 'schema:email',
        'Person': 'schema:Person',
      }
    }
  };

  // Use the synchronous JsonLdDecoder with a PreloadedJsonLdContextDocumentProvider
  // since all context documents are already in memory — no async I/O needed.
  final decoder = JsonLdDecoder(
    options: JsonLdDecoderOptions(
      contextDocumentProvider:
          PreloadedJsonLdContextDocumentProvider(preloadedContexts),
    ),
  );

  final dataset = decoder.convert(jsonLd);
  final graph = dataset.defaultGraph;

  print('Decoded ${graph.size} triple(s):');
  for (final triple in graph.triples) {
    print('  ${triple.subject} ${triple.predicate} ${triple.object}');
  }
}

void main() {
  print('JSON-LD Custom Context Example');
  print('==============================\n');

  _customCompactionContextExample();
  _preloadedContextExample();
}
