import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:test/test.dart';

class MockItemClass {}

void main() {
  group('RdfMapEntry', () {
    test('constructor sets item class', () {
      final annotation = RdfMapEntry(MockItemClass);

      expect(annotation.itemClass, equals(MockItemClass));
    });
  });

  group('RdfMapKey', () {
    test('constructor creates instance', () {
      final annotation = RdfMapKey();

      expect(annotation, isA<RdfAnnotation>());
      expect(annotation, isA<RdfMapKey>());
    });

    test('constructor is const', () {
      expect(identical(const RdfMapKey(), const RdfMapKey()), isTrue);
    });
  });

  group('RdfMapValue', () {
    test('constructor creates instance', () {
      final annotation = RdfMapValue();

      expect(annotation, isA<RdfAnnotation>());
      expect(annotation, isA<RdfMapValue>());
    });

    test('constructor is const', () {
      expect(identical(const RdfMapValue(), const RdfMapValue()), isTrue);
    });
  });
}
