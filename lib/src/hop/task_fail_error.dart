part of hop;

/**
 * Going away soon. If you'd like to notify `hop` of a failure, call
 * [TaskContext.fail]
 */
@deprecated
class TaskFailError extends _TaskFailError {
  const TaskFailError(String message) : super(message);
}

class _TaskFailError extends Error {
  final String message;

  const _TaskFailError(this.message);

  String toString() => "TaskFailError: $message";
}
