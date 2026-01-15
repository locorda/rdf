// Copyright (c) 2025, Klas Kalaß <habbatical@gmail.com>
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'package:build/build.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// Base class for vocabulary sources.
///
/// Provides an abstraction for loading vocabulary content from different sources,
/// such as URLs or local files.
abstract class VocabularySource {
  /// The URI namespace of this vocabulary.
  final String namespace;

  /// Optional set of Turtle parsing flags.
  ///
  /// These flags are passed to the TurtleFormat when parsing Turtle files.
  /// They correspond to the TurtleParsingFlag values from locorda_rdf_core.
  final List<String>? parsingFlags;

  /// Flag indicating if this vocabulary should be processed during generation.
  ///
  /// If set to false, this vocabulary will be skipped during the generation process.
  /// Defaults to true if not specified.
  final bool generate;

  /// Explicit content type for the vocabulary source.
  ///
  /// If provided, this will override the automatic content type detection based on file extension.
  final String? explicitContentType;

  /// Flag indicating if this vocabulary should be deliberately skipped.
  ///
  /// This differs from `enabled` in that it's meant for vocabularies that cannot
  /// be loaded due to licensing restrictions or proprietary content, rather than
  /// just being temporarily disabled.
  final bool skipDownload;

  /// Reason for skipping this vocabulary.
  ///
  /// This provides documentation about why a vocabulary is skipped, especially
  /// useful for proprietary or licensed vocabularies.
  final String? skipDownloadReason;

  const VocabularySource(
    this.namespace, {
    this.parsingFlags,
    this.generate = true,
    this.explicitContentType,
    this.skipDownload = false,
    this.skipDownloadReason,
  });

  /// Loads the vocabulary content.
  ///
  /// Returns the content as a string, which will be parsed by the appropriate
  /// format parser. Implementations should handle different content formats
  /// like Turtle, RDF/XML, etc.
  Future<String> loadContent();

  String get extension;

  String? get contentType {
    if (explicitContentType != null) {
      return explicitContentType;
    }

    return switch (extension) {
      '.ttl' => 'text/turtle',
      '.rdf' => 'application/rdf+xml',
      '.xml' => 'application/rdf+xml',
      '.jsonld' => 'application/ld+json',
      '.nt' => 'application/n-triples',
      _ => null,
    };
  }
}

/// Vocabulary source that loads from a URL.
class UrlVocabularySource extends VocabularySource {
  /// The actual URL to load the vocabulary content from
  final String sourceUrl;

  /// Maximum number of redirects to follow
  final int maxRedirects;

  /// Timeout for HTTP requests in seconds
  final int timeoutSeconds;

  const UrlVocabularySource(
    String namespace, {
    String? sourceUrl,
    this.maxRedirects = 5,
    this.timeoutSeconds = 30,
    List<String>? parsingFlags,
    bool enabled = true,
    String? explicitContentType,
    bool skipDownload = false,
    String? skipDownloadReason,
  }) : sourceUrl = sourceUrl ?? namespace,
       super(
         namespace,
         parsingFlags: parsingFlags,
         generate: enabled,
         explicitContentType: explicitContentType,
         skipDownload: skipDownload,
         skipDownloadReason: skipDownloadReason,
       );

