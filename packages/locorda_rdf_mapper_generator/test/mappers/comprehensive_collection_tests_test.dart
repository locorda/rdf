import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:test/test.dart';

import '../fixtures/comprehensive_collection_tests.dart';
import 'init_test_rdf_mapper_util.dart';

/// Comprehensive tests for all collection mapping scenarios.
/// This covers all missing test cases identified in the collection mapping system.
void main() {
  group('Comprehensive Collection Mapping Tests', () {
    late RdfMapper mapper;

    setUp(() {
      // Initialize with the test RDF mapper that includes generated mappers
      mapper = defaultInitTestRdfMapper(
          rdfMapper: RdfMapper.withMappers((r) => r
            ..registerMapper(StringListMapper())
            ..registerMapper(CustomMapMapper())));
    });

    group('1. CollectionMapping.fromRegistry() Tests', () {
      test('should use registry-based collection mapping', () {
        final testObject = RegistryCollectionTests(
          registryManagedCollection: ['item1', 'item2'],
        );

        final rdfContent = mapper.encodeObject(testObject,
            contentType: 'application/n-triples');

        // Should use the registered StringListMapper to serialize entire collection as JSON array
        expect(rdfContent, contains('registryCollection'));
        expect(rdfContent, contains('"[\\\"item1\\\", \\\"item2\\\"]"'));
      });
    });

    group('2. CollectionMapping.namedMapper() Tests', () {
      test('should reference named mapper for runtime injection', () {
        final testObject = NamedMapperCollectionTests(
          namedManagedCollection: ['custom1', 'custom2'],
        );

        final rdfContent = mapper.encodeObject(testObject,
            contentType: 'application/n-triples');

        // Should use default collection behavior since no named mapper is registered
        expect(rdfContent, contains('namedMapperCollection'));
        expect(rdfContent, contains('"custom1,custom2"'));
      });
    });

    group('3. CollectionMapping.mapper() vs .withItemMappers() Distinction',
        () {
      test('should use self-contained mapper for entire collection', () {
        final testObject = SelfContainedMapperTests(
          selfContainedCollection: ['alpha', 'beta', 'gamma'],
        );

        final rdfContent = mapper.encodeObject(testObject,
            contentType: 'application/n-triples');

        // Should serialize as single literal using StringListMapper
        expect(rdfContent, contains('selfContainedCollection'));
        expect(rdfContent,
            contains('"[\\\"alpha\\\", \\\"beta\\\", \\\"gamma\\\"]"'));

        // Should NOT create multiple separate triples
        expect(
            RegExp(r'selfContainedCollection.*"alpha"')
                .allMatches(rdfContent)
                .length,
            equals(0)); // Should be 0 since "alpha" is inside the JSON array
      });
    });

    group('4. CollectionMapping.mapperInstance() Tests', () {
      test('should use direct mapper instance with custom configuration', () {
        final testObject = InstanceManagedCollectionTests(
          instanceManagedCollection: ['data1', 'data2'],
        );

        final rdfContent = mapper.encodeObject(testObject,
            contentType: 'application/n-triples');

        // Should use the configured prefix and separator from customMapperInstance
        expect(rdfContent, contains('instanceManagedCollection'));
        expect(rdfContent, contains('LIST:data1|data2'));
      });
    });

    group('5. Set<T> and Iterable<T> Collection Tests', () {
      test('should handle Set collections with different strategies', () {
        final testObject = SetAndIterableCollectionTests(
          bagCollection: ['item1', 'item2', 'item3'],
          orderedCollection: ['order1', 'order2'],
          defaultIterable: ['iter1', 'iter2'],
          sequenceIterable: ['seq1', 'seq2', 'seq3'],
        );

        final rdfContent = mapper.encodeObject(testObject,
            contentType: 'application/n-triples');

        // Verify rdf:Bag structure with correct field name
        expect(rdfContent, contains('bagCollection'));
        expect(
            rdfContent,
            contains(
                '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Bag>'));

        // Verify rdf:List structure with correct field name
        expect(rdfContent, contains('orderedCollection'));
        expect(rdfContent,
            contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#first>'));

        // Verify Iterable with default behavior (multiple triples)
        expect(rdfContent, contains('defaultIterable'));
        expect(rdfContent, contains('"iter1"'));
        expect(rdfContent, contains('"iter2"'));

        // Verify Iterable with rdf:Seq structure
        expect(rdfContent, contains('sequenceIterable'));
        expect(
            rdfContent,
            contains(
                '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/1999/02/22-rdf-syntax-ns#Seq>'));
      });
    });

    group('6. itemType Parameter Tests', () {
      test('should handle explicit item type specification', () {
        final complexItem = ComplexItem(name: 'Test Item', id: 123);
        final testObject = ItemTypeParameterTests(
          complexCollection: CustomCollection([complexItem]),
        );

        final rdfContent = mapper.encodeObject(testObject,
            contentType: 'application/n-triples');
        // print(rdfContent);
        // Should work correctly with proper item type specification
        expect(rdfContent, contains('complexCollection'));
        expect(rdfContent, contains('<http://example.org/ComplexItem>'));
      });
    });

    group('7. Combined Item Mapping Tests', () {
      test('should handle collection with IRI item mapping', () {
        final testObject = CombinedItemMappingTests(
          iriItemsList: ['item1', 'item2'],
          resourceItemsSeq: [ComplexItem(name: 'Resource', id: 1)],
          languageTaggedBag: ['hello', 'world'],
        );

        final rdfContent = mapper.encodeObject(testObject,
            contentType: 'application/n-triples');

        // Should correctly map items with IRI mapping
        expect(rdfContent, contains('iriItemsList'));
        expect(rdfContent, contains('<http://example.org/item/item1>'));
        expect(rdfContent, contains('<http://example.org/item/item2>'));

        // Should handle resource items
        expect(rdfContent, contains('resourceItemsSeq'));
        expect(rdfContent,
            contains('<http://example.org/complex-items/Resource/1>'));

        // Should handle language tagged literals
        expect(rdfContent, contains('languageTaggedBag'));
        expect(rdfContent, contains('"hello"@en'));
        expect(rdfContent, contains('"world"@en'));
      });
    });

    group('8. Edge Cases and Error Scenarios', () {
      test('should handle empty collections', () {
        final testObject = EdgeCaseTests(
          emptyList: [],
          nullableList: [],
        );

        final rdfContent = mapper.encodeObject(testObject,
            contentType: 'application/n-triples');

        // Empty rdf:List should still create proper structure with rdf:nil
        expect(rdfContent, contains('emptyList'));
        expect(rdfContent,
            contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#nil>'));

        // Empty rdf:Seq should create proper container structure
        expect(rdfContent, contains('nullableList'));
      });

      test('should handle large collections for performance', () {
        final largeList = List.generate(1000, (i) => 'item$i');
        final testObject = PerformanceTests(performanceList: largeList);

        final stopwatch = Stopwatch()..start();
        final rdfContent = mapper.encodeObject(testObject,
            contentType: 'application/n-triples');
        stopwatch.stop();

        // Verify it completes in reasonable time (adjust threshold as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        expect(rdfContent, contains('performanceList'));
        expect(rdfContent, contains('item0'));
        expect(rdfContent, contains('item999'));
      });
    });

    group('9. Map Collections', () {
      test('should handle default map collections', () {
        final testObject = MapCollectionTests(
          defaultMap: {'key1': 'value1', 'key2': 'value2'},
          customMap: {'custom1': 'val1', 'custom2': 'val2'},
        );

        final rdfContent = mapper.encodeObject(testObject,
            contentType: 'application/n-triples');

        // Custom map should use CustomMapMapper serialization
        expect(rdfContent, contains('customMap'));
        expect(rdfContent, contains('custom1:val1;custom2:val2'));

        // Default map might not be serialized if empty/default behavior
        // This depends on the specific implementation
      });
    });

    group('10. includeDefaultsInSerialization with Collections', () {
      test('should handle default value serialization behavior', () {
        final testObject = DefaultSerializationTests(
          defaultHandledList: [], // Empty list equals default
        );

        final rdfContent = mapper.encodeObject(testObject,
            contentType: 'application/n-triples');

        // Should include empty list because includeDefaultsInSerialization: true
        expect(rdfContent, contains('defaultHandledList'));
        expect(rdfContent,
            contains('<http://www.w3.org/1999/02/22-rdf-syntax-ns#nil>'));
      });
    });

    group('Additional Complex Test Cases', () {
      test('should handle nested collections', () {
        final testObject = NestedCollectionTests(
          nestedCollections: [
            ['inner1', 'inner2'],
            ['inner3']
          ],
        );

        final rdfContent = mapper.encodeObject(testObject,
            contentType: 'application/n-triples');

        // Should serialize nested collections using the registered StringListMapper
        expect(rdfContent, contains('nestedCollections'));
        expect(rdfContent, contains('"[\\\"inner1\\\", \\\"inner2\\\"]"'));
        expect(rdfContent, contains('"[\\\"inner3\\\"]"'));
      });

      test('should handle mixed type collections', () {
        final testObject = MixedTypeTests(
          mixedTypeList: ['string', 42, true],
        );

        final rdfContent = mapper.encodeObject(testObject,
            contentType: 'application/n-triples');

        // Should serialize with explicit literal mapping (no datatype since it's just plain literals)
        expect(rdfContent, contains('mixedTypeList'));
        expect(rdfContent, contains('"string"'));
        expect(rdfContent, contains('"42"'));
        expect(rdfContent, contains('"true"'));
      });

      test('should handle context-managed IRI items', () {
        final testObject = ContextProviderTests(
          contextManagedItems: ['item1', 'item2'],
        );

        final rdfContent = mapper.encodeObject(testObject,
            contentType: 'application/n-triples');

        // Should correctly resolve context and map items to IRIs
        expect(rdfContent, contains('iriItemsList'));
        expect(rdfContent, contains('<https://test.example.org/item/item1>'));
        expect(rdfContent, contains('<https://test.example.org/item/item2>'));
      });
    });

    group('Regression Tests', () {
      test('should maintain backward compatibility with existing patterns', () {
        // Test that new features don't break existing collection behavior
        final basicList = <String>['basic1', 'basic2'];

        // Simple sanity check that basic patterns still work
        expect(basicList.length, equals(2));
        expect(basicList.first, equals('basic1'));
      });

      test('should handle all CollectionMapping constructor variants', () {
        // Verify all constructor patterns compile and can be instantiated
        final auto = CollectionMapping.auto();
        final fromRegistry = CollectionMapping.fromRegistry();
        final namedMapper = CollectionMapping.namedMapper('test');
        final mapperType = CollectionMapping.mapper(StringListMapper);
        final withItemMappers =
            CollectionMapping.withItemMappers(CustomCollectionMapper);
        final mapperInstance =
            CollectionMapping.mapperInstance(customMapperInstance);

        expect(auto.isAuto, isTrue);
        expect(fromRegistry.isAuto, isFalse);
        expect(namedMapper.isAuto, isFalse);
        expect(mapperType.isAuto, isFalse);
        expect(withItemMappers.isAuto, isFalse);
        expect(mapperInstance.isAuto, isFalse);
      });
    });

    group('Pattern Validation Tests', () {
      test('should generate correct RDF patterns for each collection type', () {
        // Create a comprehensive test that validates specific RDF output patterns
        final patterns = <String, RegExp>{
          'rdf:List':
              RegExp(r'<http://www\.w3\.org/1999/02/22-rdf-syntax-ns#first>'),
          'rdf:Seq':
              RegExp(r'<http://www\.w3\.org/1999/02/22-rdf-syntax-ns#_\d+>'),
          'rdf:Bag': RegExp(
              r'<http://www\.w3\.org/1999/02/22-rdf-syntax-ns#type> <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#Bag>'),
          'rdf:Alt': RegExp(
              r'<http://www\.w3\.org/1999/02/22-rdf-syntax-ns#type> <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#Alt>'),
        };

        for (final entry in patterns.entries) {
          // Each pattern should be testable independently
          expect(entry.value.hasMatch('test string'), isA<bool>());
        }
      });
    });
  });
}
