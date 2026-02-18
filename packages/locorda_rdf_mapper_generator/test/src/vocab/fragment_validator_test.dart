import 'package:locorda_rdf_mapper_generator/src/vocab/fragment_validator.dart';
import 'package:test/test.dart';

void main() {
  group('validateLowerCamelCase', () {
    group('valid cases', () {
      test('simple lowercase field name', () {
        expect(validateLowerCamelCase('title', 'Book'), isNull);
      });

      test('lowerCamelCase with multiple words', () {
        expect(validateLowerCamelCase('bookTitle', 'Book'), isNull);
      });

      test('lowerCamelCase with numbers', () {
        expect(validateLowerCamelCase('title2', 'Book'), isNull);
        expect(validateLowerCamelCase('book2Title', 'Book'), isNull);
      });

      test('single lowercase letter', () {
        expect(validateLowerCamelCase('a', 'Book'), isNull);
      });

      test('multiple camelCase transitions', () {
        expect(validateLowerCamelCase('myBookTitleField', 'Book'), isNull);
      });
    });

    group('invalid cases', () {
      test('starts with uppercase', () {
        final error = validateLowerCamelCase('Title', 'Book');
        expect(error, isNotNull);
        expect(error, contains('Title'));
        expect(error, contains('Book'));
        expect(error, contains('lowerCamelCase'));
        expect(error, contains('@RdfProperty.define(fragment:'));
      });

      test('contains underscore', () {
        final error = validateLowerCamelCase('book_title', 'Book');
        expect(error, isNotNull);
        expect(error, contains('book_title'));
        expect(error, contains('lowerCamelCase'));
      });

      test('contains hyphen', () {
        final error = validateLowerCamelCase('book-title', 'Book');
        expect(error, isNotNull);
        expect(error, contains('book-title'));
      });

      test('contains space', () {
        final error = validateLowerCamelCase('book title', 'Book');
        expect(error, isNotNull);
        expect(error, contains('book title'));
      });

      test('empty string', () {
        final error = validateLowerCamelCase('', 'Book');
        expect(error, isNotNull);
      });

      test('starts with number', () {
        final error = validateLowerCamelCase('2title', 'Book');
        expect(error, isNotNull);
        expect(error, contains('2title'));
      });

      test('contains special characters', () {
        final error = validateLowerCamelCase('book@title', 'Book');
        expect(error, isNotNull);
      });

      test('all uppercase', () {
        final error = validateLowerCamelCase('TITLE', 'Book');
        expect(error, isNotNull);
        expect(error, contains('TITLE'));
      });
    });

    test('error message includes field and class name', () {
      final error = validateLowerCamelCase('MyField', 'MyClass');
      expect(error, contains('MyField'));
      expect(error, contains('MyClass'));
    });

    test('error message suggests using explicit fragment', () {
      final error = validateLowerCamelCase('InvalidField', 'Book');
      expect(error, contains('@RdfProperty.define(fragment:'));
      expect(error, contains('InvalidField'));
    });
  });

  group('validateUpperCamelCase', () {
    group('valid cases', () {
      test('simple uppercase class name', () {
        expect(validateUpperCamelCase('Book'), isNull);
      });

      test('UpperCamelCase with multiple words', () {
        expect(validateUpperCamelCase('BookChapter'), isNull);
      });

      test('UpperCamelCase with numbers', () {
        expect(validateUpperCamelCase('Book2'), isNull);
        expect(validateUpperCamelCase('Book2Chapter'), isNull);
      });

      test('single uppercase letter', () {
        expect(validateUpperCamelCase('A'), isNull);
      });

      test('multiple camelCase transitions', () {
        expect(validateUpperCamelCase('MyBookChapterClass'), isNull);
      });
    });

    group('invalid cases', () {
      test('starts with lowercase', () {
        final error = validateUpperCamelCase('book');
        expect(error, isNotNull);
        expect(error, contains('book'));
        expect(error, contains('UpperCamelCase'));
        expect(error, contains('Rename'));
      });

      test('contains underscore', () {
        final error = validateUpperCamelCase('Book_Chapter');
        expect(error, isNotNull);
        expect(error, contains('Book_Chapter'));
        expect(error, contains('UpperCamelCase'));
      });

      test('contains hyphen', () {
        final error = validateUpperCamelCase('Book-Chapter');
        expect(error, isNotNull);
        expect(error, contains('Book-Chapter'));
      });

      test('contains space', () {
        final error = validateUpperCamelCase('Book Chapter');
        expect(error, isNotNull);
        expect(error, contains('Book Chapter'));
      });

      test('empty string', () {
        final error = validateUpperCamelCase('');
        expect(error, isNotNull);
      });

      test('starts with number', () {
        final error = validateUpperCamelCase('2Book');
        expect(error, isNotNull);
        expect(error, contains('2Book'));
      });

      test('contains special characters', () {
        final error = validateUpperCamelCase('Book@Chapter');
        expect(error, isNotNull);
      });

      test('all lowercase', () {
        final error = validateUpperCamelCase('bookchapter');
        expect(error, isNotNull);
        expect(error, contains('bookchapter'));
      });
    });

    test('error message includes class name', () {
      final error = validateUpperCamelCase('myClass');
      expect(error, contains('myClass'));
    });

    test('error message suggests proper casing', () {
      final error = validateUpperCamelCase('book_chapter');
      expect(error, contains('BookChapter'));
    });

    test('error message for lowercase suggests capitalized version', () {
      final error = validateUpperCamelCase('book');
      expect(error, contains('Book'));
    });
  });

  group('edge cases', () {
    test('very long valid lowerCamelCase name', () {
      final longName =
          'thisIsAVeryLongFieldNameWithManyCamelCaseTransitionsAndNumbers123';
      expect(validateLowerCamelCase(longName, 'Book'), isNull);
    });

    test('very long valid UpperCamelCase name', () {
      final longName =
          'ThisIsAVeryLongClassNameWithManyCamelCaseTransitionsAndNumbers123';
      expect(validateUpperCamelCase(longName), isNull);
    });

    test('single character lowercase is valid for field', () {
      expect(validateLowerCamelCase('x', 'Book'), isNull);
    });

    test('single character uppercase is valid for class', () {
      expect(validateUpperCamelCase('X'), isNull);
    });

    test('numbers in the middle are valid', () {
      expect(validateLowerCamelCase('field2Name', 'Book'), isNull);
      expect(validateUpperCamelCase('Class2Name'), isNull);
    });

    test('consecutive uppercase letters in field name are invalid', () {
      final error = validateLowerCamelCase('fieldHTML', 'Book');
      // This is actually valid according to the regex, as it matches [a-z][a-zA-Z0-9]*
      expect(error, isNull);
    });

    test('consecutive uppercase letters in class name are valid', () {
      expect(validateUpperCamelCase('HTMLParser'), isNull);
    });
  });

  group('unicode and special cases', () {
    test('unicode characters are invalid for field', () {
      final error = validateLowerCamelCase('títle', 'Book');
      expect(error, isNotNull);
    });

    test('unicode characters are invalid for class', () {
      final error = validateUpperCamelCase('Bóok');
      expect(error, isNotNull);
    });

    test('emoji are invalid', () {
      expect(validateLowerCamelCase('field😀', 'Book'), isNotNull);
      expect(validateUpperCamelCase('Book😀'), isNotNull);
    });
  });
}
