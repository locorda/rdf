import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_core/owl.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';
import 'package:locorda_rdf_terms_core/rdf.dart' show Rdf;
import 'package:locorda_rdf_terms_core/rdfs.dart';
import 'package:locorda_rdf_terms_common/dcterms.dart';
import 'package:locorda_rdf_terms_schema/schema.dart';

const testVocab = AppVocab(
  appBaseUri: 'https://example.com',
  vocabPath: '/vocab',
  label: 'Example Vocabulary',
  comment: 'Vocabulary for tests',
  metadata: [
    (Owl.versionInfo, LiteralTerm('1.2.3')),
    (Dcterms.date, LiteralTerm.withDatatype('2026-02-17', Xsd.date)),
    (Dcterms.creator, IriTerm('https://example.com/teams/core')),
  ],
);

const contractsVocab = AppVocab(
  appBaseUri: 'https://example.com',
  vocabPath: '/contracts',
  label: 'Contracts Vocabulary',
  comment: 'Vocabulary for contracts',
  metadata: [
    (Owl.versionInfo, LiteralTerm('0.9.0')),
    (Dcterms.creator, LiteralTerm('Contracts Team')),
  ],
);

@RdfGlobalResource.define(
  testVocab,
  IriStrategy('https://example.com/books/{id}'),
  label: 'Book Resource',
  comment: 'A globally identified book resource',
  metadata: [
    (Rdfs.seeAlso, IriTerm('https://example.com/docs/book')),
  ],
)
class GenVocabBook {
  @RdfIriPart('id')
  final String id;

  final String title;

  @RdfProperty.define(
    fragment: 'displayTitle',
    label: 'Display Title Explicit',
    comment: 'Title variant for UX rendering',
    metadata: [
      (Rdfs.range, Xsd.string),
    ],
  )
  final String displayTitle;

  @RdfProperty.define(
    label: 'ISBN',
    comment: 'International Standard Book Number',
  )
  final String isbn;

  const GenVocabBook({
    required this.id,
    required this.title,
    required this.displayTitle,
    required this.isbn,
  });
}

@RdfGlobalResource.define(
  testVocab,
  IriStrategy('https://example.com/library-items/{id}'),
  subClassOf: SchemaCreativeWork.classIri,
  label: 'Library Item',
  comment: 'Shared superclass-like item for content entities',
  metadata: [
    (Rdfs.seeAlso, IriTerm('https://example.com/docs/library-item')),
  ],
)
class GenVocabLibraryItem {
  @RdfIriPart('id')
  final String id;

  @RdfProperty.define(
    fragment: 'libraryItemTitle',
    label: 'Item Title',
    comment: 'Primary title for any library item',
  )
  final String title;

  @RdfProperty.define(
    fragment: 'publicationDate',
    label: 'Publication Date',
    metadata: [
      (Rdfs.range, Xsd.date),
    ],
  )
  final String publicationDate;

  const GenVocabLibraryItem({
    required this.id,
    required this.title,
    required this.publicationDate,
  });
}

@RdfGlobalResource.define(
  contractsVocab,
  IriStrategy('https://example.com/contracts/{id}'),
  subClassOf: SchemaCreativeWork.classIri,
  label: 'Contract Resource',
  comment: 'Contract entity from secondary vocabulary',
)
class GenVocabContract {
  @RdfIriPart('id')
  final String id;

  final String title;

  @RdfProperty.define(
    label: 'Signed At',
    comment: 'Date when contract was signed',
    metadata: [
      (Rdfs.range, Xsd.date),
    ],
  )
  final String signedAt;

  const GenVocabContract({
    required this.id,
    required this.title,
    required this.signedAt,
  });
}

@RdfGlobalResource.define(
  testVocab,
  IriStrategy('https://example.com/products/{id}'),
  metadata: [
    (Rdfs.label, LiteralTerm.withLanguage('Product', 'en')),
    (Rdfs.label, LiteralTerm.withLanguage('Produkt', 'de')),
    (Rdfs.label, LiteralTerm.withLanguage('Produit', 'fr')),
    (Rdfs.comment, LiteralTerm.withLanguage('A product for sale', 'en')),
    (Rdfs.comment, LiteralTerm.withLanguage('Ein Produkt zum Verkauf', 'de')),
  ],
)
class GenVocabMultilingualProduct {
  @RdfIriPart('id')
  final String id;

