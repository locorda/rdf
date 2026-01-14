import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';

import '../fixtures/annotation_subclass_test_models.dart' as astm;
import '../fixtures/comprehensive_collection_tests.dart' as cct;
import '../fixtures/global_resource_processor_test_models.dart' as grptm;
import '../fixtures/local_resource_processor_test_models.dart' as lrptm;
import '../fixtures/iri_processor_test_models.dart' as iptm;
import '../fixtures/literal_processor_test_models.dart' as lptm;
import '../fixtures/named_factory_test_models.dart' as nftm;
import '../fixtures/locorda_rdf_mapper_annotations/examples/enum_mapping_simple.dart'
    as ems;
import '../fixtures/locorda_rdf_mapper_annotations/examples/example_iri_strategies.dart'
    as eis;
import '../init_test_rdf_mapper.g.dart';

class TestMapper
    implements IriTermMapper<grptm.ClassWithIriNamedMapperStrategy> {
  const TestMapper();
  @override
  grptm.ClassWithIriNamedMapperStrategy fromRdfTerm(
      IriTerm term, DeserializationContext context) {
    throw UnimplementedError();
  }

  @override
  IriTerm toRdfTerm(grptm.ClassWithIriNamedMapperStrategy value,
      SerializationContext context) {
    // this of course is pretty nonsensical, but just for testing
    return context
        .createIriTerm('http://example.org/persons3/${value.hashCode}');
  }
}

class NamedTestGlobalResourceMapper
    implements GlobalResourceMapper<grptm.ClassWithMapperNamedMapperStrategy> {
  const NamedTestGlobalResourceMapper();

  @override
  grptm.ClassWithMapperNamedMapperStrategy fromRdfResource(
      IriTerm term, DeserializationContext context) {
    return grptm.ClassWithMapperNamedMapperStrategy();
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      grptm.ClassWithMapperNamedMapperStrategy value,
      SerializationContext context,
      {RdfSubject? parentSubject}) {
    return context
        .resourceBuilder(const IriTerm(
            'http://example.org/instance/ClassWithMapperNamedMapperStrategy'))
        .build();
  }

  @override
  IriTerm? get typeIri =>
      const IriTerm('http://example.org/g/ClassWithMapperNamedMapperStrategy');
}

class NamedTestLocalResourceMapper
    implements LocalResourceMapper<lrptm.ClassWithMapperNamedMapperStrategy> {
  const NamedTestLocalResourceMapper();

  @override
  lrptm.ClassWithMapperNamedMapperStrategy fromRdfResource(
      BlankNodeTerm term, DeserializationContext context) {
    return lrptm.ClassWithMapperNamedMapperStrategy();
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
      lrptm.ClassWithMapperNamedMapperStrategy value,
      SerializationContext context,
      {RdfSubject? parentSubject}) {
    return context.resourceBuilder(BlankNodeTerm()).build();
  }

  @override
  IriTerm? get typeIri =>
      const IriTerm('http://example.org/l/ClassWithMapperNamedMapperStrategy');
}

class NamedTestIriMapper implements IriTermMapper<iptm.IriWithNamedMapper> {
  const NamedTestIriMapper();

  @override
  iptm.IriWithNamedMapper fromRdfTerm(
      IriTerm term, DeserializationContext context) {
    return iptm.IriWithNamedMapper(term.value);
  }

  @override
  IriTerm toRdfTerm(
      iptm.IriWithNamedMapper value, SerializationContext context) {
    // this of course is pretty nonsensical, but just for testing
    return context.createIriTerm(value.value);
  }
}

class NamedTestLiteralMapper
    implements LiteralTermMapper<lptm.LiteralWithNamedMapper> {
  final IriTerm? datatype = null;
  const NamedTestLiteralMapper();

  @override
  lptm.LiteralWithNamedMapper fromRdfTerm(
      LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return lptm.LiteralWithNamedMapper(term.value);
  }

  @override
  LiteralTerm toRdfTerm(
      lptm.LiteralWithNamedMapper value, SerializationContext context) {
    // this of course is pretty nonsensical, but just for testing
    return LiteralTerm(value.value);
  }
}

