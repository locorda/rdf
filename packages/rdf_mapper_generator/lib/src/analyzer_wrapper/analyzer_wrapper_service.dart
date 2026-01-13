import 'package:build/build.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';

class AnalysisError {
  final String message;

  AnalysisError(this.message);

  @override
  String toString() {
    return 'AnalysisError: $message';
  }
}

class ParseResult {
  final List<AnalysisError> errors;

  ParseResult(this.errors);
}

abstract class AnalyzerWrapperService {
  Future<LibraryElem> libraryFor(BuildStep buildStep, AssetId assetId,
      {bool allowSyntaxErrors = false});

  Future<LibraryElem> loadLibrary(String fixturesDir, String testFilePath);

  ParseResult parseString({required String content, required String path});
}
