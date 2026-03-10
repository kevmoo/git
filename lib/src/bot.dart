// Code copied from
// https://github.com/kevmoo/bot.dart/commit/6badd135a5

void requireArgument(bool truth, String argName, [String? message]) {
  metaRequireArgumentNotNullOrEmpty(argName);
  if (!truth) {
    if (message == null || message.isEmpty) {
      message = 'value was invalid';
    }
    throw ArgumentError(message);
  }
}

void requireArgumentNotNullOrEmpty(String? argument, String argName) {
  metaRequireArgumentNotNullOrEmpty(argName);
  if (argument == null) {
    throw ArgumentError.notNull(argument);
  } else if (argument.isEmpty) {
    throw ArgumentError.value(argument, argName, 'cannot be an empty string');
  }
}

void requireArgumentContainsPattern(
  Pattern pattern,
  String argValue,
  String argName,
) {
  if (!argValue.contains(pattern)) {
    throw ArgumentError.value(
      argValue,
      argName,
      'The value "$argValue" does not contain the pattern "$pattern"',
    );
  }
}

void metaRequireArgumentNotNullOrEmpty(String argName) {
  if (argName.isEmpty) {
    throw const _InvalidOperationError(
      "That's just sad. Give me a good argName",
    );
  }
}

class _InvalidOperationError implements Exception {
  final String message;

  const _InvalidOperationError([this.message = '']);
}

