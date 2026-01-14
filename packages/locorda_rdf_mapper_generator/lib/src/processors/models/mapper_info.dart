// import 'package:analyzer/dart/element/element2.dart';
// import 'package:analyzer/dart/element/type.dart';
import 'package:locorda_rdf_mapper/mapper.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/base_mapping_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/rdf_property_info.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/processor_utils.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';

/// Contains information about a class annotated with @RdfGlobalResource
sealed class MappableClassInfo<A extends BaseMappingAnnotationInfo> {
  /// The name of the class
  Code get className;

  /// The RdfGlobalResource or RdfLocalResource annotation instance
  A get annotation;

  /// List of constructors in the class
  List<ConstructorInfo> get constructors;

  /// List of fields in the class
  List<PropertyInfo> get properties;

  /// Class-Level annotation if the entire class shall be used as a map value
  RdfMapValueAnnotationInfo? get rdfMapValue;

  List<AnnotationInfo> get annotations =>
      [if (rdfMapValue != null) rdfMapValue!];

  const MappableClassInfo();
}

/// Contains information about a class annotated with @RdfGlobalResource
class IriInfo extends MappableClassInfo<RdfIriInfo> {
  /// The name of the class
  @override
  final Code className;

  /// The RdfIri annotation instance
  @override
  final RdfIriInfo annotation;

  /// List of constructors in the class
  @override
  final List<ConstructorInfo> constructors;

  /// List of fields in the class
  @override
  final List<PropertyInfo> properties;

  /// Class-Level annotation if the entire class shall be used as a map value
  @override
  final RdfMapValueAnnotationInfo? rdfMapValue;

  /// List of enum values (empty for classes, populated for enums)
  final List<EnumValueInfo> enumValues;

  const IriInfo({
    required this.className,
    required this.annotation,
    required this.constructors,
    required this.properties,
    this.rdfMapValue,
    this.enumValues = const [],
  });

  @override
  int get hashCode => Object.hashAll([
        className,
        annotation,
        constructors,
        properties,
        enumValues,
        rdfMapValue
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! IriInfo) {
      return false;
    }
    return className == other.className &&
        annotation == other.annotation &&
        constructors == other.constructors &&
        properties == other.properties &&
        enumValues == other.enumValues &&
        rdfMapValue == other.rdfMapValue;
  }

  @override
  String toString() {
    return 'IriInfo{\n'
        '  className: $className,\n'
        '  annotation: $annotation,\n'
        '  constructors: $constructors,\n'
        '  fields: $properties,\n'
        '  enumValues: $enumValues,\n'
        '  rdfMapValue: $rdfMapValue\n'
        '}';
  }
}

/// Contains information about a class annotated with @RdfLiteral
class LiteralInfo extends MappableClassInfo<RdfLiteralInfo> {
  /// The name of the class
  @override
  final Code className;

  /// The RdfLiteral annotation instance
  @override
  final RdfLiteralInfo annotation;

  /// List of constructors in the class
  @override
  final List<ConstructorInfo> constructors;

  /// List of fields in the class
  @override
  final List<PropertyInfo> properties;

  /// Class-Level annotation if the entire class shall be used as a map value
  @override
  final RdfMapValueAnnotationInfo? rdfMapValue;

  /// List of enum values (empty for classes, populated for enums)
  final List<EnumValueInfo> enumValues;

  const LiteralInfo({
    required this.className,
    required this.annotation,
    required this.constructors,
    required this.properties,
    this.rdfMapValue,
    this.enumValues = const [],
  });

  @override
  int get hashCode => Object.hashAll([
        className,
        annotation,
        constructors,
        properties,
        enumValues,
        rdfMapValue
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! LiteralInfo) {
      return false;
    }
    return className == other.className &&
        annotation == other.annotation &&
        constructors == other.constructors &&
        properties == other.properties &&
        enumValues == other.enumValues &&
        rdfMapValue == other.rdfMapValue;
  }

  @override
  String toString() {
    return 'LiteralInfo{\n'
        '  className: $className,\n'
        '  annotation: $annotation,\n'
        '  constructors: $constructors,\n'
        '  fields: $properties,\n'
        '  enumValues: $enumValues,\n'
        '  rdfMapValue: $rdfMapValue,\n'
        '}';
  }
}

