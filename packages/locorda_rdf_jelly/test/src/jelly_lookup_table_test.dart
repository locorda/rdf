import 'package:locorda_rdf_jelly/src/lookup_table.dart';
import 'package:test/test.dart';

void main() {
  group('JellyLookupTable', () {
    test('assigns sequential IDs starting from 1 via delta encoding', () {
      final table = JellyLookupTable(10);

      // rawId=0 → delta: lastId + 1
      expect(table.set(0, 'a'), 1);
      expect(table.set(0, 'b'), 2);
      expect(table.set(0, 'c'), 3);
    });

    test('accepts explicit IDs and returns them', () {
      final table = JellyLookupTable(10);

      expect(table.set(5, 'x'), 5);
      expect(table.set(1, 'y'), 1);
    });

    test('get returns correct value for assigned IDs', () {
      final table = JellyLookupTable(10);

      table.set(0, 'alpha'); // → ID 1
      table.set(0, 'beta'); // → ID 2
      table.set(5, 'gamma');

      expect(table.get(1), 'alpha');
      expect(table.get(2), 'beta');
      expect(table.get(5), 'gamma');
    });

    test('get returns null for empty slots', () {
      final table = JellyLookupTable(10);

      table.set(3, 'x');

      expect(table.get(1), isNull);
      expect(table.get(2), isNull);
      expect(table.get(4), isNull);
    });

    test('get returns null for out-of-range IDs', () {
      final table = JellyLookupTable(4);

      table.set(4, 'x');

      expect(table.get(0), isNull); // below range
      expect(table.get(5), isNull); // above range
    });

    test('lastId tracks the resolved ID of the last set call', () {
      final table = JellyLookupTable(10);

      table.set(0, 'a'); // resolves to 1
      expect(table.lastId, 1);

      table.set(7, 'b');
      expect(table.lastId, 7);

      table.set(0, 'c'); // resolves to 7 + 1 = 8
      expect(table.lastId, 8);
    });

    test('implicit eviction: overwriting a slot replaces the old value', () {
      final table = JellyLookupTable(3);

      table.set(1, 'first');
      table.set(2, 'second');
      table.set(3, 'third');

      // Overwrite slot 1 (simulates encoder cycling back to ID 1)
      table.set(1, 'replacement');

      expect(table.get(1), 'replacement');
      expect(table.get(2), 'second');
      expect(table.get(3), 'third');
    });

    test('IDs stay within [1, maxSize] throughout cycling', () {
      final maxSize = 4;
      final table = JellyLookupTable(maxSize);

      // Fill the table
      for (var i = 1; i <= maxSize; i++) {
        table.set(i, 'v$i');
      }

      // Cycle: encoder reuses IDs 1..maxSize for new values
      for (var i = 1; i <= maxSize; i++) {
        final id = table.set(i, 'new_v$i');
        expect(id, inInclusiveRange(1, maxSize));
        expect(table.get(id), 'new_v$i');
      }
    });

    test('clear resets all entries and lastId', () {
      final table = JellyLookupTable(5);

      table.set(0, 'a');
      table.set(0, 'b');
      table.clear();

      expect(table.lastId, 0);
      expect(table.get(1), isNull);
      expect(table.get(2), isNull);
    });

    test('delta encoding uses lastId from prior explicit set', () {
      final table = JellyLookupTable(10);

      table.set(5, 'at-5'); // explicit → lastId = 5
      table.set(0, 'delta'); // 0 → 5 + 1 = 6

      expect(table.get(5), 'at-5');
      expect(table.get(6), 'delta');
      expect(table.lastId, 6);
    });
  });
}
