// ignore_for_file: unnecessary_type_check, unreachable_switch_case, dead_code
// ignore_for_file: deprecated_member_use

import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';

import 'analyzer_v7_4.dart' as v7;

class DartTypeV7 extends DartType {
  final v7.DartType dartType;

  DartTypeV7(this.dartType);

  bool get isNullable =>
      dartType.isDartCoreNull ||
      (dartType is v7.InterfaceType && dartType.isDartCoreNull) ||
      (dartType.element3?.library2?.typeSystem.isNullable(dartType) ?? false);

  get typeArguments => (dartType is v7.InterfaceType
          ? (dartType as v7.InterfaceType).typeArguments
          : [])
      .map((t) => DartTypeV7(t))
      .toList(growable: false);

  bool get isInterfaceType => dartType is v7.InterfaceType;

  bool get isDartCoreNull => dartType.isDartCoreNull;

  bool get isDartCoreIterable => dartType.isDartCoreIterable;

  @override
  bool get isElementClass => dartType.element3 is v7.ClassElement2;

  @override
  bool get isElementEnum => dartType.element3 is v7.EnumElement2;

  Elem get element => switch (dartType.element3!) {
        v7.ClassElement2 classElement2 => ClassElemV7(classElement2),
        v7.EnumElement2 enumElement2 => EnumElemV7(enumElement2),
        v7.LibraryElement2 libraryElement2 => LibraryElemV7(libraryElement2),
        v7.FieldElement2 fieldElement2 => FieldElemV7(fieldElement2),
        v7.ConstructorElement2 constructorElement2 =>
          ConstructorElemV7(constructorElement2),
        v7.FormalParameterElement formalParameterElement2 =>
          FormalParameterElemV7(formalParameterElement2),
        _ => throw ArgumentError(
            'Unsupported DartType element: ${dartType.element3.runtimeType}'),
      };

  @override
  String getDisplayString() {
    return dartType.getDisplayString();
  }

  @override
  Code toCode({bool enforceNonNull = false, bool raw = false}) {
    return _typeToCode(dartType, enforceNonNull: enforceNonNull, raw: raw);
  }

  @override
  DartType? get superclass {
    if (dartType case final v7.InterfaceType interfaceType) {
      if (interfaceType.superclass != null) {
        return DartTypeV7(interfaceType.superclass!);
      }
    }
    return null;
  }

  @override
  List<DartType> get mixins {
    if (dartType case final v7.InterfaceType interfaceType) {
      return interfaceType.mixins
          .map((mixin) => DartTypeV7(mixin))
          .toList(growable: false);
    }
    return const [];
  }

  @override
  List<DartType> get interfaces {
    if (dartType case final v7.InterfaceType interfaceType) {
      return interfaceType.interfaces
          .map((mixin) => DartTypeV7(mixin))
          .toList(growable: false);
    }
    return const [];
  }

  @override
  List<DartType> get allSupertypes {
    return [if (superclass != null) superclass!, ...mixins, ...interfaces];
  }
}

class FieldElemV7 extends ElemV7 implements FieldElem {
  final v7.FieldElement2 fieldElement;

  FieldElemV7(this.fieldElement) : super(fieldElement);

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
    return DartTypeV7(fieldElement.type);
  }

  @override
  String get name => fieldElement.name3!;

  @override
  Iterable<ElemAnnotation> get annotations =>
      fieldElement.metadata2.annotations.map((a) => ElemAnnotationV7(a));
}

class VariableElemV7 extends ElemV7 implements VariableElem {
  final v7.VariableElement2 variableElement;

  VariableElemV7(this.variableElement) : super(variableElement);

  @override
  String get name => variableElement.name3!;
}

class DartObjectV7 implements DartObject {
  final v7.DartObject dartObject;

  DartObjectV7(this.dartObject);

  DartType? get type {
    var typeValue = dartObject.type;
    return typeValue == null ? null : DartTypeV7(typeValue);
  }

  VariableElem? get variable {
    var r = dartObject.variable2;
    return r == null ? null : VariableElemV7(r);
  }

  bool get hasKnownValue {
    return dartObject.hasKnownValue;
  }

  @override
  DartObject? getField(String name) {
    final r = dartObject.getField(name);
    return r == null ? null : DartObjectV7(r);
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
    return typeValue == null ? null : DartTypeV7(typeValue);
  }

  String toString() {
    return dartObject.toString();
  }
}

class ElemAnnotationV7 implements ElemAnnotation {
  final v7.ElementAnnotation annotation;

  ElemAnnotationV7(this.annotation);

  DartObject? computeConstantValue() {
    final r = annotation.computeConstantValue();
    return r == null ? null : DartObjectV7(r);
  }
}

