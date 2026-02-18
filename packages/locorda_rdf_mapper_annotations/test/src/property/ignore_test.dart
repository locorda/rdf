import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:test/test.dart';

void main() {
  group('RdfIgnore', () {
    test('constructor creates instance', () {
      const annotation = RdfIgnore();

      expect(annotation, isA<RdfAnnotation>());
    });

    test('constructor is const', () {
      expect(identical(const RdfIgnore(), const RdfIgnore()), isTrue);
    });

    test('multiple instances are identical', () {
      const annotation1 = RdfIgnore();
      const annotation2 = RdfIgnore();

      expect(identical(annotation1, annotation2), isTrue);
    });
  });
}
