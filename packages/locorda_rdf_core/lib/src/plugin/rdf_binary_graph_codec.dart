/// RDF Binary Graph Codec Plugin System
///
/// Defines the plugin architecture for binary RDF graph serialization formats.
/// This parallels [RdfGraphCodec] but operates on [Uint8List] instead of
/// [String].
library;

import 'dart:typed_data';

import 'package:locorda_rdf_core/src/plugin/rdf_binary_base_codec.dart';
import 'package:locorda_rdf_core/src/plugin/rdf_binary_codec_registry.dart';
import 'package:locorda_rdf_core/src/rdf_binary_decoder.dart';
import 'package:locorda_rdf_core/src/rdf_binary_encoder.dart';
import 'package:locorda_rdf_core/src/rdf_binary_graph_decoder.dart';
import 'package:locorda_rdf_core/src/rdf_binary_graph_encoder.dart';

import '../graph/rdf_graph.dart';

/// A binary codec for RDF graph serialization formats.
///
/// Extends [RdfBinaryCodec] specialized for [RdfGraph]. Implementations
/// provide binary encoding and decoding of RDF graphs (e.g., Jelly TRIPLES
/// streams).
///
/// To add support for a new binary graph format, extend this class and
/// register an instance with [RdfBinaryGraphCodecRegistry].
///
/// Example:
/// ```dart
/// class MyBinaryCodec extends RdfBinaryGraphCodec {
///   @override
///   String get primaryMimeType => 'application/x-my-binary';
///
///   @override
///   Set<String> get supportedMimeTypes => {primaryMimeType};
///
///   @override
///   RdfBinaryGraphDecoder get decoder => MyBinaryDecoder();
///
///   @override
///   RdfBinaryGraphEncoder get encoder => MyBinaryEncoder();
///
///   @override
///   bool canParseBytes(Uint8List content) => /* check magic bytes */;
///
///   @override
///   RdfBinaryGraphCodec withOptions({
///     RdfBinaryEncoderOptions? encoder,
///     RdfBinaryDecoderOptions? decoder,
///   }) => this;
/// }
/// ```
abstract class RdfBinaryGraphCodec extends RdfBinaryCodec<RdfGraph> {
  @override
  RdfBinaryGraphDecoder get decoder;

  @override
  RdfBinaryGraphEncoder get encoder;

  const RdfBinaryGraphCodec();

  @override
  RdfBinaryGraphCodec withOptions({
    RdfBinaryEncoderOptions? encoder,
    RdfBinaryDecoderOptions? decoder,
  });
}

/// Manages registration and discovery of binary RDF graph codec plugins.
///
/// This registry acts as the central point for binary graph codec plugin
/// management, mirroring [RdfCodecRegistry] for binary formats.
final class RdfBinaryGraphCodecRegistry {
  final BaseRdfBinaryCodecRegistry<RdfGraph> _registry;

  /// Creates a new binary graph codec registry.
  ///
  /// Optionally accepts a list of codecs to register immediately.
  RdfBinaryGraphCodecRegistry(
      [List<RdfBinaryGraphCodec> initialCodecs = const []])
      : _registry = BaseRdfBinaryCodecRegistry() {
    for (final codec in initialCodecs) {
      registerCodec(codec);
    }
  }

  /// Registers a binary graph codec with this registry.
  void registerCodec(RdfBinaryGraphCodec codec) {
    _registry.registerCodec(codec);
  }

  /// Returns all MIME types supported by registered binary graph codecs.
  Set<String> get allMimeTypes => _registry.allMimeTypes;

  /// Returns all registered binary graph codecs.
  List<RdfBinaryGraphCodec> getAllCodecs() =>
      _registry.getAllCodecs().cast<RdfBinaryGraphCodec>();

  /// Retrieves a codec by MIME type.
  ///
  /// If [mimeType] is null, returns an auto-detecting codec.
  ///
  /// Throws [CodecNotSupportedException] if no codec matches.
  RdfBinaryGraphCodec getCodec(String? mimeType) {
    final codec = _registry.getCodec(mimeType);
    return codec is RdfBinaryGraphCodec
        ? codec
        : _RdfBinaryGraphCodecWrapper(codec);
  }

  /// Attempts to detect a codec from binary content.
  ///
  /// Returns the first codec whose [canParseBytes] returns true, or null.
  RdfBinaryGraphCodec? detectCodec(Uint8List content) {
    final result = _registry.detectCodec(content);
    if (result == null) return null;
    return result is RdfBinaryGraphCodec
        ? result
        : _RdfBinaryGraphCodecWrapper(result);
  }

  /// Clears all registered codecs (mainly for testing).
  void clear() => _registry.clear();
}

/// Wraps a generic `RdfBinaryCodec<RdfGraph>` as an `RdfBinaryGraphCodec`.
class _RdfBinaryGraphCodecWrapper extends RdfBinaryGraphCodec {
  final RdfBinaryCodec<RdfGraph> _inner;

  _RdfBinaryGraphCodecWrapper(this._inner);

  @override
  RdfBinaryGraphCodec withOptions({
    RdfBinaryEncoderOptions? encoder,
    RdfBinaryDecoderOptions? decoder,
  }) =>
      _RdfBinaryGraphCodecWrapper(
          _inner.withOptions(encoder: encoder, decoder: decoder));

  @override
  String get primaryMimeType => _inner.primaryMimeType;

  @override
  Set<String> get supportedMimeTypes => _inner.supportedMimeTypes;

  @override
  RdfBinaryGraphDecoder get decoder {
    final d = _inner.decoder;
    return d is RdfBinaryGraphDecoder ? d : _RdfBinaryGraphDecoderWrapper(d);
  }

  @override
  RdfBinaryGraphEncoder get encoder {
    final e = _inner.encoder;
    return e is RdfBinaryGraphEncoder ? e : _RdfBinaryGraphEncoderWrapper(e);
  }

  @override
  bool canParseBytes(Uint8List content) => _inner.canParseBytes(content);
}

class _RdfBinaryGraphDecoderWrapper extends RdfBinaryGraphDecoder {
  final RdfBinaryDecoder<RdfGraph> _inner;

  _RdfBinaryGraphDecoderWrapper(this._inner);

  @override
  RdfBinaryGraphDecoder withOptions(RdfBinaryDecoderOptions options) =>
      _RdfBinaryGraphDecoderWrapper(_inner.withOptions(options));

  @override
  RdfGraph convert(Uint8List input) => _inner.convert(input);
}

class _RdfBinaryGraphEncoderWrapper extends RdfBinaryGraphEncoder {
  final RdfBinaryEncoder<RdfGraph> _inner;

  _RdfBinaryGraphEncoderWrapper(this._inner);

  @override
  RdfBinaryGraphEncoder withOptions(RdfBinaryEncoderOptions options) =>
      _RdfBinaryGraphEncoderWrapper(_inner.withOptions(options));

  @override
  Uint8List convert(RdfGraph graph) => _inner.convert(graph);
}
