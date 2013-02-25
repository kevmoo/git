part of hop_tasks;

const _listFlag = 'list';

Task createUnitTestTask(Action1<unittest.Configuration> unitTestAction) {
  return new Task.async((TaskContext ctx) {
    final config = new _HopTestConfiguration(ctx);
    unitTestAction(config);

    if(!ctx.arguments.rest.isEmpty) {
      ctx.info('Filtering tests by: ${ctx.arguments.rest}');

      unittest.filterTests((unittest.TestCase tc) {
        return ctx.arguments.rest.every((arg) => tc.description.contains(arg));
      });
    }

    if(ctx.arguments[_listFlag]) {
      final list = unittest.testCases
          .map((tc) => tc.description)
          .toList();

      list.sort();

      list.insertRange(0, 1, 'Test cases:');

      ctx.info(list.join('\n'));

      return new Future.immediate(true);
    }

    unittest.runTests();
    return config.future;
  },
  config: _unittestParserConfig,
  description: 'Run unit tests in the console',
  extendedArgs: [new TaskArgument('filter', multiple: true)]);
}

void _unittestParserConfig(ArgParser parser) {
  parser.addFlag(_listFlag, abbr: 'l', defaultsTo: false,
      help: "Just list the test case names. Don't run them. Any filter is still applied.");
}

class _HopTestConfiguration extends unittest.Configuration {
  final Completer<bool> _completer;
  final TaskContext _context;

  _HopTestConfiguration(this._context) : this._completer = new Completer<bool>();

  Future<bool> get future => _completer.future;

  @override
  get autoStart => false;

  @override
  void logTestCaseMessage(unittest.TestCase testCase, String message) {
    final msg = '${testCase.description}\n$message';
    _context.fine(msg);
  }

  @override
  void onTestResult(unittest.TestCase testCase) {
    super.onTestResult(testCase);

    // result should not be null here
    assert(testCase.result != null);

    if(testCase.result == unittest.PASS) {
      _context.info(testCase.description);
    }
    else {
      _context.severe(
'''[${testCase.result}] ${testCase.description}
${testCase.message}
${testCase.stackTrace}''');
    }
  }

  @override
  void onSummary(int passed, int failed, int errors, List<unittest.TestCase> results,
              String uncaughtError) {
    final bool success = failed == 0 && errors == 0 && uncaughtError == null;
    final message = "$passed PASSED, $failed FAILED, $errors ERRORS";
    if(success) {
      _context.info(message);
    } else {
      _context.severe(message);
    }
    _completer.complete(success);
  }
}

