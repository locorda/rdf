// import 'package:analyzer/dart/constant/value.dart';
// import 'package:analyzer/dart/element/element2.dart';
// import 'package:analyzer/dart/element/type.dart';
// import 'package:analyzer/dart/element/type_system.dart';
import 'package:logging/logging.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/property_processor.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/util.dart';
import 'package:locorda_rdf_mapper_generator/src/validation/validation_context.dart';

final _log = Logger('ProcessorUtils');

/// Contains information about an IRI source reference including the
/// source code expression and required import.
class IriTermInfo {
  /// The source code expression (e.g., 'SchemaBook.classIri' or 'const IriTerm("https://schema.org/Book")')
  final Code code;

  /// The actual IRI value for fallback purposes
  final IriTerm value;

  const IriTermInfo({
    required this.code,
    required this.value,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IriTermInfo && other.code == code && other.value == value;
  }

  @override
  int get hashCode => Object.hash(
        code,
        value,
      );

  @override
  String toString() => 'IriTermInfo(code: $code, '
      'value: $value)';
}

DartObject? getAnnotation(
    Iterable<ElemAnnotation> annotations, String annotationName) {
  try {
    // Get metadata from the class element
    for (final elementAnnotation in annotations) {
      try {
        final annotation = elementAnnotation.computeConstantValue();
        if (annotation != null) {
          if (_matchesAnnotationInHierarchy(annotation.type, annotationName)) {
            return annotation;
          }
        }
      } catch (_) {
        // Ignore errors for individual annotations
        continue;
      }
    }
  } catch (_) {
    // Ignore errors during annotation processing
    return null;
  }

  return null;
}

/// Checks if the given type or any of its supertypes match the target annotation name.
/// This supports annotation subclassing by walking up the inheritance hierarchy.
bool _matchesAnnotationInHierarchy(
    DartType? type, String targetAnnotationName) {
  if (type == null) {
    return false;
  }

  final visitedTypes = <String>{};
  return _checkTypeHierarchy(type, targetAnnotationName, visitedTypes);
}

/// Recursively checks the type hierarchy to find a match for the target annotation name.
/// Uses a visited set to prevent infinite loops in case of circular dependencies.
bool _checkTypeHierarchy(
    DartType type, String targetAnnotationName, Set<String> visitedTypes) {
  final typeName = type.element.name;

  // Prevent infinite loops
  if (visitedTypes.contains(typeName)) {
    return false;
  }
  visitedTypes.add(typeName);

  // Check if current type matches
  if (typeName == targetAnnotationName) {
    return true;
  }

  // Check supertypes - the analyzer wrapper provides this data
  for (final supertype in type.allSupertypes) {
    if (_checkTypeHierarchy(supertype, targetAnnotationName, visitedTypes)) {
      return true;
    }
  }

  return false;
}

IriPartAnnotationInfo? extractIriPartAnnotation(
    String fieldName, Iterable<ElemAnnotation> annotations) {
  // Check for @RdfIriPart annotation
  final iriPartAnnotation = getAnnotation(annotations, 'RdfIriPart');
  if (iriPartAnnotation == null) {
    return null;
  }
  final name = getFieldStringValue(iriPartAnnotation, 'name') ?? fieldName;
  final pos = getField(iriPartAnnotation, 'pos')?.toIntValue() ?? 0;
  return IriPartAnnotationInfo(
    name: name,
    pos: pos,
  );
}

RdfMapEntryAnnotationInfo? extractMapEntryAnnotation(ValidationContext context,
    String fieldName, Iterable<ElemAnnotation> annotations) {
  // Check for @RdfMapEntry annotation
  final mapEntryAnnotation = getAnnotation(annotations, 'RdfMapEntry');
  if (mapEntryAnnotation == null) {
    return null;
  }
  final itemClass = getField(mapEntryAnnotation, 'itemClass');
  final itemClassType = itemClass?.toTypeValue();
  if (itemClassType == null) {
    context.addError(
        'RdfMapEntry annotation on field $fieldName must specify a type for itemClass');
    return null;
  }
  final itemType = typeToCode(itemClassType);
  final itemClassTypeElement =
      itemClassType.isInterfaceType ? itemClassType.element : null;
  final ClassElem? itemClassElement =
      itemClassTypeElement is ClassElem ? itemClassTypeElement : null;
  if (itemClassElement == null) {
    context.addError(
        'RdfMapEntry annotation on field $fieldName must specify a class for itemClass');
    return null;
  }
  return RdfMapEntryAnnotationInfo(
    itemType: itemType,
    itemClassElement: itemClassElement,
    itemClassType: itemClassType,
  );
}

RdfMapKeyAnnotationInfo? extractMapKeyAnnotation(
    Iterable<ElemAnnotation> annotations) {
  final mapKeyAnnotation = getAnnotation(annotations, 'RdfMapKey');
  return mapKeyAnnotation == null ? null : RdfMapKeyAnnotationInfo();
}

RdfMapValueAnnotationInfo? extractMapValueAnnotation(
    Iterable<ElemAnnotation> annotations) {
  final mapValueAnnotation = getAnnotation(annotations, 'RdfMapValue');
  return mapValueAnnotation == null ? null : RdfMapValueAnnotationInfo();
}

RdfUnmappedTriplesAnnotationInfo? extractUnmappedTriplesAnnotation(
    Iterable<ElemAnnotation> annotations) {
  final unmappedTriplesAnnotation =
      getAnnotation(annotations, 'RdfUnmappedTriples');
  if (unmappedTriplesAnnotation == null) {
    return null;
  }

  final globalUnmapped =
      getFieldBoolValue(unmappedTriplesAnnotation, 'globalUnmapped') ?? false;
  return RdfUnmappedTriplesAnnotationInfo(globalUnmapped: globalUnmapped);
}

bool isNull(DartObject? field) {
  return field == null || field.isNull;
}

MapperRefInfo<M>? getMapperRefInfo<M>(DartObject annotation) {
  final typeField = getField(annotation, '_mapperType');
  final instanceField = getField(annotation, '_mapperInstance');
  final name = getFieldStringValue(annotation, '_mapperName');
  final factoryName = getFieldStringValue(annotation, '_factoryName');
  final configInstanceField = getField(annotation, '_factoryConfigInstance');

  // Check if we have any mapping information
  if (name == null &&
      factoryName == null &&
      isNull(typeField) &&
      isNull(instanceField)) {
    return null;
  }

  var typeValue = typeField?.toTypeValue();
  var type = typeValue == null ? null : typeToCode(typeValue);
  var rawType = typeValue == null ? null : typeToCode(typeValue, raw: true);

  // Handle config instance type for namedFactory
  Code? configType;
  if (configInstanceField != null && !configInstanceField.isNull) {
    final configTypeValue = configInstanceField.type;
    if (configTypeValue != null) {
      configType = typeToCode(configTypeValue);
    }
  }

  return MapperRefInfo(
    name: name,
    type: type,
    rawType: rawType,
    instance: instanceField,
    factoryName: factoryName,
    configInstance: configInstanceField,
    configType: configType,
  );
}

bool isRegisterGlobally(DartObject annotation) {
  final field = getField(annotation, 'registerGlobally');
  return field?.toBoolValue() ?? true;
}

/// Extracts the mapper direction from an annotation.
/// Returns the string representation of the MapperDirection enum value,
/// or null if not set or if it's set to 'both'.
SerializationDirection? getMapperDirection(DartObject annotation) {
  final directionField = getField(annotation, 'direction');
  if (directionField == null || directionField.isNull) {
    return null;
  }
  // The direction field is of type MapperDirection enum
  // We need to extract the enum value name
  final enumValue = directionField.getField('_name')?.toStringValue();
  // Return null for 'both' as it's the default behavior
  return SerializationDirection.fromString(enumValue);
}

/**
 * Gets the field - unlike obj.getField() we will go up the 
 * inheritance tree to find a parent with the field of the specified name
 * if needed.
 */
DartObject? getField(DartObject obj, String fieldName) {
  final field = obj.getField(fieldName);
  if (field != null && !field.isNull) {
    return field;
  }
  final superInstance = obj.getField('(super)');
  if (superInstance == null) {
    return null;
  }
  return getField(superInstance, fieldName);
}

String? getFieldStringValue(DartObject obj, String fieldName) {
  final retval = getField(obj, fieldName)?.toStringValue();
  return retval == null || retval.isEmpty ? null : retval;
}

bool? getFieldBoolValue(DartObject obj, String fieldName) {
  return getField(obj, fieldName)?.toBoolValue();
}

E getEnumFieldValue<E extends Enum>(
    DartObject annotation, String fieldName, List<E> values, E defaultValue) {
  final collectionField = getField(annotation, 'collection');

  // Extract enum constant name - toStringValue() returns null for enums,
  // so we need to access the variable element's name
  final collectionValue = collectionField?.variable?.name;

  final collection = collectionValue == null
      ? defaultValue
      : values.firstWhere((e) => e.name == collectionValue);
  return collection;
}

IriTerm? getIriTerm(DartObject? iriTermObject) {
  try {
    if (iriTermObject != null && !iriTermObject.isNull) {
      // Get the IRI string from the IriTerm
      final iriValue = getFieldStringValue(iriTermObject, 'value');
      if (iriValue != null) {
        return IriTerm.validated(iriValue);
      }
    }

    return null;
  } catch (e, stackTrace) {
    _log.severe('Error getting class IRI', e, stackTrace);
    return null;
  }
}

/// Gets the source code reference for an IRI field, preserving the original expression
/// and determining the required import.
/// This is used to maintain references like 'SchemaBook.classIri' instead of
/// evaluating them to literal values.
IriTermInfo? getIriTermInfo(DartObject? iriTermObject) {
  try {
    if (iriTermObject != null && !iriTermObject.isNull) {
      // Get the actual IRI value for fallback
      final iriTerm = getIriTerm(iriTermObject)!;

      // Try to get the source reference from the variable element
      final code = toCode(iriTermObject);

      return IriTermInfo(
        code: code,
        value: iriTerm,
      );
    }
    return null;
  } catch (e) {
    _log.severe('Error getting IRI source reference', e);
    return null;
  }
}

Map<String, String> _getIriPartNameByPropertyName(
        IriTemplateInfo? templateInfo) =>
    templateInfo == null
        ? {}
        : {
            for (var pv in templateInfo.propertyVariables)
              pv.dartPropertyName: pv.name
          };

List<ConstructorInfo> extractConstructors(ClassElem classElement,
    List<PropertyInfo> fields, IriTemplateInfo? iriTemplateInfo) {
  final iriPartNameByPropertyName =
      _getIriPartNameByPropertyName(iriTemplateInfo);

  final constructors = <ConstructorInfo>[];
  try {
    final fieldsByName = {for (final field in fields) field.name: field};

    for (final constructor in classElement.constructors) {
      final parameters = <ParameterInfo>[];

      for (final parameter in constructor.formalParameters) {
        // Find the corresponding field with @RdfProperty annotation, if it exists
        final fieldInfo = fieldsByName[parameter.name];

        parameters.add(ParameterInfo(
          name: parameter.name,
          type: typeToCode(parameter.type),
          isRequired: parameter.isRequired,
          isNamed: parameter.isNamed,
          isPositional: parameter.isPositional,
          isOptional: parameter.isOptional,
          propertyInfo: fieldInfo?.propertyInfo,
          isIriPart: iriPartNameByPropertyName.containsKey(parameter.name),
          iriPartName: iriPartNameByPropertyName[parameter.name],
          isRdfLanguageTag: fieldInfo?.isRdfLanguageTag ?? false,
          isRdfValue: fieldInfo?.isRdfValue ?? false,
        ));
      }

      constructors.add(ConstructorInfo(
        name: constructor.displayName,
        isFactory: constructor.isFactory,
        isConst: constructor.isConst,
        isDefaultConstructor: constructor.isDefaultConstructor,
        parameters: parameters,
      ));
    }
  } catch (e) {
    _log.severe('Error extracting constructors', e);
  }

  return constructors;
}

List<PropertyInfo> extractProperties(
    ValidationContext context, ClassElem classElement) {
  final gettersByName = {for (var g in classElement.getters) g.name: g};
  final settersByName = {for (var g in classElement.setters) g.name: g};
  final gettersOrSettersNames = <String>{
    ...gettersByName.keys,
    ...settersByName.keys,
  };
  final fieldNames =
      classElement.fields.where((f) => !f.isStatic).map((f) => f.name).toSet();

  _log.finest('Processing fields for class: ${classElement.name}');
  final virtualFields = gettersOrSettersNames
      .where((name) => !fieldNames.contains(name))
      .map((name) {
    final getter = gettersByName[name];
    final setter = settersByName[name];
    if (getter == null && setter == null) {
      // If neither getter nor setter exists, we skip it
      return null;
    }

    // If only getter exists (no setter), this is a computed property
    // and should NOT be treated as a field requiring constructor parameters
    if (getter != null && setter == null) {
      return createPropertyInfo(
        context,
        name: name,
        type: getter.type,
        isFinal: false,
        isLate: false,
        hasInitializer:
            true, // Computed properties are "initialized" by their getter
        isSettable: false, // Getter-only properties cannot be set
        isSynthetic: false,
        annotations: getter.annotations,
        isStatic: getter.isStatic,
      );
    }

    // If only setter exists or both getter and setter exist, treat as a field
    return createPropertyInfo(
      context,
      name: name,
      type: (getter?.type ?? setter?.type)!,
      isFinal: false,
      isLate: false,
      hasInitializer: false,
      isSettable: true, // Properties with setters can be set
      isSynthetic: false,
      annotations: [
        ...(getter?.annotations ?? const <ElemAnnotation>[]),
        ...(setter?.annotations ?? const <ElemAnnotation>[])
      ],
      isStatic: getter == null
          ? setter!.isStatic
          : (setter == null
              ? getter.isStatic
              : getter.isStatic && setter.isStatic),
    );
  }).nonNulls;
  final fields = classElement.fields.where((f) => !f.isStatic).map((f) {
    final getter = gettersByName[f.name];
    final setter = settersByName[f.name];

    return createPropertyInfo(context,
        name: f.name,
        type: f.type,
        isFinal: f.isFinal,
        isLate: f.isLate,
        hasInitializer: f.hasInitializer,
        isSettable: !(f.isFinal &&
            f.hasInitializer), // Fields are settable unless they're final with initializer
        isSynthetic: f.isSynthetic,
        annotations: [
          ...f.annotations,
          // Sometimes getters/setters are detected as fields, but strangely they have no metadata
          // so we add metadata from getter/setter if exists
          ...(getter?.annotations ?? const <ElemAnnotation>[]),
          ...(setter?.annotations ?? const <ElemAnnotation>[])
        ],
        isStatic: f.isStatic);
  });
  return [
    ...virtualFields,
    ...fields,
  ];
}

PropertyInfo createPropertyInfo(ValidationContext context,
    {required String name,
    required DartType type,
    required Iterable<ElemAnnotation> annotations,
    required bool isStatic,
    required bool isFinal,
    required bool isLate,
    required bool hasInitializer,
    required bool isSettable,
    required bool isSynthetic}) {
  final mapEntry = extractMapEntryAnnotation(context, name, annotations);
  final mapKey = extractMapKeyAnnotation(annotations);
  final mapValue = extractMapValueAnnotation(annotations);
  final unmappedTriples = extractUnmappedTriplesAnnotation(annotations);

  final propertyInfo = PropertyProcessor.processFieldAlike(
    context,
    type: type,
    name: name,
    annotations: annotations,
    isStatic: isStatic,
    isFinal: isFinal,
    isLate: isLate,
    isSynthetic: isSynthetic,
    mapEntry: mapEntry,
  );
  final isNullable = type.isNullable;

  _log.finest('Annotations for field $name: $annotations');
  final isRdfValue = getAnnotation(annotations, 'RdfValue') != null;
  final isRdfLanguageTag = getAnnotation(annotations, 'RdfLanguageTag') != null;
  final providesInfo = extractProvidesAnnotation(
    name,
    annotations,
  );
  final iriPart = extractIriPartAnnotation(name, annotations);
  return PropertyInfo(
      name: name,
      type: typeToCode(type),
      typeNonNull: typeToCode(type, enforceNonNull: true),
      isFinal: isFinal,
      isLate: isLate,
      hasInitializer: hasInitializer,
      isSettable: isSettable,
      isStatic: isStatic,
      isSynthetic: isSynthetic,
      propertyInfo: propertyInfo,
      isRequired: propertyInfo?.isRequired ?? !isNullable,
      isRdfLanguageTag: isRdfLanguageTag,
      isRdfValue: isRdfValue,
      provides: providesInfo,
      iriPart: iriPart,
      mapEntry: mapEntry,
      mapKey: mapKey,
      mapValue: mapValue,
      unmappedTriples: unmappedTriples);
}

ProvidesAnnotationInfo? extractProvidesAnnotation(
  String name,
  Iterable<ElemAnnotation> annotations,
) {
  final providesAnnotation = getAnnotation(annotations, 'RdfProvides');
  if (providesAnnotation == null) {
    return null;
  }
  final providesName = getFieldStringValue(providesAnnotation, 'name');
  return ProvidesAnnotationInfo(
    name: providesName ?? name,
    dartPropertyName: name,
  );
}

/// Extracts enum constants and their custom @RdfEnumValue annotations.
List<EnumValueInfo> extractEnumValues(
    ValidationContext context, EnumElem enumElement) {
  final enumValues = <EnumValueInfo>[];

  for (final constant in enumElement.constants) {
    final constantName = constant.name;
    final enumValueAnnotation =
        getAnnotation(constant.annotations, 'RdfEnumValue');

    String serializedValue;
    if (enumValueAnnotation != null) {
      // Use custom value from @RdfEnumValue
      final customValue = getFieldStringValue(enumValueAnnotation, 'value');
      if (customValue == null || customValue.isEmpty) {
        context.addError(
            'Custom value for enum constant $constantName cannot be empty');
        continue;
      }
      serializedValue = customValue;
    } else {
      // Use enum constant name as default
      serializedValue = constantName;
    }

    enumValues.add(EnumValueInfo(
      constantName: constantName,
      serializedValue: serializedValue,
    ));
  }

  return enumValues;
}

/// Information about RDF annotation on a type
class RdfTypeAnnotationInfo {
  final String annotationType; // 'RdfGlobalResource', 'RdfLocalResource', etc.
  final bool registerGlobally;
  final String mapperClassName;
  final String mapperImportPath;