/// Contains information about a class annotated with @RdfGlobalResource
class ResourceInfo extends MappableClassInfo<RdfResourceInfo> {
  /// The name of the class
  @override
  final Code className;

  /// The RdfGlobalResource or RdfLocalResource annotation instance
  @override
  final RdfResourceInfo annotation;

  /// List of constructors in the class
  @override
  final List<ConstructorInfo> constructors;

  /// List of fields in the class
  @override
  final List<PropertyInfo> properties;

  /// Class-Level annotation if the entire class shall be used as a map value
  @override
  final RdfMapValueAnnotationInfo? rdfMapValue;

  /// Generic type parameters for the class (e.g., ['T', 'K', 'V'])
  final List<String> typeParameters;

  const ResourceInfo({
    required this.className,
    required this.annotation,
    required this.constructors,
    required this.properties,
    this.rdfMapValue,
    this.typeParameters = const [],
  });

  bool get isGlobalResource => annotation is RdfGlobalResourceInfo;

  @override
  int get hashCode => Object.hashAll([
        className,
        annotation,
        constructors,
        properties,
        rdfMapValue,
        typeParameters
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! ResourceInfo) {
      return false;
    }
    return className == other.className &&
        annotation == other.annotation &&
        constructors == other.constructors &&
        properties == other.properties &&
        rdfMapValue == other.rdfMapValue &&
        typeParameters == other.typeParameters;
  }

  @override
  String toString() {
    return 'ResourceInfo{\n'
        '  className: $className,\n'
        '  annotation: $annotation,\n'
        '  constructors: $constructors,\n'
        '  fields: $properties,\n'
        '  rdfMapValue: $rdfMapValue,\n'
        '}';
  }
}

class IriStrategyInfo extends BaseMappingInfo<IriTermMapper> {
  final String? template;
  final String? fragmentTemplate;
  final IriTemplateInfo? templateInfo;
  final IriMapperType? iriMapperType;
  final String? providedAs;

  IriStrategyInfo({
    required super.mapper,
    required this.template,
    this.fragmentTemplate,
    this.templateInfo,
    this.iriMapperType,
    this.providedAs,
  });

  @override
  int get hashCode => Object.hashAll([
        mapper,
        template,
        fragmentTemplate,
        templateInfo,
        iriMapperType,
        providedAs
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! IriStrategyInfo) {
      return false;
    }
    return mapper == other.mapper &&
        template == other.template &&
        fragmentTemplate == other.fragmentTemplate &&
        templateInfo == other.templateInfo &&
        iriMapperType == other.iriMapperType &&
        providedAs == other.providedAs;
  }

  @override
  String toString() {
    return 'IriStrategyInfo{'
        'mapper: $mapper, '
        'template: $template, '
        'fragmentTemplate: $fragmentTemplate, '
        'templateInfo: $templateInfo, '
        'iriMapperType: $iriMapperType, '
        'providedAs: $providedAs}';
  }
}

class VariableName {
  final String dartPropertyName;
  final String name;
  final bool canBeUri;
  final bool isMappedValue;

  VariableName({
    required this.dartPropertyName,
    required this.name,
    required this.canBeUri,
    this.isMappedValue = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VariableName &&
        other.dartPropertyName == dartPropertyName &&
        other.name == name &&
        other.canBeUri == canBeUri &&
        other.isMappedValue == isMappedValue;
  }

  @override
  int get hashCode =>
      Object.hash(dartPropertyName, name, canBeUri, isMappedValue);

  @override
  String toString() =>
      'VariableName(dartPropertyName: $dartPropertyName, name: $name, canBeUri: $canBeUri, isMappedValue: $isMappedValue)';
}

class IriPartAnnotationInfo extends AnnotationInfo {
  final int pos;
  final String name;

  IriPartAnnotationInfo({
    required this.pos,
    required this.name,
  });
}

class ProvidesAnnotation {
  final String name;

  ProvidesAnnotation({
    required this.name,
  });
}

class IriPartInfo {
  final String name;
  final String dartPropertyName;
  final Code type;
  final int pos;
  final bool isMappedValue;