class LibraryElemV7 extends ElemV7 implements LibraryElem {
  final v7.LibraryElement2 libraryElement;

  LibraryElemV7(this.libraryElement) : super(libraryElement);

  String get name => libraryElement.name3!;

  String get identifier => libraryElement.identifier;
  Uri? get uri => libraryElement.uri;

  Iterable<String> get exportDefinedNames =>
      libraryElement.exportNamespace.definedNames2.keys;

  Iterable<LibraryImport> get libraryImports => libraryElement.fragments
      .expand<v7.LibraryImport>((f) => f.libraryImports2)
      .map((libImport) => LibraryImportV7(libImport))
      .toList(growable: false);

  Iterable<LibraryElem> get importedLibraries => libraryElement.fragments
      .expand<v7.LibraryElement2>((f) => f.importedLibraries2)
      .map((lib) => LibraryElemV7(lib))
      .toList(growable: false);

  Iterable<LibraryElem> get exportedLibraries => libraryElement.fragments
      .expand<v7.LibraryExport>((f) => f.libraryExports2)
      .map((exp) => exp.exportedLibrary2)
      .nonNulls
      .map((lib) => LibraryElemV7(lib))
      .toList(growable: false);

  Iterable<ClassElem> get classes => libraryElement.fragments
      .expand((f) => f.classes2)
      .map((c) => c.element)
      .map(ClassElemV7.new)
      .toList(growable: false);

  Iterable<EnumElem> get enums => libraryElement.fragments
      .expand((f) => f.enums2)
      .map((e) => e.element)
      .map(EnumElemV7.new)
      .toList(growable: false);

  ClassElem? getClass(String className) {
    var r = libraryElement.getClass2(className);
    return r == null ? null : ClassElemV7(r);
  }
}

class LibraryImportV7 implements LibraryImport {
  final v7.LibraryImport libraryImport;

  String? get libraryIdentifier => libraryImport.importedLibrary2?.identifier;
  Uri? get uri => libraryImport.importedLibrary2?.uri;
  String? get prefix => libraryImport.prefix2?.name2;

  LibraryImportV7(this.libraryImport);
}

abstract class ElemV7 implements Elem {
  final v7.Element2 element;

  String get name => element.name3!;

  String? get libraryIdentifier => element.library2?.identifier;
  Uri? get libraryUri => element.library2?.uri;

  Iterable<LibraryImport> get libraryImports =>
      (element.library2?.fragments ?? [])
          .expand<v7.LibraryImport>((f) => f.libraryImports2)
          .map((libImport) => LibraryImportV7(libImport));

  ElemV7(this.element);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ElemV7) return false;
    return element == other.element;
  }

  @override
  int get hashCode => element.hashCode;
}

class GetterElemV7 extends ElemV7 implements GetterElem {
  final v7.GetterElement getterElement;

  GetterElemV7(this.getterElement) : super(getterElement);

  @override
  String get name => getterElement.name3!;

  @override
  bool get isStatic => getterElement.isStatic;

  @override
  DartType get type => DartTypeV7(getterElement.type);

  Iterable<ElemAnnotation> get annotations =>
      getterElement.metadata2.annotations.map((a) => ElemAnnotationV7(a));
}

class SetterElemV7 extends ElemV7 implements SetterElem {
  final v7.SetterElement setterElement;

  SetterElemV7(this.setterElement) : super(setterElement);

  @override
  String get name => setterElement.name3!;

  @override
  bool get isStatic => setterElement.isStatic;

  @override
  DartType get type => DartTypeV7(setterElement.type);

  Iterable<ElemAnnotation> get annotations =>
      setterElement.metadata2.annotations.map((a) => ElemAnnotationV7(a));
}

class ClassElemV7 extends ElemV7 implements ClassElem {
  final v7.ClassElement2 classElement;

  Iterable<ConstructorElem> get constructors =>
      classElement.constructors2.map((c) => ConstructorElemV7(c));

  Iterable<ElemAnnotation> get annotations =>
      classElement.metadata2.annotations.map((a) => ElemAnnotationV7(a));

  Iterable<FieldElem> get fields => classElement.fields2
      .where((f) => !f.isSynthetic)
      .map((f) => FieldElemV7(f));

  FieldElem? getField(String fieldName) {
    var r = classElement.getField2(fieldName);
    return r == null ? null : FieldElemV7(r);
  }

  @override
  Iterable<GetterElem> get getters => classElement.getters2
      .where((f) => !f.isSynthetic)
      .map((g) => GetterElemV7(g));

  Iterable<SetterElem> get setters => classElement.setters2
      .where((f) => !f.isSynthetic)
      .map((s) => SetterElemV7(s));

  @override
  bool get hasTypeParameters => classElement.typeParameters2.isNotEmpty;

