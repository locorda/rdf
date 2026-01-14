// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// Utilities for converting RDF prefix names to various naming conventions.
///
/// RDF prefixes can use various naming styles (camelCase, dash-case, snake_case).
/// This utility provides consistent conversion to Dart naming conventions.
library naming_conventions;

/// Provides naming convention conversions for RDF prefixes.
class NamingConventions {
  /// Converts a prefix to snake_case for directories and library names.
  ///
  /// Examples:
  /// - `schemaHttp` → `schema_http`
  /// - `schema-http` → `schema_http`
  /// - `schema_http` → `schema_http` (unchanged)
  /// - `dcTerms` → `dc_terms`
  /// - `rdf` → `rdf` (unchanged)
  static String toSnakeCase(String prefix) {
    if (prefix.isEmpty) return prefix;

    // First, replace dashes with underscores
    var result = prefix.replaceAll('-', '_');

    // Then handle camelCase by inserting underscores before uppercase letters
    // But only if not already preceded by an underscore
    final buffer = StringBuffer();
    for (var i = 0; i < result.length; i++) {
      final char = result[i];
      final isUpperCase =
          char == char.toUpperCase() && char != char.toLowerCase();

      if (isUpperCase && i > 0) {
        // Check if previous character is not an underscore
        final prevChar = result[i - 1];
        if (prevChar != '_') {
          buffer.write('_');
        }
      }
      buffer.write(char.toLowerCase());
    }

    return buffer.toString();
  }

  /// Converts a prefix to UpperCamelCase for class names.
  ///
  /// Examples:
  /// - `schemaHttp` → `SchemaHttp`
  /// - `schema-http` → `SchemaHttp`
  /// - `schema_http` → `SchemaHttp`
  /// - `dcterms` → `Dcterms`
  /// - `rdf` → `Rdf`
  static String toUpperCamelCase(String prefix) {
    if (prefix.isEmpty) return prefix;

    // Split on dashes, underscores, or capital letters
    final parts = _splitPrefix(prefix);

    // Capitalize first letter of each part
    return parts
        .map(
          (part) =>
              part.isEmpty
                  ? ''
                  : part[0].toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join('');
  }

  /// Converts a prefix to lowerCamelCase for property names.
  ///
  /// Examples:
  /// - `schemaHttp` → `schemaHttp`
  /// - `schema-http` → `schemaHttp`
  /// - `schema_http` → `schemaHttp`
  /// - `dcTerms` → `dcTerms`
  /// - `rdf` → `rdf`
  static String toLowerCamelCase(String prefix) {
    if (prefix.isEmpty) return prefix;

    // Split on dashes, underscores, or capital letters
    final parts = _splitPrefix(prefix);

    if (parts.isEmpty) return prefix;

    // First part stays lowercase, rest are capitalized
    final buffer = StringBuffer(parts[0].toLowerCase());
    for (var i = 1; i < parts.length; i++) {
      final part = parts[i];
      if (part.isNotEmpty) {
        buffer.write(part[0].toUpperCase() + part.substring(1).toLowerCase());
      }
    }

    return buffer.toString();
  }

  /// Splits a prefix into parts based on delimiters (dashes, underscores) and camelCase.
  ///
  /// Examples:
  /// - `schemaHttp` → `['schema', 'Http']`
  /// - `schema-http` → `['schema', 'http']`
  /// - `schema_http` → `['schema', 'http']`
  /// - `dcTerms` → `['dc', 'Terms']`
  static List<String> _splitPrefix(String prefix) {
    // First replace dashes and underscores with a marker
    var normalized = prefix.replaceAll(RegExp(r'[-_]'), '|');

    // Then split on the marker and on camelCase boundaries
    final parts = <String>[];
    final buffer = StringBuffer();

    for (var i = 0; i < normalized.length; i++) {
      final char = normalized[i];

      if (char == '|') {
        // Delimiter found, save current buffer
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
      } else {
        final isUpperCase =
            char == char.toUpperCase() && char != char.toLowerCase();

        // If we encounter an uppercase letter and buffer is not empty,
        // it's a camelCase boundary
        if (isUpperCase && buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }

        buffer.write(char);
      }
    }

    // Add remaining content
    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    return parts;
  }
}
