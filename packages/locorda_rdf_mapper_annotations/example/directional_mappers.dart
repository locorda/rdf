// ignore_for_file: unused_element

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';

// Example demonstrating directional mapper support

// ============================================================================
// Use Case 1: Deserialize-Only Resource
// ============================================================================
// Useful when consuming external RDF data where you don't need to
// serialize objects back to RDF, or when IRI construction logic is complex.

@RdfGlobalResource.deserializeOnly(
  IriTerm('http://schema.org/Book'),
)
class ExternalBook {
  // No @RdfIriPart needed - we're only deserializing
  @RdfProperty(IriTerm('http://schema.org/name'))
  final String title;

  @RdfProperty(IriTerm('http://schema.org/isbn'))
  final String isbn;

  ExternalBook({required this.title, required this.isbn});
}

// ============================================================================
// Use Case 2: Serialize-Only Resource
// ============================================================================
// Useful for data export scenarios where you generate RDF but don't
// need to read it back.

@RdfGlobalResource.serializeOnly(
  IriTerm('http://schema.org/Product'),
  IriStrategy('http://example.org/products/{id}'),
)
class ProductExport {
  @RdfIriPart('id')
  final String productId;

  @RdfProperty(IriTerm('http://schema.org/name'))
  final String name;

  @RdfProperty(IriTerm('http://schema.org/price'))
  final double price;

  ProductExport({
    required this.productId,
    required this.name,
    required this.price,
  });
}

// ============================================================================
// Use Case 3: Bidirectional Mapping (Standard)
// ============================================================================
// The default - supports both serialization and deserialization

@RdfGlobalResource(
  IriTerm('http://schema.org/Person'),
  IriStrategy('http://example.org/people/{id}'),
)
class Person {
  @RdfIriPart('id')
  final String id;

  @RdfProperty(IriTerm('http://schema.org/name'))
  final String name;

  Person({required this.id, required this.name});
}

// ============================================================================
// Use Case 4: Custom Mapper with Direction Control
// ============================================================================
// Useful when you implement custom mapper logic and want to control direction

// Deserialize-only custom mapper
@RdfGlobalResource.namedMapper(
  'readOnlyArticleMapper',
  direction: MapperDirection.deserializeOnly,
)
class ReadOnlyArticle {
  final String title;
  final String content;

  ReadOnlyArticle({required this.title, required this.content});
}

// Serialize-only custom mapper
@RdfGlobalResource.mapper(
  WriteOnlyArticleMapper,
  direction: MapperDirection.serializeOnly,
)
class WriteOnlyArticle {
  final String articleId;
  final String title;
  final String content;

  WriteOnlyArticle({
    required this.articleId,
    required this.title,
    required this.content,
  });
}

// Mock mapper for demonstration
class WriteOnlyArticleMapper
    implements GlobalResourceSerializer<WriteOnlyArticle> {
  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    WriteOnlyArticle value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject = context.createIriTerm(
      'http://example.org/articles/${value.articleId}',
    );
    return (
      subject,
      [
        Triple(
          subject,
          IriTerm('http://schema.org/headline'),
          LiteralTerm(value.title),
        ),
        Triple(
          subject,
          IriTerm('http://schema.org/articleBody'),
          LiteralTerm(value.content),
        ),
      ]
    );
  }

  @override
  IriTerm? get typeIri => IriTerm('http://schema.org/Article');
}

// ============================================================================
// Use Case 5: Const Mapper Instance with Direction
// ============================================================================

// Note: For mapper instances with direction, the mapper type must match the direction.
// A const mapper implementing only GlobalResourceSerializer can be used with serializeOnly.
// Since we can't use const with the full GlobalResourceMapper, we use namedMapper instead.

@RdfGlobalResource.namedMapper(
  'documentSerializerMapper',
  direction: MapperDirection.serializeOnly,
)
class Document {
  final String id;
  final String content;

  Document({required this.id, required this.content});
}

// Mock mapper for demonstration - would be provided to initRdfMapper
class DocumentSerializerMapper implements GlobalResourceSerializer<Document> {
  const DocumentSerializerMapper();

  @override
  (IriTerm, Iterable<Triple>) toRdfResource(
    Document value,
    SerializationContext context, {
    RdfSubject? parentSubject,
  }) {
    final subject =
        context.createIriTerm('http://example.org/docs/${value.id}');
    return (
      subject,
      [
        Triple(
          subject,
          IriTerm('http://schema.org/text'),
          LiteralTerm(value.content),
        ),
      ]
    );
  }

  @override
  IriTerm? get typeIri => IriTerm('http://schema.org/DigitalDocument');
}

// ============================================================================
// Benefits Summary
// ============================================================================
//
// 1. **Type Safety**: Standard cases maintain required IriStrategy
// 2. **Explicit Intent**: Specialized constructors make purpose clear
// 3. **Flexibility**: Custom mappers can specify direction without new constructors
// 4. **Optimization**: Generator can create optimized code for single-direction mappers
// 5. **No API Explosion**: Only 2 new constructors, not 3×4 = 12
//
// Key Design Decisions:
// - `.deserializeOnly()` and `.serializeOnly()`: For auto-generated mappers
// - `direction` parameter: For custom mapper constructors
// - Default is always `MapperDirection.both` to maintain backwards compatibility
