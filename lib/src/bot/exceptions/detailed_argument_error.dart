part of bot;

class DetailedArgumentError implements ArgumentError {
  final argument;
  final details;

  DetailedArgumentError(this.argument, this.details) {
    if(argument == null || argument.length == 0) {
      throw new InvalidOperationError("That's just sad. Give me a valid argument");
    }
    if(details == null || details.length == 0) {
      throw new InvalidOperationError("That's just sad. I need details!");
    }
  }

  String get message => 'Illegal argument: "$argument" -- $details';

  String toString() => message;
}
