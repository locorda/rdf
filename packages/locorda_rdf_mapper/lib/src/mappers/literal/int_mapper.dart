import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';

final class IntMapper extends BaseRdfLiteralTermMapper<int> {
  const IntMapper([IriTerm? datatype])
      : super(
          datatype: datatype ?? Xsd.integer,
        );

  @override
  convertFromLiteral(term, _) => int.parse(term.value);

  @override
  convertToString(i) => i.toString();
}
