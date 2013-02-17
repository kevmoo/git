part of bot;

void require(bool truth, [String message]) {
  if(!truth) {
    throw new Exception(message);
  }
}

void requireArgument(bool truth, String argName, [String message]) {
  _metaRequireArgumentNotNullOrEmpty(argName);
  if(!truth) {
    if(message == null || message.isEmpty) {
      message = 'value was invalid';
    }
    throw new DetailedArgumentError(argName, message);
  }
}

void requireArgumentNotNull(argument, String argName) {
  _metaRequireArgumentNotNullOrEmpty(argName);
  if(argument == null) {
    throw new NullArgumentError(argName);
  }
}

void requireArgumentNotNullOrEmpty(String argument, String argName) {
  _metaRequireArgumentNotNullOrEmpty(argName);
  if(argument == null) {
    throw new NullArgumentError(argName);
  }
  else if(argument.length == 0) {
    throw new DetailedArgumentError(argName, 'cannot be an empty string');
  }
}

void requireArgumentMatches(RegExp regex, String argument, String argName) {
  if(regex == null) {
    throw new InvalidOperationError("That's just sad. No null regex");
  }
  requireArgumentNotNull(argument, argName);
  if(!regex.hasMatch(argument)) {
    throw new DetailedArgumentError(argName,
        'The value "$argument" must match the regular expression "${regex.pattern}"');
  }
}

void _metaRequireArgumentNotNullOrEmpty(String argName) {
  if(argName == null || argName.length == 0) {
    throw new InvalidOperationError("That's just sad. Give me a good argName");
  }
}
