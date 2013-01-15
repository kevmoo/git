part of test_hop;

class IntegrationTests {
  static final hopPath = 'bin/hop';

  static void run() {
    test('hop output is sorted', _testOutputSorted);
    test('bad hop command', _testBadHopCommand);
  }

  static void _testBadHopCommand() {
    final onComplete = expectAsync1((ProcessResult pr) {
      expect(pr.exitCode, equals(RunResult.BAD_USAGE.exitCode));
    });

    final f = Process.run(hopPath, ['bad_command_name']);
    f.then(onComplete);
  }

  static void _testOutputSorted() {
    final onComplete = expectAsync1((ProcessResult pr) {
      expect(pr.exitCode, equals(RunResult.SUCCESS.exitCode));
      final lines = pr.stdout.trim().split('\n');
      expect(lines, orderedEquals(['dart2js', 'docs', 'hello', 'test']));
    });

    final f = Process.run(hopPath, [Runner.RAW_TASK_LIST_CMD]);
    f.then(onComplete);
  }
}
