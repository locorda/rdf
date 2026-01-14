import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/template_data.dart';

import 'code.dart';

const importRdfMapper = 'package:locorda_rdf_mapper/mapper.dart';
const importRdfMapperAnnotations =
    'package:locorda_rdf_mapper_annotations/annotations.dart';

const importRdfCore = 'package:locorda_rdf_core/core.dart';
const importRdfVocab = 'package:locorda_rdf_terms_core/rdf.dart';
const importXsd = 'package:locorda_rdf_terms_core/xsd.dart';
const importSchema = 'package:locorda_rdf_terms_schema/schema.dart';

List<Map<String, dynamic>> toMustacheList<T>(List<T> values) {
  return List.generate(values.length, (i) {
    return {'value': values[i], 'last': i == values.length - 1};
  });
}

final stringType = Code.coreType('String');

Code codeGeneric1(Code mapperInterface, Code className) => Code.combine([
      mapperInterface,
      Code.genericParamsList([className])
    ]);

Code codeGeneric2(Code type, Code p1, Code p2) => Code.combine([
      type,
      Code.genericParamsList([p1, p2])
    ]);

Code createConstructorCall(
    Code className, List<ConstructorParameterData> constructorParameters,
    {bool constContext = false}) {
  return Code.combine([
    if (constContext) Code.literal(' const '),
    className,
    Code.paramsList(
      constructorParameters
          .map((p) => Code.combine([
                Code.literal(p.parameterName),
                Code.literal(': '),
                Code.literal(p.parameterName)
              ]))
          .toList(),
    ),
  ]);
}

Code toCode(DartObject? dartObject) {
  return dartObject?.toCode() ?? Code.value('null');
}

Code typeToCode(DartType type,
    {bool enforceNonNull = false, bool raw = false}) {
  return type.toCode(enforceNonNull: enforceNonNull, raw: raw);
}

Code classToCode(ClassElem classElem) {
  return classElem.toCode();
}

Code enumToCode(EnumElem enumElem) {
  return enumElem.toCode();
}
