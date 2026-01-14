class ParseException implements Exception {
  final String message;

  ParseException(this.message);

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParseException && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
