// import 'package:analyzer/dart/constant/value.dart';
// import 'package:analyzer/dart/element/element2.dart';
import 'package:logging/logging.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/util.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';

final _log = Logger('LiteralProcessor');

/// Processes class elements to extract @RdfLiteral information.
class LiteralProcessor {
  /// Processes a class element and returns its LiteralInfo.
  ///
  /// Returns a [LiteralInfo] containing the processed information if the class is annotated
  /// with `@RdfLiteral`, otherwise returns `null`.
  static LiteralInfo? processClass(
      ValidationContext context, ClassElem classElement) {
    final annotation = getAnnotation(classElement.annotations, 'RdfLiteral');
    final className = classToCode(classElement);

    // Create the RdfGlobalResource instance from the annotation
    final rdfIriAnnotation =
        _createRdfLiteralAnnotation(context, annotation, classElement);
    if (rdfIriAnnotation == null) {
      return null; // No valid resource annotation found
    }
    final properties =
        extractProperties(context, classElement, isGenVocab: false);
    final constructors = extractConstructors(classElement, properties, null);
    final rdfMapValue = extractMapValueAnnotation(classElement.annotations);

    return LiteralInfo(
      className: className,
      annotation: rdfIriAnnotation,
      constructors: constructors,
      properties: properties,
      rdfMapValue: rdfMapValue,
    );
  }

  /// Processes an enum element and returns its LiteralInfo if it's annotated with @RdfLiteral.
  ///
  /// Returns a [LiteralInfo] containing the processed information if the enum is annotated
  /// with `@RdfLiteral`, otherwise returns `null`.
  static LiteralInfo? processEnum(
      ValidationContext context, EnumElem enumElement) {
    final annotation = getAnnotation(enumElement.annotations, 'RdfLiteral');
    final enumName = enumToCode(enumElement);

    // Create the RdfLiteral instance from the annotation
    final rdfLiteralAnnotation =
        _createRdfLiteralAnnotation(context, annotation, enumElement);
    if (rdfLiteralAnnotation == null) {
      return null; // No valid literal annotation found
    }

    // Extract enum constants and their custom values
    final enumValues = extractEnumValues(context, enumElement);

    return LiteralInfo(
      className: enumName,
      annotation: rdfLiteralAnnotation,
      constructors: [],
      properties: [],
      enumValues: enumValues,
      rdfMapValue: extractMapValueAnnotation(enumElement.annotations),
    );
  }

  static RdfLiteralInfo? _createRdfLiteralAnnotation(
      ValidationContext context, DartObject? annotation, Elem element) {
    try {
      if (annotation == null) {
        return null;
      }

      // Get the registerGlobally flag
      final registerGlobally = isRegisterGlobally(annotation);

      final mapper = getMapperRefInfo<LiteralTermMapper>(annotation);
      final datatype = getIriTermInfo(getField(annotation, 'datatype'));
      final toLiteralTermMethod =
          getField(annotation, 'toLiteralTermMethod')?.toStringValue();

      final fromLiteralTermMethod =
          getField(annotation, 'fromLiteralTermMethod')?.toStringValue();
// Get the mapper direction
      final direction = getMapperDirection(annotation);

      // Create and return the RdfGlobalResource instance
      return RdfLiteralInfo(
        registerGlobally: registerGlobally,
        mapper: mapper,
        toLiteralTermMethod: toLiteralTermMethod,
        fromLiteralTermMethod: fromLiteralTermMethod,
        datatype: datatype,
        direction: direction,
      );
    } catch (e, stackTrace) {
      _log.severe('Error creating RdfLiteralInfo', e, stackTrace);
      rethrow;
    }
  }
}
