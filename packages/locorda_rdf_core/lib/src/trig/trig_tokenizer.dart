/// TriG Tokenizer Implementation
///
/// Implements the [TriGTokenizer] class for lexical analysis of TriG syntax.
///
/// Example usage:
/// ```dart
/// import 'package:locorda_rdf_core/src/trig/trig_tokenizer.dart';
/// final tokenizer = TriGTokenizer(input);
/// final token = tokenizer.nextToken();
/// ```
/// The tokenizer is responsible for:
/// 1. Identifying the basic lexical elements of TriG (IRIs, literals, graph blocks, etc.)
/// 2. Handling whitespace, comments, and line breaks
/// 3. Providing position information for error reporting
/// 4. Managing escape sequences in strings and IRIs
///
/// See: https://www.w3.org/TR/trig/ for the TriG specification.
library trig_tokenizer;

import 'package:logging/logging.dart';

import '../pn_chars.dart' as pn;

final _log = Logger("rdf.trig");

/// Flags for non-standard TriG parsing behavior.
///
/// These flags allow for more granular control over how relaxed the parser should be
/// when encountering various non-standard TriG syntax patterns. Each flag represents
/// a specific deviation from the standard TriG specification.
///
/// Use these flags when parsing real-world TriG files that don't strictly follow
/// the W3C TriG specification but are still semantically meaningful.
enum TriGParsingFlag {
  /// Allows prefixed names to have local names that start with digits.
  /// E.g., allows `schema:3DModel` which is not valid in standard TriG/Turtle.
  allowDigitInLocalName,

  /// Allows prefix declarations without a trailing dot.
  /// E.g., allows `@prefix ex: <http://example.com/>`
  allowMissingDotAfterPrefix,

  /// Auto-adds common prefixes (rdf, rdfs, xsd, etc.) when not explicitly defined.
  /// This can help parse documents that use standard prefixes without declaring them.
  autoAddCommonPrefixes,

  /// Allows prefix declarations without the @ symbol (case-insensitive).
  /// E.g., allows `prefix ex: <http://example.com/>`, `PREFIX ex: <http://example.com/>`,
  /// `base <http://example.org/>`, or `BASE <http://example.org/>`
  allowPrefixWithoutAtSign,

  /// Handles missing dots at the end of triple statements more gracefully.
  allowMissingFinalDot,

  /// Allows simple identifiers without colons to be treated as prefixed names.
  /// E.g., allows `abc` to be treated as an IRI that is resolved against the base URI.
  ///
  /// Note: This requires that a base URI is set, either through an @base directive
  /// in the document or provided as the documentUrl parameter when decoding.
  ///
  /// Example:
  /// ```
  /// @base <http://example.org/> .
  /// <http://example.org/subject> a Type .
  /// ```
  /// Here "Type" will be resolved to <http://example.org/Type>
  allowIdentifiersWithoutColon,
}

/// Token types in TriG syntax.
///
/// TriG syntax consists of several types of tokens representing the lexical
/// elements of the language. Each value in this enum represents a specific kind
/// of token that can appear in valid TriG documents.
///
/// Basic structure tokens:
/// - [prefix]: The '@prefix' keyword for namespace prefix declarations
/// - [base]: The '@base' keyword for base IRI declarations
/// - [graph]: The 'GRAPH' keyword for named graph declarations
/// - [dot]: The '.' character that terminates statements
/// - [semicolon]: The ';' character for predicates sharing the same subject
/// - [comma]: The ',' character for objects sharing the same subject and predicate
/// - [openBrace]/[closeBrace]: The `{` and `}` for named graph blocks
///
/// Term tokens:
/// - [iri]: IRIs enclosed in angle brackets (e.g., <http://example.org/>)
/// - [prefixedName]: Prefixed names (e.g., foaf:name)
/// - [blankNode]: Blank nodes with explicit labels (e.g., _:b1)
/// - [literal]: String literals, possibly with language tags or datatypes
/// - [a]: The 'a' keyword, shorthand for the rdf:type predicate
///
/// Collection tokens:
/// - [openBracket]/[closeBracket]: The `[` and `]` for blank node property lists
/// - [openParen]/[closeParen]: The `(` and `)` for RDF collections (ordered lists)
///
/// Other:
/// - [booleanLiteral]: Boolean literals (e.g., true, false)
/// - [integerLiteral]: Integer literals (e.g., 42, -123)
/// - [decimalLiteral]: Decimal literals (e.g., 3.14, -0.5)
/// - [doubleLiteral]: Double literals with exponent notation (e.g., 1e0, 1.5E-3)
/// - [eof]: End of file marker, indicating the input has been fully consumed
enum TokenType {
  prefix,
  base,
  graph,
  iri,
  blankNode,
  literal,
  dot,
  semicolon,
  comma,
  openBracket,
  closeBracket,
  openBrace,
  closeBrace,
  openParen,
  closeParen,
  a,
  prefixedName,
  booleanLiteral,
  integerLiteral,
  decimalLiteral,
  doubleLiteral,
  eof,
}

/// A token in Turtle syntax.
///
/// Each token represents a distinct lexical element in the Turtle syntax and
/// includes both the token's content and its position in the source document,
/// which is essential for meaningful error reporting.
///
/// Position information is 1-based (the first line and column are numbered 1,
/// not 0) to match standard text editor conventions.
///
/// Examples:
/// ```
/// Token(TokenType.iri, "<http://example.org/foo>", 1, 1)
/// Token(TokenType.prefixedName, "foaf:name", 2, 5)
/// Token(TokenType.literal, "\"Hello\"", 3, 10)
/// ```
class Token {
  /// The type of this token.
  final TokenType type;

