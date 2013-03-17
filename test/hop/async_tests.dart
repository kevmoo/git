part of test_hop;

class AsyncTests {
  static void run() {
    test('null result bad' , _testNullResult);
    test('exception outside future' , _testException);
  }

  static Future _testNullResult() {
    return _testSimpleAsyncTask((ctx) => null)
        .then((value) {
          expect(value, RunResult.ERROR);
        });
  }

  static Future _testException() {
    return _testSimpleAsyncTask((ctx) {
        throw 'not impld';
      }).then((value) {
        expect(value, RunResult.EXCEPTION);
      });
  }

  static Future<RunResult> _testSimpleAsyncTask(Func1<TaskContext,
                                     Future<bool>> taskFuture) {
    return runTaskInTestRunner(new Task.async(taskFuture));
  }
}
