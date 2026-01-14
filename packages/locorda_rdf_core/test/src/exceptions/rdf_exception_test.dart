import 'package:locorda_rdf_core/src/exceptions/rdf_exception.dart';
import 'package:test/test.dart';

void main() {
  group('RdfException', () {
    test('constructor initializes properties correctly', () {
      const message = 'Test error message';
      final cause = Exception('Original error');
      final source = SourceLocation(line: 10, column: 20, source: 'test.ttl');

      final exception = RdfException(message, cause: cause, source: source);

      expect(exception.message, equals(message));
      expect(exception.cause, equals(cause));
      expect(exception.source, equals(source));
    });

    test('toString returns formatted message without source or cause', () {
      const exception = RdfException('Test error message');
      expect(exception.toString(), equals('RdfException: Test error message'));
    });

    test('toString includes source when available', () {
      final source = SourceLocation(line: 10, column: 20, source: 'test.ttl');
      final exception = RdfException('Test error message', source: source);

      expect(
        exception.toString(),
        equals('RdfException: Test error message at test.ttl:11:21'),
      );
    });

    test('toString includes cause when available', () {
      final cause = Exception('Original error');
      final exception = RdfException('Test error message', cause: cause);

      expect(
        exception.toString(),
        equals(
          'RdfException: Test error message\nCaused by: Exception: Original error',
        ),
      );
    });

    test('toString includes both source and cause when available', () {
      final cause = Exception('Original error');
      final source = SourceLocation(line: 10, column: 20, source: 'test.ttl');
      final exception = RdfException(
        'Test error message',
        cause: cause,
        source: source,
      );

      expect(
        exception.toString(),
        equals(
          'RdfException: Test error message at test.ttl:11:21\nCaused by: Exception: Original error',
        ),
      );
    });
  });

  group('SourceLocation', () {
    test('constructor initializes properties correctly', () {
      const location = SourceLocation(
        line: 5,
        column: 10,
        source: 'test.ttl',
        context: 'problematic content',
      );

      expect(location.line, equals(5));
      expect(location.column, equals(10));
      expect(location.source, equals('test.ttl'));
      expect(location.context, equals('problematic content'));
    });

    test('toString converts to 1-based line and column numbers', () {
      const location = SourceLocation(line: 5, column: 10);
      expect(location.toString(), equals('6:11'));
    });

    test('toString includes source when available', () {
      const location = SourceLocation(line: 5, column: 10, source: 'test.ttl');
      expect(location.toString(), equals('test.ttl:6:11'));
    });

    test('toString includes context when available', () {
      const location = SourceLocation(
        line: 5,
        column: 10,
        context: 'problematic content',
      );
      expect(location.toString(), equals('6:11 "problematic content"'));
    });

    test('toString includes both source and context when available', () {
      const location = SourceLocation(
        line: 5,
        column: 10,
        source: 'test.ttl',
        context: 'problematic content',
      );
      expect(
        location.toString(),
        equals('test.ttl:6:11 "problematic content"'),
      );
    });
  });
}