  @override
  Future<String> loadContent() async {
    final client = http.Client();
    try {
      // Add content negotiation headers for RDF
      final headers = {
        if (contentType == null)
          'Accept':
              'text/turtle, application/rdf+xml;q=0.9, application/ld+json;q=0.8, text/html;q=0.7'
        else
          'Accept': contentType!,
        'User-Agent': 'RDF Vocabulary Builder (Dart/HTTP Client)',
      };

      log.info(
        'Loading vocabulary from URL: $sourceUrl (namespace: $namespace)',
      );

      final request = http.Request('GET', Uri.parse(sourceUrl));
      request.headers.addAll(headers);

      // Create a custom HTTP client that can handle redirects manually
      final response = await client
          .send(request)
          .timeout(Duration(seconds: timeoutSeconds));

      // Handle redirects manually to avoid issues with server redirects
      if (response.isRedirect && maxRedirects > 0) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          log.info('Following redirect to: $redirectUrl');
          client.close();
          return await UrlVocabularySource(
            namespace,
            sourceUrl: redirectUrl,
            maxRedirects: maxRedirects - 1,
            timeoutSeconds: timeoutSeconds,
            parsingFlags: parsingFlags,
          ).loadContent();
        }
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load vocabulary from $sourceUrl: ${response.statusCode}',
        );
      }

      final bytes = await response.stream.toBytes();

      // Try to determine the correct encoding
      String? charset;
      if (response.headers.containsKey('content-type')) {
        final contentType = response.headers['content-type']!;
        final charsetMatch = RegExp(
          r'charset=([^\s;]+)',
        ).firstMatch(contentType);
        if (charsetMatch != null) {
          charset = charsetMatch.group(1);
        }
      }

      // Detect format from content-type if available
      if (response.headers.containsKey('content-type')) {
        final contentType = response.headers['content-type']!.toLowerCase();
        if (contentType.contains('turtle')) {
          log.info('Detected Turtle format from Content-Type');
        } else if (contentType.contains('rdf+xml') ||
            contentType.contains('xml')) {
          log.info('Detected RDF/XML format from Content-Type');
        } else if (contentType.contains('json')) {
          log.info('Detected JSON format from Content-Type');
        }
      }

      // Try to decode with the specified charset, fallback to UTF-8
      try {
        if (charset != null) {
          return utf8.decode(bytes, allowMalformed: true);
        } else {
          return utf8.decode(bytes);
        }
      } catch (e) {
        // Fallback to Latin-1 (ISO-8859-1) if UTF-8 decoding fails
        log.warning('UTF-8 decoding failed, trying ISO-8859-1: $e');
        return latin1.decode(bytes);
      }
    } catch (e) {
      throw Exception('Error loading vocabulary from $sourceUrl: $e');
    } finally {
      client.close();
    }
  }

  @override
  String get extension => path.extension(sourceUrl).toLowerCase();

  @override
  String toString() {
    return "UrlVocabularySource{sourceUrl: $sourceUrl, namespace: $namespace}";
  }
}

/// Vocabulary source that loads from a file.
class FileVocabularySource extends VocabularySource {
  final String filePath;

  const FileVocabularySource(
    this.filePath,
    String namespace, {
    List<String>? parsingFlags,
    bool generate = true,
    String? explicitContentType,
    bool skipDownload = false,
    String? skipDownloadReason,
  }) : super(
         namespace,
         parsingFlags: parsingFlags,
         generate: generate,
         explicitContentType: explicitContentType,
         skipDownload: skipDownload,
         skipDownloadReason: skipDownloadReason,
       );

  @override
  Future<String> loadContent() async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Vocabulary file not found: $filePath');
      }

      return await file.readAsString();
    } catch (e) {
      throw Exception('Error loading vocabulary from file $filePath: $e');
    }
  }

  @override
  String get extension => path.extension(filePath).toLowerCase();

  @override
  String toString() {
    return "FileVocabularySource{filePath: $filePath, namespace: $namespace}";
  }
}

/// Caching wrapper for vocabulary sources.
///
/// Wraps any VocabularySource and adds transparent file-based caching.
/// When cacheDir is provided, downloaded content is stored on disk using
/// the pattern {name}.{extension} and reused on subsequent loads.
class CachedVocabularySource extends VocabularySource {
  final VocabularySource _innerSource;
  final String _cacheDir;
  final String _vocabularyName;

  CachedVocabularySource(
    this._innerSource,
    this._cacheDir,
    this._vocabularyName,
  ) : super(
          _innerSource.namespace,
          parsingFlags: _innerSource.parsingFlags,
          generate: _innerSource.generate,
          explicitContentType: _innerSource.explicitContentType,
          skipDownload: _innerSource.skipDownload,
          skipDownloadReason: _innerSource.skipDownloadReason,
        );

  /// Generates cache file path using pattern: {name}.{extension}
  String _getCacheFilePath() {
    final fileName = '$_vocabularyName${_innerSource.extension}';
    return path.join(_cacheDir, fileName);
  }

  @override
  Future<String> loadContent() async {
    final cacheFilePath = _getCacheFilePath();
    final cacheFile = File(cacheFilePath);

    // Check if cached file exists
    if (await cacheFile.exists()) {
      log.info('Loading vocabulary from cache: $cacheFilePath');
      return await cacheFile.readAsString();
    }

    // Load from inner source
    log.info('Cache miss, loading from source: ${_innerSource.namespace}');
    final content = await _innerSource.loadContent();

    // Save to cache
    try {
      await cacheFile.parent.create(recursive: true);
      await cacheFile.writeAsString(content);
      log.info('Cached vocabulary to: $cacheFilePath');
    } catch (e) {
      log.warning('Failed to write vocabulary to cache: $e');
      // Continue even if caching fails
    }

    return content;
  }

  @override
  String get extension => _innerSource.extension;

  @override
  String toString() {
    return "CachedVocabularySource{cacheDir: $_cacheDir, inner: $_innerSource}";
  }
}
