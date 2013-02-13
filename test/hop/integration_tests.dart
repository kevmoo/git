part of test_hop;

class IntegrationTests {
  static void run() {
    test('hop output is sorted', _testOutputSorted);
    test('bad hop command', _testBadHopCommand);
  }

  static void _testBadHopCommand() {
    _runHop(['bad_command_name'], (ProcessResult pr) {
      expect(pr.exitCode, equals(RunResult.BAD_USAGE.exitCode));
    });
  }

  static void _testOutputSorted() {
    _runHop([Runner.RAW_TASK_LIST_CMD], (ProcessResult pr) {
      expect(pr.exitCode, equals(RunResult.SUCCESS.exitCode));
      final lines = Util.splitLines(pr.stdout.trim()).toList();
      expect(lines, orderedEquals(['analyze_libs', 'analyze_test_libs', 'bench', 'dart2js', 'docs', 'hello', 'test']));
    });
  }

  /*
   * TODO: feature for bot_test
   *       wrap Process.run (or Process.start?)
   *       log process name + args + options?
   *       log stdout/stderr via logMessage
   *       do the expect dance to ensure completion without error, etc
   */
  static void _runHop(Iterable<String> args, Action1<ProcessResult> handler) {
    final list = args.toList();
    
    final hopRunnerPath = 'tool/hop_runner.dart';
    list.insertRange(0, 1, hopRunnerPath);
       
    final future = Process.run('dart', list)
        .then(handler);

    expect(future, finishes);
  }
}
