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

  void fail(String message) {
    print(message);
    this.dispose();
    io.exit(1);
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
    task.run(ctx);
  }

  void _assertNotDisposed() {
    if(_isDisposed) {
      throw 'already disposed';
    }
  }
}