  /// The text content of this token.
  final String value;

  /// The line number where this token starts (1-based).
  final int line;

  /// The column number where this token starts (1-based).
  final int column;

  /// Creates a new token with the specified type, value, and position
  ///
  /// Position information should be 1-based (first character is at line 1, column 1).
  Token(this.type, this.value, this.line, this.column);

  @override
  String toString() => 'Token($type, "$value", $line:$column)';
}

/// Tokenizer for Turtle syntax.
///
/// This class breaks down a Turtle document into a sequence of tokens according to
/// the Turtle grammar rules. It implements a lexical analyzer that processes the input
/// character by character and builds meaningful tokens.
///
/// The tokenizer handles:
///
/// - IRIs: `<http://example.org/resource>`
/// - Prefixed names: `ex:resource`
/// - Literals: `"string"`, `"string"@en`, `"3.14"^^xsd:decimal`
/// - Blank nodes: `_:blank1`
/// - Keywords: `a` (shorthand for rdf:type), `@prefix`, `@base`
/// - Punctuation: `.`, `;`, `,`, `[`, `]`, `(`, `)`
/// - Comments: `# This is a comment`
/// - Whitespace and line breaks
///
/// The tokenizer skips whitespace and comments between tokens and provides
/// detailed position information for error reporting.
///
/// Example:
/// ```dart
/// final tokenizer = TurtleTokenizer('''
///   @prefix ex: <http://example.org/> .
///   ex:subject a ex:Type ;
///     ex:predicate "object" .
/// ''');
///
/// Token token;
/// while ((token = tokenizer.nextToken()).type != TokenType.eof) {
///   print(token);
/// }
/// ```
class TriGTokenizer {
  static final _isDigitRegExp = RegExp(r'[0-9]');
  static const _pnLocalEscChars = {
    '_',
    '~',
    '.',
    '-',
    '!',
    '\$',
    '&',
    "'",
    '(',
    ')',
    '*',
    '+',
    ',',
    ';',
    '=',
    '/',
    '?',
    '#',
    '@',
    '%',
  };
  final String _input;
  int _position = 0;
  int _line = 1;
  int _column = 1;

  /// Returns the full character at [pos] (handling surrogate pairs) and
  /// the number of UTF-16 code units it occupies (1 or 2).
  (String, int) _charAt(int pos) => pn.charAt(_input, pos);

  final Set<TriGParsingFlag> _parsingFlags;

  /// Creates a new tokenizer for the given input string.
  ///
  /// The input should be a valid Turtle document or fragment.
  /// All tokens returned by [nextToken] will be derived from this input.
  ///
  /// [parsingFlags] enables a more flexible tokenization for real-world
  /// Turtle files that may not strictly adhere to the specification.
  TriGTokenizer(this._input, {Set<TriGParsingFlag> parsingFlags = const {}})
      : _parsingFlags = parsingFlags;

  /// Checks if a specific parsing flag is enabled.
  bool _hasFlag(TriGParsingFlag flag) => _parsingFlags.contains(flag);

  /// Returns the next token without consuming it.
  ///
  /// Saves and restores the tokenizer state so that the next call to
  /// [nextToken] will return the same token.
  Token peekToken() {
    final savedPosition = _position;
    final savedLine = _line;
    final savedColumn = _column;
    final savedLastCharWidth = _lastCharWidth;
    final token = nextToken();
    _position = savedPosition;
    _line = savedLine;
    _column = savedColumn;
    _lastCharWidth = savedLastCharWidth;
    return token;
  }

