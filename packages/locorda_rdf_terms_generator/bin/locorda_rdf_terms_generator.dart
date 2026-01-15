#!/usr/bin/env dart
// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) async {
  final parser =
      ArgParser()
        ..addCommand(
          'list',
          ArgParser()..addFlag('help', abbr: 'h', negatable: false),
        )
        ..addCommand(
          'init',
          ArgParser()..addFlag('help', abbr: 'h', negatable: false),
        );

  try {
    final results = parser.parse(arguments);

    if (results.command == null) {
      printUsage(parser);
      return;
    }

    switch (results.command!.name) {
      case 'list':
        await listVocabularies();
      case 'init':
        await initVocabularyConfig();
      default:
        printUsage(parser);
    }
  } catch (e) {
    print('Error: $e');
    printUsage(parser);
    exit(1);
  }
}

void printUsage(ArgParser parser) {
  print('Usage: dart run locorda_rdf_terms_generator:<command>');
  print('');
  print('Available commands:');
  print('  list    List all available vocabularies (standard + custom)');
  print('  init    Create a template vocabularies.json file');
  print('');
  print('Examples:');
  print('  dart run locorda_rdf_terms_generator:list');
  print('  dart run locorda_rdf_terms_generator:init');
}

/// Lists all available vocabularies, including standard and custom ones
Future<void> listVocabularies() async {
  print('Loading vocabularies...\n');

  // Load standard vocabularies
  final standard = await _loadStandardVocabularies();

  // Try to load user vocabularies
  final userVocabs = await _loadUserVocabularies();

  // Deep merge: user overrides standard
  final all = _deepMerge(standard, userVocabs);

  print('Available Vocabularies (${all.length} total)');
  print('=' * 70);

  // Separate standard and custom
  final standardKeys = <String>[];
  final customKeys = <String>[];

  for (final key in all.keys.toList()..sort()) {
    if (standard.containsKey(key)) {
      standardKeys.add(key);
    } else {
      customKeys.add(key);
    }
  }

  if (standardKeys.isNotEmpty) {
    print('\n📚 Standard Vocabularies:');
    for (final key in standardKeys) {
      final vocab = all[key]!;
      final gen = vocab['generate'] == true ? ' ✓ GENERATING' : '';
      print('  $key$gen');
      print('    ${vocab['namespace']}');
    }
  }

  if (customKeys.isNotEmpty) {
    print('\n🔧 Custom Vocabularies:');
    for (final key in customKeys) {
      final vocab = all[key]!;
      final gen = vocab['generate'] == true ? ' ✓ GENERATING' : '';
      print('  $key$gen');
      print('    ${vocab['namespace']}');
      if (vocab['source'] != null) {
        print('    Source: ${vocab['source']}');
      }
    }
  }

  print(
    '\nTo generate a vocabulary, set "generate": true in your vocabularies.json',
  );
}

/// Deep merge two vocabulary maps, with override taking precedence
Map<String, Map<String, dynamic>> _deepMerge(
  Map<String, Map<String, dynamic>> base,
  Map<String, Map<String, dynamic>> override,
) {
  final merged = Map<String, Map<String, dynamic>>.from(base);

  for (final entry in override.entries) {
    final name = entry.key;
    final overrideVocab = entry.value;

    if (merged.containsKey(name)) {
      // Merge fields: override takes precedence
      final baseVocab = merged[name]!;
      merged[name] = {...baseVocab, ...overrideVocab};
    } else {
      // New vocabulary
      merged[name] = overrideVocab;
    }
  }

  return merged;
}

