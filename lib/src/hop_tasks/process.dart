part of hop_tasks;

Task createProcessTask(String command, {List<String> args: null, String description: ''}) {
  return new Task.async((ctx) => startProcess(ctx, command, args), description);
}

// TODO: document that start does an 'interactive' process
//       stderr and stdout are piped to context, etc
//       This aligns with io.Process.start
Future<bool> startProcess(TaskContext ctx,
    String command,
    [List<String> args = null]) {
  requireArgumentNotNull(ctx, 'ctx');
  requireArgumentNotNull(command, 'command');
  if(args == null) {
    args = [];
  }

  ctx.fine("Starting process:");
  ctx.fine("$command ${Strings.join(args, ' ')}");
  final processFuture = Process.start(command, args);
  return processFuture.then((process) {
    return _startProcess(process, ctx);
  });
}

Future<bool> _startProcess(Process process, TaskContext ctx) {
  final completer = new Completer<bool>();

  process.stdout.onData = () {
    final data = process.stdout.read();
    assert(data != null);
    final str = new String.fromCharCodes(data).trim();
    ctx.fine(str);
  };

  process.stderr.onData = () {
    final data = process.stderr.read();
    assert(data != null);
    final str = new String.fromCharCodes(data).trim();
    ctx.severe(str);
  };

  process.onExit = (int exitCode){
    completer.complete(exitCode == RunResult.SUCCESS.exitCode);
  };

  return completer.future;
}