  /// Gets the next token from the input.
  ///
  /// This method is the main entry point for token extraction. It:
  /// 1. Skips any whitespace and comments
  /// 2. Identifies the type of the next token based on the current character
  /// 3. Delegates to specialized parsing methods for complex tokens
  /// 4. Advances the input position past the token
  /// 5. Returns the complete Token with its type, value, and position
  ///
  /// When the end of the input is reached, it returns a token with type
  /// [TokenType.eof]. This makes it convenient to use in a loop that
  /// continues until EOF is encountered.
  ///
  /// Throws [FormatException] if unexpected characters are encountered
  /// or if tokens are malformed (e.g., unclosed string literals).
  ///
  /// Example:
  /// ```dart
  /// Token token;
  /// while ((token = tokenizer.nextToken()).type != TokenType.eof) {
  ///   // Process the token
  /// }
  /// ```
  Token nextToken() {
    _skipWhitespace();

    if (_position >= _input.length) {
      return Token(TokenType.eof, '', _line, _column);
    }

    final char = _input[_position];

    // Handle single character tokens
    switch (char) {
      case '.':
        // Check if this starts a decimal/double: '.' followed by digit
        if (_position + 1 < _input.length &&
            _isDigitRegExp.hasMatch(_input[_position + 1])) {
          return _parseNumericLiteral();
        }
        _position++;
        _column++;
        return Token(TokenType.dot, '.', _line, _column - 1);
      case ';':
        _position++;
        _column++;
        return Token(TokenType.semicolon, ';', _line, _column - 1);
      case ',':
        _position++;
        _column++;
        return Token(TokenType.comma, ',', _line, _column - 1);
      case '[':
        _position++;
        _column++;
        return Token(TokenType.openBracket, '[', _line, _column - 1);
      case ']':
        _position++;
        _column++;
        return Token(TokenType.closeBracket, ']', _line, _column - 1);
      case '{':
        _position++;
        _column++;
        return Token(TokenType.openBrace, '{', _line, _column - 1);
      case '}':
        _position++;
        _column++;
        return Token(TokenType.closeBrace, '}', _line, _column - 1);
      case '(':
        _position++;
        _column++;
        return Token(TokenType.openParen, '(', _line, _column - 1);
      case ')':
        _position++;
        _column++;
        return Token(TokenType.closeParen, ')', _line, _column - 1);
    }

    // Handle @prefix
    if (_startsWith('@prefix')) {
      _position += 7;
      _column += 7;
      return Token(TokenType.prefix, '@prefix', _line, _column - 7);
    }

    // Handle SPARQL-style 'PREFIX' (case-insensitive, without @).
    // This is part of the W3C Turtle/TriG standard grammar (sparqlPrefix production).
    // No whitespace is required between keyword and PNAME_NS per W3C grammar.
    if (_startsWithCaseInsensitive('prefix') && _isKeywordBoundary(6)) {
      _position += 6;
      _column += 6;
      return Token(TokenType.prefix, 'PREFIX', _line, _column - 6);
    }

    // Handle @base
    if (_startsWith('@base')) {
      _position += 5;
      _column += 5;
      return Token(TokenType.base, '@base', _line, _column - 5);
    }

    // Handle SPARQL-style 'BASE' (case-insensitive, without @).
    // This is part of the W3C Turtle/TriG standard grammar (sparqlBase production).
    // No whitespace is required between keyword and IRIREF per W3C grammar.
    if (_startsWithCaseInsensitive('base') && _isKeywordBoundary(4)) {
      _position += 4;
      _column += 4;
      return Token(TokenType.base, 'BASE', _line, _column - 4);
    }

    // Handle GRAPH keyword (case-insensitive) for TriG
    if (_startsWithCaseInsensitive('graph') && _isKeywordBoundary(5)) {
      final length = 5; // 'GRAPH' is 5 characters
      _position += length;
      _column += length;
      return Token(TokenType.graph, 'GRAPH', _line, _column - length);
    }

    // Handle 'a' (shorthand for rdf:type)
    if (_startsWith('a ') ||
        _startsWith('a\n') ||
        _startsWith('a\t') ||
        _startsWith('a;') ||
        _startsWith('a.') ||
        (_position + 1 == _input.length && _input[_position] == 'a')) {
      _position++;
      _column++;
      return Token(TokenType.a, 'a', _line, _column - 1);
    }

    // Handle boolean literals
    if (_startsWith('true ') ||
        _startsWith('true\n') ||
        _startsWith('true\t') ||
        _startsWith('true;') ||
        _startsWith('true.') ||
        _startsWith('true,') ||
        _startsWith('true)') ||
        _startsWith('true]') ||
        (_position + 4 == _input.length &&
            _input.substring(_position, _position + 4) == 'true')) {
      _position += 4; // Skip "true"
      _column += 4;
      return Token(TokenType.booleanLiteral, 'true', _line, _column - 4);
    }

    if (_startsWith('false ') ||
        _startsWith('false\n') ||
        _startsWith('false\t') ||
        _startsWith('false;') ||
        _startsWith('false.') ||
        _startsWith('false,') ||
        _startsWith('false)') ||
        _startsWith('false]') ||
        (_position + 5 == _input.length &&
            _input.substring(_position, _position + 5) == 'false')) {
      _position += 5; // Skip "false"
      _column += 5;
      return Token(TokenType.booleanLiteral, 'false', _line, _column - 5);
    }

    // Handle signed numeric literals (+1, -1, +1.0, -1.0, +1e0, -1e0)
    if ((char == '-' || char == '+') &&
        _position + 1 < _input.length &&
        (_isDigitRegExp.hasMatch(_input[_position + 1]) ||
            (_input[_position + 1] == '.' &&
                _position + 2 < _input.length &&
                _isDigitRegExp.hasMatch(_input[_position + 2])))) {
      return _parseNumericLiteral();
    }

    // Handle unsigned numeric literals
    if (_isDigitRegExp.hasMatch(char)) {
      return _parseNumericLiteral();
    }

    // Handle IRIs
    if (char == '<') {
      return _parseIri();
    }

    // Handle blank nodes
    if (char == '_' &&
        _position + 1 < _input.length &&
        _input[_position + 1] == ':') {
      return _parseBlankNode();
    }

    // Handle literals (both double and single quotes)
    if (char == '"' || char == "'") {
      return _parseLiteral();
    }

    // Handle prefixed names (including supplementary plane characters)
    if (_isNameStartCharAt(_position)) {
      return _parsePrefixedName();
    }

    // In relaxed mode with allowDigitInLocalName, also handle digits at the start as potential prefixed names
    // This is particularly useful for files that mistakenly start prefixed names with digits
    if (_hasFlag(TriGParsingFlag.allowDigitInLocalName) &&
        _isDigitRegExp.hasMatch(char)) {
      _log.warning(
        'With allowDigitInLocalName: Found digit as first character at $_line:$_column',
      );
      return _parsePrefixedName();
    }

    _log.severe('Unexpected character: $char at $_line:$_column');
    throw FormatException('Unexpected character: $char at $_line:$_column');
  }

