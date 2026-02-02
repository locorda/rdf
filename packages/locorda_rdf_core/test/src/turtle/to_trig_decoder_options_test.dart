import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/src/turtle/turtle_decoder.dart';
import 'package:test/test.dart';

void main() {
  group('toTriGDecoderOptions', () {
    test('should convert empty parsing flags', () {
      final turtleOptions = TurtleDecoderOptions(parsingFlags: {});
      final trigOptions = toTriGDecoderOptions(turtleOptions);

      expect(trigOptions.parsingFlags, isEmpty);
    });

    test('should convert allowDigitInLocalName flag', () {
      final turtleOptions = TurtleDecoderOptions(
        parsingFlags: {TurtleParsingFlag.allowDigitInLocalName},
      );
      final trigOptions = toTriGDecoderOptions(turtleOptions);

      expect(trigOptions.parsingFlags, hasLength(1));
      expect(
        trigOptions.parsingFlags,
        contains(TriGParsingFlag.allowDigitInLocalName),
      );
    });

    test('should convert allowMissingDotAfterPrefix flag', () {
      final turtleOptions = TurtleDecoderOptions(
        parsingFlags: {TurtleParsingFlag.allowMissingDotAfterPrefix},
      );
      final trigOptions = toTriGDecoderOptions(turtleOptions);

      expect(trigOptions.parsingFlags, hasLength(1));
      expect(
        trigOptions.parsingFlags,
        contains(TriGParsingFlag.allowMissingDotAfterPrefix),
      );
    });

    test('should convert autoAddCommonPrefixes flag', () {
      final turtleOptions = TurtleDecoderOptions(
        parsingFlags: {TurtleParsingFlag.autoAddCommonPrefixes},
      );
      final trigOptions = toTriGDecoderOptions(turtleOptions);

      expect(trigOptions.parsingFlags, hasLength(1));
      expect(
        trigOptions.parsingFlags,
        contains(TriGParsingFlag.autoAddCommonPrefixes),
      );
    });

    test('should convert allowPrefixWithoutAtSign flag', () {
      final turtleOptions = TurtleDecoderOptions(
        parsingFlags: {TurtleParsingFlag.allowPrefixWithoutAtSign},
      );
      final trigOptions = toTriGDecoderOptions(turtleOptions);

      expect(trigOptions.parsingFlags, hasLength(1));
      expect(
        trigOptions.parsingFlags,
        contains(TriGParsingFlag.allowPrefixWithoutAtSign),
      );
    });

    test('should convert allowMissingFinalDot flag', () {
      final turtleOptions = TurtleDecoderOptions(
        parsingFlags: {TurtleParsingFlag.allowMissingFinalDot},
      );
      final trigOptions = toTriGDecoderOptions(turtleOptions);

      expect(trigOptions.parsingFlags, hasLength(1));
      expect(
        trigOptions.parsingFlags,
        contains(TriGParsingFlag.allowMissingFinalDot),
      );
    });

    test('should convert allowIdentifiersWithoutColon flag', () {
      final turtleOptions = TurtleDecoderOptions(
        parsingFlags: {TurtleParsingFlag.allowIdentifiersWithoutColon},
      );
      final trigOptions = toTriGDecoderOptions(turtleOptions);

      expect(trigOptions.parsingFlags, hasLength(1));
      expect(
        trigOptions.parsingFlags,
        contains(TriGParsingFlag.allowIdentifiersWithoutColon),
      );
    });

    test('should convert all parsing flags', () {
      final turtleOptions = TurtleDecoderOptions(
        parsingFlags: {
          TurtleParsingFlag.allowDigitInLocalName,
          TurtleParsingFlag.allowMissingDotAfterPrefix,
          TurtleParsingFlag.autoAddCommonPrefixes,
          TurtleParsingFlag.allowPrefixWithoutAtSign,
          TurtleParsingFlag.allowMissingFinalDot,
          TurtleParsingFlag.allowIdentifiersWithoutColon,
        },
      );
      final trigOptions = toTriGDecoderOptions(turtleOptions);

      expect(trigOptions.parsingFlags, hasLength(6));
      expect(
        trigOptions.parsingFlags,
        containsAll([
          TriGParsingFlag.allowDigitInLocalName,
          TriGParsingFlag.allowMissingDotAfterPrefix,
          TriGParsingFlag.autoAddCommonPrefixes,
          TriGParsingFlag.allowPrefixWithoutAtSign,
          TriGParsingFlag.allowMissingFinalDot,
          TriGParsingFlag.allowIdentifiersWithoutColon,
        ]),
      );
    });

    test('should convert subset of parsing flags', () {
      final turtleOptions = TurtleDecoderOptions(
        parsingFlags: {
          TurtleParsingFlag.allowDigitInLocalName,
          TurtleParsingFlag.autoAddCommonPrefixes,
          TurtleParsingFlag.allowMissingFinalDot,
        },
      );
      final trigOptions = toTriGDecoderOptions(turtleOptions);

      expect(trigOptions.parsingFlags, hasLength(3));
      expect(
        trigOptions.parsingFlags,
        containsAll([
          TriGParsingFlag.allowDigitInLocalName,
          TriGParsingFlag.autoAddCommonPrefixes,
          TriGParsingFlag.allowMissingFinalDot,
        ]),
      );
      expect(
        trigOptions.parsingFlags,
        isNot(contains(TriGParsingFlag.allowMissingDotAfterPrefix)),
      );
      expect(
        trigOptions.parsingFlags,
        isNot(contains(TriGParsingFlag.allowPrefixWithoutAtSign)),
      );
      expect(
        trigOptions.parsingFlags,
        isNot(contains(TriGParsingFlag.allowIdentifiersWithoutColon)),
      );
    });
  });
}
