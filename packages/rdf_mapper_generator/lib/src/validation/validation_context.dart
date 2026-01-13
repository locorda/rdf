import 'package:build/build.dart';

/// Exception thrown when validation fails.
class ValidationException implements Exception {
  final List<String> errors;
  final List<String> warnings;

  ValidationException({
    required this.errors,
    this.warnings = const [],
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    if (warnings.isNotEmpty) {
      buffer.writeln('Validation Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  • $warning');
      }
      buffer.writeln();
    }

    buffer.writeln('Validation Errors:');
    for (final error in errors) {
      buffer.writeln('  • $error');
    }

    return buffer.toString();
  }
}

/// Context for collecting validation messages and failing when needed.
class ValidationContext {
  final List<String> _errors = [];
  final List<String> _warnings = [];
  final List<String> _fine = [];
  final String? _context;
  final List<ValidationContext> _children = [];
  ValidationContext([this._context]);

  /// Adds a validation error.
  void addError(String message) {
    _errors.add(_formatMessage(message));
  }

  /// Adds a validation warning.
  void addWarning(String message) {
    _warnings.add(_formatMessage(message));
  }

  void addFine(String message) {
    _fine.add(_formatMessage(message));
  }

  /// Creates a new validation context with additional context information.
  ValidationContext withContext(String context) {
    final child = ValidationContext(_combineContexts(_context, context));
    _children.add(child);
    return child;
  }

  /// Validates a condition, adding an error if false.
  void check(
    bool condition, {
    required String errorMessage,
    String? warningMessage,
  }) {
    if (!condition) {
      if (warningMessage != null) {
        addWarning(warningMessage);
      } else {
        addError(errorMessage);
      }
    }
  }

  /// Throws a [ValidationException] if there are any errors.
  void throwIfErrors() {
    if (!isValid) {
      throw ValidationException(
        errors: errors,
        warnings: warnings,
      );
    }
    if (hasWarnings) {
      for (final warning in warnings) {
        // print("!!!" + warning);
        log.warning(warning);
      }
    }
    if (hasFine) {
      for (final f in fine) {
        // print("Fine: " + f);
        log.fine(f);
      }
    }
  }

  /// Returns true if there are no errors.
  bool get isValid => _errors.isEmpty && _children.every((c) => c.isValid);

  /// Returns true if there are any warnings.
  bool get hasWarnings =>
      _warnings.isNotEmpty || _children.any((c) => c.hasWarnings);

  bool get hasFine => _fine.isNotEmpty || _children.any((c) => c.hasFine);

  /// Returns all error messages.
  List<String> get errors => List.unmodifiable([
        ..._errors,
        ..._children.expand((c) => c.errors),
      ]);

  /// Returns all warning messages.
  List<String> get warnings => List.unmodifiable([
        ..._warnings,
        ..._children.expand((c) => c.warnings),
      ]);

  List<String> get fine => List.unmodifiable([
        ..._fine,
        ..._children.expand((c) => c.fine),
      ]);

  String _formatMessage(String message) {
    return _context != null ? '[$_context] $message' : message;
  }

  static String _combineContexts(String? parent, String child) {
    if (parent == null) return child;
    return '$parent > $child';
  }
}
