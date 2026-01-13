// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as path;
import 'package:rdf_core/rdf_core.dart';

import 'cross_vocabulary_resolver.dart';
import 'model/vocabulary_model.dart';

/// Generator for creating Dart classes from vocabulary models.
///
/// This class is responsible for generating well-formatted Dart code
/// representing a vocabulary, with proper class structure, documentation,
/// and type safety.
class VocabularyClassGenerator {
  /// Cross-vocabulary resolver for handling properties across vocabulary boundaries
  final CrossVocabularyResolver resolver;

  /// Output directory for generated files, used to determine if library declarations should be included
  final String outputDir;

  final RdfNamespaceMappings _namespaceMappings;

  /// Creates a new vocabulary class generator.
  ///
  /// [resolver] Cross-vocabulary resolver for property inheritance across vocabularies
  /// [outputDir] Output directory for generated files, used to determine library declaration inclusion
  VocabularyClassGenerator({
    required this.resolver,
    required this.outputDir,
    RdfNamespaceMappings namespaceMappings = const RdfNamespaceMappings(),
  }) : _namespaceMappings = namespaceMappings;

  /// Cache for loaded Mustache templates
  final Map<String, Template> _templateCache = {};

  Future<String> loadTemplate(String name, AssetReader reader) async {
    final assetId = AssetId(
      'rdf_vocabulary_to_dart',
      path.join(
        'lib',
        'src',
        'vocab',
        'builder',
        'templates',
        '$name.mustache',
      ),
    );
    return await reader.readAsString(assetId);
  }

  /// Loads and caches a template from the template directory using package URI
  Future<Template> _getTemplate(String templateName, AssetReader reader) async {
    if (!_templateCache.containsKey(templateName)) {
      final templateSource = await loadTemplate(templateName, reader);
      _templateCache[templateName] = Template(
        templateSource,
        name: templateName,
        lenient: true,
        htmlEscapeValues: false, // Disable HTML escaping globally
      );
    }

    return _templateCache[templateName]!;
  }

  /// Generates Dart code for main vocabulary class.
  ///
  /// Returns a map containing all the generated code files:
  /// - 'main': The main vocabulary class (e.g. 'Rdf')
  /// - 'universal': The universal properties class (if applicable)
  /// - A key for each class name (e.g. 'RdfProperty') with its code
  Future<Map<String, String>> generateFiles(
    VocabularyModel model,
    AssetReader assetReader,
    Map<String, String> customMappings,
  ) async {
    final Map<String, String> generatedFiles = {};

    // Validate model has terms
    _validateModelHasTerms(model);

    // Generate main vocabulary file
    final mainFile = await _generateMainFile(model, assetReader);
    generatedFiles['main'] = mainFile;

    // Generate UniversalProperties class if needed
    final universalProperties =
        model.properties.where((p) => p.domains.isEmpty).toList();
    if (universalProperties.isNotEmpty) {
      final universalFile = await _generateUniversalPropertiesFile(
        model,
        universalProperties,
        assetReader,
        customMappings,
      );
      generatedFiles['universal'] = universalFile;
    }

    // Generate individual class files
    if (model.classes.isNotEmpty) {
      for (final rdfClass in model.classes) {
        final dartClassName = _dartIdentifier(rdfClass.localName);
        final classFile = await _generateClassFile(
          model,
          rdfClass,
          assetReader,
          customMappings,
        );
        generatedFiles[dartClassName] = classFile;
      }
    }

    return generatedFiles;
  }

  /// For backward compatibility with existing tests and integrations.
  /// Generates all code artifacts and combines them into a single string.
  Future<String> generate(
    VocabularyModel model,
    AssetReader assetReader,
  ) async {
    final Map<String, String> customMappings = {model.prefix: model.namespace};
    _validateModelHasTerms(model);

    // Debug log to help identify issues with test failures
    for (final rdfClass in model.classes) {
      log.info('Class: ${rdfClass.localName}, SeeAlso: ${rdfClass.seeAlso}');
    }
    for (final prop in model.properties) {
      log.info('Property: ${prop.localName}, Ranges: ${prop.ranges}');
    }

    final files = await generateFiles(model, assetReader, customMappings);
    final buffer = StringBuffer();

    // First add the main file
    buffer.write(files['main']);
    buffer.write('\n');

    // Add universal properties if they exist
    if (files.containsKey('universal')) {
      buffer.write(files['universal']);
      buffer.write('\n');
    }

    // Add all class-specific files
    // Sort keys for deterministic output
    final classKeys =
        files.keys.where((k) => k != 'main' && k != 'universal').toList()
          ..sort();

    for (final key in classKeys) {
      buffer.write(files[key]);
      buffer.write('\n');
    }

    return buffer.toString();
  }

