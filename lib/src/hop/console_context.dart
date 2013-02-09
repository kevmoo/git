part of hop;

class ConsoleContext extends TaskContext {
  final ReadOnlyCollection<String> arguments;
  bool _isDisposed = false;

  ConsoleContext.raw(this.arguments);

  factory ConsoleContext() {
    var args = new ReadOnlyCollection(new Options().arguments);
    return new ConsoleContext.raw(args);
  }

  void log(Level logLevel, String message) {
    _assertNotDisposed();
    print(message);
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
    final ctx = new ConsoleContext();

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
