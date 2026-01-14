// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:locorda_rdf_core/core.dart';

import 'model/vocabulary_model.dart';

/// Logger for cross-vocabulary operations

/// Manages the global class hierarchy and property applicability across vocabulary boundaries.
///
/// This resolver is responsible for tracking class inheritance and property domains
/// when vocabularies reference each other. It ensures that classes correctly
/// inherit properties from their superclasses, even when those superclasses
/// are defined in different vocabularies.
class CrossVocabularyResolver {
  /// Map of class IRIs to their direct superclass IRIs
  final Map<String, Set<String>> _directSuperClasses = {};

  /// Map of class IRIs to their direct equivalent class IRIs
  final Map<String, Set<String>> _directEquivalentClasses = {};

  /// Map of class IRIs to their full set of superclass IRIs (transitive closure)
  final Map<String, Set<String>> _allSuperClasses = {};

  /// Map of class IRIs to their full set of equivalent class IRIs (transitive closure)
  final Map<String, Set<String>> _allEquivalentClasses = {};

  /// Map of property IRIs to their domain IRIs
  final Map<String, Set<String>> _propertyDomains = {};

  /// Map of vocabulary namespaces to their properties
  final Map<String, Set<VocabularyProperty>> _vocabularyProperties = {};

  /// Map of vocabulary names to their models
  final Map<String, VocabularyModel> _vocabularyModels = {};

  /// Set of namespace IRIs that have been registered
  final Set<String> _registeredNamespaces = {};

  /// Set of namespace IRIs that are implied by references but not explicitly registered
  final Set<String> _pendingNamespaces = {};

  /// Cache of resolved external properties by class IRI
  final Map<String, List<VocabularyProperty>> _externalPropertyCache = {};

  final RdfNamespaceMappings _namespaceMappings;
  final Map<String, String> _customNamespaceMappings = {};

  /// Function to load an implied vocabulary model if available
  final Future<VocabularyModel?> Function(String namespace, String name)
  _vocabularyLoader;

  /// Creates a new cross-vocabulary resolver.
  ///
  /// [vocabularyLoader] Optional function to load implied vocabulary models
  CrossVocabularyResolver({
    required Future<VocabularyModel?> Function(String namespace, String name)
    vocabularyLoader,
    RdfNamespaceMappings namespaceMappings = const RdfNamespaceMappings(),
  }) : _vocabularyLoader = vocabularyLoader,
       _namespaceMappings = namespaceMappings;

  /// Determines a name for a vocabulary namespace
  ///
  /// [namespace] The namespace URI to get a name for
  String _determineVocabularyName(String namespace) {
    final (prefix, generated) = _namespaceMappings.getOrGeneratePrefix(
      namespace,
      customMappings: _customNamespaceMappings,
    );
    if (generated) {
      _customNamespaceMappings[namespace] = prefix;
    }
    return prefix;
  }

