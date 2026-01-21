// Copyright (c) 2026, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:locorda_rdf_terms_generator/src/cli/vocabulary_list_formatter.dart';
import 'package:test/test.dart';

void main() {
  test('formats skipped vocabularies with reasons', () {
    final standard = <String, Map<String, dynamic>>{
      'rdf': {
        'namespace': 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        'generate': false,
        'skipDownload': true,
        'skipDownloadReason': 'Licensed vocabulary',
      },
      'rdfs': {
        'namespace': 'http://www.w3.org/2000/01/rdf-schema#',
        'generate': false,
      },
    };

    final all = <String, Map<String, dynamic>>{
      ...standard,
      'custom': {
        'namespace': 'https://example.com/custom#',
        'source': 'https://example.com/custom.ttl',
        'generate': true,
        'skipDownload': true,
        'skipDownloadReason': 'Blocked by policy',
      },
    };

    final output = formatVocabularyList(all: all, standard: standard);

    expect(output, contains('⛔ Skipped Vocabularies:'));
    expect(output, contains('rdf'));
    expect(output, contains('custom'));
    expect(output, contains('Reason: Licensed vocabulary'));
    expect(output, contains('Reason: Blocked by policy'));
  });
}
