part of bot;

class DetailedArgumentError implements ArgumentError {
  final argument;
  final details;

  DetailedArgumentError(this.argument, this.details) {
    requireArgumentNotNullOrEmpty(argument, 'argument');
    requireArgumentNotNullOrEmpty(details, 'details');
  }

  String get message => 'Illegal argument: "$argument" -- $details';

  String toString() => message;
}
