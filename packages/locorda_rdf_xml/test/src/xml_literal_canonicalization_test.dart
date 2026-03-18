import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_xml/src/rdfxml_parser.dart';
import 'package:locorda_rdf_xml/src/rdfxml_constants.dart';
import 'package:test/test.dart';

/// Tests for XML literal canonicalization (C14N) in parseType="Literal".
///
/// Validates that:
/// - In-scope namespace declarations from ancestors are propagated to
///   top-level elements inside the literal
/// - Self-closing tags are expanded to open/close form
/// - Text content and attribute values are properly escaped
/// - Namespace order follows document order of ancestor declarations
void main() {
  group('XML literal canonicalization', () {
    group('namespace propagation', () {
      test(
        'propagates ancestor namespace declarations to top-level elements',
        () {
          final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/a">
              <eg:prop rdf:parseType="Literal"><br /></eg:prop>
            </rdf:Description>
          </rdf:RDF>
        ''';

          final triples = RdfXmlParser(xml).parse();

          expect(triples, hasLength(1));
          final obj = triples[0].object as LiteralTerm;
          expect(obj.datatype, equals(RdfTerms.xmlLiteral));
          // Inherited namespaces should appear on the top-level <br> element
          expect(obj.value, contains('xmlns:rdf='));
          expect(obj.value, contains('xmlns:eg='));
        },
      );

      test('preserves document order of namespace declarations', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/a">
              <eg:prop rdf:parseType="Literal"><br /></eg:prop>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        final literal = (triples[0].object as LiteralTerm).value;
        final rdfIdx = literal.indexOf('xmlns:rdf=');
        final egIdx = literal.indexOf('xmlns:eg=');
        // rdf was declared before eg in the source document
        expect(
          rdfIdx,
          lessThan(egIdx),
          reason: 'namespace order should follow document order',
        );
      });

      test(
        'does not duplicate namespace already declared on literal element',
        () {
          final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/a">
              <eg:prop rdf:parseType="Literal">
                <span xmlns:eg="http://example.org/">text</span>
              </eg:prop>
            </rdf:Description>
          </rdf:RDF>
        ''';

          final triples = RdfXmlParser(xml).parse();

          final literal = (triples[0].object as LiteralTerm).value;
          // eg should appear exactly once (from the element's own declaration)
          final egCount = 'xmlns:eg='.allMatches(literal).length;
          expect(
            egCount,
            equals(1),
            reason: 'inherited ns should not duplicate element ns',
          );
        },
      );

      test('propagates namespaces from multiple ancestors', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/a"
                             xmlns:dc="http://purl.org/dc/elements/1.1/">
              <eg:prop rdf:parseType="Literal"><br /></eg:prop>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        final literal = (triples[0].object as LiteralTerm).value;
        expect(literal, contains('xmlns:rdf='));
        expect(literal, contains('xmlns:eg='));
        expect(literal, contains('xmlns:dc='));
      });
    });

    group('tag serialization', () {
      test('expands self-closing tags', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/a">
              <eg:prop rdf:parseType="Literal"><br /></eg:prop>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        final literal = (triples[0].object as LiteralTerm).value;
        expect(literal, contains('</br>'));
        expect(literal, isNot(contains('/>')));
      });

      test('preserves nested element structure', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/a">
              <eg:prop rdf:parseType="Literal"><div><span>text</span></div></eg:prop>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        final literal = (triples[0].object as LiteralTerm).value;
        // Only the top-level element gets inherited namespaces
        expect(literal, contains('<div'));
        expect(literal, contains('<span>text</span>'));
        expect(literal, contains('</div>'));
        // Only the top-level <div> should have inherited namespaces
        final spanPart = literal.substring(literal.indexOf('<span'));
        expect(spanPart, isNot(contains('xmlns:rdf=')));
      });

      test('handles plain text content', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/a">
              <eg:prop rdf:parseType="Literal">plain text</eg:prop>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        final literal = (triples[0].object as LiteralTerm).value;
        expect(literal, equals('plain text'));
      });
    });

    group('escaping', () {
      test('escapes special characters in text content', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/a">
              <eg:prop rdf:parseType="Literal">a &amp; b &lt; c &gt; d</eg:prop>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        final literal = (triples[0].object as LiteralTerm).value;
        expect(literal, contains('&amp;'));
        expect(literal, contains('&lt;'));
        expect(literal, contains('&gt;'));
      });

      test('escapes special characters in attribute values', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/a">
              <eg:prop rdf:parseType="Literal"><span title="a &amp; b">text</span></eg:prop>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        final literal = (triples[0].object as LiteralTerm).value;
        expect(literal, contains('title="a &amp; b"'));
      });
    });

    group('empty content', () {
      test('empty parseType="Literal" produces empty string', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/a">
              <eg:prop rdf:parseType="Literal"></eg:prop>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        final literal = (triples[0].object as LiteralTerm).value;
        expect(literal, equals(''));
      });
    });

    group('CDATA handling', () {
      test('CDATA sections are converted to escaped text content', () {
        // CDATA inside parseType="Literal" must be converted to regular
        // escaped text per Canonical XML.
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/a">
              <eg:prop rdf:parseType="Literal"><![CDATA[a < b & c]]></eg:prop>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        final literal = (triples[0].object as LiteralTerm).value;
        expect(literal, equals('a &lt; b &amp; c'));
      });

      test('mixed CDATA and text content', () {
        final xml = '''
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:eg="http://example.org/">
            <rdf:Description rdf:about="http://example.org/a">
              <eg:prop rdf:parseType="Literal">before<![CDATA[<inner>]]>after</eg:prop>
            </rdf:Description>
          </rdf:RDF>
        ''';

        final triples = RdfXmlParser(xml).parse();

        final literal = (triples[0].object as LiteralTerm).value;
        expect(literal, equals('before&lt;inner&gt;after'));
      });
    });
  });
}
