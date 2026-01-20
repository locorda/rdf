import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/v8_1/analyzer_wrapper_models_v8_1.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/util.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

/// Unit tests for typeToCode() function to verify that generic type arguments
/// correctly preserve their import information.
///
/// This addresses a bug where collection types like `List<Chapter>` would lose
/// the import information for the type parameter (`Chapter`) in the generated code.
void main() {
  group('typeToCode()', tags: ['integration', 'slow'], () {
    late TestAnalyzerHelper helper;

    setUp(() async {
      helper = TestAnalyzerHelper();
      await helper.initialize();
    });

    tearDown(() async {
      await helper.dispose();
    });

    test('simple type preserves import', () async {
      final code = '''
class MyClass {
  String name;
}
''';
      final library = await helper.resolveLibrary(code);
      final classElement = library.classes.first;
      final field = classElement.fields.first;
      final type = DartTypeV8(field.type);

      final result = typeToCode(type);

      expect(result.code, contains('String'));
      expect(result.imports, contains('dart:core'));
    });

    test('List<CustomType> preserves both imports', () async {
      final code = '''
class Chapter {
  String title;
}

class Book {
  List<Chapter> chapters;
}
''';
      final library = await helper.resolveLibrary(code);
      final bookClass = library.classes.firstWhere((c) => c.name == 'Book');
      final chaptersField = bookClass.fields.first;
      final listType = DartTypeV8(chaptersField.type);

      final result = typeToCode(listType);

      // Should generate code with prefix for Chapter
      expect(result.code, equals('List<test.Chapter>'),
          reason:
              'Should generate List<test.Chapter> with prefix for custom type');

      // Should have imports for both List (dart:core) and Chapter (test library)
      expect(result.imports, contains('dart:core'),
          reason: 'Should import dart:core for List');
      expect(result.imports.any((uri) => uri.contains('test.dart')), isTrue,
          reason: 'Should import the library containing Chapter');
    });

    test('Set<String> preserves imports', () async {
      final code = '''
class MyClass {
  Set<String> tags;
}
''';
      final library = await helper.resolveLibrary(code);
      final classElement = library.classes.first;
      final field = classElement.fields.first;
      final setType = DartTypeV8(field.type);

      final result = typeToCode(setType);

      expect(result.imports, contains('dart:core'),
          reason: 'Should import dart:core for both Set and String');
    });

    test('Map<String, CustomType> preserves all imports', () async {
      final code = '''
class Review {
  int stars;
}

class Book {
  Map<String, Review> reviews;
}
''';
      final library = await helper.resolveLibrary(code);
      final bookClass = library.classes.firstWhere((c) => c.name == 'Book');
      final reviewsField = bookClass.fields.first;
      final mapType = DartTypeV8(reviewsField.type);

      final result = typeToCode(mapType);

      // Should generate code with prefix for Review
      expect(result.code, equals('Map<String, test.Review>'),
          reason:
              'Should generate Map<String, test.Review> with prefix for custom type');

      // Should have imports for Map, String (both dart:core) and Review (test library)
      expect(result.imports, contains('dart:core'),
          reason: 'Should import dart:core for Map and String');
      expect(result.imports.any((uri) => uri.contains('test.dart')), isTrue,
          reason: 'Should import the library containing Review');
    });

    test('nested generics preserve all imports', () async {
      final code = '''
class Chapter {
  String title;
}

class Book {
  List<List<Chapter>> nestedChapters;
}
''';
      final library = await helper.resolveLibrary(code);
      final bookClass = library.classes.firstWhere((c) => c.name == 'Book');
      final field = bookClass.fields.first;
      final nestedListType = DartTypeV8(field.type);

      final result = typeToCode(nestedListType);

      // Should generate code with prefix for Chapter in nested generic
      expect(result.code, equals('List<List<test.Chapter>>'),
          reason:
              'Should generate List<List<test.Chapter>> with prefix for nested custom type');

      // Should have imports for List (dart:core) and Chapter (test library)
      expect(result.imports, contains('dart:core'),
          reason: 'Should import dart:core for List');
      expect(result.imports.any((uri) => uri.contains('test.dart')), isTrue,
          reason: 'Should import the library containing Chapter');
    });

    test('Code object can be resolved with aliases', () async {
      final code = '''
class MyType {
  int value;
}

class Container {
  List<MyType> items;
}
''';
      final library = await helper.resolveLibrary(code);
      final containerClass =
          library.classes.firstWhere((c) => c.name == 'Container');
      final field = containerClass.fields.first;
      final listType = DartTypeV8(field.type);

      final codeObj = typeToCode(listType);

      // Resolve with some known imports
      final (resolved, imports) = codeObj.resolveAliases(
        knownImports: {'dart:core': ''},
      );

      // The resolved code should not contain the special markers after resolution
      expect(resolved, isNot(contains('⟨@')));
      expect(resolved, isNot(contains('@⟩')));

      // Should have determined an alias for the test library
      expect(imports.keys.any((uri) => uri.contains('test.dart')), isTrue);
    });
  });
}
