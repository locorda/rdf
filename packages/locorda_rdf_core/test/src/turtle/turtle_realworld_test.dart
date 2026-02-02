import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/turtle/turtle_decoder.dart';
import 'package:locorda_rdf_core/src/vocab/xsd.dart';
import 'package:test/test.dart';

final _log = Logger('turtle_realworld_test');

/// A test suite for testing the turtle parser against real-world turtle files.
/// This test ensures that the parser can handle complex and real-world turtle files
/// found in the assets/realworld directory.
void main() {
  group('RealWorld Turtle Parser Tests', () {
    /// Returns the absolute path to a test asset file
    String getAssetPath(String fileName) {
      // Der direkte Pfad zum Testassets-Verzeichnis
      return path.join('test/assets/realworld', fileName);
    }

    /// Helper to read a file and return its content as a string
    String readAssetFile(String fileName) {
      final file = File(getAssetPath(fileName));
      return file.readAsStringSync();
    }

    /// Creates a parser with the given content and optional parsing flags
    TurtleDecoder createDecoder({
      Set<TurtleParsingFlag> parsingFlags = const {},
    }) =>
        TurtleDecoder(
          options: TurtleDecoderOptions(parsingFlags: parsingFlags),
          namespaceMappings: RdfNamespaceMappings(),
        );

    /// Test helper to try parsing a turtle file with both strict mode and specific flags
    /// Returns a tuple containing:
    /// 1. Whether the file can be parsed with specific flags
    /// 2. The required flags if parsing succeeded
    Future<({bool success, Set<TurtleParsingFlag> flags, List<Triple> triples})>
        testFile(
      String fileName,
      String namespace,
      Set<TurtleParsingFlag> specificFlags,
    ) async {
      final content = readAssetFile(fileName);

      // If strict mode fails, try with file-specific flags

      final decoder = createDecoder(parsingFlags: specificFlags);
      final triples = decoder.convert(content, documentUrl: namespace).triples;
      _log.info(
        'Successfully parsed $fileName with specific flags: ${triples.length} triples',
      );
      return (success: true, flags: specificFlags, triples: triples);
    }

    test('should parse acl.ttl', () async {
      var specificFlags = <TurtleParsingFlag>{};
      final result = await testFile(
        'acl.ttl',
        'http://www.w3.org/ns/auth/acl#',
        specificFlags,
      );
      expect(result.success, isTrue);
      expect(result.flags, equals(specificFlags));
    });

    test('should parse vcard.ttl', () async {
      var specificFlags = <TurtleParsingFlag>{};
      final result = await testFile(
        'vcard.ttl',
        'http://www.w3.org/2006/vcard/ns#',
        specificFlags,
      );
      expect(result.success, isTrue);
      // Validate that we're using the minimum required flags
      expect(result.flags, equals(specificFlags));
      var graph = RdfGraph(triples: result.triples);
      var deprecated = graph.findTriples(
        predicate: const IriTerm('http://www.w3.org/2002/07/owl#deprecated'),
      );
      deprecated.forEach((triple) {
        expect(triple.object, isA<LiteralTerm>());
        var literal = (triple.object as LiteralTerm);
        expect(literal.datatype, equals(Xsd.boolean));
        expect(literal.value, equals("true"));
      });
      expect(deprecated.length, equals(24));
    });

    test('should parse solid.ttl', () async {
      var specificFlags = <TurtleParsingFlag>{
        TurtleParsingFlag.allowMissingDotAfterPrefix,
        TurtleParsingFlag.allowPrefixWithoutAtSign,
      };
      final result = await testFile(
        'solid.ttl',
        'http://www.w3.org/ns/solid/terms#',
        specificFlags,
      );
      expect(result.success, isTrue);
      // Validate that we're using the minimum required flags
      expect(result.flags, equals(specificFlags));
    });
    test('should parse LegalCore.ttl', () async {
      final result = await testFile('LegalCore.ttl',
          'https://spec.edmcouncil.org/fibo/ontology/FND/Law/LegalCore/', {});
      expect(result.success, isTrue);
      // Validate that we're using the minimum required flags
      expect(result.triples.length, greaterThan(60));
    });

    test('should parse schema.org.ttl', () async {
      var specificFlags = <TurtleParsingFlag>{
        TurtleParsingFlag.allowDigitInLocalName,
      };
      final result = await testFile(
        'schema.org.ttl',
        'https://schema.org/',
        specificFlags,
      );
      expect(result.success, isTrue);
      // Validate that we're using the minimum required flags
      expect(result.flags, equals(specificFlags));
    });

    test('should parse gs1Voc.ttl with uppercase PREFIX declarations',
        () async {
      var specificFlags = <TurtleParsingFlag>{
        TurtleParsingFlag.allowPrefixWithoutAtSign,
        TurtleParsingFlag.allowMissingDotAfterPrefix,
      };
      final result = await testFile(
        'gs1Voc.ttl',
        'https://ref.gs1.org/voc/',
        specificFlags,
      );
      expect(result.success, isTrue);
      // Validate that we're using the minimum required flags for uppercase PREFIX support
      expect(result.flags, equals(specificFlags));
      // Validate that we parsed a substantial number of triples from this large vocabulary
      expect(result.triples.length, greaterThan(1000));
    });
  });
}
