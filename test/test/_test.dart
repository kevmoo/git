library test_bot_test;

import 'dart:isolate';
import 'package:unittest/unittest.dart';
import 'package:bot/test.dart';

const _failMessage = 'failing, per request';
const _successValue = 42;

void register() {
  test('expectFutureComplete', _testExpectFutureComplete);
  test('expectFutureComplete with complete', _testExpectFutureCompleteWithComplete);
  test('expectFutureException', _testExpectFutureException);
  test('expectFutureException', _testExpectFutureExceptionWithComplete);
}

void _testExpectFutureComplete() {
  expectFutureComplete(_getFuture(false));
}

void _testExpectFutureCompleteWithComplete() {
  final onComplete = expectAsync1((value) {
    expect(value, _successValue);
  });
  expectFutureComplete(_getFuture(false), onComplete);
}

void _testExpectFutureException() {
  expectFutureFail(_getFuture(true));
}

void _testExpectFutureExceptionWithComplete() {
  final onFail = expectAsync1((value) {
    expect(value, _failMessage);
  });
  expectFutureFail(_getFuture(true), onFail);
}

Future _getFuture(bool shouldFail) {
  return spawnFunction(_echoIsolate)
      .call(shouldFail)
      .transform((bool returnedFail) {
        if(returnedFail) {
          throw _failMessage;
        }
        return _successValue;
      });
}

void _echoIsolate() {
  port.receive((bool input, SendPort replyTo) {
    replyTo.send(input);
  });
}
