import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_generator/vocab_builder.dart';
import 'package:locorda_rdf_terms_core/rdfs.dart';
import 'package:locorda_rdf_terms_core/rdf.dart';
import 'package:test/test.dart';

void main() {
  group('Vocabulary Metadata Generation', () {
    test('auto-generates rdfs:label from camelCase property names', () {
      final jsonFiles = [
        (
          'test.json',
          '''
{
  "mappers": [
    {
      "__type__": "ResourceMapperTemplateData",
      "className": {"code": "Book", "imports": [], "__type__": "\$Code\$"},
      "hasVocab": true,
      "vocab": {
        "appBaseUri": "https://example.com",
        "vocabPath": "/vocab"
      },
      "subClassOfIri": null,
      "genVocabMetadata": {},
      "properties": [
        {
          "isRdfProperty": true,
          "include": true,
          "fragment": "displayTitle",
          "metadata": {}
        },
        {
          "isRdfProperty": true,
          "include": true,
          "fragment": "pageCount",
          "metadata": {}
        }
      ]
    }
  ]
}
'''
        )
      ];

      final vocabData = collectVocabDataForTesting(jsonFiles);
      expect(vocabData, hasLength(1));

      final graph = vocabData.values.first;
      final vocabIri = IriTerm.validated('https://example.com/vocab#');

      // Check displayTitle has auto-generated label
      final displayTitleIri =
          IriTerm.validated('${vocabIri.value}displayTitle');
      final displayTitleLabel = graph.triples
          .where(
              (t) => t.subject == displayTitleIri && t.predicate == Rdfs.label)
          .map((t) => t.object)
          .whereType<LiteralTerm>()
          .firstOrNull;

      expect(displayTitleLabel?.value, equals('Display Title'));

      // Check pageCount has auto-generated label
      final pageCountIri = IriTerm.validated('${vocabIri.value}pageCount');
      final pageCountLabel = graph.triples
          .where((t) => t.subject == pageCountIri && t.predicate == Rdfs.label)
          .map((t) => t.object)
          .whereType<LiteralTerm>()
          .firstOrNull;

      expect(pageCountLabel?.value, equals('Page Count'));
    });

    test('auto-generates rdfs:label for classes from className', () {
      final jsonFiles = [
        (
          'test.json',
          '''
{
  "mappers": [
    {
      "__type__": "ResourceMapperTemplateData",
      "className": {"code": "GenVocabBook", "imports": [], "__type__": "\$Code\$"},
      "hasVocab": true,
      "vocab": {
        "appBaseUri": "https://example.com",
        "vocabPath": "/vocab"
      },
      "subClassOfIri": null,
      "genVocabMetadata": {},
      "properties": []
    }
  ]
}
'''
        )
      ];

      final vocabData = collectVocabDataForTesting(jsonFiles);
      final graph = vocabData.values.first;

      final classIri =
          IriTerm.validated('https://example.com/vocab#GenVocabBook');
      final classLabel = graph.triples
          .where((t) => t.subject == classIri && t.predicate == Rdfs.label)
          .map((t) => t.object)
          .whereType<LiteralTerm>()
          .firstOrNull;

      expect(classLabel?.value, equals('Gen Vocab Book'));
    });

    test('does not override explicit rdfs:label in metadata', () {
      final jsonFiles = [
        (
          'test.json',
          '''
{
  "mappers": [
    {
      "__type__": "ResourceMapperTemplateData",
      "className": {"code": "Book", "imports": [], "__type__": "\$Code\$"},
      "hasVocab": true,
      "vocab": {
        "appBaseUri": "https://example.com",
        "vocabPath": "/vocab"
      },
      "subClassOfIri": null,
      "genVocabMetadata": {},
      "properties": [
        {
          "isRdfProperty": true,
          "include": true,
          "fragment": "isbn",
          "metadata": {
            "http://www.w3.org/2000/01/rdf-schema#label": [
              {
                "termType": "literal",
                "value": "ISBN Number",
                "datatype": "http://www.w3.org/2001/XMLSchema#string"
              }
            ]
          }
        }
      ]
    }
  ]
}
'''
        )
      ];

      final vocabData = collectVocabDataForTesting(jsonFiles);
      final graph = vocabData.values.first;

      final isbnIri = IriTerm.validated('https://example.com/vocab#isbn');
      final isbnLabel = graph.triples
          .where((t) => t.subject == isbnIri && t.predicate == Rdfs.label)
          .map((t) => t.object)
          .whereType<LiteralTerm>()
          .firstOrNull;

      // Should keep explicit label, not autogenerate "Isbn"
      expect(isbnLabel?.value, equals('ISBN Number'));
    });

    test('adds rdfs:isDefinedBy for all classes and properties', () {
      final jsonFiles = [
        (
          'test.json',
          '''
{
  "mappers": [
    {
      "__type__": "ResourceMapperTemplateData",
      "className": {"code": "Book", "imports": [], "__type__": "\$Code\$"},
      "hasVocab": true,
      "vocab": {
        "appBaseUri": "https://example.com",
        "vocabPath": "/vocab"
      },
      "subClassOfIri": null,
      "genVocabMetadata": {},
      "properties": [
        {
          "isRdfProperty": true,
          "include": true,
          "fragment": "title",
          "metadata": {}
        }
      ]
    }
  ]
}
'''
        )
      ];

      final vocabData = collectVocabDataForTesting(jsonFiles);
      final graph = vocabData.values.first;

      final vocabIri = IriTerm.validated('https://example.com/vocab#');
      final classIri = IriTerm.validated('${vocabIri.value}Book');
      final titleIri = IriTerm.validated('${vocabIri.value}title');

      // Check class has isDefinedBy
      final classIsDefinedBy = graph.triples
          .where((t) =>
              t.subject == classIri && t.predicate == RdfsClass.isDefinedBy)
          .map((t) => t.object)
          .whereType<IriTerm>()
          .firstOrNull;

      expect(classIsDefinedBy, equals(vocabIri));

      // Check property has isDefinedBy
      final propertyIsDefinedBy = graph.triples
          .where((t) =>
              t.subject == titleIri && t.predicate == RdfsClass.isDefinedBy)
          .map((t) => t.object)
          .whereType<IriTerm>()
          .firstOrNull;

      expect(propertyIsDefinedBy, equals(vocabIri));
    });

    test('label generation handles various camelCase patterns', () {
      final testCases = {
        'isbn': 'Isbn',
        'title': 'Title',
        'displayTitle': 'Display Title',
        'pageCount': 'Page Count',
        'authorFirstName': 'Author First Name',
        'URLValue': 'URLValue', // All caps stays as-is
        'myHTMLParser': 'My HTMLParser',
      };

      for (final entry in testCases.entries) {
        final jsonFiles = [
          (
            'test.json',
            '''
{
  "mappers": [
    {
      "__type__": "ResourceMapperTemplateData",
      "className": {"code": "Test", "imports": [], "__type__": "\$Code\$"},
      "hasVocab": true,
      "vocab": {
        "appBaseUri": "https://example.com",
        "vocabPath": "/vocab"
      },
      "subClassOfIri": null,
      "genVocabMetadata": {},
      "properties": [
        {
          "isRdfProperty": true,
          "include": true,
          "fragment": "${entry.key}",
          "metadata": {}
        }
      ]
    }
  ]
}
'''
          )
        ];

        final vocabData = collectVocabDataForTesting(jsonFiles);
        final graph = vocabData.values.first;

        final propertyIri =
            IriTerm.validated('https://example.com/vocab#${entry.key}');
        final label = graph.triples
            .where((t) => t.subject == propertyIri && t.predicate == Rdfs.label)
            .map((t) => t.object)
            .whereType<LiteralTerm>()
            .firstOrNull;

        expect(label?.value, equals(entry.value),
            reason: 'Label for "${entry.key}" should be "${entry.value}"');
      }
    });

    group('shared fragment deduplication', () {
      // Builds a JSON payload for a single resource with the given className,
      // fragment, and optional noDomain flag.
      String _resourceJson(String className, String fragment,
              {bool noDomain = false}) =>
          '''
{
  "mappers": [
    {
      "__type__": "ResourceMapperTemplateData",
      "className": {"code": "$className", "imports": [], "__type__": "\$Code\$"},
      "hasVocab": true,
      "vocab": {
        "appBaseUri": "https://example.com",
        "vocabPath": "/vocab"
      },
      "subClassOfIri": null,
      "genVocabMetadata": {},
      "properties": [
        {
          "isRdfProperty": true,
          "include": true,
          "fragment": "$fragment",
          "noDomain": $noDomain,
          "metadata": {}
        }
      ]
    }
  ]
}
''';

      test(
          'two resources with the same noDomain fragment produce a single '
          'property without rdfs:domain', () {
        // Both ClassA and ClassB annotate a field with
        // @RdfProperty.define(fragment: 'keyword', noDomain: true).
        // The generator should produce exactly one rdf:Property triple for
        // vocab#keyword and no rdfs:domain triple.
        final jsonFiles = [
          ('classA.json', _resourceJson('ClassA', 'keyword', noDomain: true)),
          ('classB.json', _resourceJson('ClassB', 'keyword', noDomain: true)),
        ];

        final vocabData = collectVocabDataForTesting(jsonFiles);
        expect(vocabData, hasLength(1));

        final graph = vocabData.values.first;
        final vocabIri = IriTerm.validated('https://example.com/vocab#');
        final keywordIri = IriTerm.validated('${vocabIri.value}keyword');

        // Exactly one rdf:type rdf:Property triple for keyword.
        final typeTriples = graph.triples
            .where((t) =>
                t.subject == keywordIri &&
                t.predicate == Rdf.type &&
                t.object == Rdf.Property)
            .toList();
        expect(typeTriples, hasLength(1),
            reason: 'Shared noDomain fragment should produce exactly one '
                'rdf:Property triple, not one per source class');

        // No rdfs:domain triple for keyword.
        final domainTriples = graph.triples
            .where((t) => t.subject == keywordIri && t.predicate == Rdfs.domain)
            .toList();
        expect(domainTriples, isEmpty,
            reason: 'noDomain: true should suppress rdfs:domain even when the '
                'fragment is shared across multiple resources');
      });

      test(
          'two resources with the same fragment but without noDomain throw '
          'StateError (domain conflict)', () {
        // Without noDomain, each class implicitly declares rdfs:domain to
        // itself. Sharing the same fragment across two different classes is a
        // conflict that must be detected.
        final jsonFiles = [
          ('classA.json', _resourceJson('ClassA', 'keyword')),
          ('classB.json', _resourceJson('ClassB', 'keyword')),
        ];

        expect(
          () => collectVocabDataForTesting(jsonFiles),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains("Duplicate fragment 'keyword'"),
            ),
          ),
          reason:
              'Sharing a fragment across two classes without noDomain creates '
              'conflicting rdfs:domain declarations and must throw',
        );
      });

      test(
          'one resource with noDomain and another without for the same fragment '
          'throw StateError (mixed domain semantics)', () {
        // Mixing noDomain: true and noDomain: false for the same fragment is
        // always a conflict: one side wants no rdfs:domain while the other
        // wants one scoped to its class.
        final jsonFiles = [
          ('classA.json', _resourceJson('ClassA', 'keyword', noDomain: true)),
          ('classB.json', _resourceJson('ClassB', 'keyword', noDomain: false)),
        ];

        expect(
          () => collectVocabDataForTesting(jsonFiles),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains("Duplicate fragment 'keyword'"),
            ),
          ),
          reason:
              'Mixed noDomain semantics for the same fragment must be detected '
              'as a conflict',
        );
      });
    });
  });
}
