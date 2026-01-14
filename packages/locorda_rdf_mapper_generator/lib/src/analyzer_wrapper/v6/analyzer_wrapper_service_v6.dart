// ignore_for_file: deprecated_member_use, unnecessary_cast

import 'package:analyzer/dart/element/element.dart';

import 'analyzer_v6.dart' as v6;
import 'package:build/build.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_models.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/analyzer_wrapper_service.dart';
import 'package:locorda_rdf_mapper_generator/src/analyzer_wrapper/v6/analyzer_wrapper_models_v6.dart';

class AnalyzerWrapperServiceV6 implements AnalyzerWrapperService {
  @override
  Future<LibraryElem> libraryFor(BuildStep buildStep, AssetId assetId,
      {bool allowSyntaxErrors = false}) async {
    final libElem = (await buildStep.resolver.libraryFor(assetId,
        allowSyntaxErrors: allowSyntaxErrors) as LibraryElement);
    return LibraryElemV6(libElem);
  }

  @override
  ParseResult parseString({required String content, required String path}) {
    final parseResult = v6.parseString(content: content, path: path);
    if (parseResult.errors.isNotEmpty) {
      return ParseResult(parseResult.errors.map((e) {
        return AnalysisError(e.message);
      }).toList());
    }
    return ParseResult([]);
  }

  Future<LibraryElem> loadLibrary(
      String fixturesDir, String testFilePath) async {
    final collection = v6.AnalysisContextCollection(
      includedPaths: [fixturesDir],
    );

    // Parse the test file
    final session = collection.contextFor(testFilePath).currentSession;
    final result =
        await session.getResolvedUnit(testFilePath) as v6.ResolvedUnitResult;
    return LibraryElemV6(result.libraryElement);
  }
}
