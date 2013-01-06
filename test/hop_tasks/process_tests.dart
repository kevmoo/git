part of test_hop_tasks;

// TODO: support windows? Test on Linux?
// TODO: need to extend TestTaskContext to have logging events
//       needed to verify output of commands, right?

class ProcessTests {
  static void run() {
    test('test command success', _testProcessSuccess);
    test('test command fail', _testProcessFail);
    test('test command does not exist', _testProcessMissing);
  }

  static void _testProcessSuccess() {
    final scriptPath = _getTestScriptPath('bash_exit_0');
    final task = createProcessTask(scriptPath);

    _testSimpleAsyncTask(task, (RunResult result) {
      expect(result.success, isTrue);
    });
  }

  static void _testProcessFail() {
    final scriptPath = _getTestScriptPath('bash_exit_1');
    final task = createProcessTask(scriptPath);

    _testSimpleAsyncTask(task, (RunResult rr) {
      expect(rr, RunResult.FAIL);
    });
  }

  static void _testProcessMissing() {
    // NOTE: making the relatively safe assumption that this is not
    // a valid command on the test system. Could find out w/ 'which'..but...eh
    final scriptPath = 'does_not_exist_right';
    final task = createProcessTask(scriptPath);

    _testSimpleAsyncTask(task, (RunResult rr) {
      expect(rr, RunResult.EXCEPTION);
    });
  }

  static Action0 _testSimpleAsyncTask(Task task, Action1<RunResult> completeHandler) {
    final name = 'task_name';
    final tasks = new BaseConfig();
    tasks.addTask(name, task);
    tasks.freeze();

    final runner = new TestRunner(tasks, [name]);
    final future = runner.run();
    expect(future, isNotNull);

    expectFutureComplete(future, completeHandler);
  }

  static String _getTestScriptPath(String name) {
    // Since there is no way to figure out where 'this' file is, we have to
    // assume that script was run from the root of the project
    // so...the file should be at...

    final filePath = 'test/hop_tasks/process_scripts/$name';
    final file = new File(filePath);

    if(!file.existsSync()) {
      throw
'''Could not find file "$filePath".
Are you running this script from the root of the project?''';
    }
    return filePath;
  }
}
