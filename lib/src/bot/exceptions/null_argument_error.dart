part of bot;

class NullArgumentError extends DetailedArgumentError {
  NullArgumentError(String argument) : super(argument, "cannot be null");
}
