import 'dart:typed_data';

import 'package:locorda_rdf_core/src/graph/rdf_graph.dart';
import 'package:locorda_rdf_core/src/plugin/exceptions.dart';
import 'package:locorda_rdf_core/src/plugin/rdf_binary_codec_registry.dart';
import 'package:locorda_rdf_core/src/plugin/rdf_binary_graph_codec.dart';
import 'package:locorda_rdf_core/src/rdf_binary_decoder.dart';
import 'package:locorda_rdf_core/src/rdf_binary_encoder.dart';
import 'package:locorda_rdf_core/src/rdf_binary_graph_decoder.dart';
import 'package:locorda_rdf_core/src/rdf_binary_graph_encoder.dart';
import 'package:test/test.dart';

void main() {
  late BaseRdfBinaryCodecRegistry<RdfGraph> registry;

  setUp(() {
    registry = BaseRdfBinaryCodecRegistry<RdfGraph>();
  });

  group('BaseRdfBinaryCodecRegistry', () {
    test('registerCodec adds codec to registry', () {
      final codec = _MockBinaryCodec();
      registry.registerCodec(codec);

      final retrieved = registry.getCodec('application/x-test-binary');
      expect(retrieved, equals(codec));
    });

    test('getCodec throws for unregistered MIME type', () {
      expect(
        () => registry.getCodec('application/not-registered'),
        throwsA(isA<CodecNotSupportedException>()),
      );
    });

    test('getCodec handles case insensitivity', () {
      final codec = _MockBinaryCodec();
      registry.registerCodec(codec);

      final retrieved = registry.getCodec('APPLICATION/X-TEST-BINARY');
      expect(retrieved, equals(codec));
    });

    test('getCodec returns auto-detecting codec when mimeType is null', () {
      final codec = _MockBinaryCodec();
      registry.registerCodec(codec);

      final autoCodec = registry.getCodec(null);
      expect(autoCodec, isNotNull);
      // Should be able to decode using auto-detection
      final result = autoCodec.decode(Uint8List.fromList([0xDE, 0xAD]));
      expect(result, isA<RdfGraph>());
    });

    test('getCodec throws when no codecs registered and mimeType is null', () {
      expect(
        () => registry.getCodec(null),
        throwsA(isA<CodecNotSupportedException>()),
      );
    });

    test('getAllCodecs returns all registered codecs', () {
      final codec1 = _MockBinaryCodec();
      final codec2 = _MockBinaryCodec2();

      registry.registerCodec(codec1);
      registry.registerCodec(codec2);

      final codecs = registry.getAllCodecs();
      expect(codecs, hasLength(2));
      expect(codecs, contains(codec1));
      expect(codecs, contains(codec2));
    });

    test('allMimeTypes returns all supported MIME types', () {
      final codec = _MockBinaryCodec();
      registry.registerCodec(codec);

      expect(
        registry.allMimeTypes,
        containsAll({'application/x-test-binary', 'application/x-test-alt'}),
      );
    });

    test('detectCodec returns matching codec', () {
      final neverMatch = _MockBinaryCodec(canParse: false);
      final alwaysMatch = _MockBinaryCodec2();

      registry.registerCodec(neverMatch);
      registry.registerCodec(alwaysMatch);

      final detected = registry.detectCodec(Uint8List.fromList([0x01]));
      expect(detected, equals(alwaysMatch));
    });

    test('detectCodec returns null when no codec matches', () {
      final neverMatch = _MockBinaryCodec(canParse: false);
      registry.registerCodec(neverMatch);

      final detected = registry.detectCodec(Uint8List.fromList([0x01]));
      expect(detected, isNull);
    });

    test('clear removes all codecs', () {
      registry.registerCodec(_MockBinaryCodec());
      registry.clear();

      expect(registry.getAllCodecs(), isEmpty);
      expect(
        () => registry.getCodec('application/x-test-binary'),
        throwsA(isA<CodecNotSupportedException>()),
      );
    });
  });

  group('Auto-detecting binary decoder', () {
    test('tries each codec in sequence when detection fails', () {
      final failing = _FailingBinaryCodec();
      final working = _MockBinaryCodec2();

      registry.registerCodec(failing);
      registry.registerCodec(working);

      final autoCodec = registry.getCodec(null);
      final result = autoCodec.decode(Uint8List.fromList([0x01]));
      expect(result, isA<RdfGraph>());
    });

    test('throws when all codecs fail to parse', () {
      final failing1 = _FailingBinaryCodec();
      final failing2 = _FailingBinaryCodec2();

      registry.registerCodec(failing1);
      registry.registerCodec(failing2);

      final autoCodec = registry.getCodec(null);
      expect(
        () => autoCodec.decode(Uint8List.fromList([0x01])),
        throwsA(isA<CodecNotSupportedException>()),
      );
    });
  });
}

