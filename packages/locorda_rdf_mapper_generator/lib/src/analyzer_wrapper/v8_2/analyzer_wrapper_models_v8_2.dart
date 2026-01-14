// ignore_for_file: unnecessary_type_check, unreachable_switch_case, dead_code
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';

import 'analyzer_v8_2.dart' as v8;

class DartTypeV8 extends DartType {
  final v8.DartType dartType;

  DartTypeV8(this.dartType);

  bool get isNullable =>
      dartType.isDartCoreNull ||
      (dartType is v8.InterfaceType && dartType.isDartCoreNull) ||
      (dartType.element?.library?.typeSystem.isNullable(dartType) ?? false);

  get typeArguments => (dartType is v8.InterfaceType
          ? (dartType as v8.InterfaceType).typeArguments
          : [])
      .map((t) => DartTypeV8(t))
      .toList(growable: false);

  bool get isInterfaceType => dartType is v8.InterfaceType;

  bool get isDartCoreNull => dartType.isDartCoreNull;

  bool get isDartCoreIterable => dartType.isDartCoreIterable;

  @override
  bool get isElementClass => dartType.element is v8.ClassElement;

  @override
  bool get isElementEnum => dartType.element is v8.EnumElement;

  Elem get element {
    final elem = dartType.element!;
    if (elem is v8.ClassElement) {
      return ClassElemV8(elem);
    } else if (elem is v8.EnumElement) {
      return EnumElemV8(elem);
    } else if (elem is v8.LibraryElement) {
      return LibraryElemV8(elem);
    } else if (elem is v8.FieldElement) {
      return FieldElemV8(elem);
    } else if (elem is v8.ConstructorElement) {
      return ConstructorElemV8(elem);
    } else if (elem is v8.FormalParameterElement) {
      return FormalParameterElemV8(elem);
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
    if (dartType case final v8.InterfaceType interfaceType) {
      if (interfaceType.superclass != null) {
        return DartTypeV8(interfaceType.superclass!);
      }
    }
    return null;
  }

  @override
  List<DartType> get mixins {
    if (dartType case final v8.InterfaceType interfaceType) {
      return interfaceType.mixins
          .map((mixin) => DartTypeV8(mixin))
          .toList(growable: false);
    }
    return const [];
  }

  @override
  List<DartType> get interfaces {
    if (dartType case final v8.InterfaceType interfaceType) {
      return interfaceType.interfaces
          .map((mixin) => DartTypeV8(mixin))
          .toList(growable: false);
    }
    return const [];
  }

  @override
  List<DartType> get allSupertypes {
    return [if (superclass != null) superclass!, ...mixins, ...interfaces];
  }
}

class FieldElemV8 extends ElemV8 implements FieldElem {
  final v8.FieldElement fieldElement;

  FieldElemV8(this.fieldElement) : super(fieldElement);

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
    return DartTypeV8(fieldElement.type);
  }

  @override
  String get name => fieldElement.name!;

  @override
  Iterable<ElemAnnotation> get annotations =>
      fieldElement.metadata.annotations.map((a) => ElemAnnotationV8(a));
}

class VariableElemV8 extends ElemV8 implements VariableElem {
  final v8.VariableElement variableElement;

  VariableElemV8(this.variableElement) : super(variableElement);

  @override
  String get name => variableElement.name!;
}

class DartObjectV8 implements DartObject {
  final v8.DartObject dartObject;

  DartObjectV8(this.dartObject);

  DartType? get type {
    var typeValue = dartObject.type;
    return typeValue == null ? null : DartTypeV8(typeValue);
  }

  VariableElem? get variable {
    var r = dartObject.variable;
    return r == null ? null : VariableElemV8(r);
  }

  bool get hasKnownValue {
    return dartObject.hasKnownValue;
  }

  @override
  DartObject? getField(String name) {
    final r = dartObject.getField(name);
    return r == null ? null : DartObjectV8(r);
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
    return typeValue == null ? null : DartTypeV8(typeValue);
  }

  String toString() {
    return dartObject.toString();
  }
}

class ElemAnnotationV8 implements ElemAnnotation {
  final v8.ElementAnnotation annotation;

  ElemAnnotationV8(this.annotation);

  DartObject? computeConstantValue() {
    final r = annotation.computeConstantValue();
    return r == null ? null : DartObjectV8(r);
  }
}

