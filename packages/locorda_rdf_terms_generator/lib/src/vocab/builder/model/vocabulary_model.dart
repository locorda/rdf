// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_terms_generator/src/vocab/builder/vocabulary_source.dart';

const _rdfsClass = const IriTerm('http://www.w3.org/2000/01/rdf-schema#Class');
const _rdfProperty = const IriTerm(
  'http://www.w3.org/1999/02/22-rdf-syntax-ns#Property',
);
const _rdfsResource = const IriTerm(
  'http://www.w3.org/2000/01/rdf-schema#Resource',
);
const _rdfsSubClassOf = const IriTerm(
  'http://www.w3.org/2000/01/rdf-schema#subClassOf',
);
const _owlClass = const IriTerm('http://www.w3.org/2002/07/owl#Class');
const _owlThing = const IriTerm('http://www.w3.org/2002/07/owl#Thing');
const _rdfType = const IriTerm(
  'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
);

/// Represents a parsed RDF vocabulary in an intermediate format.
///
/// This model serves as a bridge between the parsed RDF graph and the
/// generated Dart code, providing a structured representation of the
/// vocabulary terms and their properties.
class VocabularyModel {
  /// The name of the vocabulary (e.g., 'rdf', 'xsd')
  final String name;

  /// The namespace IRI of this vocabulary
  final String namespace;

  /// The preferred prefix for this vocabulary
  final String prefix;

  /// Classes defined in this vocabulary
  final List<VocabularyClass> classes;

  /// Properties defined in this vocabulary
  final List<VocabularyProperty> properties;

  /// Datatypes defined in this vocabulary
  final List<VocabularyDatatype> datatypes;

  /// Other terms that don't fit into the above categories
  final List<VocabularyTerm> otherTerms;

  final VocabularySource source;

  /// Creates a new vocabulary model.
  const VocabularyModel({
    required this.name,
    required this.namespace,
    required this.prefix,
    required this.classes,
    required this.properties,
    required this.datatypes,
    required this.otherTerms,
    required this.source,
  });
}

/// Base class for vocabulary terms.
class VocabularyTerm {
  /// The local name of the term (e.g., 'type', 'Class')
  final String localName;

  /// The full IRI of the term
  final String iri;

  /// Human-readable label for the term
  final String? label;

  /// Human-readable description of the term
  final String? comment;

  /// Related resources referenced via rdfs:seeAlso
  final List<String> seeAlso;

  /// Creates a new vocabulary term.
  const VocabularyTerm({
    required this.localName,
    required this.iri,
    this.label,
    this.comment,
    this.seeAlso = const [],
  });
}

/// Represents a class defined in a vocabulary.
class VocabularyClass extends VocabularyTerm {
  /// Parent classes (superclasses) of this class
  final List<String> superClasses;

  /// Equivalent classes of this class (owl:equivalentClass)
  late List<String> equivalentClasses;

  /// Creates a new vocabulary class.
  VocabularyClass({
    required super.localName,
    required super.iri,
    super.label,
    super.comment,
    super.seeAlso,
    this.superClasses = const [],
    List<String> equivalentClasses = const [],
  }) {
    this.equivalentClasses = cleanupEquivalentClasses(equivalentClasses, iri);
    assert(
      localName.isNotEmpty && localName[0].toUpperCase() == localName[0],
      'Class localName must start with an uppercase letter: $localName',
    );
    assert(
      iri.split(RegExp(r'[/#]')).last.isNotEmpty &&
          iri.split(RegExp(r'[/#]')).last[0].toUpperCase() ==
              iri.split(RegExp(r'[/#]')).last[0],
      'The last part of the IRI must start with an uppercase letter: $iri',
    );
  }

  static List<String> cleanupEquivalentClasses(
    List<String> equivalentClasses,
    String iri,
  ) {
    // Remove duplicates and most importantly, remove the IRI and its http(s) variant
    final uniqueClassesSet = equivalentClasses.toSet();
    uniqueClassesSet.remove(iri);
    if (iri.startsWith("https://")) {
      uniqueClassesSet.remove(iri.replaceFirst("https://", "http://"));
    } else if (iri.startsWith("http://")) {
      uniqueClassesSet.remove(iri.replaceFirst("http://", "https://"));
    }
    final uniqueClasses = uniqueClassesSet.toList();
    uniqueClasses.sort();
    return uniqueClasses;
  }
}

