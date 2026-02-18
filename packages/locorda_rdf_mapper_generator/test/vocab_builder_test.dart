import 'package:build/build.dart';
import 'package:locorda_rdf_mapper_generator/vocab_builder.dart';
import 'package:test/test.dart';

void main() {
  group('VocabBuilder', () {
    test('buildExtensions defaults to lib/vocab.g.ttl', () {
      final builder = VocabBuilder(BuilderOptions(const {}));
      expect(
        builder.buildExtensions['pubspec.yaml'],
        equals(['lib/vocab.g.ttl']),
      );
    });

    test('buildExtensions uses configured vocabularies', () {
      final builder = VocabBuilder(BuilderOptions({
        'vocabularies': {
          'https://example.com/vocab#': {
            'output_file': 'lib/vocab.g.ttl',
          },
          'https://example.com/contracts#': {
            'output_file': 'lib/contracts.g.ttl',
          }
        }
      }));

      final outputs = builder.buildExtensions['pubspec.yaml'];
      expect(outputs, isNotNull);
      expect(outputs, containsAll(['lib/vocab.g.ttl', 'lib/contracts.g.ttl']));
    });

    test('buildExtensions supports vocabularies shorthand syntax', () {
      final builder = VocabBuilder(BuilderOptions({
        'vocabularies': {
          'https://example.com/vocab#': 'lib/vocab.g.ttl',
        }
      }));

      expect(
        builder.buildExtensions['pubspec.yaml'],
        contains('lib/vocab.g.ttl'),
      );
    });
  });
}
