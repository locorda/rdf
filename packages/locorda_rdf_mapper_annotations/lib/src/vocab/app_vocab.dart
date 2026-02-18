import 'package:locorda_rdf_core/core.dart';

/// Configuration class for application vocabulary generation.
///
/// This class defines the configuration for generating RDF vocabulary files
/// from annotated Dart classes. It specifies the base URI for the application's
/// vocabulary and the path component to append to generate the full vocabulary IRI.
///
/// The vocabulary IRI is constructed as: `appBaseUri + vocabPath + '#'`
/// For example, with `appBaseUri = 'https://my.app.de'` and `vocabPath = '/vocab'`,
/// the vocabulary IRI would be `https://my.app.de/vocab#`.
///
/// This class is designed to be subclassable, allowing applications to create
/// custom vocabulary configurations that extend or customize the base functionality.
class AppVocab {
  /// The base URI for the application.
  ///
  /// This should be the root URI that identifies your application or organization.
  /// For example: `'https://my.app.de'` or `'https://example.org'`.
  ///
  /// Required parameter.
  final String appBaseUri;

  /// The path component to append to the base URI for vocabulary generation.
  ///
  /// This path is appended to [appBaseUri] to form the vocabulary namespace.
  /// A '#' fragment identifier is automatically appended to create the full
  /// vocabulary IRI.
  ///
  /// Defaults to `'/vocab'`.
  final String vocabPath;

  /// Default base class for generated classes when not explicitly specified via subClassOf.
  /// Defaults to owl:Thing.
  final IriTerm defaultBaseClass;

  /// Well-known properties for auto-matching unannotated fields in define mode.
  /// Maps field fragments to standard property IRIs.
  final Map<String, IriTerm> wellKnownProperties;

  final String? label;
  final String? comment;

  /// Optional metadata for the generated ontology.
  ///
  /// Provides predicate-object pairs for the ontology resource.
  /// Used to enrich the generated Turtle with metadata triples.
  ///
  /// Common keys (using vocabulary term constants):
  /// - `Owl.versionInfo` - Version string
  /// - `Dc.created` - Creation date (ISO 8601)
  /// - `Dc.creator` - Creator/author name
  ///
  /// Values can be [LiteralTerm] or [IriTerm].
  ///
  /// Example:
  /// ```dart
  /// import 'package:locorda_rdf_terms_core/owl.dart';
  /// import 'package:locorda_rdf_terms_core/dc.dart';
  ///
  /// const myVocab = AppVocab(
  ///   appBaseUri: 'https://my.app.de',
  ///   label: 'My App Vocabulary',
  ///   comment: 'A vocabulary for my application',
  ///   metadata: [
  ///     (Owl.versionInfo, LiteralTerm('1.0.0')),
  ///     (Dc.created, LiteralTerm('2025-01-15', datatype: Xsd.date)),
  ///     (Dc.creator, IriTerm('https://my.app.de/team')),
  ///   ]
  /// );
  /// ```
  final List<(IriTerm, RdfObject)> metadata;

  /// Default curated list of well-known properties.
  static const Map<String, IriTerm> defaultWellKnownProperties = {
    'title': IriTerm('http://purl.org/dc/terms/title'),
    'description': IriTerm('http://purl.org/dc/terms/description'),
    'creator': IriTerm('http://purl.org/dc/terms/creator'),
    'created': IriTerm('http://purl.org/dc/terms/created'),
    'modified': IriTerm('http://purl.org/dc/terms/modified'),
    'publisher': IriTerm('http://purl.org/dc/elements/1.1/publisher'),
    'subject': IriTerm('http://purl.org/dc/terms/subject'),
    'name': IriTerm('http://xmlns.com/foaf/0.1/name'),
    'homepage': IriTerm('http://xmlns.com/foaf/0.1/homepage'),
    'email': IriTerm('http://xmlns.com/foaf/0.1/mbox'),
  };

  /// Creates an AppVocab configuration.
  ///
  /// [appBaseUri] is required and specifies the base URI for the application.
  /// [vocabPath] is optional and defaults to `'/vocab'`.
  /// [label] is optional and provides a human-readable label for the ontology.
  /// [comment] is optional and provides a description for the ontology.
  /// [metadata] is optional and defaults to an empty list of records.
  ///
  /// Example:
  /// ```dart
  /// import 'package:locorda_rdf_terms_core/owl.dart';
  /// import 'package:locorda_rdf_terms_core/dc.dart';
  ///
  /// const myVocab = AppVocab(
  ///   appBaseUri: 'https://my.app.de',
  ///   vocabPath: '/vocab',
  ///   label: 'Example Vocabulary',
  ///   comment: 'A vocabulary for example application',
  ///   metadata: [
  ///     (Owl.versionInfo, LiteralTerm('1.0.0')),
  ///     (Dc.created, LiteralTerm('2025-01-15', datatype: Xsd.date)),
  ///   ]
  /// );
  /// ```
  const AppVocab({
    required this.appBaseUri,
    this.vocabPath = '/vocab',
    this.defaultBaseClass =
        const IriTerm('http://www.w3.org/2002/07/owl#Thing'),
    this.wellKnownProperties = defaultWellKnownProperties,
    this.label,
    this.comment,
    this.metadata = const [],
  });
}
