part of bot;

class InvalidOperationError implements Exception {
  final String message;

  const InvalidOperationError([this.message = ""]);
}
