// ignore_for_file: unnecessary_type_check, unreachable_switch_case, dead_code
// ignore_for_file: deprecated_member_use

import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';

import 'analyzer_v6.dart' as v6;

class DartTypeV6 extends DartType {
  final v6.DartType dartType;

  DartTypeV6(this.dartType);

  bool get isNullable =>
      dartType.isDartCoreNull ||
      (dartType is v6.InterfaceType && dartType.isDartCoreNull) ||
      (dartType.element?.library?.typeSystem.isNullable(dartType) ?? false);

  get typeArguments => (dartType is v6.InterfaceType
          ? (dartType as v6.InterfaceType).typeArguments
          : [])
      .map((t) => DartTypeV6(t))
      .toList(growable: false);

  bool get isInterfaceType => dartType is v6.InterfaceType;

  bool get isDartCoreNull => dartType.isDartCoreNull;

  bool get isDartCoreIterable => dartType.isDartCoreIterable;

  @override
  bool get isElementClass => dartType.element is v6.ClassElement;

  @override
  bool get isElementEnum => dartType.element is v6.EnumElement;

  Elem get element {
    final elem = dartType.element!;
    if (elem is v6.ClassElement) {
      return ClassElemV6(elem);
    } else if (elem is v6.EnumElement) {
      return EnumElemV6(elem);
    } else if (elem is v6.LibraryElement) {
      return LibraryElemV6(elem);
    } else if (elem is v6.FieldElement) {
      return FieldElemV6(elem);
    } else if (elem is v6.ConstructorElement) {
      return ConstructorElemV6(elem);
    } else if (elem is v6.ParameterElement) {
      return FormalParameterElemV6(elem);
    } else {
      throw ArgumentError(
          'Unsupported DartType element: ${dartType.element.runtimeType}');
    }
  }

  @override
  String getDisplayString() {
    return dartType.getDisplayString(withNullability: false) +
        (isNullable ? '?' : '');
  }

  @override
  Code toCode({bool enforceNonNull = false, bool raw = false}) {
    return _typeToCode(dartType, enforceNonNull: enforceNonNull, raw: raw);
  }

  @override
  DartType? get superclass {
    if (dartType case final v6.InterfaceType interfaceType) {
      if (interfaceType.superclass != null) {
        return DartTypeV6(interfaceType.superclass!);
      }
    }
    return null;
  }

  @override
  List<DartType> get mixins {
    if (dartType case final v6.InterfaceType interfaceType) {
      return interfaceType.mixins
          .map((mixin) => DartTypeV6(mixin))
          .toList(growable: false);
    }
    return const [];
  }

  @override
  List<DartType> get interfaces {
    if (dartType case final v6.InterfaceType interfaceType) {
      return interfaceType.interfaces
          .map((mixin) => DartTypeV6(mixin))
          .toList(growable: false);
    }
    return const [];
  }

  @override
  List<DartType> get allSupertypes {
    return [if (superclass != null) superclass!, ...mixins, ...interfaces];
  }
}

class FieldElemV6 extends ElemV6 implements FieldElem {
  final v6.FieldElement fieldElement;

  FieldElemV6(this.fieldElement) : super(fieldElement);

  @override
  bool get isStatic => fieldElement.isStatic;

  @override
  bool get isSynthetic => fieldElement.isSynthetic;

  @override
  bool get isFinal => fieldElement.isFinal;

  @override
  bool get isLate => fieldElement.isLate;

  @override
  bool get hasInitializer => fieldElement.hasInitializer;

  @override
  DartType get type {
    return DartTypeV6(fieldElement.type);
  }

  @override
  String get name => fieldElement.name;

  @override
  Iterable<ElemAnnotation> get annotations =>
      fieldElement.metadata.map((a) => ElemAnnotationV6(a));
}

class VariableElemV6 extends ElemV6 implements VariableElem {
  final v6.VariableElement variableElement;

  VariableElemV6(this.variableElement) : super(variableElement);

  @override
  String get name => variableElement.name;
}

class DartObjectV6 implements DartObject {
  final v6.DartObject dartObject;

  DartObjectV6(this.dartObject);

  DartType? get type {
    var typeValue = dartObject.type;
    return typeValue == null ? null : DartTypeV6(typeValue);
  }

  VariableElem? get variable {
    var r = dartObject.variable;
    return r == null ? null : VariableElemV6(r);
  }

  bool get hasKnownValue {
    return dartObject.hasKnownValue;
  }

