import 'package:locorda_rdf_canonicalization/src/canonical/canonical_util.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';
import 'package:locorda_rdf_canonicalization/src/canonical/quad_serializer.dart';

void main() {
  group('QuadSerializer - serializeForFirstDegreeHashing', () {
    late QuadSerializer serializer;
    late BlankNodeTerm blankNode1;
    late BlankNodeTerm blankNode2;
    late BlankNodeTerm blankNode3;
    late Map<BlankNodeTerm, InputBlankNodeIdentifier> blankNodeIdentifiers;
    setUp(() {
      blankNode1 = BlankNodeTerm();
      blankNode2 = BlankNodeTerm();
      blankNode3 = BlankNodeTerm();
      blankNodeIdentifiers = {
        blankNode1: 'id1',
        blankNode2: 'id2',
        blankNode3: 'id3',
      };
      serializer = QuadSerializer();
    });

    test('should serialize quad with reference blank node as subject', () {
      final quad = Quad(
        blankNode1,
        const IriTerm('http://example.org/predicate'),
        const IriTerm('http://example.org/object'),
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id1');

      expect(
          result,
          equals(
              '_:a <http://example.org/predicate> <http://example.org/object> .\n'));
    });

    test('should serialize quad with reference blank node as object', () {
      final quad = Quad(
        const IriTerm('http://example.org/subject'),
        const IriTerm('http://example.org/predicate'),
        blankNode1,
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id1');

      expect(
          result,
          equals(
              '<http://example.org/subject> <http://example.org/predicate> _:a .\n'));
    });

    test('should serialize quad with non-reference blank node as _:z', () {
      final quad = Quad(
        blankNode1,
        const IriTerm('http://example.org/predicate'),
        blankNode2,
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id1');

      expect(result, equals('_:a <http://example.org/predicate> _:z .\n'));
    });

    test('should serialize quad with unknown blank node as _:z', () {
      final unknownBlankNode = BlankNodeTerm();
      final quad = Quad(
        blankNode1,
        const IriTerm('http://example.org/predicate'),
        unknownBlankNode,
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id1');

      expect(result, equals('_:a <http://example.org/predicate> _:z .\n'));
    });

    test('should serialize quad with reference blank node in graph', () {
      final quad = Quad(
        const IriTerm('http://example.org/subject'),
        const IriTerm('http://example.org/predicate'),
        const IriTerm('http://example.org/object'),
        blankNode1,
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id1');

      expect(
          result,
          equals(
              '<http://example.org/subject> <http://example.org/predicate> <http://example.org/object> _:a .\n'));
    });

    test('should serialize quad with non-reference blank node in graph', () {
      final quad = Quad(
        const IriTerm('http://example.org/subject'),
        const IriTerm('http://example.org/predicate'),
        const IriTerm('http://example.org/object'),
        blankNode2,
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id1');

      expect(
          result,
          equals(
              '<http://example.org/subject> <http://example.org/predicate> <http://example.org/object> _:z .\n'));
    });

    test('should serialize quad with null graph', () {
      final quad = Quad(
        blankNode1,
        const IriTerm('http://example.org/predicate'),
        const IriTerm('http://example.org/object'),
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id1');

      expect(
          result,
          equals(
              '_:a <http://example.org/predicate> <http://example.org/object> .\n'));
    });

    test('should serialize quad with string literal', () {
      final quad = Quad(
        blankNode1,
        const IriTerm('http://example.org/name'),
        LiteralTerm.string('Alice'),
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id1');

      expect(result, equals('_:a <http://example.org/name> "Alice" .\n'));
    });

    test('should serialize quad with integer literal', () {
      final quad = Quad(
        blankNode1,
        const IriTerm('http://example.org/age'),
        LiteralTerm.integer(30),
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id1');

      expect(
          result,
          equals(
              '_:a <http://example.org/age> "30"^^<http://www.w3.org/2001/XMLSchema#integer> .\n'));
    });

    test('should serialize quad with literal with language tag', () {
      final quad = Quad(
        blankNode1,
        const IriTerm('http://example.org/label'),
        LiteralTerm('Hello', language: 'en'),
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id1');

      expect(result, equals('_:a <http://example.org/label> "Hello"@en .\n'));
    });

    test('should escape special characters in literals', () {
      final quad = Quad(
        blankNode1,
        const IriTerm('http://example.org/text'),
        LiteralTerm.string('Line 1\nLine 2\r"Quote"\\ Backslash'),
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id1');

      expect(
          result,
          equals(
              '_:a <http://example.org/text> "Line 1\\nLine 2\\r\\"Quote\\"\\\\\ Backslash" .\n'));
    });

    test('should serialize quad with blank nodes in subject and object', () {
      final quad = Quad(
        blankNode1,
        const IriTerm('http://example.org/predicate'),
        blankNode3,
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id2');

      expect(result, equals('_:z <http://example.org/predicate> _:z .\n'));
    });

    test('should serialize quad with non-reference blank node as subject', () {
      final quad = Quad(
        blankNode2,
        const IriTerm('http://example.org/predicate'),
        const IriTerm('http://example.org/object'),
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id1');

      expect(
          result,
          equals(
              '_:z <http://example.org/predicate> <http://example.org/object> .\n'));
    });

    test('should handle multiple non-reference blank nodes consistently', () {
      final quad = Quad(
        blankNode2,
        const IriTerm('http://example.org/predicate'),
        blankNode3,
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id1');

      expect(result, equals('_:z <http://example.org/predicate> _:z .\n'));
    });

    test(
        'should serialize complex quad with reference and non-reference blank nodes',
        () {
      final quad = Quad(
        blankNode1,
        const IriTerm('http://example.org/knows'),
        blankNode2,
        blankNode3,
      );

      final result =
          serializer.toFirstDegreeNQuad(blankNodeIdentifiers, quad, 'id1');

      expect(result, equals('_:a <http://example.org/knows> _:z _:z .\n'));
    });
  });
}