/// Represents a property defined in a vocabulary.
class VocabularyProperty extends VocabularyTerm {
  /// The domain (subject class) of this property
  final List<String> domains;

  /// The range (object class or datatype) of this property
  final List<String> ranges;

  /// Creates a new vocabulary property.
  const VocabularyProperty({
    required super.localName,
    required super.iri,
    super.label,
    super.comment,
    super.seeAlso,
    this.domains = const [],
    this.ranges = const [],
  });
}

/// Represents a datatype defined in a vocabulary.
class VocabularyDatatype extends VocabularyTerm {
  /// Creates a new vocabulary datatype.
  const VocabularyDatatype({
    required super.localName,
    required super.iri,
    super.label,
    super.comment,
    super.seeAlso,
  });
}

/// Utility for extracting vocabulary models from RDF graphs.
class VocabularyModelExtractor {
  // URIs that should be excluded from generation
  static final _excludedUriPatterns = [
    RegExp(r'#$'), // IRIs ending with just a hash
    RegExp(r'/$'), // IRIs ending with just a slash
    RegExp(r'[\-#]\d+$'), // IRIs ending with dash or hash followed by numbers
    RegExp(r'xml-syntax'), // XML-Syntax-related IRIs, but allow rdf-syntax
  ];

  /// Extracts a vocabulary model from an RDF graph.
  ///
  /// [graph] The RDF graph containing the vocabulary definition
  /// [namespace] The namespace IRI of the vocabulary
  /// [name] The name to use for the vocabulary
  static VocabularyModel extractFrom(
    RdfGraph graph,
    String namespace,
    String name,
    VocabularySource source,
  ) {
    final prefix = _determinePrefix(name);

    final classes = <VocabularyClass>[];
    final properties = <VocabularyProperty>[];
    final datatypes = <VocabularyDatatype>[];
    final otherTerms = <VocabularyTerm>[];

    // Find all resources in the vocabulary namespace
    final vocabResources = _findVocabularyResources(graph, namespace);

    for (final resource in vocabResources) {
      try {
        final iri = resource.value;

        // Skip excluded URIs that are not actual vocabulary terms
        if (_shouldExcludeUri(iri)) {
          log.fine('Skipping excluded URI: $iri');
          continue;
        }

        final localName = _extractLocalName(iri, namespace);

        // Skip if the local name is invalid or couldn't be sanitized properly
        if (localName.isEmpty || !_isValidDartIdentifier(localName)) {
          log.warning('Skipping invalid identifier: $localName from $iri');
          continue;
        }

        final label = _findLabel(graph, resource);
        final comment = _findComment(graph, resource);
        final rdfsClass = _isRdfsClass(graph, resource);
        final owlClass = _isOwlClass(graph, resource);
        if (rdfsClass || owlClass) {
          classes.add(
            VocabularyClass(
              localName: localName,
              iri: iri,
              label: label,
              comment: comment,
              seeAlso: _findSeeAlso(graph, resource),
              superClasses:
                  {
                    // owl:Class implies rdfs:Class
                    _rdfsResource.value,
                    if (owlClass) _owlThing.value,
                    ..._findSuperClasses(graph, resource),
                  }.toList(),
              equivalentClasses: _findEquivalentClasses(graph, resource),
            ),
          );
        } else if (_isProperty(graph, resource)) {
          properties.add(
            VocabularyProperty(
              localName: localName,
              iri: iri,
              label: label,
              comment: comment,
              seeAlso: _findSeeAlso(graph, resource),
              domains: _findDomains(graph, resource),
              ranges: _findRanges(graph, resource),
            ),
          );
        } else if (_isDatatype(graph, resource)) {
          datatypes.add(
            VocabularyDatatype(
              localName: localName,
              iri: iri,
              label: label,
              comment: comment,
              seeAlso: _findSeeAlso(graph, resource),
            ),
          );
        } else {
          // If we can't determine the type, add it as an "other" term
          otherTerms.add(
            VocabularyTerm(
              localName: localName,
              iri: iri,
              label: label,
              comment: comment,
              seeAlso: _findSeeAlso(graph, resource),
            ),
          );
        }
      } catch (e, stackTrace) {
        log.warning('Error processing resource $resource: $e\n$stackTrace');
      }
    }

    return VocabularyModel(
      name: name,
      namespace: namespace,
      prefix: prefix,
      classes: classes,
      properties: properties,
      datatypes: datatypes,
      otherTerms: otherTerms,
      source: source,
    );
  }