/// IRI mapper for three part tuple with properties (String id, String surname, int version)
class TestMapper3PartsWithProperties
    implements IriTermMapper<(String, String, int)> {
  const TestMapper3PartsWithProperties();

  @override
  (String, String, int) fromRdfTerm(
      IriTerm term, DeserializationContext context) {
    // Extract ID, surname, and version from IRI like http://example.org/3parts/test-id/smith/42
    final iri = term.value;
    final match = RegExp(r'http://example\.org/3parts/([^/]+)/([^/]+)/(\d+)$')
        .firstMatch(iri);
    if (match == null) {
      throw ArgumentError('Invalid IRI format: $iri');
    }
    return (match.group(1)!, match.group(2)!, int.parse(match.group(3)!));
  }

  @override
  IriTerm toRdfTerm((String, String, int) value, SerializationContext context) {
    return context.createIriTerm(
        'http://example.org/3parts/${value.$1}/${value.$2}/${value.$3}');
  }
}

/// Test IRI mapper for String values
class TestIriMapper implements IriTermMapper<String> {
  const TestIriMapper();

  @override
  String fromRdfTerm(IriTerm term, DeserializationContext context) {
    return term.value;
  }

  @override
  IriTerm toRdfTerm(String value, SerializationContext context) {
    return context.createIriTerm(value);
  }
}

/// Test local resource mapper for `Map<String, String>` values
class TestMapEntryMapper
    implements LocalResourceMapper<MapEntry<String, String>> {
  static const IriTerm _typeIri = const IriTerm('http://example.org/MapEntry');
  static const IriTerm _key = const IriTerm('http://example.org/key');
  static const IriTerm _value = const IriTerm('http://example.org/value');
  const TestMapEntryMapper();

  @override
  MapEntry<String, String> fromRdfResource(
      BlankNodeTerm term, DeserializationContext context) {
    final reader = context.reader(term);
    return MapEntry(reader.require(_key), reader.require(_value));
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
      MapEntry<String, String> entry, SerializationContext context,
      {RdfSubject? parentSubject}) {
    return context
        .resourceBuilder(BlankNodeTerm())
        .addValue(_key, entry.key)
        .addValue(_value, entry.value)
        .build();
  }

  @override
  IriTerm? get typeIri => _typeIri;
}

/// Test literal mapper for String values (custom mapper)
class TestCustomMapper implements LiteralTermMapper<String> {
  final IriTerm? datatype = null;
  const TestCustomMapper();

  @override
  String fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return term.value;
  }

  @override
  LiteralTerm toRdfTerm(String value, SerializationContext context) {
    return LiteralTerm(value);
  }
}

/// Test global resource mapper for Object values
class TestGlobalMapper implements GlobalResourceMapper<Object> {
  const TestGlobalMapper();

  @override
  Object fromRdfResource(IriTerm term, DeserializationContext context) {
    return Object();
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      Object value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    return context
        .resourceBuilder(context
            .createIriTerm('http://example.org/objects/${value.hashCode}'))
        .build();
  }

  @override
  IriTerm? get typeIri => const IriTerm('http://example.org/Object');
}

/// Test literal mapper for double values (price mapper)
class TestLiteralPriceMapper implements LiteralTermMapper<double> {
  final IriTerm? datatype = null;
  const TestLiteralPriceMapper();

  @override
  double fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    return double.parse(term.value);
  }

  @override
  LiteralTerm toRdfTerm(double value, SerializationContext context) {
    return LiteralTerm(value.toString());
  }
}

/// Test local resource mapper for Object values
class TestLocalMapper implements LocalResourceMapper<Object> {
  const TestLocalMapper();

