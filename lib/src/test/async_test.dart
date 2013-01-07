part of bot_test;

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
