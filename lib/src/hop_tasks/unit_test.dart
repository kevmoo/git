part of hop_tasks;

Task createUnitTestTask(Action1<unittest.Configuration> unitTestAction) {
  return new Task.async((TaskContext ctx) {
    final config = new _HopTestConfiguration(ctx);
    final future = config.future;
    unitTestAction(config);
    unittest.runTests();
    return future;
  }, 'Run unit tests in the console');
}

class _HopTestConfiguration extends unittest.Configuration {
  final Completer<bool> _completer;
  final TaskContext _context;

  _HopTestConfiguration(this._context) : this._completer = new Completer<bool>();

  Future<bool> get future => _completer.future;

  get autoStart => false;

  void onStart() {
     // overloading to prevent 'print' in baseclass
  }

  void logTestcaseMessage(unittest.TestCase testCase, String message) {
    // something eles?
  }

  void onTestResult(unittest.TestCase testCase) {
    super.onTestResult(testCase);

    // result should not be null here
    assert(testCase.result != null);

    if(testCase.result == unittest.PASS) {
      _context.fine(testCase.description);
    }
    else {
      _context.severe(
'''[${testCase.result}] ${testCase.description}
${testCase.message}
${testCase.stackTrace}''');
    }
  }

  void onSummary(int passed, int failed, int errors, List<unittest.TestCase> results,
              String uncaughtError) {
    final bool success = failed == 0 && errors == 0 && uncaughtError == null;
    final message = "$passed PASSED, $failed FAILED, $errors ERRORS";
    if(success) {
      _context.fine(message);
    } else {
      _context.severe(message);
    }
    _completer.complete(success);
  }
}

