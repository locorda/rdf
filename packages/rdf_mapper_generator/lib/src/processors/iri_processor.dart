// import 'package:analyzer/dart/constant/value.dart';
// import 'package:analyzer/dart/element/element2.dart';
import 'package:logging/logging.dart';
import 'package:rdf_mapper/rdf_mapper.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:rdf_mapper_generator/src/processors/iri_strategy_processor.dart';
import 'package:rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:rdf_mapper_generator/src/templates/code.dart';
import 'package:rdf_mapper_generator/src/templates/util.dart';
import 'package:rdf_mapper_generator/src/validation/validation_context.dart';

final _log = Logger('IriProcessor');

/// Processes class elements to extract @RdfIri information.
class IriProcessor {
  /// Processes a class element and returns its ResourceInfo if it's annotated with @RdfGlobalResource or @RdfLocalResource.
  ///
  /// Returns a [MappableClassInfo] containing the processed information if the class is annotated
  /// with `@RdfIri`, otherwise returns `null`.
  static IriInfo? processClass(
      ValidationContext context, ClassElem classElement) {
    final annotation = getAnnotation(classElement.annotations, 'RdfIri');
    final className = classToCode(classElement);

    // Create the RdfGlobalResource instance from the annotation
    final rdfIriAnnotation =
        _createRdfIriAnnotation(context, annotation, classElement);
    if (rdfIriAnnotation == null) {
      return null; // No valid resource annotation found
    }
    final properties = extractProperties(context, classElement);
    final constructors = extractConstructors(
        classElement, properties, rdfIriAnnotation.templateInfo);
    final rdfMapValue = extractMapValueAnnotation(classElement.annotations);

    return IriInfo(
      className: className,
      annotation: rdfIriAnnotation,
      constructors: constructors,
      properties: properties,
      rdfMapValue: rdfMapValue,
    );
  }

  /// Processes an enum element and returns its IriInfo if it's annotated with @RdfIri.
  ///
  /// Returns an [IriInfo] containing the processed information if the enum is annotated
  /// with `@RdfIri`, otherwise returns `null`.
  static IriInfo? processEnum(ValidationContext context, EnumElem enumElement) {
    final annotation = getAnnotation(enumElement.annotations, 'RdfIri');
    final enumName = enumToCode(enumElement);

    // Create the RdfIri instance from the annotation
    final rdfIriAnnotation =
        _createRdfIriAnnotation(context, annotation, enumElement);
    if (rdfIriAnnotation == null) {
      return null; // No valid IRI annotation found
    }

    // Extract enum constants and their custom values
    final enumValues = extractEnumValues(context, enumElement);

    return IriInfo(
      className: enumName,
      annotation: rdfIriAnnotation,
      constructors: [],
      properties: [],
      enumValues: enumValues,
      rdfMapValue: extractMapValueAnnotation(enumElement.annotations),
    );
  }

  static RdfIriInfo? _createRdfIriAnnotation(
      ValidationContext context, DartObject? annotation, Elem element) {
    try {
      if (annotation == null) {
        return null;
      }

      // Get the registerGlobally flag
      final registerGlobally = isRegisterGlobally(annotation);

      final mapper = getMapperRefInfo<IriTermMapper>(annotation);

      // Get the iriStrategy from the annotation
      final templateFieldValue =
          getField(annotation, 'template')?.toStringValue();
      final fragmentTemplateFieldValue =
          getField(annotation, 'fragmentTemplate')?.toStringValue();

      // Get the mapper direction
      final direction = getMapperDirection(annotation);

      if (element is ClassElem) {
        final (template, templateInfo, iriParts) =
            IriStrategyProcessor.processIriPartsAndTemplateWithFragment(
                context,
                element,
                templateFieldValue,
                fragmentTemplateFieldValue,
                mapper);

        return RdfIriInfo(
            registerGlobally: registerGlobally,
            mapper: mapper,
            template: template,
            iriParts: iriParts,
            templateInfo: templateInfo,
            direction: direction);
      } else {
        // For enums, we only need the template string
        // If no template is provided, use {+value} as default (like classes use {+fieldName})
        final template = templateFieldValue ?? '{+value}';
        final fakeIriParts = <IriPartInfo>[
          IriPartInfo(
              name: 'value',
              dartPropertyName: 'value',
              type: Code.coreType('String'),
              pos: 1,
              isMappedValue: true)
        ];
        final templateInfo = IriStrategyProcessor.processTemplate(
            context, template, fakeIriParts,
            fragmentTemplate: fragmentTemplateFieldValue);
        return RdfIriInfo(
            registerGlobally: registerGlobally,
            mapper: mapper,
            template: template,
            iriParts: fakeIriParts,
            direction: direction,
            templateInfo: templateInfo);
      }
    } catch (e, stackTrace) {
      _log.severe('Error creating RdfIriInfo', e, stackTrace);
      rethrow;
    }
  }
}
