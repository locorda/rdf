import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:rdf_vocabularies_core/xsd.dart';
import 'package:test/test.dart';

// Import test models
import '../fixtures/literal_processor_test_models.dart';
import '../test_helper.dart';
import 'init_test_rdf_mapper_util.dart';

void main() {
  setupTestLogging();

  const testSubject = const IriTerm('https://example.org/subject');
  const testPredicate = const IriTerm('https://example.org/predicate');

  late RdfMapper mapper;

  LiteralTerm serialize<T>(T value, {RdfMapperRegistry? registry}) {
    final context =
        SerializationContextImpl(registry: registry ?? mapper.registry);
    return context.toLiteralTerm(value);
  }

  T deserialize<T>(LiteralTerm term, {RdfMapperRegistry? registry}) {
    final graph =
        RdfGraph.fromTriples([Triple(testSubject, testPredicate, term)]);
    final context = DeserializationContextImpl(
        graph: graph, registry: registry ?? mapper.registry);
    return context.fromLiteralTerm<T>(term);
  }

  setUp(() {
    mapper = defaultInitTestRdfMapper(
      testIriMapper: NamedTestIriMapper(),
    );
  });

  group('All Literal Mappers Test', () {
    test('LiteralString mapping', () {
      // Verify literal mapper registration
      expect(isRegisteredLiteralTermMapper<LiteralString>(mapper), isTrue,
          reason:
              'LiteralString should be registered as a literal term mapper');

      // Create a LiteralString instance
      final value = LiteralString(
        foo: '1234567890',
      );

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(), equals('"1234567890"'));

      // Test deserialization
      final deserialized = deserialize<LiteralString>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.foo, equals(value.foo));
    });

    test('Rating mapping', () {
      // Verify literal mapper registration
      expect(isRegisteredLiteralTermMapper<Rating>(mapper), isTrue,
          reason: 'Rating should be registered as a literal term mapper');

      // Create a Rating instance
      final value = Rating(4);

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(),
          equals('"4"^^<http://www.w3.org/2001/XMLSchema#integer>'));

      // Test deserialization
      final deserialized = deserialize<Rating>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.stars, equals(value.stars));
    });

    test('LocalizedText mapping', () {
      // Verify literal mapper registration
      expect(isRegisteredLiteralTermMapper<LocalizedText>(mapper), isTrue,
          reason:
              'LocalizedText should be registered as a literal term mapper');

      // Create a LocalizedText instance
      final value = LocalizedText('Hello World', 'en');

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(), equals('"Hello World"@en'));
      expect(term.language, equals('en'));

      // Test deserialization
      final deserialized = deserialize<LocalizedText>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.text, equals(value.text));
      expect(deserialized.language, equals(value.language));
    });

    test('LiteralDouble mapping', () {
      // Verify literal mapper registration
      expect(isRegisteredLiteralTermMapper<LiteralDouble>(mapper), isTrue,
          reason:
              'LiteralDouble should be registered as a literal term mapper');

      // Create a LiteralDouble instance
      final value = LiteralDouble(foo: 3.14159);

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(),
          equals('"3.14159"^^<http://www.w3.org/2001/XMLSchema#double>'));
      expect(term.datatype, equals(Xsd.double));

      // Test deserialization
      final deserialized = deserialize<LiteralDouble>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.foo, equals(value.foo));
    });

    test('LiteralInteger mapping', () {
      // Verify literal mapper registration
      expect(isRegisteredLiteralTermMapper<LiteralInteger>(mapper), isTrue,
          reason:
              'LiteralInteger should be registered as a literal term mapper');

      // Create a LiteralInteger instance
      final value = LiteralInteger(value: 42);

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(),
          equals('"42"^^<http://www.w3.org/2001/XMLSchema#integer>'));
      expect(term.datatype,
          equals(const IriTerm('http://www.w3.org/2001/XMLSchema#integer')));

      // Test deserialization
      final deserialized = deserialize<LiteralInteger>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.value, equals(value.value));
    });

    test('Temperature custom mapping', () {
      // Verify literal mapper registration
      expect(isRegisteredLiteralTermMapper<Temperature>(mapper), isTrue,
          reason: 'Temperature should be registered as a literal term mapper');

      // Create a Temperature instance
      final value = Temperature(23.5);

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(), equals('"23.5°C"'));

      // Test deserialization
      final deserialized = deserialize<Temperature>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.celsius, equals(value.celsius));
    });

    test('CustomLocalizedText custom mapping', () {
      // Verify literal mapper registration
      expect(isRegisteredLiteralTermMapper<CustomLocalizedText>(mapper), isTrue,
          reason:
              'CustomLocalizedText should be registered as a literal term mapper');

      // Create a CustomLocalizedText instance
      final value = CustomLocalizedText('Bonjour le monde', 'fr');

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(), equals('"Bonjour le monde"@fr'));
      expect(term.language, equals('fr'));

      // Test deserialization
      final deserialized = deserialize<CustomLocalizedText>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.text, equals(value.text));
      expect(deserialized.language, equals(value.language));
    });

    test('DoubleAsMilliunit custom mapping', () {
      // Verify literal mapper registration
      expect(isRegisteredLiteralTermMapper<DoubleAsMilliunit>(mapper), isTrue,
          reason:
              'DoubleAsMilliunit should be registered as a literal term mapper');

      // Create a DoubleAsMilliunit instance
      final value = DoubleAsMilliunit(1.234);

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(),
          equals('"1234"^^<http://www.w3.org/2001/XMLSchema#int>'));
      expect(term.datatype,
          equals(const IriTerm('http://www.w3.org/2001/XMLSchema#int')));

      // Test deserialization
      final deserialized = deserialize<DoubleAsMilliunit>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.value, equals(value.value));
    });

    test('LiteralWithNamedMapper mapping', () {
      // Verify literal mapper registration
      expect(
          isRegisteredLiteralTermMapper<LiteralWithNamedMapper>(mapper), isTrue,
          reason:
              'LiteralWithNamedMapper should be registered as a literal term mapper');

      // Create a LiteralWithNamedMapper instance
      final value = LiteralWithNamedMapper('test value');

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(), equals('"test value"'));

      // Test deserialization
      final deserialized = deserialize<LiteralWithNamedMapper>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.value, equals(value.value));
    });

    test('LiteralWithMapper mapping', () {
      // Verify literal mapper registration
      expect(isRegisteredLiteralTermMapper<LiteralWithMapper>(mapper), isTrue,
          reason:
              'LiteralWithMapper should be registered as a literal term mapper');

      // Create a LiteralWithMapper instance
      final value = LiteralWithMapper('mapper test');

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(), equals('"mapper test"'));

      // Test deserialization
      final deserialized = deserialize<LiteralWithMapper>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.value, equals(value.value));
    });

    test('LiteralWithMapperInstance mapping', () {
      // Verify literal mapper registration
      expect(isRegisteredLiteralTermMapper<LiteralWithMapperInstance>(mapper),
          isTrue,
          reason:
              'LiteralWithMapperInstance should be registered as a literal term mapper');

      // Create a LiteralWithMapperInstance instance
      final value = LiteralWithMapperInstance('instance test');

      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.toString(), equals('"instance test"'));

      // Test deserialization
      final deserialized = deserialize<LiteralWithMapperInstance>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.value, equals(value.value));
    });

    test('LiteralWithNonConstructorValue mapping', () {
      // Verify literal mapper registration
      expect(
          isRegisteredLiteralTermMapper<LiteralWithNonConstructorValue>(mapper),
          isTrue,
          reason:
              'LiteralWithNonConstructorValue should be registered as a literal term mapper');

      // Create a LiteralWithNonConstructorValue instance
      final value = LiteralWithNonConstructorValue()
        ..value = "test non-constructor value";

      // Test round-trip serialization/deserialization
      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.value, equals('test non-constructor value'));

      // Test deserialization
      final deserialized = deserialize<LiteralWithNonConstructorValue>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.value, equals(value.value));
    });

    test('LocalizedTextWithNonConstructorLanguage mapping', () {
      // Verify literal mapper registration
      expect(
          isRegisteredLiteralTermMapper<
              LocalizedTextWithNonConstructorLanguage>(mapper),
          isTrue,
          reason:
              'LocalizedTextWithNonConstructorLanguage should be registered as a literal term mapper');

      // Create a LocalizedTextWithNonConstructorLanguage instance
      final value = LocalizedTextWithNonConstructorLanguage("Hello world")
        ..language = "en";

      // Test round-trip serialization/deserialization
      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.value, equals('Hello world'));
      expect(term.language, equals('en'));

      // Test deserialization
      final deserialized =
          deserialize<LocalizedTextWithNonConstructorLanguage>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.text, equals(value.text));
      expect(deserialized.language, equals(value.language));
    });

    test('LiteralLateFinalLocalizedText mapping', () {
      // Verify literal mapper registration
      expect(
          isRegisteredLiteralTermMapper<LiteralLateFinalLocalizedText>(mapper),
          isTrue,
          reason:
              'LiteralLateFinalLocalizedText should be registered as a literal term mapper');

      // Create a LiteralWithMixedFields instance
      final value = LiteralLateFinalLocalizedText()
        ..baseValue = "Test value"
        ..language = "de";

      // Test round-trip serialization/deserialization
      final term = serialize(value);
      expect(term, isNotNull);
      expect(term.value, equals('Test value'));
      expect(term.language, equals('de'));

      // Test deserialization
      final deserialized = deserialize<LiteralLateFinalLocalizedText>(term);
      expect(deserialized, isNotNull);
      expect(deserialized.baseValue, equals(value.baseValue));
      expect(deserialized.language, equals(value.language));
    });
  });
}

bool isRegisteredLiteralTermMapper<T>(RdfMapper mapper) {
  return mapper.registry.hasLiteralTermDeserializerFor<T>() &&
      mapper.registry.hasLiteralTermSerializerFor<T>();
}
