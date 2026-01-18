// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';
import 'package:locorda_rdf_core/core.dart';

import 'package:locorda_rdf_xml/xml.dart';

import 'class_generator.dart';
import 'cross_vocabulary_resolver.dart';
import 'model/vocabulary_model.dart';
import 'utils/naming_conventions.dart';
import 'vocabulary_source.dart';

/// Logger for the vocabulary builder

/// Extracts the language version from the current Dart SDK version.
/// Returns the major.minor version (e.g., "3.10" from "3.10.0").
Version _getCurrentLanguageVersion() {
  // Platform.version format: "3.10.0 (stable) (Thu Nov 6 05:24:55 2025 -0800) on \"macos_arm64\""
  final versionString = Platform.version.split(' ').first;
  final version = Version.parse(versionString);
  // Use major.minor only for language version, ignore patch
  return Version(version.major, version.minor, 0);
}

class MutableVocabularyLoader {
  VocabularyLoader? _loader;
  Future<VocabularyLoaderResult> load(String namespace, String name) {
    if (_loader == null) {
      throw StateError('Vocabulary loader not set');
    }
    return _loader!(namespace, name);
  }
}

/// A builder that generates Dart classes for RDF vocabularies.
///
/// This builder reads vocabulary configuration JSON files and generates vocabulary
/// class files based on the configuration. The generated files are automatically
/// formatted according to Dart formatting guidelines.
///
/// ## build_runner Integration Limitations
///
/// This builder faces architectural constraints due to build_runner's [buildExtensions]
/// design. The [buildExtensions] getter only supports basename-based output patterns
/// relative to the input file's directory. Patterns like `{input}.dart` resolve to
/// `<input_basename>.dart` in the same directory as the input. It is impossible to
/// declare arbitrary nested output paths like `rdf/classes/alt.dart` from an input
/// file `vocabularies.json` located elsewhere.
///
/// ### Workaround Implementation
///
/// To accommodate the generation of nested directory structures (e.g., vocabulary
/// subdirectories with class files), this builder employs a hybrid approach:
///
/// 1. **Main vocabulary files** (e.g., `rdf.dart`, `rdfs.dart`) are written through
///    [BuildStep.writeAsString] and are explicitly declared in [buildExtensions].
///    These files benefit from build_runner's incremental build tracking.
///
/// 2. **Subdirectory files** (e.g., `rdf/classes/alt.dart`, `rdf/index.dart`) are
///    written directly to the filesystem using [File.writeAsStringSync], bypassing
///    [BuildStep] entirely. These files are not declared in [buildExtensions] because
///    build_runner cannot represent such nested patterns.
///
/// 3. **buildExtensions getter constraint**: The [buildExtensions] getter must
///    return output paths synchronously, but vocabulary names need to be read from
///    configuration files (potentially including package: URIs). Since getters cannot
///    be async, [_getVocabularyNamesForBuildExtensions] performs synchronous file I/O
///    using [File.readAsStringSync] and manual package resolution via
///    `.dart_tool/package_config.json`. This is unavoidable given Dart's language
///    constraints.
///
/// ### Consequences
///
/// - **Main files**: Full incremental build support. Changes are properly tracked.
/// - **Subdirectory files**: No incremental build support. These files are regenerated
///   on every build run, even if unchanged. Manual deletions are not detected.
/// - **Build system validation**: The direct file writes do not trigger
///   `UnexpectedOutputException` because they are not declared in [buildExtensions].
///
/// This is a pragmatic workaround given build_runner's current capabilities. The
/// alternative would be to generate all classes into a single monolithic Dart file,
/// which would create unmanageable files (e.g., schema.org vocabulary with nearly a thousand files currently would result
/// in a single ~36MB file) and severely impact IDE performance and code maintainability.
class VocabularyBuilder implements Builder {
  /// List of vocabulary configuration file paths (relative to package or using package: URLs)
  final List<String> vocabularyConfigs;

  /// Output directory for generated vocabulary files
  final String outputDir;

  /// Optional directory for caching downloaded vocabularies
  final String? cacheDir;

  /// The cross-vocabulary resolver that tracks relationships between vocabularies
  final CrossVocabularyResolver _resolver;

  /// Map of vocabulary models by name
  final Map<String, VocabularyModel> _vocabularyModels = {};

