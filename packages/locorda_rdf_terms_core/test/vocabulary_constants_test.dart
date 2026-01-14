// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:locorda_rdf_terms_core/owl.dart';
import 'package:locorda_rdf_terms_core/rdf.dart';
import 'package:locorda_rdf_terms_core/rdfs.dart';
import 'package:locorda_rdf_terms_core/xsd.dart';
import 'package:test/test.dart';
import 'package:locorda_rdf_core/core.dart';

void main() {
  group('Namespace URI Tests', () {
    test('Vocabulary namespaces are correct', () {
      // Test namespace values
      expect(
        Rdf.namespace,
        equals('http://www.w3.org/1999/02/22-rdf-syntax-ns#'),
      );
      expect(Rdfs.namespace, equals('http://www.w3.org/2000/01/rdf-schema#'));
      expect(Owl.namespace, equals('http://www.w3.org/2002/07/owl#'));
      expect(Xsd.namespace, equals('http://www.w3.org/2001/XMLSchema#'));
    });

    test('Vocabulary prefixes are correct', () {
      // Test prefix values
      expect(Rdf.prefix, equals('rdf'));
      expect(Rdfs.prefix, equals('rdfs'));
      expect(Owl.prefix, equals('owl'));
      expect(Xsd.prefix, equals('xsd'));
    });
  });

  group('Common RDF Terms Tests', () {
    test('RDF core terms have correct IRIs', () {
      expect(
        Rdf.type.value,
        equals('http://www.w3.org/1999/02/22-rdf-syntax-ns#type'),
      );
      expect(
        Rdf.Property.value,
        equals('http://www.w3.org/1999/02/22-rdf-syntax-ns#Property'),
      );
      expect(
        Rdf.value.value,
        equals('http://www.w3.org/1999/02/22-rdf-syntax-ns#value'),
      );
      expect(
        Rdf.nil.value,
        equals('http://www.w3.org/1999/02/22-rdf-syntax-ns#nil'),
      );
    });

    test('RDFS core terms have correct IRIs', () {
      expect(
        Rdfs.Class.value,
        equals('http://www.w3.org/2000/01/rdf-schema#Class'),
      );
      expect(
        Rdfs.Resource.value,
        equals('http://www.w3.org/2000/01/rdf-schema#Resource'),
      );
      expect(
        Rdfs.label.value,
        equals('http://www.w3.org/2000/01/rdf-schema#label'),
      );
      expect(
        Rdfs.comment.value,
        equals('http://www.w3.org/2000/01/rdf-schema#comment'),
      );
    });
  });

  group('IriTerm Tests', () {
    test('All vocabulary constants are IriTerm instances', () {
      // Check that constants are IriTerm instances
      expect(Rdf.type, isA<IriTerm>());
      expect(Rdfs.Class, isA<IriTerm>());
      expect(Owl.Class, isA<IriTerm>());

      expect(Xsd.string, isA<IriTerm>());
    });

    test('IriTerm objects have correct string representation', () {
      expect(
        Rdf.type.toString(),
        equals('<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>'),
      );
    });
  });
}