// -- Test helpers ------------------------------------------------------------

class _MockBinaryCodec extends RdfBinaryGraphCodec {
  final bool canParse;

  _MockBinaryCodec({this.canParse = true});

  @override
  String get primaryMimeType => 'application/x-test-binary';

  @override
  Set<String> get supportedMimeTypes =>
      {'application/x-test-binary', 'application/x-test-alt'};

  @override
  RdfBinaryGraphDecoder get decoder => _MockBinaryDecoder();

  @override
  RdfBinaryGraphEncoder get encoder => _MockBinaryEncoder();

  @override
  bool canParseBytes(Uint8List content) => canParse;

  @override
  RdfBinaryGraphCodec withOptions({
    RdfBinaryEncoderOptions? encoder,
    RdfBinaryDecoderOptions? decoder,
  }) =>
      this;
}

class _MockBinaryCodec2 extends RdfBinaryGraphCodec {
  @override
  String get primaryMimeType => 'application/x-test-binary-2';

  @override
  Set<String> get supportedMimeTypes => {'application/x-test-binary-2'};

  @override
  RdfBinaryGraphDecoder get decoder => _MockBinaryDecoder();

  @override
  RdfBinaryGraphEncoder get encoder => _MockBinaryEncoder();

  @override
  bool canParseBytes(Uint8List content) => true;

  @override
  RdfBinaryGraphCodec withOptions({
    RdfBinaryEncoderOptions? encoder,
    RdfBinaryDecoderOptions? decoder,
  }) =>
      this;
}

class _FailingBinaryCodec extends RdfBinaryGraphCodec {
  @override
  String get primaryMimeType => 'application/x-failing';

  @override
  Set<String> get supportedMimeTypes => {'application/x-failing'};

  @override
  RdfBinaryGraphDecoder get decoder => _FailingBinaryDecoder('error 1');

  @override
  RdfBinaryGraphEncoder get encoder => _MockBinaryEncoder();

  @override
  bool canParseBytes(Uint8List content) => false;

  @override
  RdfBinaryGraphCodec withOptions({
    RdfBinaryEncoderOptions? encoder,
    RdfBinaryDecoderOptions? decoder,
  }) =>
      this;
}

class _FailingBinaryCodec2 extends RdfBinaryGraphCodec {
  @override
  String get primaryMimeType => 'application/x-failing-2';

  @override
  Set<String> get supportedMimeTypes => {'application/x-failing-2'};

  @override
  RdfBinaryGraphDecoder get decoder => _FailingBinaryDecoder('error 2');

  @override
  RdfBinaryGraphEncoder get encoder => _MockBinaryEncoder();

  @override
  bool canParseBytes(Uint8List content) => false;

  @override
  RdfBinaryGraphCodec withOptions({
    RdfBinaryEncoderOptions? encoder,
    RdfBinaryDecoderOptions? decoder,
  }) =>
      this;
}

class _MockBinaryDecoder extends RdfBinaryGraphDecoder {
  @override
  RdfGraph convert(Uint8List input) => RdfGraph();

  @override
  RdfBinaryGraphDecoder withOptions(RdfBinaryDecoderOptions options) => this;
}

class _FailingBinaryDecoder extends RdfBinaryGraphDecoder {
  final String message;

  _FailingBinaryDecoder(this.message);

  @override
  RdfGraph convert(Uint8List input) => throw FormatException(message);

  @override
  RdfBinaryGraphDecoder withOptions(RdfBinaryDecoderOptions options) => this;
}

class _MockBinaryEncoder extends RdfBinaryGraphEncoder {
  @override
  Uint8List convert(RdfGraph graph) => Uint8List.fromList([0xDE, 0xAD]);

  @override
  RdfBinaryGraphEncoder withOptions(RdfBinaryEncoderOptions options) => this;
}