  final MutableVocabularyLoader mutableVocabularyLoader;

  /// Dart code formatter instance with same settings as `dart format` command line tool
  final DartFormatter _dartFormatter = DartFormatter(
    languageVersion: _getCurrentLanguageVersion(),
  );

  /// Creates a new vocabulary builder.
  ///
  /// [vocabularyConfigs] specifies paths to vocabulary configuration JSON files.
  /// Files are loaded in order, with later files overriding earlier ones at field level.
  /// The standard_vocabularies.json is always loaded first as the base layer.
  /// [outputDir] specifies where to generate the vocabulary files, relative to lib/.

  /// Public constructor that initializes internal dependencies and delegates to the inner constructor
  factory VocabularyBuilder({
    required List<String> vocabularyConfigs,
    required String outputDir,
    String? cacheDir,
  }) {
    // Create a mutable vocabulary loader that will be configured during build
    final loader = MutableVocabularyLoader();
    return VocabularyBuilder._inner(
      vocabularyConfigs: [
        "package:locorda_rdf_terms_generator/standard_vocabularies.json",
        ...vocabularyConfigs,
      ],
      outputDir: outputDir,
      mutableVocabularyLoader: loader,
      cacheDir: cacheDir,
    );
  }

  VocabularyBuilder._inner({
    required this.vocabularyConfigs,
    required this.outputDir,
    required this.mutableVocabularyLoader,
    this.cacheDir,
  }) : _resolver = CrossVocabularyResolver(
         vocabularyLoader: mutableVocabularyLoader.load,
       );

  /// Loads an implied vocabulary that was discovered through references
  static VocabularyLoader createVocabularyLoader(
    Map<String, VocabularySource> vocabularySources,
    String? cacheDir,
  ) {
    final loader = createRdfGraphLoader(vocabularySources, cacheDir);
    return (String namespace, String name) async {
      final result = (await loader(namespace, name));
      return _extractVocabulary(name, namespace, result?.$1, result?.$2);
    };
  }

  static Future<(RdfGraph?, VocabularySource)?> Function(
    String namespace,
    String name,
  )
  createRdfGraphLoader(
    Map<String, VocabularySource> vocabularySources,
    String? cacheDir,
  ) {
    return (String namespace, String name) async {
      log.info('Loading implied vocabulary "$name" from namespace $namespace');

      try {
        var source =
            vocabularySources.values
                .where((source) => source.namespace == namespace)
                .firstOrNull;

        if (source == null) {
          log.warning(
            'No configured source found for vocabulary $namespace ($name), trying to guess it',
          );
          // Try to derive a turtle URL from the namespace
          final sourceUrl = await _findVocabularyUrl(namespace);
          if (sourceUrl == null) {
            log.warning(
              'Could not derive a valid URL for vocabulary namespace: $namespace',
            );
            return null;
          }

          log.info('Using derived URL for vocabulary $name: $sourceUrl');

          // Create a source for the vocabulary - ohne spezifische Parsing-Flags für abgeleitete Vokabulare
          source = UrlVocabularySource(namespace, sourceUrl: sourceUrl);
          // Wrap with cache if cacheDir is configured
          final cacheDirValue = cacheDir;
          if (cacheDirValue != null) {
            source = CachedVocabularySource(
              source,
              cacheDirValue,
              NamingConventions.toSnakeCase(name),
            );
          }
        } else {
          log.info(
            'Using configured source for vocabulary $name: ${source.namespace}',
          );
        }

        return _loadRdfGraph(name, source, cacheDir);
      } catch (e, stackTrace) {
        log.severe(
          'Error loading implied vocabulary $name from $namespace: $e\n$stackTrace',
        );
        return null;
      }
    };
  }

  static Map<(String, VocabularySource), Future<(RdfGraph?, VocabularySource)>>
  _rdfGraphCache = {};

  static Future<(RdfGraph?, VocabularySource)> _loadRdfGraph(
    String name,
    VocabularySource source,
    String? cacheDir,
  ) {
    var cachedGraph = _rdfGraphCache[(name, source)];
    if (cachedGraph != null) {
      return cachedGraph;
    }
    final graph = _doLoadRdfGraph(name, source, cacheDir);
    _rdfGraphCache[(name, source)] = graph;
    return graph;
  }

