part of hop;

class TaskFailError extends Error {
  final String message;

  const TaskFailError(this.message);

  String toString() => "TaskFailError: $message";
}
