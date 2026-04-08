import 'dart:convert';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/jsonld/jsonld_context.dart';
import 'package:test/test.dart';

void main() {
  test('debug nest', () {
    final contextProcessor = JsonLdContextProcessor(
      processingMode: 'json-ld-1.1',
      format: 'JSON-LD',
    );
    var activeContext = const JsonLdContext();
    activeContext = contextProcessor.mergeContext(
      activeContext,
      {"@vocab": "http://example.org/", "p2": {"@nest": "@nest"}},
      seenContextIris: <String>{},
    );
    
    print('Terms: ${activeContext.terms.keys}');
    final p2Def = activeContext.terms['p2'];
    print('p2: iri=${p2Def?.iri}, nestValue=${p2Def?.nestValue}');
  });
}
