import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';

// ============================================================================
// Global Resource Tests (already implemented)
// ============================================================================

/// Test model for deserialize-only global resource mapper
@RdfGlobalResource.deserializeOnly(
  IriTerm('http://example.org/DeserializeOnlyClass'),
)
class DeserializeOnlyGlobalResource {
  @RdfProperty(IriTerm('http://example.org/name'))
  final String name;

  DeserializeOnlyGlobalResource({required this.name});
}

/// Test model for serialize-only global resource mapper
@RdfGlobalResource.serializeOnly(
  IriTerm('http://example.org/SerializeOnlyClass'),
  IriStrategy('http://example.org/items/{id}'),
)
class SerializeOnlyGlobalResource {
  @RdfIriPart('id')
  final String id;

  @RdfProperty(IriTerm('http://example.org/title'))
  final String title;

  SerializeOnlyGlobalResource({required this.id, required this.title});
}

/// Test model for bidirectional global resource mapper
@RdfGlobalResource(
  IriTerm('http://example.org/BidirectionalClass'),
  IriStrategy('http://example.org/bidirectional/{id}'),
)
class BidirectionalGlobalResource {
  @RdfIriPart('id')
  final String id;

  @RdfProperty(IriTerm('http://example.org/description'))
  final String description;

  BidirectionalGlobalResource({required this.id, required this.description});
}

// ============================================================================
// Local Resource Tests
// ============================================================================

/// Test model for deserialize-only local resource mapper
@RdfLocalResource(
  IriTerm('http://example.org/LocalDeserializeOnly'),
  true,
  MapperDirection.deserializeOnly,
)
class DeserializeOnlyLocalResource {
  @RdfProperty(IriTerm('http://example.org/localName'))
  final String localName;

  DeserializeOnlyLocalResource({required this.localName});
}

/// Test model for serialize-only local resource mapper
@RdfLocalResource(
  IriTerm('http://example.org/LocalSerializeOnly'),
  true,
  MapperDirection.serializeOnly,
)
class SerializeOnlyLocalResource {
  @RdfProperty(IriTerm('http://example.org/localTitle'))
  final String localTitle;

  SerializeOnlyLocalResource({required this.localTitle});
}

/// Test model for bidirectional local resource mapper
@RdfLocalResource(
  IriTerm('http://example.org/LocalBidirectional'),
)
class BidirectionalLocalResource {
  @RdfProperty(IriTerm('http://example.org/localDescription'))
  final String localDescription;

  BidirectionalLocalResource({required this.localDescription});
}

// ============================================================================
// IRI Mapper Tests
// ============================================================================

/// Test model for deserialize-only IRI mapper
@RdfIri(
  'http://example.org/iri/deserialize/{id}',
  true,
  MapperDirection.deserializeOnly,
)
class DeserializeOnlyIriClass {
  @RdfIriPart('id')
  final String id;

  DeserializeOnlyIriClass({required this.id});
}

/// Test model for serialize-only IRI mapper
@RdfIri(
  'http://example.org/iri/serialize/{code}',
  true,
  MapperDirection.serializeOnly,
)
class SerializeOnlyIriClass {
  @RdfIriPart('code')
  final String code;

  SerializeOnlyIriClass({required this.code});
}

/// Test model for bidirectional IRI mapper
@RdfIri(
  'http://example.org/iri/bidirectional/{uuid}',
)
class BidirectionalIriClass {
  @RdfIriPart('uuid')
  final String uuid;

  BidirectionalIriClass({required this.uuid});
}

// ============================================================================
// Literal Mapper Tests
// ============================================================================

/// Test model for deserialize-only literal mapper
@RdfLiteral(
  Xsd.string,
  true,
  MapperDirection.deserializeOnly,
)
class DeserializeOnlyLiteralClass {
  @RdfValue()
  final String value;

  DeserializeOnlyLiteralClass({required this.value});
}

/// Test model for serialize-only literal mapper
@RdfLiteral(
  Xsd.integer,
  true,
  MapperDirection.serializeOnly,
)
class SerializeOnlyLiteralClass {
  @RdfValue()
  final int value;

  SerializeOnlyLiteralClass({required this.value});
}

/// Test model for bidirectional literal mapper
@RdfLiteral(Xsd.boolean)
class BidirectionalLiteralClass {
  @RdfValue()
  final bool value;

  BidirectionalLiteralClass({required this.value});
}

// ============================================================================
// Enum IRI Tests
// ============================================================================

/// Test enum for deserialize-only IRI mapper
@RdfIri(
  'http://example.org/enum/priority/{value}',
  true,
  MapperDirection.deserializeOnly,
)
enum DeserializeOnlyIriEnum {
  @RdfEnumValue('high')
  high,
  @RdfEnumValue('medium')
  medium,
  @RdfEnumValue('low')
  low,
}

/// Test enum for serialize-only IRI mapper
@RdfIri(
  'http://example.org/enum/status/{value}',
  true,
  MapperDirection.serializeOnly,
)
enum SerializeOnlyIriEnum {
  @RdfEnumValue('active')
  active,
  @RdfEnumValue('inactive')
  inactive,
}

/// Test enum for bidirectional IRI mapper
@RdfIri(
  'http://example.org/enum/type/{value}',
)
enum BidirectionalIriEnum {
  @RdfEnumValue('typeA')
  typeA,
  @RdfEnumValue('typeB')
  typeB,
}

// ============================================================================
// Enum Literal Tests
// ============================================================================

/// Test enum for deserialize-only literal mapper
@RdfLiteral(
  Xsd.string,
  true,
  MapperDirection.deserializeOnly,
)
enum DeserializeOnlyLiteralEnum {
  @RdfEnumValue('option1')
  option1,
  @RdfEnumValue('option2')
  option2,
}

/// Test enum for serialize-only literal mapper
@RdfLiteral(
  Xsd.string,
  true,
  MapperDirection.serializeOnly,
)
enum SerializeOnlyLiteralEnum {
  @RdfEnumValue('choiceA')
  choiceA,
  @RdfEnumValue('choiceB')
  choiceB,
}

/// Test enum for bidirectional literal mapper
@RdfLiteral(Xsd.string)
enum BidirectionalLiteralEnum {
  @RdfEnumValue('valueX')
  valueX,
  @RdfEnumValue('valueY')
  valueY,
}
