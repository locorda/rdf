import 'package:locorda_rdf_mapper_generator/src/processors/broader_imports.dart';
import 'package:locorda_rdf_mapper_generator/src/processors/models/mapper_info.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/util.dart';

sealed class MappableClassMapperTemplateData {
  Map<String, dynamic> toMap();
  const MappableClassMapperTemplateData();
}

sealed class GeneratedMapperTemplateData
    extends MappableClassMapperTemplateData {
  /// The name of the Dart class being mapped
  final Code className;

  /// The name of the generated mapper class
  final Code mapperClassName;

  /// The name of the mapper interface
  final Code mapperInterfaceName;
  final MapperConstructorTemplateData mapperConstructor;
  final List<FieldData> mapperFields;

  /// Generic type parameters for the class (e.g., ['T', 'K', 'V'])
  final List<String> typeParameters;

  GeneratedMapperTemplateData({
    required this.className,
    required this.mapperClassName,
    required this.mapperInterfaceName,
    required this.mapperConstructor,
    required List<FieldData> mapperFields,
    this.typeParameters = const [],
  }) : mapperFields = mapperFields.toSet().toList(growable: false)
          ..sort(
            (a, b) => a.name.compareTo(b.name),
          );
}

class CustomMapperTemplateData implements MappableClassMapperTemplateData {
  final String? customMapperName;
  final Code mapperInterfaceType;
  final Code className;
  final bool isTypeBased;
  final Code? customMapperInstance;
  final bool registerGlobally;

  const CustomMapperTemplateData({
    required this.className,
    required this.mapperInterfaceType,
    required this.customMapperName,
    required this.isTypeBased,
    required this.customMapperInstance,
    required this.registerGlobally,
  }) : assert(
          customMapperName != null || customMapperInstance != null,
          'At least one of customMapperName or customMapperInstance must be provided',
        );

  @override
  Map<String, dynamic> toMap() {
    return {
      'className': className.toMap(),
      'mapperInterfaceType': mapperInterfaceType.toMap(),
      'customMapperName': customMapperName,
      'customMapperInstance': customMapperInstance?.toMap(),
      'hasCustomMapperName': customMapperName != null,
      'isTypeBased': isTypeBased,
      'hasCustomMapperInstance': customMapperInstance != null,
      'registerGlobally': registerGlobally,
    };
  }
}

/// Template data model for generating global resource mappers.
///
/// This class contains all the data needed to render the mustache template
/// for a global resource mapper class.
class ResourceMapperTemplateData extends GeneratedMapperTemplateData {
  final Code termClass;

  /// The type IRI expression (e.g., 'SchemaBook.classIri')
  final Code? typeIri;

  /// IRI strategy information
  final IriData? iriStrategy;

  /// List of parameters for this constructor
  final List<PropertyData> propertiesToDeserializeAsConstructorParameters;
  final List<PropertyData> propertiesToDeserializeAsFields;

  /// Property mapping information
  final List<PropertyData> propertiesToSerialize;

  final bool needsReader;

  /// Whether to register this mapper globally
  final bool registerGlobally;

  /// Mapper direction: 'serializeOnly', 'deserializeOnly', or null for both
  final SerializationDirection? direction;

  ResourceMapperTemplateData({
    required super.className,
    required super.mapperClassName,
    required super.mapperInterfaceName,
    required super.mapperConstructor,
    required super.mapperFields,
    super.typeParameters = const [],
    required this.termClass,
    required Code? typeIri,
    required IriData? iriStrategy,
    required List<PropertyData> propertiesToDeserializeAsConstructorParameters,
    required bool needsReader,
    required bool registerGlobally,
    required List<PropertyData> propertiesToSerialize,
    required List<PropertyData> propertiesToDeserializeAsFields,
    required this.direction,
  })  : typeIri = typeIri,
        iriStrategy = iriStrategy,
        propertiesToDeserializeAsConstructorParameters =
            propertiesToDeserializeAsConstructorParameters,
        propertiesToDeserializeAsFields = propertiesToDeserializeAsFields,
        needsReader = needsReader,
        registerGlobally = registerGlobally,
        propertiesToSerialize = propertiesToSerialize;

