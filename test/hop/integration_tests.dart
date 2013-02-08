part of test_hop;

class IntegrationTests {
  static final hopPath = 'bin/hop';

  static void run() {
    test('hop output is sorted', _testOutputSorted);
    test('bad hop command', _testBadHopCommand);
  }

  static void _testBadHopCommand() {
    final future = Process.run(hopPath, ['bad_command_name'])
        .then((ProcessResult pr) {
          expect(pr.exitCode, equals(RunResult.BAD_USAGE.exitCode));
        });

    expect(future, completes);
  }

  static void _testOutputSorted() {
    final future = Process.run(hopPath, [Runner.RAW_TASK_LIST_CMD])
        .then((ProcessResult pr) {
          expect(pr.exitCode, equals(RunResult.SUCCESS.exitCode));
          final lines = pr.stdout.trim().split('\n');
          expect(lines, orderedEquals(['analyze_libs', 'analyze_test_libs', 'bench', 'dart2js', 'docs', 'hello', 'test']));
        });

    expect(future, completes);
  }
}
