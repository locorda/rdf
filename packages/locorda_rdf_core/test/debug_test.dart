import 'dart:convert';
import 'package:locorda_rdf_core/src/jsonld/jsonld_expansion_processor.dart';
import 'package:test/test.dart';
import 'package:logging/logging.dart';

void main() {
  test('debug - trace expandIriReference', () {
    Logger.root.level = Level.FINEST;
    Logger.root.onRecord.listen((r) => print('${r.loggerName}: ${r.message}'));
    
    final processor = JsonLdExpansionProcessor(
      processingMode: 'json-ld-1.1',
      documentBaseUri: 'https://w3c.github.io/json-ld-api/tests/expand/test.jsonld',
    );
    
    final input = {
      "@context": {
        "ex": "http://example.org/",
        "name": "http://example.org/name"
      },
      "@id": "ex:node1",
      "name": "hello",
    };
    final r = processor.expand(input, documentUrl: 'https://w3c.github.io/json-ld-api/tests/expand/test.jsonld');
    print('Result: ${jsonEncode(r)}');
  });
}
