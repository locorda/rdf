/// JSON-LD external context document loading infrastructure.
///
/// This library provides interfaces and implementations for loading
/// external JSON-LD context documents referenced by string values
/// in `@context`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:locorda_rdf_core/core.dart';

/// JSON type aliases for clearer parser contracts.
typedef JsonValue = Object?;
typedef JsonObject = Map<String, JsonValue>;
typedef JsonArray = List<JsonValue>;

JsonValue parseJsonValueOrThrow(
  String source, {
  required String format,
  String? location,
}) {
  try {
    return json.decode(source) as JsonValue;
  } catch (e) {
    final locationSuffix = location == null ? '' : ' at $location';
    throw RdfSyntaxException(
      'Invalid JSON syntax$locationSuffix: $e',
      format: format,
      cause: e,
    );
  }
}

/// Full input for loading an external JSON-LD context.
class JsonLdContextDocumentRequest {
  /// Raw `@context` entry value from the JSON-LD document.
  final String contextReference;

  /// Effective base IRI used to resolve [contextReference].
  final String? baseIri;

  /// Fully resolved context IRI.
  final String resolvedContextIri;

  const JsonLdContextDocumentRequest({
    required this.contextReference,
    required this.baseIri,
    required this.resolvedContextIri,
  });
}

/// Sync provider abstraction for external JSON-LD context documents.
abstract interface class JsonLdContextDocumentProvider {
  JsonValue loadContextDocument(JsonLdContextDocumentRequest request);
}

/// Async provider abstraction for external JSON-LD context documents.
abstract interface class AsyncJsonLdContextDocumentProvider {
  Future<JsonValue> loadContextDocumentAsync(
      JsonLdContextDocumentRequest request);
}

/// Built-in provider that maps canonical IRI prefixes to local filesystem
/// locations and loads/decodes context documents from disk.
class MappedFileJsonLdContextDocumentProvider
    implements
        JsonLdContextDocumentProvider,
        AsyncJsonLdContextDocumentProvider {
  final Map<String, String> iriPrefixMappings;

  const MappedFileJsonLdContextDocumentProvider({
    this.iriPrefixMappings = const {},
  });

  @override
  JsonValue loadContextDocument(JsonLdContextDocumentRequest request) {
    final mappedIri = _applyMappings(request.resolvedContextIri);
    final uri = Uri.tryParse(mappedIri);

    if (uri != null && uri.scheme == 'file') {
      final file = File.fromUri(uri);
      if (!file.existsSync()) return null;
      return _decodeDocument(file.readAsStringSync(), mappedIri);
    }

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return null;
    }

    final file = File(mappedIri);
    if (!file.existsSync()) return null;
    return _decodeDocument(file.readAsStringSync(), mappedIri);
  }

  @override
  Future<JsonValue> loadContextDocumentAsync(
    JsonLdContextDocumentRequest request,
  ) async {
    final mappedIri = _applyMappings(request.resolvedContextIri);
    final uri = Uri.tryParse(mappedIri);

    if (uri != null && uri.scheme == 'file') {
      final file = File.fromUri(uri);
      if (!file.existsSync()) return null;
      return _decodeDocument(await file.readAsString(), mappedIri);
    }

    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return null;
    }

    final file = File(mappedIri);
    if (!file.existsSync()) return null;
    return _decodeDocument(await file.readAsString(), mappedIri);
  }

  String _applyMappings(String iri) {
    if (iriPrefixMappings.isEmpty) return iri;

    final sortedKeys = iriPrefixMappings.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final sourcePrefix in sortedKeys) {
      if (iri.startsWith(sourcePrefix)) {
        final targetPrefix = iriPrefixMappings[sourcePrefix]!;
        final suffix = iri.substring(sourcePrefix.length);
        return '$targetPrefix$suffix';
      }
    }

    return iri;
  }

  JsonValue _decodeDocument(String content, String location) {
    try {
      return json.decode(content);
    } catch (_) {
      // Return raw content for custom processing in decoder fallback path.
      return content;
    }
  }
}

/// Cross-request cache for parsed external context documents.
abstract interface class JsonLdContextDocumentCache {
  JsonValue getParsed(String resolvedContextIri);

  void putParsed(String resolvedContextIri, JsonValue parsedContextDocument);
}

/// In-memory cache implementation for parsed external context documents.
class InMemoryJsonLdContextDocumentCache implements JsonLdContextDocumentCache {
  final JsonObject _parsedDocuments = {};

  @override
  JsonValue getParsed(String resolvedContextIri) =>
      _parsedDocuments[resolvedContextIri];

  @override
  void putParsed(String resolvedContextIri, JsonValue parsedContextDocument) {
    _parsedDocuments[resolvedContextIri] = parsedContextDocument;
  }
}
