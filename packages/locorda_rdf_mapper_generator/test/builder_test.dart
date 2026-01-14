import 'package:build/build.dart';

import 'package:locorda_rdf_mapper_generator/builder.dart';
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