  /// Registers a vocabulary model with the resolver.
  ///
  /// This method processes the class hierarchy and property domains
  /// from the provided vocabulary model and integrates them into
  /// the global resolution context.
  void registerVocabulary(VocabularyModel model) {
    log.info('Registering vocabulary: ${model.name} (${model.namespace})');

    // Store the vocabulary model
    _vocabularyModels[model.name] = model;
    _registeredNamespaces.add(model.namespace);
    _customNamespaceMappings[model.namespace] = model.prefix;

    // Register classes, their superclasses and equivalent classes
    for (final rdfClass in model.classes) {
      final classIri = rdfClass.iri;

      // Register direct superclasses and track potential external vocabularies
      if (rdfClass.superClasses.isNotEmpty) {
        _directSuperClasses[classIri] = Set.from(rdfClass.superClasses);

        // Check for superclasses from other vocabularies
        for (final superClass in rdfClass.superClasses) {
          final superNamespace = _extractNamespace(superClass);
          if (superNamespace != null &&
              superNamespace != model.namespace &&
              !_registeredNamespaces.contains(superNamespace)) {
            _pendingNamespaces.add(superNamespace);
            log.info('Found reference to external vocabulary: $superNamespace');
          }
        }
      } else {
        _directSuperClasses[classIri] = {};
      }

      // Register equivalent classes
      if (rdfClass.equivalentClasses.isNotEmpty) {
        _directEquivalentClasses[classIri] = Set.from(
          rdfClass.equivalentClasses,
        );

        // Check for equivalent classes from other vocabularies
        for (final equivClass in rdfClass.equivalentClasses) {
          final equivNamespace = _extractNamespace(equivClass);
          if (equivNamespace != null &&
              equivNamespace != model.namespace &&
              !_registeredNamespaces.contains(equivNamespace)) {
            _pendingNamespaces.add(equivNamespace);
            log.info(
              'Found reference to external vocabulary through equivalentClass: $equivNamespace',
            );
          }
        }
      }
    }

    // Register properties and their domains
    final vocabProperties = <VocabularyProperty>{};
    for (final property in model.properties) {
      vocabProperties.add(property);

      if (property.domains.isNotEmpty) {
        _propertyDomains[property.iri] = Set.from(property.domains);

        // Check for domains from other vocabularies
        for (final domain in property.domains) {
          final domainNamespace = _extractNamespace(domain);
          if (domainNamespace != null &&
              domainNamespace != model.namespace &&
              !_registeredNamespaces.contains(domainNamespace)) {
            _pendingNamespaces.add(domainNamespace);
            log.info(
              'Found reference to external vocabulary: $domainNamespace',
            );
          }
        }
      } else {
        // For properties without explicit domains, don't automatically assign to global resources
        // This ensures that namespace-specific predicates stay within their namespace
        _propertyDomains[property.iri] = <String>{};

        log.fine(
          'Property ${property.iri} has no explicit domain, ' +
              'will only be available within ${model.name} vocabulary',
        );
      }
    }

    if (vocabProperties.isNotEmpty) {
      _vocabularyProperties[model.namespace] = vocabProperties;
    }

    // Clear caches as the hierarchy has changed
    _externalPropertyCache.clear();

    // Rebuild the transitive closure of the class hierarchy
    _rebuildClassHierarchy();
  }

  /// Extracts the namespace from an IRI
  String? _extractNamespace(String iri) {
    // Try to extract namespace by finding the last # or / character
    final hashIndex = iri.lastIndexOf('#');
    if (hashIndex != -1) {
      return iri.substring(0, hashIndex + 1);
    }

    final slashIndex = iri.lastIndexOf('/');
    if (slashIndex != -1) {
      return iri.substring(0, slashIndex + 1);
    }

    return null;
  }

  /// Attempts to load any pending vocabularies that were referenced but not registered
  Future<void> loadPendingVocabularies() async {
    if (_pendingNamespaces.isEmpty) {
      return;
    }

    log.info(
      'Attempting to load ${_pendingNamespaces.length} pending vocabularies',
    );

    // Process only the current pending namespaces (as loading might add more)
    final namespacesToProcess = Set<String>.from(_pendingNamespaces);
    _pendingNamespaces.clear();

    for (final namespace in namespacesToProcess) {
      if (_registeredNamespaces.contains(namespace)) {
        continue; // Already registered while processing this loop
      }

      // Determine the vocabulary name
      final name = _determineVocabularyName(namespace);

      log.info(
        'Attempting to load vocabulary "$name" from namespace $namespace',
      );

      // Try to load the vocabulary
      final model = await _vocabularyLoader(namespace, name);

      // Null can be returned if the vocabulary is deliberately skipped or cannot be loaded
      if (model != null) {
        registerVocabulary(model);
      } else {
        log.warning(
          'Skipped or failed to load implied vocabulary from namespace: $namespace',
        );
      }
    }

    // If new pending namespaces were discovered during loading, process them too
    if (_pendingNamespaces.isNotEmpty) {
      await loadPendingVocabularies();
    }
  }

