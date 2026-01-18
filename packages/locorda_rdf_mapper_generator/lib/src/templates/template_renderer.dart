import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:mustache_template/mustache_template.dart';
import 'package:path/path.dart' as path;
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/util.dart';
import 'package:locorda_rdf_mapper_generator/src/utils/dart_formatter.dart';

final _log = Logger('TemplateRenderer');

/// Renders mustache templates for RDF mapper generation.
class TemplateRenderer {
  static final _instance = TemplateRenderer._();

  /// Cached templates
  final Map<String, Future<Template>> _templateCache = {};

  /// Code formatter for generated Dart code
  final CodeFormatter _codeFormatter;

  TemplateRenderer._({CodeFormatter? codeFormatter})
      : _codeFormatter = codeFormatter ?? DartCodeFormatter();

  factory TemplateRenderer({CodeFormatter? codeFormatter}) =>
      codeFormatter == null
          ? _instance
          : TemplateRenderer._(codeFormatter: codeFormatter);

  /// Renders a global resource mapper using the provided template data.
  Future<String> _renderResourceMapper(
      Map<String, dynamic> data, AssetReader reader) async {
    final template = await _getTemplate('resource_mapper', reader);
    return template.renderString(data);
  }

  Future<String> _renderIriMapper(
      Map<String, dynamic> data, AssetReader reader) async {
    final template = await _getTemplate('iri_mapper', reader);
    return template.renderString(data);
  }

  Future<String> _renderLiteralMapper(
      Map<String, dynamic> data, AssetReader reader) async {
    final template = await _getTemplate('literal_mapper', reader);
    return template.renderString(data);
  }

  Future<String> _renderEnumIriMapper(
      Map<String, dynamic> data, AssetReader reader) async {
    final template = await _getTemplate('enum_iri_mapper', reader);
    return template.renderString(data);
  }

  Future<String> _renderEnumLiteralMapper(
      Map<String, dynamic> data, AssetReader reader) async {
    final template = await _getTemplate('enum_literal_mapper', reader);
    return template.renderString(data);
  }

  Future<String> renderInitFileTemplate(
      Map<String, dynamic> data, AssetReader reader) async {
    final template = await _getTemplate('init_rdf_mapper', reader);
    final result = template.renderString(data);

    // Format the generated code using the injected formatter
    return _codeFormatter.formatCode(result);
  }

  /// Renders a complete file using the file template and multiple mappers.
  Future<String> renderFileTemplate(String mapperImportUri,
      Map<String, dynamic> data, AssetReader reader) async {
    final modelImportUri =
        mapperImportUri.replaceAll('.rdf_mapper.g.dart', '.dart');
    const defaultImports = [importRdfCore, importRdfMapper];
    final broaderImports = _safeCastToStringMap(data['broaderImports']);
    final originalImports = _safeCastToStringMap(data['originalImports']);
    data = resolveCodeSnipplets(
      data,
      defaultImports: [...defaultImports, mapperImportUri, importDartCore],
      importAliases: {modelImportUri: '', ...originalImports},
      baseUris: _createBaseUris(mapperImportUri),
      broaderImports: broaderImports,
    );
    final template = await _getTemplate('file_template', reader);

    // Render each mapper individually first
    final renderedMappers = <String>[];
    for (final mapperData in data['mappers']) {
      final mapperCode = switch (mapperData['__type__']) {
        'ResourceMapperTemplateData' => await _renderResourceMapper(
            mapperData as Map<String, dynamic>, reader),
        // Custom mappers are coded by our users, we do not render them here
        'CustomMapperTemplateData' => null,
        'IriMapperTemplateData' =>
          await _renderIriMapper(mapperData as Map<String, dynamic>, reader),
        'LiteralMapperTemplateData' => await _renderLiteralMapper(
            mapperData as Map<String, dynamic>, reader),
        'EnumIriMapperTemplateData' => await _renderEnumIriMapper(
            mapperData as Map<String, dynamic>, reader),
        'EnumLiteralMapperTemplateData' => await _renderEnumLiteralMapper(
            mapperData as Map<String, dynamic>, reader),
        // Add cases for other mapper types if needed
        _ => throw Exception('Unknown mapper type: ${mapperData['__type__']}'),
      };
      if (mapperCode == null) {
        continue; // Skip if the mapper code is null (e.g., custom mappers)
      }
      renderedMappers.add(mapperCode);
    }

    // Build the complete file data map

    data['mappers'] =
        renderedMappers.map((code) => {'mapperCode': code}).toList();
    data['imports'] = defaultImports;
    final result = template.renderString(data);

    // Format the generated code using the injected formatter
    return _codeFormatter.formatCode(result);
  }

