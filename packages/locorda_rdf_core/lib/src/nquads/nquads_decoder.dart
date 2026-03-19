/// N-Quads parser - Implementation of the RdfParser interface for N-Quads format
///
/// This file provides the parser implementation for the N-Quads format,
/// which is a line-based serialization of RDF.
library nquads_parser;

import 'package:logging/logging.dart';
import 'package:locorda_rdf_core/src/dataset/rdf_dataset.dart';
import 'package:locorda_rdf_core/src/rdf_dataset_decoder.dart';
import 'package:locorda_rdf_core/src/rdf_decoder.dart';

import '../dataset/quad.dart';
import '../exceptions/rdf_decoder_exception.dart';
import '../exceptions/rdf_exception.dart';
import '../graph/rdf_term.dart';
import '../pn_chars.dart' as pn;
import '../rdf_quads_decoder.dart';

/// Options for configuring the N-Quads decoder behavior.
///
/// N-Quads has a straightforward format with minimal configuration options
/// compared to more complex RDF serialization formats. This class provides a
/// placeholder for future extension points if needed.
///
/// The current implementation uses default parsing behavior as defined by
/// the N-Quads specification, without additional configuration options.
class NQuadsDecoderOptions extends RdfDatasetDecoderOptions {
  /// Creates a new instance of NquadsDecoderOptions with default settings.
  ///
  /// Since N-Quads is a simple format, there are currently no configurable options.
  const NQuadsDecoderOptions();

  /// Creates an instance of NquadsDecoderOptions from generic decoder options.
  ///
  /// This factory method ensures that when generic [RdfDatasetDecoderOptions] are provided
  /// to a method expecting N-Quads-specific options, they are properly converted.
  ///
  /// The [options] parameter contains the generic decoder options to convert.
  /// Returns an instance of NquadsDecoderOptions.
  static NQuadsDecoderOptions from(RdfGraphDecoderOptions options) =>
      switch (options) {
        NQuadsDecoderOptions _ => options,
        _ => NQuadsDecoderOptions(),
      };
}

/// Decoder for the N-Quads format that yields a sequence of Quads.
///
/// Unlike [NQuadsDecoder] which groups parsed quads into an [RdfDataset],
/// this decoder preserves the exact textual order of the statements from the source.
///
/// This decoder is the list-level API and owns chunk-to-chunk parser
/// continuity for stream processing.
final class NQuadsToQuadsDecoder extends RdfQuadsDecoder {
  final _logger = Logger('rdf.nquads.quad_parser');
  static const _formatName = 'application/n-quads';
  final IriTermFactory _iriTermFactory;

  // ignore: unused_field
  final NQuadsDecoderOptions _options;

  NQuadsToQuadsDecoder({
    NQuadsDecoderOptions options = const NQuadsDecoderOptions(),
    IriTermFactory iriTermFactory = IriTerm.validated,
  })  : _options = options,
        _iriTermFactory = iriTermFactory;

  @override
  RdfQuadsDecoder withOptions(RdfGraphDecoderOptions options) =>
      NQuadsToQuadsDecoder(
          options: NQuadsDecoderOptions.from(options),
          iriTermFactory: _iriTermFactory);

  @override
  Iterable<Quad> convert(String input, {String? documentUrl}) {
    return decode(input, documentUrl: documentUrl).quads;
  }

