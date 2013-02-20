part of test_bot_async;

void registerDelayedResultTests() {
  group('delayedResult', () {

    _drTest('null', null, null);

    _drTest('obj', 1, 1);

    _drTest('func to obj', () => 2, 2);
    _drTest('func to func to obj', () {
      return () => 3;
    }, 3);

    _drTest('future to obj', new Future.immediate(4), 4);

    _drTest('func to future to obj', () => new Future.immediate(5), 5);

    [false, true].forEach((v) {
      _testSilly([], v);
      _testSilly([true], v);
      _testSilly([false], v);
      _testSilly([true, true], v);
      _testSilly([true, false], v);
      _testSilly([false, true], v);
      _testSilly([false, false], v);
      _testSilly([true,true, true], v);
      _testSilly([true, true, false], v);
      _testSilly([true, false, true], v);
      _testSilly([true, false, false], v);
      _testSilly([false, true, true], v);
      _testSilly([false, true, false], v);
      _testSilly([false, false, true], v);
      _testSilly([false, false, false], v);
    });
  });
}

int _drValue = 0;

void _testSilly(List<bool> values, bool doThrow) {

  final finalVal = _drValue++;

  var msg = values.map((v) => v ? 'future' : 'func').join(' to ');
  if(!msg.isEmpty) {
    msg = msg.concat(' to ');
  }

  final finalOutput = doThrow ? 'throw sorry' : 'obj';

  msg = msg.concat(finalOutput);

  _drTest(msg, _returnSilly(values, finalVal, doThrow), finalVal, doThrow);
}

_returnSilly(List<bool> values, finalVal, bool doThrow) {
  assert(values != null);
  if(values.isEmpty) {
    if(doThrow) {
      return () { throw "sorry, I don't like $finalVal"; };
    }
    return finalVal;
  }

  final doFuture = values.removeAt(0);
  if(doFuture) {
    return new Future.immediate(_returnSilly(values, finalVal, doThrow));
  } else {
    return () => _returnSilly(values, finalVal, doThrow);
  }
}

void _drTest(String description, input, expectedOutput, [bool expectThrow = false]) {
  test(description, () {
    final future = getDelayedResult(input);
    if(expectThrow) {
      expect(future, throwsA("sorry, I don't like $expectedOutput"));
    } else {
      expect(future, finishesWith(same(expectedOutput)));
    }
  });
}
