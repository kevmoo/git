part of test_hop;

class IntegrationTests {
  static void run() {
    test('hop output is sorted', _testOutputSorted);
    test('bad hop command', _testBadHopCommand);
  }

  static Future _testBadHopCommand() {
    return _runHop(['bad_command_name'], {})
        .then((ProcessResult pr) {
          expect(pr.exitCode, equals(RunResult.BAD_USAGE.exitCode));
        });
  }

  static Future _testOutputSorted() {
    final env = {
                 'COMP_LINE': 'hop',
                 'COMP_POINT': '4'
    };

    return _runHop(['completion', '--', 'hop'], env)
        .then((ProcessResult pr) {
          expect(pr.exitCode, equals(RunResult.SUCCESS.exitCode));
          final lines = Util.splitLines(pr.stdout.trim()).toList();
          expect(lines, orderedEquals(['analyze_libs', 'analyze_test_libs', 'bench',
                                       'dart2js', 'docs', 'help', 'test',
                                       'update-html']));
    });
  }

  /*
   * TODO: feature for bot_test
   *       wrap Process.run (or Process.start?)
   *       log process name + args + options?
   *       log stdout/stderr via logMessage
   *       do the expect dance to ensure completion without error, etc
   */
  static Future<ProcessResult> _runHop(Iterable<String> args, Map<String, String> env) {
    final list = args.toList();

    final hopRunnerPath = 'tool/hop_runner.dart';
    list.insertRange(0, 1, hopRunnerPath);

    // assuming `dart` is in system path
    env['PATH'] = Platform.environment['PATH'];

    final options = new ProcessOptions()
      ..workingDirectory = new Directory.current().path
      ..environment = env;

    return Process.run('dart', list, options);
  }
}
