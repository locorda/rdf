import 'package:test/test.dart';
import 'package:rdf_canonicalization/src/canonical/blank_node_hasher.dart';

void main() {
  group('BlankNodeHasher.createPermutations', () {
    test('should return empty list for empty input', () {
      final result = BlankNodeHasher.createPermutations([]);
      expect(result, equals([[]]));
    });

    test('should return single element for single input', () {
      final result = BlankNodeHasher.createPermutations(['a']);
      expect(result, equals([['a']]));
    });

    test('should return correct permutations for two elements', () {
      final result = BlankNodeHasher.createPermutations(['a', 'b']);
      expect(result, containsAll([
        ['a', 'b'],
        ['b', 'a']
      ]));
      expect(result.length, equals(2));
    });

    test('should return correct permutations for three elements', () {
      final result = BlankNodeHasher.createPermutations(['a', 'b', 'c']);
      expect(result, containsAll([
        ['a', 'b', 'c'],
        ['a', 'c', 'b'],
        ['b', 'a', 'c'],
        ['b', 'c', 'a'],
        ['c', 'a', 'b'],
        ['c', 'b', 'a']
      ]));
      expect(result.length, equals(6));
    });

    test('should generate correct number of permutations (n!)', () {
      expect(BlankNodeHasher.createPermutations(['a']).length, equals(1));
      expect(BlankNodeHasher.createPermutations(['a', 'b']).length, equals(2));
      expect(BlankNodeHasher.createPermutations(['a', 'b', 'c']).length, equals(6));
      expect(BlankNodeHasher.createPermutations(['a', 'b', 'c', 'd']).length, equals(24));
    });

    test('should handle duplicate elements as separate entities', () {
      final result = BlankNodeHasher.createPermutations(['a', 'a']);
      expect(result.length, equals(2));
      expect(result, containsAll([
        ['a', 'a'],
        ['a', 'a']
      ]));
    });

    test('should preserve element order within permutations', () {
      final result = BlankNodeHasher.createPermutations(['x', 'y', 'z']);

      // Check that each permutation contains all original elements
      for (final perm in result) {
        expect(perm.length, equals(3));
        expect(perm, contains('x'));
        expect(perm, contains('y'));
        expect(perm, contains('z'));
      }
    });

    test('should work with blank node identifier strings', () {
      final result = BlankNodeHasher.createPermutations(['_:b0', '_:b1', '_:b2']);
      expect(result.length, equals(6));

      // Verify specific permutations exist
      expect(result, anyElement(orderedEquals(['_:b0', '_:b1', '_:b2'])));
      expect(result, anyElement(orderedEquals(['_:b2', '_:b1', '_:b0'])));
    });

    test('should generate all unique permutations for four elements', () {
      final result = BlankNodeHasher.createPermutations(['a', 'b', 'c', 'd']);

      // Convert to Set to check uniqueness
      final uniquePerms = result.map((perm) => perm.join(',')).toSet();
      expect(uniquePerms.length, equals(24));
      expect(result.length, equals(24));
    });
  });
}