  const IriPartInfo({
    required this.name,
    required this.dartPropertyName,
    required this.type,
    required this.pos,
    this.isMappedValue = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IriPartInfo &&
        other.name == name &&
        other.dartPropertyName == dartPropertyName &&
        other.type == type &&
        other.pos == pos &&
        other.isMappedValue == isMappedValue;
  }

  @override
  int get hashCode =>
      Object.hash(name, dartPropertyName, type, pos, isMappedValue);

  @override
  String toString() =>
      'IriPartInfo(name: $name, dartPropertyName: $dartPropertyName, type: $type, pos: $pos, isMappedValue: $isMappedValue)';
}

class IriMapperType {
  final Code type;
  final List<IriPartInfo> parts;

  const IriMapperType(this.type, this.parts);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IriMapperType &&
        other.type == type &&
        other.parts.length == parts.length &&
        other.parts.every((part) => parts.contains(part));
  }

  @override
  int get hashCode => Object.hash(type, parts);

  @override
  String toString() => 'IriMapperType(type: $type, parts: $parts)';
}

/// Contains information about a processed IRI template.
class IriTemplateInfo {
  /// The original template string.
  final String template;
  final String? fragmentTemplate;

  /// All variables found in the template.
  final Set<VariableName> variableNames;
  Set<String> get variables => variableNames.map((e) => e.name).toSet();

  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<VariableName> propertyVariables;

  /// Variables that need to be provided from context.
  Set<String> get contextVariables =>
      contextVariableNames.map((e) => e.name).toSet();
  final Set<VariableName> contextVariableNames;

  /// Whether the template passed validation.
  final bool isValid;

  /// Validation error messages.
  final List<String> validationErrors;

  /// Warning messages about template configuration issues.
  final List<String> warnings;
  final List<IriPartInfo>? iriParts;

  const IriTemplateInfo({
    required this.template,
    this.fragmentTemplate,
    required Set<VariableName> variables,
    required this.propertyVariables,
    required Set<VariableName> contextVariables,
    required this.isValid,
    required this.validationErrors,
    this.iriParts = const [],
    this.warnings = const [],
  })  : variableNames = variables,
        contextVariableNames = contextVariables;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! IriTemplateInfo) return false;

    return template == other.template &&
        fragmentTemplate == other.fragmentTemplate &&
        variables.length == other.variables.length &&
        variables.difference(other.variables).isEmpty &&
        propertyVariables.length == other.propertyVariables.length &&
        propertyVariables.difference(other.propertyVariables).isEmpty &&
        contextVariables.length == other.contextVariables.length &&
        contextVariables.difference(other.contextVariables).isEmpty &&
        isValid == other.isValid &&
        validationErrors.length == other.validationErrors.length &&
        _listEquals(validationErrors, other.validationErrors) &&
        warnings.length == other.warnings.length &&
        _listEquals(warnings, other.warnings);
  }

  @override
  int get hashCode {
    return Object.hash(
      template,
      fragmentTemplate,
      variables.length,
      propertyVariables.length,
      contextVariables.length,
      isValid,
      validationErrors.length,
      warnings.length,
    );
  }

  @override
  String toString() {
    return 'IriTemplateInfo('
        'template: $template, '
        'fragmentTemplate: $fragmentTemplate, '
        'variables: $variables, '
        'propertyVariables: $propertyVariables, '
        'contextVariables: $contextVariables, '
        'isValid: $isValid, '
        'validationErrors: $validationErrors, '
        'warnings: $warnings, ';
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

enum SerializationDirection {
  serializeOnly,
  deserializeOnly;

  /// Mapper direction: 'serializeOnly', 'deserializeOnly', or null for both
  static SerializationDirection? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'serializeOnly':
        return SerializationDirection.serializeOnly;
      case 'deserializeOnly':
        return SerializationDirection.deserializeOnly;
      case 'both':
        // Return null for 'both' as it's the default behavior
        return null;
      default:
        return null;
    }
  }
}

sealed class BaseMappingAnnotationInfo<T> extends BaseMappingInfo<T> {
  final bool registerGlobally;
  final SerializationDirection? direction;