  ({Iterable<Quad> quads, Map<BlankNodeTerm, String> blankNodeLabels}) decode(
      String input,
      {String? documentUrl,
      Map<String, BlankNodeTerm>? bnodeMap}) {
    _logger.fine(
      'Parsing N-Quads document${documentUrl != null ? " with base URL: $documentUrl" : ""}',
    );

    final List<Quad> quads = [];
    final List<String> lines = input.split('\n');
    final Map<String, BlankNodeTerm> blankNodeMap = bnodeMap ?? {};
    int lineNumber = 0;

    for (final line in lines) {
      lineNumber++;
      final trimmed = line.trim();

      // Skip empty lines and comments
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      // Remove trailing comments while respecting literals and IRIs.
      final withoutComment = _stripComment(trimmed).trim();
      if (withoutComment.isEmpty) {
        continue;
      }

      try {
        final quad = _parseLine(withoutComment, lineNumber, blankNodeMap);
        quads.add(quad);
      } catch (e) {
        throw RdfDecoderException(
          'Error parsing N-Quads at line $lineNumber: ${e.toString()}',
          format: _formatName,
          source: SourceLocation(
            line: lineNumber - 1, // Convert to 0-based line number
            column: 0,
            context: withoutComment,
          ),
        );
      }
    }

    final blankNodeLabels = {
      for (final entry in blankNodeMap.entries) entry.value: entry.key
    };

    if (blankNodeLabels.length != blankNodeMap.length) {
      throw RdfException(
          'Inconsistent blank node labeling: some blank nodes have duplicate labels.');
    }

    return (quads: quads, blankNodeLabels: blankNodeLabels);
  }

  /// Parses a single line of N-Quads format into a Quad
  Quad _parseLine(
      String line, int lineNumber, Map<String, BlankNodeTerm> blankNodeMap) {
    // Check that the line ends with a period
    if (!line.trim().endsWith('.')) {
      throw RdfDecoderException(
        'Missing period at end of triple',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1, // Convert to 0-based line number
          column: line.trim().length,
          context: line.trim(),
        ),
      );
    }

    // Remove the trailing period and trim
    final content = line.trim().substring(0, line.trim().length - 1).trim();

