import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';
import 'package:test/test.dart';

class TestRdfAnnotation extends RdfAnnotation {
  const TestRdfAnnotation();
}

void main() {
  group('RdfAnnotation', () {
    test('can be extended', () {
      final annotation = const TestRdfAnnotation();
      expect(annotation, isA<RdfAnnotation>());
    });

    test('constructor is const', () {
      // This test verifies that we can create const instances of RdfAnnotation subclasses
      expect(const TestRdfAnnotation(), isA<RdfAnnotation>());
      expect(identical(const TestRdfAnnotation(), const TestRdfAnnotation()),
          isTrue);
    });
  });
}
