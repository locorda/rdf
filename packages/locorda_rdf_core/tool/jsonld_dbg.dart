import 'dart:io';

import 'package:locorda_rdf_core/core.dart';

void main(List<String> args) {
  final fixture = args.isNotEmpty
      ? args.first
      : '../../test_assets/w3c/json-ld-api/tests/toRdf/0113-in.jsonld';

  final input = File(fixture).readAsStringSync();

  final fixtureName = fixture.split('/').last;
  final documentUrl =
      'https://w3c.github.io/json-ld-api/tests/toRdf/$fixtureName';

  final testsRoot = File(fixture).absolute.parent.parent.path;
  final testsRootUri = Directory(testsRoot).absolute.uri.toString();

  final dataset = JsonLdDecoder(
    options: JsonLdDecoderOptions(
      contextDocumentProvider: MappedFileJsonLdContextDocumentProvider(
        iriPrefixMappings: {
          'https://w3c.github.io/json-ld-api/tests/': testsRootUri,
        },
      ),
    ),
  ).convert(
    input,
    documentUrl: documentUrl,
  );

  print('fixture: $fixture');
  print('default triples: ${dataset.defaultGraph.triples.length}');
  print('named graphs: ${dataset.namedGraphs.length}');
  for (final quad in dataset.quads) {
    print(quad);
  }
}
