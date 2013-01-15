part of bot_test;

void pending() {
  throw new ExpectException('Not implemented');
}

final Matcher throwsInvalidOperationError =
  const Throws(const _InvalidOperationError());

final Matcher throwsStateError =
  const Throws(const _StateErrorMatcher());

final Matcher throwsNullArgumentError =
  const Throws(const _NullArgumentError());

final Matcher throwsAssertionError =
  const Throws(const _AssertionErrorMatcher());

void expectFutureFail(Future future, [Action1<AsyncError> onException]) {
  assert(future != null);

  final testWait = expectAsync2((bool isError, result) {
    assert(isError != null);

    if(!isError) {
      fail('Expected future to throw an exception');
    }
    if(onException != null) {
      onException(result);
    }
  });
  future.then((value) => testWait(false, value), onError: (error) => testWait(true, error));
}

void expectFutureComplete(Future future, [Action1 onComplete]) {
  assert(future != null);

  final testWait = expectAsync2((bool isError, result) {
    assert(isError != null);

    if(isError) {
      final AsyncError err = result;
      registerException(err.error, err.stackTrace);
    }

    if(onComplete != null) {
      onComplete(result);
    }
  });
  future.then((value) => testWait(false, value), onError: (error) => testWait(true, error));
}

class _AssertionErrorMatcher extends TypeMatcher {
  const _AssertionErrorMatcher() : super("AssertMatcher");
  bool matches(item, MatchState matchState) => item is AssertionError;
}

class _StateErrorMatcher extends TypeMatcher {
  const _StateErrorMatcher() : super("StateErrorMatcher");
  bool matches(item, MatchState matchState) => item is StateError;
}

class _InvalidOperationError extends TypeMatcher {
  const _InvalidOperationError() : super("InvalidOperationException");
  bool matches(item, MatchState matchState) => item is InvalidOperationError;
}

class _NullArgumentError extends TypeMatcher {
  const _NullArgumentError() : super("NullArgumentException");
  bool matches(item, MatchState matchState) => item is NullArgumentError;
}
