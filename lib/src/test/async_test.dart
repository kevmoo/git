part of bot_test;

void expectFutureFail(Future future, [Action1 onException]) {
  assert(future != null);

  final testWait = expectAsync1((Future f) {
    assert(f.isComplete);

    if(f.hasValue) {
      throw 'Future completed. Expected failure.';
    } else {
      if(onException != null) {
        onException(f.exception);
      }
    }
  });
  future.onComplete(testWait);
}

void expectFutureComplete(Future future, [Action1 onComplete]) {
  assert(future != null);

  final testWait = expectAsync1((Future f) {
    assert(f.isComplete);

    if(f.hasValue) {
      if(onComplete != null) {
        onComplete(f.value);
      }
    } else {
      assert(f.exception != null);
      throw f.exception;
    }
  });
  future.onComplete(testWait);
}
