import 'dart:convert';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/jsonld/jsonld_context.dart';
import 'package:test/test.dart';

void main() {
  test('debug json literal context', () {
    final contextProcessor = JsonLdContextProcessor(
      processingMode: 'json-ld-1.1',
      format: 'JSON-LD',
      documentBaseUri: 'https://w3c.github.io/json-ld-api/tests/compact/js01-in.jsonld',
    );
    
    var activeContext = JsonLdContext(
      base: 'https://w3c.github.io/json-ld-api/tests/compact/js01-in.jsonld',
      hasBase: true,
    );
    
    final contextValue = {"@version": 1.1, "e": {"@id": "http://example.org/vocab#bool", "@type": "@json"}};
    
    activeContext = contextProcessor.mergeContext(
      activeContext,
      contextValue,
      seenContextIris: <String>{},
    );
    
    print('Terms: ${activeContext.terms.keys}');
    final eDef = activeContext.terms['e'];
    print('e term: iri=${eDef?.iri}, typeMapping=${eDef?.typeMapping}, containers=${eDef?.containers}');
  });
}
