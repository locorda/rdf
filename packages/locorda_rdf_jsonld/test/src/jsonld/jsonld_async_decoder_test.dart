import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';
import 'package:test/test.dart';

class _InlineAsyncContextProvider
    implements AsyncJsonLdContextDocumentProvider {
  final Future<dynamic> Function(JsonLdContextDocumentRequest request) _load;

  const _InlineAsyncContextProvider(this._load);

  @override
  Future<dynamic> loadContextDocumentAsync(
      JsonLdContextDocumentRequest request) {
    return _load(request);
  }
}

void main() {
  group('AsyncJsonLdDecoder', () {
    test('loads external context asynchronously', () async {
      final input = '''
      {
        "@context": "https://example.org/context.jsonld",
        "@id": "http://example.org/person",
        "name": "Alice"
      }
      ''';

      final decoder = AsyncJsonLdDecoder(
        options: AsyncJsonLdDecoderOptions(
          contextDocumentProvider: _InlineAsyncContextProvider(
            (request) async {
              if (request.resolvedContextIri ==
                  'https://example.org/context.jsonld') {
                return {
                  '@context': {'name': 'http://xmlns.com/foaf/0.1/name'}
                };
              }
              return null;
            },
          ),
        ),
      );

      final dataset = await decoder.convert(input);
      final graph = dataset.defaultGraph;

      expect(graph.triples, hasLength(1));
      final triple = graph.triples.first;
      expect(triple.subject, equals(IriTerm('http://example.org/person')));
      expect(
          triple.predicate, equals(IriTerm('http://xmlns.com/foaf/0.1/name')));
      expect(triple.object, equals(LiteralTerm.string('Alice')));
    });

    test('each context IRI is loaded only once per decode call', () async {
      // Document references the same context twice via different nodes.
      final input = '''
      [
        {
          "@context": "https://example.org/context.jsonld",
          "@id": "http://example.org/a",
          "name": "Alice"
        },
        {
          "@context": "https://example.org/context.jsonld",
          "@id": "http://example.org/b",
          "name": "Bob"
        }
      ]
      ''';

      var loadCalls = 0;

      final decoder = AsyncJsonLdDecoder(
        options: AsyncJsonLdDecoderOptions(
          contextDocumentProvider: _InlineAsyncContextProvider(
            (request) async {
              loadCalls += 1;
              if (request.resolvedContextIri ==
                  'https://example.org/context.jsonld') {
                return {
                  '@context': {'name': 'http://xmlns.com/foaf/0.1/name'}
                };
              }
              return null;
            },
          ),
        ),
      );

      final dataset = await decoder.convert(input);
      expect(dataset.defaultGraph.triples, hasLength(2));
      expect(loadCalls, equals(1));
    });
  });
}
