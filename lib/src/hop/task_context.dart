part of hop;

abstract class TaskContext extends DisposableImpl {

  void fine(String message) {
    _logCore(message, AnsiColor.BLUE);
  }

  void error(String message) {
    _logCore(message, AnsiColor.RED);
  }

  void info(String message) {
    _logCore(message, AnsiColor.BLUE);
  }

  void fail(String message) {
    throw new TaskFailError(message);
  }

  void _logCore(String message, AnsiColor color);
}
