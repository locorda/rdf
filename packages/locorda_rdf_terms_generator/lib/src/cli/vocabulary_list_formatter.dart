// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// Formats the vocabulary listing output for the CLI.
String formatVocabularyList({
  required Map<String, Map<String, dynamic>> all,
  required Map<String, Map<String, dynamic>> standard,
}) {
  final lines = <String>[];

  lines.add('Available Vocabularies (${all.length} total)');
  lines.add('=' * 70);

  final standardKeys = <String>[];
  final customKeys = <String>[];
  final skipped = <String, Map<String, dynamic>>{};

  for (final key in all.keys.toList()..sort()) {
    final vocab = all[key]!;
    if (_isSkipped(vocab)) {
      skipped[key] = vocab;
    }

    if (standard.containsKey(key)) {
      standardKeys.add(key);
    } else {
      customKeys.add(key);
    }
  }

  if (standardKeys.isNotEmpty) {
    lines.add('\n📚 Standard Vocabularies:');
    for (final key in standardKeys) {
      final vocab = all[key]!;
      if (_isSkipped(vocab)) {
        continue;
      }
      lines.add(_formatVocabEntry(key, vocab));
      lines.add('    ${vocab['namespace']}');
    }
  }

  if (customKeys.isNotEmpty) {
    lines.add('\n🔧 Custom Vocabularies:');
    for (final key in customKeys) {
      final vocab = all[key]!;
      if (_isSkipped(vocab)) {
        continue;
      }
      lines.add(_formatVocabEntry(key, vocab));
      lines.add('    ${vocab['namespace']}');
      if (vocab['source'] != null) {
        lines.add('    Source: ${vocab['source']}');
      }
    }
  }

  if (skipped.isNotEmpty) {
    lines.add('\n⛔ Skipped Vocabularies:');
    for (final key in skipped.keys.toList()..sort()) {
      final vocab = skipped[key]!;
      final reason = _skipReason(vocab);
      lines.add('  $key');
      lines.add('    ${vocab['namespace']}');
      lines.add('    Reason: $reason');
    }
  }

  lines.add(
    '\nTo generate a vocabulary, set "generate": true in your vocabularies.json',
  );

  return lines.join('\n');
}

String _formatVocabEntry(String key, Map<String, dynamic> vocab) {
  final generateMarker = vocab['generate'] == true ? ' ✓ GENERATING' : '';
  return '  $key$generateMarker';
}

bool _isSkipped(Map<String, dynamic> vocab) {
  return vocab['skipDownload'] == true;
}

String _skipReason(Map<String, dynamic> vocab) {
  final reason = vocab['skipDownloadReason'];
  if (reason is String && reason.trim().isNotEmpty) {
    return reason;
  }
  return 'No reason provided';
}
