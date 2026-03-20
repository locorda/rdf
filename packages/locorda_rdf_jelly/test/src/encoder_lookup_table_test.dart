import 'package:locorda_rdf_jelly/src/jelly_encoder_state.dart';
import 'package:test/test.dart';

void main() {
  group('EncoderLookupTable', () {
    test('assigns sequential IDs starting from 1', () {
      final table = EncoderLookupTable(10);

      expect(table.ensureAndGetId('a'), (1, true));
      expect(table.ensureAndGetId('b'), (2, true));
      expect(table.ensureAndGetId('c'), (3, true));
    });

    test('returns isNew=false for already-present values', () {
      final table = EncoderLookupTable(10);

      expect(table.ensureAndGetId('a'), (1, true));
      expect(table.ensureAndGetId('a'), (1, false));
    });

    test('operator[] returns assigned ID', () {
      final table = EncoderLookupTable(10);

      table.ensureAndGetId('a');
      table.ensureAndGetId('b');

      expect(table['a'], 1);
      expect(table['b'], 2);
      expect(table['missing'], isNull);
    });

    test('contains returns true for present values', () {
      final table = EncoderLookupTable(10);

      table.ensureAndGetId('a');

      expect(table.contains('a'), isTrue);
      expect(table.contains('b'), isFalse);
    });

    test('evicts oldest entry when full', () {
      final table = EncoderLookupTable(2);

      expect(table.ensureAndGetId('a'), (1, true)); // fills slot 1
      expect(table.ensureAndGetId('b'), (2, true)); // fills slot 2
      expect(table.ensureAndGetId('c'),
          (1, true)); // evicts 'a' (oldest), reuses ID 1

      expect(table['a'], isNull);
      expect(table['b'], 2);
      expect(table['c'], 1);
    });

    test('reuses evicted ID instead of incrementing', () {
      final table = EncoderLookupTable(2);

      table.ensureAndGetId('a'); // ID 1
      table.ensureAndGetId('b'); // ID 2
      table.ensureAndGetId('c'); // evicts 'a', reuses ID 1
      table.ensureAndGetId('d'); // evicts 'b', reuses ID 2

      expect(table['c'], 1);
      expect(table['d'], 2);
    });

    test('IDs stay within [1, maxSize] after many evictions', () {
      final table = EncoderLookupTable(3);

      for (var i = 0; i < 100; i++) {
        final (id, _) = table.ensureAndGetId('v$i');
        expect(id, inInclusiveRange(1, 3));
      }
    });

    test('re-adding evicted value gets a new assignment', () {
      final table = EncoderLookupTable(2);

      table.ensureAndGetId('a'); // ID 1
      table.ensureAndGetId('b'); // ID 2
      table.ensureAndGetId('c'); // evicts 'a', reuses ID 1

      // 'a' was evicted, re-adding should assign a new entry
      final (newId, isNew) = table.ensureAndGetId('a');
      expect(isNew, isTrue);
      expect(newId, inInclusiveRange(1, 2));
    });

    group('deltaEncode', () {
      test('returns 0 when ID is lastEmittedId + 1', () {
        final table = EncoderLookupTable(10);

        table.lastEmittedId = 0;
        expect(table.deltaEncode(1), 0); // 1 == 0+1

        expect(table.deltaEncode(2), 0); // 2 == 1+1
      });

      test('returns raw ID when not sequential', () {
        final table = EncoderLookupTable(10);

        table.lastEmittedId = 0;
        expect(table.deltaEncode(3), 3); // 3 != 0+1

        // lastEmittedId is now 3
        expect(table.deltaEncode(3), 3); // 3 != 3+1
      });

      test('updates lastEmittedId', () {
        final table = EncoderLookupTable(10);

        table.deltaEncode(5);
        expect(table.lastEmittedId, 5);

        table.deltaEncode(6);
        expect(table.lastEmittedId, 6);
      });
    });
  });
}