  @override
  DartObject? getField(String name) {
    final r = dartObject.getField(name);
    return r == null ? null : DartObjectV6(r);
  }

  String? toStringValue() {
    return dartObject.toStringValue();
  }

  @override
  bool get isNull => dartObject.isNull;

  @override
  bool? toBoolValue() {
    return dartObject.toBoolValue();
  }

  @override
  int? toIntValue() {
    return dartObject.toIntValue();
  }

  @override
  Code toCode() {
    return _toCode(dartObject);
  }

  DartType? toTypeValue() {
    var typeValue = dartObject.toTypeValue();
    return typeValue == null ? null : DartTypeV6(typeValue);
  }

  String toString() {
    return dartObject.toString();
  }
}

class ElemAnnotationV6 implements ElemAnnotation {
  final v6.ElementAnnotation annotation;

  ElemAnnotationV6(this.annotation);

  DartObject? computeConstantValue() {
    final r = annotation.computeConstantValue();
    return r == null ? null : DartObjectV6(r);
  }
}

class LibraryElemV6 extends ElemV6 implements LibraryElem {
  final v6.LibraryElement libraryElement;

  LibraryElemV6(this.libraryElement) : super(libraryElement);

  String get name => libraryElement.name;

  String get identifier => libraryElement.identifier;
  Uri? get uri => libraryElement.source.uri;

  Iterable<String> get exportDefinedNames =>
      libraryElement.exportNamespace.definedNames.keys;

  Iterable<LibraryImport> get libraryImports =>
      libraryElement.definingCompilationUnit.libraryImports
          .map((libImport) => LibraryImportV6(libImport))
          .toList(growable: false);

  Iterable<LibraryElem> get importedLibraries =>
      libraryElement.importedLibraries.map((lib) => LibraryElemV6(lib));

  Iterable<LibraryElem> get exportedLibraries =>
      libraryElement.exportedLibraries.map((lib) => LibraryElemV6(lib));

  Iterable<ClassElem> get classes => libraryElement.units
      .expand((unit) => unit.classes)
      .map((c) => ClassElemV6(c));

  Iterable<EnumElem> get enums => libraryElement.units
      .expand((unit) => unit.enums)
      .map((e) => EnumElemV6(e));

  ClassElem? getClass(String className) {
    var r = libraryElement.getClass(className);
    return r == null ? null : ClassElemV6(r);
  }
}

class LibraryImportV6 implements LibraryImport {
  final v6.LibraryImportElement libraryImport;

  String? get libraryIdentifier => libraryImport.importedLibrary?.identifier;
  Uri? get uri => libraryImport.importedLibrary?.source.uri;
  String? get prefix => libraryImport.prefix?.element.name;

  LibraryImportV6(this.libraryImport);
}

abstract class ElemV6 implements Elem {
  final v6.Element element;

  String get name => element.name!;

  String? get libraryIdentifier => element.library?.identifier;
  Uri? get libraryUri => element.library?.source.uri;

  Iterable<LibraryImport> get libraryImports =>
      (element.library?.definingCompilationUnit.libraryImports ?? [])
          .map((libImport) => LibraryImportV6(libImport));

  ElemV6(this.element);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ElemV6) return false;
    return element == other.element;
  }

  @override
  int get hashCode => element.hashCode;
}

class GetterElemV6 extends ElemV6 implements GetterElem {
  final v6.PropertyAccessorElement getterElement;

  GetterElemV6(this.getterElement) : super(getterElement);

  @override
  String get name => getterElement.name;

  @override
  bool get isStatic => getterElement.isStatic;

  @override
  DartType get type => DartTypeV6(getterElement.type);

  Iterable<ElemAnnotation> get annotations =>
      getterElement.metadata.map((a) => ElemAnnotationV6(a));
}

class SetterElemV6 extends ElemV6 implements SetterElem {
  final v6.PropertyAccessorElement setterElement;

  SetterElemV6(this.setterElement) : super(setterElement);

  @override
  String get name => setterElement.name;

  @override
  bool get isStatic => setterElement.isStatic;

  @override
  DartType get type => DartTypeV6(setterElement.type);

  Iterable<ElemAnnotation> get annotations =>
      setterElement.metadata.map((a) => ElemAnnotationV6(a));
}

class ClassElemV6 extends ElemV6 implements ClassElem {
  final v6.ClassElement classElement;

  Iterable<ConstructorElem> get constructors =>
      classElement.constructors.map((c) => ConstructorElemV6(c));

  Iterable<ElemAnnotation> get annotations =>
      classElement.metadata.map((a) => ElemAnnotationV6(a));

