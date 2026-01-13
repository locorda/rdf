// Actually working with analyzer >= 6.9.0 < v8.0.0 - including v7.4.0
//
// NOT working with analyzer v8.2.0
//
// ignore_for_file: deprecated_member_use
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
        LibraryExportElement,
        LibraryImportElement,
        ConstructorElement,
        ParameterElement,
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
typedef LibraryExportElement = dynamic;
typedef LibraryImportElement = dynamic;
typedef ConstructorElement = dynamic;
typedef ParameterElement = dynamic;
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
