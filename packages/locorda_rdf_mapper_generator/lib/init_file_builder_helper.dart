import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/template_renderer.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/util.dart';

class _InitFileTemplateData {
  final String generatedOn;
  final bool isTest;
  final List<_Mapper> mappers;
  final List<_InitFunctionParameter> initFunctionParameters;
  final Map<String, String> broaderImports;

  _InitFileTemplateData(
      {required this.generatedOn,
      required this.isTest,
      required this.mappers,
      required this.initFunctionParameters,
      required this.broaderImports});

  Map<String, dynamic> toMap() {
    return {
      'generatedOn': generatedOn,
      'isTest': isTest,
      'mappers': mappers.map((m) => m.toMap()).toList(),
      'initFunctionParameters':
          initFunctionParameters.map((i) => i.toMap()).toList(),
      'hasInitFunctionParameters': initFunctionParameters.isNotEmpty,
      'broaderImports': broaderImports,
    };
  }
}

class _Mapper {
  final Code type;
  final Code code;
  final SerializationDirection? direction;

  _Mapper({
    required this.type,
    required this.code,
    this.direction,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toMap(),
      'code': code.toMap(),
      'registerMethod': switch (direction) {
        SerializationDirection.serializeOnly => 'registerSerializer',
        SerializationDirection.deserializeOnly => 'registerDeserializer',
        null => 'registerMapper',
      },
    };
  }
}

class _InitFunctionParameter {
  final Code type;
  final String? name;
  _InitFunctionParameter({
    required this.type,
    this.name,
  });
  Map<String, dynamic> toMap() {
    return {
      'type': type.toMap(),
      'name': name,
    };
  }
}

class _RequiredMapperParameter {
  final Code type;
  final String parameterName;
  final bool isNamed;
  final bool isTypeBased;
  final bool isInstance;
  final String? name;
  final Code initFunctionParameterCode;
  final Code initFunctionParameterType;
  final String initFunctionParameterName;

  _RequiredMapperParameter({
    required this.type,
    required this.parameterName,
    required this.isNamed,
    required this.isTypeBased,
    required this.isInstance,
    required this.name,
    required this.initFunctionParameterCode,
    required this.initFunctionParameterType,
    required this.initFunctionParameterName,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toMap(),
      'code': initFunctionParameterCode.toMap(),
      'parameterName': parameterName,
      'isNamed': isNamed,
      'isTypeBased': isTypeBased,
      'isInstance': isInstance,
      'name': name,
    };
  }
}

typedef _InitFileContributions = (
  Iterable<_Mapper>,
  Map<String, _InitFunctionParameter>,
  Map<String, String>, // BroaderImports
);
const _InitFileContributions noInitFileContributions = (
  const <_Mapper>[],
  const <String, _InitFunctionParameter>{},
  const <String, String>{},
);

class InitFileBuilderHelper {
  static final _templateRenderer = TemplateRenderer();
  final Logger log = Logger('InitFileBuilderHelper');

  InitFileBuilderHelper();