  static Future<(RdfGraph?, VocabularySource)> _doLoadRdfGraph(
    String name,
    VocabularySource source,
    String? cacheDir,
  ) async {
    final namespace = source.namespace;

    // Überprüfen, ob das Vokabular übersprungen werden soll
    if (source.skipDownload) {
      final reason = source.skipDownloadReason ?? 'No reason provided';
      log.info('Deliberately skipping vocabulary "$name": $reason');
      return (null, source);
    }

    try {
      // Load the vocabulary content
      final content = await source.loadContent();
      if (content.isEmpty) {
        log.warning('Empty content for implied vocabulary $name');
        return (null, source);
      }

      log.info(
        'Loaded content for vocabulary $name: ${content.substring(0, min(content.length, 500))}',
      );
      // Convert parsing flags to a set of TurtleParsingFlag values
      final parsingFlags = _convertParsingFlagsToSet(source.parsingFlags);

      // Parse the vocabulary
      final rdfCore = RdfCore.withCodecs(
        codecs: [
          TurtleCodec(
            decoderOptions: TurtleDecoderOptions(parsingFlags: parsingFlags),
          ),
          JsonLdGraphCodec(),
          RdfXmlCodec(),
          NTriplesCodec(),
        ],
      );

      RdfGraph? graph;

      try {
        log.info('Trying to parse $name ');
        if (source.parsingFlags != null && source.parsingFlags!.isNotEmpty) {
          log.info('Using parsing flags: ${source.parsingFlags!.join(", ")}');
        }

        graph = rdfCore.decode(
          content,
          documentUrl: source.namespace,
          contentType: source.contentType,
        );

        log.info('Successfully parsed $name');
        return (graph, source);
      } catch (e) {
        log.severe(
          'Failed to parse implied vocabulary $name from $namespace: $e',
        );
        return (null, source);
      }
    } catch (e, stackTrace) {
      log.severe(
        'Error loading vocabulary $name from $namespace: $e\n$stackTrace',
      );
      return (null, source);
    }
  }

  static Future<VocabularyLoaderResult> _extractVocabulary(
    String name,
    String namespace,
    RdfGraph? graph,
    VocabularySource? source,
  ) async {
    try {
      if (graph == null || source == null) {
        if (source != null && source.skipDownload) {
          log.warning(
            'Skipped extracting vocabulary "$name": ' +
                'Reason: ${source.skipDownloadReason ?? "No reason provided"}',
          );
        } else {
          log.severe('Failed to load RDF graph for vocabulary $name');
        }
        return (null, source);
      }

      // Extract the vocabulary model
      final model = VocabularyModelExtractor.extractFrom(
        graph,
        namespace,
        name,
        source,
      );
      log.info('Successfully extracted vocabulary model for $name');

      return (model, source);
    } catch (e, stackTrace) {
      log.severe(
        'Error extracting vocabulary $name from $namespace: $e\n$stackTrace',
      );
      return (null, source);
    }
  }

  static Future<VocabularyLoaderResult> _loadVocabulary(
    String name,
    VocabularySource source,
    String? cacheDir,
  ) async {
    final namespace = source.namespace;

    final (graph, _) = await _loadRdfGraph(name, source, cacheDir);
    return _extractVocabulary(name, namespace, graph, source);
  }

  /// Algorithmically tries to find a valid turtle URL for a vocabulary namespace
  static Future<String?> _findVocabularyUrl(String namespace) async {
    // List of URL patterns to try, in order of preference
    final urlCandidates = <String>[];

    // Case 0: Try the namespace URL directly as is
    urlCandidates.add(namespace);

    // Case 1: Remove trailing hash and add .ttl extension
    if (namespace.endsWith('#')) {
      urlCandidates.add('${namespace.substring(0, namespace.length - 1)}.ttl');
    }

    // Case 2: Remove trailing slash and add .ttl extension
    if (namespace.endsWith('/')) {
      urlCandidates.add('${namespace.substring(0, namespace.length - 1)}.ttl');
    }

    // Case 3: As-is with .ttl appended (works for some vocabularies)
    urlCandidates.add('$namespace.ttl');

    // Case 4: Try with -ns.ttl suffix (common for W3C)
    if (namespace.endsWith('#') || namespace.endsWith('/')) {
      final base = namespace.substring(0, namespace.length - 1);
      urlCandidates.add('$base-ns.ttl');
    } else {
      urlCandidates.add('$namespace-ns.ttl');
    }

    // Case 5: Known W3C pattern where the schema is in a specific file without the hash
    final hashIndex = namespace.lastIndexOf('#');
    if (hashIndex > 0) {
      urlCandidates.add(namespace.substring(0, hashIndex));
    }

    // Try each URL candidate until we find one that works
    for (final url in urlCandidates) {
      log.info('Trying vocabulary URL: $url');

      try {
        final response = await http.head(
          Uri.parse(url),
          headers: {'Accept': 'text/turtle, application/ld+json'},
        );

        if (response.statusCode == 200) {
          log.info('Found valid vocabulary URL: $url');
          return url;
        }
      } catch (e) {
        log.fine('Error checking URL $url: $e');
        // Continue to the next URL candidate
      }
    }

    // If all attempts fail, return null
    return null;
  }

