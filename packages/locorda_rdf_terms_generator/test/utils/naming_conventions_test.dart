// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:locorda_rdf_terms_generator/src/vocab/builder/utils/naming_conventions.dart';

void main() {
  group('NamingConventions.toSnakeCase', () {
    test('converts camelCase to snake_case', () {
      expect(NamingConventions.toSnakeCase('schemaHttp'), 'schema_http');
      expect(NamingConventions.toSnakeCase('dcTerms'), 'dc_terms');
      expect(NamingConventions.toSnakeCase('myVocabName'), 'my_vocab_name');
    });

    test('converts dash-case to snake_case', () {
      expect(NamingConventions.toSnakeCase('schema-http'), 'schema_http');
      expect(NamingConventions.toSnakeCase('dc-terms'), 'dc_terms');
      expect(NamingConventions.toSnakeCase('my-vocab-name'), 'my_vocab_name');
    });

    test('leaves snake_case unchanged', () {
      expect(NamingConventions.toSnakeCase('schema_http'), 'schema_http');
      expect(NamingConventions.toSnakeCase('dc_terms'), 'dc_terms');
      expect(NamingConventions.toSnakeCase('my_vocab_name'), 'my_vocab_name');
    });

    test('handles simple lowercase names', () {
      expect(NamingConventions.toSnakeCase('rdf'), 'rdf');
      expect(NamingConventions.toSnakeCase('xsd'), 'xsd');
      expect(NamingConventions.toSnakeCase('rdfs'), 'rdfs');
      expect(NamingConventions.toSnakeCase('dcterms'), 'dcterms');
    });

    test('handles empty string', () {
      expect(NamingConventions.toSnakeCase(''), '');
    });

    test('handles mixed formats', () {
      expect(
        NamingConventions.toSnakeCase('schema-HttpVocab'),
        'schema_http_vocab',
      );
      expect(NamingConventions.toSnakeCase('my_vocabName'), 'my_vocab_name');
    });
  });

  group('NamingConventions.toUpperCamelCase', () {
    test('converts camelCase to UpperCamelCase', () {
      expect(NamingConventions.toUpperCamelCase('schemaHttp'), 'SchemaHttp');
      expect(NamingConventions.toUpperCamelCase('dcTerms'), 'DcTerms');
      expect(NamingConventions.toUpperCamelCase('myVocabName'), 'MyVocabName');
    });

    test('converts dash-case to UpperCamelCase', () {
      expect(NamingConventions.toUpperCamelCase('schema-http'), 'SchemaHttp');
      expect(NamingConventions.toUpperCamelCase('dc-terms'), 'DcTerms');
      expect(
        NamingConventions.toUpperCamelCase('my-vocab-name'),
        'MyVocabName',
      );
    });

    test('converts snake_case to UpperCamelCase', () {
      expect(NamingConventions.toUpperCamelCase('schema_http'), 'SchemaHttp');
      expect(NamingConventions.toUpperCamelCase('dc_terms'), 'DcTerms');
      expect(
        NamingConventions.toUpperCamelCase('my_vocab_name'),
        'MyVocabName',
      );
    });

    test('capitalizes simple lowercase names', () {
      expect(NamingConventions.toUpperCamelCase('rdf'), 'Rdf');
      expect(NamingConventions.toUpperCamelCase('xsd'), 'Xsd');
      expect(NamingConventions.toUpperCamelCase('rdfs'), 'Rdfs');
      expect(NamingConventions.toUpperCamelCase('dcterms'), 'Dcterms');
    });

    test('handles empty string', () {
      expect(NamingConventions.toUpperCamelCase(''), '');
    });
  });

  group('NamingConventions.toLowerCamelCase', () {
    test('preserves already lowerCamelCase', () {
      expect(NamingConventions.toLowerCamelCase('schemaHttp'), 'schemaHttp');
      expect(NamingConventions.toLowerCamelCase('dcTerms'), 'dcTerms');
      expect(NamingConventions.toLowerCamelCase('myVocabName'), 'myVocabName');
    });

    test('converts dash-case to lowerCamelCase', () {
      expect(NamingConventions.toLowerCamelCase('schema-http'), 'schemaHttp');
      expect(NamingConventions.toLowerCamelCase('dc-terms'), 'dcTerms');
      expect(
        NamingConventions.toLowerCamelCase('my-vocab-name'),
        'myVocabName',
      );
    });

    test('converts snake_case to lowerCamelCase', () {
      expect(NamingConventions.toLowerCamelCase('schema_http'), 'schemaHttp');
      expect(NamingConventions.toLowerCamelCase('dc_terms'), 'dcTerms');
      expect(
        NamingConventions.toLowerCamelCase('my_vocab_name'),
        'myVocabName',
      );
    });

    test('keeps simple lowercase names lowercase', () {
      expect(NamingConventions.toLowerCamelCase('rdf'), 'rdf');
      expect(NamingConventions.toLowerCamelCase('xsd'), 'xsd');
      expect(NamingConventions.toLowerCamelCase('rdfs'), 'rdfs');
      expect(NamingConventions.toLowerCamelCase('dcterms'), 'dcterms');
    });

    test('handles empty string', () {
      expect(NamingConventions.toLowerCamelCase(''), '');
    });
  });
}