  /// Parses a numeric literal token (integer, decimal, or double).
  ///
  /// Implements the W3C grammar:
  /// - `INTEGER ::= [+-]? [0-9]+`
  /// - `DECIMAL ::= [+-]? [0-9]* '.' [0-9]+`
  /// - `DOUBLE  ::= [+-]? ([0-9]+ '.' [0-9]* EXPONENT | '.' [0-9]+ EXPONENT | [0-9]+ EXPONENT)`
  /// - `EXPONENT ::= [eE] [+-]? [0-9]+`
  Token _parseNumericLiteral() {
    final startLine = _line;
    final startColumn = _column;
    final buffer = StringBuffer();

    // Optional sign
    if (_position < _input.length &&
        (_input[_position] == '+' || _input[_position] == '-')) {
      buffer.write(_input[_position]);
      _position++;
      _column++;
    }

    // Digits before decimal point
    bool hasDigitsBeforeDot = false;
    while (_position < _input.length &&
        _isDigitRegExp.hasMatch(_input[_position])) {
      buffer.write(_input[_position]);
      _position++;
      _column++;
      hasDigitsBeforeDot = true;
    }

    // Decimal point
    bool hasDot = false;
    if (_position < _input.length && _input[_position] == '.') {
      // Only consume the dot if followed by a digit OR if this could be a double
      // (digits before dot + exponent coming later)
      // Peek: if next char after '.' is a digit, it's definitely decimal/double
      // If next char is 'e'/'E', it's a double like "1.e5" -> actually "1." needs digit after
      // Per spec: DECIMAL needs [0-9]+ after dot, DOUBLE allows [0-9]* after dot but needs EXPONENT
      final nextPos = _position + 1;
      final hasDigitAfterDot =
          nextPos < _input.length && _isDigitRegExp.hasMatch(_input[nextPos]);
      final hasExponentAfterDot = nextPos < _input.length &&
          (_input[nextPos] == 'e' || _input[nextPos] == 'E');

      if (hasDigitAfterDot || (hasDigitsBeforeDot && hasExponentAfterDot)) {
        hasDot = true;
        buffer.write('.');
        _position++;
        _column++;

        // Digits after decimal point
        while (_position < _input.length &&
            _isDigitRegExp.hasMatch(_input[_position])) {
          buffer.write(_input[_position]);
          _position++;
          _column++;
        }
      }
    }

    // Exponent
    bool hasExponent = false;
    if (_position < _input.length &&
        (_input[_position] == 'e' || _input[_position] == 'E')) {
      hasExponent = true;
      buffer.write(_input[_position]);
      _position++;
      _column++;

      // Optional sign in exponent
      if (_position < _input.length &&
          (_input[_position] == '+' || _input[_position] == '-')) {
        buffer.write(_input[_position]);
        _position++;
        _column++;
      }

      // Exponent digits (required)
      bool hasExponentDigits = false;
      while (_position < _input.length &&
          _isDigitRegExp.hasMatch(_input[_position])) {
        buffer.write(_input[_position]);
        _position++;
        _column++;
        hasExponentDigits = true;
      }

      if (!hasExponentDigits) {
        throw FormatException(
          'Invalid numeric literal: exponent requires at least one digit at $startLine:$startColumn',
        );
      }
    }

    final TokenType type;
    if (hasExponent) {
      type = TokenType.doubleLiteral;
    } else if (hasDot) {
      type = TokenType.decimalLiteral;
    } else {
      type = TokenType.integerLiteral;
    }

    return Token(type, buffer.toString(), startLine, startColumn);
  }

  /// Skips whitespace and comments in the input.
  ///
  /// This method advances the current position past:
  /// - Whitespace characters (spaces, tabs, carriage returns)
  /// - Line breaks (adjusting line and column counters)
  /// - Comments (from # to the end of the line)
  ///
  /// After calling this method, the current position will either:
  /// - Be at the start of a meaningful token
  /// - Be at the end of the input (position >= length)
  void _skipWhitespace() {
    while (_position < _input.length) {
      final char = _input[_position];
      if (char == '\n') {
        _line++;
        _column = 1;
        _position++;
      } else if (char == ' ' || char == '\t' || char == '\r') {
        _column++;
        _position++;
      } else if (char == '#') {
        _skipComment();
      } else {
        break;
      }
    }
  }

  /// Skips a comment in the input.
  ///
  /// Comments in Turtle start with # and continue until the end of the line.
  /// This method advances the position to the end of the current line.
  /// Line break handling is left to _skipWhitespace.
  void _skipComment() {
    while (_position < _input.length && _input[_position] != '\n') {
      _position++;
    }
  }