  @override
  List<String> get typeParameterNames =>
      classElement.typeParameters2.map((tp) => tp.name3!).toList();

  ClassElemV7(this.classElement) : super(classElement);

  @override
  Code toCode() {
    return _classToCode(classElement);
  }
}

class EnumElemV7 extends ElemV7 implements EnumElem {
  final v7.EnumElement2 enumElement;
  Iterable<ElemAnnotation> get annotations =>
      enumElement.metadata2.annotations.map((a) => ElemAnnotationV7(a));

  EnumElemV7(this.enumElement) : super(enumElement);

  Iterable<FieldElem> get constants =>
      enumElement.constants2.map((c) => FieldElemV7(c));

  @override
  Code toCode() {
    return _enumToCode(enumElement);
  }
}

class FormalParameterElemV7 extends ElemV7 implements FormalParameterElem {
  final v7.FormalParameterElement parameterElement;

  FormalParameterElemV7(this.parameterElement) : super(parameterElement);

  @override
  String get name => parameterElement.name3!;

  @override
  bool get isNamed => parameterElement.isNamed;

  @override
  bool get isRequired => parameterElement.isRequired;

  @override
  bool get isOptional => parameterElement.isOptional;

  @override
  bool get isPositional => parameterElement.isPositional;

  @override
  DartType get type => DartTypeV7(parameterElement.type);
}

class ConstructorElemV7 extends ElemV7 implements ConstructorElem {
  final v7.ConstructorElement2 constructorElement;

  ConstructorElemV7(this.constructorElement) : super(constructorElement);

  String get name => constructorElement.name3!;

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
          .map(FormalParameterElemV7.new)
          .toList(growable: false);
}

Code _typeToCode(v7.DartType type,
    {bool enforceNonNull = false, bool raw = false}) {
  var typeName = raw ? type.name : null;

  typeName ??= type.getDisplayString();

  if (enforceNonNull && typeName.endsWith('?')) {
    typeName = typeName.substring(0, typeName.length - 1);
  }
  final importUri = _getImportUriForType(type.element3);
  return Code.type(typeName, importUri: importUri);
}

Code _enumToCode(v7.EnumElement2 type) {
  final typeName = type.name3!;
  final importUri = _getImportUriForType(type);
  return Code.type(typeName, importUri: importUri);
}

Code _classToCode(v7.ClassElement2 type) {
  final typeName = type.name3!;
  final importUri = _getImportUriForType(type);
  return Code.type(typeName, importUri: importUri);
}

/// Converts a DartObject to a Code instance with proper import tracking
///
/// This function analyzes a compile-time constant value and generates the
/// corresponding Dart code along with any necessary import dependencies.
Code _toCode(v7.DartObject? value) {
  if (value == null || value.isNull) {
    return Code.value('null');
  }

  if (value.type?.isDartCoreType == true) {
    return DartTypeV7(value.toTypeValue()!).toCode();
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
    final enumType = value.type!.getDisplayString();
    if (enumValue != null) {
      final importUri = _getImportUriForType(value.type!.element3);
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

  if (value.variable2 != null) {
    // Handle variables (e.g., const variables)
    final variable = value.variable2!;
    final variableName = variable.name3;
    final enclosingElement = variable.enclosingElement2;
    if (enclosingElement is v7.ClassElement2 &&
        variableName != null &&
        variable.isStatic) {
      return Code.combine(
          [_classToCode(enclosingElement), Code.literal('.$variableName')]);
    }
  }

  // Handle objects with const constructors (like custom mappers)
  var typeElement = value.type?.element3;
  if (typeElement is v7.ClassElement2) {
    for (final constructor in typeElement.constructors2) {
      final fields = constructor.formalParameters;
      if (constructor.isConst) {
        final constructorName = constructor.displayName;
        final positionalArgCodes = <Code>[];
        final namedArgCodes = <Code>[];

        // Separate positional and named parameters
        for (final field in fields) {
          final fieldValue = value.getField(field.name3!);
          if (fieldValue != null) {
            final fieldCode = _toCode(fieldValue);

            if (field.isNamed) {
              // Named parameter: paramName: value
              namedArgCodes.add(
                  Code.combine([Code.value('${field.name3!}: '), fieldCode]));
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
          Code.paramsList(allArgCodes),
        ]);
      }
    }
  }

  // Fallback to string representation if type is not recognized
  return Code.value(value.toStringValue() ?? '');
}

/// Determines the import URI for a given type element
String? _getImportUriForType(v7.Element2? element) {
  if (element == null) return null;

  final source = element.library2?.identifier;
  final sourceUri = element.library2?.uri;
  if (source == null || sourceUri == null) return null;

  return source.toString();
}
