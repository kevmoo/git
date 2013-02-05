part of hop;

abstract class TaskLogger {

  // level 500
  void fine(String message) {
    log(message, Level.FINE);
  }

  // level 800
  void info(String message) {
    log(message, Level.INFO);
  }

  // level 900
  void warning(String message) {
    log(message, Level.WARNING);
  }

  // level 1000
  void severe(String message) {
    log(message, Level.SEVERE);
  }

  void log(String message, Level logLevel);
}

abstract class TaskContext extends TaskLogger implements Disposable {
  List<String> get arguments;

  void log(String message, Level logLevel);

  TaskLogger getSubLogger(String name);

  /**
   * Terminates the current [Task] with a [TaskFailError] including the provided
   * [message].
   */
  void fail(String message) {
    throw new TaskFailError(message);
  }
}
