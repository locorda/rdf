import 'package:locorda_rdf_mapper_generator/src/utils/iri_parser.dart';
import 'package:test/test.dart';

void main() {
  group('parseIriParts', () {
    test('should parse basic IRI with baseUri and id', () {
      final iriParts = parseIriParts('https://my.host.de/test/persons/234',
          '{+baseUri}/persons/{thisId}', ['baseUri', 'thisId']);

      expect(iriParts['thisId'], '234');
      expect(iriParts['baseUri'], 'https://my.host.de/test');
    });

    test('should parse IRI with multiple path segments in baseUri', () {
      final iriParts = parseIriParts(
          'https://api.example.com/v1/data/users/123',
          '{+baseUri}/users/{id}',
          ['baseUri', 'id']);

      expect(iriParts['id'], '123');
      expect(iriParts['baseUri'], 'https://api.example.com/v1/data');
    });

    test('should parse IRI with single variable', () {
      final iriParts = parseIriParts('user123', '{userId}', ['userId']);

      expect(iriParts['userId'], 'user123');
    });

    test('should parse IRI with variable at the beginning', () {
      final iriParts = parseIriParts(
          'admin/settings/theme', '{role}/settings/theme', ['role']);

      expect(iriParts['role'], 'admin');
    });

    test('should parse IRI with variable in the middle', () {
      final iriParts = parseIriParts(
          'api/v2/products', 'api/{version}/products', ['version']);

      expect(iriParts['version'], 'v2');
    });

    test('should parse IRI with multiple variables', () {
      final iriParts = parseIriParts(
          'https://example.com/users/john/posts/42',
          '{+base}/users/{username}/posts/{postId}',
          ['base', 'username', 'postId']);

      expect(iriParts['base'], 'https://example.com');
      expect(iriParts['username'], 'john');
      expect(iriParts['postId'], '42');
    });

    test('should parse IRI with consecutive variables', () {
      // Note: This is inherently ambiguous - we need at least one separator
      // Testing with a dot separator to make it unambiguous
      final iriParts = parseIriParts(
          'file123.txt', '{name}.{extension}', ['name', 'extension']);

      expect(iriParts['name'], 'file123');
      expect(iriParts['extension'], 'txt');
    });

    test('should parse IRI with numeric IDs', () {
      final iriParts = parseIriParts('https://db.example.com/records/999999',
          '{+baseUrl}/records/{recordId}', ['baseUrl', 'recordId']);

      expect(iriParts['baseUrl'], 'https://db.example.com');
      expect(iriParts['recordId'], '999999');
    });

    test('should parse IRI with UUID-like IDs', () {
      final iriParts = parseIriParts(
          'https://api.service.com/entities/550e8400-e29b-41d4-a716-446655440000',
          '{+baseUri}/entities/{entityId}',
          ['baseUri', 'entityId']);

      expect(iriParts['baseUri'], 'https://api.service.com');
      expect(iriParts['entityId'], '550e8400-e29b-41d4-a716-446655440000');
    });

    test('should parse IRI with special characters in ID', () {
      final iriParts = parseIriParts('https://example.com/items/item-name_123',
          '{+base}/items/{itemId}', ['base', 'itemId']);

      expect(iriParts['base'], 'https://example.com');
      expect(iriParts['itemId'], 'item-name_123');
    });

    test('should handle IRI with query parameters (not in template)', () {
      final iriParts = parseIriParts(
          'https://example.com/users/123?format=json',
          '{+baseUri}/users/{userId}',
          ['baseUri', 'userId']);

      expect(iriParts['baseUri'], 'https://example.com');
      expect(iriParts['userId'], '123?format=json');
    });

    test('should handle IRI with fragment (not in template)', () {
      final iriParts = parseIriParts('https://example.com/docs/page#section1',
          '{+baseUri}/docs/{pageId}', ['baseUri', 'pageId']);

      expect(iriParts['baseUri'], 'https://example.com');
      expect(iriParts['pageId'], 'page#section1');
    });

    test('should handle IRI with fragment (in template)', () {
      final iriParts = parseIriParts('https://example.com/docs/page#section1',
          '{+baseUri}/docs/{pageId}#section1', ['baseUri', 'pageId']);

      expect(iriParts['baseUri'], 'https://example.com');
      expect(iriParts['pageId'], 'page');
    });

    test('should return empty map when IRI does not match template', () {
      final iriParts = parseIriParts('https://example.com/different/structure',
          '{baseUri}/users/{userId}', ['baseUri', 'userId']);

      expect(iriParts, isEmpty);
    });

    test('should return empty map when template has more segments than IRI',
        () {
      final iriParts = parseIriParts('https://example.com/users',
          '{+baseUri}/users/{userId}/profile', ['baseUri', 'userId']);

      expect(iriParts, isEmpty);
    });

    test('should handle localhost URLs', () {
      final iriParts = parseIriParts('http://localhost:8080/api/items/456',
          '{+baseUrl}/api/items/{itemId}', ['baseUrl', 'itemId']);

      expect(iriParts['baseUrl'], 'http://localhost:8080');
      expect(iriParts['itemId'], '456');
    });

    test('should handle file URLs', () {
      final iriParts = parseIriParts('file:///home/user/documents/report.pdf',
          'file:///{+path}/documents/{filename}', ['path', 'filename']);

      expect(iriParts['path'], 'home/user');
      expect(iriParts['filename'], 'report.pdf');
    });

    test('should handle file URLs without extension', () {
      final iriParts = parseIriParts('file:///home/user/documents/report.pdf',
          'file:///{+path}/documents/{filename}.pdf', ['path', 'filename']);

      expect(iriParts['path'], 'home/user');
      expect(iriParts['filename'], 'report');
    });

    test('should handle URLs without extension', () {
      final iriParts = parseIriParts('http://example.com/report.pdf',
          '{+baseUri}/{filename}.pdf', ['baseUri', 'filename']);

      expect(iriParts['baseUri'], 'http://example.com');
      expect(iriParts['filename'], 'report');
    });

    test('should handle URNs', () {
      final iriParts = parseIriParts('urn:isbn:0451450523',
          'urn:{type}:{identifier}', ['type', 'identifier']);

      expect(iriParts['type'], 'isbn');
      expect(iriParts['identifier'], '0451450523');
    });

    test('should handle relative paths', () {
      final iriParts = parseIriParts('docs/api/reference',
          '{section}/{subsection}/{page}', ['section', 'subsection', 'page']);

      expect(iriParts['section'], 'docs');
      expect(iriParts['subsection'], 'api');
      expect(iriParts['page'], 'reference');
    });

    test('should handle empty segments gracefully', () {
      final iriParts = parseIriParts('https://example.com//users/123',
          '{+baseUri}//users/{id}', ['baseUri', 'id']);

      expect(iriParts['baseUri'], 'https://example.com');
      expect(iriParts['id'], '123');
    });

    test('should handle template with only literal parts (no variables)', () {
      final iriParts =
          parseIriParts('static/path/here', 'static/path/here', []);

      expect(iriParts, isEmpty);
    });

    test('should handle variables with underscores and numbers', () {
      final iriParts = parseIriParts(
          'https://api.example.com/v1/user_profiles/user_123',
          '{+base_url}/v1/user_profiles/{user_id}',
          ['base_url', 'user_id']);

      expect(iriParts['base_url'], 'https://api.example.com');
      expect(iriParts['user_id'], 'user_123');
    });

    test('should handle very long URIs', () {
      final longUri =
          'https://very.long.domain.name.example.com/api/v2/extremely/long/path/with/many/segments/final/resource/12345';
      final iriParts = parseIriParts(
          longUri, '{+baseUri}/final/resource/{id}', ['baseUri', 'id']);

      expect(iriParts['baseUri'],
          'https://very.long.domain.name.example.com/api/v2/extremely/long/path/with/many/segments');
      expect(iriParts['id'], '12345');
    });

    test('should handle URI with port numbers', () {
      final iriParts = parseIriParts(
          'https://example.com:9443/secure/api/data/789',
          '{+baseUri}/data/{dataId}',
          ['baseUri', 'dataId']);

      expect(iriParts['baseUri'], 'https://example.com:9443/secure/api');
      expect(iriParts['dataId'], '789');
    });

    test('should handle international domain names', () {
      final iriParts = parseIriParts(
          'https://münchen.example.de/resources/item-456',
          '{+baseUri}/resources/{resourceId}',
          ['baseUri', 'resourceId']);

      expect(iriParts['baseUri'], 'https://münchen.example.de');
      expect(iriParts['resourceId'], 'item-456');
    });

    test('should handle empty variable values', () {
      final iriParts =
          parseIriParts('api//test', 'api/{emptyVar}/test', ['emptyVar']);

      expect(iriParts['emptyVar'], '');
    });

    test('should handle variables with special regex characters', () {
      final iriParts = parseIriParts('api/v1.2/items/item-123.json',
          'api/{version}/items/{itemFile}', ['version', 'itemFile']);

      expect(iriParts['version'], 'v1.2');
      expect(iriParts['itemFile'], 'item-123.json');
    });

    test('should handle template with encoded characters', () {
      final iriParts = parseIriParts(
          'https://example.com/users/john%20doe/profile',
          '{+baseUri}/users/{username}/profile',
          ['baseUri', 'username']);

      expect(iriParts['baseUri'], 'https://example.com');
      expect(iriParts['username'], 'john%20doe');
    });

    test('should handle malformed templates gracefully', () {
      final iriParts = parseIriParts('https://example.com/test',
          '{unclosedVariable/test', ['unclosedVariable']);

      expect(iriParts, isEmpty);
    });

    test('should handle case where variable is not in template', () {
      final iriParts = parseIriParts('https://example.com/test',
          'https://example.com/test', ['nonExistentVar']);

      expect(iriParts, isEmpty);
    });

    test('should handle very short URIs', () {
      final iriParts = parseIriParts('a', '{singleChar}', ['singleChar']);

      expect(iriParts['singleChar'], 'a');
    });

    test('should handle multiple occurrences of same variable pattern', () {
      // This tests a potential edge case in replaceFirst
      final iriParts =
          parseIriParts('prefix_test_suffix', 'prefix_{var}_suffix', ['var']);

      expect(iriParts['var'], 'test');
    });

    // Tests specifically for RFC 6570 reserved expansion functionality
    group('RFC 6570 reserved expansion tests', () {
      test('should distinguish between default and +reserved expansion', () {
        // Default behavior: baseUri should NOT include slashes
        final iriPartsDefault = parseIriParts(
            'https://example.com/api/users/123',
            'https://{baseUri}/api/users/{id}',
            ['baseUri', 'id']);

        expect(iriPartsDefault['baseUri'], 'example.com');
        expect(iriPartsDefault['id'], '123');

        // Reserved expansion: baseUri SHOULD include slashes
        final iriPartsExpanded = parseIriParts(
            'https://example.com/api/users/123',
            '{+baseUri}/users/{id}',
            ['baseUri', 'id']);

        expect(iriPartsExpanded['baseUri'], 'https://example.com/api');
        expect(iriPartsExpanded['id'], '123');
      });

      test('should handle mixed expansion types in same template', () {
        final iriParts = parseIriParts(
            'https://api.example.com/v1/files/report.pdf',
            '{+baseUri}/files/{filename}.pdf',
            ['baseUri', 'filename']);

        expect(iriParts['baseUri'], 'https://api.example.com/v1');
        expect(iriParts['filename'], 'report');
      });

      test('should handle path variables with +reserved expansion', () {
        final iriParts = parseIriParts(
            'files/documents/subfolder/project/readme.txt',
            'files/{+path}/{filename}.txt',
            ['path', 'filename']);

        expect(iriParts['path'], 'documents/subfolder/project');
        expect(iriParts['filename'], 'readme');
      });

      test('should handle consecutive variables with different expansion types',
          () {
        final iriParts = parseIriParts(
            'https://cdn.example.com/images/user/avatar.jpg',
            '{+baseUrl}/{category}/{filename}.jpg',
            ['baseUrl', 'category', 'filename']);

        expect(iriParts['baseUrl'], 'https://cdn.example.com/images');
        expect(iriParts['category'], 'user');
        expect(iriParts['filename'], 'avatar');
      });
    });
  });
}
