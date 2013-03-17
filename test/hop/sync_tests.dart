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

  static Future _testCtxFail() {
    return _testSimpleSyncTask((ctx) => ctx.fail('fail!'))
      .then((value) {
        expect(value, RunResult.FAIL);
      });
  }

  static Future _testTrueIsCool() {
    return _testSimpleSyncTask((ctx) => true).then((value) {
      expect(value, RunResult.SUCCESS);
    });
  }

  static Future _testFalseIsFail() {
    return _testSimpleSyncTask((ctx) => false).then((value) {
      expect(value, RunResult.FAIL);
    });
  }

  static Future _testNullIsSad() {
    return _testSimpleSyncTask((ctx) => null).then((value) {
      expect(value, RunResult.ERROR);
    });
  }

  static Future _testExceptionIsSad() {
    return _testSimpleSyncTask((ctx) {
        throw 'sorry';
      })
      .then((value) {
        expect(value, RunResult.EXCEPTION);
      });
  }

  static Future _testBadParam() {
    final taskConfig = new TaskRegistry();
    taskConfig.addSync('good', (ctx) => true);

    final hopConfig = new HopConfig(taskConfig, ['bad'], _testPrint);

    return Runner.run(hopConfig)
        .then((value) {
          expect(value, RunResult.BAD_USAGE);
          // TODO: test that proper error message is printed
        });
  }

  static Future _testNoParam() {
    final taskConfig = new TaskRegistry();
    taskConfig.addSync('good', (ctx) => true);

    final hopConfig = new HopConfig(taskConfig, [], _testPrint);

    return Runner.run(hopConfig)
        .then((value) {
          expect(value, RunResult.SUCCESS);
          // TODO: test that task list is printed
        });
  }

  static Future _testNoTasks() {
    final taskConfig = new TaskRegistry();

    final hopConfig = new HopConfig(taskConfig, [], _testPrint);

    return Runner.run(hopConfig)
        .then((value) {
          expect(value, RunResult.SUCCESS);
        });
  }

  static Future _testSimpleSyncTask(Func1<TaskContext, bool> taskFunc) {
    return runTaskInTestRunner(new Task.sync(taskFunc));
  }
}
