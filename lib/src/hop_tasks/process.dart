part of hop_tasks;

Task createProcessTask(String command, {List<String> args: null, String description: ''}) {
  return new Task.async((ctx) => startProcess(ctx, command, args), description);
}

// TODO: document that start does an 'interactive' process
//       stderr and stdout are piped to context, etc
//       This aligns with io.Process.start
Future<bool> startProcess(TaskLogger ctx, String command,
    [List<String> args = null]) {

  requireArgumentNotNull(ctx, 'ctx');
  requireArgumentNotNull(command, 'command');
  if(args == null) {
    args = [];
  }

  ctx.fine("Starting process:");
  ctx.fine("$command ${Strings.join(args, ' ')}");
  return Process.start(command, args)
      .then((process) {
        return pipeProcess(process,
            stdOutWriter: ctx.fine,
            stdErrWriter: ctx.severe);
      })
      .then((int exitCode) {
        return exitCode == 0;
      });
}

Future<int> pipeProcess(Process process,
    {Action1<String> stdOutWriter, Action1<String> stdErrWriter}) {
  final completer = new Completer<int>();

  bool finished = false;

  if(stdOutWriter != null) {
    process.stdout.onData = () {
      final data = process.stdout.read();
      assert(data != null);
      final str = new String.fromCharCodes(data).trim();

      assert(!finished);
      stdOutWriter(str);
    };
  }

  if(stdErrWriter != null) {
    process.stderr.onData = () {
      final data = process.stderr.read();
      assert(data != null);
      final str = new String.fromCharCodes(data).trim();

      assert(!finished);
      stdErrWriter(str);
    };
  }

  process.onExit = (int exitCode){
    assert(!finished);
    finished = true;
    completer.complete(exitCode);
  };

  return completer.future;
}