  @override
  Object fromRdfResource(BlankNodeTerm term, DeserializationContext context) {
    return Object();
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
      Object value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    return context.resourceBuilder(BlankNodeTerm()).build();
  }

  @override
  IriTerm? get typeIri => const IriTerm('http://example.org/LocalObject');
}

/// Test global resource mapper for Object values (named mapper)
class TestNamedMapper implements GlobalResourceMapper<Object> {
  const TestNamedMapper();

  @override
  Object fromRdfResource(IriTerm term, DeserializationContext context) {
    return Object();
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      Object value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    return context
        .resourceBuilder(
            context.createIriTerm('http://example.org/named/${value.hashCode}'))
        .build();
  }

  @override
  IriTerm? get typeIri => const IriTerm('http://example.org/NamedObject');
}

/// Test IRI mapper for chapter IDs (book ID, chapter number tuple)
class TestChapterIdMapper implements IriTermMapper<(String, int)> {
  const TestChapterIdMapper();

  @override
  (String, int) fromRdfTerm(IriTerm term, DeserializationContext context) {
    // Extract book ID and chapter number from IRI like http://example.org/books/book-123/chapters/42
    final iri = term.value;
    final match = RegExp(r'http://example\.org/books/([^/]+)/chapters/(\d+)$')
        .firstMatch(iri);
    if (match == null) {
      throw ArgumentError('Invalid chapter IRI format: $iri');
    }
    return (match.group(1)!, int.parse(match.group(2)!));
  }

  @override
  IriTerm toRdfTerm((String, int) value, SerializationContext context) {
    return context.createIriTerm(
        'http://example.org/books/${value.$1}/chapters/${value.$2}');
  }
}

/// Test literal mapper for Priority enum values
class TestCustomPriorityMapper implements LiteralTermMapper<ems.Priority> {
  final IriTerm? datatype = null;
  const TestCustomPriorityMapper();

  @override
  ems.Priority fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    switch (term.value.toLowerCase()) {
      case 'high':
        return ems.Priority.high;
      case 'medium':
        return ems.Priority.medium;
      case 'low':
        return ems.Priority.low;
      default:
        return ems.Priority.medium; // default
    }
  }

  @override
  LiteralTerm toRdfTerm(ems.Priority value, SerializationContext context) {
    return LiteralTerm(value.name);
  }
}

/// Test IRI mapper for UserReference values
class TestUserReferenceMapper implements IriTermMapper<eis.UserReference> {
  const TestUserReferenceMapper();

  @override
  eis.UserReference fromRdfTerm(IriTerm term, DeserializationContext context) {
    // Extract user ID from IRI like http://example.org/users/user-123
    final iri = term.value;
    final match = RegExp(r'http://example\.org/users/(.+)$').firstMatch(iri);
    if (match == null) {
      throw ArgumentError('Invalid user reference IRI format: $iri');
    }
    return eis.UserReference(match.group(1)!);
  }

  @override
  IriTerm toRdfTerm(eis.UserReference value, SerializationContext context) {
    return context.createIriTerm('http://example.org/users/${value.username}');
  }
}

/// Test global resource mapper for ComplexItem
class TestComplexItemGlobalMapper
    implements GlobalResourceMapper<cct.ComplexItem> {
  const TestComplexItemGlobalMapper();

  @override
  cct.ComplexItem fromRdfResource(
      IriTerm term, DeserializationContext context) {
    // Simple test implementation - decode from IRI
    final iri = term.value;
    final match = RegExp(r'http://example\.org/complex-items/([^/]+)/(\d+)$')
        .firstMatch(iri);
    if (match == null) {
      throw ArgumentError('Invalid complex item IRI format: $iri');
    }
    return cct.ComplexItem(
        name: match.group(1)!, id: int.parse(match.group(2)!));
  }

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
      cct.ComplexItem value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    final iri = context.createIriTerm(
        'http://example.org/complex-items/${value.name}/${value.id}');
    return context.resourceBuilder(iri).build();
  }

  @override
  IriTerm? get typeIri => const IriTerm('http://example.org/ComplexItem');
}