  /// Converts this template data to a Map for mustache rendering
  Map<String, dynamic> toMap() {
    final allProperties = [
      ...propertiesToDeserializeAsConstructorParameters,
      ...propertiesToDeserializeAsFields
    ];
    final hasUnmappedTriplesFields =
        allProperties.any((p) => p.isRdfUnmappedTriples);
    final hasUnmappedTriplesProperties =
        propertiesToSerialize.any((p) => p.isRdfUnmappedTriples);

    final needsDeserialization =
        direction != SerializationDirection.serializeOnly;
    final needsSerialization =
        direction != SerializationDirection.deserializeOnly;

    return {
      'className': className.toMap(),
      'mapperClassName': mapperClassName.toMap(),
      'mapperInterfaceName': mapperInterfaceName.toMap(),
      'termClass': termClass.toMap(),
      'typeIri': typeIri?.toMap(),
      'hasTypeIri': typeIri != null,
      'hasIriStrategy': iriStrategy != null,
      'iriStrategy': iriStrategy?.toMap(),
      'constructorParameters': toMustacheList(
          propertiesToDeserializeAsConstructorParameters
              .map((p) => p.toMap())
              .toList()),
      'nonConstructorFields': toMustacheList(
          propertiesToDeserializeAsFields.map((p) => p.toMap()).toList()),
      'constructorParametersOrOtherFields':
          toMustacheList(allProperties.map((p) => p.toMap()).toList()),
      'hasNonConstructorFields': propertiesToDeserializeAsFields.isNotEmpty,
      'hasUnmappedTriplesFields': hasUnmappedTriplesFields,
      'hasUnmappedTriplesProperties': hasUnmappedTriplesProperties,
      'properties': propertiesToSerialize.map((p) => p.toMap()).toList(),
      'mapperConstructor': mapperConstructor.toMap(),
      'mapperFields':
          toMustacheList(mapperFields.map((f) => f.toMap()).toList()),
      'hasMapperFields': mapperFields.isNotEmpty,
      'needsReader': needsReader,
      'registerGlobally': registerGlobally,
      'needsDeserialization': needsDeserialization,
      'needsSerialization': needsSerialization,
      // necessary for init file builder
      'direction': direction?.name,
    };
  }
}

class FieldData {
  final String name;
  final Code type;
  final bool isLate;
  final bool isFinal;

  FieldData(
      {required this.name,
      required this.type,
      required this.isLate,
      required this.isFinal});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.toMap(),
      'isLate': isLate,
      'isFinal': isFinal,
    };
  }

  @override
  String toString() {
    return 'FieldData{name: $name, type: $type, isLate: $isLate, isFinal: $isFinal}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FieldData &&
        other.name == name &&
        other.type == type &&
        other.isLate == isLate &&
        other.isFinal == isFinal;
  }

  @override
  int get hashCode {
    return name.hashCode ^ type.hashCode ^ isLate.hashCode ^ isFinal.hashCode;
  }
}

class ParameterAssignmentData {
  final String fieldName;
  final String parameterName;

  ParameterAssignmentData(
      {required this.fieldName, required this.parameterName});
  Map<String, dynamic> toMap() {
    return {
      'fieldName': fieldName,
      'parameterName': parameterName,
    };
  }

  @override
  int get hashCode => fieldName.hashCode ^ parameterName.hashCode;

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ParameterAssignmentData &&
        other.fieldName == fieldName &&
        other.parameterName == parameterName;
  }
}

class BodyAssignmentData {
  final String fieldName;
  final Code defaultValue;

  BodyAssignmentData({required this.fieldName, required this.defaultValue});
  Map<String, dynamic> toMap() {
    return {
      'fieldName': fieldName,
      'defaultValue': defaultValue.toMap(),
    };
  }