  const BaseMappingAnnotationInfo({
    this.registerGlobally = true,
    this.direction,
    super.mapper,
  });

  @override
  int get hashCode =>
      Object.hashAll([super.hashCode, registerGlobally, direction]);

  @override
  bool operator ==(Object other) {
    if (other is! BaseMappingAnnotationInfo<T>) {
      return false;
    }
    return super == other &&
        registerGlobally == other.registerGlobally &&
        direction == other.direction;
  }

  @override
  String toString() {
    return 'BaseMappingAnnotationInfo{'
        'registerGlobally: $registerGlobally, '
        'direction: $direction, '
        'mapper: $mapper}';
  }
}

sealed class RdfResourceInfo<T> extends BaseMappingAnnotationInfo<T> {
  final IriTermInfo? classIri;

  const RdfResourceInfo(
      {required this.classIri,
      required super.registerGlobally,
      super.direction,
      required super.mapper});

  @override
  int get hashCode =>
      Object.hashAll([classIri, registerGlobally, direction, mapper]);

  @override
  bool operator ==(Object other) {
    if (other is! RdfResourceInfo) {
      return false;
    }
    return classIri == other.classIri &&
        registerGlobally == other.registerGlobally &&
        direction == other.direction &&
        mapper == other.mapper;
  }

  @override
  String toString() {
    return 'RdfResourceInfo{'
        'classIri: $classIri, '
        'registerGlobally: $registerGlobally, '
        'direction: $direction, '
        'mapper: $mapper}';
  }
}

class RdfIriInfo extends BaseMappingAnnotationInfo<IriTermMapper> {
  final String? template;
  final IriTemplateInfo? templateInfo;
  final List<IriPartInfo>? iriParts;
  const RdfIriInfo(
      {required super.registerGlobally,
      super.direction,
      required super.mapper,
      required this.template,
      required this.iriParts,
      required this.templateInfo})
      : assert((template == null) != (mapper == null),
            'Either template or mapper must be provided, but not both.');

  @override
  int get hashCode => Object.hash(super.hashCode, template, templateInfo);

  @override
  bool operator ==(Object other) {
    if (other is! RdfIriInfo) {
      return false;
    }
    return super == other &&
        template == other.template &&
        templateInfo == other.templateInfo;
  }

  @override
  String toString() {
    return 'RdfIriInfo{'
        'registerGlobally: $registerGlobally, '
        'mapper: $mapper, '
        'template: $template, '
        'templateInfo: $templateInfo}';
  }
}

class RdfLiteralInfo extends BaseMappingAnnotationInfo<LiteralTermMapper> {
  final String? toLiteralTermMethod;
  final String? fromLiteralTermMethod;
  final IriTermInfo? datatype;

  const RdfLiteralInfo(
      {required super.registerGlobally,
      super.direction,
      required super.mapper,
      required this.fromLiteralTermMethod,
      required this.toLiteralTermMethod,
      required this.datatype})
      : assert(
            ((fromLiteralTermMethod == null) &&
                    (toLiteralTermMethod == null)) ||
                ((fromLiteralTermMethod != null) &&
                    (toLiteralTermMethod != null)),
            'Either both fromLiteralTermMethod or toLiteralTermMethod must be provided, or none of them.');

  @override
  int get hashCode => Object.hash(
      super.hashCode, fromLiteralTermMethod, toLiteralTermMethod, datatype);

  @override
  bool operator ==(Object other) {
    if (other is! RdfLiteralInfo) {
      return false;
    }
    return super == other &&
        fromLiteralTermMethod == other.fromLiteralTermMethod &&
        toLiteralTermMethod == other.toLiteralTermMethod &&
        datatype == other.datatype;
  }

  @override
  String toString() {
    return 'RdfLiteralInfo{'
        'registerGlobally: $registerGlobally, '
        'mapper: $mapper, '
        'fromLiteralTermMethod: $fromLiteralTermMethod, '
        'toLiteralTermMethod: $toLiteralTermMethod, '
        'datatype: $datatype}';
  }
}

class RdfGlobalResourceInfo extends RdfResourceInfo<GlobalResourceMapper> {
  final IriStrategyInfo? iri;
  const RdfGlobalResourceInfo(
      {required super.classIri,
      required this.iri,
      required super.registerGlobally,
      super.direction,
      required super.mapper});

