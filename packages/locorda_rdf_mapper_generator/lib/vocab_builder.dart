import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:locorda_rdf_mapper_generator/src/vocab/turtle_generator.dart';
import 'package:locorda_rdf_terms_core/rdfs.dart';

Builder rdfVocabBuilder(BuilderOptions options) =>
    VocabBuilder(options, iriTermFactory: IriTerm.validated);

Map<String, RdfGraph> collectVocabDataForTesting(
  List<(String path, String content)> jsonFiles, {
  IriTermFactory iriTermFactory = IriTerm.validated,
}) =>
    _collectVocabData(jsonFiles, iriTermFactory: iriTermFactory);

class VocabBuilder implements Builder {
  final _ParsedVocabOptions _options;
  final Map<String, List<String>> _buildExtensions;
  final IriTermFactory _iriTermFactory;

  VocabBuilder(BuilderOptions options,
      {IriTermFactory iriTermFactory = IriTerm.validated})
      : this._(_parseOptions(options), iriTermFactory: iriTermFactory);

  VocabBuilder._(_ParsedVocabOptions options,
      {required IriTermFactory iriTermFactory})
      : _options = options,
        _buildExtensions = _computeBuildExtensions(options),
        _iriTermFactory = iriTermFactory;

  @override
  Map<String, List<String>> get buildExtensions => _buildExtensions;

  @override
  Future<void> build(BuildStep buildStep) async {
    if (!buildStep.inputId.path.endsWith('pubspec.yaml')) {
      return;
    }

    final cacheFiles =
        await buildStep.findAssets(Glob('**/*.rdf_mapper.cache.json')).toList();
    if (cacheFiles.isEmpty) {
      return;
    }

    final jsonFiles = await Future.wait(cacheFiles.map((file) async => (
          file.path,
          await buildStep.readAsString(file),
        )));

    final currentLockState = _collectLockState(jsonFiles);
    final existingLockState = _readLockState();
    final lockComparison = _compareLockStates(
      previous: existingLockState,
      current: currentLockState,
    );
    for (final info in lockComparison.infos) {
      log.info(info);
    }
    for (final warning in lockComparison.warnings) {
      log.warning(warning);
    }
    if (lockComparison.errors.isNotEmpty) {
      throw StateError(lockComparison.errors.join('\n\n'));
    }

    final vocabData =
        _collectVocabData(jsonFiles, iriTermFactory: _iriTermFactory);
    if (vocabData.isEmpty) {
      return;
    }

    if (_options.isConfigured) {
      final missing = vocabData.keys
          .where((vocabIri) => !_options.vocabularies.containsKey(vocabIri))
          .toList();
      if (missing.isNotEmpty) {
        throw StateError(
            'Vocabulary IRIs not configured in vocabularies: ${missing.join(', ')}');
      }
    }

    final graphByOutputPath = <String, RdfGraph>{};
    for (final entry in vocabData.entries) {
      final vocabIri = entry.key;
      final vocabConfig = _options.vocabularies[vocabIri];
      final outputPath = _resolveOutputPath(
        vocabIri: vocabIri,
        vocabConfig: vocabConfig,
        vocabCount: vocabData.length,
        isConfigured: _options.isConfigured,
      );

      final extensionPath = vocabConfig?.extensions;
      final graphWithExtensions = extensionPath == null
          ? entry.value
          : entry.value
              .merge(await _readExtensionGraph(buildStep, extensionPath));

      final existingGraph = graphByOutputPath[outputPath];
      if (existingGraph == null) {
        graphByOutputPath[outputPath] = graphWithExtensions;
      } else {
        graphByOutputPath[outputPath] =
            existingGraph.merge(graphWithExtensions);
      }
    }

    for (final entry in graphByOutputPath.entries) {
      await buildStep.writeAsString(
        AssetId(buildStep.inputId.package, entry.key),
        turtle.encode(entry.value),
      );
    }

    _writeLockState(currentLockState);
  }
}

