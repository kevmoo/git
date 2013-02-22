part of test_hop;

class AsyncTests {
  static void run() {
    test('null result bad' , _testNullResult);
    test('exception outside future' , _testException);
  }

  static void _testNullResult() {
    _testSimpleAsyncTask((ctx) => null,
      (value) {
        expect(value, RunResult.ERROR);
      }
    );
  }

  static void _testException() {
    _testSimpleAsyncTask((ctx) {
      throw 'not impld';
    },
      (value) {
        expect(value, RunResult.EXCEPTION);
      }
    );
  }

  static Action0 _testSimpleAsyncTask(Func1<TaskContext,
                                     Future<bool>> taskFuture,
                                     Action1<RunResult> completeHandler) {
    testTaskCompletion(new Task.async(taskFuture), completeHandler);
  }
}
