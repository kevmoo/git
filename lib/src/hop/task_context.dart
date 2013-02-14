part of hop;

abstract class TaskContext extends TaskLogger implements Disposable {
  ArgResults get arguments;

  TaskLogger getSubLogger(String name);

  /**
   * Terminates the current [Task] with a [TaskFailError] including the provided
   * [message].
   */
  void fail(String message) {
    throw new _TaskFailError(message);
  }
}