  /// Generates the main vocabulary file
  Future<String> _generateMainFile(
    VocabularyModel model,
    AssetReader assetReader,
  ) async {
    final className = _capitalize(model.name);

    // Create the data model for the template
    final Map<String, dynamic> templateData = {
      'addLibraryDeclaration': !outputDir.contains('/src/'),
      'libraryDocumentation': '${className} Vocabulary',
      'libraryName': '${model.prefix}_vocab',
      'imports': [],
      'className': className,
      'namespace': model.namespace,
      'prefix': model.prefix,
      'vocabPrefix': model.prefix.toLowerCase(),
      'terms': _prepareTermsForTemplate([
        ...model.classes,
        ...model.datatypes,
        ...model.otherTerms,
        ...model.properties,
      ], model.prefix),
    };

    // Render the header and main class templates
    final headerTemplate = await _getTemplate('header', assetReader);
    final mainClassTemplate = await _getTemplate('main_class', assetReader);

    return headerTemplate.renderString(templateData) +
        mainClassTemplate.renderString(templateData);
  }

  /// Generates the universal properties file
  Future<String> _generateUniversalPropertiesFile(
    VocabularyModel model,
    List<VocabularyProperty> universalProperties,
    AssetReader assetReader,
    Map<String, String> customMappings,
  ) async {
    final className = _capitalize(model.name);
    final universalClassName = '${className}UniversalProperties';

    // Create the data model for the template
    final Map<String, dynamic> templateData = {
      'addLibraryDeclaration': !outputDir.contains('/src/'),
      'libraryDocumentation':
          'Universal Properties for the ${className} vocabulary',
      'libraryName': '${model.prefix}_universal_vocab',
      'imports': [],
      'className': className,
      'universalClassName': universalClassName,
      'namespace': model.namespace,
      'prefix': model.prefix,
      'vocabPrefix': model.prefix.toLowerCase(),
      'properties': _preparePropertiesForTemplate(
        universalProperties,
        model.prefix,
        model.namespace,
        customMappings,
      ),
    };

    // Render the header and universal properties templates
    final headerTemplate = await _getTemplate('header', assetReader);
    final universalTemplate = await _getTemplate(
      'universal_properties',
      assetReader,
    );

    return headerTemplate.renderString(templateData) +
        universalTemplate.renderString(templateData);
  }

  /// Generates a class file for a specific RDF class
  Future<String> _generateClassFile(
    VocabularyModel model,
    VocabularyClass rdfClass,
    AssetReader assetReader,
    Map<String, String> customMappings,
  ) async {
    final className = _capitalize(model.name);

    final dartClassName = '${className}${_dartIdentifier(rdfClass.localName)}';

    // Get all properties that can be used with this class
    final properties = resolver.getPropertiesForClass(
      rdfClass.iri,
      model.namespace,
    );

    // Get all parent classes for documentation
    final superClassList = _classsListForMustache(
      resolver.getAllSuperClasses(rdfClass.iri),
      rdfClass,
    );
    final equivalentClassesList = _classsListForMustache(
      resolver.getAllEquivalentClasses(rdfClass.iri),
      rdfClass,
    );
    // Remove any classes from equivalentClassesList that are already in superClassList
    // to avoid duplication in documentation
    equivalentClassesList.removeWhere(
      (eqClass) => superClassList.any(
        (superClass) => superClass['iri'] == eqClass['iri'],
      ),
    );
    final equivalentClassesSuperClassList = _classsListForMustache(
      resolver.getAllEquivalentClassSuperClasses(rdfClass.iri),
      rdfClass,
    );
    equivalentClassesSuperClassList.removeWhere(
      (eqClass) =>
          superClassList.any(
            (superClass) => superClass['iri'] == eqClass['iri'],
          ) ||
          equivalentClassesList.any(
            (superClass) => superClass['iri'] == eqClass['iri'],
          ),
    );

    // Create the data model for the template
    final Map<String, dynamic> templateData = {
      'addLibraryDeclaration': !outputDir.contains('/src/'),
      'libraryDocumentation':
          '${rdfClass.localName} class from ${className} vocabulary',
      'libraryName': '${model.prefix}_${dartClassName.toLowerCase()}_vocab',
      'imports': [],
      'className': className,
      'dartClassName': dartClassName,
      'localName': rdfClass.localName,
      'classIri': rdfClass.iri,
      'comment': _formatDartDocComment(rdfClass.comment),
      'namespace': model.namespace,
      'seeAlso': rdfClass.seeAlso,
      'superClasses': superClassList,
      'hasSuperClasses': superClassList.isNotEmpty,
      'equivalentClasses': equivalentClassesList,
      'hasEquivalentClasses': equivalentClassesList.isNotEmpty,
      'equivalentClassesSuperClasses': equivalentClassesSuperClassList,
      'hasEquivalentClassesSuperClasses':
          equivalentClassesSuperClassList.isNotEmpty,
      'properties': _preparePropertiesForTemplate(
        properties,
        model.prefix,
        model.namespace,
        customMappings,
      ),
    };

    // Render the header and class template
    final headerTemplate = await _getTemplate('header', assetReader);
    final classTemplate = await _getTemplate('class', assetReader);

    return headerTemplate.renderString(templateData) +
        classTemplate.renderString(templateData);
  }