  /// Konvertiert die String-Liste der Parsing-Flags in ein Set von TurtleParsingFlag-Werten
  static Set<TurtleParsingFlag> _convertParsingFlagsToSet(
    List<String>? flagsList,
  ) {
    final Set<TurtleParsingFlag> flagsSet = {};
    if (flagsList != null) {
      for (final flag in flagsList) {
        flagsSet.add(TurtleParsingFlag.values.byName(flag));
      }
    }
    return flagsSet;
  }

  /// Loads vocabulary names from configuration for buildExtensions.
  /// Uses synchronous file I/O since buildExtensions is called before build() runs.
  List<String> _getVocabularyNamesForBuildExtensions() {
    final allVocabularyNames = <String>[];

    // Load each user config file
    for (final configPath in vocabularyConfigs) {
      // Skip package: URLs for now - can't easily resolve synchronously
      final String filePath;
      if (configPath.startsWith('package:')) {
        final p = configPath.substring('package:'.length);
        final packageName = p.split('/').first;
        final remainingPath = p.substring(packageName.length + 1);
        final packagePath = _findPackagePath(packageName);
        if (packagePath == null) {
          log.warning(
            'Cannot resolve package URI synchronously for buildExtensions: $configPath',
          );
          continue;
        }
        filePath = path.join(packagePath, remainingPath);
      } else {
        filePath = configPath;
      }

      final configFile = File(filePath);
      if (!configFile.existsSync()) {
        continue;
      }

      try {
        allVocabularyNames.addAll(_readVocabulariesToGenerate(configFile));
      } catch (e) {
        // Ignore errors for individual config files
        log.warning('Could not load config file $configPath: $e');
      }
    }

    return allVocabularyNames;
  }

  Iterable<String> _readVocabulariesToGenerate(File configFile) {
    final content = configFile.readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final vocabsJson = json['vocabularies'] as Map<String, dynamic>?;
    if (vocabsJson != null) {
      return vocabsJson.entries
          .where((entry) {
            final config = entry.value as Map<String, dynamic>;
            final generate = config['generate'] as bool? ?? true;
            return generate;
          })
          .map((entry) => entry.key);
    }
    return const [];
  }

  /// Find package path by looking for .dart_tool/package_config.json
  String? _findPackagePath(String packageName) {
    var currentDir = Directory.current;

    while (true) {
      final packageConfigFile = File(
        path.join(currentDir.path, '.dart_tool', 'package_config.json'),
      );

      if (packageConfigFile.existsSync()) {
        try {
          final configContent = packageConfigFile.readAsStringSync();
          final config = json.decode(configContent) as Map<String, dynamic>;
          final packages = config['packages'] as List<dynamic>?;

          if (packages != null) {
            for (final pkg in packages) {
              if (pkg['name'] == packageName) {
                final rootUri = pkg['rootUri'] as String?;
                if (rootUri != null) {
                  final packageConfigDir = packageConfigFile.parent.parent.path;
                  return path.normalize(path.join(packageConfigDir, rootUri));
                }
              }
            }
          }
        } catch (e) {
          // Ignore parsing errors
        }
      }

      final parent = currentDir.parent;
      if (parent.path == currentDir.path) {
        break; // Reached root
      }
      currentDir = parent;
    }

    return null;
  }

