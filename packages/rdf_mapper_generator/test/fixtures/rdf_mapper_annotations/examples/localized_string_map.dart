import 'package:rdf_core/rdf_core.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_annotations/rdf_mapper_annotations.dart';

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
