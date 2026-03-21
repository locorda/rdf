/// RDF/XML Serializer Implementation
///
/// Serializes RDF graphs to the RDF/XML syntax format according to the W3C specification.
/// This serializer transforms RDF data models (graphs of triples) into a standard
/// XML representation that can be processed by XML tools while preserving the
/// semantics of the RDF data.
///
/// Key features:
/// - Namespace management for compact and readable output
/// - Typed node serialization (using element types instead of rdf:type triples)
/// - Support for RDF collections (rdf:List)
/// - Proper handling of blank nodes
/// - Datatype and language tag serialization
/// - Configurable formatting options for human readability or compact storage
///
/// The implementation follows clean architecture principles with injectable
/// dependencies for XML building and namespace management, making it easy to
/// adapt to different requirements and test thoroughly.
///
/// Example usage:
/// ```dart
/// final serializer = RdfXmlSerializer();
/// final rdfXml = serializer.write(graph, customPrefixes: {'ex': 'http://example.org/'});
/// ```
///
/// For configuration options, see [RdfXmlEncoderOptions].
library rdfxml_serializer;

import 'package:logging/logging.dart';
import 'package:locorda_rdf_core/core.dart';
import 'package:locorda_rdf_xml/src/rdfxml_constants.dart';
import 'package:xml/xml.dart';

import 'configuration.dart';
import 'exceptions.dart';
import 'implementations/serialization_impl.dart';
import 'interfaces/serialization.dart';

/// Checks if a string is a valid XML local name
///
/// Simple validation for XML names.

bool _isValidXmlName(String name) {
  if (name.isEmpty) {
    return false;
  }

  // First character must be a letter or underscore
  final firstChar = name.codeUnitAt(0);
  if (!((firstChar >= 65 && firstChar <= 90) || // A-Z
      (firstChar >= 97 && firstChar <= 122) || // a-z
      firstChar == 95)) {
    // _
    return false;
  }

  // Subsequent characters can also include digits and some symbols
  for (int i = 1; i < name.length; i++) {
    final char = name.codeUnitAt(i);
    if (!((char >= 65 && char <= 90) || // A-Z
        (char >= 97 && char <= 122) || // a-z
        (char >= 48 && char <= 57) || // 0-9
        char == 95 || // _
        char == 45 || // -
        char == 46)) {
      // .
      return false;
    }
  }

  return true;
}

/// Serializer for RDF/XML format
///
/// Implements the RDF/XML serialization algorithm according to the W3C specification.
/// This serializer converts RDF triples into XML-encoded RDF data.
///
/// Features:
/// - Prefix handling for compact output
/// - Type consolidation (using element types instead of rdf:type triples)
/// - Support for RDF collections
/// - Blank node serialization
/// - Datatype and language tag handling
final class RdfXmlSerializer implements IRdfXmlSerializer {
  static final _logger = Logger('rdf.serializer.rdfxml');

  /// Namespace manager for handling namespace declarations
  final IriCompaction _iriCompaction;

  /// XML builder for creating XML documents
  final IRdfXmlBuilder _xmlBuilder;

  /// Serializer options for configuring behavior
  final RdfXmlEncoderOptions _options;

  /// Creates a new RDF/XML serializer
  ///
  /// Parameters:

  /// - [xmlBuilder] Optional XML builder for creating XML documents
  /// - [options] Optional serializer options
  RdfXmlSerializer({
    RdfNamespaceMappings? namespaceMappings,
    IRdfXmlBuilder? xmlBuilder,
    RdfXmlEncoderOptions? options,
  }) : _iriCompaction = IriCompaction(
         namespaceMappings ?? const RdfNamespaceMappings(),
         IriCompactionSettings(
           iriRelativization:
               options?.iriRelativization ?? IriRelativizationOptions.full(),
           // Really important in XML: we usually do not want full iris, but for example predicates must be prefix:localName
           generateMissingPrefixes: true,
           allowedCompactionTypes: {
             ...allowedCompactionTypesAll,
             IriRole.datatype: {
               IriCompactionType.full,
               IriCompactionType.prefixed,
             },
             IriRole.predicate: {IriCompactionType.prefixed},
             IriRole.type: {IriCompactionType.prefixed},
             IriRole.subject: {
               IriCompactionType.full,
               IriCompactionType.relative,
             },
             IriRole.object: {
               IriCompactionType.full,
               IriCompactionType.relative,
             },
           },
           specialPredicates: {},
           specialDatatypes: {RdfTerms.string},
         ),
         _isValidXmlName,
       ),
       _xmlBuilder = xmlBuilder ?? DefaultRdfXmlBuilder(),
       _options = options ?? const RdfXmlEncoderOptions();