  /// Rebuilds the transitive closure of the class hierarchy.
  void _rebuildClassHierarchy() {
    log.fine('Rebuilding class hierarchy');
    _allSuperClasses.clear();
    _allEquivalentClasses.clear();

    // First, build the equivalence relationships (transitive closure)
    for (final entry in _directEquivalentClasses.entries) {
      final classIri = entry.key;
      final equivalentClasses = entry.value;

      // Initialize equivalent classes set
      if (!_allEquivalentClasses.containsKey(classIri)) {
        _allEquivalentClasses[classIri] = <String>{};
      }

      // Add direct equivalent classes
      _allEquivalentClasses[classIri]!.addAll(
        otherExceptSchemeChanges(
          _allEquivalentClasses[classIri]!,
          equivalentClasses,
        ),
      );

      // Make sure equivalent classes have reciprocal relationships
      for (final equivClass in equivalentClasses) {
        if (!_allEquivalentClasses.containsKey(equivClass)) {
          _allEquivalentClasses[equivClass] = <String>{};
        }

        // Add the original class as equivalent to the equivalent class (symmetric relationship)
        _allEquivalentClasses[equivClass]!.addAll(
          otherExceptSchemeChanges(_allEquivalentClasses[equivClass]!, {
            classIri,
          }),
        );
      }
    }

    // Initialize with direct superclasses
    for (final entry in _directSuperClasses.entries) {
      _allSuperClasses[entry.key] = Set.from(entry.value);
    }

    // Compute transitive closure for equivalence and inheritance relationships together
    bool changed;
    do {
      changed = false;

      // First compute equivalent classes transitivity
      for (final classIri in _allEquivalentClasses.keys.toList()) {
        final currentEquivClasses = Set<String>.from(
          _allEquivalentClasses[classIri] ?? {},
        );
        final newEquivClasses = Set<String>.from(currentEquivClasses);

        // Add equivalent classes of equivalent classes
        for (final equivClass in currentEquivClasses.toList()) {
          final transitiveEquivs = _allEquivalentClasses[equivClass] ?? {};
          newEquivClasses.addAll(
            otherExceptSchemeChanges(newEquivClasses, transitiveEquivs),
          );
        }

        // Add equivalent classes of superclasses
        final superClasses = _allSuperClasses[classIri] ?? {};
        for (final superClass in superClasses.toList()) {
          final superClassEquivs = _allEquivalentClasses[superClass] ?? {};
          newEquivClasses.addAll(
            otherExceptSchemeChanges(newEquivClasses, superClassEquivs),
          );
        }

        // If we've added new equivalent classes, update and flag for another iteration
        if (newEquivClasses.length > currentEquivClasses.length) {
          _allEquivalentClasses[classIri] = newEquivClasses;
          changed = true;
        }
      }

      // Then compute superclass transitivity including equivalent classes
      for (final classIri in _allSuperClasses.keys.toList()) {
        final currentSuperClasses = Set<String>.from(
          _allSuperClasses[classIri] ?? {},
        );
        final newSuperClasses = Set<String>.from(currentSuperClasses);

        // Add parent's parents
        for (final parentIri in currentSuperClasses.toList()) {
          final grandparents = _allSuperClasses[parentIri] ?? {};
          newSuperClasses.addAll(
            otherExceptSchemeChanges(newSuperClasses, grandparents),
          );
        }

        // Add superclasses of equivalent classes
        final equivClasses = _allEquivalentClasses[classIri] ?? {};
        for (final equivClass in equivClasses) {
          final equivSuperClasses = _allSuperClasses[equivClass] ?? {};
          newSuperClasses.addAll(
            otherExceptSchemeChanges(newSuperClasses, equivSuperClasses),
          );
        }

        // If we've added new superclasses, update and flag for another iteration
        if (newSuperClasses.length > currentSuperClasses.length) {
          _allSuperClasses[classIri] = newSuperClasses;
          changed = true;
        }
      }
    } while (changed);

    // Remove self-references in equivalent classes
    for (final entry in _allEquivalentClasses.entries) {
      entry.value.remove(entry.key);
    }

    // Remove self-references that may have been introduced
    for (final entry in _allSuperClasses.entries) {
      entry.value.remove(entry.key);
    }

    // Debug output
    for (final entry in _allSuperClasses.entries) {
      log.fine('Class ${entry.key} inherits from: ${entry.value.join(', ')}');
    }

    for (final entry in _allEquivalentClasses.entries) {
      log.fine(
        'Class ${entry.key} is equivalent to: ${entry.value.join(', ')}',
      );
    }

    log.info(
      'Completed class hierarchy computation (total classes: ${_allSuperClasses.length}, ' +
          'with ${_allEquivalentClasses.length} having equivalent classes)',
    );
  }

