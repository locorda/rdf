import 'dart:io';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';
import 'package:test/test.dart';

/// Unit tests for JSON-LD decoder Phase 1 features:
/// @vocab, complex term definitions, context arrays, @language,
/// @list, @set, @reverse
void main() {
  group('@vocab support', () {
    test('expands undefined terms using @vocab', () {
      final input = '''
      {
        "@context": {
          "@vocab": "http://schema.org/"
        },
        "@id": "http://example.org/person",
        "name": "Alice"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      expect(graph.triples, hasLength(1));
      final triple = graph.triples.first;
      expect(triple.subject, equals(IriTerm('http://example.org/person')));
      expect(triple.predicate, equals(IriTerm('http://schema.org/name')));
      expect(triple.object, equals(LiteralTerm.string('Alice')));
    });

    test('@vocab does not override explicit prefix mappings', () {
      final input = '''
      {
        "@context": {
          "@vocab": "http://schema.org/",
          "foaf": "http://xmlns.com/foaf/0.1/"
        },
        "@id": "http://example.org/person",
        "name": "Alice",
        "foaf:knows": {"@id": "http://example.org/bob"}
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      final nameTriple = graph.findTriples(
        predicate: IriTerm('http://schema.org/name'),
      );
      expect(nameTriple, hasLength(1));

      final knowsTriple = graph.findTriples(
        predicate: IriTerm('http://xmlns.com/foaf/0.1/knows'),
      );
      expect(knowsTriple, hasLength(1));
    });

    test('@vocab with @type generates rdf:type with expanded IRI', () {
      final input = '''
      {
        "@context": {
          "@vocab": "http://schema.org/"
        },
        "@id": "http://example.org/person",
        "@type": "Person"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      final typeTriple = graph.findTriples(
        predicate: IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
      );
      expect(typeTriple, hasLength(1));
      expect(
          typeTriple.first.object, equals(IriTerm('http://schema.org/Person')));
    });

    test('@vocab: null disables default vocabulary', () {
      final input = '''
      {
        "@context": {
          "@vocab": null
        },
        "@id": "http://example.org/person",
        "http://schema.org/name": "Alice"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      // The full IRI predicate should still work
      expect(graph.triples, hasLength(1));
      expect(graph.triples.first.predicate,
          equals(IriTerm('http://schema.org/name')));
    });
  });

  group('Complex term definitions', () {
    test('@type: @id coerces string values to IRIs', () {
      final input = '''
      {
        "@context": {
          "homepage": {"@id": "http://xmlns.com/foaf/0.1/homepage", "@type": "@id"}
        },
        "@id": "http://example.org/person",
        "homepage": "http://example.org/alice"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      final triple = graph.triples.first;
      expect(triple.predicate,
          equals(IriTerm('http://xmlns.com/foaf/0.1/homepage')));
      // Value should be an IRI, not a literal
      expect(triple.object, isA<IriTerm>());
      expect(
          (triple.object as IriTerm).value, equals('http://example.org/alice'));
    });

    test('@type: @vocab coerces string values using vocab expansion', () {
      final input = '''
      {
        "@context": {
          "@vocab": "http://schema.org/",
          "status": {"@id": "http://example.org/status", "@type": "@vocab"}
        },
        "@id": "http://example.org/thing",
        "status": "Active"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      final triple = graph.triples.first;
      expect(triple.predicate, equals(IriTerm('http://example.org/status')));
      // "Active" should be expanded via @vocab
      expect(triple.object, isA<IriTerm>());
      expect(
          (triple.object as IriTerm).value, equals('http://schema.org/Active'));
    });

    test('term with @id but no @type treats values as literals', () {
      final input = '''
      {
        "@context": {
          "name": {"@id": "http://xmlns.com/foaf/0.1/name"}
        },
        "@id": "http://example.org/person",
        "name": "Alice"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      final triple = graph.triples.first;
      expect(
          triple.predicate, equals(IriTerm('http://xmlns.com/foaf/0.1/name')));
      expect(triple.object, isA<LiteralTerm>());
      expect((triple.object as LiteralTerm).value, equals('Alice'));
    });

    test('@type with datatype IRI creates typed literal', () {
      final input = '''
      {
        "@context": {
          "xsd": "http://www.w3.org/2001/XMLSchema#",
          "age": {"@id": "http://schema.org/age", "@type": "xsd:integer"}
        },
        "@id": "http://example.org/person",
        "age": "42"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      final triple = graph.triples.first;
      expect(triple.object, isA<LiteralTerm>());
      final literal = triple.object as LiteralTerm;
      expect(literal.value, equals('42'));
      expect(literal.datatype,
          equals(IriTerm('http://www.w3.org/2001/XMLSchema#integer')));
    });

    test('@type with vocab-relative datatype expands via @vocab', () {
      final input = '''
      {
        "@context": {
          "@vocab": "http://example.org/vocab#",
          "date": {"@id": "http://schema.org/date", "@type": "dateTime"}
        },
        "@id": "http://example.org/person",
        "date": "2011-01-25T00:00:00Z"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      final literal = graph.triples.first.object as LiteralTerm;
      expect(
        literal.datatype,
        equals(IriTerm('http://example.org/vocab#dateTime')),
      );
    });

    test('@id null mapping suppresses property expansion', () {
      final input = '''
      {
        "@context": {
          "@vocab": "http://xmlns.com/foaf/0.1/",
          "from": null,
          "university": {"@id": null}
        },
        "@id": "http://example.org/person",
        "name": "Alice",
        "from": "Italy",
        "university": "TU Graz"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      expect(graph.triples, hasLength(1));
      expect(
        graph.triples.first.predicate,
        equals(IriTerm('http://xmlns.com/foaf/0.1/name')),
      );
    });
  });

  group('Context arrays', () {
    test('merges multiple inline context objects', () {
      final input = '''
      {
        "@context": [
          {"foaf": "http://xmlns.com/foaf/0.1/"},
          {"schema": "http://schema.org/"}
        ],
        "@id": "http://example.org/person",
        "foaf:name": "Alice",
        "schema:email": "alice@example.org"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      expect(graph.triples, hasLength(2));
      expect(
        graph.findTriples(predicate: IriTerm('http://xmlns.com/foaf/0.1/name')),
        hasLength(1),
      );
      expect(
        graph.findTriples(predicate: IriTerm('http://schema.org/email')),
        hasLength(1),
      );
    });

    test('later context overrides earlier context', () {
      final input = '''
      {
        "@context": [
          {"name": "http://xmlns.com/foaf/0.1/name"},
          {"name": "http://schema.org/name"}
        ],
        "@id": "http://example.org/person",
        "name": "Alice"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      // Should use the later definition
      expect(
        graph.findTriples(predicate: IriTerm('http://schema.org/name')),
        hasLength(1),
      );
    });

    test('unresolvable external context entries throw', () {
      final input = '''
      {
        "@context": [
          "http://schema.org/",
          {"name": "http://xmlns.com/foaf/0.1/name"}
        ],
        "@id": "http://example.org/person",
        "name": "Alice"
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('context array with @vocab and term definitions', () {
      final input = '''
      {
        "@context": [
          {"@vocab": "http://schema.org/"},
          {"input": {"@id": "http://example.org/input", "@type": "@id"}}
        ],
        "@id": "http://example.org/test",
        "name": "Test",
        "input": "http://example.org/data"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      // "name" expanded via @vocab
      expect(
        graph.findTriples(predicate: IriTerm('http://schema.org/name')),
        hasLength(1),
      );
      // "input" uses explicit term definition with IRI coercion
      final inputTriple =
          graph.findTriples(predicate: IriTerm('http://example.org/input'));
      expect(inputTriple, hasLength(1));
      expect(inputTriple.first.object, isA<IriTerm>());
    });

    test('resolves external context using contextDocumentLoader', () {
      final input = '''
      {
        "@context": [
          "https://example.org/context.jsonld",
          {"@base": "doc"}
        ],
        "@id": "",
        "name": "Alice"
      }
      ''';

      final dataset = JsonLdDecoder(
        options: JsonLdDecoderOptions(
          contextDocumentLoader: (request) {
            expect(request.contextReference,
                equals('https://example.org/context.jsonld'));
            expect(request.baseIri, equals('https://example.org/manifest'));
            expect(request.resolvedContextIri,
                equals('https://example.org/context.jsonld'));
            if (request.resolvedContextIri ==
                'https://example.org/context.jsonld') {
              return '{"@context": {"name": "http://xmlns.com/foaf/0.1/name"}}';
            }
            return null;
          },
        ),
      ).convert(input, documentUrl: 'https://example.org/manifest');

      final graph = dataset.defaultGraph;
      expect(graph.triples, hasLength(1));
      final triple = graph.triples.first;
      expect(triple.subject, equals(IriTerm('https://example.org/doc')));
      expect(
          triple.predicate, equals(IriTerm('http://xmlns.com/foaf/0.1/name')));
      expect(triple.object, equals(LiteralTerm.string('Alice')));
    });

    test('mapped file provider resolves virtual base URLs', () {
      final tempDir = Directory.systemTemp.createTempSync('jsonld_ctx_');
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      final contextFile = File('${tempDir.path}/context.jsonld');
      contextFile.writeAsStringSync(
        '{"@context": {"name": "http://xmlns.com/foaf/0.1/name"}}',
      );

      final input = '''
      {
        "@context": "https://virtual.example/context.jsonld",
        "@id": "http://example.org/person",
        "name": "Alice"
      }
      ''';

      final dataset = JsonLdDecoder(
        options: JsonLdDecoderOptions(
          contextDocumentProvider: MappedFileJsonLdContextDocumentProvider(
            iriPrefixMappings: {
              'https://virtual.example/': tempDir.uri.toString(),
            },
          ),
        ),
      ).convert(input);

      final graph = dataset.defaultGraph;
      expect(graph.triples, hasLength(1));
      final triple = graph.triples.first;
      expect(triple.subject, equals(IriTerm('http://example.org/person')));
      expect(
          triple.predicate, equals(IriTerm('http://xmlns.com/foaf/0.1/name')));
      expect(triple.object, equals(LiteralTerm.string('Alice')));
    });

    test('resolves relative external contexts against context base', () {
      final tempDir = Directory.systemTemp.createTempSync('jsonld_ctx_rel_');
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      final contextDir = Directory('${tempDir.path}/nested')..createSync();
      File('${tempDir.path}/root.jsonld').writeAsStringSync('''
      {
        "@context": [
          {"@base": "https://example.org/base/"},
          "nested/context.jsonld"
        ],
        "@id": "",
        "name": "Alice"
      }
      ''');
      File('${contextDir.path}/context.jsonld').writeAsStringSync(
        '{"@context": {"name": "http://xmlns.com/foaf/0.1/name"}}',
      );

      final dataset = JsonLdDecoder(
        options: JsonLdDecoderOptions(
          contextDocumentProvider: MappedFileJsonLdContextDocumentProvider(
            iriPrefixMappings: {
              'https://example.org/': tempDir.uri.toString(),
            },
          ),
        ),
      ).convert(
        File('${tempDir.path}/root.jsonld').readAsStringSync(),
        documentUrl: 'https://example.org/manifest.jsonld',
      );

      final graph = dataset.defaultGraph;
      expect(graph.triples, hasLength(1));
      expect(
        graph.triples.first.predicate,
        equals(IriTerm('http://xmlns.com/foaf/0.1/name')),
      );
      expect(
        graph.triples.first.subject,
        equals(IriTerm('https://example.org/base/')),
      );
    });
  });

  group('Validation guards', () {
    test('throws when property-valued @index misses @container @index', () {
      final input = '''
      {
        "@context": {
          "@version": 1.1,
          "@vocab": "http://example.com/",
          "container": {"@index": "prop"}
        },
        "@id": "http://example.com/node",
        "container": {"en": "value"}
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws when property-valued @index is a keyword', () {
      final input = '''
      {
        "@context": {
          "@version": 1.1,
          "@vocab": "http://example.com/",
          "container": {
            "@id": "http://example.com/container",
            "@container": "@index",
            "@index": "@index"
          }
        },
        "@id": "http://example.com/node",
        "container": {"en": "value"}
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws for invalid value object with unexpected keyword', () {
      final input = '''
      {
        "http://example/foo": {"@value": "bar", "@id": "http://example/baz"}
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws for invalid language-tagged value type', () {
      final input = '''
      {
        "http://example/foo": {"@value": true, "@language": "en"}
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws for invalid set or list object', () {
      final input = '''
      {
        "http://example/prop": {"@list": ["foo"], "@id": "http://example/bar"}
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws for invalid @reverse mapping IRI', () {
      final input = '''
      {
        "@context": {
          "rev": {"@reverse": "not an IRI"}
        },
        "@id": "http://example.org/foo",
        "rev": {"@id": "http://example.org/bar"}
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws for empty term definition', () {
      final input = '''
      {
        "@context": {
          "": {"@id": "http://example.org/empty"}
        },
        "@id": "http://example/test#example"
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws for @context keyword redefinition', () {
      final input = '''
      {
        "@context": {
          "@context": {
            "p": "ex:p"
          }
        },
        "@id": "ex:1",
        "p": "value"
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws for invalid @reverse value type', () {
      final input = '''
      {
        "http://example/prop": {
          "@reverse": true
        }
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws for invalid @included scalar value', () {
      final input = '''
      {
        "@context": {
          "@version": 1.1,
          "@vocab": "http://example.org/"
        },
        "@included": "string"
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws when type map string expands to literal mapping', () {
      final input = '''
      {
        "@context": {
          "@version": 1.1,
          "@vocab": "http://example.org/ns/",
          "@base": "http://example.org/base/",
          "foo": {"@type": "literal", "@container": "@type"}
        },
        "foo": {"bar": "baz"}
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws when @propagate is non-boolean', () {
      final input = '''
      {
        "@context": {
          "@version": 1.1,
          "@propagate": "no"
        }
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws processing mode conflict for @version 1.1 in json-ld-1.0', () {
      final input = '''
      {
        "@context": {
          "@version": 1.1
        }
      }
      ''';

      expect(
        () => JsonLdDecoder(
          options: const JsonLdDecoderOptions(processingMode: 'json-ld-1.0'),
        ).convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws for invalid top-level @nest scalar value', () {
      final input = '''
      {
        "@context": {"@vocab": "http://example.org/"},
        "@nest": "invalid"
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws for invalid @nest term-definition value', () {
      final input = '''
      {
        "@context": {
          "term": {"@id": "http://example/term", "@nest": "@id"}
        }
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });

    test('throws when @nest is combined with @reverse in term definition', () {
      final input = '''
      {
        "@context": {
          "term": {"@reverse": "http://example/term", "@nest": "@nest"}
        }
      }
      ''';

      expect(
        () => JsonLdDecoder().convert(input),
        throwsA(isA<RdfSyntaxException>()),
      );
    });
  });

  group('Property-valued index', () {
    test('injects map key into configured index property', () {
      final input = '''
      {
        "@context": {
          "@version": 1.1,
          "@base": "http://example.com/",
          "@vocab": "http://example.com/",
          "author": {"@type": "@id", "@container": "@index", "@index": "prop"}
        },
        "@id": "article",
        "author": {
          "regular": "person/1",
          "guest": ["person/2", "person/3"]
        }
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      expect(
        graph.findTriples(
          subject: IriTerm('http://example.com/person/1'),
          predicate: IriTerm('http://example.com/prop'),
          object: LiteralTerm.string('regular'),
        ),
        hasLength(1),
      );
      expect(
        graph.findTriples(
          subject: IriTerm('http://example.com/person/2'),
          predicate: IriTerm('http://example.com/prop'),
          object: LiteralTerm.string('guest'),
        ),
        hasLength(1),
      );
      expect(
        graph.findTriples(
          subject: IriTerm('http://example.com/person/3'),
          predicate: IriTerm('http://example.com/prop'),
          object: LiteralTerm.string('guest'),
        ),
        hasLength(1),
      );
    });
  });

  group('@language in context (default language)', () {
    test('applies default language to plain string literals', () {
      final input = '''
      {
        "@context": {
          "@language": "en",
          "name": "http://xmlns.com/foaf/0.1/name"
        },
        "@id": "http://example.org/person",
        "name": "Alice"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      final triple = graph.triples.first;
      expect(triple.object, isA<LiteralTerm>());
      final literal = triple.object as LiteralTerm;
      expect(literal.value, equals('Alice'));
      expect(literal.language, equals('en'));
    });

    test('explicit @language on value overrides default', () {
      final input = '''
      {
        "@context": {
          "@language": "en",
          "name": "http://xmlns.com/foaf/0.1/name"
        },
        "@id": "http://example.org/person",
        "name": {"@value": "Alice", "@language": "de"}
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      final literal = graph.triples.first.object as LiteralTerm;
      expect(literal.language, equals('de'));
    });

    test('@value with @type overrides default language', () {
      final input = '''
      {
        "@context": {
          "@language": "en",
          "age": "http://schema.org/age"
        },
        "@id": "http://example.org/person",
        "age": {"@value": "42", "@type": "http://www.w3.org/2001/XMLSchema#integer"}
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      final literal = graph.triples.first.object as LiteralTerm;
      expect(literal.value, equals('42'));
      expect(literal.language, isNull);
      expect(literal.datatype,
          equals(IriTerm('http://www.w3.org/2001/XMLSchema#integer')));
    });

    test('@language: null disables default language for a term', () {
      final input = '''
      {
        "@context": {
          "@language": "en",
          "code": {"@id": "http://example.org/code", "@language": null}
        },
        "@id": "http://example.org/thing",
        "code": "ABC123"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      final literal = graph.triples.first.object as LiteralTerm;
      expect(literal.value, equals('ABC123'));
      expect(literal.language, isNull);
    });

    test('default language does not apply to IRI-coerced values', () {
      final input = '''
      {
        "@context": {
          "@language": "en",
          "homepage": {"@id": "http://xmlns.com/foaf/0.1/homepage", "@type": "@id"}
        },
        "@id": "http://example.org/person",
        "homepage": "http://example.org/alice"
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      // Should be an IRI, not a language-tagged literal
      expect(graph.triples.first.object, isA<IriTerm>());
    });

    test('rdfDirection i18n-datatype emits directional datatype literal', () {
      final input = '''
      {
        "@id": "http://example.org/person",
        "http://example.org/label": {
          "@value": "no language",
          "@direction": "rtl"
        }
      }
      ''';

      final dataset = JsonLdDecoder(
        options: const JsonLdDecoderOptions(rdfDirection: RdfDirection.i18nDatatype),
      ).convert(input);
      final graph = dataset.defaultGraph;

      expect(graph.triples, hasLength(1));
      final literal = graph.triples.first.object as LiteralTerm;
      expect(literal.value, equals('no language'));
      expect(
        literal.datatype,
        equals(IriTerm('https://www.w3.org/ns/i18n#_rtl')),
      );
      expect(literal.language, isNull);
    });

    test('rdfDirection compound-literal emits compound node with language', () {
      final input = '''
      {
        "@id": "http://example.org/person",
        "http://example.org/label": {
          "@value": "en-US",
          "@language": "en-US",
          "@direction": "rtl"
        }
      }
      ''';

      final dataset = JsonLdDecoder(
        options: const JsonLdDecoderOptions(rdfDirection: RdfDirection.compoundLiteral),
      ).convert(input);
      final graph = dataset.defaultGraph;

      expect(graph.triples, hasLength(4));

      final labelTriples = graph.findTriples(
        subject: IriTerm('http://example.org/person'),
        predicate: IriTerm('http://example.org/label'),
      );
      expect(labelTriples, hasLength(1));

      final compoundNode = labelTriples.first.object;
      expect(compoundNode, isA<BlankNodeTerm>());

      expect(
        graph.findTriples(
          subject: compoundNode as RdfSubject,
          predicate:
              IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#direction'),
          object: LiteralTerm.string('rtl'),
        ),
        hasLength(1),
      );
      expect(
        graph.findTriples(
          subject: compoundNode,
          predicate:
              IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#language'),
          object: LiteralTerm.string('en-us'),
        ),
        hasLength(1),
      );
      expect(
        graph.findTriples(
          subject: compoundNode,
          predicate:
              IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#value'),
          object: LiteralTerm.string('en-US'),
        ),
        hasLength(1),
      );
    });
  });

  group('@list (RDF Collections)', () {
    test('creates RDF collection from @list array', () {
      final input = '''
      {
        "@context": {
          "items": "http://example.org/items"
        },
        "@id": "http://example.org/thing",
        "items": {"@list": ["a", "b", "c"]}
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      // Should have: thing -items-> _:b1
      //   _:b1 rdf:first "a" . _:b1 rdf:rest _:b2 .
      //   _:b2 rdf:first "b" . _:b2 rdf:rest _:b3 .
      //   _:b3 rdf:first "c" . _:b3 rdf:rest rdf:nil .
      // = 1 + 6 = 7 triples
      expect(graph.triples, hasLength(7));

      // Verify the collection head is linked
      final itemsTriples = graph.findTriples(
        subject: IriTerm('http://example.org/thing'),
        predicate: IriTerm('http://example.org/items'),
      );
      expect(itemsTriples, hasLength(1));

      // Verify rdf:nil is present
      final nilTriples = graph.findTriples(
        object: IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#nil'),
      );
      expect(nilTriples, hasLength(1));
    });

    test('empty @list generates rdf:nil directly', () {
      final input = '''
      {
        "@context": {
          "items": "http://example.org/items"
        },
        "@id": "http://example.org/thing",
        "items": {"@list": []}
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      expect(graph.triples, hasLength(1));
      final triple = graph.triples.first;
      expect(triple.object,
          equals(IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#nil')));
    });

    test('@list with single item', () {
      final input = '''
      {
        "@context": {
          "items": "http://example.org/items"
        },
        "@id": "http://example.org/thing",
        "items": {"@list": ["only"]}
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      // thing -> items -> _:b1
      // _:b1 rdf:first "only" . _:b1 rdf:rest rdf:nil .
      expect(graph.triples, hasLength(3));
    });

    test('@list with IRI items', () {
      final input = '''
      {
        "@context": {
          "members": {"@id": "http://example.org/members", "@type": "@id"}
        },
        "@id": "http://example.org/group",
        "members": {"@list": ["http://example.org/alice", "http://example.org/bob"]}
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      // Verify first items are IRIs
      final firstTriples = graph.findTriples(
        predicate: IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#first'),
      );
      expect(firstTriples, hasLength(2));
      for (final t in firstTriples) {
        expect(t.object, isA<IriTerm>());
      }
    });
  });

  group('@set', () {
    test('@set is treated as simple array', () {
      final input = '''
      {
        "@context": {
          "tags": "http://example.org/tags"
        },
        "@id": "http://example.org/thing",
        "tags": {"@set": ["a", "b"]}
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      // @set just means "array" — produces 2 individual triples
      expect(graph.triples, hasLength(2));
      final triples =
          graph.findTriples(predicate: IriTerm('http://example.org/tags'));
      expect(triples, hasLength(2));
    });

    test('empty @set produces no triples', () {
      final input = '''
      {
        "@context": {
          "tags": "http://example.org/tags"
        },
        "@id": "http://example.org/thing",
        "tags": {"@set": []}
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      expect(graph.triples, isEmpty);
    });
  });

  group('@reverse', () {
    test('@reverse in node body swaps subject and object', () {
      final input = '''
      {
        "@id": "http://example.org/alice",
        "@reverse": {
          "http://xmlns.com/foaf/0.1/knows": {
            "@id": "http://example.org/bob"
          }
        }
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      // Bob knows Alice (reversed)
      expect(graph.triples, hasLength(1));
      final triple = graph.triples.first;
      expect(triple.subject, equals(IriTerm('http://example.org/bob')));
      expect(
          triple.predicate, equals(IriTerm('http://xmlns.com/foaf/0.1/knows')));
      expect(triple.object, equals(IriTerm('http://example.org/alice')));
    });

    test('@reverse term definition in context', () {
      final input = '''
      {
        "@context": {
          "isKnownBy": {"@reverse": "http://xmlns.com/foaf/0.1/knows"}
        },
        "@id": "http://example.org/alice",
        "isKnownBy": {"@id": "http://example.org/bob"}
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      // Bob knows Alice (reversed through term definition)
      expect(graph.triples, hasLength(1));
      final triple = graph.triples.first;
      expect(triple.subject, equals(IriTerm('http://example.org/bob')));
      expect(
          triple.predicate, equals(IriTerm('http://xmlns.com/foaf/0.1/knows')));
      expect(triple.object, equals(IriTerm('http://example.org/alice')));
    });

    test('@reverse with multiple objects', () {
      final input = '''
      {
        "@id": "http://example.org/alice",
        "@reverse": {
          "http://xmlns.com/foaf/0.1/knows": [
            {"@id": "http://example.org/bob"},
            {"@id": "http://example.org/charlie"}
          ]
        }
      }
      ''';

      final dataset = JsonLdDecoder().convert(input);
      final graph = dataset.defaultGraph;

      expect(graph.triples, hasLength(2));
      // Both Bob and Charlie know Alice
      for (final triple in graph.triples) {
        expect(triple.predicate,
            equals(IriTerm('http://xmlns.com/foaf/0.1/knows')));
        expect(triple.object, equals(IriTerm('http://example.org/alice')));
      }
    });
  });

  group('Integration: manifest-like document', () {
    test('parses a simplified manifest structure', () {
      // Simplified version of the W3C JSON-LD test manifest structure
      final input = '''
      {
        "@context": {
          "@vocab": "https://w3c.github.io/json-ld-api/tests/vocab#",
          "mf": "http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#",
          "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
          "input": {"@id": "mf:action", "@type": "@id"},
          "expect": {"@id": "mf:result", "@type": "@id"},
          "name": "mf:name",
          "purpose": "rdfs:comment",
          "sequence": {"@id": "mf:entries", "@type": "@id", "@container": "@list"}
        },
        "@id": "",
        "@type": "mf:Manifest",
        "name": "Test Suite",
        "sequence": [
          {
            "@id": "#t001",
            "@type": ["PositiveEvaluationTest", "ToRDFTest"],
            "name": "Test one",
            "purpose": "Tests the first thing",
            "input": "tests/0001-in.jsonld",
            "expect": "tests/0001-out.nq"
          }
        ]
      }
      ''';

      final dataset = JsonLdDecoder().convert(input,
          documentUrl: 'https://w3c.github.io/json-ld-api/tests/manifest');
      final graph = dataset.defaultGraph;

      // Manifest should have rdf:type
      final typeTriples = graph.findTriples(
        subject: IriTerm('https://w3c.github.io/json-ld-api/tests/manifest'),
        predicate: IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
      );
      expect(typeTriples, hasLength(1));
      expect(
          typeTriples.first.object,
          equals(IriTerm(
              'http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#Manifest')));

      // "name" should be expanded to mf:name
      final nameTriples = graph.findTriples(
        predicate: IriTerm(
            'http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#name'),
      );
      expect(nameTriples.length, greaterThanOrEqualTo(1));

      // sequence should be an RDF list (mf:entries)
      final entriesTriples = graph.findTriples(
        subject: IriTerm('https://w3c.github.io/json-ld-api/tests/manifest'),
        predicate: IriTerm(
            'http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#entries'),
      );
      expect(entriesTriples, hasLength(1));

      // input should be expanded to mf:action and coerced to IRI
      final actionTriples = graph.findTriples(
        predicate: IriTerm(
            'http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#action'),
      );
      expect(actionTriples, hasLength(1));
      expect(actionTriples.first.object, isA<IriTerm>());

      // "purpose" expanded to rdfs:comment
      final commentTriples = graph.findTriples(
        predicate: IriTerm('http://www.w3.org/2000/01/rdf-schema#comment'),
      );
      expect(commentTriples, hasLength(1));

      // @type "PositiveEvaluationTest" expanded via @vocab
      final testTypes = graph.findTriples(
        subject:
            IriTerm('https://w3c.github.io/json-ld-api/tests/manifest#t001'),
        predicate: IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
      );
      expect(testTypes, hasLength(2));
      final typeIris =
          testTypes.map((t) => (t.object as IriTerm).value).toSet();
      expect(
          typeIris,
          contains(
              'https://w3c.github.io/json-ld-api/tests/vocab#PositiveEvaluationTest'));
      expect(typeIris,
          contains('https://w3c.github.io/json-ld-api/tests/vocab#ToRDFTest'));
    });
  });
}