  const RdfTypeAnnotationInfo({
    required this.annotationType,
    required this.registerGlobally,
    required this.mapperClassName,
    required this.mapperImportPath,
  });

  @override
  String toString() =>
      'RdfTypeAnnotationInfo(type: $annotationType, registerGlobally: $registerGlobally, '
      'mapper: $mapperClassName)';
}

/// Analyzes a Dart type to determine if it has RDF annotations and whether
/// a mapper should be inferred for it.
RdfTypeAnnotationInfo? analyzeTypeForRdfAnnotation(DartType type) {
  if (type.isNotInterfaceType) {
    return null;
  }

  final element = type.element;
  if (element is! AnnotatedElem) {
    // Not an annotated element, skip
    return null;
  }
  final annotations = (element as AnnotatedElem).annotations;

  // Check for RDF annotations
  final rdfAnnotations = [
    'RdfGlobalResource',
    'RdfLocalResource',
    'RdfIri',
    'RdfLiteral',
  ];

  for (final annotationType in rdfAnnotations) {
    final annotation = getAnnotation(annotations, annotationType);
    if (annotation != null) {
      final registerGlobally = isRegisterGlobally(annotation);

      // Generate mapper class name and import path
      final className = element.name;
      final mapperClassName = '${className}Mapper';

      // Determine import path based on the source library
      final sourceLibraryUri = element.libraryIdentifier!;

      String mapperImportPath;
      if (sourceLibraryUri.endsWith('.dart')) {
        // Convert from 'package:foo/to/source.dart' to 'package:foo/to/source.rdf_mapper.g.dart'
        mapperImportPath =
            '${sourceLibraryUri.substring(0, sourceLibraryUri.length - '.dart'.length)}.rdf_mapper.g.dart';
      } else {
        // Fallback for package imports or other schemes
        mapperImportPath = 'generated_mappers.dart';
      }
      return RdfTypeAnnotationInfo(
        annotationType: annotationType,
        registerGlobally: registerGlobally,
        mapperClassName: mapperClassName,
        mapperImportPath: mapperImportPath,
      );
    }
  }

  return null;
}