  /// Finds all resources that are part of the vocabulary namespace.
  static List<IriTerm> _findVocabularyResources(
    RdfGraph graph,
    String namespace,
  ) {
    final resources = <IriTerm>{};

    // Find resources as subjects
    for (final triple in graph.triples) {
      if (triple.subject is IriTerm) {
        final subject = triple.subject as IriTerm;
        if (subject.value.startsWith(namespace)) {
          resources.add(subject);
        }
      }
    }

    // Find resources as predicates
    for (final triple in graph.triples) {
      IriTerm predicate = triple.predicate as IriTerm;
      if (predicate.value.startsWith(namespace)) {
        resources.add(predicate);
      }
    }

    // Find resources as objects
    for (final triple in graph.triples) {
      if (triple.object is IriTerm) {
        final object = triple.object as IriTerm;
        if (object.value.startsWith(namespace)) {
          resources.add(object);
        }
      }
    }

    return resources.toList();
  }

  /// Determines if a resource is a class.
  static bool _isRdfsClass(RdfGraph graph, IriTerm resource) {
    // Check if explicitly typed as a class

    if (_isA(graph, resource, _rdfsClass)) {
      return true;
    }

    // Check if resource is used as subject of a rdfs:subClassOf relationship
    // According to RDFS semantics, this implicitly makes it an rdfs:Class
    final subClassOfTriples = graph.findTriples(
      subject: resource,
      predicate: _rdfsSubClassOf,
    );

    if (subClassOfTriples.isNotEmpty) {
      return true;
    }
    // do not do the more expensive check for all subclasses of rdfs:Class
    // if we know it is a property
    if (_isA(graph, resource, _rdfProperty)) {
      return false;
    }

    if (_isSubtypeOf(graph, resource, _rdfsClass)) {
      return true;
    }
    return false;
  }

  static bool _isOwlClass(RdfGraph graph, IriTerm resource) {
    // Check if explicitly typed as a class

    return _isA(graph, resource, _owlClass);
  }

  static bool _isA(RdfGraph graph, IriTerm resource, IriTerm type) {
    // Check if explicitly typed as a class

    final typeTriples = graph.findTriples(
      subject: resource,
      predicate: _rdfType,
      object: type,
    );

    if (typeTriples.isNotEmpty) {
      return true;
    }

    return false;
  }

  /// Determines if a resource is a subtype of a given type - not a subclass!
  /// Meaning for example that a resource is typed not as a class directly, but
  /// as something which is a subclass of a class. For example, if a resource is typed as a
  /// rdfs:Datatype and not as a rdfs:Class, we still want to treat it as a class.
  ///
  static bool _isSubtypeOf(RdfGraph graph, IriTerm resource, IriTerm type) {
    // Check if explicitly typed as a class
    if (_isA(graph, resource, type)) {
      return true;
    }
    var subclassesOfType =
        graph
            .findTriples(predicate: _rdfsSubClassOf, object: type)
            .map((triple) => triple.subject)
            .whereType<IriTerm>()
            .toList();
    for (var subtype in subclassesOfType) {
      if (_isSubtypeOf(graph, resource, subtype)) {
        return true;
      }
    }
    return false;
  }

  /// Determines if a resource is a property.
  static bool _isProperty(RdfGraph graph, IriTerm resource) {
    const propertyTypes = [
      const IriTerm('http://www.w3.org/1999/02/22-rdf-syntax-ns#Property'),
      const IriTerm('http://www.w3.org/2002/07/owl#ObjectProperty'),
      const IriTerm('http://www.w3.org/2002/07/owl#DatatypeProperty'),
      const IriTerm('http://www.w3.org/2002/07/owl#AnnotationProperty'),
    ];

    for (final propertyType in propertyTypes) {
      final typeTriples = graph.findTriples(
        subject: resource,
        predicate: const IriTerm(
          'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
        ),
        object: propertyType,
      );

      if (typeTriples.isNotEmpty) {
        return true;
      }
    }

    // Check if it's used as a predicate in the graph
    for (final triple in graph.triples) {
      if (triple.predicate == resource) {
        return true;
      }
    }

    return false;
  }

