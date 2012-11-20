part of bot_test;

void pending() {
  throw new ExpectException('Not implemented');
}

final Matcher throwsInvalidOperationError =
  const Throws(const _InvalidOperationError());

final Matcher throwsNullArgumentError =
  const Throws(const _NullArgumentError());

class _InvalidOperationError extends TypeMatcher {
  const _InvalidOperationError() : super("InvalidOperationException");
  bool matches(item, MatchState matchState) => item is InvalidOperationError;
}

class _NullArgumentError extends TypeMatcher {
  const _NullArgumentError() : super("NullArgumentException");
  bool matches(item, MatchState matchState) => item is NullArgumentError;
}
