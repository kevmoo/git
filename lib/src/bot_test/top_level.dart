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

void expectFutureFail(Future future, [Action1 onException]) {
  assert(future != null);

  final testWait = expectAsync1((Future f) {
    assert(f.isComplete);

    expect(f.hasValue, isFalse, reason: 'Expected future to throw an exception');
    if(onException != null) {
      onException(f.exception);
    }
  });
  future.onComplete(testWait);
}

void expectFutureComplete(Future future, [Action1 onComplete]) {
  assert(future != null);

  final testWait = expectAsync1((Future f) {
    assert(f.isComplete);

    expect(f.hasValue, true, reason: 'Expected future to complete. Instead: ${f.exception}');

    if(onComplete != null) {
      onComplete(f.value);
    }
  });
  future.onComplete(testWait);
}