  /// Gets a template by name, loading and caching it if necessary.
  Future<Template> _getTemplate(
          String templateName, AssetReader reader) async =>
      _templateCache.putIfAbsent(
          templateName,
          () async => Template(await _loadTemplate(templateName, reader),
              name: templateName,
              lenient: true,
              htmlEscapeValues: false)); // Disable HTML escaping globally

  Future<String> _loadTemplate(String name, AssetReader reader) async {
    final assetId = AssetId(
      'locorda_rdf_mapper_generator',
      path.join(
        'lib',
        'src',
        'templates',
        '$name.mustache',
      ),
    );
    return await reader.readAsString(assetId);
  }

  Map<String, dynamic> resolveCodeSnipplets(Map<String, dynamic> data,
      {List<String> defaultImports = const [],
      Map<String, String> importAliases = const {},
      Set<String> baseUris = const {},
      Map<String, String> broaderImports = const {},
      bool makeImportsRelative = true}) {
    // the default imports all are without aliases (or better: for the empty alias)
    final knownImports = <String, String>{...importAliases};

    for (final import in defaultImports) {
      knownImports[import] = '';
    }
    _log.info('Resolving code snippets with imports: $knownImports');

    // Create a copy of the data to avoid modifying the original
    final resolvedData = _deepCopyMap(data);

    final usedImports = <String, String>{};
    // Recursively traverse and resolve Code instances
    _traverseAndResolveCode(
        resolvedData, knownImports, usedImports, broaderImports);

    // Remove the original imports from knownImports and add aliasedImports
    for (final import in defaultImports) {
      knownImports.remove(import);
      usedImports.remove(import);
    }

    // Add aliasedImports entry for mustache templates
    final aliasedImports = usedImports.entries
        .map((entry) => {
              'uri': _toRelativeUri(baseUris, entry.key),
              'alias': entry.value,
              'hasAlias': entry.value.isNotEmpty,
            })
        .toList();

    resolvedData['aliasedImports'] = aliasedImports;
    resolvedData['hasAliasedImports'] = aliasedImports.isNotEmpty;
    if (makeImportsRelative) {
      if (resolvedData['imports'] is List) {
        for (var import in resolvedData['imports']) {
          if (import is String) {
            import = _toRelativeUri(baseUris, import);
          } else if (import is Map<String, dynamic> &&
              import.containsKey('import')) {
            import['import'] = _toRelativeUri(baseUris, import['import']);
          }
        }
      }
    }
    return resolvedData;
  }

