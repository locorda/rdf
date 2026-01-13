import 'package:rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:test/test.dart';

void main() {
  group('MapperRefInfo', () {
    late MapperRefInfo<dynamic> testInstance;
    late MapperRefInfo<dynamic> identicalInstance;
    late MapperRefInfo<dynamic> differentInstance;

    setUp(() {
      testInstance = const MapperRefInfo<dynamic>(
        name: 'TestMapper',
        type: null,
        instance: null,
      );

      identicalInstance = const MapperRefInfo<dynamic>(
        name: 'TestMapper',
        type: null,
        instance: null,
      );

      differentInstance = const MapperRefInfo<dynamic>(
        name: 'DifferentMapper',
        type: null,
        instance: null,
      );
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-MapperRefInfo instances', () {
      expect(testInstance, isNot(equals('not a MapperRefInfo')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('hashCode is different for different instances', () {
      expect(testInstance.hashCode, isNot(equals(differentInstance.hashCode)));
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('MapperRefInfo{'));
      expect(result, contains('name: TestMapper'));
      expect(result, contains('type: null'));
      expect(result, contains('instance: null'));
    });
  });

  group('BaseMappingInfo', () {
    late BaseMappingInfo<dynamic> testInstance;
    late BaseMappingInfo<dynamic> identicalInstance;
    late BaseMappingInfo<dynamic> differentInstance;

    setUp(() {
      const mapper = MapperRefInfo<dynamic>(
        name: 'TestMapper',
        type: null,
        instance: null,
      );

      testInstance = const BaseMappingInfo<dynamic>(mapper: mapper);
      identicalInstance = const BaseMappingInfo<dynamic>(mapper: mapper);
      differentInstance = const BaseMappingInfo<dynamic>(mapper: null);
    });

    test('equals returns true for identical instances', () {
      expect(testInstance, equals(identicalInstance));
    });

    test('equals returns false for different instances', () {
      expect(testInstance, isNot(equals(differentInstance)));
    });

    test('equals returns false for non-BaseMappingInfo instances', () {
      expect(testInstance, isNot(equals('not a BaseMappingInfo')));
    });

    test('hashCode is consistent for identical instances', () {
      expect(testInstance.hashCode, equals(identicalInstance.hashCode));
    });

    test('hashCode is different for different instances', () {
      expect(testInstance.hashCode, isNot(equals(differentInstance.hashCode)));
    });

    test('toString returns formatted string representation', () {
      final result = testInstance.toString();
      expect(result, contains('BaseMappingInfo{'));
      expect(result, contains('mapper:'));
    });
  });
}
