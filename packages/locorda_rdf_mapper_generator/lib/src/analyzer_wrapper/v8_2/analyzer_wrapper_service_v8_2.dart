// ignore_for_file: deprecated_member_use

import 'package:build/build.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_service.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/v8_2/analyzer_wrapper_models_v8_2.dart';

import 'analyzer_v8_2.dart' as v8;

class AnalyzerWrapperServiceV8 implements AnalyzerWrapperService {
  @override
  Future<LibraryElem> libraryFor(BuildStep buildStep, AssetId assetId,
      {bool allowSyntaxErrors = false}) async {
    final libElem = (await buildStep.resolver
        .libraryFor(assetId, allowSyntaxErrors: allowSyntaxErrors));
    return LibraryElemV8(libElem);
  }

  @override
  ParseResult parseString({required String content, required String path}) {
    final parseResult = v8.parseString(content: content, path: path);
    if (parseResult.errors.isNotEmpty) {
      return ParseResult(parseResult.errors.map((e) {
        return AnalysisError(e.message);
      }).toList());
    }
    return ParseResult([]);
  }

  Future<LibraryElem> loadLibrary(
      String fixturesDir, String testFilePath) async {
    final collection = v8.AnalysisContextCollection(
      includedPaths: [fixturesDir],
    );

    // Parse the test file
    final session = collection.contextFor(testFilePath).currentSession;
    final result =
        await session.getResolvedUnit(testFilePath) as v8.ResolvedUnitResult;
    return LibraryElemV8(result.libraryElement);
  }
}
