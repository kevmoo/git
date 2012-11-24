part of hop;

abstract class TaskContext extends DisposableImpl {

  void fine(String message) {
    _logCore(message, Level.FINE);
  }

  void severe(String message) {
    _logCore(message, Level.SEVERE);
  }

  void info(String message) {
    _logCore(message, Level.INFO);
  }

  void fail(String message) {
    throw new TaskFailError(message);
  }

  @protected
  void _logCore(String message, Level logLevel);
}
