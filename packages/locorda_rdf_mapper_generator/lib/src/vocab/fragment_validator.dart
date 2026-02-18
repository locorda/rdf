/// Validation utilities for vocabulary generation fragments.
///
/// This module provides validation functions for fragment identifiers used
/// in vocabulary generation. It ensures that auto-derived fragments follow
/// proper naming conventions.
library;

/// Validates that a field name follows lowerCamelCase convention.
///
/// This is used to validate auto-derived property fragments, which are derived
/// from field names. The field name must start with a lowercase letter and
/// contain only alphanumeric characters.
///
/// Pattern: `^[a-z][a-zA-Z0-9]*$`
///
/// Returns `null` if valid, or an error message if invalid.
/// The error message includes the field name and instructions for fixing the issue.
///
/// Examples:
/// ```dart
/// validateLowerCamelCase('title', 'Book') // null (valid)
/// validateLowerCamelCase('bookTitle', 'Book') // null (valid)
/// validateLowerCamelCase('Title', 'Book') // error message
/// validateLowerCamelCase('book_title', 'Book') // error message
/// validateLowerCamelCase('', 'Book') // error message
/// ```
///
/// Note: Explicit fragment values bypass this validation (user's responsibility).
String? validateLowerCamelCase(String fieldName, String className) {
  final pattern = RegExp(r'^[a-z][a-zA-Z0-9]*$');

  if (!pattern.hasMatch(fieldName)) {
    return "Field '$fieldName' in class '$className' must be in lowerCamelCase "
        "for vocab fragment derivation. Use @RdfProperty.define(fragment: '$fieldName') "
        "to explicitly set the fragment and bypass validation.";
  }

  return null;
}

/// Validates that a class name follows UpperCamelCase convention.
///
/// This is used to validate auto-derived class fragments, which are derived
/// from class names. The class name must start with an uppercase letter and
/// contain only alphanumeric characters.
///
/// Pattern: `^[A-Z][a-zA-Z0-9]*$`
///
/// Returns `null` if valid, or an error message if invalid.
/// The error message includes the class name and instructions for fixing the issue.
///
/// Examples:
/// ```dart
/// validateUpperCamelCase('Book') // null (valid)
/// validateUpperCamelCase('BookChapter') // null (valid)
/// validateUpperCamelCase('book') // error message
/// validateUpperCamelCase('Book_Chapter') // error message
/// validateUpperCamelCase('') // error message
/// ```
///
/// Note: There is no override mechanism for class fragments; the class must
/// be renamed to follow the convention.
String? validateUpperCamelCase(String className) {
  final pattern = RegExp(r'^[A-Z][a-zA-Z0-9]*$');

  if (!pattern.hasMatch(className)) {
    return "Class '$className' must be in UpperCamelCase for vocab fragment derivation. "
        "Rename the class to follow proper casing (e.g., '${_toUpperCamelCase(className)}').";
  }

  return null;
}

/// Converts a string to UpperCamelCase for suggestion purposes.
/// This is a simple helper for error messages.
String _toUpperCamelCase(String input) {
  if (input.isEmpty) return '';

  // Remove underscores and capitalize after them
  final parts = input.split('_');
  final capitalized = parts.map((part) {
    if (part.isEmpty) return '';
    return part[0].toUpperCase() + part.substring(1).toLowerCase();
  }).join('');

  // Ensure first letter is uppercase
  if (capitalized.isEmpty) return '';
  return capitalized[0].toUpperCase() + capitalized.substring(1);
}