  @RdfProperty.define(
    metadata: [
      (Rdfs.label, LiteralTerm.withLanguage('Name', 'en')),
      (Rdfs.label, LiteralTerm.withLanguage('Name', 'de')),
      (Rdfs.label, LiteralTerm.withLanguage('Nom', 'fr')),
    ],
  )
  final String name;

  @RdfProperty.define(
    metadata: [
      (Rdfs.label, LiteralTerm.withLanguage('Price', 'en')),
      (Rdfs.label, LiteralTerm.withLanguage('Preis', 'de')),
      (Rdfs.range, Xsd.decimal),
    ],
  )
  final double price;

  const GenVocabMultilingualProduct({
    required this.id,
    required this.name,
    required this.price,
  });
}

/// Tests mixed usage: subClassOf with both external vocabulary properties
/// (regular @RdfProperty) and custom properties (@RdfProperty.define or unannotated).
/// Ensures that external properties are NOT added to the generated vocabulary.
@RdfGlobalResource.define(
  testVocab,
  IriStrategy('https://example.com/articles/{id}'),
  subClassOf: SchemaCreativeWork.classIri,
  label: 'Article',
  comment: 'A blog or news article extending Schema.org CreativeWork',
)
class GenVocabArticle {
  @RdfIriPart('id')
  final String id;

  // External vocabulary property - should NOT be added to our vocabulary
  @RdfProperty(SchemaCreativeWork.name)
  final String name;

  // External vocabulary property - should NOT be added to our vocabulary
  @RdfProperty(SchemaCreativeWork.dateCreated)
  final String dateCreated;

  // External vocabulary property - should NOT be added to our vocabulary
  @RdfProperty(SchemaCreativeWork.author,
      iri: IriMapping('https://example.com/authors/{authorId}'))
  final String authorId;

  // Custom property with define - SHOULD be added to our vocabulary
  @RdfProperty.define(
    fragment: 'viewCount',
    label: 'View Count',
    comment: 'Number of times this article has been viewed',
    metadata: [
      (Rdfs.range, Xsd.nonNegativeInteger),
    ],
  )
  final int viewCount;

  // Custom property without annotation - SHOULD be added to our vocabulary
  final String internalNotes;

  const GenVocabArticle({
    required this.id,
    required this.name,
    required this.dateCreated,
    required this.authorId,
    required this.viewCount,
    required this.internalNotes,
  });
}

/// Tests that user-specified rdf:type in metadata overrides the default rdf:Property type.
/// This demonstrates how users can explicitly set owl:ObjectProperty or owl:DatatypeProperty
/// when needed for formal ontology requirements.
@RdfGlobalResource.define(
  testVocab,
  IriStrategy('https://example.com/publications/{id}'),
  label: 'Publication',
  comment: 'Publication resource with explicitly typed properties',
)
class GenVocabPropertyTypeOverride {
  @RdfIriPart('id')
  final String id;

  // Default rdf:Property (no type override)
  final String title;

  // Explicitly typed as owl:DatatypeProperty via metadata
  @RdfProperty.define(
    fragment: 'wordCount',
    label: 'Word Count',
    metadata: [
      (Rdf.type, OwlDatatypeProperty.classIri),
      (Rdfs.range, Xsd.integer),
    ],
  )
  final int wordCount;

  // Explicitly typed as owl:ObjectProperty via metadata
  @RdfProperty.define(
    fragment: 'primaryAuthor',
    label: 'Primary Author',
    comment: 'The main author of this publication',
    iri: IriMapping('https://example.com/authors/{primaryAuthorId}'),
    metadata: [
      (Rdf.type, OwlObjectProperty.classIri),
      (Rdfs.range, IriTerm('https://example.com/vocab#Person')),
    ],
  )
  final String primaryAuthorId;

  const GenVocabPropertyTypeOverride({
    required this.id,
    required this.title,
    required this.wordCount,
    required this.primaryAuthorId,
  });
}