    // Split into subject, predicate, object, [graph]
    final parts = _splitQuadParts(content, lineNumber);
    if (parts.length != 3 && parts.length != 4) {
      throw RdfDecoderException(
        'Invalid quad format: expected 3 or 4 parts, found ${parts.length}',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1, // Convert to 0-based line number
          column: 0,
          context: content,
        ),
      );
    }

    final subject = _parseSubject(parts[0].trim(), lineNumber, blankNodeMap);
    final predicate = _parsePredicate(parts[1].trim(), lineNumber);
    final object = _parseObject(parts[2].trim(), lineNumber, blankNodeMap);

    // Parse graph if present (N-Quads format)
    RdfGraphName? graph;
    if (parts.length == 4) {
      graph = _parseGraphName(parts[3].trim(), lineNumber, blankNodeMap);
    }

    return Quad(subject, predicate, object, graph);
  }

  /// Splits quad content into subject, predicate, object, and optional graph.
  ///
  /// Supports both regular and minimal-whitespace forms, e.g.:
  /// `<s> <p> <o>` and `<s><p><o>`.
  List<String> _splitQuadParts(String content, int lineNumber) {
    final parts = <String>[];
    var i = 0;

    i = _skipWhitespace(content, i);
    final subject =
        _readTerm(content, i, allowLiteral: false, lineNumber: lineNumber);
    parts.add(subject.term);
    i = _skipWhitespace(content, subject.nextIndex);

    final predicate =
        _readTerm(content, i, allowLiteral: false, lineNumber: lineNumber);
    parts.add(predicate.term);
    i = _skipWhitespace(content, predicate.nextIndex);

    final object =
        _readTerm(content, i, allowLiteral: true, lineNumber: lineNumber);
    parts.add(object.term);
    i = _skipWhitespace(content, object.nextIndex);

    if (i < content.length) {
      final graph =
          _readTerm(content, i, allowLiteral: false, lineNumber: lineNumber);
      parts.add(graph.term);
      i = _skipWhitespace(content, graph.nextIndex);
    }

    if (i != content.length) {
      throw RdfDecoderException(
        'Invalid trailing content in quad line',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1,
          column: i,
          context: content,
        ),
      );
    }

    return parts;
  }

  String _stripComment(String line) {
    var inQuotes = false;
    var inUri = false;
    var escapedInQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final c = line[i];

      if (inQuotes) {
        if (escapedInQuotes) {
          escapedInQuotes = false;
          continue;
        }
        if (c == '\\') {
          escapedInQuotes = true;
          continue;
        }
        if (c == '"') {
          inQuotes = false;
        }
        continue;
      }

      if (inUri) {
        if (c == '>') {
          inUri = false;
        }
        continue;
      }

      if (c == '"') {
        inQuotes = true;
        continue;
      }
      if (c == '<') {
        inUri = true;
        continue;
      }
      if (c == '#') {
        return line.substring(0, i);
      }
    }

    return line;
  }

  int _skipWhitespace(String value, int start) {
    var i = start;
    while (i < value.length && value[i].trim().isEmpty) {
      i++;
    }
    return i;
  }

  ({String term, int nextIndex}) _readTerm(
    String content,
    int start, {
    required bool allowLiteral,
    required int lineNumber,
  }) {
    if (start >= content.length) {
      throw RdfDecoderException(
        'Unexpected end of line while reading term',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1,
          column: start,
          context: content,
        ),
      );
    }

    final first = content[start];

    if (first == '<') {
      final end = content.indexOf('>', start + 1);
      if (end == -1) {
        throw RdfDecoderException(
          'Unterminated IRI term',
          format: _formatName,
          source: SourceLocation(
            line: lineNumber - 1,
            column: start,
            context: content,
          ),
        );
      }
      return (term: content.substring(start, end + 1), nextIndex: end + 1);
    }

    if (first == '_' &&
        start + 1 < content.length &&
        content[start + 1] == ':') {
      var i = start + 2;
      while (i < content.length) {
        final (ch, w) = pn.charAt(content, i);
        if (!pn.pnCharsOrDot.hasMatch(ch)) break;
        i += w;
      }
      // Strip trailing dots (not allowed at end of blank node label)
      while (i > start + 2 && content[i - 1] == '.') {
        i--;
      }
      return (term: content.substring(start, i), nextIndex: i);
    }

    if (allowLiteral && first == '"') {
      var i = start + 1;
      var escaped = false;
      while (i < content.length) {
        final c = content[i];
        if (escaped) {
          escaped = false;
        } else if (c == '\\') {
          escaped = true;
        } else if (c == '"') {
          i++;
          break;
        }
        i++;
      }

      if (i > content.length || content[i - 1] != '"') {
        throw RdfDecoderException(
          'Unterminated literal term',
          format: _formatName,
          source: SourceLocation(
            line: lineNumber - 1,
            column: start,
            context: content,
          ),
        );
      }

      if (i < content.length && content[i] == '@') {
        i++;
        while (i < content.length &&
            RegExp(r'[A-Za-z0-9-]').hasMatch(content[i])) {
          i++;
        }
      } else if (i + 1 < content.length &&
          content[i] == '^' &&
          content[i + 1] == '^') {
        i += 2;
        if (i >= content.length || content[i] != '<') {
          throw RdfDecoderException(
            'Typed literal requires datatype IRI',
            format: _formatName,
            source: SourceLocation(
              line: lineNumber - 1,
              column: i,
              context: content,
            ),
          );
        }
        final end = content.indexOf('>', i + 1);
        if (end == -1) {
          throw RdfDecoderException(
            'Unterminated datatype IRI in typed literal',
            format: _formatName,
            source: SourceLocation(
              line: lineNumber - 1,
              column: i,
              context: content,
            ),
          );
        }
        i = end + 1;
      }

      return (term: content.substring(start, i), nextIndex: i);
    }

    throw RdfDecoderException(
      'Invalid term start: $first',
      format: _formatName,
      source: SourceLocation(
        line: lineNumber - 1,
        column: start,
        context: content,
      ),
    );
  }

  /// Parses the subject part of a triple (IRI or blank node)
  RdfSubject _parseSubject(
      String subject, int lineNumber, Map<String, BlankNodeTerm> blankNodeMap) {
    if (subject.startsWith('<') && subject.endsWith('>')) {
      // IRI
      final iri = _parseIri(subject, lineNumber);
      return _iriTermFactory(iri);
    } else if (subject.startsWith('_:')) {
      // Blank node
      final label = subject.substring(2); // Remove '_:' prefix
      _validateBlankNodeLabel(label, lineNumber, subject);
      return blankNodeMap.putIfAbsent(label, () => BlankNodeTerm());
    } else {
      throw RdfDecoderException(
        'Invalid subject: $subject. Must be an IRI or blank node',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1, // Convert to 0-based line number
          column: 0,
          context: subject,
        ),
      );
    }
  }

  /// Parses the predicate part of a triple (always an IRI in N-Quads)
  RdfPredicate _parsePredicate(String predicate, int lineNumber) {
    if (predicate.startsWith('<') && predicate.endsWith('>')) {
      // IRI
      final iri = _parseIri(predicate, lineNumber);
      return _iriTermFactory(iri);
    } else {
      throw RdfDecoderException(
        'Invalid predicate: $predicate. Must be an IRI',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1, // Convert to 0-based line number
          column: 0,
          context: predicate,
        ),
      );
    }
  }

  /// Parses the object part of a triple (IRI, blank node, or literal)
  RdfObject _parseObject(
      String object, int lineNumber, Map<String, BlankNodeTerm> blankNodeMap) {
    if (object.startsWith('<') && object.endsWith('>')) {
      // IRI
      final iri = _parseIri(object, lineNumber);
      return _iriTermFactory(iri);
    } else if (object.startsWith('_:')) {
      // Blank node
      final label = object.substring(2); // Remove '_:' prefix
      _validateBlankNodeLabel(label, lineNumber, object);
      return blankNodeMap.putIfAbsent(label, () => BlankNodeTerm());
    } else if (object.startsWith('"')) {
      // Literal
      return _parseLiteral(object, lineNumber);
    } else {
      throw RdfDecoderException(
        'Invalid object: $object. Must be an IRI, blank node, or literal',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1, // Convert to 0-based line number
          column: 0,
          context: object,
        ),
      );
    }
  }

  /// Parses the graph part of a quad (IRI or blank node)
  RdfGraphName _parseGraphName(
      String graph, int lineNumber, Map<String, BlankNodeTerm> blankNodeMap) {
    if (graph.startsWith('<') && graph.endsWith('>')) {
      // IRI
      final iri = _parseIri(graph, lineNumber);
      return _iriTermFactory(iri);
    } else if (graph.startsWith('_:')) {
      // Blank node
      final label = graph.substring(2); // Remove '_:' prefix
      _validateBlankNodeLabel(label, lineNumber, graph);
      return blankNodeMap.putIfAbsent(label, () => BlankNodeTerm());
    } else {
      throw RdfDecoderException(
        'Invalid graph: $graph. Must be an IRI or blank node',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1, // Convert to 0-based line number
          column: 0,
          context: graph,
        ),
      );
    }
  }

  /// Parses an IRI from its N-Quads representation (enclosed in angle brackets)
  String _parseIri(String iriText, int lineNumber) {
    if (!iriText.startsWith('<') || !iriText.endsWith('>')) {
      throw RdfDecoderException(
        'Invalid IRI: $iriText. Must be enclosed in angle brackets',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1, // Convert to 0-based line number
          column: 0,
          context: iriText,
        ),
      );
    }

    final iri = iriText.substring(1, iriText.length - 1);
    return _unescapeIri(iri, lineNumber);
  }

  /// Parses a literal from its N-Quads representation
  LiteralTerm _parseLiteral(String literalText, int lineNumber) {
    // Find the end of the literal value
    int endQuoteIndex = _findEndQuoteIndex(literalText);
    if (endQuoteIndex == -1) {
      throw RdfDecoderException(
        'Invalid literal: $literalText. Missing closing quote',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1, // Convert to 0-based line number
          column: 0,
          context: literalText,
        ),
      );
    }

    // Extract the literal value
    final value = literalText.substring(1, endQuoteIndex);
    final valueUnescaped = _unescapeLiteral(value, lineNumber);

    if (endQuoteIndex == literalText.length - 1) {
      // Simple literal without language tag or datatype
      // Use xsd:string as the default datatype
      return LiteralTerm.string(valueUnescaped);
    }

    final suffix = literalText.substring(endQuoteIndex + 1).trim();

    if (suffix.startsWith('@')) {
      // Literal with language tag
      final lang = suffix.substring(1);
      _validateLanguageTag(lang, lineNumber, literalText);
      return LiteralTerm.withLanguage(valueUnescaped, lang);
    } else if (suffix.startsWith('^^')) {
      // Typed literal
      if (!suffix.substring(2).startsWith('<') || !suffix.endsWith('>')) {
        throw RdfDecoderException(
          'Invalid datatype IRI in literal: $literalText',
          format: _formatName,
          source: SourceLocation(
            line: lineNumber - 1, // Convert to 0-based line number
            column: endQuoteIndex + 1,
            context: suffix,
          ),
        );
      }

      final datatypeIri = suffix.substring(3, suffix.length - 1);
      final unescapedDatatypeIri = _unescapeIri(datatypeIri, lineNumber);

      // Create the datatype IRI term
      final datatypeIriTerm = _iriTermFactory(unescapedDatatypeIri);
      return LiteralTerm(valueUnescaped, datatype: datatypeIriTerm);
    } else {
      throw RdfDecoderException(
        'Invalid literal suffix: $suffix',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1, // Convert to 0-based line number
          column: endQuoteIndex + 1,
          context: suffix,
        ),
      );
    }
  }

  /// Finds the closing quote of a literal, accounting for escaped quotes
  int _findEndQuoteIndex(String literalText) {
    bool escaped = false;

    // Start from index 1 to skip the opening quote
    for (int i = 1; i < literalText.length; i++) {
      if (escaped) {
        escaped = false;
        continue;
      }

      if (literalText[i] == '\\') {
        escaped = true;
        continue;
      }

      if (literalText[i] == '"') {
        return i;
      }
    }

    return -1; // No closing quote found
  }

  String _unescapeLiteral(String input, int lineNumber) {
    final buffer = StringBuffer();
    bool escaped = false;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (escaped) {
        switch (char) {
          case 't':
            buffer.write('\t');
            break;
          case 'b':
            buffer.write('\b');
            break;
          case 'n':
            buffer.write('\n');
            break;
          case 'r':
            buffer.write('\r');
            break;
          case 'f':
            buffer.write('\f');
            break;
          case '"':
            buffer.write('"');
            break;
          case '\'':
            buffer.write('\'');
            break;
          case '\\':
            buffer.write('\\');
            break;
          case 'u':
            // Unicode escape (4 hex digits)
            if (i + 4 < input.length) {
              final hexCode = input.substring(i + 1, i + 5);
              if (!_isHex(hexCode)) {
                throw RdfDecoderException(
                  'Invalid Unicode escape in literal: \\u$hexCode',
                  format: _formatName,
                  source: SourceLocation(
                    line: lineNumber - 1,
                    column: i,
                    context: input,
                  ),
                );
              }
              final codePoint = int.parse(hexCode, radix: 16);
              buffer.write(String.fromCharCode(codePoint));
              i += 4; // Skip the 4 hex digits
            } else {
              throw RdfDecoderException(
                'Incomplete Unicode escape in literal',
                format: _formatName,
                source: SourceLocation(
                  line: lineNumber - 1,
                  column: i,
                  context: input,
                ),
              );
            }
            break;
          case 'U':
            // Unicode escape (8 hex digits)
            if (i + 8 < input.length) {
              final hexCode = input.substring(i + 1, i + 9);
              if (!_isHex(hexCode)) {
                throw RdfDecoderException(
                  'Invalid Unicode escape in literal: \\U$hexCode',
                  format: _formatName,
                  source: SourceLocation(
                    line: lineNumber - 1,
                    column: i,
                    context: input,
                  ),
                );
              }
              final codePoint = int.parse(hexCode, radix: 16);
              buffer.write(String.fromCharCode(codePoint));
              i += 8; // Skip the 8 hex digits
            } else {
              throw RdfDecoderException(
                'Incomplete Unicode escape in literal',
                format: _formatName,
                source: SourceLocation(
                  line: lineNumber - 1,
                  column: i,
                  context: input,
                ),
              );
            }
            break;
          default:
            throw RdfDecoderException(
              'Invalid escape sequence in literal: \\$char',
              format: _formatName,
              source: SourceLocation(
                line: lineNumber - 1,
                column: i,
                context: input,
              ),
            );
        }
        escaped = false;
      } else if (char == '\\') {
        escaped = true;
      } else {
        buffer.write(char);
      }
    }

    if (escaped) {
      throw RdfDecoderException(
        'Trailing backslash in literal escape sequence',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1,
          column: input.length - 1,
          context: input,
        ),
      );
    }

    return buffer.toString();
  }

  String _unescapeIri(String input, int lineNumber) {
    final buffer = StringBuffer();

    for (int i = 0; i < input.length; i++) {
      final c = input[i];
      if (c != '\\') {
        buffer.write(c);
        continue;
      }

      if (i + 1 >= input.length) {
        throw RdfDecoderException(
          'Trailing backslash in IRI',
          format: _formatName,
          source: SourceLocation(
            line: lineNumber - 1,
            column: i,
            context: input,
          ),
        );
      }

      final esc = input[i + 1];
      if (esc == 'u') {
        if (i + 5 >= input.length) {
          throw RdfDecoderException(
            'Incomplete Unicode escape in IRI',
            format: _formatName,
            source: SourceLocation(
              line: lineNumber - 1,
              column: i,
              context: input,
            ),
          );
        }
        final hex = input.substring(i + 2, i + 6);
        if (!_isHex(hex)) {
          throw RdfDecoderException(
            'Invalid Unicode escape in IRI: \\u$hex',
            format: _formatName,
            source: SourceLocation(
              line: lineNumber - 1,
              column: i,
              context: input,
            ),
          );
        }
        buffer.writeCharCode(int.parse(hex, radix: 16));
        i += 5;
        continue;
      }

      if (esc == 'U') {
        if (i + 9 >= input.length) {
          throw RdfDecoderException(
            'Incomplete Unicode escape in IRI',
            format: _formatName,
            source: SourceLocation(
              line: lineNumber - 1,
              column: i,
              context: input,
            ),
          );
        }
        final hex = input.substring(i + 2, i + 10);
        if (!_isHex(hex)) {
          throw RdfDecoderException(
            'Invalid Unicode escape in IRI: \\U$hex',
            format: _formatName,
            source: SourceLocation(
              line: lineNumber - 1,
              column: i,
              context: input,
            ),
          );
        }
        buffer.writeCharCode(int.parse(hex, radix: 16));
        i += 9;
        continue;
      }

      throw RdfDecoderException(
        'Invalid IRI escape sequence: \\$esc',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1,
          column: i,
          context: input,
        ),
      );
    }

    return buffer.toString();
  }

  bool _isHex(String s) {
    for (int i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (!((c >= 0x30 && c <= 0x39) || // 0-9
          (c >= 0x41 && c <= 0x46) || // A-F
          (c >= 0x61 && c <= 0x66))) {
        // a-f
        return false;
      }
    }
    return true;
  }

  void _validateLanguageTag(
      String lang, int lineNumber, String originalLiteral) {
    if (!RegExp(r'^[A-Za-z]+(-[A-Za-z0-9]+)*$').hasMatch(lang)) {
      throw RdfDecoderException(
        'Invalid language tag: $lang',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1,
          column: 0,
          context: originalLiteral,
        ),
      );
    }
  }

  void _validateBlankNodeLabel(
      String label, int lineNumber, String originalTerm) {
    // BLANK_NODE_LABEL ::= '_:' (PN_CHARS_U | [0-9]) ((PN_CHARS | '.')* PN_CHARS)?
    if (label.isEmpty) {
      throw RdfDecoderException(
        'Empty blank node label',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1,
          column: 0,
          context: originalTerm,
        ),
      );
    }

    // First char: PN_CHARS_U | [0-9]
    final (firstCh, firstW) = pn.charAt(label, 0);
    final isDigit = firstCh.length == 1 &&
        firstCh.codeUnitAt(0) >= 0x30 &&
        firstCh.codeUnitAt(0) <= 0x39;
    if (!pn.pnCharsU.hasMatch(firstCh) && !isDigit) {
      throw RdfDecoderException(
        'Invalid start character in blank node label: $firstCh',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1,
          column: 0,
          context: originalTerm,
        ),
      );
    }

    // Remaining chars: ((PN_CHARS | '.')* PN_CHARS)? — dots not at end
    var i = firstW;
    while (i < label.length) {
      final (ch, w) = pn.charAt(label, i);
      if (ch != '.' && !pn.pnChars.hasMatch(ch)) {
        throw RdfDecoderException(
          'Invalid character in blank node label: $ch',
          format: _formatName,
          source: SourceLocation(
            line: lineNumber - 1,
            column: i + 2, // +2 for '_:' prefix
            context: originalTerm,
          ),
        );
      }
      i += w;
    }

    // Last char must not be '.'
    if (label.endsWith('.')) {
      throw RdfDecoderException(
        'Blank node label must not end with a dot',
        format: _formatName,
        source: SourceLocation(
          line: lineNumber - 1,
          column: label.length + 1,
          context: originalTerm,
        ),
      );
    }
  }

  /// Decodes streamed N-Quads chunks while preserving blank-node identity
  /// across chunk boundaries at quad-list level.
  @override
  Stream<Iterable<Quad>> bind(Stream<String> stream) async* {
    final bnodeMap = <String, BlankNodeTerm>{};
    await for (final chunk in stream) {
      yield decode(chunk, bnodeMap: bnodeMap).quads;
    }
  }
}

