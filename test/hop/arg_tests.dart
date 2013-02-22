part of test_hop;

void registerArgTests() {
  group('task arguments', () {
    test('simple args', () {

      final task = _makeSimpleTask();
      testTaskCompletion(task, (RunResult result) {
        expect(result, RunResult.SUCCESS);
      }, extraArgs: ['hello', 'args']);
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
