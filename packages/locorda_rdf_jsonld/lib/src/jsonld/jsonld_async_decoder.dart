/// Async JSON-LD decoder that preloads external contexts before
/// delegating to the synchronous decoder.
library;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/extend.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_codec.dart';
import 'package:locorda_rdf_jsonld/src/jsonld/jsonld_context_documents.dart';

/// Options for [AsyncJsonLdDecoder].
class AsyncJsonLdDecoderOptions {
  final AsyncJsonLdContextDocumentProvider? contextDocumentProvider;

  const AsyncJsonLdDecoderOptions({
    this.contextDocumentProvider,
  });
}

/// Async JSON-LD decoder that preserves the synchronous core parser.
///
/// External contexts are preloaded asynchronously, then passed to the
/// synchronous [JsonLdDecoder] via a [PreloadedJsonLdContextDocumentProvider].
class AsyncJsonLdDecoder {
  final AsyncJsonLdDecoderOptions _options;
  final IriTermFactory _iriTermFactory;
  final String _format;

  const AsyncJsonLdDecoder({
    AsyncJsonLdDecoderOptions options = const AsyncJsonLdDecoderOptions(),
    IriTermFactory iriTermFactory = IriTerm.validated,
    String format = 'JSON-LD',
  })  : _options = options,
        _iriTermFactory = iriTermFactory,
        _format = format;

  Future<RdfDataset> convert(String input, {String? documentUrl}) async {
    final preloadedDocuments = <String, JsonValue>{};
    final asyncProvider = _options.contextDocumentProvider;

    if (asyncProvider != null) {
      final root = parseJsonValueOrThrow(input, format: _format);

      final seen = <String>{};
      await _preloadExternalContexts(
        root,
        effectiveBaseIri: documentUrl,
        seenContextIris: seen,
        preloadedDocuments: preloadedDocuments,
      );
    }

    return JsonLdDecoder(
      options: JsonLdDecoderOptions(
        contextDocumentProvider:
            PreloadedJsonLdContextDocumentProvider(preloadedDocuments),
      ),
      iriTermFactory: _iriTermFactory,
      format: _format,
    ).convert(input, documentUrl: documentUrl);
  }

  Future<void> _preloadExternalContexts(
    JsonValue node, {
    required String? effectiveBaseIri,
    required Set<String> seenContextIris,
    required Map<String, JsonValue> preloadedDocuments,
  }) async {
    if (node is JsonArray) {
      for (final item in node) {
        await _preloadExternalContexts(
          item,
          effectiveBaseIri: effectiveBaseIri,
          seenContextIris: seenContextIris,
          preloadedDocuments: preloadedDocuments,
        );
      }
      return;
    }

    if (node is! JsonObject) {
      return;
    }

    if (node.containsKey('@context')) {
      await _preloadContextDefinition(
        node['@context'],
        effectiveBaseIri: effectiveBaseIri,
        seenContextIris: seenContextIris,
        preloadedDocuments: preloadedDocuments,
      );
    }

    // Look for scoped contexts in term definitions.
    if (node.containsKey('@context') && node['@context'] is JsonObject) {
      final contextMap = node['@context'] as JsonObject;
      for (final value in contextMap.values) {
        if (value is JsonObject && value.containsKey('@context')) {
          await _preloadContextDefinition(
            value['@context'],
            effectiveBaseIri: effectiveBaseIri,
            seenContextIris: seenContextIris,
            preloadedDocuments: preloadedDocuments,
          );
        }
      }
    }
  }

  Future<void> _preloadContextDefinition(
    JsonValue definition, {
    required String? effectiveBaseIri,
    required Set<String> seenContextIris,
    required Map<String, JsonValue> preloadedDocuments,
  }) async {
    if (definition is JsonArray) {
      for (final item in definition) {
        await _preloadContextDefinition(
          item,
          effectiveBaseIri: effectiveBaseIri,
          seenContextIris: seenContextIris,
          preloadedDocuments: preloadedDocuments,
        );
      }
      return;
    }

    if (definition is String) {
      final resolvedContextIri = resolveIri(definition, effectiveBaseIri);

      if (seenContextIris.contains(resolvedContextIri)) {
        return;
      }
      seenContextIris.add(resolvedContextIri);

      if (preloadedDocuments.containsKey(resolvedContextIri)) {
        return;
      }

      final provider = _options.contextDocumentProvider;
      if (provider == null) return;

      final request = JsonLdContextDocumentRequest(
        contextReference: definition,
        baseIri: effectiveBaseIri,
        resolvedContextIri: resolvedContextIri,
      );
      final loaded = await provider.loadContextDocumentAsync(request);

      if (loaded == null) {
        throw RdfSyntaxException(
          'Unable to resolve external context: $resolvedContextIri',
          format: _format,
        );
      }

      preloadedDocuments[resolvedContextIri] = loaded;

      await _preloadExternalContexts(
        loaded,
        effectiveBaseIri: resolvedContextIri,
        seenContextIris: seenContextIris,
        preloadedDocuments: preloadedDocuments,
      );
      return;
    }

    if (definition is JsonObject) {
      var nestedBase = effectiveBaseIri;
      if (definition.containsKey('@base') && definition['@base'] is String) {
        nestedBase =
            resolveIri(definition['@base'] as String, effectiveBaseIri);
      } else if (definition.containsKey('@base') &&
          definition['@base'] == null) {
        nestedBase = null;
      }

      if (definition.containsKey('@context')) {
        await _preloadContextDefinition(
          definition['@context'],
          effectiveBaseIri: nestedBase,
          seenContextIris: seenContextIris,
          preloadedDocuments: preloadedDocuments,
        );
      }

      for (final value in definition.values) {
        if (value is JsonObject && value.containsKey('@context')) {
          await _preloadContextDefinition(
            value['@context'],
            effectiveBaseIri: nestedBase,
            seenContextIris: seenContextIris,
            preloadedDocuments: preloadedDocuments,
          );
        }
      }
    }
  }
}