  @override
  Map<String, List<String>> get buildExtensions {
    // Use the first config file as trigger, output to configured outputDir
    // Must explicitly list all possible outputs since glob patterns don't work reliably
    final firstConfig = vocabularyConfigs.firstWhere(
      (config) => !config.startsWith('package:'),
      orElse: () => 'lib/src/vocabularies.json',
    );

    final outputs = <String>['$outputDir/_index.dart'];

    // Load vocabulary names and generate explicit paths
    final vocabNames = _getVocabularyNamesForBuildExtensions();
    for (final name in vocabNames) {
      final snakeCaseName = NamingConventions.toSnakeCase(name);
      // Main vocabulary file
      outputs.add('$outputDir/$snakeCaseName.dart');
    }

    final r = {firstConfig: outputs};
    return r;
  }

  /// Formats a Dart source code string according to Dart style guidelines
  ///
  /// Returns the formatted code string, or the original string if formatting fails
  String _formatDartCode(String dartCode) {
    try {
      return _dartFormatter.format(dartCode);
    } catch (e, stackTrace) {
      log.warning('Failed to format Dart code: $e\n$stackTrace');
      // Return unformatted code if formatting fails
      return dartCode;
    }
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    log.info('Starting vocabulary generation');

    // Read and merge vocabulary configuration files
    final vocabularySources = await _loadVocabularyManifest(buildStep);
    if (vocabularySources == null || vocabularySources.isEmpty) {
      log.severe(
        'Failed to load vocabularies from configs: ${vocabularyConfigs.join(", ")}',
      );
      return;
    }

    // Important: make sure that the resolver uses the vocabulary config.
    mutableVocabularyLoader._loader = createVocabularyLoader(
      vocabularySources,
      cacheDir,
    );

    // Process all vocabularies in the manifest in two phases:
    // 1. Parse all vocabulary sources and register them with the resolver
    // 2. Generate code for all vocabularies using the resolver

    // Phase 1: Parse and register vocabularies
    await _parseVocabularies(buildStep, vocabularySources);

    // Load any vocabularies that were referenced but not explicitly defined
    await _resolver.loadPendingVocabularies();

    // Phase 2: Generate code for each vocabulary
    final results = await _generateVocabularyClasses(buildStep);

    // Generate the index file for successful vocabularies
    final successfulVocabularies =
        results.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    if (successfulVocabularies.isNotEmpty) {
      await _generateIndex(buildStep, successfulVocabularies);
    } else {
      log.warning('No vocabulary files were successfully generated');
    }

    log.info(
      'Vocabulary generation completed. '
      'Success: ${successfulVocabularies.length}/${results.length}',
    );
  }

