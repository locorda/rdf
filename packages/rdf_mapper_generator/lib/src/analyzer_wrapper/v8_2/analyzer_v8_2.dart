// ignore_for_file: deprecated_member_use

// Actually working with analyzer >= v8.2.0
//
// This is probably the future, but we want to stay as
// compatible as possible so this is not yet used.
//
// NOT working with analyzer v7.4.0, and of course not with v6.x.x
//
/*
export 'package:analyzer/dart/constant/value.dart' show DartObject;
export 'package:analyzer/dart/analysis/utilities.dart' show parseString;
export 'package:analyzer/dart/analysis/analysis_context_collection.dart'
    show AnalysisContextCollection;
export 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;

export 'package:analyzer/dart/element/element.dart'
    show
        Element,
        ClassElement,
        EnumElement,
        LibraryElement,
        FieldElement,
        ElementAnnotation,
        LibraryExport,
        LibraryImport,
        ConstructorElement,
        FormalParameterElement,
        PrefixElement,
        PropertyAccessorElement,
        VariableElement;
export 'package:analyzer/dart/element/type.dart' show DartType, InterfaceType;

*/

// Dummy types for compatibility with analyzer v7.4.0 wrapper,
// this will not run though.
typedef DartObject = dynamic;
typedef DartType = dynamic;
typedef Element = dynamic;
typedef ClassElement = dynamic;
typedef EnumElement = dynamic;
typedef LibraryElement = dynamic;
typedef FieldElement = dynamic;
typedef ElementAnnotation = dynamic;
typedef LibraryExport = dynamic;
typedef LibraryImport = dynamic;
typedef ConstructorElement = dynamic;
typedef FormalParameterElement = dynamic;
typedef GetterElement = dynamic;
typedef SetterElement = dynamic;
typedef VariableElement = dynamic;
typedef ResolvedUnitResult = dynamic;
typedef ParseResult = dynamic;
typedef LibraryElem = dynamic;
typedef InterfaceType = dynamic;
typedef ParseStringResult = dynamic;
typedef PropertyAccessorElement = dynamic;

ParseStringResult parseString({required String content, required String path}) {
  throw UnimplementedError(
      'parseString is not implemented in this analyzer version');
}

class AnalysisContextCollection {
  AnalysisContextCollection({required List<String> includedPaths}) {
    throw UnimplementedError(
        'AnalysisContextCollection is not implemented in this analyzer version');
  }

  dynamic contextFor(String path) {
    throw UnimplementedError(
        'contextFor is not implemented in this analyzer version');
  }
}
