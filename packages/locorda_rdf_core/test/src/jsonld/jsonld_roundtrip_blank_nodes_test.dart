import 'dart:io';

import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('JSON-LD roundtrip blank nodes', () {
    test('preserves blank node to graph-name value sets', () {
      final shardNq = File(
        '../locorda_rdf_canonicalization/test/assets/realworld/custom/shard.nq',
      ).readAsStringSync();

      final baseDataset = nquads.decode(shardNq);
      final roundtripDataset = jsonld.decode(jsonld.encode(baseDataset));

      final baseValues = _normalizedGraphNameSets(baseDataset);
      final roundtripValues = _normalizedGraphNameSets(roundtripDataset);

      expect(roundtripValues, equals(baseValues));
    });
  });
}

List<String> _normalizedGraphNameSets(RdfDataset dataset) {
  final values = _graphNamesByBlankNodes(dataset)
      .values
      .map(_normalizeGraphNameSet)
      .toList()
    ..sort();
  return values;
}

String _normalizeGraphNameSet(Set<RdfGraphName?> names) {
  final normalized = names
      .map((name) => name == null ? 'default' : name.toString())
      .toList()
    ..sort();
  return normalized.join('|');
}

Map<BlankNodeTerm, Set<RdfGraphName?>> _graphNamesByBlankNodes(
  RdfDataset dataset,
) {
  return dataset.quads.fold(<BlankNodeTerm, Set<RdfGraphName?>>{}, (acc, quad) {
    if (quad.subject is BlankNodeTerm) {
      acc
          .putIfAbsent(quad.subject as BlankNodeTerm, () => <RdfGraphName?>{})
          .add(quad.graphName);
    }
    if (quad.object is BlankNodeTerm) {
      acc
          .putIfAbsent(quad.object as BlankNodeTerm, () => <RdfGraphName?>{})
          .add(quad.graphName);
    }
    return acc;
  });
}