  /// Gets all applicable properties for a class across all vocabularies.
  ///
  /// This method returns all properties that can be used with the given class,
  /// including those inherited from superclasses, even when those superclasses
  /// are defined in different vocabularies.
  ///
  /// [classIri] The IRI of the class to get properties for
  /// [vocabNamespace] The namespace of the current vocabulary (used to filter properties)
  List<VocabularyProperty> getPropertiesForClass(
    String classIri,
    String vocabNamespace,
  ) {
    final result = <VocabularyProperty>{};

    // Get the full set of classes (this class and all its superclasses)
    final allClassTypes = getAllClassTypes(classIri);

    log.fine('Getting properties for $classIri in namespace $vocabNamespace');
    log.fine('Class hierarchy: ${allClassTypes.join(', ')}');

    // First add properties from this vocabulary namespace
    final vocabProperties = _vocabularyProperties[vocabNamespace] ?? {};
    for (final property in vocabProperties) {
      // Properties from the same namespace with no domains are considered "universal" to that namespace
      if (_propertyDomains[property.iri] == null ||
          _propertyDomains[property.iri]!.isEmpty) {
        result.add(property);
        log.fine(
          'Added universal property ${property.iri} from same namespace',
        );
        continue;
      }

      // Check if any domain of the property is compatible with this class or its superclasses
      final domains = _propertyDomains[property.iri] ?? {};
      for (final domain in domains) {
        if (allClassTypes.contains(domain)) {
          result.add(property);
          log.fine('Added property ${property.iri} due to domain $domain');
          break;
        }
      }
    }

    // Then add properties from external vocabularies that apply to this class
    final externalProperties = _getExternalPropertiesForClass(
      classIri,
      vocabNamespace,
    );
    result.addAll(externalProperties);

    return result.toList();
  }

  /// Gets all class types for a given class, including itself, its superclasses,
  /// equivalent classes, and global resource types.
  Set<String> getAllClassTypes(String classIri) {
    return {
      classIri,
      ...getAllSuperClasses(classIri),
      ...getAllEquivalentClasses(classIri),
      ...getAllEquivalentClassSuperClasses(classIri),
    };
  }

  Set<String> getAllEquivalentClasses(String classIri) {
    var excludeClasses = {classIri, ...getAllSuperClasses(classIri)};
    return otherExceptSchemeChanges(
      excludeClasses,
      _allEquivalentClasses[classIri] ?? const <String>{},
    ).toSet();
  }

  Set<String> getAllSuperClasses(String classIri) {
    final result = <String>{...(_allSuperClasses[classIri] ?? const {})};
    return otherExceptSchemeChanges({classIri}, result).toSet();
  }

  Set<String> getAllEquivalentClassSuperClasses(String classIri) {
    var equivClasses = getAllEquivalentClasses(classIri);
    var excludeClasses = <String>{
      classIri,
      ...getAllSuperClasses(classIri),
      ...equivClasses,
    };
    final result = <String>{};

    // Also include superclasses of equivalent classes
    for (final equivClass in equivClasses) {
      var classesToAdd = otherExceptSchemeChanges(
        excludeClasses,
        _allSuperClasses[equivClass] ?? const {},
      );
      excludeClasses.addAll(classesToAdd);
      result.addAll(classesToAdd);
    }

    return result;
  }