Future<RdfGraph> _readExtensionGraph(
    BuildStep buildStep, String extensionPath) async {
  final extensionAsset = AssetId(buildStep.inputId.package, extensionPath);
  final extensionContent = await buildStep.readAsString(extensionAsset);

  try {
    return rdf.decode(extensionContent, contentType: 'text/turtle');
  } catch (_) {
    try {
      return rdf.decode(extensionContent, contentType: 'application/trig');
    } catch (error) {
      throw StateError(
          'Failed to parse extension file "$extensionPath" as Turtle or TriG: $error');
    }
  }
}

String _resolveOutputPath({
  required String vocabIri,
  required _VocabularyConfig? vocabConfig,
  required int vocabCount,
  required bool isConfigured,
}) {
  if (!isConfigured) {
    if (vocabCount > 1) {
      throw StateError(
          'Multiple vocabularies found but no vocabularies configured. '
          'Please configure vocabularies in build.yaml to specify where each vocabulary should be written, '
          'or ensure that only a single vocabulary is used. Found vocabularies: $vocabIri');
    }
    return _defaultOutputPath;
  }

  final configuredOutputPath = vocabConfig?.outputFile;
  if (configuredOutputPath != null && configuredOutputPath.isNotEmpty) {
    return configuredOutputPath;
  }

  if (vocabCount == 1) {
    return _defaultOutputPath;
  }

  throw StateError(
      'Vocabulary "$vocabIri" has no output_file configured in vocabularies and multiple vocabularies are present.');
}

const _defaultOutputPath = 'lib/vocab.g.ttl';

class _VocabularyConfig {
  final String? outputFile;
  final String? extensions;

  const _VocabularyConfig({
    required this.outputFile,
    required this.extensions,
  });
}

class _ParsedVocabOptions {
  final bool isConfigured;
  final Map<String, _VocabularyConfig> vocabularies;

  const _ParsedVocabOptions({
    required this.isConfigured,
    required this.vocabularies,
  });
}

_ParsedVocabOptions _parseOptions(BuilderOptions options) {
  final vocabularies = options.config['vocabularies'];
  if (vocabularies != null) {
    if (vocabularies is! Map) {
      throw ArgumentError.value(vocabularies, 'vocabularies',
          'Must be a map of vocab IRI to configuration.');
    }

    final result = <String, _VocabularyConfig>{};
    vocabularies.forEach((key, value) {
      if (key is! String) {
        throw ArgumentError('vocabularies keys must be strings. Found: $key');
      }

      if (value is String) {
        result[key] = _VocabularyConfig(outputFile: value, extensions: null);
        return;
      }

      if (value is! Map) {
        throw ArgumentError(
            'vocabularies[$key] must be a string or map. Found: $value');
      }

      final outputFile = value['output_file'];
      if (outputFile != null && outputFile is! String) {
        throw ArgumentError(
            'vocabularies[$key].output_file must be a string if provided. Found: $outputFile');
      }

      final extensions = value['extensions'];
      if (extensions != null && extensions is! String) {
        throw ArgumentError(
            'vocabularies[$key].extensions must be a string if provided. Found: $extensions');
      }

      result[key] = _VocabularyConfig(
        outputFile: outputFile as String?,
        extensions: extensions as String?,
      );
    });

    return _ParsedVocabOptions(isConfigured: true, vocabularies: result);
  }

  final outputFiles = options.config['output_files'];
  if (outputFiles == null) {
    return const _ParsedVocabOptions(isConfigured: false, vocabularies: {});
  }
  if (outputFiles is! Map) {
    throw ArgumentError.value(outputFiles, 'output_files',
        'Must be a map of vocab IRI to file path.');
  }

  final legacyResult = <String, _VocabularyConfig>{};
  outputFiles.forEach((key, value) {
    if (key is! String || value is! String) {
      throw ArgumentError(
          'output_files entries must be string to string. Found: $key -> $value');
    }
    legacyResult[key] = _VocabularyConfig(outputFile: value, extensions: null);
  });
  return _ParsedVocabOptions(isConfigured: true, vocabularies: legacyResult);
}

