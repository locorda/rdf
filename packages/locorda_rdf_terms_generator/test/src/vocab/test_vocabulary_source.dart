import 'package:locorda_rdf_terms_generator/src/vocab/builder/vocabulary_source.dart';

class TestVocabularySource extends VocabularySource {
  TestVocabularySource(String namespace)
    : super(
        namespace,
        parsingFlags: ['flag1', 'flag2'],
        generate: true,
        explicitContentType: 'application/rdf+xml',
        skipDownload: false,
        skipDownloadReason: 'Test reason',
      );

  @override
  String get extension => '';

  @override
  Future<String> loadContent() {
    throw UnimplementedError();
  }
}