  /// Loads and merges vocabulary configurations from multiple sources.
  ///
  /// Always loads standard_vocabularies.json as the base layer first, then loads
  /// and merges each config from vocabularyConfigs in order. Later configs override
  /// earlier ones at the field level.
  ///
  /// Supports package: URLs using AssetId.resolve().
  Future<Map<String, VocabularySource>?> _loadVocabularyManifest(
    BuildStep buildStep,
  ) async {
    try {
      Map<String, Map<String, dynamic>> mergedVocabs = {};

      // Load and merge each user config
      for (final configPath in vocabularyConfigs) {
        AssetId configId;

        // Support package: URLs
        if (configPath.startsWith('package:')) {
          configId = AssetId.resolve(Uri.parse(configPath));
        } else {
          configId = AssetId(buildStep.inputId.package, configPath);
        }

        if (!await buildStep.canRead(configId)) {
          log.warning('Configuration file not found: $configPath');
          continue;
        }

        final content = await buildStep.readAsString(configId);
        final json = jsonDecode(content) as Map<String, dynamic>;
        final vocabsJson = json['vocabularies'] as Map<String, dynamic>?;

        if (vocabsJson == null) {
          log.warning('No vocabularies found in config: $configPath');
          continue;
        }

        // Merge vocabularies - field-level override
        for (final entry in vocabsJson.entries) {
          final name = entry.key;
          final newConfig = entry.value as Map<String, dynamic>;

          if (mergedVocabs.containsKey(name)) {
            // Merge at field level - new fields override old ones
            mergedVocabs[name]!.addAll(newConfig);
          } else {
            // New vocabulary
            mergedVocabs[name] = Map<String, dynamic>.from(newConfig);
          }
        }

        log.info(
          'Merged config from $configPath (${vocabsJson.length} vocabularies)',
        );
      }

      // Convert merged configs to VocabularySource objects
      final vocabularies = <String, VocabularySource>{};

      for (final entry in mergedVocabs.entries) {
        final name = entry.key;
        final vocabConfig = entry.value;
        final type = vocabConfig['type'] as String? ?? 'url';
        final namespace = vocabConfig['namespace'] as String;

        // Extract turtle parsing flags if they exist
        List<String>? parsingFlags;
        if (vocabConfig.containsKey('parsingFlags')) {
          final flagsJson = vocabConfig['parsingFlags'];
          if (flagsJson is List) {
            parsingFlags = flagsJson.map((flag) => flag.toString()).toList();
            log.info('Found parsing flags for $name: $parsingFlags');
          } else {
            log.warning(
              'Invalid parsingFlags format for $name, expected a list',
            );
          }
        }

        // Check if the vocabulary is enabled, default to true if not specified
        final bool generate = vocabConfig['generate'] as bool? ?? true;

        // Get explicit content type if specified
        final String? explicitContentType =
            vocabConfig['contentType'] as String?;

        // Extract skip flag and reason if present
        final bool skipDownload = vocabConfig['skipDownload'] as bool? ?? false;
        final String? skipDownloadReason =
            vocabConfig['skipDownloadReason'] as String?;

        VocabularySource source;
        try {
          switch (type) {
            case 'url':
              // Use 'source' field if available, otherwise fall back to namespace
              final sourceUrl = vocabConfig['source'] ?? namespace;
              if (sourceUrl is! String) {
                throw ArgumentError(
                  'Invalid sourceUrl for vocabulary $name, expected a string, not $sourceUrl',
                );
              }

              source = UrlVocabularySource(
                namespace,
                sourceUrl: sourceUrl,
                parsingFlags: parsingFlags,
                enabled: generate,
                explicitContentType: explicitContentType,
                skipDownload: skipDownload,
                skipDownloadReason: skipDownloadReason,
              );
              // Wrap with cache if cacheDir is configured
              final cacheDirValue = cacheDir;
              if (cacheDirValue != null) {
                source = CachedVocabularySource(
                  source,
                  cacheDirValue,
                  NamingConventions.toSnakeCase(name),
                );
              }
              break;
            case 'file':
              final filePath = vocabConfig['source'];
              if (filePath is! String) {
                throw ArgumentError(
                  'Invalid filePath for vocabulary $name, expected a string, not $filePath',
                );
              }

              source = FileVocabularySource(
                filePath,
                namespace,
                parsingFlags: parsingFlags,
                generate: generate,
                explicitContentType: explicitContentType,
                skipDownload: skipDownload,
                skipDownloadReason: skipDownloadReason,
              );
              break;
            case 'package':
              final packageUri = vocabConfig['source'];
              if (packageUri is! String) {
                throw ArgumentError(
                  'Invalid packageUri for vocabulary $name, expected a string, not $packageUri',
                );
              }

              source = PackageVocabularySource(
                packageUri,
                namespace,
                buildStep,
                parsingFlags: parsingFlags,
                generate: generate,
                explicitContentType: explicitContentType,
                skipDownload: skipDownload,
                skipDownloadReason: skipDownloadReason,
              );
              break;
            default:
              log.warning('Unknown vocabulary source type: $type for $name');
              continue;
          }

          vocabularies[name] = source;
        } catch (e, stackTrace) {
          log.severe(
            'Error creating source for vocabulary $name: $e\n$stackTrace',
          );
          // Skip this vocabulary
        }
      }

      log.info('Final merged vocabulary count: ${vocabularies.length}');
      return vocabularies;
    } catch (e, stackTrace) {
      log.severe('Error loading vocabulary configs: $e\n$stackTrace');
      return null;
    }
  }

