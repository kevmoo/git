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
    test('no tasks defined', _testNoTasks);
    test('ctx.fail', _testCtxFail);
  }

  static void _testCtxFail() {
    _testSimpleSyncTask((ctx) => ctx.fail('fail!'), (value) {
      expect(value, RunResult.FAIL);
    });
  }

  static void _testTrueIsCool() {
    _testSimpleSyncTask((ctx) => true, (value) {
      expect(value, RunResult.SUCCESS);
    });
  }

  static void _testFalseIsFail() {
    _testSimpleSyncTask((ctx) => false, (value) {
      expect(value, RunResult.FAIL);
    });
  }

  static void _testNullIsSad() {
    _testSimpleSyncTask((ctx) => null,(value) {
      expect(value, RunResult.ERROR);
    });
  }

  static void _testExceptionIsSad() {
    _testSimpleSyncTask((ctx) {
        throw 'sorry';
      },
      (value) {
        expect(value, RunResult.EXCEPTION);
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

    final onComplete = expectAsync1((value) {
      expect(value, RunResult.BAD_USAGE);
      // TODO: test that proper error message is printed
    });

    future.then(onComplete);
  }

  static void _testNoParam() {
    final tasks = new BaseConfig();
    tasks.addSync('good', (ctx) => true);
    tasks.freeze();

    final runner = new TestRunner(tasks, []);
    final future = runner.run();
    expect(future, isNotNull);

    final onComplete = expectAsync1((value) {
      expect(value, RunResult.SUCCESS);
      // TODO: test that task list is printed
    });

    future.then(onComplete);
  }

  static void _testNoTasks() {
    final tasks = new BaseConfig();
    tasks.freeze();

    final runner = new TestRunner(tasks, []);
    final future = runner.run();
    expect(future, isNotNull);

    final onComplete = expectAsync1((value) {
      expect(value, RunResult.SUCCESS);
      // TODO: test that task list is printed
    });

    future.then(onComplete);
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

    final onComplete = expectAsync1(completeHandler);

    future.then(onComplete);
  }
}