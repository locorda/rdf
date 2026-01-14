import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:test/test.dart';

class MockMapper {}

void main() {
  group('MapperRef', () {
    test('creates instance with null values', () {
      final mapperRef = MapperRef<MockMapper>();

      expect(mapperRef.name, isNull);
      expect(mapperRef.type, isNull);
      expect(mapperRef.instance, isNull);
    });

    test('creates instance with name', () {
      const mapperName = 'testMapper';
      final mapperRef = MapperRef<MockMapper>(name: mapperName);

      expect(mapperRef.name, equals(mapperName));
      expect(mapperRef.type, isNull);
      expect(mapperRef.instance, isNull);
    });

    test('creates instance with type', () {
      final mapperRef = MapperRef<MockMapper>(type: MockMapper);

      expect(mapperRef.name, isNull);
      expect(mapperRef.type, equals(MockMapper));
      expect(mapperRef.instance, isNull);
    });

    test('creates instance with instance', () {
      final mockMapper = MockMapper();
      final mapperRef = MapperRef<MockMapper>(instance: mockMapper);

      expect(mapperRef.name, isNull);
      expect(mapperRef.type, isNull);
      expect(mapperRef.instance, equals(mockMapper));
    });

    test('creates instance with all values', () {
      const mapperName = 'testMapper';
      final mockMapper = MockMapper();
      final mapperRef = MapperRef<MockMapper>(
        name: mapperName,
        type: MockMapper,
        instance: mockMapper,
      );

      expect(mapperRef.name, equals(mapperName));
      expect(mapperRef.type, equals(MockMapper));
      expect(mapperRef.instance, equals(mockMapper));
    });
  });
}