  /// Phase 1: Parses all vocabulary sources and registers them with the resolver
  Future<void> _parseVocabularies(
    BuildStep buildStep,
    Map<String, VocabularySource> vocabularySources,
  ) async {
    log.info('Phase 1: Parsing vocabularies and registering with resolver');

    // Process vocabularies sequentially with a small delay to avoid overwhelming external servers
    for (final entry in vocabularySources.entries) {
      final name = entry.key;
      final source = entry.value;

      try {
        if (source.skipDownload) {
          final reason = source.skipDownloadReason ?? 'No reason provided';
          log.info('Deliberately skipping vocabulary "$name": $reason');
          continue;
        }

        log.info('Processing vocabulary: $name from ${source.namespace}');
        final (model, vocabSource) = await _loadVocabulary(
          name,
          source,
          cacheDir,
        );
        if (model == null) {
          if (vocabSource != null) {
            if (vocabSource.skipDownload) {
              log.info(
                'Deliberately skipped vocabulary "$name": ${vocabSource.skipDownloadReason ?? "No reason provided"}',
              );
              continue;
            } else {
              log.severe(
                'Failed to extract vocabulary model for $name from ${vocabSource.namespace}',
              );
            }
          } else {
            log.severe('Failed to extract vocabulary model for $name');
          }
          log.severe('Failed to parse vocabulary $name with any format');
          continue;
        }

        // Store the model for later use
        _vocabularyModels[name] = model;

        // Register the model with the cross-vocabulary resolver
        _resolver.registerVocabulary(model);

        log.info('Registered vocabulary: $name');

        // Small delay between requests to be polite to servers
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e, stackTrace) {
        log.severe('Error processing vocabulary $name: $e\n$stackTrace');
      }
    }

    log.info(
      'Phase 1 complete. Registered ${_vocabularyModels.length} vocabularies',
    );
  }

  /// Phase 2: Generate code for all vocabularies using the cross-vocabulary resolver
  Future<Map<String, bool>> _generateVocabularyClasses(
    BuildStep buildStep,
  ) async {
    log.info('Phase 2: Generating vocabulary classes');

    final results = <String, bool>{};
    final customNamespaces = <String, String>{
      for (var m in _vocabularyModels.values) m.prefix: m.namespace,
    };
    // Generate classes for each vocabulary
    for (final entry in _vocabularyModels.entries) {
      final name = entry.key;
      final scname = NamingConventions.toSnakeCase(name);
      final model = entry.value;
      if (!model.source.generate) {
        log.info(
          'Skipping vocabulary $name ($scname) as per manifest configuration',
        );
        continue;
      }
      try {
        // Generate Dart code with the class generator
        final generator = VocabularyClassGenerator(
          resolver: _resolver,
          outputDir: outputDir,
        );

        // Instead of writing to individual files, we'll generate a combined file
        // that contains all the necessary code and exports
        final filesMap = await generator.generateFiles(
          model,
          buildStep,
          customNamespaces,
        );

        // Format and write the main vocabulary file which we've declared in buildExtensions
        final mainCode = _formatDartCode(filesMap['main']!);
        final mainFilePath = _getFullOutputPath('$scname.dart');
        final mainFileId = AssetId(buildStep.inputId.package, mainFilePath);
        await buildStep.writeAsString(mainFileId, mainCode);

        // Create the directory structure for sub-files manually (not through build system)
        Directory(
          path.dirname(_getVocabularyDirPath(name)),
        ).createSync(recursive: true);

        // Create vocabulary-specific directory
        final vocabDir = Directory(_getVocabularyDirPath(name));
        if (!vocabDir.existsSync()) {
          vocabDir.createSync();
        }

        // Create classes directory
        final classesDir = Directory(_getVocabularyClassesPath(name));
        if (!classesDir.existsSync()) {
          classesDir.createSync();
        }

        // Write universal properties file if it exists
        if (filesMap.containsKey('universal')) {
          final universalCode = _formatDartCode(filesMap['universal']!);
          final universalFile = File(
            '${_getVocabularyDirPath(name)}/${scname}_universal.dart',
          );
          universalFile.writeAsStringSync(universalCode);
        }

        // Write each class to its own file in the classes directory
        for (final classEntry in filesMap.entries) {
          final className = classEntry.key;

          // Skip the main and universal files
          if (className == 'main' || className == 'universal') continue;

          // Use lowercase filenames for dart conventions
          final classFileName = className.toLowerCase();

          // Fix import path in the class file to point to the correct location
          String classCode = classEntry.value;
          classCode = classCode.replaceAll(
            "import '../$scname.dart';",
            "import '../../$scname.dart';",
          );

          // Check if the code imports the main class but doesn't use it - if so, remove the import
          if (!classCode.contains("$className.") &&
              classCode.contains("import '../../$scname.dart';")) {
            classCode = classCode.replaceAll(
              "import '../../$scname.dart';\n",
              "",
            );
          }

          final formattedCode = _formatDartCode(classCode);
          final classFile = File(
            '${_getVocabularyClassesPath(name)}/$classFileName.dart',
          );
          classFile.writeAsStringSync(formattedCode);
        }

        // Generate vocabulary index file
        final indexBuffer =
            StringBuffer()
              ..writeln(
                '// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>',
              )
              ..writeln(
                '// All rights reserved. Use of this source code is governed by a BSD-style',
              )
              ..writeln('// license that can be found in the LICENSE file.')
              ..writeln()
              ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
              ..writeln('// Generated by VocabularyBuilder')
              ..writeln();

        // Export all generated class files
        final sortedClassNames =
            filesMap.keys
                .where((key) => key != 'main' && key != 'universal')
                .toList()
              ..sort();

        for (final className in sortedClassNames) {
          // Use lowercase filenames for exports
          final classFileName = className.toLowerCase();
          indexBuffer.writeln("export 'classes/$classFileName.dart';");
        }

        // Export universal properties if applicable
        if (filesMap.containsKey('universal')) {
          indexBuffer.writeln("export '${scname}_universal.dart';");
        }

        // Write the formatted index file
        final indexCode = _formatDartCode(indexBuffer.toString());
        final indexFile = File('${_getVocabularyDirPath(name)}/index.dart');
        indexFile.writeAsStringSync(indexCode);

        log.info(
          'Generated vocabulary class: $scname with ${filesMap.length - 2} class files',
        );
        results[name] = true;
      } catch (e, stack) {
        log.severe('Error generating class for vocabulary $name: $e\n$stack');
        results[name] = false;
      }
    }

    return results;
  }

