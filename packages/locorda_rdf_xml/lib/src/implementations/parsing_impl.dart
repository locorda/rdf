/// Default implementations of XML parsing interfaces
///
/// Provides concrete implementations of the XML parsing interfaces
/// defined in the interfaces directory.
library rdfxml.parsing.implementations;

import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_core/extend.dart';
import 'package:xml/xml.dart';

import '../exceptions.dart';
import '../interfaces/xml_parsing.dart';
import 'parsing_context.dart';

/// Default implementation of IXmlDocumentProvider
///
/// Uses the xml package to parse XML documents.
final class DefaultXmlDocumentProvider implements IXmlDocumentProvider {
  /// Creates a new DefaultXmlDocumentProvider
  const DefaultXmlDocumentProvider();

  @override
  XmlDocument parseXml(String input) {
    // Extract entity declarations from DOCTYPE and create custom entity mapping
    final entityMapping = _extractEntityMapping(input);

    return XmlDocument.parse(input, entityMapping: entityMapping);
  }

  /// Extracts entity declarations from DOCTYPE and creates an entity mapping
  ///
  /// Parses DOCTYPE declarations like:
  /// <!ENTITY cmns-dt "https://www.omg.org/spec/Commons/DatesAndTimes/">
  ///
  /// Returns an XmlEntityMapping that resolves these custom entities
  XmlEntityMapping _extractEntityMapping(String input) {
    final entities = <String, String>{};

    // Look for DOCTYPE declaration
    final doctypeRegex = RegExp(
      r'<!DOCTYPE[^>]*\[(.*?)\]>',
      multiLine: true,
      dotAll: true,
    );

    final doctypeMatch = doctypeRegex.firstMatch(input);
    if (doctypeMatch != null) {
      final doctypeContent = doctypeMatch.group(1) ?? '';

      // Extract entity declarations
      // Format: <!ENTITY name "value" > or <!ENTITY name "value">
      // Note: \s* handles optional whitespace before the closing >
      final entityRegex = RegExp(
        r'<!ENTITY\s+(\S+)\s+"([^"]+)"\s*>',
        multiLine: true,
      );

      for (final match in entityRegex.allMatches(doctypeContent)) {
        final entityName = match.group(1);
        final entityValue = match.group(2);
        if (entityName != null && entityValue != null) {
          entities[entityName] = entityValue;
        }
      }
    }

    // Return custom entity mapping combining HTML5 and DOCTYPE entities
    return _DoctypeEntityMapping(entities);
  }
}

/// Custom entity mapping that combines HTML5 entities with DOCTYPE-declared entities
class _DoctypeEntityMapping extends XmlEntityMapping {
  final Map<String, String> _customEntities;
  final XmlEntityMapping _htmlMapping = XmlDefaultEntityMapping.html5();

  _DoctypeEntityMapping(this._customEntities);

  @override
  String? decodeEntity(String input) {
    // First try custom entities
    if (_customEntities.containsKey(input)) {
      return _customEntities[input];
    }
    // Fall back to HTML5 entities
    return _htmlMapping.decodeEntity(input);
  }

  @override
  String encodeText(String input) => _htmlMapping.encodeText(input);

  @override
  String encodeAttributeValue(String input, XmlAttributeType type) =>
      _htmlMapping.encodeAttributeValue(input, type);
}

/// Default implementation of IUriResolver
///
/// Provides URI resolution functionality for RDF/XML processing.
/// Uses efficient caching for improved performance with large documents.
final class DefaultUriResolver implements IUriResolver {
  /// Creates a new DefaultUriResolver
  const DefaultUriResolver();

  /// Matches percent-encoded sequences that decode to non-ASCII UTF-8 bytes
  /// (high-bit set, i.e. 0x80–0xFF).
  static final _nonAsciiPercentEncoded = RegExp(r'(%[89A-Fa-f][0-9A-Fa-f])+');

  @override
  String resolveUri(String uri, String? baseUri) {
    try {
      final resolved = resolveIri(uri, baseUri);
      // Dart's Uri percent-encodes non-ASCII characters during resolution.
      // IRIs (RFC 3987) allow non-ASCII, so we decode sequences that were
      // introduced by resolution—but preserve those already present in the
      // original input or base URI.
      //
      // Limitation: if the same multi-byte sequence (e.g. %C3%BC for ü)
      // appears encoded in one input and as a literal in the other, the
      // literal occurrence will also be preserved as percent-encoded.
      // This is acceptable because such mixed-encoding across inputs is
      // extremely rare in practice.
      final preserveSequences = _collectEncodedNonAscii(uri);
      if (baseUri != null) {
        preserveSequences.addAll(_collectEncodedNonAscii(baseUri));
      }
      if (preserveSequences.isEmpty) {
        // Fast path: no intentional percent-encoding in original inputs,
        // decode all non-ASCII sequences introduced by Dart.
        return resolved.replaceAllMapped(_nonAsciiPercentEncoded, (m) {
          try {
            return Uri.decodeComponent(m.group(0)!);
          } catch (_) {
            return m.group(0)!;
          }
        });
      }
      return resolved.replaceAllMapped(_nonAsciiPercentEncoded, (m) {
        final seq = m.group(0)!;
        if (preserveSequences.contains(seq)) {
          return seq;
        }
        try {
          return Uri.decodeComponent(seq);
        } catch (_) {
          return seq;
        }
      });
    } on BaseIriRequiredException catch (e) {
      throw RdfXmlBaseUriRequiredException(relativeUri: e.relativeUri);
    }
  }

  /// Collects all percent-encoded non-ASCII sequences from [input].
  static Set<String> _collectEncodedNonAscii(String input) {
    final result = <String>{};
    for (final m in _nonAsciiPercentEncoded.allMatches(input)) {
      result.add(m.group(0)!);
    }
    return result;
  }
}

/// Functional implementation of IBlankNodeManager
///
/// Provides a functional approach to blank node management using immutable context.
final class FunctionalBlankNodeManager implements IBlankNodeManager {
  /// The current parsing context
  var _context = RdfXmlParsingContext.empty();

  /// Creates a new functional blank node manager
  FunctionalBlankNodeManager();

  /// Gets or creates a blank node for a given ID
  ///
  /// Ensures that the same blank node ID always maps to the same blank node term.
  /// Uses an immutable context to manage state.
  @override
  BlankNodeTerm getBlankNode(String nodeId) {
    final result = _context.getOrCreateBlankNode(nodeId);
    _context = result.$2; // Update the context with potential new blank node
    return result.$1; // Return the blank node
  }
}