  List<Map<String, String>> _classsListForMustache(
    Set<String> allSuperClasses,
    VocabularyClass rdfClass,
  ) {
    final superClassList =
        allSuperClasses.where((superClass) => superClass != rdfClass.iri).map((
          superClass,
        ) {
          return {
            'iri': superClass,
            'readableName': _extractReadableNameFromIri(superClass),
          };
        }).toList();

    // Sort parent classes for consistent output
    superClassList.sort(
      (a, b) =>
          (a['readableName'] as String).compareTo(b['readableName'] as String),
    );
    return superClassList;
  }

  /// Prepares a list of terms for use in a template
  List<Map<String, dynamic>> _prepareTermsForTemplate(
    List<VocabularyTerm> terms,
    String prefix,
  ) {
    return terms.map((term) {
      final Map<String, dynamic> result = {
        'localName': term.localName,
        'iri': term.iri,
        'dartName': _dartIdentifier(term.localName),
        'comment': _formatDartDocComment(term.comment),
        'vocabPrefix': prefix.toLowerCase(),
        'seeAlso': term.seeAlso,
        'hasSeeAlso': term.seeAlso.isNotEmpty,
      };

      // Add range information if the term is a property
      if (term is VocabularyProperty) {
        result['ranges'] = _toMustacheList(term.ranges);
        result['hasRanges'] = term.ranges.isNotEmpty;
        // Add domain information for properties
        result['domainDescription'] = _getDomainDescription(term, null);
        result['domains'] = term.domains;
      }

      return result;
    }).toList();
  }

  /// Enriches a list of strings for Mustache templating.
  /// Each element becomes a map with `value` and `last`.
  List<Map<String, dynamic>> _toMustacheList(List<String> values) {
    return List.generate(values.length, (i) {
      return {'value': values[i], 'last': i == values.length - 1};
    });
  }

  /// Prepares a list of properties for use in a template
  List<Map<String, dynamic>> _preparePropertiesForTemplate(
    List<VocabularyProperty> properties,
    String prefix,
    String classNamespace,
    Map<String, String> customMappings,
  ) {
    return properties.map((property) {
      final propertyName = _getPropertyName(
        property,
        classNamespace,
        customMappings,
      );
      final externalPrefix = _getPropertyPrefix(
        property,
        classNamespace,
        customMappings,
      );
      return {
        'localName': property.localName,
        'iri': property.iri,
        'dartName': propertyName,
        'comment': _formatDartDocComment(property.comment),
        'vocabPrefix': prefix.toLowerCase(),
        'domainDescription': _getDomainDescription(property, classNamespace),
        'domains': property.domains,
        'ranges': _toMustacheList(property.ranges),
        'hasRanges': property.ranges.isNotEmpty,
        'seeAlso': property.seeAlso,
        'hasSeeAlso': property.seeAlso.isNotEmpty,
        'externalPrefix': externalPrefix,
      };
    }).toList();
  }

