import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart';

final _log = Logger('DartFormatter');

/// Interface for formatting Dart code.
abstract class CodeFormatter {
  /// Formats the given Dart code.
  ///
  /// Returns the formatted code on success, or the original unformatted code
  /// if formatting fails.
  String formatCode(String code);
}

/// Implementation of CodeFormatter using dart_style.
class DartCodeFormatter implements CodeFormatter {
  final DartFormatter _formatter;

  DartCodeFormatter({DartFormatter? formatter})
      : _formatter = formatter ??
            DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            );

  @override
  String formatCode(String code) {
    try {
      return _formatter.format(code);
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to format generated Dart code: $e',
        e,
        stackTrace,
      );
      // Return unformatted code as fallback to avoid build failures
      return code;
    }
  }
}

/// No-op formatter for testing or when formatting is disabled.
class NoOpCodeFormatter implements CodeFormatter {
  @override
  String formatCode(String code) => code;
}