  @override
  int get hashCode => fieldName.hashCode ^ defaultValue.hashCode;

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BodyAssignmentData &&
        other.fieldName == fieldName &&
        other.defaultValue == defaultValue;
  }
}

class MapperConstructorTemplateData {
  /// The name of the generated mapper class
  final Code mapperClassName;

  /// The name of the mapper interface
  final List<ParameterAssignmentData> parameterAssignments;
  final List<BodyAssignmentData> bodyAssignments;
  final List<ConstructorParameterData> mapperConstructorParameters;
  final bool isConst;

  MapperConstructorTemplateData({
    required this.mapperClassName,
    required this.parameterAssignments,
    required this.bodyAssignments,
    required this.mapperConstructorParameters,
    required this.isConst,
  });

  /// Converts this template data to a Map for mustache rendering
  Map<String, dynamic> toMap() {
    return {
      'className': mapperClassName.toMap(),
      'isConst': isConst,
      'parameters': toMustacheList(
          mapperConstructorParameters.map((p) => p.toMap()).toList()),
      'hasParameters': mapperConstructorParameters.isNotEmpty,
      'parameterAssignments':
          toMustacheList(parameterAssignments.map((p) => p.toMap()).toList()),
      'hasParameterAssignments': parameterAssignments.isNotEmpty,
      'bodyAssignments':
          toMustacheList(bodyAssignments.map((p) => p.toMap()).toList()),
      'hasBodyAssignments': bodyAssignments.isNotEmpty,
    };
  }
}

class LiteralMapperTemplateData extends GeneratedMapperTemplateData {
  static final rdfLanguageDatatype = Code.combine([
    Code.type('Rdf', importUri: importRdfVocab),
    Code.value('.langString')
  ]).toMap();

  /// List of parameters for this constructor
  final List<PropertyData> constructorParameters;

  /// List of non-constructor fields that are RDF value or language tag fields
  final List<PropertyData> nonConstructorFields;

  /// Property mapping information
  final List<PropertyData> properties;

  /// Whether to register this mapper globally
  final bool registerGlobally;

  final Code? datatype;
  final Code? toLiteralTermMethodCall;
  final Code? fromLiteralTermMethodCall;
  final PropertyData? rdfValue;
  final PropertyData? rdfLanguageTag;

  /// Mapper direction: 'serializeOnly', 'deserializeOnly', or null for both
  final SerializationDirection? direction;

  LiteralMapperTemplateData({
    required super.className,
    required super.mapperClassName,
    required super.mapperInterfaceName,
    required super.mapperConstructor,
    required super.mapperFields,
    required this.datatype,
    required this.toLiteralTermMethodCall,
    required this.fromLiteralTermMethodCall,
    required this.rdfValue,
    required this.rdfLanguageTag,
    required List<PropertyData> constructorParameters,
    required List<PropertyData> nonConstructorFields,
    required bool registerGlobally,
    required List<PropertyData> properties,
    required this.direction,
  })  : constructorParameters = constructorParameters,
        nonConstructorFields = nonConstructorFields,
        registerGlobally = registerGlobally,
        properties = properties,
        super();

