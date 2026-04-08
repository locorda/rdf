import 'dart:convert';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/jsonld/jsonld_compaction_processor.dart';
import 'package:test/test.dart';

void main() {
  test('graph array', () {
    final input = [{"@id": "http://example.com/graph/1", "@graph": [{"@id": "http://example.com/node/1", "http://example.com/property": [{"@value": "property"}]}]}];
    final context = {};
    final processor = JsonLdCompactionProcessor(processingMode: 'json-ld-1.1');
    final result = processor.compact(input, context: context);
    print(const JsonEncoder.withIndent('  ').convert(result));
  });
}