  @override
  int get hashCode => Object.hash(super.hashCode, iri);

  @override
  bool operator ==(Object other) {
    if (other is! RdfGlobalResourceInfo) {
      return false;
    }
    return super == other && iri == other.iri;
  }

  @override
  String toString() {
    return 'RdfGlobalResourceInfo{'
        'classIri: $classIri, '
        'iri: $iri, '
        'registerGlobally: $registerGlobally, '
        'direction: $direction, '
        'mapper: $mapper}';
  }
}

class RdfLocalResourceInfo extends RdfResourceInfo<GlobalResourceMapper> {
  const RdfLocalResourceInfo(
      {required super.classIri,
      required super.registerGlobally,
      super.direction,
      required super.mapper});

  @override
  // ignore: unnecessary_overrides
  int get hashCode => super.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! RdfLocalResourceInfo) {
      return false;
    }
    return super == other;
  }

  @override
  String toString() {
    return 'RdfLocalResourceInfo{'
        'classIri: $classIri, '
        'registerGlobally: $registerGlobally, '
        'direction: $direction, '
        'mapper: $mapper}';
  }
}

/// Information about a constructor
class ConstructorInfo {
  /// The name of the constructor (empty string for default constructor)
  final String name;

  /// Whether this is a factory constructor
  final bool isFactory;

  /// Whether this is a const constructor
  final bool isConst;

  /// Whether this is the default constructor
  final bool isDefaultConstructor;

  /// List of parameters for this constructor
  final List<ParameterInfo> parameters;

  const ConstructorInfo({
    required this.name,
    required this.isFactory,
    required this.isConst,
    required this.isDefaultConstructor,
    required this.parameters,
  });

  @override
  int get hashCode => Object.hashAll(
      [name, isFactory, isConst, isDefaultConstructor, parameters]);

  @override
  bool operator ==(Object other) {
    if (other is! ConstructorInfo) {
      return false;
    }
    return name == other.name &&
        isFactory == other.isFactory &&
        isConst == other.isConst &&
        isDefaultConstructor == other.isDefaultConstructor &&
        parameters == other.parameters;
  }

  @override
  String toString() {
    return 'ConstructorInfo{\n'
        '  name: $name,\n'
        '  isFactory: $isFactory,\n'
        '  isConst: $isConst,\n'
        '  isDefaultConstructor: $isDefaultConstructor,\n'
        '  parameters: $parameters\n'
        '}';
  }
}

/// Information about a parameter
class ParameterInfo {
  /// The name of the parameter
  final String name;

  /// The type of the parameter as a string
  final Code type;

  /// Whether this parameter is required
  final bool isRequired;

  /// Whether this is a named parameter
  final bool isNamed;

  /// Whether this is a positional parameter
  final bool isPositional;

  /// Whether this parameter is optional
  final bool isOptional;

  /// The RDF property info associated with this parameter, if it maps to a field with @RdfProperty
  final RdfPropertyInfo? propertyInfo;

  /// Whether this parameter is an IRI part
  final bool isIriPart;

  /// The name of the IRI part variable
  final String? iriPartName;

  final bool isRdfValue;
  final bool isRdfLanguageTag;

  const ParameterInfo({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNamed,
    required this.isPositional,
    required this.isOptional,
    required this.propertyInfo,
    required this.isIriPart,
    required this.iriPartName,
    required this.isRdfValue,
    required this.isRdfLanguageTag,
  });

  @override
  int get hashCode => Object.hashAll([
        name,
        type,
        isRequired,
        isNamed,
        isPositional,
        isOptional,
        propertyInfo,
        isIriPart,
        iriPartName,
        isRdfValue,
        isRdfLanguageTag,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! ParameterInfo) {
      return false;
    }
    return name == other.name &&
        type == other.type &&
        isRequired == other.isRequired &&
        isNamed == other.isNamed &&
        isPositional == other.isPositional &&
        isOptional == other.isOptional &&
        propertyInfo == other.propertyInfo &&
        isIriPart == other.isIriPart &&
        iriPartName == other.iriPartName &&
        isRdfValue == other.isRdfValue &&
        isRdfLanguageTag == other.isRdfLanguageTag;
  }