class LibraryElemV8 extends ElemV8 implements LibraryElem {
  final v8.LibraryElement libraryElement;

  LibraryElemV8(this.libraryElement) : super(libraryElement);

  String get name => libraryElement.name!;

  String get identifier => libraryElement.identifier;
  Uri? get uri => libraryElement.uri;

  Iterable<String> get exportDefinedNames =>
      libraryElement.exportNamespace.definedNames2.keys;

  Iterable<LibraryImport> get libraryImports => libraryElement.fragments
      .expand((f) => f.libraryImports)
      .map((libImport) => LibraryImportV8(libImport))
      .toList(growable: false);

  Iterable<LibraryElem> get importedLibraries => libraryElement.fragments
      .expand((f) => f.importedLibraries)
      .map((lib) => LibraryElemV8(lib))
      .toList(growable: false);

  Iterable<LibraryElem> get exportedLibraries =>
      libraryElement.exportedLibraries
          .map((lib) => LibraryElemV8(lib))
          .toList(growable: false);

  Iterable<ClassElem> get classes => libraryElement.fragments
      .expand((f) => f.classes)
      .map((c) => c.element)
      .map((c) => ClassElemV8(c))
      .toList(growable: false);

  Iterable<EnumElem> get enums => libraryElement.fragments
      .expand((f) => f.enums)
      .map((e) => e.element)
      .map((e) => EnumElemV8(e))
      .toList(growable: false);

  ClassElem? getClass(String className) {
    var r = libraryElement.getClass(className);
    return r == null ? null : ClassElemV8(r);
  }
}

class LibraryImportV8 implements LibraryImport {
  final v8.LibraryImport libraryImport;

  String? get libraryIdentifier => libraryImport.importedLibrary?.identifier;
  Uri? get uri => libraryImport.importedLibrary?.uri;
  String? get prefix => libraryImport.prefix?.element.name;

  LibraryImportV8(this.libraryImport);
}

abstract class ElemV8 implements Elem {
  final v8.Element element;

  String get name => element.name!;

  String? get libraryIdentifier => element.library?.identifier;
  Uri? get libraryUri => element.library?.uri;

  Iterable<LibraryImport> get libraryImports =>
      (element.library?.fragments ?? [])
          .expand<v8.LibraryImport>((f) => f.libraryImports)
          .map((libImport) => LibraryImportV8(libImport));

  ElemV8(this.element);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ElemV8) return false;
    return element == other.element;
  }

  @override
  int get hashCode => element.hashCode;
}

class GetterElemV8 extends ElemV8 implements GetterElem {
  final v8.PropertyAccessorElement getterElement;

  GetterElemV8(this.getterElement) : super(getterElement);

  @override
  String get name => getterElement.name!;

  @override
  bool get isStatic => getterElement.isStatic;

  @override
  DartType get type => DartTypeV8(getterElement.type);

  Iterable<ElemAnnotation> get annotations =>
      getterElement.metadata.annotations.map((a) => ElemAnnotationV8(a));
}

class SetterElemV8 extends ElemV8 implements SetterElem {
  final v8.PropertyAccessorElement setterElement;

  SetterElemV8(this.setterElement) : super(setterElement);

  @override
  String get name => setterElement.name!;

  @override
  bool get isStatic => setterElement.isStatic;

  @override
  DartType get type => DartTypeV8(setterElement.type);

  Iterable<ElemAnnotation> get annotations =>
      setterElement.metadata.annotations.map((a) => ElemAnnotationV8(a));
}

class ClassElemV8 extends ElemV8 implements ClassElem {
  final v8.ClassElement classElement;

  Iterable<ConstructorElem> get constructors =>
      classElement.constructors.map((c) => ConstructorElemV8(c));

  Iterable<ElemAnnotation> get annotations =>
      classElement.metadata.annotations.map((a) => ElemAnnotationV8(a));

  Iterable<FieldElem> get fields => classElement.fields
      .where((f) => !f.isSynthetic)
      .map((f) => FieldElemV8(f));

  FieldElem? getField(String fieldName) {
    var r = classElement.getField(fieldName);
    return r == null ? null : FieldElemV8(r);
  }

  @override
  Iterable<GetterElem> get getters => classElement.getters
      .where((a) => !a.isSynthetic)
      .map((g) => GetterElemV8(g));