  /// Converts this template data to a Map for mustache rendering
  Map<String, dynamic> toMap() {
    final needsDeserialization =
        direction != SerializationDirection.serializeOnly;
    final needsSerialization =
        direction != SerializationDirection.deserializeOnly;

    return {
      'className': className.toMap(),
      'mapperClassName': mapperClassName.toMap(),
      'mapperInterfaceName': mapperInterfaceName.toMap(),
      'datatype': datatype?.toMap(),
      'toLiteralTermMethodCall': toLiteralTermMethodCall?.toMap(),
      'fromLiteralTermMethodCall': fromLiteralTermMethodCall?.toMap(),
      'hasDatatype': datatype != null,
      'hasMethods':
          toLiteralTermMethodCall != null && fromLiteralTermMethodCall != null,
      'constructorParameters':
          toMustacheList(constructorParameters.map((p) => p.toMap()).toList()),
      'nonConstructorFields':
          toMustacheList(nonConstructorFields.map((p) => p.toMap()).toList()),
      'hasNonConstructorFields': nonConstructorFields.isNotEmpty,
      'constructorParametersOrOtherFields': toMustacheList([
        ...constructorParameters,
        ...nonConstructorFields
      ].map((p) => p.toMap()).toList()),
      'mapperConstructor': mapperConstructor.toMap(),
      'mapperFields':
          toMustacheList(mapperFields.map((f) => f.toMap()).toList()),
      'hasMapperFields': mapperFields.isNotEmpty,
      'properties': properties.map((p) => p.toMap()).toList(),
      'registerGlobally': registerGlobally,
      'rdfValue': rdfValue?.toMap(),
      'hasRdfValue': rdfValue != null,
      'rdfLanguageTag': rdfLanguageTag?.toMap(),
      'hasRdfLanguageTag': rdfLanguageTag != null,
      'rdfLanguageDatatype': rdfLanguageDatatype,
      'hasCustomDatatype': datatype != null || rdfLanguageTag != null,
      'needsDeserialization': needsDeserialization,
      'needsSerialization': needsSerialization,
      // necessary for init file builder
      'direction': direction?.name,
    };
  }
}

class IriMapperTemplateData extends GeneratedMapperTemplateData {
  /// IRI strategy information
  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<VariableNameData> propertyVariables;

  final Set<DependencyUsingVariableData> contextVariables;

  /// The regex pattern built from the template.
  final String regexPattern;

  /// The template converted to Dart string interpolation syntax.
  final String interpolatedTemplate;
  final String? interpolatedFragmentTemplate;

  /// List of parameters for this constructor
  final List<PropertyData> constructorParameters;

  /// List of non-constructor fields that are IRI parts
  final List<PropertyData> nonConstructorFields;

  /// Whether to register this mapper globally
  final bool registerGlobally;

  final VariableNameData? singleMappedValue;

  /// Mapper direction: 'serializeOnly', 'deserializeOnly', or null for both
  final SerializationDirection? direction;

  IriMapperTemplateData({
    required super.className,
    required super.mapperClassName,
    required super.mapperInterfaceName,
    required super.mapperConstructor,
    required super.mapperFields,
    required this.interpolatedTemplate,
    required this.interpolatedFragmentTemplate,
    required this.propertyVariables,
    required this.regexPattern,
    required this.constructorParameters,
    required this.nonConstructorFields,
    required this.registerGlobally,
    required this.contextVariables,
    this.singleMappedValue,
    required this.direction,
  });

  /// Converts this template data to a Map for mustache rendering
  Map<String, dynamic> toMap() {
    final needsDeserialization =
        direction != SerializationDirection.serializeOnly;
    final needsSerialization =
        direction != SerializationDirection.deserializeOnly;

    return {
      'className': className.toMap(),
      'mapperClassName': mapperClassName.toMap(),
      'mapperInterfaceName': mapperInterfaceName.toMap(),
      'regexPattern': regexPattern,
      'interpolatedTemplate': interpolatedTemplate,
      'hasInterpolatedFragmentTemplate': interpolatedFragmentTemplate != null,
      'interpolatedFragmentTemplate': interpolatedFragmentTemplate,
      'propertyVariables':
          toMustacheList(propertyVariables.map((e) => e.toMap()).toList()),
      'constructorParameters':
          toMustacheList(constructorParameters.map((p) => p.toMap()).toList()),
      'nonConstructorFields':
          toMustacheList(nonConstructorFields.map((p) => p.toMap()).toList()),
      'hasNonConstructorFields': nonConstructorFields.isNotEmpty,
      'constructorParametersOrOtherFields': toMustacheList([
        ...constructorParameters,
        ...nonConstructorFields
      ].map((p) => p.toMap()).toList()),
      'contextVariables':
          toMustacheList(contextVariables.map((p) => p.toMap()).toList()),
      'hasContextVariables': contextVariables.isNotEmpty,
      'mapperConstructor': mapperConstructor.toMap(),
      'mapperFields':
          toMustacheList(mapperFields.map((f) => f.toMap()).toList()),
      'hasMapperFields': mapperFields.isNotEmpty,
      'registerGlobally': registerGlobally,
      'singleMappedValue': singleMappedValue?.toMap(),
      'hasSingleMappedValue': singleMappedValue != null,
      'needsDeserialization': needsDeserialization,
      'needsSerialization': needsSerialization,
      // necessary for init file builder
      'direction': direction?.name,
    };
  }
}

