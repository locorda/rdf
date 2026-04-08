import 'package:locorda_rdf_core/src/iri_util.dart';

void main() {
  final base = 'https://w3c.github.io/json-ld-api/tests/compact/0066-in.jsonld';
  print('query: ${relativizeIri("https://w3c.github.io/json-ld-api/tests/compact/0066-in.jsonld?query=works", base)}');
  print('tests/: ${relativizeIri("https://w3c.github.io/json-ld-api/tests/", base)}');
  print('api/: ${relativizeIri("https://w3c.github.io/json-ld-api/", base)}');
  print('parent: ${relativizeIri("https://w3c.github.io/json-ld-api/parent", base)}');
  print('parent-parent: ${relativizeIri("https://w3c.github.io/parent-parent-eq-root", base)}');
  print('still-root: ${relativizeIri("https://w3c.github.io/still-root", base)}');
  print('link: ${relativizeIri("https://w3c.github.io/json-ld-api/tests/compact/link", base)}');
  print('frag: ${relativizeIri("https://w3c.github.io/json-ld-api/tests/compact/0066-in.jsonld#fragment-works", base)}');
}
