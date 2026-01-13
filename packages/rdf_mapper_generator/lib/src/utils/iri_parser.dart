/// Utility functions for parsing IRI templates according to RFC 6570 URI Template standard.
///
/// This module provides functionality to extract variable values from complete IRIs
/// using template patterns that support both default and reserved expansion.
library iri_parser;

import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';

String buildRegexPattern(String template, String? fragmentTemplate,
    Iterable<VariableName> variables) {
  // incorporate fragmentTemplate into the regex pattern if needed
  if (fragmentTemplate != null && fragmentTemplate.isNotEmpty) {
    if (template.contains('#')) {
      template = template.substring(0, template.indexOf('#'));
    }
    template = '$template#$fragmentTemplate';
  }
  // Convert template to regex pattern by escaping special regex characters
  String regexPattern = RegExp.escape(template);

  // Replace variables with named capture groups
  // Process all variables to create appropriate regex patterns
  for (final variable in variables) {
    // Use named capture groups for cleaner variable extraction
    regexPattern = regexPattern
        .replaceAll('\\{\\+${variable.name}\\}',
            '(?<${variable.name}>.*)') // .* for +reserved expansion
        .replaceAll('\\{${variable.name}\\}',
            '(?<${variable.name}>[^/]*)'); // [^/]* for default
  }
  return regexPattern;
}

/// Parses IRI parts from a complete IRI using a template.
///
/// FIXM: currently this function is copied to the `global_resource_data_builder.dart` file by hand, it would be better to automate that.
///
/// Supports RFC 6570 URI Template standard:
/// - `{variable}` (default): excludes reserved characters like '/'
/// - `{+variable}`: includes reserved characters for URLs/paths (RFC 6570 Level 2)
///
/// This function extracts variable values from a complete IRI by matching it
/// against a template pattern. The template uses placeholders that are replaced
/// with regex patterns to capture the actual values.
///
/// **Parameters:**
/// - [iri]: The complete IRI to parse
/// - [template]: The URI template pattern with variable placeholders
/// - [variables]: List of variable names that should be extracted
///
/// **Returns:**
/// A map containing variable names as keys and their extracted values as values.
/// Returns an empty map if the IRI doesn't match the template pattern.
///
/// **Examples:**
/// ```dart
/// // Basic parsing with reserved expansion
/// final result = parseIriParts(
///   'https://api.example.com/users/123',
///   '{+baseUri}/users/{id}',
///   ['baseUri', 'id']
/// );
/// // Returns: {'baseUri': 'https://api.example.com', 'id': '123'}
///
/// // Default expansion (excludes path separators)
/// final result2 = parseIriParts(
///   'https://example.com/api/users/456',
///   'https://{host}/api/users/{id}',
///   ['host', 'id']
/// );
/// // Returns: {'host': 'example.com', 'id': '456'}
/// ```
Map<String, String> parseIriParts(
    String iri, String template, List<String> variables) {
  final regex = RegExp(
      '^${buildRegexPattern(template, null, variables.map((v) => VariableName(name: v, dartPropertyName: v, canBeUri: false)))}\$');
  final match = regex.firstMatch(iri);

  // Extract all named groups if match is found
  return match == null
      ? <String, String>{}
      : Map.fromEntries(match.groupNames.map((name) {
          final namedGroup = match.namedGroup(name)!;
          return MapEntry(name, namedGroup);
        }));
}
