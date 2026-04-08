import 'dart:convert';
import 'package:locorda_rdf_core/src/jsonld/jsonld_compaction_processor.dart';
import 'package:locorda_rdf_core/src/jsonld/jsonld_context.dart';
import 'package:locorda_rdf_core/src/jsonld/jsonld_context_processor.dart';
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (record.loggerName == 'rdf.jsonld.compaction' &&
        record.message.contains('http://example.org/term2')) {
      print('LOG: ${record.message}');
    }
  });

  final processor = JsonLdCompactionProcessor(processingMode: 'json-ld-1.1');

  final input = [
    {
      "@id": "http://example.org/id1",
      "@type": ["http://example.org/Type1", "http://example.org/Type2"],
      "http://example.org/term1": [
        {"@value": "v1", "@type": "http://example.org/different-datatype"}
      ],
      "http://example.org/term2": [{"@id": "http://example.org/id2"}]
    }
  ];

  final context = {
    "@context": {
      "ex": "http://example.org/",
      "term1": {"@id": "ex:term1", "@type": "ex:datatype"},
      "term2": "ex:term2"
    }
  };

  // Check what the context processor produces
  final ctxProcessor = JsonLdContextProcessor(
    processingMode: 'json-ld-1.1',
    format: 'JSON-LD',
  );
  var ctx = const JsonLdContext();
  ctx = ctxProcessor.mergeContext(ctx, context['@context'], seenContextIris: <String>{});
  print('Terms:');
  for (final e in ctx.terms.entries) {
    print('  ${e.key} -> iri=${e.value.iri} null=${e.value.isNullMapping}');
  }

  final result = processor.compact(input, context: context);
  print(const JsonEncoder.withIndent('  ').convert(result));
}
