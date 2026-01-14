import 'package:locorda_rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/template_data.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';

/// Builds template data from processed resource information.
class TemplateDataBuilder {
  /// Builds file template data for multiple global resource mappers.
  static FileTemplateData buildFileTemplate(
      ValidationContext context,
      String sourcePath,
      List<MappableClassMapperTemplateData> mapperDatas,
      BroaderImports broaderImports,
      final Map<String, String> originalImports,
      String mapperFileImportUri) {
    final header = FileHeaderData(
      sourcePath: sourcePath,
      generatedOn: DateTime.now().toIso8601String(),
    );

    return FileTemplateData(
      header: header,
      mappers: mapperDatas.map((m) => MapperData(m)).toList(),
      broaderImports: broaderImports,
      originalImports: originalImports,
      mapperFileImportUri: mapperFileImportUri,
    );
  }
}