  /// Gets properties from external vocabularies that apply to a given class
  Set<VocabularyProperty> _getExternalPropertiesForClass(
    String classIri,
    String currentNamespace,
  ) {
    // Check cache first
    final cacheKey = '$classIri|$currentNamespace';
    if (_externalPropertyCache.containsKey(cacheKey)) {
      return Set.from(_externalPropertyCache[cacheKey]!);
    }

    final result = <VocabularyProperty>{};

    // Get the full set of classes (this class and all its superclasses)
    final allClassTypes = getAllClassTypes(classIri);

    // Add properties from all other vocabularies
    for (final entry in _vocabularyProperties.entries) {
      final vocabNamespace = entry.key;

      // Skip the current vocabulary namespace
      if (vocabNamespace == currentNamespace) {
        continue;
      }

      final properties = entry.value;
      for (final property in properties) {
        // Only include properties with explicit domains that match this class
        // Properties without explicit domains are kept within their own vocabulary
        if (_propertyDomains[property.iri] == null ||
            _propertyDomains[property.iri]!.isEmpty) {
          continue;
        }

        // Check if any domain of the property is compatible with this class or its superclasses
        final domains = _propertyDomains[property.iri] ?? {};
        for (final domain in domains) {
          if (allClassTypes.contains(domain)) {
            result.add(property);
            log.fine(
              'Added external property ${property.iri} due to domain $domain',
            );
            break;
          }
        }
      }
    }

    // Cache the result
    _externalPropertyCache[cacheKey] = result.toList();
    return result;
  }

  /// Gets all applicable cross-vocabulary properties for a class.
  ///
  /// This method returns properties from other vocabularies (not the source vocabulary)
  /// that can be used with the given class due to inheritance.
  ///
  /// [classIri] The IRI of the class to get properties for
  /// [sourceVocabNamespace] The namespace of the source vocabulary to exclude
  List<VocabularyProperty> getCrossVocabPropertiesForClass(
    String classIri,
    String sourceVocabNamespace,
  ) {
    return _getExternalPropertiesForClass(
      classIri,
      sourceVocabNamespace,
    ).toList();
  }

  /// Gets debug information about a class's inheritance hierarchy
  Map<String, dynamic> getClassInheritanceDebugInfo(String classIri) {
    return {
      'class': classIri,
      'directSuperclasses': _directSuperClasses[classIri]?.toList() ?? [],
      'directEquivalentClasses':
          _directEquivalentClasses[classIri]?.toList() ?? [],
      'allSuperclasses': _allSuperClasses[classIri]?.toList() ?? [],
      'applicablePropertiesByVocabulary':
          _vocabularyProperties.entries
              .map((entry) {
                final namespace = entry.key;
                final properties =
                    entry.value
                        .where((prop) {
                          final domains = _propertyDomains[prop.iri] ?? {};
                          if (domains.isEmpty) return true;

                          final allTypes = getAllClassTypes(classIri);

                          return domains.any(
                            (domain) => allTypes.contains(domain),
                          );
                        })
                        .map((p) => p.iri)
                        .toList();

                return MapEntry(namespace, properties);
              })
              .where((e) => e.value.isNotEmpty)
              .toList(),
    };
  }

  static String _trimHttpsHttpPrefix(String iri) {
    if (iri.startsWith('http://')) {
      return iri.substring(7);
    }
    if (iri.startsWith('https://')) {
      return iri.substring(8);
    }
    return iri;
  }

  //@visibleForTesting
  static Iterable<String> otherExceptSchemeChanges(
    Set<String> classes,
    Set<String> other,
  ) {
    return other.where((superClass) {
      // Exclude scheme changes (e.g., http://example.com/ -> https://example.com/)
      return !classes.any(
        (existing) =>
            _trimHttpsHttpPrefix(existing) == _trimHttpsHttpPrefix(superClass),
      );
    });
  }
}