/// Test local resource mapper for ComplexItem
class TestComplexItemLocalMapper
    implements LocalResourceMapper<cct.ComplexItem> {
  const TestComplexItemLocalMapper();

  @override
  cct.ComplexItem fromRdfResource(
      BlankNodeTerm term, DeserializationContext context) {
    // Simple test implementation - return default values
    return cct.ComplexItem(name: 'test-item', id: 1);
  }

  @override
  (BlankNodeTerm, Iterable<Triple>) toRdfResource(
      cct.ComplexItem value, SerializationContext context,
      {RdfSubject? parentSubject}) {
    return context.resourceBuilder(BlankNodeTerm()).build();
  }

  @override
  IriTerm? get typeIri => const IriTerm('http://example.org/ComplexItem');
}

/// Test custom collection mapper for `List<String>`
class TestCustomCollectionMapper implements LiteralTermMapper<List<String>> {
  const TestCustomCollectionMapper();

  @override
  IriTerm? get datatype => null;

  @override
  List<String> fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    // Parse comma-separated values
    final value = term.value;
    if (value.isEmpty) return [];
    return value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  LiteralTerm toRdfTerm(List<String> value, SerializationContext context) {
    return LiteralTerm(value.join(','));
  }
}

/// Test custom map mapper for `Map<String, int>`
class TestCustomMapMapper implements LiteralTermMapper<Map<String, int>> {
  const TestCustomMapMapper();

  @override
  IriTerm? get datatype => null;

  @override
  Map<String, int> fromRdfTerm(LiteralTerm term, DeserializationContext context,
      {bool bypassDatatypeCheck = false}) {
    // Parse JSON-like format: {"key1":42,"key2":100}
    final value = term.value.trim();
    if (value.isEmpty || value == '{}') return <String, int>{};

    try {
      // Simple JSON-like parsing for Map<String, int>
      final map = <String, int>{};
      final content = value.substring(1, value.length - 1); // Remove { and }
      if (content.isNotEmpty) {
        final pairs = content.split(',');
        for (final pair in pairs) {
          final colonIndex = pair.indexOf(':');
          if (colonIndex > 0) {
            final key =
                pair.substring(0, colonIndex).trim().replaceAll('"', '');
            final valueStr = pair.substring(colonIndex + 1).trim();
            final intValue = int.parse(valueStr);
            map[key] = intValue;
          }
        }
      }
      return map;
    } catch (e) {
      throw FormatException('Invalid map format: $value');
    }
  }

  @override
  LiteralTerm toRdfTerm(Map<String, int> value, SerializationContext context) {
    if (value.isEmpty) return LiteralTerm('{}');
    final entries = value.entries.map((e) => '"${e.key}":${e.value}').join(',');
    return LiteralTerm('{$entries}');
  }
}

/// Test IRI mapper for PodIri factory
class TestPodIriMapper<T> implements IriTermMapper<(String,)> {
  final astm.PodConfig config;
  const TestPodIriMapper(this.config);

  @override
  (String,) fromRdfTerm(IriTerm term, DeserializationContext context) {
    // Extract id from IRI like http://example.org/pod/test-id
    final iri = term.value;
    final match = RegExp(r'http://example\.org/pod/(.+)$').firstMatch(iri);
    if (match == null) {
      throw ArgumentError('Invalid pod IRI format: $iri');
    }
    return (match.group(1)!,);
  }

  @override
  IriTerm toRdfTerm((String,) value, SerializationContext context) {
    final paddedId = value.$1.padLeft(config.digits, '0');
    return context.createIriTerm('http://example.org/pod/$paddedId');
  }
}

/// Test IRI mapper for configurable book IRI factory
class TestConfigurableBookIriMapper<T> implements IriTermMapper<(String,)> {
  final nftm.IriMapperConfig config;
  const TestConfigurableBookIriMapper(this.config);

