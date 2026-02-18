import 'package:locorda_rdf_mapper_generator/src/templates/code.dart';

abstract class LibraryImport {
  String? get libraryIdentifier;
  String? get prefix;
  //Uri? get uri;
}

abstract class DartType {
  Code toCode({bool enforceNonNull = false, bool raw = false});
  bool get isInterfaceType;
  bool get isNotInterfaceType => !isInterfaceType;
  bool get isNullable;
  bool get isDartCoreNull;
  bool get isDartCoreIterable;
  Elem get element;
  bool get isElementClass;
  bool get isElementEnum;
  List<DartType> get typeArguments;

  /// Returns the supertypes of this type (superclass, mixins, interfaces).
  /// Returns empty list if this type has no supertypes or if supertype information is not available.
  List<DartType> get allSupertypes;

  DartType? get superclass;

  List<DartType> get mixins;

  List<DartType> get interfaces;

  String getDisplayString();
}

abstract class VariableElem extends Elem {}

abstract class DartObject {
  DartType? get type;
  VariableElem? get variable;
  DartObject? getField(String name);
  bool get isNull;

  bool get hasKnownValue;

  String? toStringValue();
  DartType? toTypeValue();
  bool? toBoolValue();
  int? toIntValue();
  double? toDoubleValue();
  List<DartObject>? toListValue();
  Map<DartObject, DartObject>? toMapValue();
  Code toCode();

  String toString();
}

abstract class ElemAnnotation {
  DartObject? computeConstantValue();
}

abstract class LibraryElem extends Elem {
  Iterable<LibraryElem> get importedLibraries;
  Iterable<LibraryElem> get exportedLibraries;
  Iterable<String> get exportDefinedNames;
  Iterable<ClassElem> get classes;

  Iterable<EnumElem> get enums;

  ClassElem? getClass(String className);
  String get identifier;
}

abstract class Elem {
  String get name;
  String? get libraryIdentifier;
  Uri? get libraryUri;

  Iterable<LibraryImport> get libraryImports;
}

abstract interface class AnnotatedElem {
  Iterable<ElemAnnotation> get annotations;
}

abstract class FieldElem extends Elem implements AnnotatedElem {
  bool get isStatic;
  bool get isFinal;
  bool get isLate;
  bool get isSynthetic;
  bool get hasInitializer;
  DartType get type;
  String get name;
  Iterable<ElemAnnotation> get annotations;
}

abstract class GetterElem extends Elem implements AnnotatedElem {
  bool get isStatic;
  DartType get type;
  String get name;
  Iterable<ElemAnnotation> get annotations;
}

abstract class SetterElem extends Elem implements AnnotatedElem {
  bool get isStatic;
  DartType get type;
  String get name;
  Iterable<ElemAnnotation> get annotations;
}

abstract class ClassElem extends Elem implements AnnotatedElem {
  Iterable<ConstructorElem> get constructors;
  Iterable<ElemAnnotation> get annotations;
  Iterable<FieldElem> get fields;
  Iterable<GetterElem> get getters;
  Iterable<SetterElem> get setters;
  FieldElem? getField(String fieldName);
  bool get hasTypeParameters;
  List<String> get typeParameterNames;
  Code toCode();
}

abstract class EnumElem extends Elem implements AnnotatedElem {
  Iterable<ElemAnnotation> get annotations;

  /// aka: enum elements
  Iterable<FieldElem> get constants;
  Code toCode();
}

abstract class FormalParameterElem extends Elem {
  String get name;
  bool get isNamed;
  bool get isRequired;
  bool get isPositional;
  bool get isOptional;
  DartType get type;
}

abstract class ConstructorElem extends Elem {
  String get displayName;
  bool get isFactory;
  bool get isConst;
  bool get isDefaultConstructor;
  Iterable<FormalParameterElem> get formalParameters;
}
