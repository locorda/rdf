import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_service.dart';
//import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/v6/analyzer_wrapper_service_v6.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/v8_1/analyzer_wrapper_service_v8_1.dart';
//import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/v8_2/analyzer_wrapper_service_v8_2.dart';

class AnalyzerWrapperServiceFactory {
  static AnalyzerWrapperService create() {
    return AnalyzerWrapperServiceV8();
  }
}