  @override
  (String,) fromRdfTerm(IriTerm term, DeserializationContext context) {
    // Extract id from IRI using config baseUri
    final iri = term.value;
    final baseUri = config.baseUri;
    final match =
        RegExp('$baseUri/books/(.+)\\?format=${config.format}').firstMatch(iri);
    if (match == null) {
      throw ArgumentError('Invalid configurable book IRI format: $iri');
    }
    return (match.group(1)!,);
  }

  @override
  IriTerm toRdfTerm((String,) value, SerializationContext context) {
    return context.createIriTerm(
        '${config.baseUri}/books/${value.$1}?format=${config.format}');
  }
}

/// Test IRI mapper for simple book IRI factory
class TestSimpleBookIriMapper<T> implements IriTermMapper<(String,)> {
  const TestSimpleBookIriMapper();

  @override
  (String,) fromRdfTerm(IriTerm term, DeserializationContext context) {
    // Extract id from IRI like https://example.com/books/test-id
    final iri = term.value;
    final match = RegExp(r'https://example\.com/books/(.+)$').firstMatch(iri);
    if (match == null) {
      throw ArgumentError('Invalid simple book IRI format: $iri');
    }
    return (match.group(1)!,);
  }

  @override
  IriTerm toRdfTerm((String,) value, SerializationContext context) {
    return context.createIriTerm('https://example.com/books/${value.$1}');
  }
}

const baseUri = 'http://example.org';

/// Default PodIri factory for test purposes
IriTermMapper<(String,)> Function<T>(astm.PodConfig) get _defaultPodIriFactory {
  return <T>(astm.PodConfig config) {
    return TestPodIriMapper<T>(config);
  };
}

/// Default configurable book IRI factory for test purposes
IriTermMapper<(String,)> Function<T>(nftm.IriMapperConfig)
    get _defaultConfigurableBookIriFactory {
  return <T>(nftm.IriMapperConfig config) {
    return TestConfigurableBookIriMapper<T>(config);
  };
}

/// Default simple book IRI factory for test purposes
IriTermMapper<(String,)> Function<T>() get _defaultSimpleBookIriFactory {
  return <T>() {
    return TestSimpleBookIriMapper<T>();
  };
}

/// Default simple variant reference factory for test purposes
IriTermMapper<String> Function<T>(Type) get _defaultSimpleVariantRefFactory {
  return <T>(Type type) {
    return TestIriMapper();
  };
}

