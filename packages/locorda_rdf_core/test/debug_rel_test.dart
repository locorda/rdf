import 'package:locorda_rdf_core/src/iri_util.dart';
import 'package:test/test.dart';

void main() {
  test('relativize same', () {
    final result = relativizeIri('http://example.com/api/things/1', 'http://example.com/api/things/1');
    print('Result: "$result"');
  });
}
