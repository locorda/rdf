import 'package:test/test.dart';
import 'package:rdf_mapper_generator/src/utils/dart_formatter.dart';
import 'package:rdf_mapper_generator/src/templates/template_renderer.dart';

void main() {
  group('DartCodeFormatter', () {
    late CodeFormatter formatter;

    setUp(() {
      formatter = DartCodeFormatter();
    });

    test('formats valid Dart code correctly', () {
      const unformattedCode = '''
class TestClass{
String   name;
int     age  ;
TestClass(this.name,this.age);
}
''';

      const expectedFormattedCode = '''class TestClass {
  String name;
  int age;
  TestClass(this.name, this.age);
}
''';

      final result = formatter.formatCode(unformattedCode);
      expect(result, equals(expectedFormattedCode));
    });

    test('handles invalid Dart code gracefully', () {
      const invalidCode = '''
class TestClass {
  String name
  // Missing semicolon above should cause parse error
}
''';

      // Should return the original code when formatting fails
      final result = formatter.formatCode(invalidCode);
      expect(result, equals(invalidCode));
    });

    test('formats complex generated mapper code', () {
      const complexCode = '''
/// Generated mapper for [Book] global resources.
class BookMapper implements GlobalResourceMapper<Book> {
final IriTerm typeIri = Schema.Book;
@override
Book fromRdfResource(IriTerm subject, DeserializationContext context) {
final reader = context.reader(subject);
final title = reader.require<String>(Schema.name);
final author = reader.optional<String>(Schema.author);
return Book(title: title, author: author);
}
}
''';

      final result = formatter.formatCode(complexCode);

      // Verify the result is properly formatted (contains proper indentation)
      expect(result, contains('  final IriTerm typeIri'));
      expect(result, contains('  @override'));
      expect(result, contains('    final reader'));
      expect(result.split('\n').length, greaterThan(1));
    });

    test('preserves comments and documentation', () {
      const codeWithComments = '''
/// This is a documentation comment
class TestClass {
// This is a regular comment
String name;
/* Multi-line
   comment */
int age;
}
''';

      final result = formatter.formatCode(codeWithComments);

      expect(result, contains('/// This is a documentation comment'));
      expect(result, contains('// This is a regular comment'));
      expect(result, contains('/* Multi-line'));
    });
  });

  group('NoOpCodeFormatter', () {
    test('returns code unchanged', () {
      const code = 'class  Test{int x;}';
      final formatter = NoOpCodeFormatter();

      final result = formatter.formatCode(code);

      expect(result, equals(code));
    });
  });

  group('Dependency Injection', () {
    test('TemplateRenderer can be injected with custom formatter', () {
      final customFormatter = NoOpCodeFormatter();
      final renderer = TemplateRenderer(codeFormatter: customFormatter);

      // This test just verifies the DI works - renderer should use the injected formatter
      expect(renderer, isNotNull);
    });
  });
}
