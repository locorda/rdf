/// Example demonstrating lossless RDF mapping with @RdfUnmappedTriples annotation
/// and using RdfGraph as a property type for subgraphs.
///
/// This example shows two powerful features:
/// 1. @RdfUnmappedTriples annotation to preserve unmapped RDF triples
/// 2. Using RdfGraph as a regular property type to capture subgraphs
///
/// Both features leverage the UnmappedTriplesMapper system, allowing flexible
/// handling of RDF data without always requiring custom Dart classes.
///
library;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

/// A person with basic properties and lossless mapping support.
///
/// This class demonstrates how @RdfUnmappedTriples preserves additional
/// properties that may be present in the RDF data but aren't explicitly
/// mapped to Dart properties.
@RdfGlobalResource(
  SchemaPerson.classIri,
  IriStrategy("https://example.org/people/{id}"),
)
class Person {
  /// Unique identifier for the person
  @RdfIriPart("id")
  final String id;

  /// Person's full name
  @RdfProperty(SchemaPerson.name)
  final String name;

  /// Person's age in years
  @RdfProperty(SchemaPerson.foafAge)
  final int age;

  /// Example of using RdfGraph as a regular property type.
  ///
  /// This captures all triples about the person's address as a subgraph,
  /// without needing to create a separate Address class. Useful for
  /// simple, non-cyclic subgraphs that you want to preserve as-is.
  @RdfProperty(SchemaPerson.address)
  final RdfGraph? address;

  /// Captures any additional RDF properties not explicitly mapped above.
  ///
  /// This field will automatically be populated with triples like:
  /// - https://schema.org/email "john@example.com"
  /// - https://schema.org/telephone "+1-555-0123"
  /// - https://example.org/customProperty "custom value"
  ///
  /// These properties are preserved during round-trip serialization.
  /// Note: This uses the default subject-scoped collection.
  @RdfUnmappedTriples()
  final RdfGraph unmappedProperties;

  Person({
    required this.id,
    required this.name,
    required this.age,
    this.address,
    RdfGraph? unmappedProperties,
  }) : unmappedProperties = unmappedProperties ?? RdfGraph(triples: []);
}

/// Example of a top-level document class using global unmapped triples collection.
///
/// This demonstrates the recommended pattern for using @RdfUnmappedTriples with
/// globalUnmapped=true - only on a single, top-level document container class
/// like a Solid WebID/Profile Document.
@RdfGlobalResource(
  IriTerm("https://example.org/vocab/ProfileDocument"),
  IriStrategy("https://example.org/profiles/{profileId}"),
)
class ProfileDocument {
  /// Unique identifier for the profile document
  @RdfIriPart("profileId")
  final String profileId;

  /// The primary person described by this profile document
  @RdfProperty(IriTerm("https://example.org/vocab/primaryTopic"))
  final Person primaryTopic;

  /// Additional people mentioned in the profile (just URIs, not full data)
  @RdfProperty(IriTerm("https://example.org/vocab/knows"))
  final List<Uri> knownPeople;

  /// Captures ALL unmapped triples from the entire document graph.
  ///
  /// This includes unmapped triples from:
  /// - The document itself
  /// - The primary person (full object data)
  /// - Any other subjects referenced in the document
  /// - Any blank nodes referenced by these entities
  ///
  /// WARNING: Only use globalUnmapped=true on ONE top-level class per application.
  @RdfUnmappedTriples(globalUnmapped: true)
  final RdfGraph globalUnmappedTriples;

  ProfileDocument({
    required this.profileId,
    required this.primaryTopic,
    this.knownPeople = const [],
    RdfGraph? globalUnmappedTriples,
  }) : globalUnmappedTriples = globalUnmappedTriples ?? RdfGraph(triples: []);
}

/// Example usage showing both lossless mapping and RdfGraph properties:
///
/// ```dart
/// void main() {
///   // Sample RDF data with more properties than our Dart class maps
///   final turtle = '''
///     @prefix schema: <https://schema.org/> .
///     @prefix ex: <https://example.org/> .
///
///     <https://example.org/people/123> a schema:Person ;
///       schema:name "John Doe" ;
///       schema:age 30 ;
///       schema:address [
///         schema:streetAddress "123 Main St" ;
///         schema:addressLocality "Example City" ;
///         schema:postalCode "12345" ;
///         ex:buildingType "Apartment"
///       ] ;
///       schema:email "john@example.com" ;
///       schema:telephone "+1-555-0123" ;
///       ex:customProperty "custom value" .
///   ''';
///
///   // Initialize the generated mapper
///   final rdfMapper = initRdfMapper();
///
///   // Decode - both address subgraph and unmapped properties are preserved
///   final person = rdfMapper.decodeObject<Person>(turtle);
///   print('Name: ${person.name}');  // "John Doe"
///   print('Age: ${person.age}');    // 30
///
///   // Address is captured as an RdfGraph containing the blank node subgraph
///   print('Address triples: ${person.address?.triples.length}'); // 4 (street, city, postal, buildingType)
///
///   // Unmapped properties (email, telephone, customProperty) are preserved separately
///   print('Unmapped triples: ${person.unmappedProperties.triples.length}'); // 3
///
///   // Encode back - all original data is preserved (address subgraph + unmapped properties)
///   final roundTripTurtle = rdfMapper.encodeObject(person);
///
///   // Perfect lossless round-trip!
///   final person2 = rdfMapper.decodeObject<Person>(roundTripTurtle);
///   assert(person.address?.triples.length == person2.address?.triples.length);
///   assert(person.unmappedProperties.triples.length == person2.unmappedProperties.triples.length);
/// }
/// ```
///
/// Key benefits of this approach:
///
/// 1. **@RdfUnmappedTriples**: Preserves unknown/additional properties for true lossless mapping
/// 2. **RdfGraph properties**: Handle known subgraphs without creating custom classes
/// 3. **Flexibility**: Mix strongly-typed properties (name, age) with graph-based ones (address)
/// 4. **Future-proof**: Your application can handle RDF data evolution gracefully
///
/// When to use each approach:
/// - Use **@RdfUnmappedTriples** for truly unknown/variable properties
/// - Use **RdfGraph properties** for known subgraphs that are too complex or variable for custom classes
/// - Use **custom classes** for well-defined, stable object structures
