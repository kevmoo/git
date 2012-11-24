part of test_hop;

// TODO: test output using new TestRunner

class SyncTests {
  static void run() {
    test('true result is cool', _testTrueIsCool);
    test('false result fails', _testFalseIsFail);
    test('null result is sad', _testNullIsSad);
    test('exception is sad', _testExceptionIsSad);
    test('bad task name', _testBadParam);
    test('no task name', _testNoParam);
    test('ctx.fail', _testCtxFail);
  }

  static void _testCtxFail() {
    _testSimpleSyncTask((ctx) => ctx.fail('fail!'), (f) {
      expect(f.value, RunResult.FAIL);
    });
  }

  static void _testTrueIsCool() {
    _testSimpleSyncTask((ctx) => true, (f) {
      expect(f.value, RunResult.SUCCESS);
    });
  }

  static void _testFalseIsFail() {
    _testSimpleSyncTask((ctx) => false, (f) {
      expect(f.value, RunResult.FAIL);
    });
  }

  static void _testNullIsSad() {
    _testSimpleSyncTask((ctx) => null,(Future f) {
      expect(f.value, RunResult.ERROR);
    });
  }

  static void _testExceptionIsSad() {
    _testSimpleSyncTask((ctx) {
        throw 'sorry';
      },
      (Future f) {
        expect(f.value, RunResult.EXCEPTION);
      }
    );
  }

  static void _testBadParam() {
    final tasks = new BaseConfig();
    tasks.addSync('good', (ctx) => true);
    tasks.freeze();

    final runner = new TestRunner(tasks, ['bad']);
    final future = runner.run();
    expect(future, isNotNull);
    expect(future.isComplete, isTrue);

    final onComplete = expectAsync1((f) {
      expect(f.value, RunResult.BAD_USAGE);
      // TODO: test that proper error message is printed
    });

    future.onComplete(onComplete);
  }

  static void _testNoParam() {
    final tasks = new BaseConfig();
    tasks.addSync('good', (ctx) => true);
    tasks.freeze();

    final runner = new TestRunner(tasks, []);
    final future = runner.run();
    expect(future, isNotNull);
    expect(future.isComplete, isTrue);

    final onComplete = expectAsync1((f) {
      expect(f.value, RunResult.SUCCESS);
      // TODO: test that task list is printed
    });

    future.onComplete(onComplete);
  }

  static Action0 _testSimpleSyncTask(Func1<TaskContext, bool> task,
                            Action1<Future<bool>> completeHandler) {
    final name = 'task_name';
    final tasks = new BaseConfig();
    tasks.addSync(name, task);
    tasks.freeze();

    final runner = new TestRunner(tasks, [name]);
    final future = runner.run();
    expect(future, isNotNull);
    expect(future.isComplete, isTrue);

    final onComplete = expectAsync1(completeHandler);

    future.onComplete(onComplete);
  }
}