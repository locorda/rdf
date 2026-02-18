import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_generator/src/vocab/turtle_generator.dart';
import 'package:locorda_rdf_terms_core/owl.dart';
import 'package:locorda_rdf_terms_core/rdf.dart';
import 'package:locorda_rdf_terms_core/rdfs.dart';
import 'package:test/test.dart';

void main() {
  group('generateTurtle', () {
    test('emits ontology label/comment/metadata when provided', () {
      final vocabTerm = IriTerm('https://example.com/vocab#');
      final creatorIri = IriTerm('https://example.com/team');
      final graph = createOwlOntology(
        VocabOntologyDefinition(
          vocabularyIri: vocabTerm,
          metadata: {
            RdfsClass.label: [LiteralTerm('Example Vocabulary')],
            RdfsClass.comment: [LiteralTerm('Vocabulary for testing')],
            IriTerm('http://www.w3.org/2002/07/owl#versionInfo'): [
              LiteralTerm('1.0.0')
            ],
            IriTerm('http://purl.org/dc/terms/creator'): [creatorIri],
          },
          classes: const [],
        ),
      );

      expect(
          graph.findTriples(
              subject: vocabTerm,
              predicate: RdfsClass.label,
              object: LiteralTerm('Example Vocabulary')),
          isNotEmpty);
      expect(
          graph.findTriples(
              subject: vocabTerm,
              predicate: RdfsClass.comment,
              object: LiteralTerm('Vocabulary for testing')),
          isNotEmpty);
      expect(
          graph.findTriples(
              subject: vocabTerm,
              predicate: IriTerm('http://www.w3.org/2002/07/owl#versionInfo'),
              object: LiteralTerm('1.0.0')),
          isNotEmpty);
      expect(
          graph.findTriples(
              subject: vocabTerm,
              predicate: IriTerm('http://purl.org/dc/terms/creator'),
              object: creatorIri),
          isNotEmpty);
    });

    test('emits ontology, class, and properties', () {
      final graph = createOwlOntology(
        VocabOntologyDefinition(
          vocabularyIri: IriTerm('https://example.com/vocab#'),
          classes: [
            VocabClassDefinition(
              classIri: IriTerm('https://example.com/vocab#Book'),
              subClassOfIri: null,
              properties: [
                VocabPropertyDefinition(
                  propertyIri: IriTerm('https://example.com/vocab#title'),
                ),
                VocabPropertyDefinition(
                  propertyIri: IriTerm('https://example.com/vocab#author'),
                ),
              ],
            )
          ],
        ),
      );

      final vocabTerm = IriTerm('https://example.com/vocab#');
      final classTerm = IriTerm('https://example.com/vocab#Book');
      final titleTerm = IriTerm('https://example.com/vocab#title');

      expect(
          graph.findTriples(
              subject: vocabTerm,
              predicate: RdfProperty.type,
              object: OwlOntology.classIri),
          isNotEmpty);
      expect(
          graph.findTriples(
              subject: classTerm,
              predicate: RdfProperty.type,
              object: OwlClass.classIri),
          isNotEmpty);
      expect(
          graph.findTriples(
              subject: titleTerm,
              predicate: RdfProperty.type,
              object: RdfProperty.classIri),
          isNotEmpty);
      expect(
          graph.findTriples(
              subject: titleTerm,
              predicate: RdfProperty.rdfsDomain,
              object: classTerm),
          isNotEmpty);
    });

    test('emits subClassOf when provided', () {
      final graph = createOwlOntology(
        VocabOntologyDefinition(
          vocabularyIri: IriTerm('https://example.com/vocab#'),
          classes: [
            VocabClassDefinition(
              classIri: IriTerm('https://example.com/vocab#Chapter'),
              subClassOfIri: IriTerm('https://schema.org/Chapter'),
              properties: const [],
            )
          ],
        ),
      );

      final classTerm = IriTerm('https://example.com/vocab#Chapter');
      final subClassTerm = IriTerm('https://schema.org/Chapter');

      expect(
          graph.findTriples(
              subject: classTerm,
              predicate: RdfsClass.subClassOf,
              object: subClassTerm),
          isNotEmpty);
    });

    test('does not emit rdfs:domain for noDomain properties', () {
      final graph = createOwlOntology(
        VocabOntologyDefinition(
          vocabularyIri: IriTerm('https://example.com/vocab#'),
          classes: [
            VocabClassDefinition(
              classIri: IriTerm('https://example.com/vocab#Entity'),
              subClassOfIri: IriTerm('http://www.w3.org/2002/07/owl#Thing'),
              properties: const [
                VocabPropertyDefinition(
                  propertyIri: IriTerm('https://example.com/vocab#identifier'),
                  noDomain: true,
                )
              ],
            )
          ],
        ),
      );

      final property = IriTerm('https://example.com/vocab#identifier');
      final classTerm = IriTerm('https://example.com/vocab#Entity');

      expect(
        graph.findTriples(
          subject: property,
          predicate: RdfProperty.rdfsDomain,
          object: classTerm,
        ),
        isEmpty,
      );
    });
  });
}
