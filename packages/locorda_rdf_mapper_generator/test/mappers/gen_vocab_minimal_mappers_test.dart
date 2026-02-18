import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:test/test.dart';

import '../fixtures/gen_vocab_minimal_test_models.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
  group('GenVocab minimal mapper integration', () {
    late RdfMapper mapper;

    setUp(() {
      mapper = defaultInitTestRdfMapper();
    });

    test('registers minimal define global resource mapper', () {
      expect(
          mapper.registry
              .hasGlobalResourceDeserializerFor<GenVocabMinimalEntity>(),
          isTrue);
    });

    test('roundtrip uses implicit predicate from property name', () {
      final entity = GenVocabMinimalEntity(
        id: 'minimal-1',
        minimalName: 'Minimal Example',
        lastModified: DateTime.now(),
      );

      final rdfContent = mapper.encodeObject(entity);
      final graph = rdf.decode(rdfContent, contentType: 'text/turtle');
      final subject = IriTerm('https://example.com/minimal/minimal-1');

      expect(
        graph.findTriples(
          subject: subject,
          predicate: IriTerm('https://minimal.example.com/vocab#minimalName'),
          object: LiteralTerm('Minimal Example'),
        ),
        isNotEmpty,
      );

      final decoded = mapper.decodeObject<GenVocabMinimalEntity>(rdfContent);
      expect(decoded.id, equals(entity.id));
      expect(decoded.minimalName, equals(entity.minimalName));
    });
  });
}