  /// Parses an IRI token.
  ///
  /// IRIs in Turtle are enclosed in angle brackets (<...>).
  /// This method handles:
  /// - The opening and closing angle brackets
  /// - The content between the brackets
  /// - Escape sequences in the IRI (e.g., \u00A9 for ©)
  ///
  /// Example in Turtle:
  /// ```turtle
  /// <http://example.org/resource>
  /// <http://example.org/with\#fragment>
  /// ```
  ///
  /// Returns a token of type [TokenType.iri] containing the complete IRI
  /// including the angle brackets.
  ///
  /// Throws [FormatException] if the IRI is not properly closed.
  Token _parseIri() {
    final startLine = _line;
    final startColumn = _column;

    // Save start position to capture entire IRI including brackets
    final startPos = _position;

    _position++; // Skip opening <
    _column++;

    while (_position < _input.length && _input[_position] != '>') {
      final c = _input[_position];
      // IRIREF disallows certain characters per spec [^<>"{}|^`\x00-\x20]
      if (c.codeUnitAt(0) <= 0x20 || '<>"{}|^`'.contains(c)) {
        throw FormatException(
          'Invalid character in IRI: ${_describeChar(c)} at $startLine:$startColumn',
        );
      }
      if (c == '\\') {
        // Only \uXXXX and \UXXXXXXXX are valid in IRIREF
        if (_position + 1 >= _input.length) {
          throw FormatException(
            'Incomplete escape in IRI at $startLine:$startColumn',
          );
        }
        final esc = _input[_position + 1];
        if (esc == 'u') {
          _validateHexEscape(_position + 2, 4, startLine, startColumn);
          _position += 6;
          _column += 6;
        } else if (esc == 'U') {
          _validateHexEscape(_position + 2, 8, startLine, startColumn);
          _position += 10;
          _column += 10;
        } else {
          throw FormatException(
            'Invalid escape \\$esc in IRI at $startLine:$startColumn',
          );
        }
      } else {
        _position++;
        _column++;
      }
    }

    if (_position >= _input.length) {
      throw FormatException('Unclosed IRI at $startLine:$startColumn');
    }

    _position++; // Skip closing >
    _column++;

    // Extract the entire IRI with angle brackets
    final iri = _input.substring(startPos, _position);

    return Token(TokenType.iri, iri, startLine, startColumn);
  }

  /// Parses a blank node token.
  ///
  /// Blank nodes in Turtle start with _: followed by a name.
  /// They represent anonymous resources that don't need global identifiers.
  ///
  /// Example in Turtle:
  /// ```turtle
  /// _:b1
  /// _:blank123
  /// ```
  ///
  /// Returns a token of type [TokenType.blankNode] containing the complete
  /// blank node identifier.
  Token _parseBlankNode() {
    final startLine = _line;
    final startColumn = _column;
    final buffer = StringBuffer();

    // Skip the _: prefix
    _position += 2;
    _column += 2;
    buffer.write('_:');

    // BLANK_NODE_LABEL ::= '_:' (PN_CHARS_U | [0-9]) ((PN_CHARS | '.')* PN_CHARS)?
    // Dots allowed in the middle but not at the end.
    while (_position < _input.length) {
      if (_isNameCharAt(_position)) {
        final w = _lastCharWidth;
        buffer.write(_input.substring(_position, _position + w));
        _position += w;
        _column++;
      } else if (_input[_position] == '.') {
        buffer.write('.');
        _position++;
        _column++;
      } else {
        break;
      }
    }
    // Strip trailing dots (not allowed at end of blank node label)
    final label = buffer.toString();
    final trimmed = label.replaceAll(RegExp(r'\.+$'), '');
    final dotsRemoved = label.length - trimmed.length;
    if (dotsRemoved > 0) {
      _position -= dotsRemoved;
      _column -= dotsRemoved;
    }

    return Token(
      TokenType.blankNode,
      trimmed,
      startLine,
      startColumn,
    );
  }