  Map<String, dynamic>? buildTemplateData(
      List<(String path, String package, String content)> jsonFiles,
      {required bool isTest,
      required String outputPath,
      required String currentPackage}) {
    try {
      final sortedJsonFiles = _sortJsonFiles(jsonFiles);
      final templateData =
          _processJsonFiles(sortedJsonFiles, isTest, outputPath);

      return _buildFinalTemplateData(templateData, currentPackage);
    } catch (e, stackTrace) {
      log.severe('Error building template data: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Sorts JSON files by package and path for consistent processing order
  List<(String path, String package, String content)> _sortJsonFiles(
      List<(String path, String package, String content)> jsonFiles) {
    return List.from(jsonFiles)
      ..sort((a, b) {
        final (aPath, aPackage, _) = a;
        final (bPath, bPackage, _) = b;
        final cmp = aPackage.compareTo(bPackage);
        if (cmp != 0) return cmp;
        return aPath.compareTo(bPath);
      });
  }

  /// Processes all JSON files and extracts mapper information
  _InitFileTemplateData _processJsonFiles(
      List<(String path, String package, String content)> sortedJsonFiles,
      bool isTest,
      String outputPath) {
    final contributions = sortedJsonFiles.map((file) {
      final (path, package, content) = file;

      try {
        var jsonData = jsonDecode(content) as Map<String, dynamic>;

        // Process mappers and context providers from this file
        return _processFileMappers(jsonData);
      } catch (e, stackTrace) {
        log.warning('Error processing cache file $path: $e', e, stackTrace);
        return noInitFileContributions;
      }
    });

    final (mappers, initFunctionParameters, broaderImports) =
        mergeInitFileContributions(contributions);
    final sortedMapperParameters =
        _sortInitFunctionParameters(initFunctionParameters);
    return _InitFileTemplateData(
      generatedOn: DateTime.now().toIso8601String(),
      isTest: isTest,
      mappers: mappers.toList(),
      initFunctionParameters: sortedMapperParameters,
      broaderImports: broaderImports,
    );
  }

  /// Processes mappers and context providers from a single JSON file
  _InitFileContributions _processFileMappers(Map<String, dynamic> jsonData) {
    final mappersData =
        (jsonData['mappers'] as List? ?? []).cast<Map<String, dynamic>>();
    final all = mappersData.map<_InitFileContributions>(
        (mapperData) => switch (mapperData['__type__'] as String?) {
              'ResourceMapperTemplateData' => collectMapper(mapperData),
              'CustomMapperTemplateData' => collectCustomMapper(mapperData),
              'IriMapperTemplateData' => collectMapper(mapperData),
              'LiteralMapperTemplateData' => collectMapper(mapperData),
              'EnumIriMapperTemplateData' => collectMapper(mapperData),
              'EnumLiteralMapperTemplateData' => collectMapper(mapperData),
              _ => () {
                  log.warning('Unknown mapper type: ${mapperData['__type__']}');
                  return noInitFileContributions;
                }()
            });
    final (mappers, initFunctionParameters, _) =
        mergeInitFileContributions(all);

    // Extract broader imports from this file
    final broaderImports = _safeCastToStringMap(jsonData['broaderImports']);

    return (mappers, initFunctionParameters, broaderImports);
  }

  _InitFileContributions mergeInitFileContributions(
      Iterable<_InitFileContributions> all) {
    final mappers = all.expand((c) => c.$1).toList();
    final allInitFunctionParameters = all
        .fold<Map<String, _InitFunctionParameter>>(
            {}, (acc, c) => {...acc, ...c.$2});
    final allBroaderImports =
        all.fold<Map<String, String>>({}, (acc, c) => {...acc, ...c.$3});
    return (mappers, allInitFunctionParameters, allBroaderImports);
  }

  _InitFileContributions collectMapper(Map<String, dynamic> mapperData) {
    final className = extractNullableCodeProperty(mapperData, 'className');
    final mapperClassName =
        extractNullableCodeProperty(mapperData, 'mapperClassName');

    if (className == null || mapperClassName == null) {
      return noInitFileContributions;
    }

    // Extract all required custom mappers for this mapper, excluding those that are already providers
    final requiredMapperParameters =
        _extractRequiredMapperParameters(mapperData);
    final parametersByName =
        _indexInitFunctionParameters(requiredMapperParameters);

    // Check if this mapper should be registered globally
    final registerGlobally = mapperData['registerGlobally'] as bool? ?? true;
    final direction =
        SerializationDirection.fromString(mapperData['direction'] as String?);
    final code = _buildCodeInstantiateMapperFromRequired(
        mapperClassName, requiredMapperParameters);

    if (registerGlobally) {
      return (
        [
          _Mapper(
            code: code,
            type: className,
            direction: direction,
          )
        ],
        parametersByName,
        const <String, String>{}, // No broader imports at mapper level
      );
    }
    return noInitFileContributions;
  }

  Code _buildCodeInstantiateMapperFromRequired(Code mapperClassName,
      List<_RequiredMapperParameter> requiredMapperParameters) {
    var requiredMapperParams = requiredMapperParameters
        .map((i) => (i.parameterName, i.initFunctionParameterCode));

    // Deduplicate parameters by name
    var paramMap = <String, (String, Code)>{};
    for (var param in requiredMapperParams) {
      if (paramMap.containsKey(param.$1)) {
        log.warning(
            'Duplicate parameter name "${param.$1}" in mapper instantiation. Using the first occurrence.');
      }
      paramMap.putIfAbsent(param.$1, () => param);
    }

    var sortedParams = paramMap.values.toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));
    return _buildCodeInstantiateMapper(mapperClassName, sortedParams);
  }

  Code _buildCodeInstantiateMapper(
      Code mapperClassName, List<(String paramName, Code paramValue)> params) {
    return Code.combine([
      mapperClassName,
      Code.paramsList(
        params.map((cp) =>
            Code.combine([Code.literal(cp.$1), Code.literal(':'), cp.$2])),
      )
    ]);
  }

  _InitFileContributions collectCustomMapper(Map<String, dynamic> mapperData) {
    final className = extractCodeProperty(mapperData, 'className');
    final mapperInterfaceType =
        extractCodeProperty(mapperData, 'mapperInterfaceType');
    final customMapperInstance =
        extractNullableCodeProperty(mapperData, 'customMapperInstance');
    final customMapperName = mapperData['customMapperName'] as String?;
    // Check if this mapper should be registered globally
    final registerGlobally = mapperData['registerGlobally'] as bool? ?? true;

    if (registerGlobally) {
      final code = customMapperInstance ??
          (customMapperName == null ? null : Code.literal(customMapperName));
      if (code == null) {
        throw ArgumentError('No valid code found for Custom mapper ');
      }
      final initFunctionParameter = customMapperName != null
          ? _InitFunctionParameter(
              type: mapperInterfaceType, name: customMapperName)
          : null;

      return (
        [
          _Mapper(
            type: className,
            code: code,
          )
        ],
        {
          if (initFunctionParameter?.name != null)
            initFunctionParameter!.name!: initFunctionParameter
        },
        const <String, String>{}, // No broader imports at mapper level
      );
    }
    return noInitFileContributions;
  }

  Code? extractNullableCodeProperty(
          Map<String, dynamic> mapperData, String propertyName) =>
      mapperData[propertyName] != null
          ? extractCodeProperty(mapperData, propertyName)
          : null;

  Code extractCodeProperty(
          Map<String, dynamic> mapperData, String propertyName) =>
      Code.fromMap(mapperData[propertyName] as Map<String, dynamic>);

  /// Extracts custom mappers from constructor parameters that require named mappers
  List<_RequiredMapperParameter> _extractRequiredMapperParameters(
      Map<String, dynamic> mapperData) {
    final mapperConstructor =
        mapperData['mapperConstructor'] as Map<String, dynamic>?;
    if (mapperConstructor == null) return [];
    final constructorParameters =
        (mapperConstructor['parameters'] as List? ?? [])
            .cast<Map<String, dynamic>>();

    return constructorParameters
        .map((param) => param['value'] as Map<String, dynamic>?)
        .where((param) => param != null)
        .map((param) => param!)
        .where((param) => !(param['hasDefaultValue'] as bool? ?? false))
        .where((param) => param['type'] != null)
        .map((param) => _RequiredMapperParameter(
            initFunctionParameterCode:
                extractCodeProperty(param, 'initFunctionParameterCode'),
            initFunctionParameterType:
                extractCodeProperty(param, 'initFunctionParameterType'),
            initFunctionParameterName:
                param['initFunctionParameterName'] as String,
            type: extractCodeProperty(param, 'type'),
            parameterName: param['parameterName'] as String,
            isNamed: true,
            isTypeBased: false,
            isInstance: false,
            name: param['parameterName'] as String))
        .toList();
  }

  /// Collects required mapper parameters into the initFunctionParameters map by name
  Map<String, _InitFunctionParameter> _indexInitFunctionParameters(
          List<_RequiredMapperParameter> requiredMapperParameters) =>
      {
        for (final param in requiredMapperParameters)
          param.initFunctionParameterName: _InitFunctionParameter(
              type: param.initFunctionParameterType,
              name: param.initFunctionParameterName)
      };

  /// Builds the final template data from processing results
  Map<String, dynamic> _buildFinalTemplateData(
    _InitFileTemplateData result,
    String currentPackage,
  ) {
    final rawData = result.toMap();
    final broaderImports = result.broaderImports;
    final data = _templateRenderer.resolveCodeSnipplets(rawData,
        defaultImports: [importRdfMapper, importDartCore],
        broaderImports: broaderImports);

    // Clean up aliasedImports URIs by removing asset:packageName/lib/ or asset:packageName/test/ prefixes
    _fixupAliasedImports(data, currentPackage);

    return data;
  }

  Map<String, String> _safeCastToStringMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, String>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val.toString()));
    }
    return {};
  }

  /// Sorts IRI mappers by parameter name for consistent ordering
  List<_InitFunctionParameter> _sortInitFunctionParameters(
      Map<String, _InitFunctionParameter> iriMappers) {
    return iriMappers.values.toList()
      ..sort((a, b) => (a.name!).compareTo(b.name!));
  }

  void _fixupAliasedImports(Map<String, dynamic> data, String currentPackage) {
    if (data['aliasedImports'] is List) {
      final aliasedImports = data['aliasedImports'] as List;
      for (final import in aliasedImports) {
        if (import is Map<String, dynamic> && import['uri'] is String) {
          final uri = import['uri'] as String;
          final cleanedUri = _cleanupImportUri(uri, currentPackage);
          import['uri'] = cleanedUri;
        }
      }
    }
  }

  /// Cleans up import URIs by removing asset:packageName/lib/ or asset:packageName/test/ prefixes
  String _cleanupImportUri(String uri, String currentPackage) {
    // Check for asset:packageName/lib/ prefix
    final libPrefix = 'asset:$currentPackage/lib/';
    if (uri.startsWith(libPrefix)) {
      return 'package:$currentPackage/${uri.substring(libPrefix.length)}';
    }

    // Check for asset:packageName/test/ prefix
    final testPrefix = 'asset:$currentPackage/test/';
    if (uri.startsWith(testPrefix)) {
      return '${uri.substring(testPrefix.length)}';
    }
    // Check for asset:packageName/ prefix
    final assetPrefix = 'asset:$currentPackage/';
    if (uri.startsWith(assetPrefix)) {
      return 'package:$currentPackage/${uri.substring(assetPrefix.length)}';
    }

    // Return the URI unchanged if no prefixes match
    return uri;
  }

  Future<String> build(
    List<(String path, String package, String content)> jsonFiles,
    AssetReader reader, {
    required bool isTest,
    required String outputPath,
    required String currentPackage,
  }) async {
    final templateData = buildTemplateData(
      jsonFiles,
      isTest: isTest,
      outputPath: outputPath,
      currentPackage: currentPackage,
    );
    if (templateData == null) {
      return '';
    }

    return await _templateRenderer.renderInitFileTemplate(templateData, reader);
  }
}
