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
        GetterElement,
        SetterElement,
        VariableElement;
export 'package:analyzer/dart/element/type.dart' show DartType, InterfaceType;