  Iterable<FieldElem> get fields => classElement.fields
      .where((f) => !f.isSynthetic)
      .map((f) => FieldElemV6(f));

  FieldElem? getField(String fieldName) {
    var r = classElement.getField(fieldName);
    return r == null ? null : FieldElemV6(r);
  }

  @override
  Iterable<GetterElem> get getters => classElement.accessors
      .where((a) => a.isGetter && !a.isSynthetic)
      .map((g) => GetterElemV6(g));

  Iterable<SetterElem> get setters => classElement.accessors
      .where((a) => a.isSetter && !a.isSynthetic)
      .map((s) => SetterElemV6(s));

  @override
  bool get hasTypeParameters => classElement.typeParameters.isNotEmpty;

  @override
  List<String> get typeParameterNames =>
      classElement.typeParameters.map((tp) => tp.name).toList();

  ClassElemV6(this.classElement) : super(classElement);

  @override
  Code toCode() {
    return _classToCode(classElement);
  }
}

class EnumElemV6 extends ElemV6 implements EnumElem {
  final v6.EnumElement enumElement;
  Iterable<ElemAnnotation> get annotations =>
      enumElement.metadata.map((a) => ElemAnnotationV6(a));

  EnumElemV6(this.enumElement) : super(enumElement);

  Iterable<FieldElem> get constants => enumElement.fields
      .where((f) => f.isEnumConstant)
      .map((c) => FieldElemV6(c));

  @override
  Code toCode() {
    return _enumToCode(enumElement);
  }
}

class FormalParameterElemV6 extends ElemV6 implements FormalParameterElem {
  final v6.ParameterElement parameterElement;

  FormalParameterElemV6(this.parameterElement) : super(parameterElement);

  @override
  String get name => parameterElement.name;

  @override
  bool get isNamed => parameterElement.isNamed;

  @override
  bool get isRequired => parameterElement.isRequired;

  @override
  bool get isOptional => parameterElement.isOptional;

  @override
  bool get isPositional => parameterElement.isPositional;

  @override
  DartType get type => DartTypeV6(parameterElement.type);
}

class ConstructorElemV6 extends ElemV6 implements ConstructorElem {
  final v6.ConstructorElement constructorElement;

  ConstructorElemV6(this.constructorElement) : super(constructorElement);

  String get name => constructorElement.name;

  @override
  bool get isConst => constructorElement.isConst;
  @override
  bool get isFactory => constructorElement.isFactory;
  @override
  bool get isDefaultConstructor => constructorElement.isDefaultConstructor;
  @override
  String get displayName => constructorElement.displayName;

  Iterable<FormalParameterElem> get formalParameters =>
      constructorElement.parameters
          .map((p) => FormalParameterElemV6(p))
          .toList(growable: false);
}

Code _typeToCode(v6.DartType type,
    {bool enforceNonNull = false, bool raw = false}) {
  // Handle generics recursively to preserve import information for type arguments
  if (type is v6.InterfaceType && type.typeArguments.isNotEmpty) {
    final baseName = type.element.name ?? type.name ?? '';
    final baseImportUri = _getImportUriForType(type.element);
    
    // Recursively convert type arguments
    final typeArgCodes = type.typeArguments
        .map((arg) => _typeToCode(arg, enforceNonNull: false, raw: raw))
        .toList();
    
    // Build the complete generic type with Code.combine to preserve imports
    final baseCode = Code.type(baseName, importUri: baseImportUri);
    final genericParams = Code.genericParamsList(typeArgCodes);
    
    var result = Code.combine([baseCode, genericParams]);
    
    // Handle nullable types
    final isNullable =
        type.element?.library?.typeSystem.isNullable(type) ?? false;
    if (!enforceNonNull && isNullable) {
      result = Code.combine([result, Code.literal('?')]);
    }
    
    return result;
  }
  
  // Fallback for non-generic types
  var typeName = raw ? type.name : null;

  typeName ??= type.getDisplayString(withNullability: false);

  final isNullable =
      type.element?.library?.typeSystem.isNullable(type) ?? false;
  if (!enforceNonNull && isNullable) {
    typeName += '?';
  }
  final importUri = _getImportUriForType(type.element);
  return Code.type(typeName, importUri: importUri);
}

Code _enumToCode(v6.EnumElement type) {
  final typeName = type.name;
  final importUri = _getImportUriForType(type);
  return Code.type(typeName, importUri: importUri);
}