Map<String, List<String>> _computeBuildExtensions(_ParsedVocabOptions options) {
  if (options.vocabularies.isEmpty) {
    return const {
      'pubspec.yaml': [_defaultOutputPath]
    };
  }

  final outputs = options.vocabularies.values
      .map((v) => v.outputFile)
      .whereType<String>()
      .toSet()
      .toList()
    ..sort();

  final hasMissingOutputPath =
      options.vocabularies.values.any((v) => v.outputFile == null);
  if (hasMissingOutputPath) {
    outputs.add(_defaultOutputPath);
  }

  return {
    'pubspec.yaml': outputs,
  };
}

Map<String, RdfGraph> _collectVocabData(
    List<(String path, String content)> jsonFiles,
    {required IriTermFactory iriTermFactory}) {
  final vocabByIri = <String, _MutableVocabOntology>{};
  final fragmentUsage = <String, Map<String, _FragmentUsage>>{};

  for (final file in jsonFiles) {
    final (_, content) = file;
    final jsonData = jsonDecode(content) as Map<String, dynamic>;
    final mappers = (jsonData['mappers'] as List? ?? []).cast<dynamic>();

    for (final mapper in mappers) {
      if (mapper is! Map<String, dynamic>) {
        continue;
      }
      if (mapper['__type__'] != 'ResourceMapperTemplateData') {
        continue;
      }
      if (mapper['hasVocab'] != true) {
        continue;
      }
      final vocabMap = mapper['vocab'] as Map<String, dynamic>?;
      if (vocabMap == null) {
        continue;
      }
      final appBaseUri = vocabMap['appBaseUri'] as String?;
      final vocabPath = vocabMap['vocabPath'] as String?;
      if (appBaseUri == null || vocabPath == null) {
        continue;
      }
      final className =
          Code.fromMap(mapper['className'] as Map<String, dynamic>)
              .codeWithoutAlias
              .split('<')
              .first;

      final vocabIri = '$appBaseUri$vocabPath#';
      final mutableOntology = vocabByIri.putIfAbsent(
        vocabIri,
        () => _MutableVocabOntology(
          vocabularyIri: iriTermFactory(vocabIri),
          metadata: {},
        ),
      );

      _mergeMetadata(
        mutableOntology.metadata,
        _extractOntologyMetadata(vocabMap, iriTermFactory: iriTermFactory),
        vocabIri: vocabIri,
        sourceName: className,
      );

      final classMetadata = _extractMetadata(
        mapper['genVocabMetadata'],
        iriTermFactory: iriTermFactory,
      );

      // Auto-generate rdfs:label from class name if not explicitly provided
      if (!classMetadata.containsKey(Rdfs.label)) {
        classMetadata[Rdfs.label] = [
          LiteralTerm(_generateLabelFromCamelCase(className))
        ];
      }

      final classIri = '$vocabIri$className';
      final subClassOfIri = (mapper['subClassOfIri'] as String?) ??
          (vocabMap['defaultBaseClass'] as String?);

      final properties = (mapper['properties'] as List? ?? []).cast<dynamic>();
      final propertyDefinitions = <VocabPropertyDefinition>[];
      for (final property in properties) {
        if (property is! Map<String, dynamic>) {
          continue;
        }
        if (property['isRdfProperty'] != true) {
          continue;
        }
        // FIXME: include is documented differently!!!! I rather not have this
        // hack here because it is confusing if the user thinks they disabled
        // inclusion in serialization (as documented) but it actually also disables inclusion in vocab generation.
        //if (property['include'] == false) {
        //  continue;
        //}
        final fragment = property['fragment'] as String?;
        if (fragment == null || fragment.isEmpty) {
          continue;
        }

        final noDomain = property['noDomain'] == true;

        final vocabFragments = fragmentUsage.putIfAbsent(
            vocabIri, () => <String, _FragmentUsage>{});
        final sourceName = '$className.${property['propertyName'] ?? fragment}';
        final propertyMetadata = _extractMetadata(property['metadata'],
            iriTermFactory: iriTermFactory);
        final explicitDomain = _extractExplicitDomain(propertyMetadata);
        final existing = vocabFragments[fragment];
        final usage = _FragmentUsage(
          sourceName: sourceName,
          classIri: classIri,
          noDomain: noDomain,
          explicitDomain: explicitDomain,
        );
        if (existing != null &&
            !_areCompatibleFragmentUsages(existing, usage)) {
          throw StateError(
              "Duplicate fragment '$fragment' in vocabulary '$vocabIri' has conflicting domain semantics. "
              'Used by ${existing.sourceName} and $sourceName. '
              'Resolve by using shared explicit rdfs:domain, noDomain: true on all occurrences, '
              'or different fragments.');
        }
        vocabFragments.putIfAbsent(fragment, () => usage);

        // Auto-generate rdfs:label from fragment if not explicitly provided
        if (!propertyMetadata.containsKey(Rdfs.label)) {
          propertyMetadata[Rdfs.label] = [
            LiteralTerm(_generateLabelFromCamelCase(fragment))
          ];
        }

        propertyDefinitions.add(VocabPropertyDefinition(
          propertyIri: iriTermFactory('$vocabIri$fragment'),
          noDomain: noDomain,
          metadata: propertyMetadata,
        ));
      }

      final definition = VocabClassDefinition(
        classIri: iriTermFactory(classIri),
        subClassOfIri:
            subClassOfIri == null ? null : iriTermFactory(subClassOfIri),
        metadata: classMetadata,
        properties: propertyDefinitions,
      );
      mutableOntology.classes.add(definition);
    }
  }

  return {
    for (final entry in vocabByIri.entries)
      entry.key: createOwlOntology(entry.value.toDefinition()),
  };
}

