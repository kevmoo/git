part of bot;

class NullArgumentError implements ArgumentError {
  final String argument;

  NullArgumentError(this.argument);

  String get message => 'Null argument: $argument';

  String toString() => message;
}
