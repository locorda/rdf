import 'dart:typed_data';

import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('RdfCore binary integration', () {
    late RdfCore rdfCore;
    final mockCodec = _MockJellyGraphCodec();
    final mockDatasetCodec = _MockJellyDatasetCodec();

    setUp(() {
      rdfCore = RdfCore.withStandardCodecs(
        additionalBinaryGraphCodecs: [mockCodec],
        additionalBinaryDatasetCodecs: [mockDatasetCodec],
      );
    });

    test('decodeBinary delegates to binary graph codec', () {
      final graph = rdfCore.decodeBinary(
        Uint8List.fromList([0x01, 0x02]),
        contentType: 'application/x-jelly-rdf',
      );
      expect(graph, isA<RdfGraph>());
    });

    test('encodeBinary delegates to binary graph codec', () {
      final bytes = rdfCore.encodeBinary(
        RdfGraph(),
        contentType: 'application/x-jelly-rdf',
      );
      expect(bytes, isNotEmpty);
    });

    test('decodeBinaryDataset delegates to binary dataset codec', () {
      final dataset = rdfCore.decodeBinaryDataset(
        Uint8List.fromList([0x01, 0x02]),
        contentType: 'application/x-jelly-rdf',
      );
      expect(dataset, isA<RdfDataset>());
    });

    test('encodeBinaryDataset delegates to binary dataset codec', () {
      final bytes = rdfCore.encodeBinaryDataset(
        RdfDataset.empty(),
        contentType: 'application/x-jelly-rdf',
      );
      expect(bytes, isNotEmpty);
    });

    test('binaryGraphCodec returns codec for MIME type', () {
      final codec =
          rdfCore.binaryGraphCodec(contentType: 'application/x-jelly-rdf');
      expect(codec.primaryMimeType, 'application/x-jelly-rdf');
    });

    test('binaryGraphCodec throws for unknown MIME type', () {
      expect(
        () => rdfCore.binaryGraphCodec(contentType: 'application/unknown'),
        throwsA(isA<CodecNotSupportedException>()),
      );
    });

    test('decodeBinary throws when no binary codecs registered', () {
      final coreWithoutBinary = RdfCore.withStandardCodecs();
      expect(
        () => coreWithoutBinary.decodeBinary(Uint8List.fromList([0x01])),
        throwsA(isA<CodecNotSupportedException>()),
      );
    });

    test('withCodecs accepts binary codecs', () {
      final core = RdfCore.withCodecs(
        binaryGraphCodecs: [mockCodec],
        binaryDatasetCodecs: [mockDatasetCodec],
      );
      final graph = core.decodeBinary(
        Uint8List.fromList([0x01]),
        contentType: 'application/x-jelly-rdf',
      );
      expect(graph, isA<RdfGraph>());
    });
  });
}

// -- Test helpers ------------------------------------------------------------

class _MockJellyGraphCodec extends RdfBinaryGraphCodec {
  @override
  String get primaryMimeType => 'application/x-jelly-rdf';

  @override
  Set<String> get supportedMimeTypes => {'application/x-jelly-rdf'};

  @override
  RdfBinaryGraphDecoder get decoder => _MockGraphDecoder();

  @override
  RdfBinaryGraphEncoder get encoder => _MockGraphEncoder();

  @override
  bool canParseBytes(Uint8List content) => true;

  @override
  RdfBinaryGraphCodec withOptions({
    RdfBinaryEncoderOptions? encoder,
    RdfBinaryDecoderOptions? decoder,
  }) =>
      this;
}

class _MockJellyDatasetCodec extends RdfBinaryDatasetCodec {
  @override
  String get primaryMimeType => 'application/x-jelly-rdf';

  @override
  Set<String> get supportedMimeTypes => {'application/x-jelly-rdf'};

  @override
  RdfBinaryDatasetDecoder get decoder => _MockDatasetDecoder();

  @override
  RdfBinaryDatasetEncoder get encoder => _MockDatasetEncoder();

  @override
  bool canParseBytes(Uint8List content) => true;

  @override
  RdfBinaryDatasetCodec withOptions({
    RdfBinaryEncoderOptions? encoder,
    RdfBinaryDecoderOptions? decoder,
  }) =>
      this;
}

class _MockGraphDecoder extends RdfBinaryGraphDecoder {
  @override
  RdfGraph convert(Uint8List input) => RdfGraph();

  @override
  RdfBinaryGraphDecoder withOptions(RdfBinaryDecoderOptions options) => this;
}

class _MockGraphEncoder extends RdfBinaryGraphEncoder {
  @override
  Uint8List convert(RdfGraph graph) => Uint8List.fromList([0xDE, 0xAD]);

  @override
  RdfBinaryGraphEncoder withOptions(RdfBinaryEncoderOptions options) => this;
}

class _MockDatasetDecoder extends RdfBinaryDatasetDecoder {
  @override
  RdfDataset convert(Uint8List input) => RdfDataset.empty();

  @override
  RdfBinaryDatasetDecoder withOptions(RdfBinaryDecoderOptions options) => this;
}

class _MockDatasetEncoder extends RdfBinaryDatasetEncoder {
  @override
  Uint8List convert(RdfDataset dataset) => Uint8List.fromList([0xBE, 0xEF]);

  @override
  RdfBinaryDatasetEncoder withOptions(RdfBinaryEncoderOptions options) => this;
}
