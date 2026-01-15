// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:io';

import 'package:build_test/build_test.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_terms_generator/src/vocab/builder/class_generator.dart';
import 'package:locorda_rdf_terms_generator/src/vocab/builder/cross_vocabulary_resolver.dart';
import 'package:locorda_rdf_terms_generator/src/vocab/builder/model/vocabulary_model.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'event_vocabulary_collision_test.mocks.dart';
import 'src/vocab/test_vocabulary_source.dart';

Future<TestReaderWriter> createTestAssetReader() async {
  final readerWriter = TestReaderWriter();
  await readerWriter.testing.loadIsolateSources();
  return readerWriter;
}

@GenerateMocks([CrossVocabularyResolver])
/// Integration test for Event vocabulary collision fix
///
/// This test verifies that the terms generator correctly handles the case where
/// a vocabulary's prefix name (when converted to UpperCamelCase) matches a term's
/// local name, which would create a Dart class with a member of the same name.
void main() {
  group('Event vocabulary collision fix', () {
    late MockCrossVocabularyResolver mockResolver;
    late VocabularyClassGenerator generator;
    late TestReaderWriter assetReader;
    late TestVocabularySource source;

    setUp(() async {
      mockResolver = MockCrossVocabularyResolver();
      assetReader = await createTestAssetReader();
      source = TestVocabularySource('http://purl.org/NET/c4dm/event.owl#');
      generator = VocabularyClassGenerator(
        resolver: mockResolver,
        outputDir: 'lib/src/vocab/generated',
      );
    });

    test('event.n3 generates valid Dart code without collisions', () async {
      // Read the actual event.n3 file
      final eventN3File = File('test/assets/event.n3');
      expect(
        eventN3File.existsSync(),
        isTrue,
        reason: 'event.n3 test file should exist',
      );

      final content = await eventN3File.readAsString();

      // Parse the vocabulary (N3 is a superset of Turtle)
      final graph = turtle.decode(
        content,
        documentUrl: 'http://purl.org/NET/c4dm/event.owl#',
      );

      // Extract vocabulary model from graph
      final model = VocabularyModelExtractor.extractFrom(
        graph,
        'http://purl.org/NET/c4dm/event.owl#',
        'Event',
        source,
      );

      expect(model, isNotNull);
      expect(model.name, equals('Event'));
      // Note: prefix is auto-generated from name, so it will be 'Event' not 'event'

      // Find the Event class in the model
      final eventClass = model.classes.firstWhere(
        (c) => c.localName == 'Event',
        orElse: () => throw StateError('Event class not found in vocabulary'),
      );

      expect(eventClass, isNotNull);
      expect(eventClass.localName, equals('Event'));

      // Setup mock resolver for all classes
      for (final cls in model.classes) {
        when(
          mockResolver.getPropertiesForClass(cls.iri, model.namespace),
        ).thenReturn([]);
        when(mockResolver.getAllClassTypes(cls.iri)).thenReturn({cls.iri});
        when(mockResolver.getAllSuperClasses(cls.iri)).thenReturn(<String>{});
        when(
          mockResolver.getAllEquivalentClasses(cls.iri),
        ).thenReturn(<String>{});
        when(
          mockResolver.getAllEquivalentClassSuperClasses(cls.iri),
        ).thenReturn(<String>{});
      }

      // Generate Dart code
      final code = await generator.generate(model, assetReader);

      expect(code, isNotNull);
      expect(code, isNotEmpty);

      // Verify the main class is generated
      expect(code, contains('class Event {'));

      // Verify the collision is resolved: Event term should become EventClass
      expect(
        code,
        contains('static const EventClass ='),
        reason: 'Event term should be renamed to EventClass to avoid collision',
      );

      expect(
        code,
        contains("IriTerm('http://purl.org/NET/c4dm/event.owl#Event')"),
      );

      // Verify there's no direct collision
      final hasCollision = RegExp(
        r'class\s+Event\s*\{[^}]*static\s+const\s+Event\s*=',
        multiLine: true,
        dotAll: true,
      ).hasMatch(code);

      expect(
        hasCollision,
        isFalse,
        reason:
            'Generated code should not have static const Event inside class Event',
      );

      // Verify the code is compilable Dart (basic syntax check)
      expect(code, contains('import '));
      expect(code, contains('class Event'));
      expect(code, isNot(contains('static const Event =')));
    });

    test('event.n3 vocabulary structure is as expected', () async {
      // Read and parse the event.n3 file
      final eventN3File = File('test/assets/event.n3');
      final content = await eventN3File.readAsString();

      final graph = turtle.decode(
        content,
        documentUrl: 'http://purl.org/NET/c4dm/event.owl#',
      );

      final model = VocabularyModelExtractor.extractFrom(
        graph,
        'http://purl.org/NET/c4dm/event.owl#',
        'Event',
        source,
      );

      // Verify basic structure
      expect(model.classes.isNotEmpty, isTrue);
      expect(model.properties.isNotEmpty, isTrue);

      // Verify Event class exists
      final hasEventClass = model.classes.any((c) => c.localName == 'Event');
      expect(
        hasEventClass,
        isTrue,
        reason: 'Event vocabulary should contain an Event class',
      );

      // This is the key collision: prefix "event" -> class name "Event"
      // and there's a term "Event" -> would create collision
      final eventClassLocalName =
          model.classes.firstWhere((c) => c.localName == 'Event').localName;
      final vocabularyClassName = model.name;

      expect(
        eventClassLocalName,
        equals(vocabularyClassName),
        reason:
            'This test verifies the collision scenario exists: '
            'vocabulary class name matches a term local name',
      );
    });
  });
}