/// Template data for the entire generated file.
///
/// This contains the file header, all imports, and all mapper classes.
class FileTemplateData {
  /// Header information with source path and generation timestamp
  final FileHeaderData header;

  final BroaderImports broaderImports;

  final Map<String, String> originalImports;

  /// All generated mapper classes
  final List<MapperData> mappers;

  final String mapperFileImportUri;
  const FileTemplateData({
    required this.header,
    required this.broaderImports,
    required this.originalImports,
    required this.mappers,
    required this.mapperFileImportUri,
  });

  /// Converts this template data to a Map for mustache rendering
  Map<String, dynamic> toMap() {
    return {
      'header': header.toMap(),
      'broaderImports': broaderImports.toMap(),
      'originalImports': originalImports,
      'mappers': mappers.map((m) => m.toMap()).toList(),
      'mapperFileImportUri': mapperFileImportUri,
    };
  }
}

/// Template data for file header information.
class FileHeaderData {
  final String sourcePath;
  final String generatedOn;

  const FileHeaderData({
    required this.sourcePath,
    required this.generatedOn,
  });

  Map<String, dynamic> toMap() => {
        'sourcePath': sourcePath,
        'generatedOn': generatedOn,
      };
}

/// Template data for a single mapper class.
class MapperData {
  final MappableClassMapperTemplateData mapperData;

  const MapperData(this.mapperData);

  Map<String, dynamic> toMap() {
    return {
      '__type__': mapperData.runtimeType.toString(),
      ...mapperData.toMap(),
    };
  }
}

/// Data for import statements
class ImportData {
  final String import;

  const ImportData(this.import);

  Map<String, dynamic> toMap() => {'import': import};
}

/// Data for context variable providers required by the mapper
class ContextProviderData {
  /// The name of the context variable
  final String variableName;

  /// The name of the private field that stores the provider
  final String privateFieldName;

  /// The name of the constructor parameter
  final String parameterName;

  /// The placeholder pattern to replace in IRI templates (e.g., '{baseUri}')
  final String placeholder;

  final bool isField;
  final Code type;
  const ContextProviderData(
      {required this.variableName,
      required this.privateFieldName,
      required this.parameterName,
      required this.placeholder,
      this.isField = true,
      this.type = const Code.literal('String Function()')});

  Map<String, dynamic> toMap() => {
        'variableName': variableName,
        'privateFieldName': privateFieldName,
        'parameterName': parameterName,
        'placeholder': placeholder,
        'isField': isField,
        'type': type.toMap()
      };
}

class VariableNameData {
  final String variableName;
  final String placeholder;
  final bool isString;
  final bool isMappedValue;

  const VariableNameData({
    required this.variableName,
    required this.placeholder,
    required this.isString,
    required this.isMappedValue,
  });

  Map<String, dynamic> toMap() => {
        'variableName': variableName,
        'placeholder': placeholder,
        'isString': isString,
        'isMappedValue': isMappedValue,
      };
}

class DependencyUsingVariableData {
  final String variableName;
  final Code code;

