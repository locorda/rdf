import 'package:build/build.dart';

import 'package:rdf_mapper_generator/rdf_mapper_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Builder Tests', () {
    test('rdfMapperCacheBuilder returns an instance of RdfMapperCacheBuilder',
        () {
      // Create dummy BuilderOptions
      final builderOptions = BuilderOptions({});
      final builder = rdfMapperCacheBuilder(builderOptions);
      expect(builder, isA<RdfMapperCacheBuilder>());
    });
  });
}