void _mergeMetadata(
  Map<IriTerm, List<RdfObject>> target,
  Map<IriTerm, List<RdfObject>> incoming, {
  required String vocabIri,
  required String sourceName,
}) {
  for (final entry in incoming.entries) {
    final existing = target[entry.key];
    if (existing == null) {
      target[entry.key] = List<RdfObject>.from(entry.value);
      continue;
    }
    // Merge values - add any new values not already in the list
    for (final value in entry.value) {
      if (!existing.contains(value)) {
        existing.add(value);
      }
    }
  }
}

Map<IriTerm, List<RdfObject>> _extractOntologyMetadata(
    Map<String, dynamic> data,
    {required IriTermFactory iriTermFactory}) {
  final metadata =
      _extractMetadata(data['metadata'], iriTermFactory: iriTermFactory);

  final label = data['label'] as String?;
  final comment = data['comment'] as String?;

  if (label != null && label.isNotEmpty) {
    metadata.putIfAbsent(Rdfs.label, () => []).add(LiteralTerm(label));
  }
  if (comment != null && comment.isNotEmpty) {
    metadata.putIfAbsent(Rdfs.comment, () => []).add(LiteralTerm(comment));
  }

  return metadata;
}

Map<IriTerm, List<RdfObject>> _extractMetadata(dynamic metadataRaw,
    {required IriTermFactory iriTermFactory}) {
  if (metadataRaw == null) {
    return {};
  }

  if (metadataRaw is! Map<String, dynamic>) {
    throw ArgumentError.value(
        metadataRaw, 'metadata', 'Expected a map of IRI to RDF object values.');
  }

  final metadata = <IriTerm, List<RdfObject>>{};

  for (final entry in metadataRaw.entries) {
    final key = entry.key;
    final values = entry.value;
    if (values is! List) {
      continue;
    }

    for (final value in values) {
      if (value is! Map<String, dynamic>) {
        continue;
      }
      final literalValue = value['value'] as String?;
      if (literalValue == null) {
        continue;
      }

      final termType = value['termType'] as String?;
      if (termType == 'iri') {
        metadata
            .putIfAbsent(iriTermFactory(key), () => [])
            .add(iriTermFactory(literalValue));
        continue;
      }

      final datatype = value['datatype'] as String?;
      final language = value['language'] as String?;
      metadata.putIfAbsent(iriTermFactory(key), () => []).add(datatype == null
          ? LiteralTerm(literalValue, language: language)
          : LiteralTerm(literalValue,
              datatype: iriTermFactory(datatype), language: language));
    }
  }

  return metadata;
}