  /// Generates an index file that exports all generated vocabulary classes.
  Future<void> _generateIndex(
    BuildStep buildStep,
    Iterable<String> vocabularyNames,
  ) async {
    final buffer =
        StringBuffer()
          ..writeln('// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>')
          ..writeln(
            '// All rights reserved. Use of this source code is governed by a BSD-style',
          )
          ..writeln('// license that can be found in the LICENSE file.')
          ..writeln()
          ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
          ..writeln('// Generated by VocabularyBuilder')
          ..writeln();

    // Export all generated vocabulary files
    final sortedNames = vocabularyNames.toList()..sort();
    for (final name in sortedNames) {
      final scname = NamingConventions.toSnakeCase(name);
      buffer.writeln("export '$scname.dart';");

      // Also export the vocabulary directory with its classes if it exists
      final vocabDirPath = _getVocabularyDirPath(name);
      final vocabIndexPath = '$vocabDirPath/index.dart';
      final vocabIndexFile = File(vocabIndexPath);

      if (vocabIndexFile.existsSync()) {
        buffer.writeln("export '$scname/index.dart';");
      }
    }

    // Format the index file code
    final indexCode = buffer.toString();
    final formattedIndexCode = _formatDartCode(indexCode);

    final outputPath = _getFullOutputPath('_index.dart');
    final outputId = AssetId(buildStep.inputId.package, outputPath);

    await buildStep.writeAsString(outputId, formattedIndexCode);

    log.info('Generated vocabulary index file');
  }

  /// Converts a relative file path to the full output path.
  /// This ensures consistency between buildExtensions and actual file output.
  String _getFullOutputPath(String relativePath) {
    final baseOutputDir = outputDir;
    //outputDir.startsWith('lib/') ? outputDir : 'lib/$outputDir';
    return '$baseOutputDir/$relativePath';
  }

  /// Gets the path to a vocabulary directory (uses snake_case)
  String _getVocabularyDirPath(String vocabName) {
    final model = _vocabularyModels[vocabName];
    if (model == null) {
      throw StateError('Vocabulary model not found for: $vocabName');
    }
    final snakeCaseName = NamingConventions.toSnakeCase(model.prefix);
    return _getFullOutputPath(snakeCaseName);
  }

  /// Gets the path to a vocabulary's classes directory
  String _getVocabularyClassesPath(String vocabName) {
    return '${_getVocabularyDirPath(vocabName)}/classes';
  }
}
