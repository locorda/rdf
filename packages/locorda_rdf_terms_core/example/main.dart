// Example demonstrating locorda_rdf_terms_core usage
// This package provides the most fundamental RDF vocabularies as Dart constants

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_terms_core/rdf.dart';
import 'package:locorda_rdf_terms_core/rdfs.dart';
import 'package:locorda_rdf_terms_core/owl.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';

/// Demonstrates the essential RDF vocabularies provided by locorda_rdf_terms_core.
///
/// This package contains only the most fundamental RDF vocabularies:
/// - RDF: Core Resource Description Framework vocabulary
/// - RDFS: RDF Schema vocabulary for defining classes and properties
/// - OWL: Web Ontology Language for creating ontologies
/// - XSD: XML Schema Datatypes for typed literals
///
/// For additional vocabularies (FOAF, Dublin Core, vCard, etc.), see the
/// locorda_rdf_terms_* packages in the locorda/rdf-vocabularies monorepo.
void main() {
  print('=== Core RDF Vocabularies Example ===\n');

  // Example 1: Using RDF vocabulary
  _rdfExample();

  // Example 2: Using RDFS for schema definition
  _rdfsExample();

  // Example 3: Using OWL for ontology definition
  _owlExample();

  // Example 4: Using XSD datatypes
  _xsdDatatypesExample();
}

/// Example demonstrating RDF vocabulary usage
void _rdfExample() {
  print('--- RDF Vocabulary Example ---');

  final personIri = IriTerm('http://example.org/person/jane');
  final personTypeIri = IriTerm('http://example.org/vocab/Person');

  final graph = RdfGraph.fromTriples([
    // Use rdf:type to declare the type of a resource
    Triple(personIri, Rdf.type, personTypeIri),

    // rdf:Property is the class of RDF properties
    Triple(IriTerm('http://example.org/vocab/name'), Rdf.type, Rdf.Property),
  ]);

  print(ntriples.encode(graph));
  print('');
}

/// Example demonstrating RDFS vocabulary for schema definition
void _rdfsExample() {
  print('--- RDFS Schema Definition Example ---');

  final personClass = IriTerm('http://example.org/vocab/Person');
  final employeeClass = IriTerm('http://example.org/vocab/Employee');
  final nameProperty = IriTerm('http://example.org/vocab/name');

  final graph = RdfGraph.fromTriples([
    // Define a class using rdfs:Class
    Triple(personClass, Rdf.type, Rdfs.Class),
    Triple(personClass, Rdfs.label, LiteralTerm.string('Person')),
    Triple(personClass, Rdfs.comment, LiteralTerm.string('A human being')),

    // Define a subclass relationship
    Triple(employeeClass, Rdf.type, Rdfs.Class),
    Triple(employeeClass, Rdfs.label, LiteralTerm.string('Employee')),
    Triple(employeeClass, Rdfs.subClassOf, personClass),

    // Define a property with domain and range
    Triple(nameProperty, Rdf.type, Rdf.Property),
    Triple(nameProperty, Rdfs.label, LiteralTerm.string('name')),
    Triple(nameProperty, Rdfs.domain, personClass),
    Triple(
      nameProperty,
      Rdfs.range,
      LiteralTerm(Xsd.string.value, datatype: Rdfs.Datatype),
    ),
  ]);

  print(ntriples.encode(graph));
  print('');
}

/// Example demonstrating OWL vocabulary for ontology definition
void _owlExample() {
  print('--- OWL Ontology Definition Example ---');

  final ontologyIri = IriTerm('http://example.org/ontology');
  final personClass = IriTerm('http://example.org/vocab/Person');
  final organizationClass = IriTerm('http://example.org/vocab/Organization');
  final worksForProperty = IriTerm('http://example.org/vocab/worksFor');
  final employedByProperty = IriTerm('http://example.org/vocab/employedBy');

  final graph = RdfGraph.fromTriples([
    // Declare an OWL ontology
    Triple(ontologyIri, Rdf.type, Owl.Ontology),
    Triple(
      ontologyIri,
      Rdfs.label,
      LiteralTerm.string('Example Organization Ontology'),
    ),

    // Define OWL classes
    Triple(personClass, Rdf.type, Owl.Class),
    Triple(organizationClass, Rdf.type, Owl.Class),

    // Define symmetric and transitive properties using OWL
    Triple(worksForProperty, Rdf.type, Owl.ObjectProperty),
    Triple(worksForProperty, Rdfs.domain, personClass),
    Triple(worksForProperty, Rdfs.range, organizationClass),

    // Define property characteristics
    Triple(employedByProperty, Rdf.type, Owl.ObjectProperty),
    Triple(employedByProperty, Owl.inverseOf, worksForProperty),

    // Define property restrictions
    Triple(
      IriTerm('http://example.org/vocab/hasName'),
      Rdf.type,
      Owl.DatatypeProperty,
    ),
    Triple(
      IriTerm('http://example.org/vocab/hasName'),
      Rdf.type,
      Owl.FunctionalProperty,
    ),
  ]);

  print(ntriples.encode(graph));
  print('');
}

/// Example demonstrating XSD datatypes for typed literals
void _xsdDatatypesExample() {
  print('--- XSD Datatypes Example ---');

  final resourceIri = IriTerm('http://example.org/resource/1');

  final graph = RdfGraph.fromTriples([
    // String types
    Triple(
      resourceIri,
      IriTerm('http://example.org/vocab/name'),
      LiteralTerm('Jane Doe', datatype: Xsd.string),
    ),

    // Numeric types
    Triple(
      resourceIri,
      IriTerm('http://example.org/vocab/age'),
      LiteralTerm('42', datatype: Xsd.integer),
    ),
    Triple(
      resourceIri,
      IriTerm('http://example.org/vocab/height'),
      LiteralTerm('1.75', datatype: Xsd.decimal),
    ),
    Triple(
      resourceIri,
      IriTerm('http://example.org/vocab/weight'),
      LiteralTerm('70.5', datatype: Xsd.double),
    ),

    // Boolean
    Triple(
      resourceIri,
      IriTerm('http://example.org/vocab/active'),
      LiteralTerm('true', datatype: Xsd.boolean),
    ),

    // Date and time types
    Triple(
      resourceIri,
      IriTerm('http://example.org/vocab/birthDate'),
      LiteralTerm('1982-01-15', datatype: Xsd.date),
    ),
    Triple(
      resourceIri,
      IriTerm('http://example.org/vocab/lastLogin'),
      LiteralTerm('2026-01-14T10:30:00Z', datatype: Xsd.dateTime),
    ),
    Triple(
      resourceIri,
      IriTerm('http://example.org/vocab/workingHours'),
      LiteralTerm('PT8H', datatype: Xsd.duration),
    ),

    // Other useful types
    Triple(
      resourceIri,
      IriTerm('http://example.org/vocab/homepage'),
      LiteralTerm('https://example.org', datatype: Xsd.anyURI),
    ),
    Triple(
      resourceIri,
      IriTerm('http://example.org/vocab/hash'),
      LiteralTerm('5d41402abc4b2a76b9719d911017c592', datatype: Xsd.hexBinary),
    ),
  ]);

  print(ntriples.encode(graph));
  print('');
}