  @override
  String toString() {
    return 'ParameterInfo{\n'
        '  name: $name,\n'
        '  type: $type,\n'
        '  isRequired: $isRequired,\n'
        '  isNamed: $isNamed,\n'
        '  isPositional: $isPositional,\n'
        '  isOptional: $isOptional,\n'
        '  propertyInfo: $propertyInfo\n'
        '}';
  }
}

// Marker interface
sealed class AnnotationInfo {
  const AnnotationInfo();
}

final class ProvidesAnnotationInfo extends AnnotationInfo {
  final String name;
  final String dartPropertyName;

  const ProvidesAnnotationInfo(
      {required this.name, required this.dartPropertyName});

  @override
  int get hashCode => Object.hash(name, dartPropertyName);

  @override
  bool operator ==(Object other) {
    if (other is! ProvidesAnnotationInfo) {
      return false;
    }
    return name == other.name && dartPropertyName == other.dartPropertyName;
  }

  @override
  String toString() {
    return 'ProvidesInfo{name: $name, dartPropertyName: $dartPropertyName}';
  }
}

final class RdfMapKeyAnnotationInfo extends AnnotationInfo {
  static const RdfMapKeyAnnotationInfo instance = RdfMapKeyAnnotationInfo._();

  const RdfMapKeyAnnotationInfo._();

  factory RdfMapKeyAnnotationInfo() => instance;

  @override
  String toString() {
    return 'RdfMapKeyAnnotationInfo';
  }
}

final class RdfMapValueAnnotationInfo extends AnnotationInfo {
  static const RdfMapValueAnnotationInfo instance =
      RdfMapValueAnnotationInfo._();

  const RdfMapValueAnnotationInfo._();

  factory RdfMapValueAnnotationInfo() => instance;

  @override
  String toString() {
    return 'RdfMapValueAnnotationInfo';
  }
}

final class RdfMapEntryAnnotationInfo extends AnnotationInfo {
  final Code itemType;
  final ClassElem itemClassElement;
  final DartType itemClassType;

  const RdfMapEntryAnnotationInfo(
      {required this.itemType,
      required this.itemClassElement,
      required this.itemClassType});

  @override
  int get hashCode => Object.hash(itemType, itemClassElement, itemClassType);

  @override
  bool operator ==(Object other) {
    if (other is! RdfMapEntryAnnotationInfo) {
      return false;
    }
    return itemType == other.itemType &&
        itemClassElement == other.itemClassElement &&
        itemClassType == other.itemClassType;
  }

  @override
  String toString() {
    return 'RdfMapEntryAnnotationInfo{itemType: $itemType, itemClassElement: $itemClassElement, itemClassType: $itemClassType}';
  }
}

final class RdfUnmappedTriplesAnnotationInfo extends AnnotationInfo {
  final bool globalUnmapped;

  const RdfUnmappedTriplesAnnotationInfo({this.globalUnmapped = false});

  factory RdfUnmappedTriplesAnnotationInfo.instance() =>
      const RdfUnmappedTriplesAnnotationInfo();

  @override
  String toString() {
    return 'RdfUnmappedTriplesAnnotationInfo(globalUnmapped: $globalUnmapped)';
  }

  @override
  int get hashCode => globalUnmapped.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! RdfUnmappedTriplesAnnotationInfo) {
      return false;
    }
    return globalUnmapped == other.globalUnmapped;
  }
}

/// Information about a property (field or getter/setter) in a class
class PropertyInfo {
  /// The name of the property
  final String name;

  /// The type of the property as a string
  final Code type;

  /// The type of the property as a string
  final Code typeNonNull;

  /// Whether this field is final
  final bool isFinal;

  /// Whether this field is late-initialized
  final bool isLate;

  /// Whether this field has an initializer
  final bool hasInitializer;

  /// Whether this property can be set (false for getter-only properties)
  final bool isSettable;

  /// Whether this is a static field
  final bool isStatic;

  /// Whether this is a synthetic field
  final bool isSynthetic;

