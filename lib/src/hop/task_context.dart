part of hop;

abstract class TaskContext extends TaskLogger implements Disposable {
  ArgResults get arguments;

  TaskLogger getSubLogger(String name);

  /**
   * Terminates the current [Task] with a failure, explained by [message].
   */
  void fail(String message) {
    throw new _TaskFailError(message);
  }
}