Code _classToCode(v6.ClassElement type) {
  final typeName = type.name;
  final importUri = _getImportUriForType(type);
  return Code.type(typeName, importUri: importUri);
}

/// Converts a DartObject to a Code instance with proper import tracking
///
/// This function analyzes a compile-time constant value and generates the
/// corresponding Dart code along with any necessary import dependencies.
Code _toCode(v6.DartObject? value) {
  if (value == null || value.isNull) {
    return Code.value('null');
  }

  if (value.type?.isDartCoreType == true) {
    return DartTypeV6(value.toTypeValue()!).toCode();
  }

  // Handle primitive types (no imports needed)
  if (value.type?.isDartCoreBool == true) {
    return Code.value(value.toBoolValue().toString());
  }
  if (value.type?.isDartCoreInt == true) {
    return Code.value(value.toIntValue().toString());
  }
  if (value.type?.isDartCoreDouble == true) {
    return Code.value(value.toDoubleValue().toString());
  }
  if (value.type?.isDartCoreString == true) {
    final str = value.toStringValue() ?? '';
    // Escape single quotes and wrap in single quotes
    return Code.value("'${str.replaceAll("'", "\\'")}'");
  }

  // Handle enums - these need import tracking
  if (value.type?.isDartCoreEnum == true) {
    final enumValue = value.getField('_name')?.toStringValue();
    final enumType = value.type!.getDisplayString(withNullability: false);
    if (enumValue != null) {
      final importUri = _getImportUriForType(value.type!.element);
      return Code.type('$enumType.$enumValue', importUri: importUri);
    }
  }

  // Handle lists
  if (value.type?.isDartCoreList == true) {
    final items = value.toListValue() ?? [];
    final itemCodes = items.map((item) => _toCode(item)).toList();
    final combinedCode = Code.combine(itemCodes, separator: ', ');
    return Code.combine([Code.value('['), combinedCode, Code.value(']')]);
  }

  // Handle maps
  if (value.type?.isDartCoreMap == true) {
    final map = value.toMapValue() ?? {};
    final entryCodes = map.entries.map((entry) {
      final keyCode = _toCode(entry.key);
      final valueCode = _toCode(entry.value);
      return Code.combine([keyCode, Code.value(': '), valueCode]);
    }).toList();
    final combinedEntries = Code.combine(entryCodes, separator: ', ');
    return Code.combine([Code.value('{'), combinedEntries, Code.value('}')]);
  }

  if (value.variable != null) {
    // Handle variables (e.g., const variables)
    final variable = value.variable!;
    final variableName = variable.name;
    final enclosingElement = variable.enclosingElement3;
    if (enclosingElement is v6.ClassElement &&
        variableName.isNotEmpty &&
        variable.isStatic) {
      return Code.combine(
          [_classToCode(enclosingElement), Code.literal('.$variableName')]);
    }
  }

  // Handle objects with const constructors (like custom mappers)
  var typeElement = value.type?.element;
  if (typeElement is v6.ClassElement) {
    for (final constructor in typeElement.constructors) {
      final fields = constructor.parameters;
      if (constructor.isConst) {
        final constructorName = constructor.displayName;
        final positionalArgCodes = <Code>[];
        final namedArgCodes = <Code>[];

        // Separate positional and named parameters
        for (final field in fields) {
          final fieldValue = value.getField(field.name);
          if (fieldValue != null) {
            final fieldCode = _toCode(fieldValue);

            if (field.isNamed) {
              // Named parameter: paramName: value
              namedArgCodes.add(
                  Code.combine([Code.value('${field.name}: '), fieldCode]));
            } else {
              // Positional parameter: just the value
              positionalArgCodes.add(fieldCode);
            }
          }
        }

        // Combine positional and named arguments
        final allArgCodes = <Code>[];
        allArgCodes.addAll(positionalArgCodes);
        allArgCodes.addAll(namedArgCodes);

        final importUri = _getImportUriForType(typeElement);

        return Code.combine([
          Code.literal('const '),
          Code.type(constructorName, importUri: importUri),
          Code.paramsList(allArgCodes)
        ]);
      }
    }
  }

  // Fallback to string representation if type is not recognized
  return Code.value(value.toStringValue() ?? '');
}

/// Determines the import URI for a given type element
String? _getImportUriForType(v6.Element? element) {
  if (element == null) return null;

  final source = element.library?.identifier;

  // No uri on library in analyzer v6
  final sourceUri = element.library?.source.uri;
  if (source == null || sourceUri == null) return null;

  return sourceUri.toString();
}
