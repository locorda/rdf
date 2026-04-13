import 'dart:convert';

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_jsonld/jsonld.dart';
import 'package:test/test.dart';

void main() {
  group('JSON-LD Encoder — Literal @type compaction', () {
    late JsonLdEncoder encoder;

    setUp(() {
      encoder = JsonLdEncoder(namespaceMappings: RdfNamespaceMappings());
    });

    /// Encodes a single triple (ex:subject, ex:predicate, [literal]) and
    /// returns the parsed JSON map so we can inspect the output structure.
    Map<String, dynamic> _encodeAndDecode(LiteralTerm literal) {
      final subject = IriTerm('http://example.org/subject');
      final predicate = IriTerm('http://example.org/predicate');
      final graph = RdfGraph(
        triples: [Triple(subject, predicate, literal)],
      );
      final dataset = RdfDataset(defaultGraph: graph, namedGraphs: const {});
      return jsonDecode(encoder.convert(dataset)) as Map<String, dynamic>;
    }

    test('emits compact xsd: prefix for non-native-type literals', () {
      // dateTime is not natively handled (not converted to a JSON number/bool)
      final literal = LiteralTerm.typed(
        '2025-04-23T12:00:00Z',
        'dateTime',
      );

      final json = _encodeAndDecode(literal);

      // @context must include the xsd prefix
      final context = json['@context'] as Map<String, dynamic>;
      expect(context.containsKey('xsd'), isTrue,
          reason: 'xsd prefix should be declared in @context');

      // The property value should use compact "xsd:dateTime" for @type,
      // not the full IRI.
      final value = json['ex:predicate'] as Map<String, dynamic>?;
      expect(value, isNotNull,
          reason:
              'predicate should be compacted via the auto-generated ex: prefix');
      expect(value!['@type'], equals('xsd:dateTime'),
          reason:
              'literal @type must use compact prefix notation, not the full IRI');
    });

    test('emits compact prefix for a fully custom datatype', () {
      final literal = LiteralTerm.typed(
        'some-value',
        'http://example.org/CustomType',
      );
      final dataset = RdfDataset(
        defaultGraph: RdfGraph(triples: [
          Triple(
            IriTerm('http://example.org/subject'),
            IriTerm('http://example.org/predicate'),
            literal,
          ),
        ]),
        namedGraphs: const {},
      );

      final json = jsonDecode(encoder.convert(dataset)) as Map<String, dynamic>;

      // The literal @type is in the same http://example.org/ namespace, so
      // it should be compacted using whatever prefix is generated for it.
      final context = json['@context'] as Map<String, dynamic>;
      final prefix =
          context.entries.firstWhere((e) => e.value == 'http://example.org/');

      final value = json['${prefix.key}:predicate'] as Map<String, dynamic>?;
      expect(value, isNotNull);
      // @type should be compacted, not the raw full IRI
      expect(
        value!['@type'],
        isNot(equals('http://example.org/CustomType')),
        reason: 'literal @type should be a compact IRI, not the full IRI',
      );
      expect(
        value['@type'],
        endsWith(':CustomType'),
        reason: 'literal @type should end with the local name after a colon',
      );
    });

    test('xsd:string literals are emitted as plain JSON strings', () {
      final json = _encodeAndDecode(LiteralTerm.string('hello'));
      // The value should be a bare string, not an object
      expect(json['ex:predicate'], equals('hello'));
    });

    test('xsd:integer literals are emitted as JSON numbers', () {
      final json = _encodeAndDecode(LiteralTerm.typed('42', 'integer'));
      expect(json['ex:predicate'], equals(42));
    });

    test('xsd:boolean literals are emitted as JSON booleans', () {
      final json = _encodeAndDecode(LiteralTerm.typed('true', 'boolean'));
      expect(json['ex:predicate'], equals(true));
    });
  });
}
