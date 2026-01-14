import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:test/test.dart';

void main() {
  group('RdfProvides', () {
    test('constructor with name', () {
      const name = 'testName';
      final annotation = RdfProvides(name);

      expect(annotation.name, equals(name));
      expect(annotation, isA<RdfAnnotation>());
    });

    test('constructor with null name', () {
      final annotation = RdfProvides(null);

      expect(annotation.name, isNull);
      expect(annotation, isA<RdfAnnotation>());
    });

    test('constructor is const', () {
      const name = 'testName';
      expect(
          identical(const RdfProvides(name), const RdfProvides(name)), isTrue);
    });
  });
}
