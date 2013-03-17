part of test_hop;

void registerArgTests() {
  group('task arguments', () {
    test('simple args', () {

      final task = _makeSimpleTask();
      return runTaskInTestRunner(task, extraArgs: ['hello', 'args'])
          .then((RunResult result) {
            expect(result, RunResult.SUCCESS);
          });
    });
  });
}


Task _makeSimpleTask() {
  return new Task.sync((ctx) {
    final args = ctx.arguments.rest;
    expect(args.length, 2);
    expect(args[0], 'hello');
    expect(args[1], 'args');
    return true;
  });
}
