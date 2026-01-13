// ignore_for_file: deprecated_member_use, unnecessary_cast
import 'analyzer_v7_4.dart' as v7;
import 'package:build/build.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_service.dart';
import 'package:rdf_mapper_generator/src/analyzer_wrapper/v7_4/analyzer_wrapper_models_v7_4.dart';

class AnalyzerWrapperServiceV7 implements AnalyzerWrapperService {
  @override
  Future<LibraryElem> libraryFor(BuildStep buildStep, AssetId assetId,
      {bool allowSyntaxErrors = false}) async {
    final libElem = await buildStep.resolver.libraryFor(assetId,
        allowSyntaxErrors: allowSyntaxErrors) as v7.LibraryElement2;
    return LibraryElemV7(libElem);
  }

  @override
  ParseResult parseString({required String content, required String path}) {
    final parseResult = v7.parseString(content: content, path: path);
    if (parseResult.errors.isNotEmpty) {
      return ParseResult(parseResult.errors.map((e) {
        return AnalysisError(e.message);
      }).toList());
    }
    return ParseResult([]);
  }

  Future<LibraryElem> loadLibrary(
      String fixturesDir, String testFilePath) async {
    final collection = v7.AnalysisContextCollection(
      includedPaths: [fixturesDir],
    );

    // Parse the test file
    final session = collection.contextFor(testFilePath).currentSession;
    final result =
        await session.getResolvedUnit(testFilePath) as v7.ResolvedUnitResult;
    return LibraryElemV7(result.libraryElement2);
  }
}
