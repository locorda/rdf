import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';

final class DateTimeMapper extends BaseRdfLiteralTermMapper<DateTime> {
  const DateTimeMapper([IriTerm? datatype])
      : super(
          datatype: datatype ?? Xsd.dateTime,
        );

  @override
  convertFromLiteral(term, _) => DateTime.parse(term.value).toUtc();

  @override
  convertToString(dateTime) => dateTime.toUtc().toIso8601String();
}
