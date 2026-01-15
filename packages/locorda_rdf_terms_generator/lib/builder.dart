// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// This library exposes the builder factory for generating Dart classes
/// from RDF vocabulary namespace IRIs.
library locorda_rdf_terms_generator;

import 'package:build/build.dart';
export 'src/vocab/builder/vocabulary_source.dart';
import 'src/vocab/builder/vocabulary_builder.dart';

const defaultVocabularyConfigs = ['lib/src/vocabularies.json'];
const fallbackOutputDir = 'lib/src/vocab/generated';

/// Creates a vocabulary to Dart code generator with the given options.
///
/// Configuration options:
/// - vocabulary_configs: List of paths to JSON config files (default: ['lib/src/vocabularies.json'])
///   Supports package URLs like 'package:my_package/vocabularies.json'
/// - output_dir: Output directory for generated files (default: 'lib/src/vocab/generated')
/// - cache_dir: Optional directory for caching downloaded vocabularies (default: null, no caching)
///
/// Configuration files are merged in order, with later files overriding earlier ones (field-level merge).
/// Standard vocabularies are always loaded as the base layer.
Builder rdfVocabularyToDart(BuilderOptions options) {
  // Read configuration from BuilderOptions
  final configsRaw = options.config['vocabulary_configs'];
  final List<String> vocabularyConfigs;

  if (configsRaw == null) {
    vocabularyConfigs = defaultVocabularyConfigs;
  } else if (configsRaw is List) {
    vocabularyConfigs = configsRaw.map((e) => e.toString()).toList();
  } else if (configsRaw is String) {
    vocabularyConfigs = [configsRaw];
  } else {
    throw ArgumentError(
      'vocabulary_configs must be a string or list of strings, got ${configsRaw.runtimeType}',
    );
  }

  final outputDir =
      options.config['output_dir'] as String? ?? fallbackOutputDir;
  final cacheDir = options.config['cache_dir'] as String?;

  return VocabularyBuilder(
    vocabularyConfigs: vocabularyConfigs,
    outputDir: outputDir,
    cacheDir: cacheDir,
  );
}