  /// Parses a literal token.
  ///
  /// Literals in Turtle represent string values and can have several forms:
  /// - Simple strings: "Hello"
  /// - Multi-line strings: """Hello
  ///   World"""
  /// - Language-tagged strings: "Hello"@en
  /// - Typed literals with datatype IRI: "123"^^<http://www.w3.org/2001/XMLSchema#integer>
  /// - Typed literals with prefixed names: "123"^^xsd:integer
  ///
  /// This method handles:
  /// - The opening and closing quotes (both single and triple quotes)
  /// - Escape sequences within the string
  /// - Optional language tags (@lang)
  /// - Optional datatype annotations (^^datatype)
  ///
  /// Returns a token of type [TokenType.literal] containing the complete literal
  /// including quotes, language tag or datatype annotation.
  ///
  /// Throws [FormatException] if the literal is not properly closed.
  Token _parseLiteral() {
    final startLine = _line;
    final startColumn = _column;

    // Save the starting position to capture the entire literal
    final startPos = _position;

    // Determine the quote character (single or double)
    final quoteChar = _input[_position];

    // Check for triple quotes (multi-line literal)
    final isTripleQuoted = _position + 2 < _input.length &&
        _input[_position] == quoteChar &&
        _input[_position + 1] == quoteChar &&
        _input[_position + 2] == quoteChar;

    if (isTripleQuoted) {
      // Skip the opening triple quotes
      _position += 3;
      _column += 3;

      // Find the closing triple quotes
      bool foundClosing = false;
      while (_position + 2 <= _input.length) {
        if (_position + 2 < _input.length &&
            _input[_position] == quoteChar &&
            _input[_position + 1] == quoteChar &&
            _input[_position + 2] == quoteChar) {
          // Found closing triple quotes
          _position += 3;
          _column += 3;
          foundClosing = true;
          break;
        }

        if (_input[_position] == '\n') {
          _line++;
          _column = 1;
          _position++;
        } else if (_input[_position] == '\\') {
          _validateStringEscape(_line, _column);
        } else {
          _position++;
          _column++;
        }
      }

      // Check if we reached the end of the input without finding closing quotes
      if (!foundClosing) {
        throw FormatException(
          'Unclosed multi-line literal at $startLine:$startColumn',
        );
      }
    } else {
      // Regular single-line literal
      // Skip opening quote and scan to find the closing quote
      _position++; // Skip opening quote
      _column++;

      while (_position < _input.length && _input[_position] != quoteChar) {
        if (_input[_position] == '\\') {
          _validateStringEscape(_line, _column);
        } else {
          _position++;
          _column++;
        }
      }

      if (_position >= _input.length) {
        throw FormatException('Unclosed literal at $startLine:$startColumn');
      }

      _position++; // Skip closing quote
      _column++;
    }

    // Check for language tag or datatype annotation
    if (_position < _input.length) {
      // Language tag: LANGTAG ::= '@' [a-zA-Z]+ ('-' [a-zA-Z0-9]+)*
      if (_input[_position] == '@') {
        _position++;
        _column++;
        // First part must be [a-zA-Z]+
        if (_position >= _input.length ||
            !RegExp(r'[a-zA-Z]').hasMatch(_input[_position])) {
          throw FormatException(
            'Invalid language tag: must start with a letter at $startLine:$startColumn',
          );
        }
        while (_position < _input.length &&
            RegExp(r'[a-zA-Z]').hasMatch(_input[_position])) {
          _position++;
          _column++;
        }
        // Subsequent parts: ('-' [a-zA-Z0-9]+)*
        while (_position < _input.length && _input[_position] == '-') {
          _position++;
          _column++;
          if (_position >= _input.length ||
              !RegExp(r'[a-zA-Z0-9]').hasMatch(_input[_position])) {
            throw FormatException(
              'Invalid language tag at $startLine:$startColumn',
            );
          }
          while (_position < _input.length &&
              RegExp(r'[a-zA-Z0-9]').hasMatch(_input[_position])) {
            _position++;
            _column++;
          }
        }
      }
      // Datatype annotation
      else if (_position + 1 < _input.length &&
          _input[_position] == '^' &&
          _input[_position + 1] == '^') {
        _position += 2;
        _column += 2;
        if (_position < _input.length && _input[_position] == '<') {
          // Parse until closing '>'
          while (_position < _input.length && _input[_position] != '>') {
            _position++;
            _column++;
          }
          if (_position < _input.length) {
            _position++; // Skip closing '>'
            _column++;
          }
        }
        // Handle prefixed name datatype (e.g., xsd:integer)
        else if (_position < _input.length && _isNameStartCharAt(_position)) {
          // Parse prefix and local name
          while (_position < _input.length) {
            if (_isNameCharAt(_position) || _input[_position] == ':') {
              _position += _lastCharWidth;
              _column++;
            } else {
              break;
            }
          }
        }
      }
    }

    // Extract the entire literal with its annotations
    final literal = _input.substring(startPos, _position);

    return Token(TokenType.literal, literal, startLine, startColumn);
  }

