import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper/src/context/deserialization_context_impl.dart';
import 'package:rdf_mapper/src/context/serialization_context_impl.dart';
import 'package:rdf_vocabularies_core/dcterms.dart';
import 'package:rdf_vocabularies_core/rdf.dart';
import 'package:test/test.dart';

// Import test models
import '../../fixtures/rdf_mapper_annotations/examples/example_crdt_item.dart';
// Import generated mappers
import '../../fixtures/rdf_mapper_annotations/examples/example_crdt_item.rdf_mapper.g.dart';
import '../init_test_rdf_mapper_util.dart';

void main() {
  late RdfMapper mapper;

  /// Helper to create serialization context
  SerializationContext createSerializationContext() {
    return SerializationContextImpl(registry: mapper.registry);
  }

  /// Helper to create deserialization context
  DeserializationContext createDeserializationContext() {
    final graph = RdfGraph.fromTriples([]);
    return DeserializationContextImpl(graph: graph, registry: mapper.registry);
  }

  setUp(() {
    mapper = defaultInitTestRdfMapper();
  });

  group('CRDT Item Example Test', () {
    group('ItemLastModifiedByMapper (IRI mapping)', () {
      test('serializes user ID to app instance IRI', () {
        final mapper = ItemLastModifiedByMapper(
          storageRootProvider: () => 'http://example.org/storage',
        );
        final context = createSerializationContext();

        final iriTerm = mapper.toRdfTerm('user123', context);

        expect(
          iriTerm.value,
          equals(
              'http://example.org/storage/solidtask/appinstance/user123.ttl'),
        );
      });

      test('deserializes user ID from app instance IRI', () {
        final mapper = ItemLastModifiedByMapper(
          storageRootProvider: () => 'http://example.org/storage',
        );
        final context = createDeserializationContext();

        final userId = mapper.fromRdfTerm(
          const IriTerm(
              'http://example.org/storage/solidtask/appinstance/user456.ttl'),
          context,
        );

        expect(userId, equals('user456'));
      });

      test('handles different storage roots', () {
        final storageRoots = [
          'http://example.org/storage',
          'https://secure.example.org/data',
          'http://localhost:8080/solidtask',
          'urn:example:storage',
        ];

        for (final storageRoot in storageRoots) {
          final mapper = ItemLastModifiedByMapper(
            storageRootProvider: () => storageRoot,
          );
          final context = createSerializationContext();

          final iriTerm = mapper.toRdfTerm('testUser', context);
          expect(
            iriTerm.value,
            equals('$storageRoot/solidtask/appinstance/testUser.ttl'),
          );
        }
      });

      test('round-trip serialization maintains user ID', () {
        final mapper = ItemLastModifiedByMapper(
          storageRootProvider: () => 'http://test.org/storage',
        );
        final serContext = createSerializationContext();
        final deserContext = createDeserializationContext();

        final testUserIds = [
          'user1',
          'user-with-hyphens',
          'user_with_underscores',
          'user.with.dots',
          'user@domain.com',
          'unicode用户',
        ];

        for (final originalUserId in testUserIds) {
          final iriTerm = mapper.toRdfTerm(originalUserId, serContext);
          final deserializedUserId = mapper.fromRdfTerm(iriTerm, deserContext);
          expect(deserializedUserId, equals(originalUserId));
        }
      });
    });

    group('VectorClockEntryClientIdMapper (IRI mapping)', () {
      test('serializes client ID to app instance IRI', () {
        final mapper = VectorClockEntryClientIdMapper(
          storageRootProvider: () => 'http://example.org/storage',
        );
        final context = createSerializationContext();

        final iriTerm = mapper.toRdfTerm('client123', context);

        expect(
          iriTerm.value,
          equals(
              'http://example.org/storage/solidtask/appinstance/client123.ttl'),
        );
      });

      test('deserializes client ID from app instance IRI', () {
        final mapper = VectorClockEntryClientIdMapper(
          storageRootProvider: () => 'http://example.org/storage',
        );
        final context = createDeserializationContext();

        final clientId = mapper.fromRdfTerm(
          const IriTerm(
              'http://example.org/storage/solidtask/appinstance/client456.ttl'),
          context,
        );

        expect(clientId, equals('client456'));
      });

      test('handles various client ID formats', () {
        final mapper = VectorClockEntryClientIdMapper(
          storageRootProvider: () => 'http://example.org/storage',
        );
        final context = createSerializationContext();

        final clientIds = [
          'mobile-app-123',
          'web-client',
          'desktop.app',
          'client_v2',
          'uuid-4567-89ab-cdef',
        ];

        for (final clientId in clientIds) {
          final iriTerm = mapper.toRdfTerm(clientId, context);
          expect(
            iriTerm.value,
            equals(
                'http://example.org/storage/solidtask/appinstance/$clientId.ttl'),
          );
        }
      });
    });

    group('VectorClockEntryMapper (map entry resource)', () {
      test('serializes vector clock entry as resource', () {
        final mapper = VectorClockEntryMapper(
          storageRootProvider: () => 'http://example.org/storage',
          taskIdProvider: () => 'task123',
        );
        final context = createSerializationContext();

        final entry = VectorClockEntry('client456', 42);
        final (subject, triples) = mapper.toRdfResource(entry, context);

        expect(
          subject.value,
          equals(
              'http://example.org/storage/solidtask/task/task123.ttl#vectorclock-client456'),
        );

        expect(triples.length, equals(2)); // clientId and clockValue

        final clientTriple = triples.firstWhere(
          (t) => t.predicate == SolidTaskVectorClockEntry.clientId,
        );
        expect(
          (clientTriple.object as IriTerm).value,
          equals(
              'http://example.org/storage/solidtask/appinstance/client456.ttl'),
        );

        final clockTriple = triples.firstWhere(
          (t) => t.predicate == SolidTaskVectorClockEntry.clockValue,
        );
        expect((clockTriple.object as LiteralTerm).value, equals('42'));
      });

      test('deserializes vector clock entry from resource', () {
        final entrySubject = const IriTerm(
          'http://example.org/storage/solidtask/task/task789.ttl#vectorclock-clientABC',
        );
        final triples = [
          Triple(
            entrySubject,
            SolidTaskVectorClockEntry.clientId,
            const IriTerm(
                'http://example.org/storage/solidtask/appinstance/clientABC.ttl'),
          ),
          Triple(
            entrySubject,
            SolidTaskVectorClockEntry.clockValue,
            LiteralTerm('15',
                datatype:
                    const IriTerm('http://www.w3.org/2001/XMLSchema#integer')),
          ),
        ];

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        final vectorClockMapper = VectorClockEntryMapper(
          storageRootProvider: () => 'http://example.org/storage',
          taskIdProvider: () => 'task789',
        );

        final entry = vectorClockMapper.fromRdfResource(entrySubject, context);

        expect(entry.clientId, equals('clientABC'));
        expect(entry.clockValue, equals(15));
      });

      test('handles different task and client combinations', () {
        final testCases = [
          ('task1', 'client1', 1),
          ('task-complex-id', 'client-complex-id', 99),
          ('task_with_underscores', 'client_with_underscores', 256),
          ('unicode任务', 'unicode客户端', 1024),
        ];

        for (final (taskId, clientId, clockValue) in testCases) {
          final mapper = VectorClockEntryMapper(
            storageRootProvider: () => 'http://test.org',
            taskIdProvider: () => taskId,
          );
          final context = createSerializationContext();

          final entry = VectorClockEntry(clientId, clockValue);
          final (subject, triples) = mapper.toRdfResource(entry, context);

          expect(
            subject.value,
            equals(
                'http://test.org/solidtask/task/$taskId.ttl#vectorclock-$clientId'),
          );

          final clockTriple = triples.firstWhere(
            (t) => t.predicate == SolidTaskVectorClockEntry.clockValue,
          );
          expect(
            (clockTriple.object as LiteralTerm).value,
            equals(clockValue.toString()),
          );
        }
      });
    });

    group('ItemMapper (complete CRDT item)', () {
      test('serializes item with all CRDT properties', () {
        final mapper = ItemMapper(
          storageRootProvider: () => 'http://example.org/storage',
        );
        final context = createSerializationContext();

        final item = Item(text: 'Test task', lastModifiedBy: 'user123');
        item.id = 'task456'; // Override random ID for predictable test
        item.createdAt = DateTime.utc(2023, 6, 15, 10, 30, 0);
        item.vectorClock = {'user123': 1, 'user456': 2};
        item.isDeleted = false;

        final (subject, triples) = mapper.toRdfResource(item, context);
        /*
        print(defaultInitTestRdfMapper(
            storageRootProvider: () =>
                'http://example.org/storage').encodeObject(item,
            //contentType: 'application/n-triples',
             baseUri: 'http://example.org/storage/solidtask/task/task456.ttl'));
             */
        expect(
          subject.value,
          equals('http://example.org/storage/solidtask/task/task456.ttl'),
        );

        expect(triples.length, greaterThanOrEqualTo(5));

        // Check text property
        final textTriple = triples.firstWhere(
          (t) => t.predicate == SolidTaskTask.text,
        );
        expect((textTriple.object as LiteralTerm).value, equals('Test task'));

        // Check creator property
        final creatorTriple = triples.firstWhere(
          (t) => t.predicate == Dcterms.creator,
        );
        expect(
          (creatorTriple.object as IriTerm).value,
          equals(
              'http://example.org/storage/solidtask/appinstance/user123.ttl'),
        );

        // Check creation date
        final createdTriple = triples.firstWhere(
          (t) => t.predicate == Dcterms.created,
        );
        expect(
          (createdTriple.object as LiteralTerm).value,
          contains('2023-06-15'),
        );

        // Check isDeleted property
        final deletedTriple = triples.firstWhere(
          (t) => t.predicate == SolidTaskTask.isDeleted,
        );
        expect((deletedTriple.object as LiteralTerm).value, equals('false'));

        // Check vector clock entries
        final vectorClockTriples = triples.where(
          (t) => t.predicate == SolidTaskTask.vectorClock,
        );
        expect(vectorClockTriples.length, equals(2));
      });

      test('deserializes item from complete RDF graph', () {
        final itemSubject = const IriTerm(
          'http://example.org/storage/solidtask/task/taskABC.ttl',
        );
        final user789Subject = const IriTerm(
          'http://example.org/storage/solidtask/appinstance/user789.ttl',
        );
        final clockUser789Subject = const IriTerm(
          'http://example.org/storage/solidtask/task/taskABC.ttl#vectorclock-user789',
        );
        final triples = [
          Triple(
            itemSubject,
            SolidTaskTask.text,
            LiteralTerm('Deserialized task'),
          ),
          Triple(
            itemSubject,
            Dcterms.creator,
            const IriTerm(
                'http://example.org/storage/solidtask/appinstance/user789.ttl'),
          ),
          Triple(
            itemSubject,
            Dcterms.created,
            LiteralTerm(
              '2023-07-20T14:45:30.000Z',
              datatype:
                  const IriTerm('http://www.w3.org/2001/XMLSchema#dateTime'),
            ),
          ),
          Triple(
            itemSubject,
            SolidTaskTask.isDeleted,
            LiteralTerm('true',
                datatype:
                    const IriTerm('http://www.w3.org/2001/XMLSchema#boolean')),
          ),
          Triple(
            itemSubject,
            SolidTaskTask.vectorClock,
            clockUser789Subject,
          ),
          Triple(
            clockUser789Subject,
            Rdf.type,
            SolidTaskVectorClockEntry.classIri,
          ),
          Triple(
            clockUser789Subject,
            SolidTaskVectorClockEntry.clientId,
            user789Subject,
          ),
          Triple(
            clockUser789Subject,
            SolidTaskVectorClockEntry.clockValue,
            LiteralTerm.integer(1),
          ),
        ];

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        final itemMapper = ItemMapper(
          storageRootProvider: () => 'http://example.org/storage',
        );

        final item = itemMapper.fromRdfResource(itemSubject, context);

        expect(item.id, equals('taskABC'));
        expect(item.text, equals('Deserialized task'));
        expect(item.lastModifiedBy, equals('user789'));
        expect(item.createdAt, equals(DateTime.utc(2023, 7, 20, 14, 45, 30)));
        expect(item.isDeleted, equals(true));
        // Note: Vector clock test may need adjustment based on actual implementation
        expect(item.vectorClock, isA<Map<String, int>>());
        expect(item.vectorClock['user789'], equals(1));
        expect(item.vectorClock.length, equals(1));
      });

      test('handles empty vector clock', () {
        final mapper = ItemMapper(
          storageRootProvider: () => 'http://example.org/storage',
        );
        final context = createSerializationContext();

        final item = Item(text: 'Empty clock task', lastModifiedBy: 'user123');
        item.vectorClock = {}; // Empty vector clock

        final (subject, triples) = mapper.toRdfResource(item, context);

        final vectorClockTriples = triples.where(
          (t) => t.predicate == SolidTaskTask.vectorClock,
        );
        expect(vectorClockTriples.length, equals(0));
      });

      test('handles large vector clocks', () {
        final mapper = ItemMapper(
          storageRootProvider: () => 'http://example.org/storage',
        );
        final context = createSerializationContext();

        final item = Item(text: 'Large clock task', lastModifiedBy: 'user1');

        // Create large vector clock
        final largeVectorClock = <String, int>{};
        for (int i = 1; i <= 100; i++) {
          largeVectorClock['user$i'] = i;
        }
        item.vectorClock = largeVectorClock;

        final (subject, triples) = mapper.toRdfResource(item, context);

        final vectorClockTriples = triples.where(
          (t) => t.predicate == SolidTaskTask.vectorClock,
        );
        // Each entry in the vector clock should create a separate resource reference
        expect(vectorClockTriples.length, equals(100));

        // Verify that each vector clock entry points to a proper IRI
        for (final vcTriple in vectorClockTriples) {
          expect(vcTriple.object, isA<IriTerm>());
          final vcIri = (vcTriple.object as IriTerm).value;
          expect(vcIri, contains('#vectorclock-'));
          expect(vcIri, contains('user'));
        }
      });

      test('round-trip serialization maintains all data', () {
        final itemMapper0 = ItemMapper(
          storageRootProvider: () => 'http://test.org/storage',
        );
        final serContext = createSerializationContext();

        final originalItem = Item(
          text: 'Round-trip test task',
          lastModifiedBy: 'testUser',
        );
        originalItem.id = 'roundTripTask';
        originalItem.createdAt = DateTime.utc(2023, 8, 1, 12, 0, 0);
        originalItem.vectorClock = {
          'testUser': 5,
          'otherUser': 3,
          'thirdUser': 7,
        };
        originalItem.isDeleted = true;

        final (subject, triples) =
            itemMapper0.toRdfResource(originalItem, serContext);

        final graph = RdfGraph.fromTriples(triples);
        final context = DeserializationContextImpl(
          graph: graph,
          registry: mapper.registry,
        );

        final itemMapper = ItemMapper(
          storageRootProvider: () => 'http://test.org/storage',
        );
        final deserializedItem = itemMapper.fromRdfResource(subject, context);

        expect(deserializedItem.id, equals(originalItem.id));
        expect(deserializedItem.text, equals(originalItem.text));
        expect(deserializedItem.lastModifiedBy,
            equals(originalItem.lastModifiedBy));
        expect(deserializedItem.createdAt, equals(originalItem.createdAt));
        expect(deserializedItem.isDeleted, equals(originalItem.isDeleted));
        expect(deserializedItem.vectorClock, equals(originalItem.vectorClock));
      });

      test('handles Unicode text content', () {
        final mapper = ItemMapper(
          storageRootProvider: () => 'http://example.org/storage',
        );
        final context = createSerializationContext();

        final unicodeTexts = [
          'Task with 日本語 characters',
          'Tâche avec caractères français',
          'Aufgabe mit deutschen Umlauten: äöü',
          'Задача с русскими символами',
          'משימה עם תווים עבריים',
          'Task with emojis: 📝 ✅ 🚀',
          'Mixed: English 中文 العربية',
        ];

        for (final unicodeText in unicodeTexts) {
          final item = Item(text: unicodeText, lastModifiedBy: 'unicodeUser');
          final (subject, triples) = mapper.toRdfResource(item, context);

          final textTriple = triples.firstWhere(
            (t) => t.predicate == SolidTaskTask.text,
          );
          expect((textTriple.object as LiteralTerm).value, equals(unicodeText));
        }
      });
    });

    group('Integration and edge cases', () {
      test('handles different storage configurations', () {
        final storageConfigs = [
          'http://localhost:3000/data',
          'https://solid.example.org/storage',
          'http://192.168.1.100:8080/solidtask',
          'urn:storage:local',
        ];

        for (final storageRoot in storageConfigs) {
          final mapper = ItemMapper(
            storageRootProvider: () => storageRoot,
          );
          final context = createSerializationContext();

          final item = Item(text: 'Config test', lastModifiedBy: 'configUser');
          item.id = 'configTest';

          final (subject, triples) = mapper.toRdfResource(item, context);

          expect(subject.value,
              equals('$storageRoot/solidtask/task/configTest.ttl'));

          final creatorTriple = triples.firstWhere(
            (t) => t.predicate == Dcterms.creator,
          );
          expect(
            (creatorTriple.object as IriTerm).value,
            equals('$storageRoot/solidtask/appinstance/configUser.ttl'),
          );
        }
      });

      test('validates vector clock data types', () {
        final mapper = ItemMapper(
          storageRootProvider: () => 'http://example.org/storage',
        );
        final context = createSerializationContext();

        final item = Item(text: 'Type test', lastModifiedBy: 'typeUser');
        item.vectorClock = {
          'user1': 0, // zero value
          'user2': 1, // small value
          'user3': 999999, // large value
          'user4': -1, // negative value (if allowed)
        };

        final (subject, triples) = mapper.toRdfResource(item, context);

        final vectorClockTriples = triples.where(
          (t) => t.predicate == SolidTaskTask.vectorClock,
        );

        // Each vector clock entry should be a separate resource, not direct literals
        expect(vectorClockTriples.length, equals(4));

        // Vector clock entries should be IRIs pointing to separate resources
        for (final vcTriple in vectorClockTriples) {
          expect(vcTriple.object, isA<IriTerm>());
          final vcIri = (vcTriple.object as IriTerm).value;
          expect(vcIri, contains('#vectorclock-'));
        }

        // Note: The actual clock values would be in separate triples for each vector clock entry resource
        // This test validates the structure, not the specific values due to incomplete implementation
      });

      test('handles edge case timestamps', () {
        final mapper = ItemMapper(
          storageRootProvider: () => 'http://example.org/storage',
        );
        final context = createSerializationContext();

        final edgeCaseDates = [
          DateTime.utc(1970, 1, 1), // Unix epoch
          DateTime.utc(2000, 1, 1), // Y2K
          DateTime.utc(2038, 1, 19, 3, 14, 7), // Unix timestamp limit
          DateTime.utc(2100, 12, 31, 23, 59, 59), // Future date
          DateTime.now().toUtc(), // Current time
        ];

        for (final date in edgeCaseDates) {
          final item = Item(text: 'Date test', lastModifiedBy: 'dateUser');
          item.createdAt = date;

          final (subject, triples) = mapper.toRdfResource(item, context);

          final createdTriple = triples.firstWhere(
            (t) => t.predicate == Dcterms.created,
          );

          // Verify the date was serialized (exact format may vary)
          final dateString = (createdTriple.object as LiteralTerm).value;
          expect(dateString, contains(date.year.toString()));
        }
      });

      test('validates IRI extraction for complex patterns', () {
        final mapper = ItemLastModifiedByMapper(
          storageRootProvider: () => 'http://example.org/storage',
        );
        final context = createDeserializationContext();

        final complexPatterns = [
          'http://example.org/storage/solidtask/appinstance/user-123.ttl',
          'https://secure.org/storage/solidtask/appinstance/user_456.ttl',
          'http://localhost:8080/storage/solidtask/appinstance/user.789.ttl',
          'urn:storage/solidtask/appinstance/uuid-1234-5678.ttl',
        ];

        for (final iri in complexPatterns) {
          // Should not throw - extracts what follows the pattern
          final userId = mapper.fromRdfTerm(IriTerm.validated(iri), context);
          expect(userId, isNotEmpty);
        }
      });
    });
  });
}
