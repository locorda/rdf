/// RDF Binary Codec Registry
///
/// Provides the base registry for binary RDF codec plugins, mirroring
/// [BaseRdfCodecRegistry] for binary formats.
library;

import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:locorda_rdf_core/src/plugin/exceptions.dart';
import 'package:locorda_rdf_core/src/plugin/rdf_binary_base_codec.dart';
import 'package:locorda_rdf_core/src/rdf_binary_decoder.dart';
import 'package:locorda_rdf_core/src/rdf_binary_encoder.dart';

/// Base registry for binary RDF codecs.
///
/// Manages registration of binary codecs by MIME type and provides
/// auto-detection of binary formats. This mirrors [BaseRdfCodecRegistry]
/// but works with [RdfBinaryCodec] instances.
class BaseRdfBinaryCodecRegistry<G> {
  final _logger = Logger('rdf.binary_codec_registry');
  final Map<String, RdfBinaryCodec<G>> _codecsByMimeType = {};
  final List<RdfBinaryCodec<G>> _codecs = [];

  BaseRdfBinaryCodecRegistry();

  /// Registers a binary codec with this registry.
  ///
  /// Makes the codec available for all its [supportedMimeTypes].
  void registerCodec(RdfBinaryCodec<G> codec) {
    _logger.fine(
        'Registering binary rdf codec: ${codec.primaryMimeType} for $this');
    _codecs.add(codec);

    for (final mimeType in codec.supportedMimeTypes) {
      final normalized = _normalizeMimeType(mimeType);
      _codecsByMimeType[normalized] = codec;
    }
  }

  /// Returns all MIME types supported by all registered codecs.
  Set<String> get allMimeTypes {
    final mimeTypes = <String>{};
    for (final codec in _codecs) {
      mimeTypes.addAll(codec.supportedMimeTypes);
    }
    return Set.unmodifiable(mimeTypes);
  }

  /// Retrieves a codec by MIME type.
  ///
  /// If [mimeType] is null, returns an auto-detecting codec.
  ///
  /// Throws [CodecNotSupportedException] if no codec matches.
  RdfBinaryCodec<G> getCodec(String? mimeType) {
    if (mimeType != null) {
      final result = _codecsByMimeType[_normalizeMimeType(mimeType)];
      if (result == null) {
        throw CodecNotSupportedException(
          'No binary codec registered for MIME type: $mimeType',
        );
      }
      return result;
    }

    if (_codecs.isEmpty) {
      throw CodecNotSupportedException('No binary codecs registered');
    }

    return _AutoDetectingRdfBinaryCodec<G>(
      defaultCodec: _codecs.first,
      registry: this,
    );
  }

  /// Returns all registered codecs.
  List<RdfBinaryCodec<G>> getAllCodecs() => List.unmodifiable(_codecs);

  /// Attempts to detect a codec from binary content.
  ///
  /// Returns the first codec whose [canParseBytes] returns true, or null.
  RdfBinaryCodec<G>? detectCodec(Uint8List content) {
    _logger.fine('Attempting to detect binary codec from content');

    for (final codec in _codecs) {
      if (codec.canParseBytes(content)) {
        _logger.fine('Detected binary codec: ${codec.primaryMimeType}');
        return codec;
      }
    }

    _logger.fine('No binary codec detected');
    return null;
  }

  /// Clears all registered codecs (mainly for testing).
  void clear() {
    _codecs.clear();
    _codecsByMimeType.clear();
  }

  static String _normalizeMimeType(String mimeType) {
    return mimeType.trim().toLowerCase();
  }
}

/// A binary codec that auto-detects the format during decoding.
///
/// Uses the registry to try each registered codec when decoding.
/// Encodes using the default (first registered) codec.
class _AutoDetectingRdfBinaryCodec<G> extends RdfBinaryCodec<G> {
  final RdfBinaryCodec<G> _defaultCodec;
  final BaseRdfBinaryCodecRegistry<G> _registry;
  final RdfBinaryEncoderOptions? _encoderOptions;
  final RdfBinaryDecoderOptions? _decoderOptions;

  _AutoDetectingRdfBinaryCodec({
    required RdfBinaryCodec<G> defaultCodec,
    required BaseRdfBinaryCodecRegistry<G> registry,
    RdfBinaryEncoderOptions? encoderOptions,
    RdfBinaryDecoderOptions? decoderOptions,
  })  : _defaultCodec = defaultCodec,
        _registry = registry,
        _encoderOptions = encoderOptions,
        _decoderOptions = decoderOptions;

  @override
  RdfBinaryCodec<G> withOptions({
    RdfBinaryEncoderOptions? encoder,
    RdfBinaryDecoderOptions? decoder,
  }) =>
      _AutoDetectingRdfBinaryCodec(
        defaultCodec: _defaultCodec,
        registry: _registry,
        encoderOptions: encoder ?? _encoderOptions,
        decoderOptions: decoder ?? _decoderOptions,
      );

  @override
  String get primaryMimeType => _defaultCodec.primaryMimeType;

  @override
  Set<String> get supportedMimeTypes => _registry.allMimeTypes;

  @override
  RdfBinaryDecoder<G> get decoder =>
      _AutoDetectingRdfBinaryDecoder(_registry, options: _decoderOptions);

  @override
  RdfBinaryEncoder<G> get encoder {
    if (_encoderOptions != null) {
      return _defaultCodec.encoder.withOptions(_encoderOptions);
    }
    return _defaultCodec.encoder;
  }

  @override
  bool canParseBytes(Uint8List content) {
    return _registry.detectCodec(content) != null;
  }
}

/// A binary decoder that auto-detects the format from content.
class _AutoDetectingRdfBinaryDecoder<G> extends RdfBinaryDecoder<G> {
  final _logger = Logger('rdf.binary_format_detecting_parser');
  final BaseRdfBinaryCodecRegistry<G> _registry;
  final RdfBinaryDecoderOptions? _decoderOptions;

  _AutoDetectingRdfBinaryDecoder(this._registry,
      {RdfBinaryDecoderOptions? options})
      : _decoderOptions = options;

  @override
  RdfBinaryDecoder<G> withOptions(RdfBinaryDecoderOptions options) =>
      _AutoDetectingRdfBinaryDecoder(_registry, options: options);

  @override
  G convert(Uint8List input) {
    final format = _registry.detectCodec(input);
    Object? selectedFormatException;
    if (format != null) {
      _logger.fine('Using detected binary format: ${format.primaryMimeType}');
      try {
        return (_decoderOptions == null
                ? format.decoder
                : format.decoder.withOptions(_decoderOptions))
            .convert(input);
      } catch (e) {
        _logger.fine(
          'Failed with detected binary format ${format.primaryMimeType}: $e',
        );
        selectedFormatException = e;
      }
    }

    final codecs = _registry.getAllCodecs();
    if (codecs.isEmpty) {
      throw CodecNotSupportedException('No binary RDF codecs registered');
    }

    Exception? lastException;
    for (final codec in codecs) {
      try {
        _logger.fine('Trying binary codec: ${codec.primaryMimeType}');
        return (_decoderOptions == null
                ? codec.decoder
                : codec.decoder.withOptions(_decoderOptions))
            .convert(input);
      } catch (e) {
        _logger.fine(
            'Failed with binary format ${codec.primaryMimeType}: $e');
        lastException = e is Exception ? e : Exception(e.toString());
      }
    }

    throw CodecNotSupportedException(
      'Could not parse binary content with any registered codec: '
      '${(selectedFormatException ?? lastException)?.toString() ?? "unknown error"}',
    );
  }
}