  /// Parses a prefixed name token.
  ///
  /// Prefixed names in Turtle consist of:
  /// - An optional prefix (namespace alias)
  /// - A colon separator (:)
  /// - A local name (the part after the colon)
  ///
  /// Examples in Turtle:
  /// ```turtle
  /// foaf:name       # With prefix 'foaf'
  /// :localName      # With default prefix (empty)
  /// ```
  ///
  /// The prefix must have been declared earlier in the document with @prefix.
  /// This method doesn't validate that requirement; it just tokenizes the syntax.
  ///
  /// Returns a token of type [TokenType.prefixedName] containing the
  /// complete prefixed name.
  ///
  /// Throws [FormatException] if the input doesn't contain a colon where required,
  /// particularly in prefix declarations.
  Token _parsePrefixedName() {
    final startLine = _line;
    final startColumn = _column;
    final buffer = StringBuffer();

    // Check for a digit at the start when allowDigitInLocalName is enabled
    final isStartingWithDigit = _position < _input.length &&
        _isDigitRegExp.hasMatch(_input[_position]) &&
        _hasFlag(TriGParsingFlag.allowDigitInLocalName);

    // Handle empty prefix case (just a colon)
    if (_position < _input.length && _input[_position] == ':') {
      buffer.write(':');
      _position++;
      _column++;
      if (_isLocalNameStart()) {
        _parseLocalNameBody(buffer);
      }
      return Token(
        TokenType.prefixedName,
        buffer.toString(),
        startLine,
        startColumn,
      );
    }

    // Save the prefix part to check if we're in a prefix declaration context
    final prefixStart = _position;
    bool foundColon = false;

    // Special handling for names starting with a digit when allowDigitInLocalName is enabled
    if (isStartingWithDigit) {
      // If starting with a digit, add it to the buffer and continue parsing as a name
      buffer.write(_input[_position]);
      _position++;
      _column++;
    }

    while (_position < _input.length) {
      if (_isNameCharAt(_position) ||
          (isStartingWithDigit && _isDigitRegExp.hasMatch(_input[_position]))) {
        final w = _lastCharWidth;
        buffer.write(_input.substring(_position, _position + w));
        _position += w;
        _column++;
      } else if (_input[_position] == '.' &&
          _position + 1 < _input.length &&
          (_isNameCharAt(_position + 1) || _input[_position + 1] == '.')) {
        // PN_PREFIX allows dots in the middle: ((PN_CHARS | '.')* PN_CHARS)?
        buffer.write('.');
        _position++;
        _column++;
      } else if (_input[_position] == ':') {
        foundColon = true;
        buffer.write(':');
        _position++;
        _column++;
        if (_isLocalNameStart()) {
          _parseLocalNameBody(buffer);
        }
        return Token(
          TokenType.prefixedName,
          buffer.toString(),
          startLine,
          startColumn,
        );
      } else {
        break;
      }
    }

    // Check the context - if we're parsing what appears to be a prefix declaration
    // but didn't find a colon, it's an error
    if (!foundColon) {
      final prefixPart = _input.substring(prefixStart, _position).trim();

      // Look back in the input to see if '@prefix' appears before this token
      int lookBack = prefixStart - 1;
      while (lookBack >= 0 &&
          (_input[lookBack] == ' ' || _input[lookBack] == '\t')) {
        lookBack--;
      }

      // Check if we might be in a prefix declaration context
      if (lookBack >= 7 &&
          (_input.substring(lookBack - 7, lookBack + 1) == '@prefix ' ||
              (_hasFlag(TriGParsingFlag.allowPrefixWithoutAtSign) &&
                  _input.substring(lookBack - 6, lookBack + 1) == 'prefix '))) {
        _log.severe(
          'Invalid prefix declaration: missing colon after prefix name',
        );
        throw FormatException(
          'Invalid prefix declaration: missing colon after "$prefixPart" at $startLine:$startColumn',
        );
      }

      // In relaxed mode, handle standalone identifiers that might be mistaken for prefixes
      if ((_hasFlag(TriGParsingFlag.allowIdentifiersWithoutColon))) {
        _log.warning(
          'In relaxed mode: Found identifier without colon: "$prefixPart" at $startLine:$startColumn',
        );
        // Try to convert to a proper prefixed name if possible, or use as is
        return Token(
          TokenType.prefixedName,
          buffer.toString(),
          startLine,
          startColumn,
        );
      } else {
        _log.severe(
          'Invalid prefixed name format without colon: "$prefixPart"',
        );
        throw FormatException(
          'Invalid prefixed name format without colon: "$prefixPart" at $startLine:$startColumn',
        );
      }
    }

    return Token(
      TokenType.prefixedName,
      buffer.toString(),
      startLine,
      startColumn,
    );
  }

  /// Checks if the input at the current position starts with the given prefix.
  ///
  /// This helper method is used to identify multi-character tokens like
  /// '@prefix' and '@base' without advancing the position.
  ///
  /// Returns true if the input string at the current position starts with
  /// the specified prefix, false otherwise.
  bool _startsWith(String prefix) {
    if (_position + prefix.length > _input.length) return false;
    return _input.substring(_position, _position + prefix.length) == prefix;
  }

  /// Validates that [count] hex digits follow at [startPos] and that the
  /// resulting code point is a valid Unicode scalar value (not a surrogate).
  void _validateHexEscape(int startPos, int count, int line, int col) {
    if (startPos + count > _input.length) {
      throw FormatException(
        'Incomplete Unicode escape at $line:$col',
      );
    }
    final hex = _input.substring(startPos, startPos + count);
    if (!RegExp('^[0-9A-Fa-f]{$count}\$').hasMatch(hex)) {
      throw FormatException(
        'Invalid hex digits in Unicode escape: $hex at $line:$col',
      );
    }
    final codePoint = int.parse(hex, radix: 16);
    if (codePoint >= 0xD800 && codePoint <= 0xDFFF) {
      throw FormatException(
        'Surrogate code point U+${hex.toUpperCase()} is not allowed at $line:$col',
      );
    }
    if (codePoint > 0x10FFFF) {
      throw FormatException(
        'Code point U+${hex.toUpperCase()} exceeds maximum Unicode value at $line:$col',
      );
    }
  }

  static const _validStringEscapes = {
    'b',
    't',
    'n',
    'f',
    'r',
    '"',
    "'",
    '\\',
  };

  /// Validates and skips an escape sequence in a string literal starting
  /// at the backslash. Advances [_position] and [_column] past the escape.
  void _validateStringEscape(int line, int col) {
    // _position is at the backslash
    _position++;
    _column++;
    if (_position >= _input.length) {
      throw FormatException(
        'Incomplete escape sequence at $line:$col',
      );
    }
    final esc = _input[_position];
    if (_validStringEscapes.contains(esc)) {
      _position++;
      _column++;
    } else if (esc == 'u') {
      _validateHexEscape(_position + 1, 4, line, col);
      _position += 5; // u + 4 hex
      _column += 5;
    } else if (esc == 'U') {
      _validateHexEscape(_position + 1, 8, line, col);
      _position += 9; // U + 8 hex
      _column += 9;
    } else {
      throw FormatException(
        'Invalid escape \\$esc in string at $line:$col',
      );
    }
  }

  static String _describeChar(String c) {
    final code = c.codeUnitAt(0);
    if (code < 0x20) return '\\x${code.toRadixString(16).padLeft(2, '0')}';
    return c;
  }

