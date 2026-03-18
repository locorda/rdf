import 'package:test/test.dart';
import 'package:locorda_rdf_xml/src/implementations/parsing_impl.dart';

/// Tests for IRI-aware percent-encoding in DefaultUriResolver.
///
/// IRIs (RFC 3987) allow non-ASCII characters as literals. When Dart's
/// Uri.parse percent-encodes them during resolution, DefaultUriResolver
/// must decode them back—while preserving intentional percent-encoding
/// that was already present in the original input.
void main() {
  group('DefaultUriResolver IRI percent-encoding', () {
    late DefaultUriResolver resolver;

    setUp(() {
      resolver = DefaultUriResolver();
    });

    test('decodes non-ASCII introduced by Dart in fragment', () {
      // ü in the fragment should be preserved as a literal IRI character
      final result = resolver.resolveUri('#Dürst', 'http://example.org/');

      expect(result, equals('http://example.org/#Dürst'));
    });

    test('decodes non-ASCII introduced by Dart in path', () {
      final result = resolver.resolveUri('café', 'http://example.org/dir/');

      expect(result, equals('http://example.org/dir/café'));
    });

    test('preserves percent-encoding already in relative URI', () {
      // %C3%A9 (é) is already percent-encoded in the input—preserve it
      final result = resolver.resolveUri(
        'caf%C3%A9',
        'http://example.org/dir/',
      );

      expect(result, equals('http://example.org/dir/caf%C3%A9'));
    });

    test('preserves percent-encoding already in base URI', () {
      final result = resolver.resolveUri(
        '#frag',
        'http://example.org/%C3%BC/doc',
      );

      expect(result, equals('http://example.org/%C3%BC/doc#frag'));
    });

    test('handles mixed: literal non-ASCII in uri, none in base', () {
      final result = resolver.resolveUri('Üntersuchung', 'http://example.org/');

      expect(result, equals('http://example.org/Üntersuchung'));
    });

    test('handles ASCII-only URIs unchanged', () {
      final result = resolver.resolveUri(
        'resource',
        'http://example.org/path/',
      );

      expect(result, equals('http://example.org/path/resource'));
    });

    test('handles absolute IRI with non-ASCII unchanged', () {
      final result = resolver.resolveUri(
        'http://example.org/résumé',
        'http://other.org/',
      );

      expect(result, equals('http://example.org/résumé'));
    });

    test('decodes multi-byte UTF-8 sequence introduced by Dart', () {
      // Japanese character は (U+306F, 3-byte UTF-8: E3 81 AF)
      final result = resolver.resolveUri('#は', 'http://example.org/');

      expect(result, equals('http://example.org/#は'));
    });

    test('preserves intentional percent-encoding of multi-byte character', () {
      // %E3%81%AF is the percent-encoded form of は
      final result = resolver.resolveUri('#%E3%81%AF', 'http://example.org/');

      expect(result, equals('http://example.org/#%E3%81%AF'));
    });

    test('handles empty relative URI with non-ASCII base', () {
      final result = resolver.resolveUri('', 'http://example.org/café');

      // Empty relative resolves to base without fragment
      expect(result, equals('http://example.org/café'));
    });
  });
}