/// Decoder for the N-Quads format that yields an [RdfDataset].
///
/// This decoder wraps [NQuadsToQuadsDecoder] and groups the sequentially
/// parsed quads into a mathematically unique [RdfDataset].
///
/// This wrapper intentionally focuses on dataset value-object materialization
/// and does not define additional stream continuity semantics beyond its
/// delegate.
final class NQuadsDecoder extends RdfDatasetDecoder {
  final NQuadsToQuadsDecoder _decoder;

  /// Creates a new N-Quads parser focusing on Datasets
  NQuadsDecoder({
    NQuadsDecoderOptions options = const NQuadsDecoderOptions(),
    IriTermFactory iriTermFactory = IriTerm.validated,
  }) : _decoder = NQuadsToQuadsDecoder(
            options: options, iriTermFactory: iriTermFactory);

  @override
  RdfDatasetDecoder withOptions(RdfGraphDecoderOptions options) =>
      NQuadsDecoder(
          options: NQuadsDecoderOptions.from(options),
          iriTermFactory: _decoder._iriTermFactory);

  @override
  RdfDataset convert(String input, {String? documentUrl}) {
    return decode(input, documentUrl: documentUrl).dataset;
  }

  ({RdfDataset dataset, Map<BlankNodeTerm, String> blankNodeLabels}) decode(
      String input,
      {String? documentUrl}) {
    final result = _decoder.decode(
      input,
      documentUrl: documentUrl,
    );
    return (
      dataset: RdfDataset.fromQuads(result.quads),
      blankNodeLabels: result.blankNodeLabels
    );
  }
}
