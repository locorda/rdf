import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_terms_core/owl.dart';
import 'package:locorda_rdf_terms_core/rdf.dart';
import 'package:locorda_rdf_terms_core/rdfs.dart';

class VocabOntologyDefinition {
  final IriTerm vocabularyIri;
  final Map<IriTerm, List<RdfObject>> metadata;
  final List<VocabClassDefinition> classes;

  const VocabOntologyDefinition({
    required this.vocabularyIri,
    required this.classes,
    this.metadata = const {},
  });
}

class VocabClassDefinition {
  final IriTerm classIri;
  final IriTerm? subClassOfIri;
  final Map<IriTerm, List<RdfObject>> metadata;
  final List<VocabPropertyDefinition> properties;

  const VocabClassDefinition({
    required this.classIri,
    required this.subClassOfIri,
    this.metadata = const {},
    required this.properties,
  });
}

class VocabPropertyDefinition {
  final IriTerm propertyIri;
  final bool noDomain;
  final Map<IriTerm, List<RdfObject>> metadata;

  const VocabPropertyDefinition({
    required this.propertyIri,
    this.noDomain = false,
    this.metadata = const {},
  });
}

RdfGraph createOwlOntology(VocabOntologyDefinition ontology) {
  final triples = <Triple>[];
  final vocabTerm = ontology.vocabularyIri;
  final actualVocabMetadata = {
    ...ontology.metadata,
    if (!ontology.metadata.containsKey(RdfProperty.type))
      RdfProperty.type: [OwlOntology.classIri],
  };

  for (final entry in actualVocabMetadata.entries) {
    for (final value in entry.value) {
      triples.add(Triple(vocabTerm, entry.key, value));
    }
  }

  for (final clazz in ontology.classes) {
    final classTerm = clazz.classIri;
    final actualClassMetadata = {
      ...clazz.metadata,
      if (!clazz.metadata.containsKey(RdfProperty.type))
        RdfProperty.type: [OwlClass.classIri],
      if (!clazz.metadata.containsKey(RdfsClass.isDefinedBy))
        RdfsClass.isDefinedBy: [vocabTerm],
      if (!clazz.metadata.containsKey(RdfsClass.subClassOf))
        RdfsClass.subClassOf: [clazz.subClassOfIri ?? RdfsResource.classIri],
    };

    for (final entry in actualClassMetadata.entries) {
      for (final value in entry.value) {
        triples.add(Triple(classTerm, entry.key, value));
      }
    }

    for (final property in clazz.properties) {
      final propertyTerm = property.propertyIri;
      final actualMetadata = {
        ...property.metadata,
        if (!property.metadata.containsKey(RdfProperty.type))
          RdfProperty.type: [RdfProperty.classIri],
        if (!property.noDomain &&
            !property.metadata.containsKey(RdfProperty.rdfsDomain))
          RdfProperty.rdfsDomain: [classTerm],
        if (!property.metadata.containsKey(RdfsClass.isDefinedBy))
          RdfsClass.isDefinedBy: [vocabTerm],
      };
      for (final entry in actualMetadata.entries) {
        for (final value in entry.value) {
          triples.add(Triple(propertyTerm, entry.key, value));
        }
      }
    }
  }

  return RdfGraph.fromTriples(triples);
}