  /// Writes an RDF graph to RDF/XML format
  ///
  /// Parameters:
  /// - [graph] The RDF graph to serialize
  /// - [baseUri] Optional base URI for the document
  /// - [customPrefixes] Custom namespace prefix mappings
  @override
  String write(
    RdfGraph graph, {
    String? baseUri,
    Map<String, String> customPrefixes = const {},
  }) {
    _logger.fine('Serializing graph to RDF/XML');

    try {
      // Validate graph if empty
      if (graph.isEmpty) {
        _logger.warning('Serializing empty graph to RDF/XML');
      }

      // Build namespace declarations
      final iriCompactionResult = _iriCompaction.compactAllIris(
        graph,
        customPrefixes,
        baseUri: baseUri,
      );

      // Build XML document
      final document = _xmlBuilder.buildDocument(
        graph,
        baseUri,
        iriCompactionResult,
        _options,
      );

      // Generate XML string — use custom pretty-printer that preserves
      // whitespace in text-only elements (literal values).
      if (_options.prettyPrint) {
        return _toXmlStringPreservingText(
          document,
          indent: ' ' * _options.indentSpaces,
        );
      }
      return document.toXmlString(pretty: false);
    } catch (e, stackTrace) {
      _logger.severe('Error serializing to RDF/XML: $e', e, stackTrace);
      print(stackTrace);
      if (e is RdfXmlEncoderException) {
        rethrow;
      }
      throw RdfXmlEncoderException(
        'Error serializing to RDF/XML: $e',
        cause: e,
      );
    }
  }
}

/// Pretty-prints an [XmlDocument] while preserving whitespace in text-only
/// elements (i.e. literal values in RDF/XML).
///
/// The standard `toXmlString(pretty: true)` normalises whitespace inside text
/// nodes, which destroys multi-line literal content. This function adds
/// structural indentation between element tags but writes text content of
/// leaf elements verbatim.
String _toXmlStringPreservingText(XmlDocument doc, {String indent = '  '}) {
  final buf = StringBuffer();
  for (final child in doc.children) {
    _writeNode(buf, child, 0, indent);
  }
  return buf.toString();
}

void _writeNode(StringBuffer buf, XmlNode node, int level, String indent) {
  switch (node) {
    case XmlProcessing():
      buf.write('<?${node.target}');
      if (node.value.isNotEmpty) buf.write(' ${node.value}');
      buf.writeln('?>');
    case XmlComment():
      buf
        ..write(indent * level)
        ..writeln('<!--${node.value}-->');
    case XmlElement():
      _writeElement(buf, node, level, indent);
    case XmlText():
      // Top-level text (inter-element whitespace) — skip
      break;
    default:
      // Declaration, doctype, etc. — write as-is via the xml library
      buf.write(node.toXmlString());
  }
}

void _writeElement(
  StringBuffer buf,
  XmlElement el,
  int level,
  String indent,
) {
  final ind = indent * level;
  final hasChildElements = el.childElements.isNotEmpty;

  // Opening tag
  buf.write('$ind<${el.name.qualified}');
  for (final attr in el.attributes) {
    buf.write(' ${attr.name.qualified}=');
    buf.write('"${attr.value.replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')}"');
  }

  if (el.children.isEmpty) {
    buf.writeln('/>');
    return;
  }

  buf.write('>');

  if (!hasChildElements) {
    // Leaf element — write text/CDATA inline to preserve whitespace
    for (final child in el.children) {
      if (child is XmlText) {
        buf.write(_escapeXmlText(child.value));
      } else if (child is XmlCDATA) {
        buf.write('<![CDATA[${child.value}]]>');
      }
    }
    buf.writeln('</${el.name.qualified}>');
    return;
  }

  // Has child elements — recurse with increased indentation
  buf.writeln();
  for (final child in el.children) {
    if (child is XmlText) continue; // skip inter-element whitespace
    _writeNode(buf, child, level + 1, indent);
  }
  buf.writeln('$ind</${el.name.qualified}>');
}

String _escapeXmlText(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