  const DependencyUsingVariableData({
    required this.variableName,
    required this.code,
  });

  Map<String, dynamic> toMap() => {
        'variableName': variableName,
        'code': code.toMap(),
      };

  @override
  String toString() {
    return 'DependencyUsingVariableData{variableName: $variableName, code: $code}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DependencyUsingVariableData &&
        other.variableName == variableName &&
        other.code == code;
  }

  @override
  int get hashCode {
    return variableName.hashCode ^ code.hashCode;
  }
}

class IriTemplateData {
  /// The original template string.
  final String template;

  /// All variables found in the template.
  final Set<VariableNameData> variables;

  /// Variables that correspond to class properties with @RdfIriPart.
  final Set<VariableNameData> propertyVariables;

  /// Variables that need to be provided from context.
  final Set<DependencyUsingVariableData> contextVariables;

  /// The regex pattern built from the template.
  final String regexPattern;

  /// The template converted to Dart string interpolation syntax.
  final String interpolatedTemplate;

  /// The fragment template converted to Dart string interpolation syntax (optional).
  final String? interpolatedFragmentTemplate;

  /// Whether this template has a fragment component.
  bool get hasFragment => interpolatedFragmentTemplate != null;

  const IriTemplateData({
    required this.template,
    required this.variables,
    required this.propertyVariables,
    required this.contextVariables,
    required this.regexPattern,
    required this.interpolatedTemplate,
    this.interpolatedFragmentTemplate,
  });

  Map<String, dynamic> toMap() {
    return {
      'template': template,
      'variables': toMustacheList(variables.map((v) => v.toMap()).toList()),
      'propertyVariables':
          toMustacheList(propertyVariables.map((p) => p.toMap()).toList()),
      'contextVariables':
          toMustacheList(contextVariables.map((c) => c.toMap()).toList()),
      'regexPattern': regexPattern,
      'interpolatedTemplate': interpolatedTemplate,
      'hasInterpolatedFragmentTemplate': interpolatedFragmentTemplate != null,
      'interpolatedFragmentTemplate': interpolatedFragmentTemplate,
      'hasFragment': hasFragment,
    };
  }
}

class IriPartData {
  final String name;
  final String dartPropertyName;
  final bool isRdfProperty;

  const IriPartData({
    required this.name,
    required this.dartPropertyName,
    required this.isRdfProperty,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'dartPropertyName': dartPropertyName,
        'isRdfProperty': isRdfProperty,
      };
}

/// Data for IRI strategy
class IriData {
  final IriTemplateData? template;
  final bool hasFullIriPartTemplate;

  final bool hasMapper;
  final List<IriPartData> iriMapperParts;

  const IriData({
    this.template,
    required this.hasFullIriPartTemplate,
    this.hasMapper = false,
    required this.iriMapperParts,
  });

  bool get hasTemplate => template != null;

  Map<String, dynamic> toMap() => {
        'template': template?.toMap(),
        'hasTemplate': hasTemplate,
        'hasMapper': hasMapper,
        'iriMapperParts':
            toMustacheList(iriMapperParts.map((p) => p.toMap()).toList()),
        'hasIriMapperParts': iriMapperParts.isNotEmpty,
        'requiresIriParsing': !hasFullIriPartTemplate &&
            iriMapperParts
                .any((p) => !p.isRdfProperty && p.dartPropertyName.isNotEmpty),
        'hasFullIriPartTemplate': hasFullIriPartTemplate
      };
}

class ConstructorParameterData {
  final Code type;
  final String parameterName;
  final Code? defaultValue;
  final Code initFunctionParameterType;
  final String initFunctionParameterName;
  final Code initFunctionParameterCode;

  ConstructorParameterData(
      {required this.type,
      required this.parameterName,
      required this.defaultValue})
      : initFunctionParameterType = type,
        initFunctionParameterName = parameterName,
        initFunctionParameterCode = Code.literal(parameterName);

