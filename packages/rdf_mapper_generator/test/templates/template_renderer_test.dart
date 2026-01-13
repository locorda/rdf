import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateRenderer', () {
    late TemplateRenderer renderer;

    setUp(() {
      renderer = TemplateRenderer();
    });

    group('resolveCodeSnipplets', () {
      test('resolves simple Code instance', () {
        final code = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final data = {
          'someField': 'value',
          'codeField': code.toMap(),
        };

        final result = renderer.resolveCodeSnipplets(data);

        expect(result['someField'], equals('value'));
        expect(result['codeField'], equals('bar.MyClass'));
        expect(result['aliasedImports'], hasLength(1));
        expect(
            result['aliasedImports'][0]['uri'], equals('package:foo/bar.dart'));
        expect(result['aliasedImports'][0]['alias'], equals('bar'));
        expect(result['aliasedImports'][0]['hasAlias'], isTrue);
      });
      test('resolves simple Code instance without alias if requested so', () {
        final code = Code.type('MyClass', importUri: 'package:foo/bar.dart');
        final data = {
          'someField': 'value',
          'codeField': code.toMap(),
        };

        final result = renderer.resolveCodeSnipplets(data,
            defaultImports: ['package:foo/bar.dart']);

        expect(result['someField'], equals('value'));
        expect(result['codeField'], equals('MyClass'));
        expect(result['aliasedImports'], hasLength(0));
      });

      test('resolves nested Code instances', () {
        final code1 = Code.type('ClassA', importUri: 'package:foo/a.dart');
        final code2 = Code.type('ClassB', importUri: 'package:bar/b.dart');

        final data = {
          'nested': {
            'code1': code1.toMap(),
            'someList': [
              'string',
              code2.toMap(),
              123,
            ],
          },
        };

        final result = renderer.resolveCodeSnipplets(data);

        expect(result['nested']['code1'], equals('a.ClassA'));
        expect(result['nested']['someList'][0], equals('string'));
        expect(result['nested']['someList'][1], equals('b.ClassB'));
        expect(result['nested']['someList'][2], equals(123));
        expect(result['aliasedImports'], hasLength(2));
      });

      test('respects known imports without aliases', () {
        final code = Code.coreType('MyClass');
        final data = {
          'codeField': code.toMap(),
        };

        final result = renderer.resolveCodeSnipplets(data);

        expect(result['codeField'], equals('MyClass'));
        expect(result['aliasedImports'], hasLength(1));
        expect(result['aliasedImports'][0]['uri'], equals('dart:core'));
        expect(result['aliasedImports'][0]['alias'], equals(''));
        expect(result['aliasedImports'][0]['hasAlias'], isFalse);
      });

      test('handles alias conflicts with known imports', () {
        final code1 = Code.type('ClassA', importUri: 'package:a/foo.dart');
        final code2 = Code.type('ClassB', importUri: 'package:b/foo.dart');

        final data = {
          'code1': code1.toMap(),
          'code2': code2.toMap(),
        };

        final result = renderer.resolveCodeSnipplets(data);

        expect(result['code1'], equals('foo.ClassA'));
        expect(result['code2'], equals('foo2.ClassB'));
        expect(result['aliasedImports'], hasLength(2));

        final aliases = result['aliasedImports'] as List;
        final aliasMap = {for (var item in aliases) item['uri']: item['alias']};
        expect(aliasMap['package:a/foo.dart'], equals('foo'));
        expect(aliasMap['package:b/foo.dart'], equals('foo2'));
      });

      test('preserves non-Code data unchanged', () {
        final data = {
          'string': 'hello',
          'number': 42,
          'bool': true,
          'list': [1, 2, 3],
          'map': {'nested': 'value'},
        };

        final result = renderer.resolveCodeSnipplets(data);

        expect(result['string'], equals('hello'));
        expect(result['number'], equals(42));
        expect(result['bool'], isTrue);
        expect(result['list'], equals([1, 2, 3]));
        expect(result['map'], equals({'nested': 'value'}));
        expect(result['aliasedImports'], isEmpty);
      });
    });
  });
}
