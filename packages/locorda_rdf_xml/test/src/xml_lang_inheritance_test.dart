import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_xml/src/rdfxml_parser.dart';
import 'package:test/test.dart';

/// Tests for xml:lang inheritance from ancestor elements per the XML spec.
///
/// The XML specification states that xml:lang applies to all descendant
/// elements unless overridden. The RDF/XML spec uses this to determine
/// language tags for literal values.
void main() {
  group('xml:lang inheritance', () {
    group('property element content', () {
      test('inherits xml:lang from rdf:Description', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/node"
                             xml:lang="fr">
              <eg:property>chat</eg:property>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        expect(triples, hasLength(1));
        expect(
          triples[0].object,
          equals(LiteralTerm.withLanguage('chat', 'fr')),
        );
      });

      test('inherits xml:lang from rdf:RDF (2 levels deep)', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/"
                   xml:lang="de">
            <rdf:Description rdf:about="http://example.org/node">
              <eg:property>Katze</eg:property>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        expect(triples, hasLength(1));
        expect(
          triples[0].object,
          equals(LiteralTerm.withLanguage('Katze', 'de')),
        );
      });

      test('property element xml:lang overrides ancestor', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/"
                   xml:lang="en">
            <rdf:Description rdf:about="http://example.org/node">
              <eg:property xml:lang="fr">chat</eg:property>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        expect(triples, hasLength(1));
        expect(
          triples[0].object,
          equals(LiteralTerm.withLanguage('chat', 'fr')),
        );
      });

      test('xml:lang="" resets language scope', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/"
                   xml:lang="en">
            <rdf:Description rdf:about="http://example.org/node"
                             xml:lang="">
              <eg:property>no language</eg:property>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        expect(triples, hasLength(1));
        expect(triples[0].object, equals(LiteralTerm.string('no language')));
      });

      test('xml:lang="" on property element resets language', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/"
                   xml:lang="en">
            <rdf:Description rdf:about="http://example.org/node">
              <eg:property xml:lang="">no language</eg:property>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        expect(triples, hasLength(1));
        expect(triples[0].object, equals(LiteralTerm.string('no language')));
      });

      test('no xml:lang anywhere produces untagged literal', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/node">
              <eg:property>chat</eg:property>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        expect(triples, hasLength(1));
        expect(triples[0].object, equals(LiteralTerm.string('chat')));
      });
    });

    group('property attributes on node elements', () {
      test('inherits xml:lang from rdf:Description', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/node"
                             xml:lang="fr"
                             eg:property="chat" />
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        expect(triples, hasLength(1));
        expect(
          triples[0].object,
          equals(LiteralTerm.withLanguage('chat', 'fr')),
        );
      });

      test('inherits xml:lang from rdf:RDF for property attributes', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/"
                   xml:lang="de">
            <rdf:Description rdf:about="http://example.org/node"
                             eg:property="Katze" />
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        expect(triples, hasLength(1));
        expect(
          triples[0].object,
          equals(LiteralTerm.withLanguage('Katze', 'de')),
        );
      });
    });

    group('parseType="Literal" ignores xml:lang', () {
      test('xml:lang on ancestor does not apply to XML literals', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/"
                   xml:lang="fr">
            <rdf:Description rdf:about="http://example.org/node">
              <eg:property rdf:parseType="Literal">chat</eg:property>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        expect(triples, hasLength(1));
        final obj = triples[0].object as LiteralTerm;
        expect(
          obj.datatype,
          equals(
            const IriTerm(
              'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral',
            ),
          ),
        );
        // XMLLiteral should NOT have a language tag, regardless of xml:lang
        expect(obj.language, isNull);
      });

      test('xml:lang on property element does not apply to XML literals', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/node">
              <eg:property xml:lang="fr"
                           rdf:parseType="Literal">chat</eg:property>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        expect(triples, hasLength(1));
        final obj = triples[0].object as LiteralTerm;
        expect(
          obj.datatype,
          equals(
            const IriTerm(
              'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral',
            ),
          ),
        );
        expect(obj.language, isNull);
      });
    });
  });
}
