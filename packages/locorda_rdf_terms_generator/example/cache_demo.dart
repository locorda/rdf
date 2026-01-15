// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// Demonstrates vocabulary caching functionality.
///
/// This example shows how to configure vocabulary caching in build.yaml:
///
/// ```yaml
/// targets:
///   $default:
///     builders:
///       locorda_rdf_terms_generator:vocabulary_builder:
///         options:
///           manifest: "lib/src/vocabularies.json"
///           output_dir: "lib/src/vocab"
///           cache_dir: ".dart_tool/rdf_vocabulary_cache"  # Enable caching
/// ```
///
/// When cache_dir is configured:
/// - First build: Downloads vocabularies and saves to cache
/// - Subsequent builds: Loads from cache (much faster!)
/// - Cache files use pattern: {vocabulary_name}.{extension}
///   Example: schema.ttl, foaf.rdf, dublin_core.ttl
///
/// When cache_dir is NOT configured:
/// - Vocabularies are downloaded fresh on every build
/// - Content is kept in memory only
///
/// Benefits:
/// - Faster rebuilds (no network requests)
/// - Works offline after initial download
/// - Easier debugging (inspect cached files)
/// - Can version control cache for reproducible builds
void main() {
  print('Vocabulary Caching Demo');
  print('========================\n');

  print('To enable caching, add to your build.yaml:');
  print('');
  print('targets:');
  print('  \$default:');
  print('    builders:');
  print('      locorda_rdf_terms_generator:vocabulary_builder:');
  print('        options:');
  print('          manifest: "lib/src/vocabularies.json"');
  print('          output_dir: "lib/src/vocab"');
  print('          cache_dir: ".dart_tool/rdf_vocabulary_cache"');
  print('');
  print('Cache files will be stored as:');
  print('  - schema.ttl (for schema.org vocabulary)');
  print('  - foaf.rdf (for FOAF vocabulary)');
  print('  - dublin_core.ttl (for Dublin Core vocabulary)');
  print('');
  print('Run: dart run build_runner build');
}
