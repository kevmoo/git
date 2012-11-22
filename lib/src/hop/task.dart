part of hop;

class Task {
  static final RegExp _validNameRegExp = new RegExp(r'^[a-z][a-z0-9_]*$');

  final name;
  final TaskDefinition _exec;

  factory Task.sync(String name, Func1<TaskContext, bool> exec) {
    final futureExec = (TaskContext state) => new Future.immediate(exec(state));

    return new Task.async(name, futureExec);
  }

  Task.async(this.name, this._exec) {
    requireArgumentNotNullOrEmpty(name, 'name');
    requireArgument(_validNameRegExp.hasMatch(name), 'name',
        '"$name" is not a valid name');
  }

  Future<bool> run(TaskContext state) {
    requireArgumentNotNull(state, 'state');
    return _exec(state);
  }
}