  ConstructorParameterData.full(
      {required this.type,
      required this.parameterName,
      required this.defaultValue,
      required this.initFunctionParameterType,
      required this.initFunctionParameterName,
      required this.initFunctionParameterCode});

  Map<String, dynamic> toMap() => {
        'type': type.toMap(),
        'parameterName': parameterName,
        'defaultValue': defaultValue?.toMap(),
        'hasDefaultValue': defaultValue != null,
        'initFunctionParameterType': initFunctionParameterType.toMap(),
        'initFunctionParameterName': initFunctionParameterName,
        'initFunctionParameterCode': initFunctionParameterCode.toMap(),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ConstructorParameterData &&
        other.type == type &&
        other.parameterName == parameterName &&
        other.defaultValue == defaultValue;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        parameterName.hashCode ^
        (defaultValue?.hashCode ?? 0);
  }
}

/// Data for RDF properties
class PropertyData {
  final String propertyName; // not in ParameterData
  final bool isFieldNullable;
  final bool isRdfProperty;
  final bool isIriPart;
  final bool isRdfValue;
  final bool isRdfLanguageTag;
  final bool isRdfMapEntry;
  final bool isRdfMapKey;
  final bool isRdfMapValue;
  final bool isRdfUnmappedTriples;

  final String? iriPartName;
  final String? name; // constructorParameterName
  final bool isNamed; // isNamedConstructorParameter
  final Code? defaultValue;
  final bool hasDefaultValue;
  final Code dartType;

  final Code? readerCall;
  final Code? builderCall;

  const PropertyData({
    required this.propertyName,
    required this.isFieldNullable,
    required this.isRdfProperty,
    required this.isRdfMapEntry,
    required this.isRdfMapKey,
    required this.isRdfMapValue,
    required this.isRdfUnmappedTriples,
    required this.isIriPart,
    required this.isRdfValue,
    required this.isRdfLanguageTag,
    required this.iriPartName,
    required this.name,
    required this.isNamed,
    required this.defaultValue,
    required this.hasDefaultValue,
    required this.dartType,
    required this.readerCall,
    required this.builderCall,
  });

  bool get isConstructorParameter => (name ?? '').isNotEmpty;

  Map<String, dynamic> toMap() => {
        'isRequired': !(isFieldNullable || hasDefaultValue),
        'isRdfProperty': isRdfProperty,
        'isIriPart': isIriPart && !isRdfProperty,
        'isRdfValue': isRdfValue,
        'isRdfLanguageTag': isRdfLanguageTag,
        'isRdfUnmappedTriples': isRdfUnmappedTriples,
        'iriPartName': iriPartName,
        'name': (name ?? '').isNotEmpty ? name : propertyName,
        'isNamed': isNamed,
        'defaultValue': defaultValue?.toMap(),
        'hasDefaultValue': hasDefaultValue,
        'dartType': dartType.toMap(),
        'hasReaderCall': readerCall != null,
        'readerCall': readerCall?.toMap(),
        'hasBuilderCall': builderCall != null,
        'builderCall': builderCall?.toMap(),
      };
}

/// Template data for generating enum literal mappers.
///
/// This class contains all data needed to render mustache templates
/// for enum mappers annotated with @RdfLiteral.
class EnumLiteralMapperTemplateData extends GeneratedMapperTemplateData {
  /// The datatype for literal serialization
  final Code? datatype;

  /// List of enum values with their serialization mappings
  final List<Map<String, dynamic>> enumValues;

  /// Whether to register this mapper globally
  final bool registerGlobally;

  final String? fromLiteralTermMethod;
  final String? toLiteralTermMethod;

  /// Mapper direction: 'serializeOnly', 'deserializeOnly', or null for both
  final SerializationDirection? direction;

  EnumLiteralMapperTemplateData({
    required super.className,
    required super.mapperClassName,
    required super.mapperInterfaceName,
    required super.mapperConstructor,
    required super.mapperFields,
    required this.datatype,
    required this.enumValues,
    required this.registerGlobally,
    required this.fromLiteralTermMethod,
    required this.toLiteralTermMethod,
    required this.direction,
  }) : super();