  /// Validates that the model contains at least some terms (classes, properties, datatypes, or other terms).
  /// Throws an exception if the model is empty.
  void _validateModelHasTerms(VocabularyModel model) {
    final hasTerms =
        model.classes.isNotEmpty ||
        model.properties.isNotEmpty ||
        model.datatypes.isNotEmpty ||
        model.otherTerms.isNotEmpty;

    if (!hasTerms) {
      throw StateError(
        'No terms found for vocabulary: ${model.name} (${model.namespace}). '
        'The vocabulary source may be inaccessible or incorrectly formatted.',
      );
    }
  }

  /// Extracts a human-readable name from an IRI
  String _extractReadableNameFromIri(String iri) {
    // Try to extract the name after the last # or /
    final hashIndex = iri.lastIndexOf('#');
    if (hashIndex != -1 && hashIndex < iri.length - 1) {
      return iri.substring(hashIndex + 1);
    }

    final slashIndex = iri.lastIndexOf('/');
    if (slashIndex != -1 && slashIndex < iri.length - 1) {
      return iri.substring(slashIndex + 1);
    }

    // Fallback to the full IRI
    return iri;
  }

  /// Gets a property name with prefix if it comes from a different namespace
  String _getPropertyName(
    VocabularyTerm term,
    String? classNamespace,
    Map<String, String> customMappings,
  ) {
    final dartName = _dartIdentifier(term.localName);
    final propertyPrefix = _getPropertyPrefix(
      term,
      classNamespace,
      customMappings,
    );
    // If classNamespace is null, we're generating the main class (no prefix needed)
    return propertyPrefix == null
        ? dartName
        : '${propertyPrefix}${_capitalize(dartName)}';
  }

  String? _getPropertyPrefix(
    VocabularyTerm term,
    String? classNamespace,
    Map<String, String> customMappings,
  ) {
    // If classNamespace is null, we're generating the main class (no prefix needed)
    if (classNamespace == null) return null;

    // If the property belongs to a different namespace than the class,
    // prefix it to avoid naming conflicts
    if (!term.iri.startsWith(classNamespace)) {
      // Extract the namespace from the IRI
      final namespace = _extractNamespace(term.iri);
      if (namespace != null && namespace != classNamespace) {
        final (prefix, generated) = _namespaceMappings.getOrGeneratePrefix(
          namespace,
          customMappings: customMappings,
        );
        if (generated) {
          customMappings[prefix] = namespace;
        }
        return prefix;
      }
    }

    return null;
  }

  /// Extracts the namespace from an IRI
  String? _extractNamespace(String iri) {
    // First try to extract namespace ending with a hash
    var hashIndex = iri.lastIndexOf('#');
    if (hashIndex >= 0) {
      return iri.substring(0, hashIndex + 1);
    }

    // Then try to extract namespace ending with a slash
    var lastSlashIndex = iri.lastIndexOf('/');
    if (lastSlashIndex >= 0) {
      var beforeLastSlashIndex = iri
          .substring(0, lastSlashIndex)
          .lastIndexOf('/');
      if (beforeLastSlashIndex >= 0) {
        return iri.substring(0, lastSlashIndex + 1);
      }
    }

    return null;
  }

  /// Provides documentation about property domain applicability
  String _getDomainDescription(
    VocabularyProperty property,
    String? classNamespace,
  ) {
    if (property.domains.isNotEmpty) {
      return "Can be used on: ${property.domains.join(', ')}";
    }

    // For properties without explicit domains but in the same vocabulary
    return "Can be used on all classes in this vocabulary";
  }

  /// Converts a local name to a valid Dart identifier.
  String _dartIdentifier(String localName) {
    // Special case handling for names that would result in invalid Dart identifiers
    if (localName.startsWith('_')) {
      return 'underscore${localName.substring(1)}';
    }

    if (localName.startsWith(RegExp(r'\d'))) {
      return 'n$localName';
    }

    // Replace characters that are not valid in Dart identifiers
    return localName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  /// Capitalizes the first letter of a string.
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Formats a potentially multiline comment for Dart documentation.
  /// Each line will be properly prefixed with /// for Dart doc comments.
  String _formatDartDocComment(String? comment) {
    if (comment == null || comment.isEmpty) {
      return '';
    }

    // Split the comment into lines
    var lines = comment.split('\n');

    // Replace all instances of [[ and ]] in comments to avoid dartdoc interpreting them as references
    lines =
        lines
            .map((line) => line.replaceAll('[[', '{[').replaceAll(']]', ']}'))
            .toList();

    // Format each line with the Dart doc prefix
    return lines.map((line) => line.trim()).join('\n/// ');
  }
}
