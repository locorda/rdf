import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_annotations/annotations.dart';
import 'package:locorda_rdf_terms_core/rdf.dart' show Rdf;

@RdfLocalResource()
class Book {
  @RdfProperty(IriTerm('http://example.org/book/title'),
      literal: LiteralMapping.mapperInstance(const LocalizedEntryMapper()))
  final Map<String, String> translations;

  Book({required this.translations});
}

class LocalizedEntryMapper
    implements LiteralTermMapper<MapEntry<String, String>> {
  const LocalizedEntryMapper();

  @override
  IriTerm? get datatype => Rdf.langString;

  @override
  MapEntry<String, String> fromRdfTerm(
          LiteralTerm term, DeserializationContext context,
          {bool bypassDatatypeCheck = false}) =>
      MapEntry(
        term.language ?? 'en',
        term.value,
      );

  @override
  LiteralTerm toRdfTerm(
          MapEntry<String, String> value, SerializationContext context) =>
      LiteralTerm.withLanguage(value.value, value.key);
}
