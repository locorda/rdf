import 'dart:typed_data';

import 'package:locorda_rdf_core/core.dart';
import 'package:test/test.dart';

void main() {
  group('RdfCore.supportsContentType', () {
    late RdfCore rdfCore;

    setUp(() {
      rdfCore = RdfCore.withStandardCodecs(
        additionalBinaryGraphCodecs: [_MockBinaryGraphCodec()],
        additionalBinaryDatasetCodecs: [_MockBinaryDatasetCodec()],
      );
    });

    test('returns true for a registered text-graph MIME type', () {
      expect(rdfCore.supportsContentType('text/turtle'), isTrue);
    });

    test('returns true for a registered text-dataset MIME type', () {
      expect(rdfCore.supportsContentType('application/n-quads'), isTrue);
    });

    test('returns true for a registered binary MIME type', () {
      expect(rdfCore.supportsContentType('application/x-jelly-rdf'), isTrue);
    });

    test('returns false for an unknown MIME type', () {
      expect(rdfCore.supportsContentType('application/unknown'), isFalse);
    });

    test('is case-insensitive', () {
      expect(rdfCore.supportsContentType('TEXT/TURTLE'), isTrue);
    });

    test('trims whitespace', () {
      expect(rdfCore.supportsContentType('  text/turtle  '), isTrue);
    });
  });

  group('RdfCore.contentTypeInfo', () {
    late RdfCore rdfCore;

    setUp(() {
      rdfCore = RdfCore.withStandardCodecs(
        additionalBinaryGraphCodecs: [_MockBinaryGraphCodec()],
        additionalBinaryDatasetCodecs: [_MockBinaryDatasetCodec()],
      );
    });

    test('returns null for an unknown content type', () {
      expect(rdfCore.contentTypeInfo('application/unknown'), isNull);
    });

    test(
        'text-graph type: isBinary=false, supportsGraph=true, supportsDataset=false',
        () {
      final info = rdfCore.contentTypeInfo('text/turtle');
      expect(info, isNotNull);
      expect(info!.primaryMimeType, 'text/turtle');
      expect(info.isBinary, isFalse);
      expect(info.supportsGraph, isTrue);
      expect(info.supportsDataset, isFalse);
    });

    test(
        'text-dataset type: isBinary=false, supportsGraph=false, supportsDataset=true',
        () {
      final info = rdfCore.contentTypeInfo('application/n-quads');
      expect(info, isNotNull);
      expect(info!.primaryMimeType, 'application/n-quads');
      expect(info.isBinary, isFalse);
      expect(info.supportsGraph, isFalse);
      expect(info.supportsDataset, isTrue);
    });

    test(
        'binary-graph-only type: isBinary=true, supportsGraph=true, supportsDataset=false',
        () {
      final core = RdfCore.withCodecs(
        binaryGraphCodecs: [_MockBinaryGraphCodec()],
      );
      final info = core.contentTypeInfo('application/x-jelly-rdf');
      expect(info, isNotNull);
      expect(info!.isBinary, isTrue);
      expect(info.supportsGraph, isTrue);
      expect(info.supportsDataset, isFalse);
    });

    test(
        'binary-dataset-only type: isBinary=true, supportsGraph=false, supportsDataset=true',
        () {
      final core = RdfCore.withCodecs(
        binaryDatasetCodecs: [_MockBinaryDatasetCodec()],
      );
      final info = core.contentTypeInfo('application/x-jelly-rdf');
      expect(info, isNotNull);
      expect(info!.isBinary, isTrue);
      expect(info.supportsGraph, isFalse);
      expect(info.supportsDataset, isTrue);
    });

    test(
        'type in both binary graph and binary dataset: isBinary=true, supportsGraph=true, supportsDataset=true',
        () {
      // Standard setup registers the mock codec in both binary registries
      final info = rdfCore.contentTypeInfo('application/x-jelly-rdf');
      expect(info, isNotNull);
      expect(info!.isBinary, isTrue);
      expect(info.supportsGraph, isTrue);
      expect(info.supportsDataset, isTrue);
    });

    test('is case-insensitive', () {
      final lower = rdfCore.contentTypeInfo('text/turtle');
      final upper = rdfCore.contentTypeInfo('TEXT/TURTLE');
      expect(upper, equals(lower));
    });

    test('trims whitespace', () {
      final normal = rdfCore.contentTypeInfo('text/turtle');
      final padded = rdfCore.contentTypeInfo('  text/turtle  ');
      expect(padded, equals(normal));
    });

    test(
        'alias MIME type resolves to primary: application/x-turtle -> text/turtle',
        () {
      final info = rdfCore.contentTypeInfo('application/x-turtle');
      expect(info, isNotNull);
      expect(info!.primaryMimeType, 'text/turtle');
      expect(info.supportsGraph, isTrue);
    });

    test('N3 alias resolves to turtle primary MIME type', () {
      final info = rdfCore.contentTypeInfo('text/n3');
      expect(info, isNotNull);
      expect(info!.primaryMimeType, 'text/turtle');
    });

    test('RdfContentTypeInfo equality is value-based', () {
      const a = RdfContentTypeInfo(
          primaryMimeType: 'text/turtle',
          isBinary: false,
          supportsGraph: true,
          supportsDataset: false);
      const b = RdfContentTypeInfo(
          primaryMimeType: 'text/turtle',
          isBinary: false,
          supportsGraph: true,
          supportsDataset: false);
      const c = RdfContentTypeInfo(
          primaryMimeType: 'text/turtle',
          isBinary: true,
          supportsGraph: true,
          supportsDataset: false);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}

// -- Test helpers ------------------------------------------------------------

class _MockBinaryGraphCodec extends RdfBinaryGraphCodec {
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

class _MockBinaryDatasetCodec extends RdfBinaryDatasetCodec {
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
  Uint8List convert(RdfDataset dataset) => Uint8List.fromList([0xDE, 0xAD]);

  @override
  RdfBinaryDatasetEncoder withOptions(RdfBinaryEncoderOptions options) => this;
}
