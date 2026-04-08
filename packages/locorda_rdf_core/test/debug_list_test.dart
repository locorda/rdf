import 'dart:convert';
import 'dart:io';
import 'package:locorda_rdf_core/src/jsonld/jsonld_compaction_processor.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.message}');
  });

  final contextFile = File(
      '../../test_assets/w3c/json-ld-api/tests/compact/0007-context.jsonld');
  final inputFile =
      File('../../test_assets/w3c/json-ld-api/tests/compact/0007-in.jsonld');
  final context = jsonDecode(contextFile.readAsStringSync());
  final input = jsonDecode(inputFile.readAsStringSync());

  final processor = JsonLdCompactionProcessor(processingMode: 'json-ld-1.1');
  final result = processor.compact(input, context: context);
  // Just show the book node
  final graph = result['@graph'] as List;
  for (final node in graph) {
    final n = node as Map;
    if (n['@id'] == 'http://example.org/test#library') {
      print(const JsonEncoder.withIndent('  ').convert(n));
    }
  }
}
