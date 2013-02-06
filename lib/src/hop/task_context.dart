part of hop;

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
