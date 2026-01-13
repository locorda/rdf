// import 'package:analyzer/dart/element/element2.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:rdf_mapper_generator/src/processors/iri_processor.dart';
import 'package:rdf_mapper_generator/src/processors/literal_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

/// Processor for handling enum elements annotated with RDF term annotations.
///
/// This processor identifies enums that are annotated with @RdfLiteral or @RdfIri
/// and delegates processing to the appropriate specialized processor.
class EnumProcessor {
  /// Processes an enum element to determine if it should generate a mapper.
  ///
  /// Returns a [MappableClassInfo] if the enum is annotated with a supported
  /// RDF term annotation, null otherwise.
  static MappableClassInfo? processEnum(
    ValidationContext context,
    EnumElem enumElement,
  ) {
    // Try IRI processing first
    final iriInfo = IriProcessor.processEnum(context, enumElement);
    if (iriInfo != null) {
      return iriInfo;
    }

    // Try literal processing
    final literalInfo = LiteralProcessor.processEnum(context, enumElement);
    if (literalInfo != null) {
      return literalInfo;
    }

    // No supported annotations found
    return null;
  }
}
