import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  final subject = const IriTerm('http://example.org/subject');
  final namePredicate = const IriTerm('http://example.org/name');
  final agePredicate = const IriTerm('http://example.org/age');

  late RdfMapperRegistry registry;

  setUp(() {
    registry = RdfMapperRegistry();
  });

  group('DeserializationStrictness', () {
    group('TooManyPropertyValuesException', () {
      late RdfGraph multiValueGraph;

      setUp(() {
        multiValueGraph = RdfGraph(triples: [
          Triple(subject, namePredicate, LiteralTerm.string('Alice')),
          Triple(subject, namePredicate, LiteralTerm.string('Bob')),
        ]);
      });

      test('strict mode throws on multiple values', () {
        final context = DeserializationContextImpl(
          graph: multiValueGraph,
          registry: registry,
          strictness: DeserializationStrictness.strict,
        );

        expect(
          () => context.optional<String>(subject, namePredicate),
          throwsA(isA<TooManyPropertyValuesException>()),
        );
      });

      test('warnOnly mode returns first value and logs warning', () {
        final logs = <LogRecord>[];
        final sub =
            Logger('DeserializationContextImpl').onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final context = DeserializationContextImpl(
          graph: multiValueGraph,
          registry: registry,
          strictness: DeserializationStrictness.warnOnly,
        );

        final result = context.optional<String>(subject, namePredicate);
        expect(result, equals('Alice'));
        expect(logs, hasLength(1));
        expect(logs.first.level, equals(Level.WARNING));
        expect(logs.first.message, contains('Multiple values'));
      });

      test('lenient mode returns first value without logging', () {
        final logs = <LogRecord>[];
        final sub =
            Logger('DeserializationContextImpl').onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final context = DeserializationContextImpl(
          graph: multiValueGraph,
          registry: registry,
          strictness: DeserializationStrictness.lenient,
        );

        final result = context.optional<String>(subject, namePredicate);
        expect(result, equals('Alice'));
        expect(logs, isEmpty);
      });

      test(
          'require in warnOnly mode returns first value for multi-valued property',
          () {
        final context = DeserializationContextImpl(
          graph: multiValueGraph,
          registry: registry,
          strictness: DeserializationStrictness.warnOnly,
        );

        final result = context.require<String>(subject, namePredicate);
        expect(result, equals('Alice'));
      });
    });

    group('DeserializerDatatypeMismatchException', () {
      test('strict mode throws on datatype mismatch', () {
        final context = DeserializationContextImpl(
          graph: RdfGraph(triples: [
            Triple(
              subject,
              agePredicate,
              // Custom datatype that no deserializer expects
              LiteralTerm('42',
                  datatype: const IriTerm('http://example.org/custom')),
            ),
          ]),
          registry: registry,
          strictness: DeserializationStrictness.strict,
        );

        expect(
          () => context.optional<int>(subject, agePredicate),
          throwsA(isA<DeserializerDatatypeMismatchException>()),
        );
      });

      test('warnOnly mode returns null on datatype mismatch and logs warning',
          () {
        final logs = <LogRecord>[];
        final sub =
            Logger('DeserializationContextImpl').onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final context = DeserializationContextImpl(
          graph: RdfGraph(triples: [
            Triple(
              subject,
              agePredicate,
              LiteralTerm('42',
                  datatype: const IriTerm('http://example.org/custom')),
            ),
          ]),
          registry: registry,
          strictness: DeserializationStrictness.warnOnly,
        );

        final result = context.optional<int>(subject, agePredicate);
        expect(result, isNull);
        expect(logs, hasLength(1));
        expect(logs.first.level, equals(Level.WARNING));
        expect(logs.first.message, contains('Datatype mismatch'));
      });

      test('lenient mode returns null on datatype mismatch without logging',
          () {
        final logs = <LogRecord>[];
        final sub =
            Logger('DeserializationContextImpl').onRecord.listen(logs.add);
        addTearDown(sub.cancel);

        final context = DeserializationContextImpl(
          graph: RdfGraph(triples: [
            Triple(
              subject,
              agePredicate,
              LiteralTerm('42',
                  datatype: const IriTerm('http://example.org/custom')),
            ),
          ]),
          registry: registry,
          strictness: DeserializationStrictness.lenient,
        );

        final result = context.optional<int>(subject, agePredicate);
        expect(result, isNull);
        expect(logs, isEmpty);
      });

      test(
          'require with datatype mismatch in lenient mode throws PropertyValueNotFoundException',
          () {
        final context = DeserializationContextImpl(
          graph: RdfGraph(triples: [
            Triple(
              subject,
              agePredicate,
              LiteralTerm('42',
                  datatype: const IriTerm('http://example.org/custom')),
            ),
          ]),
          registry: registry,
          strictness: DeserializationStrictness.lenient,
        );

        expect(
          () => context.require<int>(subject, agePredicate),
          throwsA(isA<PropertyValueNotFoundException>()),
        );
      });
    });
  });

  group('RdfMapperSettings', () {
    test('strict() creates settings with strict strictness', () {
      const settings = RdfMapperSettings.strict();
      expect(settings.strictness, equals(DeserializationStrictness.strict));
    });

    test('warnOnly() creates settings with warnOnly strictness', () {
      const settings = RdfMapperSettings.warnOnly();
      expect(settings.strictness, equals(DeserializationStrictness.warnOnly));
    });

    test('lenient() creates settings with lenient strictness', () {
      const settings = RdfMapperSettings.lenient();
      expect(settings.strictness, equals(DeserializationStrictness.lenient));
    });

    test('default constructor uses strict strictness', () {
      const settings = RdfMapperSettings();
      expect(settings.strictness, equals(DeserializationStrictness.strict));
    });

    test('copyWith replaces strictness', () {
      const settings = RdfMapperSettings.strict();
      final lenient = settings.copyWith(
        strictness: DeserializationStrictness.lenient,
      );
      expect(lenient.strictness, equals(DeserializationStrictness.lenient));
    });

    test('copyWith without arguments preserves all values', () {
      const settings = RdfMapperSettings.warnOnly();
      final copy = settings.copyWith();
      expect(copy.strictness, equals(settings.strictness));
    });
  });

  group('RdfMapper integration', () {
    test('settings propagate through RdfMapper.withMappers', () {
      final mapper = RdfMapper.withMappers(
        (registry) {
          registry.registerMapper<_TestPerson>(_TestPersonMapper());
        },
        settings: const RdfMapperSettings.warnOnly(),
      );

      final turtle = '''
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        <http://example.org/person/1> rdf:type <http://example.org/Person> ;
          <http://example.org/name> "Alice" ;
          <http://example.org/name> "Bob" .
      ''';

      // Should not throw - warnOnly mode should handle duplicate names
      final person = mapper.decodeObject<_TestPerson>(
        turtle,
        completeness: CompletenessMode.lenient,
      );
      expect(person.name, equals('Alice'));
    });

    test('settings propagate through RdfMapper.withDefaultRegistry', () {
      final mapper = RdfMapper.withMappers(
        (registry) {
          registry.registerMapper<_TestPerson>(_TestPersonMapper());
        },
        settings: const RdfMapperSettings.lenient(),
      );

      final turtle = '''
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        <http://example.org/person/1> rdf:type <http://example.org/Person> ;
          <http://example.org/name> "Alice" ;
          <http://example.org/name> "Bob" .
      ''';

      final person = mapper.decodeObject<_TestPerson>(
        turtle,
        completeness: CompletenessMode.lenient,
      );
      expect(person.name, equals('Alice'));
    });
  });
}

class _TestPerson {
  final String id;
  final String name;

  _TestPerson({required this.id, required this.name});
}

class _TestPersonMapper implements GlobalResourceMapper<_TestPerson> {
  @override
  IriTerm get typeIri => const IriTerm('http://example.org/Person');

  @override
  _TestPerson fromRdfResource(IriTerm subject, DeserializationContext context) {
    final reader = context.reader(subject);
    return _TestPerson(
      id: subject.value,
      name: reader.require<String>(const IriTerm('http://example.org/name')),
    );
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    _TestPerson instance,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    return context
        .resourceBuilder(IriTerm(instance.id))
        .addValue(const IriTerm('http://example.org/name'), instance.name)
        .build();
  }
}
