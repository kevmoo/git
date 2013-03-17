part of hop;

class ConsoleContext extends TaskContext {
  final Task task;
  final ArgResults arguments;
  bool _isDisposed = false;

  ConsoleContext.raw(this.arguments, this.task);

  void log(Level logLevel, String message) {
    _assertNotDisposed();
    if(logLevel >= Level.FINE) {
      print(message);
    }
  }

  /**
   * At the moment [getSubLogger] returns [this].
   */
  TaskLogger getSubLogger(String name) {
    // TODO: should actualy support sub loggers
    return this;
  }

  bool get isDisposed => _isDisposed;

  void dispose() {
    _assertNotDisposed();
    _isDisposed = true;
  }

  static void runTaskAsProcess(Task task) {
    assert(task != null);

    final parser = new ArgParser();
    task.configureArgParser(parser);

    ArgResults args;
    try {
      args = tryArgsCompletion(parser);
    } on FormatException catch (ex, stack) {
      print('There was a problem parsing the provided arguments.');
      print(ex.message);
      print(parser.getUsage());
      io.exit(RunResult.BAD_USAGE.exitCode);
    }
    final ctx = new ConsoleContext.raw(args, task);

    Runner.runTask(ctx, task)
      .then((RunResult rr) {
        ctx.dispose();
        io.exit(rr.exitCode);
      });
  }

  void _assertNotDisposed() {
    if(_isDisposed) {
      throw 'already disposed';
    }
  }
}
