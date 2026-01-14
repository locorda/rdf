/// Example demonstrating global unmapped triples for document-level preservation.
///
/// This example shows how to use `@RdfUnmappedTriples(globalUnmapped: true)` to
/// capture ALL unmapped triples from an entire RDF document, ensuring complete
/// round-trip preservation of complex documents like WebID/Profile documents.
///
/// Key features demonstrated:
/// - Document-level container class with global unmapped triples collection
/// - Generic document class that can wrap any primary topic type
/// - Solid WebID Profile document structure with person data
/// - Complete preservation of document-level metadata and unknown properties
///
/// **Important:** Only use `globalUnmapped: true` on a single top-level document
/// class to avoid duplicate data collection.
library;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_common/foaf.dart';
import 'package:locorda_rdf_terms_common/solid.dart';
import 'package:locorda_rdf_terms_common/pim.dart';

/// Generic document container with global unmapped triples preservation.
///
/// This class represents a FOAF Personal Profile Document that can contain
/// any type of primary topic while preserving all document-level metadata
/// and unknown properties through global unmapped triples collection.
@RdfGlobalResource(FoafPersonalProfileDocument.classIri, IriStrategy(),
    registerGlobally: false)
class Document<T> {
  /// The IRI of the document itself
  @RdfIriPart()
  @RdfProvides()
  final String documentIri;

  /// The main subject/topic of this document
  @RdfProperty(FoafPersonalProfileDocument.primaryTopic,
      contextual: ContextualMapping.namedProvider("primaryTopic"))
  final T primaryTopic;

  /// The agent who created this document
  @RdfProperty(FoafPersonalProfileDocument.maker)
  final Uri maker;

  /// Captures ALL unmapped triples from the entire document graph.
  ///
  /// This includes:
  /// - Document-level metadata not explicitly mapped above
  /// - Triples about other entities in the document
  /// - Unknown properties and extensions
  /// - Complete preservation for round-trip serialization
  @RdfUnmappedTriples(globalUnmapped: true)
  final RdfGraph unmapped;

  Document(
      {required this.documentIri,
      required this.maker,
      required this.primaryTopic,
      required this.unmapped});
}

/// Contextual mapping provider for IRI-relative serialization
const iriRelative =
    ContextualMapping.provider(IriRelativeSerializationProvider);

/// Person class representing the primary topic of a WebID Profile document.
///
/// This class demonstrates standard RDF property mapping without unmapped triples
/// collection, as the global collection is handled at the document level.
/// All person-specific properties are explicitly mapped to maintain type safety.
@RdfGlobalResource(FoafPerson.classIri, IriStrategy("{+documentIri}#me"),
    registerGlobally: false)
class Person {
  /// The person's display name
  @RdfProperty(FoafPerson.name)
  String name;

  /// Reference to the person's preference file (relative IRI)
  @RdfProperty(FoafPerson.pimPreferencesFile, contextual: iriRelative)
  String preferencesFile;

  /// Primary storage location for the person's data
  @RdfProperty(Pim.storage)
  Uri storage;

  /// The person's Solid account (relative IRI)
  @RdfProperty(Solid.account, contextual: iriRelative)
  String account;

  /// OIDC issuer for authentication
  @RdfProperty(Solid.oidcIssuer)
  Uri oidcIssuer;

  /// Private type index file (relative IRI)
  @RdfProperty(Solid.privateTypeIndex, contextual: iriRelative)
  String privateTypeIndex;

  /// Public type index file (relative IRI)
  @RdfProperty(Solid.publicTypeIndex, contextual: iriRelative)
  String publicTypeIndex;

  Person(
      {required this.name,
      required this.preferencesFile,
      required this.storage,
      required this.account,
      required this.oidcIssuer,
      required this.privateTypeIndex,
      required this.publicTypeIndex});
}

/// Example usage demonstrating global unmapped triples preservation:
///
/// ```dart
/// void main() {
///   // Initialize the RDF mapper
///   RdfMapper mapper = initRdfMapper();
///
///   // Create a Person instance with realistic data
///   final person = Person(
///     name: 'Klas Kalass',
///     preferencesFile: '/settings/prefs.ttl',
///     storage: Uri.parse('http://example.org/'),
///     account: '/',
///     oidcIssuer: Uri.parse('https://datapod.igrant.io'),
///     privateTypeIndex: '/settings/privateTypeIndex.ttl',
///     publicTypeIndex: '/settings/publicTypeIndex.ttl',
///   );
///
///   // Create a Document<Person> instance
///   final document = Document<Person>(
///     documentIri: 'http://example.org/card',
///     maker: Uri.parse('http://example.org/me'),
///     primaryTopic: person,
///     unmapped: RdfGraph(),
///   );
///
///   // Serialize to RDF with explicit mapper registration
///   final graph = mapper.encodeObject(document,
///       register: (registry) => registry
///         ..registerMapper(DocumentMapper<Person>(
///           primaryTopic: SerializationProvider.iriContextual((IriTerm iri) =>
///               PersonMapper(documentIriProvider: () => iri.iri)),
///         )));
///
///   // Convert to Turtle format
///   final turtle = graph.toTurtle();
///   print('Generated RDF:');
///   print(turtle);
///
///   // Now test round-trip with additional unmapped data
///   final extendedTurtle = '''
///     ${turtle}
///
///     # Additional document metadata (will be captured in unmapped)
///     <http://example.org/card> <https://example.org/version> "1.2" .
///     <http://example.org/card> <https://example.org/lastModified> "2025-08-13T10:30:00Z" .
///
///     # Additional unrelated entity (will be captured in unmapped)
///     <http://example.org/workOrg> a <http://xmlns.com/foaf/0.1/Organization> ;
///       <http://xmlns.com/foaf/0.1/name> "Example Corp" ;
///       <http://xmlns.com/foaf/0.1/homepage> <https://example.com> .
///   ''';
///
///   // Decode back with global unmapped triples preservation
///   final decodedDocument = mapper.decodeObject<Document<Person>>(
///     RdfGraph.fromTurtle(extendedTurtle),
///     register: (registry) => registry
///       ..registerMapper(DocumentMapper<Person>(
///         primaryTopic: DeserializationProvider.iriContextual((IriTerm iri) =>
///             PersonMapper(documentIriProvider: () => iri.iri)),
///       ))
///   );
///
///   // Verify that mapped properties are preserved
///   print('Person name: ${decodedDocument.primaryTopic.name}');
///   print('Document maker: ${decodedDocument.maker}');
///
///   // Verify that unmapped triples are captured
///   print('Unmapped triples count: ${decodedDocument.unmapped.triples.length}');
///   print('Unmapped triples include document metadata and unrelated entities');
///
///   // Perfect round-trip: encode back with all unmapped data preserved
///   final restoredGraph = mapper.encodeObject(decodedDocument,
///       register: (registry) => registry
///         ..registerMapper(DocumentMapper<Person>(
///           primaryTopic: SerializationProvider.iriContextual((IriTerm iri) =>
///               PersonMapper(documentIriProvider: () => iri.iri)),
///         )));
///
///   print('Round-trip successful: all data preserved');
/// }
/// ```
///
/// This example demonstrates how global unmapped triples capture:
/// - Document-level metadata (version, lastModified)
/// - Complete unrelated entities (work organization)
/// - Any future extensions to the profile format
/// - Perfect round-trip fidelity for complex RDF documents
