import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('RdfTriplesDecoder contract', () {
    test('NTriplesToTriplesDecoder implements RdfTriplesDecoder', () {
      final decoder = NTriplesToTriplesDecoder();

      expect(decoder, isA<RdfTriplesDecoder>());
    });

    test('withOptions returns a RdfTriplesDecoder', () {
      final base = NTriplesToTriplesDecoder();
      final configured = base.withOptions(const NTriplesDecoderOptions());

      expect(configured, isA<RdfTriplesDecoder>());
      final triples = configured
          .convert('<http://example.org/s> <http://example.org/p> "o" .');
      expect(triples.length, 1);
    });

    test('bind works through abstraction type ', () async {
      final RdfTriplesDecoder decoder = NTriplesToTriplesDecoder();
      final chunks = Stream.fromIterable(const [
        '_:b1 <http://example.org/p> "first" .',
        '_:b1 <http://example.org/p> "second" .',
      ]);

      final batches = await decoder.bind(chunks).toList();
      expect(batches, hasLength(2));

      final s1 = batches[0].first.subject;
      final s2 = batches[1].first.subject;
      expect(identical(s1, s2), isTrue);
    });
  });
}
