import 'package:test/test.dart';
import 'package:locorda_rdf_mapper_annotations/src/vocab/app_vocab.dart';

void main() {
  group('AppVocab', () {
    test('constructor assigns fields', () {
      const vocab = AppVocab(
        iri: 'http://example.org/vocab#',
        prefix: 'ex',
        label: 'Example Vocabulary',
        comment: 'A demo vocabulary for testing.',
      );
      expect(vocab.iri, 'http://example.org/vocab#');
      expect(vocab.prefix, 'ex');
      expect(vocab.label, 'Example Vocabulary');
      expect(vocab.comment, 'A demo vocabulary for testing.');
    });
  });
}