  @override
  Map<String, dynamic> toMap() {
    final needsDeserialization =
        direction != SerializationDirection.serializeOnly;
    final needsSerialization =
        direction != SerializationDirection.deserializeOnly;

    return {
      'className': className.toMap(),
      'mapperClassName': mapperClassName.toMap(),
      'mapperInterfaceName': mapperInterfaceName.toMap(),
      'datatype': datatype?.toMap(),
      'hasDatatype': datatype != null,
      'enumValues': toMustacheList(enumValues),
      'registerGlobally': registerGlobally,
      'fromLiteralTermMethod': fromLiteralTermMethod,
      'toLiteralTermMethod': toLiteralTermMethod,
      'mapperConstructor': mapperConstructor.toMap(),
      'mapperFields':
          toMustacheList(mapperFields.map((f) => f.toMap()).toList()),
      'hasMapperFields': mapperFields.isNotEmpty,
      'needsDeserialization': needsDeserialization,
      'needsSerialization': needsSerialization,
      // necessary for init file builder
      'direction': direction?.name,
    };
  }
}

/// Template data for generating enum IRI mappers.
///
/// This class contains all data needed to render mustache templates
/// for enum mappers annotated with @RdfIri.
class EnumIriMapperTemplateData extends GeneratedMapperTemplateData {
  /// Regex pattern for deserialization
  final String? regexPattern;

  /// Interpolated template for serialization
  final String? interpolatedTemplate;
  final String? interpolatedFragmentTemplate;

  /// List of enum values with their serialization mappings
  final List<Map<String, dynamic>> enumValues;

  /// Whether to register this mapper globally
  final bool registerGlobally;

  /// Whether this uses a full IRI part template (no regex parsing needed)
  final bool requiresIriParsing;

  final Set<DependencyUsingVariableData> contextVariables;

  /// Mapper direction: 'serializeOnly', 'deserializeOnly', or null for both
  final SerializationDirection? direction;

  EnumIriMapperTemplateData({
    required super.className,
    required super.mapperClassName,
    required super.mapperInterfaceName,
    required super.mapperConstructor,
    required super.mapperFields,
    required this.regexPattern,
    required this.interpolatedTemplate,
    required this.interpolatedFragmentTemplate,
    required this.enumValues,
    required this.registerGlobally,
    required this.requiresIriParsing,
    required this.contextVariables,
    required this.direction,
  });

  @override
  Map<String, dynamic> toMap() {
    final needsDeserialization =
        direction != SerializationDirection.serializeOnly;
    final needsSerialization =
        direction != SerializationDirection.deserializeOnly;

    return {
      'className': className.toMap(),
      'mapperClassName': mapperClassName.toMap(),
      'mapperInterfaceName': mapperInterfaceName.toMap(),
      'regexPattern': regexPattern,
      'interpolatedTemplate': interpolatedTemplate,
      'hasInterpolatedFragmentTemplate': interpolatedFragmentTemplate != null,
      'interpolatedFragmentTemplate': interpolatedFragmentTemplate,
      'enumValues': toMustacheList(enumValues),
      'contextVariables':
          toMustacheList(contextVariables.map((c) => c.toMap()).toList()),
      'hasContextVariables': contextVariables.isNotEmpty,
      'registerGlobally': registerGlobally,
      'requiresIriParsing': requiresIriParsing,
      'mapperConstructor': mapperConstructor.toMap(),
      'mapperFields':
          toMustacheList(mapperFields.map((f) => f.toMap()).toList()),
      'hasMapperFields': mapperFields.isNotEmpty,
      'needsDeserialization': needsDeserialization,
      'needsSerialization': needsSerialization,
      // necessary for init file builder
      'direction': direction?.name,
    };
  }
}
