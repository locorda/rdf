const importDartCore = 'dart:core';

/// Represents generated code with its import dependencies and type aliases.
///
/// This class manages code generation where types might come from different
/// packages/libraries and need to be properly imported and aliased in the
/// target file to avoid naming conflicts.
///
/// ## Propagation and Resolution
/// Code objects are designed to be propagated as-is through the data layer
/// (PropertyModel, PropertyResolvedModel, PropertyData, etc.) without being
/// converted to strings until the final template rendering stage. This ensures
/// that:
/// 1. Import information is preserved throughout the processing pipeline
/// 2. Aliases are correctly resolved with the final import context
/// 3. Type references maintain their import dependencies
///
/// The resolution to final string representation happens only during template
/// rendering when Code objects are converted to their string form with proper
/// import aliases applied.
class Code {
  static const String typeMarker = '\$Code\$';
  static const String typeProperty = '__type__';

  final String _code;
  final Set<String> _imports; // Import URIs only

  // Special markers to safely identify aliases in code - these are invalid Dart syntax
  static const String _aliasStartMarker = '⟨@';
  static const String _aliasEndMarker = '@⟩';

  const Code._(this._code, this._imports);

  Map<String, dynamic> toMap() {
    return {
      'code': _code,
      'imports': _imports.toList(),
      typeProperty: typeMarker,
    };
  }

  static Code fromMap(Map<String, dynamic> map) {
    assert(map[typeProperty] == typeMarker, 'Invalid map for Code: $map');
    return Code._(
      map['code'] as String,
      Set<String>.from(map['imports'] as List<dynamic>),
    );
  }

  /// Creates a Code instance with the given code string and no imports
  const Code.literal(String code) : this._(code, const {});

  /// Creates a Code instance for a simple value that doesn't require imports
  const Code.value(String code) : this.literal(code);

  /// Creates a Code instance for a type reference that may require imports
  factory Code.type(String typeName, {String? importUri}) {
    if (importUri == null) {
      // No import needed - this is a built-in type or already available
      return Code.literal(typeName);
    }

    return Code._('${_wrapImportUri(importUri)}$typeName', {importUri});
  }

  factory Code.coreType(String typeName) {
    return Code.type(typeName, importUri: importDartCore);
  }

  /// Combines multiple Code instances to a parameter list
  factory Code.paramsList(Iterable<Code> params) {
    return Code.combine(
      [
        Code.literal('('),
        Code.combine(
          params,
          separator: ', ',
        ),
        Code.literal(')')
      ],
    );
  }
  factory Code.genericParamsList(Iterable<Code> params) {
    return Code.combine(
      [
        Code.literal('<'),
        Code.combine(
          params,
          separator: ', ',
        ),
        Code.literal('>')
      ],
    );
  }

  factory Code.combine(Iterable<Code> codes, {String separator = ''}) {
    if (codes.isEmpty) return Code.literal('');
    if (codes.length == 1) return codes.first;

    final combinedImports = codes.expand((c) => c._imports).toSet();

    // Second pass: build the combined code by resolving each code with the alias mapping
    String combinedCode = codes.map((c) => c._code).join(separator);

    return Code._(combinedCode, combinedImports);
  }

  /// The generated code string
  String get code => resolveAliases().$1;

  /// All import dependencies required by this code
  Set<String> get imports => Set.unmodifiable(_imports);

  /// Checks if this code has any import dependencies
  bool get hasImports => _imports.isNotEmpty;

  // The code without any import aliases, suitable for pure code generation or if
  // you are just interested in the name of a type for example.
  // To get the pure class name without imports, we resolve aliases
  // and use the class name without any import prefixes.
  String get codeWithoutAlias => resolveAliases(
      knownImports:
          Map.fromIterable(imports, key: (v) => v, value: (v) => '')).$1;

  /// Resolves alias markers in code to actual aliases
  /// Returns a record with the resolved code and a map of import URIs to aliases
  (String, Map<String, String>) resolveAliases(
      {Map<String, String> knownImports = const {},
      Map<String, String> broaderImports = const {}}) {
    String resolvedCode = _code;
    final importsWithAlias = <String, String>{};

    // Track which aliases are already used to avoid conflicts
    final usedAliases = <String>{};
    usedAliases.addAll(knownImports.values);

    for (final originalImportUri in _imports) {
      final importUri = broaderImports[originalImportUri] ?? originalImportUri;
      String alias;

      if (knownImports.containsKey(importUri)) {
        // Use the known alias
        alias = knownImports[importUri]!;
      } else {
        // Generate a new alias, ensuring it doesn't conflict
        alias = _generateAliasFromUri(importUri);
        if (alias.isNotEmpty) {
          int counter = 2;
          while (usedAliases.contains(alias)) {
            alias = '${_generateAliasFromUri(importUri)}$counter';
            counter++;
          }
        }
        usedAliases.add(alias);
      }

      importsWithAlias[importUri] = alias;
      final marker = _wrapImportUri(originalImportUri);
      resolvedCode =
          resolvedCode.replaceAll(marker, alias.isEmpty ? '' : '$alias.');
    }

    return (resolvedCode, importsWithAlias);
  }

  /// Generates a default alias from an import URI
  static String _generateAliasFromUri(String uri) {
    if (uri.startsWith('package:') ||
        uri.startsWith('asset:') ||
        uri.startsWith('file:')) {
      // Extract filename from URI: package:foo/bar/baz.dart -> baz, asset:foo/bar.dart -> bar
      final prefixLength = uri.split(":")[0].length + 1; // +1 for the colon
      final parts = uri.substring(prefixLength).split('/');
      if (parts.isNotEmpty) {
        final lastPart = parts.last;
        // Remove .dart extension if present
        final aliasName = lastPart.endsWith('.dart')
            ? lastPart.substring(0, lastPart.length - 5)
            : lastPart;
        return _sanitizeAlias(aliasName);
      }
    } else if (uri.startsWith('dart:')) {
      if (uri == 'dart:core') {
        // Special case for dart:core - no alias needed
        return '';
      }
      // dart:core -> core
      return _sanitizeAlias(uri.substring(5));
    }

    // Fallback: use a generic alias
    return 'lib${uri.hashCode.abs()}';
  }

  /// Wraps an import URI with special markers for safe replacement
  static String _wrapImportUri(String importUri) {
    return '$_aliasStartMarker$importUri$_aliasEndMarker';
  }

  /// Sanitizes an alias to ensure it's a valid Dart identifier
  /// If the result is too long, shortens it by using first letters of underscore-separated parts
  static String _sanitizeAlias(String input) {
    final sanitized = input.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    // If alias is reasonably short, return as is
    if (sanitized.length <= 12) {
      return sanitized;
    }

    // For long aliases, use first letter of each underscore-separated part
    final parts = sanitized.split('_').where((part) => part.isNotEmpty);
    if (parts.length > 1) {
      final abbreviated = parts.map((part) => part[0].toLowerCase()).join();
      return abbreviated.isNotEmpty ? abbreviated : sanitized;
    }

    // For single long words without underscores, truncate to reasonable length
    return sanitized.length > 12 ? sanitized.substring(0, 12) : sanitized;
  }

  @override
  String toString() => _code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Code && _code == other._code;

  @override
  int get hashCode => _code.hashCode;
}