/// Generates a human-readable label from a camelCase identifier.
///
/// Examples:
/// - "displayTitle" → "Display Title"
/// - "isbn" → "Isbn"
/// - "pageCount" → "Page Count"
String _generateLabelFromCamelCase(String identifier) {
  if (identifier.isEmpty) return identifier;

  // Insert space before uppercase letters that follow lowercase letters
  final spacedIdentifier = identifier.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match[1]} ${match[2]}',
  );

  // Capitalize first letter
  return spacedIdentifier[0].toUpperCase() + spacedIdentifier.substring(1);
}

IriTerm? _extractExplicitDomain(Map<IriTerm, List<RdfObject>> metadata) {
  final values = metadata[Rdfs.domain];
  if (values == null || values.isEmpty) {
    return null;
  }
  for (final value in values) {
    if (value is IriTerm) {
      return value;
    }
  }
  return null;
}

bool _areCompatibleFragmentUsages(_FragmentUsage first, _FragmentUsage second) {
  if (first.noDomain != second.noDomain) {
    return false;
  }

  final firstDomain = first.explicitDomain?.value;
  final secondDomain = second.explicitDomain?.value;

  if (first.noDomain && second.noDomain) {
    return firstDomain == null && secondDomain == null;
  }

  if (firstDomain != null || secondDomain != null) {
    return firstDomain != null && firstDomain == secondDomain;
  }

  return first.classIri == second.classIri;
}

_LockState _collectLockState(List<(String path, String content)> jsonFiles) {
  final types = <String, _LockTypeState>{};

  for (final (_, content) in jsonFiles) {
    final jsonData = jsonDecode(content) as Map<String, dynamic>;
    final mappers = (jsonData['mappers'] as List? ?? []).cast<dynamic>();

    for (final mapper in mappers) {
      if (mapper is! Map<String, dynamic>) {
        continue;
      }
      if (mapper['__type__'] != 'ResourceMapperTemplateData') {
        continue;
      }

      final className =
          Code.fromMap(mapper['className'] as Map<String, dynamic>)
              .codeWithoutAlias
              .split('<')
              .first;
      final typeKey = _buildQualifiedTypeKey(jsonData, className);
      final hasVocab = mapper['hasVocab'] == true;
      String classIri = 'dart:$className';
      if (hasVocab) {
        final vocabMap = mapper['vocab'] as Map<String, dynamic>?;
        final appBaseUri = vocabMap?['appBaseUri'] as String?;
        final vocabPath = vocabMap?['vocabPath'] as String?;
        if (appBaseUri != null && vocabPath != null) {
          classIri = '$appBaseUri$vocabPath#$className';
        }
      } else {
        final typeIriMap = mapper['typeIri'] as Map<String, dynamic>?;
        final typeIriCode = typeIriMap == null
            ? null
            : Code.fromMap(typeIriMap).codeWithoutAlias;
        final literalIri = typeIriCode == null
            ? null
            : RegExp(r"IriTerm\('([^']+)'\)").firstMatch(typeIriCode)?.group(1);
        if (literalIri != null && literalIri.isNotEmpty) {
          classIri = literalIri;
        }
      }

      final properties = <String, _LockPropertyState>{};
      final mapperProperties =
          (mapper['properties'] as List? ?? []).cast<dynamic>();
      for (final property in mapperProperties) {
        if (property is! Map<String, dynamic>) {
          continue;
        }
        if (property['isRdfProperty'] != true) {
          continue;
        }
        final propertyName = (property['propertyName'] as String?) ??
            (property['name'] as String?);
        final predicateIri = property['predicateIri'] as String?;
        if (propertyName == null ||
            predicateIri == null ||
            predicateIri.isEmpty) {
          continue;
        }
        final source = property['vocabPropertySource'] as String?;
        final resolvedSource =
            (source == null || source.isEmpty) ? 'external' : source;
        properties[propertyName] = _LockPropertyState(
          iri: predicateIri,
          source: resolvedSource,
        );
      }

      types[typeKey] = _LockTypeState(
        classIri: classIri,
        properties: properties,
      );
    }
  }

  return _LockState(types: types);
}