  /// Checks if the character at [_position] + [keywordLength] is a keyword boundary.
  ///
  /// A boundary exists at EOF or when the next character is not a PN_CHARS character
  /// (letter, digit, underscore, hyphen, etc.) — i.e. it cannot continue a name token.
  /// This prevents false keyword matches on prefixes of longer names (e.g. "baseline").
  bool _isKeywordBoundary(int keywordLength) {
    final pos = _position + keywordLength;
    if (pos >= _input.length) return true;
    return !_isNameCharAt(pos);
  }

  /// Checks if the input at the current position starts with the given prefix (case-insensitive).
  ///
  /// This helper method is used to identify multi-character tokens like
  /// 'prefix', 'PREFIX', 'base', 'BASE' etc. without advancing the position.
  ///
  /// Returns true if the input string at the current position starts with
  /// the specified prefix (case-insensitive comparison), false otherwise.
  bool _startsWithCaseInsensitive(String prefix) {
    if (_position + prefix.length > _input.length) return false;
    return _input
            .substring(_position, _position + prefix.length)
            .toLowerCase() ==
        prefix.toLowerCase();
  }

  /// Checks if the current position starts a valid PN_LOCAL first character:
  /// `(PN_CHARS_U | ':' | [0-9] | PLX)`.
  bool _isLocalNameStart() {
    if (_position >= _input.length) return false;
    final c = _input[_position];
    if (_isNameStartCharAt(_position) ||
        _isDigitRegExp.hasMatch(c) ||
        c == ':') {
      return true;
    }
    if (c == '%' && _position + 2 < _input.length) return true;
    if (c == '\\' &&
        _position + 1 < _input.length &&
        _pnLocalEscChars.contains(_input[_position + 1])) {
      return true;
    }
    return false;
  }

  /// Tries to consume a PLX sequence (`%XX` or `\X`) at the current position.
  /// Appends consumed characters to [buffer] and returns true if successful.
  bool _tryConsumePlx(StringBuffer buffer) {
    if (_position >= _input.length) return false;
    if (_input[_position] == '%' && _position + 2 < _input.length) {
      // PERCENT ::= '%' HEX HEX
      final h1 = _input[_position + 1];
      final h2 = _input[_position + 2];
      if (RegExp(r'[0-9A-Fa-f]').hasMatch(h1) &&
          RegExp(r'[0-9A-Fa-f]').hasMatch(h2)) {
        buffer.write(_input.substring(_position, _position + 3));
        _position += 3;
        _column += 3;
        return true;
      }
    } else if (_input[_position] == '\\' && _position + 1 < _input.length) {
      // PN_LOCAL_ESC ::= '\' ('_' | '~' | '.' | '-' | '!' | '$' | '&' | "'" | '(' | ')' | '*' | '+' | ',' | ';' | '=' | '/' | '?' | '#' | '@' | '%')
      final next = _input[_position + 1];
      if (_pnLocalEscChars.contains(next)) {
        buffer.write(_input.substring(_position, _position + 2));
        _position += 2;
        _column += 2;
        return true;
      }
    }
    return false;
  }

  /// Parses the body of a PN_LOCAL (local name after the colon in a prefixed name).
  /// Appends characters to [buffer] from the current position.
  void _parseLocalNameBody(StringBuffer buffer) {
    while (_position < _input.length) {
      if (_tryConsumePlx(buffer)) {
        continue;
      }
      if (_isLocalNameCharAt(_position) ||
          _isDigitRegExp.hasMatch(_input[_position])) {
        final w = _lastCharWidth;
        buffer.write(_input.substring(_position, _position + w));
        _position += w;
        _column++;
      } else {
        break;
      }
    }
    // Strip trailing dots (not allowed at end of PN_LOCAL)
    final content = buffer.toString();
    if (content.endsWith('.')) {
      final colIdx = content.indexOf(':');
      final afterColon = content.substring(colIdx + 1);
      final trimmed = afterColon.replaceAll(RegExp(r'\.+$'), '');
      final dotsRemoved = afterColon.length - trimmed.length;
      if (dotsRemoved > 0) {
        _position -= dotsRemoved;
        _column -= dotsRemoved;
        buffer.clear();
        buffer.write(content.substring(0, content.length - dotsRemoved));
      }
    }
  }

  /// Checks if a character is valid as the start of a name.
  ///
  /// In Turtle, name start characters are defined by the specification as:
  /// - Letters (a-z, A-Z)
  /// - Underscore (_)
  /// - Colon (:) in some contexts
  ///
  /// This is used for prefixed names and local names.
  ///
  /// Returns true if the character is valid as a name start character,
  /// false otherwise.
  static final _isNameStartCharRegExp = pn.pnNameStartChar;

  /// Returns true if the character at [pos] is a name start char, and if so,
  /// sets `_lastCharWidth` to the number of UTF-16 code units consumed.
  int _lastCharWidth = 1;
  bool _isNameStartCharAt(int pos) {
    final (ch, w) = _charAt(pos);
    _lastCharWidth = w;
    return _isNameStartCharRegExp.hasMatch(ch);
  }

  bool _isNameCharAt(int pos) {
    final (ch, w) = _charAt(pos);
    _lastCharWidth = w;
    return _isNameCharRegExp.hasMatch(ch);
  }

  bool _isLocalNameCharAt(int pos) {
    final (ch, w) = _charAt(pos);
    _lastCharWidth = w;
    return _isLocalNameCharRegExp.hasMatch(ch);
  }

  static final _isNameCharRegExp = pn.pnChars;

  static final _isLocalNameCharRegExp = pn.pnLocalNameChar;
}