  /// Determines if a resource is a datatype.
  static bool _isDatatype(RdfGraph graph, IriTerm resource) {
    final typeTriples = graph.findTriples(
      subject: resource,
      predicate: const IriTerm(
        'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
      ),
      object: const IriTerm('http://www.w3.org/2000/01/rdf-schema#Datatype'),
    );

    return typeTriples.isNotEmpty;
  }

  /// Finds the label of a resource.
  static String? _findLabel(RdfGraph graph, IriTerm resource) {
    final labelTriples = graph.findTriples(
      subject: resource,
      predicate: const IriTerm('http://www.w3.org/2000/01/rdf-schema#label'),
    );

    if (labelTriples.isNotEmpty) {
      final label = labelTriples.first.object;
      if (label is LiteralTerm) {
        return label.value;
      }
    }

    return null;
  }

  /// Finds the comment of a resource.
  static String? _findComment(RdfGraph graph, IriTerm resource) {
    final commentTriples = graph.findTriples(
      subject: resource,
      predicate: const IriTerm('http://www.w3.org/2000/01/rdf-schema#comment'),
    );

    if (commentTriples.isNotEmpty) {
      final comment = commentTriples.first.object;
      if (comment is LiteralTerm) {
        return comment.value;
      }
    }

    return null;
  }

  /// Finds the superclasses of a class.
  static List<String> _findSuperClasses(RdfGraph graph, IriTerm resource) {
    final superClassTriples = graph.findTriples(
      subject: resource,
      predicate: const IriTerm(
        'http://www.w3.org/2000/01/rdf-schema#subClassOf',
      ),
    );

    return superClassTriples
        .where((triple) => triple.object is IriTerm)
        .map((triple) => (triple.object as IriTerm).value)
        .toList();
  }

  /// Finds the equivalent classes of a class.
  static List<String> _findEquivalentClasses(RdfGraph graph, IriTerm resource) {
    // Look for subject equivalentClass object triples
    final equivalentClassTriples = graph.findTriples(
      subject: resource,
      predicate: const IriTerm('http://www.w3.org/2002/07/owl#equivalentClass'),
    );

    // Also look for object equivalentClass subject triples (equivalentClass is symmetric)
    final reverseEquivalentClassTriples = graph.findTriples(
      object: resource,
      predicate: const IriTerm('http://www.w3.org/2002/07/owl#equivalentClass'),
    );

    final result = <String>[];

    // Add forward equivalentClass relationships
    result.addAll(
      equivalentClassTriples
          .where((triple) => triple.object is IriTerm)
          .map((triple) => (triple.object as IriTerm).value),
    );

    // Add reverse equivalentClass relationships (where this class is the object)
    result.addAll(
      reverseEquivalentClassTriples
          .where((triple) => triple.subject is IriTerm)
          .map((triple) => (triple.subject as IriTerm).value),
    );

    return result;
  }

  /// Finds the domains of a property.
  static List<String> _findDomains(RdfGraph graph, IriTerm resource) {
    // Standard rdfs:domain
    final domainTriples = graph.findTriples(
      subject: resource,
      predicate: const IriTerm('http://www.w3.org/2000/01/rdf-schema#domain'),
    );

    // Schema.org http domainIncludes
    final schemaOrgHttpDomainTriples = graph.findTriples(
      subject: resource,
      predicate: const IriTerm('http://schema.org/domainIncludes'),
    );
    final schemaOrgDomainTriples = graph.findTriples(
      subject: resource,
      predicate: const IriTerm('https://schema.org/domainIncludes'),
    );

    final domains = [
      ...domainTriples
          .where((triple) => triple.object is IriTerm)
          .map((triple) => (triple.object as IriTerm).value),
      ...schemaOrgDomainTriples
          .where((triple) => triple.object is IriTerm)
          .map((triple) => (triple.object as IriTerm).value),
      ...schemaOrgHttpDomainTriples
          .where((triple) => triple.object is IriTerm)
          .map((triple) => (triple.object as IriTerm).value),
    ];

    return domains;
  }