_LockState? _readLockState() {
  final file = File(_lockFileName);
  if (!file.existsSync()) {
    return null;
  }
  final raw = file.readAsStringSync();
  final json = jsonDecode(raw);
  if (json is! Map<String, dynamic>) {
    throw StateError('Invalid $_lockFileName format: expected JSON object.');
  }
  final version = json['lockFileVersion'];
  if (version != 1) {
    throw StateError('Unsupported $_lockFileName version: $version');
  }

  final typesRaw = json['types'];
  if (typesRaw is! Map<String, dynamic>) {
    throw StateError('Invalid $_lockFileName format: missing "types" map.');
  }

  final types = <String, _LockTypeState>{};
  for (final typeEntry in typesRaw.entries) {
    final typeName = typeEntry.key;
    final typeValue = typeEntry.value;
    if (typeValue is! Map<String, dynamic>) {
      continue;
    }
    final classIri = typeValue['classIri'] as String?;
    if (classIri == null) {
      continue;
    }

    final propertiesRaw = typeValue['properties'];
    final properties = <String, _LockPropertyState>{};
    if (propertiesRaw is Map<String, dynamic>) {
      for (final propEntry in propertiesRaw.entries) {
        final propName = propEntry.key;
        final propValue = propEntry.value;
        if (propValue is! Map<String, dynamic>) {
          continue;
        }
        final iri = propValue['iri'] as String?;
        final source = propValue['source'] as String?;
        if (iri == null || source == null) {
          continue;
        }
        properties[propName] = _LockPropertyState(iri: iri, source: source);
      }
    }

    types[typeName] =
        _LockTypeState(classIri: classIri, properties: properties);
  }

  return _LockState(types: types);
}

_LockComparison _compareLockStates({
  required _LockState? previous,
  required _LockState current,
}) {
  final errors = <String>[];
  final warnings = <String>[];
  final infos = <String>[];

  if (previous == null) {
    return _LockComparison(errors: errors, warnings: warnings, infos: infos);
  }

  for (final previousTypeEntry in previous.types.entries) {
    final typeName = previousTypeEntry.key;
    final previousType = previousTypeEntry.value;
    final currentType = current.types[typeName];

    if (currentType == null) {
      final hasAuto =
          previousType.properties.values.any((p) => p.source == 'auto');
      if (hasAuto) {
        errors.add(
          '[ERROR] Type "$typeName" disappeared and contains auto-mapped properties. '
          'This is a breaking RDF mapping change. Rename back or migrate existing data.',
        );
      } else {
        infos.add('[INFO] Type "$typeName" disappeared.');
      }
      continue;
    }

    if (previousType.classIri != currentType.classIri) {
      warnings.add(
        '[WARNING] Class IRI changed for "$typeName": '
        '${previousType.classIri} -> ${currentType.classIri}',
      );
    }

    for (final previousPropertyEntry in previousType.properties.entries) {
      final propertyName = previousPropertyEntry.key;
      final previousProperty = previousPropertyEntry.value;
      final currentProperty = currentType.properties[propertyName];

      if (currentProperty == null) {
        if (previousProperty.source == 'auto') {
          errors.add(
            '[ERROR] Auto-mapped property disappeared: $typeName.$propertyName '
            '(${previousProperty.iri}). This is a breaking RDF mapping change.',
          );
        } else {
          infos.add('[INFO] Property disappeared: $typeName.$propertyName');
        }
        continue;
      }

      if (previousProperty.iri != currentProperty.iri) {
        if (previousProperty.source == 'auto') {
          errors.add(
            '[ERROR] Auto-mapped property IRI changed for $typeName.$propertyName: '
            '${previousProperty.iri} -> ${currentProperty.iri}',
          );
        } else {
          warnings.add(
            '[WARNING] Property IRI changed for $typeName.$propertyName '
            '(source: ${previousProperty.source}): '
            '${previousProperty.iri} -> ${currentProperty.iri}',
          );
        }
      }
    }
  }

  return _LockComparison(errors: errors, warnings: warnings, infos: infos);
}