RdfMapper defaultInitTestRdfMapper(
    {RdfMapper? rdfMapper,
    // Provider parameters
    String Function()? apiBaseProvider,
    String Function()? baseUriProvider,
    String Function()? baseVocabProvider,
    String Function()? departmentProvider,
    String Function()? orgNamespaceProvider,
    String Function()? storageRootProvider,
    String Function()? versionProvider,
    // IRI mapper parameters
    IriTermMapper<(String, int)>? chapterIdMapper,
    LiteralTermMapper<ems.Priority>? customPriorityMapper,
    IriTermMapper<String>? iriMapper,
    LocalResourceMapper<MapEntry<String, String>>? mapEntryMapper,
    LiteralTermMapper<String>? testCustomMapper,
    GlobalResourceMapper<Object>? testGlobalMapper,
    GlobalResourceMapper<grptm.ClassWithMapperNamedMapperStrategy>?
        testGlobalResourceMapper,
    IriTermMapper<iptm.IriWithNamedMapper>? testIriMapper,
    LiteralTermMapper<lptm.LiteralWithNamedMapper>? testLiteralMapper,
    LiteralTermMapper<double>? testLiteralPriceMapper,
    LocalResourceMapper<Object>? testLocalMapper,
    LocalResourceMapper<lrptm.ClassWithMapperNamedMapperStrategy>?
        testLocalResourceMapper,
    IriTermMapper<grptm.ClassWithIriNamedMapperStrategy>? testMapper,
    IriTermMapper<
            (
              String id,
              String surname,
              int version,
            )>?
        testMapper3,
    GlobalResourceMapper<Object>? testNamedMapper,
    IriTermMapper<eis.UserReference>? userReferenceMapper,
    // New mapper parameters
    GlobalResourceMapper<cct.ComplexItem>? complexItemMapperGlobal,
    LocalResourceMapper<cct.ComplexItem>? complexItemMapperLocal,
    Mapper<List<String>>? customCollectionMapper,
    // Factory function parameters
    IriTermMapper<(String id,)> Function<T>(astm.PodConfig)? podIriFactory,
    IriTermMapper<(String id,)> Function<T>(nftm.IriMapperConfig)?
        configurableBookIriFactory,
    IriTermMapper<(String id,)> Function<T>()? simpleBookIriFactory,
    IriTermMapper<String> Function<T>(Type)? simpleVariantRefFactory}) {
  return initTestRdfMapper(
    rdfMapper: rdfMapper,
    // Provider parameters
    apiBaseProvider: apiBaseProvider ?? (() => 'http://example.org/api'),
    baseUriProvider: baseUriProvider ?? (() => baseUri),
    baseVocabProvider: baseVocabProvider ?? (() => 'http://example.org/vocab#'),
    departmentProvider: departmentProvider ?? (() => 'engineering'),
    orgNamespaceProvider:
        orgNamespaceProvider ?? (() => 'http://example.org/org/'),
    storageRootProvider:
        storageRootProvider ?? (() => 'http://example.org/storage/'),
    versionProvider: versionProvider ?? (() => 'v1'),
    // Named mapper parameters
    chapterIdMapper: chapterIdMapper ?? const TestChapterIdMapper(),
    customPriorityMapper:
        customPriorityMapper ?? const TestCustomPriorityMapper(),
    iriMapper: iriMapper ?? const TestIriMapper(),
    mapEntryMapper: mapEntryMapper ?? const TestMapEntryMapper(),
    testCustomMapper: testCustomMapper ?? const TestCustomMapper(),
    testGlobalMapper: testGlobalMapper ?? const TestGlobalMapper(),
    testGlobalResourceMapper:
        testGlobalResourceMapper ?? const NamedTestGlobalResourceMapper(),
    testIriMapper: testIriMapper ?? const NamedTestIriMapper(),
    testLiteralMapper: testLiteralMapper ?? const NamedTestLiteralMapper(),
    testLiteralPriceMapper:
        testLiteralPriceMapper ?? const TestLiteralPriceMapper(),
    testLocalMapper: testLocalMapper ?? const TestLocalMapper(),
    testLocalResourceMapper:
        testLocalResourceMapper ?? const NamedTestLocalResourceMapper(),
    testMapper: testMapper ?? const TestMapper(),
    testMapper3: testMapper3 ?? const TestMapper3PartsWithProperties(),
    testNamedMapper: testNamedMapper ?? const TestNamedMapper(),
    userReferenceMapper: userReferenceMapper ?? const TestUserReferenceMapper(),
    // New mapper parameters
    complexItemMapperGlobal:
        complexItemMapperGlobal ?? const TestComplexItemGlobalMapper(),
    complexItemMapperLocal:
        complexItemMapperLocal ?? const TestComplexItemLocalMapper(),
    customCollectionMapper:
        customCollectionMapper ?? const TestCustomCollectionMapper(),
    // Factory function parameters
    $podIri$Factory: podIriFactory ?? _defaultPodIriFactory,
    configurableBookIriFactory:
        configurableBookIriFactory ?? _defaultConfigurableBookIriFactory,
    simpleBookIriFactory: simpleBookIriFactory ?? _defaultSimpleBookIriFactory,
    simpleVariantRefFactory:
        simpleVariantRefFactory ?? _defaultSimpleVariantRefFactory,
  );
}
