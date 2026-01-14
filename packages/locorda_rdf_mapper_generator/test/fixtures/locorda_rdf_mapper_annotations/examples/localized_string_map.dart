import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';

@RdfLocalResource()
class Book {
  @RdfProperty(
    const IriTerm('http://example.org/book/title'),
    literal: LiteralMapping.mapperInstance(const LocalizedEntryMapper()),
  )
  final Map<String, String> translations;

  Book({required this.translations});
}

class LocalizedEntryMapper
    implements LiteralTermMapper<MapEntry<String, String>> {
  final IriTerm? datatype = null;
  const LocalizedEntryMapper();

  @override
  MapEntry<String, String> fromRdfTerm(
    LiteralTerm term,
    DeserializationContext context, {
    bool bypassDatatypeCheck = false,
  }) =>
      MapEntry(term.language ?? 'en', term.value);

  @override
  LiteralTerm toRdfTerm(
    MapEntry<String, String> value,
    SerializationContext context,
  ) =>
      LiteralTerm.withLanguage(value.value, value.key);
}