  /// The IRI of the RDF property associated with this property, if any
  final RdfPropertyInfo? propertyInfo;

  /// Whether this property is required (non-nullable)
  final bool isRequired;

  final bool isRdfValue;
  final bool isRdfLanguageTag;

  final ProvidesAnnotationInfo? provides;
  final IriPartAnnotationInfo? iriPart;

  final RdfMapEntryAnnotationInfo? mapEntry;
  final RdfMapKeyAnnotationInfo? mapKey;
  final RdfMapValueAnnotationInfo? mapValue;
  final RdfUnmappedTriplesAnnotationInfo? unmappedTriples;

  const PropertyInfo({
    required this.name,
    required this.type,
    required Code? typeNonNull,
    required this.isFinal,
    required this.isLate,
    required this.hasInitializer,
    required this.isSettable,
    required this.isStatic,
    required this.isSynthetic,
    required this.isRdfValue,
    required this.isRdfLanguageTag,
    required this.provides,
    required this.iriPart,
    required this.propertyInfo,
    required this.isRequired, // = false,
    this.mapEntry,
    this.mapKey,
    this.mapValue,
    this.unmappedTriples,
  }) : typeNonNull = typeNonNull ?? type;

  @override
  int get hashCode => Object.hashAll([
        name,
        type,
        typeNonNull,
        isFinal,
        isLate,
        hasInitializer,
        isSettable,
        isStatic,
        isSynthetic,
        propertyInfo,
        isRequired,
        isRdfValue,
        isRdfLanguageTag,
        provides,
        mapEntry,
        mapKey,
        mapValue,
        unmappedTriples,
        iriPart,
      ]);

  @override
  bool operator ==(Object other) {
    if (other is! PropertyInfo) {
      return false;
    }
    return name == other.name &&
        type == other.type &&
        typeNonNull == other.typeNonNull &&
        isFinal == other.isFinal &&
        isLate == other.isLate &&
        hasInitializer == other.hasInitializer &&
        isSettable == other.isSettable &&
        isStatic == other.isStatic &&
        isSynthetic == other.isSynthetic &&
        propertyInfo == other.propertyInfo &&
        isRequired == other.isRequired &&
        isRdfValue == other.isRdfValue &&
        isRdfLanguageTag == other.isRdfLanguageTag &&
        provides == other.provides &&
        mapEntry == other.mapEntry &&
        mapKey == other.mapKey &&
        mapValue == other.mapValue &&
        unmappedTriples == other.unmappedTriples &&
        iriPart == other.iriPart;
  }

  @override
  String toString() {
    return 'FieldInfo{\n'
        '  name: $name,\n'
        '  type: $type,\n'
        '  typeNonNull: $typeNonNull,\n'
        '  isFinal: $isFinal,\n'
        '  isLate: $isLate,\n'
        '  isStatic: $isStatic,\n'
        '  isSynthetic: $isSynthetic,\n'
        '  propertyInfo: $propertyInfo,\n'
        '  isRequired: $isRequired\n'
        '  isRdfValue: $isRdfValue,\n'
        '  isRdfLanguageTag: $isRdfLanguageTag\n'
        '  provides: $provides\n'
        '  iriPart: $iriPart\n'
        '  mapEntry: $mapEntry\n'
        '  mapKey: $mapKey\n'
        '  mapValue: $mapValue\n'
        '  unmappedTriples: $unmappedTriples\n'
        '}';
  }
}

/// Contains information about an enum value and its serialized representation
class EnumValueInfo {
  /// The name of the enum constant
  final String constantName;

  /// The serialized value (either custom from @RdfEnumValue or the constant name)
  final String serializedValue;

  const EnumValueInfo({
    required this.constantName,
    required this.serializedValue,
  });

  @override
  int get hashCode => Object.hash(constantName, serializedValue);

  @override
  bool operator ==(Object other) {
    if (other is! EnumValueInfo) {
      return false;
    }
    return constantName == other.constantName &&
        serializedValue == other.serializedValue;
  }

  @override
  String toString() {
    return 'EnumValueInfo(constantName: $constantName, serializedValue: $serializedValue)';
  }
}

/// Contains information about a class annotated with @RdfGlobalResource
