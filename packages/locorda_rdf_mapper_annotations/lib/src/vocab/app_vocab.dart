/// Defines the AppVocab annotation for marking a Dart library as an RDF vocabulary root.
///
/// This annotation is used to indicate that a Dart library defines an RDF vocabulary.
/// It is intended for use on library-level elements only.
///
/// Example:
///   @AppVocab(
///     iri: 'http://example.org/vocab#',
///     prefix: 'ex',
///     label: 'Example Vocabulary',
///     comment: 'A demo vocabulary for testing.'
///   )
///   library example_vocab;
///
/// All fields are required and must be compile-time constants.
///
/// - [iri]: The base IRI of the vocabulary (must end with '#' or '/').
/// - [prefix]: The recommended short prefix for the vocabulary (e.g., 'ex').
/// - [label]: A human-readable label for the vocabulary.
/// - [comment]: A human-readable comment or description.
///
/// This annotation is processed by the vocab builder to generate Turtle/OWL output.
class AppVocab {
  /// The base IRI of the vocabulary (must end with '#' or '/').
  final String iri;

  /// The recommended short prefix for the vocabulary (e.g., 'ex').
  final String prefix;

  /// A human-readable label for the vocabulary.
  final String label;

  /// A human-readable comment or description.
  final String comment;

  /// Creates an [AppVocab] annotation.
  const AppVocab({
    required this.iri,
    required this.prefix,
    required this.label,
    required this.comment,
  });
}