  /// Finds the ranges of a property.
  static List<String> _findRanges(RdfGraph graph, IriTerm resource) {
    // Standard rdfs:range
    final rangeTriples = graph.findTriples(
      subject: resource,
      predicate: const IriTerm('http://www.w3.org/2000/01/rdf-schema#range'),
    );

    // Schema.org rangeIncludes
    final schemaOrgRangeTriples = graph.findTriples(
      subject: resource,
      predicate: const IriTerm('https://schema.org/rangeIncludes'),
    );
    // Schema.org http rangeIncludes
    final schemaOrgHttpRangeTriples = graph.findTriples(
      subject: resource,
      predicate: const IriTerm('http://schema.org/rangeIncludes'),
    );

    final ranges = [
      ...rangeTriples
          .where((triple) => triple.object is IriTerm)
          .map((triple) => (triple.object as IriTerm).value),
      ...schemaOrgRangeTriples
          .where((triple) => triple.object is IriTerm)
          .map((triple) => (triple.object as IriTerm).value),
      ...schemaOrgHttpRangeTriples
          .where((triple) => triple.object is IriTerm)
          .map((triple) => (triple.object as IriTerm).value),
    ];

    return ranges;
  }

  /// Finds all rdfs:seeAlso references for a resource.
  static List<String> _findSeeAlso(RdfGraph graph, IriTerm resource) {
    final seeAlsoTriples = graph.findTriples(
      subject: resource,
      predicate: const IriTerm('http://www.w3.org/2000/01/rdf-schema#seeAlso'),
    );

    return seeAlsoTriples
        .where((triple) => triple.object is IriTerm)
        .map((triple) => (triple.object as IriTerm).value)
        .toList();
  }

  /// Extracts the local name from an IRI and sanitizes it for use as a Dart identifier.
  static String _extractLocalName(String iri, String namespace) {
    String rawLocalName;

    if (iri.startsWith(namespace)) {
      rawLocalName = iri.substring(namespace.length);
      // If there's a hash or slash at the end of the namespace, it's already separated
      if (rawLocalName.isNotEmpty) {
        return _sanitizeDartIdentifier(rawLocalName);
      }
    }

    // Fallback: extract the last segment after # or /
    final hashIndex = iri.lastIndexOf('#');
    if (hashIndex != -1 && hashIndex < iri.length - 1) {
      rawLocalName = iri.substring(hashIndex + 1);
      return _sanitizeDartIdentifier(rawLocalName);
    }

    final slashIndex = iri.lastIndexOf('/');
    if (slashIndex != -1 && slashIndex < iri.length - 1) {
      rawLocalName = iri.substring(slashIndex + 1);
      return _sanitizeDartIdentifier(rawLocalName);
    }

    // Couldn't determine a reasonable local name
    log.warning('Could not extract local name from IRI: $iri');
    return '';
  }

  /// Sanitizes a string to be a valid Dart identifier.
  static String _sanitizeDartIdentifier(String input) {
    if (input.isEmpty) return '';

    // Replace disallowed characters with underscores
    var sanitized = input.replaceAll(RegExp(r'[^\w$]'), '_');

    // Ensure the first character is valid (not a number or underscore)
    if (sanitized.startsWith(RegExp(r'[0-9]'))) {
      sanitized = 'n$sanitized';
    }

    // Make sure it's not a reserved word
    if (_reservedWords.contains(sanitized)) {
      sanitized = '${sanitized}_';
    }

    return sanitized;
  }

  /// Checks if a string is a valid Dart identifier
  static bool _isValidDartIdentifier(String identifier) {
    return identifier.isNotEmpty &&
        !_reservedWords.contains(identifier) &&
        RegExp(r'^[a-zA-Z$][a-zA-Z0-9_$]*$').hasMatch(identifier);
  }

  /// Determines if a URI should be excluded from generation
  static bool _shouldExcludeUri(String uri) {
    // Check against the list of exclusion patterns
    for (final pattern in _excludedUriPatterns) {
      if (pattern.hasMatch(uri)) return true;
    }

    return false;
  }

  /// Determines the preferred prefix for a vocabulary name.
  ///
  /// Preserves the original casing to allow for proper naming convention conversions.
  static String _determinePrefix(String name) {
    switch (name.toLowerCase()) {
      case 'dcterms':
        return 'dcterms';
      default:
        return name; // Return original name, not toLowerCase()
    }
  }

  /// Dart reserved words that can't be used as identifiers
  static const _reservedWords = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'Function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'while',
    'with',
    'yield',
  };
}
