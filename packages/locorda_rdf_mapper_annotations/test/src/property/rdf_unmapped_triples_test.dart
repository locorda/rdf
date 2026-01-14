import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:test/test.dart';

void main() {
  group('RdfUnmappedTriples', () {
    test('default constructor creates instance with globalUnmapped=false', () {
      const annotation = RdfUnmappedTriples();
      expect(annotation.globalUnmapped, isFalse);
      expect(annotation, isA<RdfAnnotation>());
    });

    test('constructor with globalUnmapped=true', () {
      const annotation = RdfUnmappedTriples(globalUnmapped: true);
      expect(annotation.globalUnmapped, isTrue);
      expect(annotation, isA<RdfAnnotation>());
    });

    test('constructor with globalUnmapped=false explicit', () {
      const annotation = RdfUnmappedTriples(globalUnmapped: false);
      expect(annotation.globalUnmapped, isFalse);
      expect(annotation, isA<RdfAnnotation>());
    });

    test('annotation implements RdfAnnotation', () {
      const annotation = RdfUnmappedTriples();
      expect(annotation, isA<RdfAnnotation>());
    });

    test('instances with same globalUnmapped value are equal', () {
      const annotation1 = RdfUnmappedTriples(globalUnmapped: true);
      const annotation2 = RdfUnmappedTriples(globalUnmapped: true);
      expect(annotation1.globalUnmapped, equals(annotation2.globalUnmapped));
    });

    test('instances with different globalUnmapped values are different', () {
      const annotation1 = RdfUnmappedTriples(globalUnmapped: true);
      const annotation2 = RdfUnmappedTriples(globalUnmapped: false);
      expect(annotation1.globalUnmapped,
          isNot(equals(annotation2.globalUnmapped)));
    });

    test('constructor is const', () {
      // This test verifies that the constructor is compile-time constant
      const annotation1 = RdfUnmappedTriples();
      const annotation2 = RdfUnmappedTriples(globalUnmapped: false);
      const annotation3 = RdfUnmappedTriples(globalUnmapped: true);

      expect(annotation1, isA<RdfUnmappedTriples>());
      expect(annotation2, isA<RdfUnmappedTriples>());
      expect(annotation3, isA<RdfUnmappedTriples>());
    });
  });
}