  Iterable<SetterElem> get setters => classElement.setters
      .where((a) => !a.isSynthetic)
      .map((s) => SetterElemV8(s));

  @override
  bool get hasTypeParameters => classElement.typeParameters.isNotEmpty;

  @override
  List<String> get typeParameterNames =>
      classElement.typeParameters.map((tp) => tp.name!).toList();

  ClassElemV8(this.classElement) : super(classElement);

  @override
  Code toCode() {
    return _classToCode(classElement);
  }
}

class EnumElemV8 extends ElemV8 implements EnumElem {
  final v8.EnumElement enumElement;
  Iterable<ElemAnnotation> get annotations =>
      enumElement.metadata.annotations.map((a) => ElemAnnotationV8(a));

  EnumElemV8(this.enumElement) : super(enumElement);

  Iterable<FieldElem> get constants => enumElement.fields
      .where((f) => f.isEnumConstant)
      .map((c) => FieldElemV8(c));

  @override
  Code toCode() {
    return _enumToCode(enumElement);
  }
}

class FormalParameterElemV8 extends ElemV8 implements FormalParameterElem {
  final v8.FormalParameterElement parameterElement;

  FormalParameterElemV8(this.parameterElement) : super(parameterElement);

  @override
  String get name => parameterElement.name!;

  @override
  bool get isNamed => parameterElement.isNamed;

  @override
  bool get isRequired => parameterElement.isRequired;

  @override
  bool get isOptional => parameterElement.isOptional;

  @override
  bool get isPositional => parameterElement.isPositional;

  @override
  DartType get type => DartTypeV8(parameterElement.type);
}

class ConstructorElemV8 extends ElemV8 implements ConstructorElem {
  final v8.ConstructorElement constructorElement;

  ConstructorElemV8(this.constructorElement) : super(constructorElement);

  String get name => constructorElement.name!;

  @override
  bool get isConst => constructorElement.isConst;
  @override
  bool get isFactory => constructorElement.isFactory;
  @override
  bool get isDefaultConstructor => constructorElement.isDefaultConstructor;
  @override
  String get displayName => constructorElement.displayName;

  Iterable<FormalParameterElem> get formalParameters =>
      constructorElement.formalParameters
          .map((p) => FormalParameterElemV8(p))
          .toList(growable: false);
}

Code _typeToCode(v8.DartType type,
    {bool enforceNonNull = false, bool raw = false}) {
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

Code _enumToCode(v8.EnumElement type) {
  final typeName = type.name!;
  final importUri = _getImportUriForType(type);
  return Code.type(typeName, importUri: importUri);
}

Code _classToCode(v8.ClassElement type) {
  final typeName = type.name!;
  final importUri = _getImportUriForType(type);
  return Code.type(typeName, importUri: importUri);
}

/// Converts a DartObject to a Code instance with proper import tracking
///
/// This function analyzes a compile-time constant value and generates the
/// corresponding Dart code along with any necessary import dependencies.
Code _toCode(v8.DartObject? value) {
  if (value == null || value.isNull) {
    return Code.value('null');
  }

  if (value.type?.isDartCoreType == true) {
    return DartTypeV8(value.toTypeValue()!).toCode();
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
    final variableName = variable.name!;
    final enclosingElement = variable.enclosingElement;
    if (enclosingElement is v8.ClassElement &&
        variableName.isNotEmpty &&
        variable.isStatic) {
      return Code.combine(
          [_classToCode(enclosingElement), Code.literal('.$variableName')]);
    }
  }

  // Handle objects with const constructors (like custom mappers)
  var typeElement = value.type?.element;
  if (typeElement is v8.ClassElement) {
    for (final constructor in typeElement.constructors) {
      final fields = constructor.formalParameters;
      if (constructor.isConst) {
        final constructorName = constructor.displayName;
        final positionalArgCodes = <Code>[];
        final namedArgCodes = <Code>[];

        // Separate positional and named parameters
        for (final field in fields) {
          final fieldValue = value.getField(field.name!);
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
String? _getImportUriForType(v8.Element? element) {
  if (element == null) return null;

  final source = element.library?.identifier;

  // No uri on library in analyzer v8
  final sourceUri = element.library?.uri;
  if (source == null || sourceUri == null) return null;

  return sourceUri.toString();
}
