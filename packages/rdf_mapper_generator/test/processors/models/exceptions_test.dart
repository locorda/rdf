import 'package:rdf_mapper_generator/src/processors/models/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('ParseException', () {
    late ParseException testInstance;
    late ParseException identicalInstance;
    late ParseException differentInstance;

    setUp(() {
      testInstance = ParseException('Test error message');
      identicalInstance = ParseException('Test error message');
      differentInstance = ParseException('Different error message');
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns true for same instance', () {
      expect(testInstance, equals(testInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-ParseException instances', () {
      expect(testInstance, isNot(equals('not a ParseException')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('hashCode is different for different instances', () {
      expect(testInstance.hashCode, isNot(equals(differentInstance.hashCode)));
    });

    test('toString returns the message', () {
      expect(testInstance.toString(), equals('Test error message'));
    });

    test('implements Exception interface', () {
      expect(testInstance, isA<Exception>());
    });
  });
}