/// Creates a template vocabularies.json file
Future<void> initVocabularyConfig() async {
  // Try to find package root (has pubspec.yaml)
  var currentDir = Directory.current;
  File? pubspecFile;

  // Look up to 3 levels for pubspec.yaml
  for (var i = 0; i < 3; i++) {
    final testPubspec = File(p.join(currentDir.path, 'pubspec.yaml'));
    if (testPubspec.existsSync()) {
      pubspecFile = testPubspec;
      break;
    }
    final parent = currentDir.parent;
    if (parent.path == currentDir.path) break; // At root
    currentDir = parent;
  }

  if (pubspecFile == null) {
    print('⚠️  Could not find pubspec.yaml');
    print('   Run this command from your Dart/Flutter package root');
    exit(1);
  }

  // Ensure lib/ directory exists
  final libDir = Directory(p.join(currentDir.path, 'lib'));
  if (!libDir.existsSync()) {
    print('📁 Creating lib/ directory...');
    libDir.createSync();
  }

  final filename = p.join(libDir.path, 'vocabularies.json');
  final file = File(filename);

  if (file.existsSync()) {
    print('❌ $filename already exists');
    print('   Delete it first or edit the existing file');
    exit(1);
  }

  final template = {
    'vocabularies': {
      'myOntology': {
        'type': 'file',
        'namespace': 'https://example.com/ontology#',
        'source': 'file://path/to/ontology.ttl',
        'generate': true,
      },
      'exampleUrlBased': {
        'type': 'url',
        'namespace': 'https://example.com/vocab#',
        'source': 'https://example.com/vocab.ttl',
        'generate': false,
      },
      'exampleWithAllOptions': {
        'type': 'url',
        'namespace': 'https://example.com/advanced#',
        'source': 'https://example.com/advanced.ttl',
        'contentType': 'text/turtle',
        'parsingFlags': ['allowPrefixWithoutAtSign'],
        'generate': false,
      },
    },
  };

  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(template),
  );

  print('✅ Created lib/vocabularies.json\n');
  print('Examples included:');
  print(
    '  • myOntology           - Minimal file-based vocabulary (GENERATING)',
  );
  print('  • exampleUrlBased      - URL-based vocabulary');
  print('  • exampleWithAllOptions - Shows all available fields\n');
  print('Edit lib/vocabularies.json to customize or remove examples.\n');
  print('Available fields:');
  print('  type          - "url" or "file" (default: "url")');
  print('  namespace     - Required vocabulary namespace IRI');
  print('  source        - Required URL or file path');
  print('  contentType   - Optional MIME type (e.g., "text/turtle")');
  print('  parsingFlags  - Optional parsing flags array');
  print('  generate      - true to generate classes (default: false)\n');
  print('To generate standard vocabularies (rdf, foaf, schema, etc.):');
  print('  "foaf": { "generate": true }\n');
  print('📦 Ready to build!');
  print('   dart run build_runner build\n');
  print(
    'Run "dart run locorda_rdf_terms_generator list" to see all available vocabularies.',
  );
}

/// Load standard vocabularies from the generator package
Future<Map<String, Map<String, dynamic>>> _loadStandardVocabularies() async {
  try {
    File? file;

    // Try package URI resolution first (works when installed as dependency)
    try {
      final packageUri = Uri.parse(
        'package:locorda_rdf_terms_generator/standard_vocabularies.json',
      );
      final resolvedUri = await Isolate.resolvePackageUri(packageUri);

      if (resolvedUri != null) {
        file = File(resolvedUri.toFilePath());
        if (!file.existsSync()) {
          file = null;
        }
      }
    } catch (_) {
      // Package resolution failed, will try fallback
    }

    // Fallback: use script-relative path (works when running from within package)
    if (file == null) {
      final scriptUri = Platform.script;
      final scriptPath = scriptUri.toFilePath();
      final packageRoot = p.dirname(p.dirname(scriptPath));
      final standardVocabPath = p.join(
        packageRoot,
        'lib',
        'standard_vocabularies.json',
      );
      file = File(standardVocabPath);
    }

    if (!file.existsSync()) {
      print('Warning: Could not find standard_vocabularies.json');
      return {};
    }

    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final vocabs = json['vocabularies'] as Map<String, dynamic>;

    return vocabs.map(
      (key, value) => MapEntry(key, value as Map<String, dynamic>),
    );
  } catch (e) {
    print('Warning: Error loading standard vocabularies: $e');
    return {};
  }
}

/// Load user vocabularies from conventional location (lib/vocabularies.json)
Future<Map<String, Map<String, dynamic>>> _loadUserVocabularies() async {
  // Check conventional location first
  var file = File('lib/vocabularies.json');

  // Fallback to current directory (for backwards compatibility)
  if (!file.existsSync()) {
    file = File('vocabularies.json');
  }

  if (!file.existsSync()) {
    return {};
  }

  try {
    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    final vocabs = json['vocabularies'] as Map<String, dynamic>;

    return vocabs.map(
      (key, value) => MapEntry(key, value as Map<String, dynamic>),
    );
  } catch (e) {
    print('Warning: Error loading ${file.path}: $e');
    return {};
  }
}
