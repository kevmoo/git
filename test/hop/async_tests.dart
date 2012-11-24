part of test_hop;

class AsyncTests {
  static void run() {
    test('null result bad' , _testNullResult);
  }

  static void _testNullResult() {
    _testSimpleAsyncTask((ctx) => null,
      (Future f) {
        expect(f.value, RunResult.ERROR);
      }
    );
  }

  static Action0 _testSimpleAsyncTask(Func1<TaskContext,
                                     Future<bool>> taskFuture,
                                     Action1<Future<bool>> completeHandler) {
    final name = 'task_name';
    final tasks = new BaseConfig();
    tasks.addAsync(name, taskFuture);
    tasks.freeze();

    final runner = new TestRunner(tasks, [name]);
    final future = runner.run();
    expect(future, isNotNull);
    expect(future.isComplete, isTrue);

    final onComplete = expectAsync1(completeHandler);

    future.onComplete(onComplete);
  }
}
