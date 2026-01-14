// Actually working with analyzer >= v7.4.0 < v9.0.0
//
// NOT working with analyzer v6.x.x, and deprecated but working in v8.2.0
//

// ignore_for_file: deprecated_member_use

export 'package:analyzer/dart/constant/value.dart' show DartObject;
export 'package:analyzer/dart/analysis/utilities.dart' show parseString;
export 'package:analyzer/dart/analysis/analysis_context_collection.dart'
    show AnalysisContextCollection;
export 'package:analyzer/dart/analysis/results.dart' show ResolvedUnitResult;

export 'package:analyzer/dart/element/element2.dart'
    show
        Element2,
        ClassElement2,
        EnumElement2,
        LibraryElement2,
        FieldElement2,
        ElementAnnotation,
        LibraryExport,
        LibraryImport,
        ConstructorElement2,
        FormalParameterElement,
        GetterElement,
        SetterElement,
        VariableElement2;
export 'package:analyzer/dart/element/type.dart' show DartType, InterfaceType;
/*

// Dummy types for compatibility with analyzer v7.4.0 wrapper,
// this will not run though.
typedef DartObject = dynamic;
typedef DartType = dynamic;
typedef Element2 = dynamic;
typedef ClassElement2 = dynamic;
typedef EnumElement2 = dynamic;
typedef LibraryElement2 = dynamic;
typedef FieldElement2 = dynamic;
typedef ElementAnnotation = dynamic;
typedef LibraryExport = dynamic;
typedef LibraryImport = dynamic;
typedef ConstructorElement2 = dynamic;
typedef FormalParameterElement = dynamic;
typedef GetterElement = dynamic;
typedef SetterElement = dynamic;
typedef VariableElement2 = dynamic;
typedef ResolvedUnitResult = dynamic;
typedef ParseResult = dynamic;
typedef LibraryElem = dynamic;
typedef InterfaceType = dynamic;
typedef ParseStringResult = dynamic;

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
*/
