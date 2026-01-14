// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// This library exposes the builder factory for generating Dart classes
/// from RDF vocabulary namespace IRIs.
library locorda_rdf_terms_generator;

import 'package:build/build.dart';
export 'src/vocab/builder/vocabulary_source.dart';
import 'src/vocab/builder/vocabulary_builder.dart';

const fallbackVocabJsonPath = 'lib/src/vocab/vocabulary_sources.vocab.json';
const fallbackOutputDir = 'lib/src/vocab/generated';

/// Creates a vocabulary to Dart code generator with the given options.
///
/// Configuration options:
/// - vocabulary_config_path: Path to the JSON manifest file (default: 'lib/src/vocab/vocabulary_sources.vocab.json')
/// - output_dir: Output directory for generated files (default: 'lib/src/vocab/generated')
Builder rdfVocabularyToDart(BuilderOptions options) {
  // Read configuration from BuilderOptions
  final manifestPath =
      options.config['vocabulary_config_path'] as String? ??
      fallbackVocabJsonPath;
  final outputDir =
      options.config['output_dir'] as String? ?? fallbackOutputDir;
  return VocabularyBuilder(
    manifestAssetPath: manifestPath,
    outputDir: outputDir,
  );
}

/// Returns the build extensions for the vocabulary builder based on the given options.
/// This is used for dynamic configuration in the builder's build.yaml.
Map<String, List<String>> getBuildExtensions(Map<String, dynamic> config) {
  final manifestPath =
      config['vocabulary_config_path'] as String? ?? fallbackVocabJsonPath;
  final outputDir = config['output_dir'] as String? ?? fallbackOutputDir;

  // Create a temporary builder instance just to get the build extensions
  // This ensures that the build extensions in build.yaml match those in the actual builder
  final builder = VocabularyBuilder(
    manifestAssetPath: manifestPath,
    outputDir: outputDir,
  );

  return builder.buildExtensions;
}