String _buildQualifiedTypeKey(Map<String, dynamic> jsonData, String className) {
  final header = jsonData['header'] as Map<String, dynamic>?;
  final sourcePath = header?['sourcePath'] as String?;
  final mapperFileImportUri = jsonData['mapperFileImportUri'] as String?;
  final packageName = _extractPackageNameFromAssetUri(mapperFileImportUri);

  if (packageName == null || packageName.isEmpty) {
    return sourcePath == null || sourcePath.isEmpty
        ? '#$className'
        : '$sourcePath#$className';
  }

  if (sourcePath == null || sourcePath.isEmpty) {
    return '$packageName#$className';
  }

  return '$packageName/$sourcePath#$className';
}

String? _extractPackageNameFromAssetUri(String? mapperFileImportUri) {
  if (mapperFileImportUri == null || mapperFileImportUri.isEmpty) {
    return null;
  }
  final match = RegExp(r'^asset:([^/]+)/').firstMatch(mapperFileImportUri);
  return match?.group(1);
}

void _writeLockState(_LockState state) {
  final sortedTypeNames = state.types.keys.toList()..sort();
  final types = <String, dynamic>{};
  for (final typeName in sortedTypeNames) {
    final typeState = state.types[typeName]!;
    final sortedPropertyNames = typeState.properties.keys.toList()..sort();
    final properties = <String, dynamic>{};
    for (final propertyName in sortedPropertyNames) {
      final propertyState = typeState.properties[propertyName]!;
      properties[propertyName] = {
        'iri': propertyState.iri,
        'source': propertyState.source,
      };
    }
    types[typeName] = {
      'classIri': typeState.classIri,
      'properties': properties,
    };
  }

  final jsonMap = {
    'lockFileVersion': 1,
    'types': types,
  };

  final file = File(_lockFileName);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(jsonMap));
}

const _lockFileName = '.locorda_rdf_mapper.lock';

class _FragmentUsage {
  final String sourceName;
  final String classIri;
  final bool noDomain;
  final IriTerm? explicitDomain;

  const _FragmentUsage({
    required this.sourceName,
    required this.classIri,
    required this.noDomain,
    required this.explicitDomain,
  });
}

class _LockPropertyState {
  final String iri;
  final String source;

  const _LockPropertyState({required this.iri, required this.source});
}

class _LockTypeState {
  final String classIri;
  final Map<String, _LockPropertyState> properties;

  const _LockTypeState({required this.classIri, required this.properties});
}

class _LockState {
  final Map<String, _LockTypeState> types;

  const _LockState({required this.types});
}

class _LockComparison {
  final List<String> errors;
  final List<String> warnings;
  final List<String> infos;

  const _LockComparison({
    required this.errors,
    required this.warnings,
    required this.infos,
  });
}

class _MutableVocabOntology {
  final IriTerm vocabularyIri;
  final Map<IriTerm, List<RdfObject>> metadata;
  final List<VocabClassDefinition> classes = <VocabClassDefinition>[];

  _MutableVocabOntology({
    required this.vocabularyIri,
    required this.metadata,
  });

  VocabOntologyDefinition toDefinition() {
    return VocabOntologyDefinition(
      vocabularyIri: vocabularyIri,
      metadata: metadata,
      classes: classes,
    );
  }
}
