import 'package:rdf_core/src/exceptions/rdf_exception.dart';
import 'package:rdf_core/src/exceptions/rdf_validation_exception.dart';
import 'package:test/test.dart';

void main() {
  group('RdfValidationException', () {
    test('constructor initializes properties correctly', () {
      const message = 'Validation error';
      final cause = Exception('Data inconsistency');
      final source = SourceLocation(line: 0, column: 0, source: 'graph node');

      final exception = RdfValidationException(
        message,
        cause: cause,
        source: source,
      );

      expect(exception.message, equals(message));
      expect(exception.cause, equals(cause));
      expect(exception.source, equals(source));
    });

    test('toString formats message correctly', () {
      const exception = RdfValidationException('Validation error');
      expect(
        exception.toString(),
        equals('RdfValidationException: Validation error'),
      );
    });

    test('toString includes source when available', () {
      final source = SourceLocation(line: 0, column: 0, source: 'graph node');
      final exception = RdfValidationException(
        'Validation error',
        source: source,
      );

      expect(
        exception.toString(),
        equals('RdfValidationException: Validation error at graph node:1:1'),
      );
    });

    test('toString includes cause when available', () {
      final cause = Exception('Data inconsistency');
      final exception = RdfValidationException(
        'Validation error',
        cause: cause,
      );

      expect(
        exception.toString(),
        equals(
          'RdfValidationException: Validation error\nCaused by: Exception: Data inconsistency',
        ),
      );
    });
  });

  group('RdfConstraintViolationException', () {
    test('constructor initializes properties correctly', () {
      const message = 'Constraint violated';
      const constraint = 'cardinality';
      final cause = Exception('Too many values');

      final exception = RdfConstraintViolationException(
        message,
        constraint: constraint,
        cause: cause,
      );

      expect(exception.message, equals(message));
      expect(exception.constraint, equals(constraint));
      expect(exception.cause, equals(cause));
    });

    test('toString formats message correctly', () {
      const exception = RdfConstraintViolationException(
        'Constraint violated',
        constraint: 'cardinality',
      );

      expect(
        exception.toString(),
        equals(
          'RdfConstraintViolationException: cardinality - Constraint violated',
        ),
      );
    });

    test('toString includes all components when available', () {
      final cause = Exception('Too many values');
      final source = SourceLocation(line: 5, column: 10, source: 'graph node');
      final exception = RdfConstraintViolationException(
        'Constraint violated',
        constraint: 'cardinality',
        cause: cause,
        source: source,
      );

      expect(
        exception.toString(),
        equals(
          'RdfConstraintViolationException: cardinality - Constraint violated at graph node:6:11\nCaused by: Exception: Too many values',
        ),
      );
    });
  });

  group('RdfTypeException', () {
    test('constructor initializes properties correctly', () {
      const message = 'Type error';
      const expectedType = 'xsd:integer';
      const actualType = 'xsd:string';

      final exception = RdfTypeException(
        message,
        expectedType: expectedType,
        actualType: actualType,
      );

      expect(exception.message, equals(message));
      expect(exception.expectedType, equals(expectedType));
      expect(exception.actualType, equals(actualType));
    });

    test('constructor accepts null for actualType', () {
      const message = 'Type error';
      const expectedType = 'xsd:integer';

      final exception = RdfTypeException(message, expectedType: expectedType);

      expect(exception.message, equals(message));
      expect(exception.expectedType, equals(expectedType));
      expect(exception.actualType, isNull);
    });

    test('toString formats message with actualType correctly', () {
      const exception = RdfTypeException(
        'Type error',
        expectedType: 'xsd:integer',
        actualType: 'xsd:string',
      );

      expect(
        exception.toString(),
        equals(
          'RdfTypeException: Expected: xsd:integer, Found: xsd:string - Type error',
        ),
      );
    });

    test('toString formats message without actualType correctly', () {
      const exception = RdfTypeException(
        'Type error',
        expectedType: 'xsd:integer',
      );

      expect(
        exception.toString(),
        equals('RdfTypeException: Expected: xsd:integer - Type error'),
      );
    });

    test('toString includes all components when available', () {
      final cause = Exception('Conversion error');
      final source = SourceLocation(
        line: 5,
        column: 10,
        source: 'literal node',
      );
      final exception = RdfTypeException(
        'Type error',
        expectedType: 'xsd:integer',
        actualType: 'xsd:string',
        cause: cause,
        source: source,
      );

      expect(
        exception.toString(),
        equals(
          'RdfTypeException: Expected: xsd:integer, Found: xsd:string - Type error at literal node:6:11\nCaused by: Exception: Conversion error',
        ),
      );
    });
  });

  group('RdfShapeValidationException', () {
    test('constructor initializes properties correctly', () {
      const message = 'Shape validation failed';
      const shapeId = 'http://example.org/shapes#PersonShape';
      const targetNode = 'http://example.org/people/john';

      final exception = RdfShapeValidationException(
        message,
        shapeId: shapeId,
        targetNode: targetNode,
      );

      expect(exception.message, equals(message));
      expect(exception.shapeId, equals(shapeId));
      expect(exception.targetNode, equals(targetNode));
    });

    test('toString formats message correctly', () {
      const exception = RdfShapeValidationException(
        'Shape validation failed',
        shapeId: 'http://example.org/shapes#PersonShape',
        targetNode: 'http://example.org/people/john',
      );

      expect(
        exception.toString(),
        equals(
          'RdfShapeValidationException: Node http://example.org/people/john failed to conform to shape http://example.org/shapes#PersonShape - Shape validation failed',
        ),
      );
    });

    test('toString includes all components when available', () {
      final cause = Exception('Missing required property');
      final source = SourceLocation(
        line: 0,
        column: 0,
        source: 'validation context',
      );
      final exception = RdfShapeValidationException(
        'Shape validation failed',
        shapeId: 'http://example.org/shapes#PersonShape',
        targetNode: 'http://example.org/people/john',
        cause: cause,
        source: source,
      );

      expect(
        exception.toString(),
        equals(
          'RdfShapeValidationException: Node http://example.org/people/john failed to conform to shape http://example.org/shapes#PersonShape - Shape validation failed at validation context:1:1\nCaused by: Exception: Missing required property',
        ),
      );
    });
  });
}
