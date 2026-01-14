import 'package:locorda_rdf_core/src/graph/rdf_term.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/src/base/base_mapping.dart';
import 'package:test/test.dart';

// Ein einfaches Interface für Test-Zwecke
abstract class TestMapper implements LiteralTermMapper {}

// Eine konkrete Test-Klasse, die das Interface implementiert
class ConcreteTestMapper implements TestMapper {
  @override
  IriTerm? get datatype => null;

  @override
  fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    throw UnimplementedError();
  }

  @override
  LiteralTerm toRdfTerm(value, SerializationContext context) {
    throw UnimplementedError();
  }
}

// Eine Test-Implementation von BaseMapping
class TestMapping extends BaseMapping<TestMapper> {
  const TestMapping({
    String? mapperName,
    Type? mapperType,
    TestMapper? mapperInstance,
  }) : super(
          mapperName: mapperName,
          mapperType: mapperType,
          mapperInstance: mapperInstance,
        );
}

void main() {
  group('BaseMapping', () {
    test('null mapper when no configuration is provided', () {
      final mapping = TestMapping();
      expect(mapping.mapper, isNull);
    });

    test('mapper with name when mapperName is provided', () {
      const mapperName = 'testMapper';
      final mapping = TestMapping(mapperName: mapperName);

      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, equals(mapperName));
      expect(mapping.mapper!.instance, isNull);
      expect(mapping.mapper!.type, isNull);
    });

    test('mapper with type when mapperType is provided', () {
      final mapping = TestMapping(mapperType: ConcreteTestMapper);

      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, isNull);
      expect(mapping.mapper!.instance, isNull);
      expect(mapping.mapper!.type, equals(ConcreteTestMapper));
    });

    test('mapper with instance when mapperInstance is provided', () {
      final mockMapper = ConcreteTestMapper();
      final mapping = TestMapping(mapperInstance: mockMapper);

      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, isNull);
      expect(mapping.mapper!.instance, equals(mockMapper));
      expect(mapping.mapper!.type, isNull);
    });

    test('mapper with multiple configurations', () {
      final mockMapper = ConcreteTestMapper();
      final mapping = TestMapping(
        mapperName: 'testMapper',
        mapperType: ConcreteTestMapper,
        mapperInstance: mockMapper,
      );

      expect(mapping.mapper, isNotNull);
      expect(mapping.mapper!.name, equals('testMapper'));
      expect(mapping.mapper!.instance, equals(mockMapper));
      expect(mapping.mapper!.type, equals(ConcreteTestMapper));
    });
  });
}