  /// Recursively traverses the data structure and resolves Code instances
  void _traverseAndResolveCode(dynamic data, Map<String, String> knownImports,
      Map<String, String> usedImports, Map<String, String> broaderImports,
      [Set<Object>? visited]) {
    visited ??= <Object>{};

    // Prevent infinite recursion with circular references
    if (data is Object && visited.contains(data)) {
      return;
    }

    if (data is Map<String, dynamic>) {
      visited.add(data);

      // Check if this is a Code instance
      if (data.containsKey(Code.typeProperty) &&
          data[Code.typeProperty] == Code.typeMarker) {
        // This shouldn't happen if called correctly from parent
        throw StateError(
            'Code instance found at root level - should be handled by parent');
      }

      // Process all values in the map, checking for Code instances
      final keys = data.keys
          .toList(); // Create a copy to avoid modification during iteration
      for (final key in keys) {
        final value = data[key];
        if (value is Map<String, dynamic> &&
            value.containsKey(Code.typeProperty) &&
            value[Code.typeProperty] == Code.typeMarker) {
          // This is a Code instance, reconstruct it and replace with resolved code
          final code = Code.fromMap(value);
          final (resolvedCode, moreImports) = code.resolveAliases(
              knownImports: knownImports, broaderImports: broaderImports);

          // Update knownImports with new imports
          knownImports.addAll(moreImports);
          usedImports.addAll(moreImports);

          // Replace the Code map with the resolved code string
          data[key] = resolvedCode;
        } else {
          // Recursively process the value
          _traverseAndResolveCode(
              value, knownImports, usedImports, broaderImports, visited);
        }
      }

      visited.remove(data);
    } else if (data is List) {
      visited.add(data);

      // Process all items in the list, checking for Code instances
      for (int i = 0; i < data.length; i++) {
        final item = data[i];
        if (item is Map<String, dynamic> &&
            item.containsKey(Code.typeProperty) &&
            item[Code.typeProperty] == Code.typeMarker) {
          // This is a Code instance, reconstruct it and replace with resolved code
          final code = Code.fromMap(item);
          final (resolvedCode, moreImports) = code.resolveAliases(
              knownImports: knownImports, broaderImports: broaderImports);

          // Update knownImports with new imports
          knownImports.addAll(moreImports);
          usedImports.addAll(moreImports);
          // Replace the Code map with the resolved code string
          data[i] = resolvedCode;
        } else {
          // Recursively process the item
          _traverseAndResolveCode(
              item, knownImports, usedImports, broaderImports, visited);
        }
      }

      visited.remove(data);
    }
    // For primitive types (String, int, bool, etc.), do nothing
  }

  /// Creates a deep copy of a map structure
  Map<String, dynamic> _deepCopyMap(Map<String, dynamic> original,
      [Set<Object>? visited]) {
    visited ??= <Object>{};

    if (visited.contains(original)) {
      // Return a new empty map to break the cycle
      return <String, dynamic>{};
    }

    visited.add(original);
    final copy = <String, dynamic>{};
    for (final entry in original.entries) {
      copy[entry.key] = _deepCopyValue(entry.value, visited);
    }
    visited.remove(original);
    return copy;
  }

  /// Creates a deep copy of any value (recursive helper for _deepCopyMap)
  dynamic _deepCopyValue(dynamic value, [Set<Object>? visited]) {
    visited ??= <Object>{};

    if (value is Map<String, dynamic>) {
      return _deepCopyMap(value, visited);
    } else if (value is List) {
      if (visited.contains(value)) {
        // Return a new empty list to break the cycle
        return <dynamic>[];
      }
      visited.add(value);
      final result =
          value.map((item) => _deepCopyValue(item, visited)).toList();
      visited.remove(value);
      return result;
    } else {
      // Primitive types can be copied directly
      return value;
    }
  }

  String _toRelativeUri(Set<String> baseUris, String uri) {
    for (final baseUri in baseUris) {
      if (uri.startsWith(baseUri)) {
        return uri.substring(baseUri.length);
      }
    }
    return uri;
  }

  Set<String> _createBaseUris(String mapperImportUri) {
    final parts = mapperImportUri.split(':');
    final p = parts.length < 2
        ? mapperImportUri
        : parts.sublist(1).join(':'); // Join back if scheme is present

    // Extract the base URI from the mapper import URI
    final baseUri = path.dirname(p);
    final normalizedBaseUri = baseUri.endsWith('/') ? baseUri : '$baseUri/';
    // Return a set containing the base URI
    return {
      'asset:' + normalizedBaseUri,
      'package:' + normalizedBaseUri,
      'file:' + normalizedBaseUri,
      'test:' + normalizedBaseUri
    };
  }

  /// Safely casts a dynamic value to Map&lt;String, String&gt;
  Map<String, String> _safeCastToStringMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, String>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val.toString()));
    }
    return {};
  }
}
