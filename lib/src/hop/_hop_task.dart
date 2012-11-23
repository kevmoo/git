part of hop;

class _HopTask {
  static final RegExp _validNameRegExp = new RegExp(r'^[a-z][a-z0-9_]*$');

  final name;
  final AsyncTask _exec;

  factory _HopTask.sync(String name, Func1<TaskContext, bool> exec) {
    final futureExec = (TaskContext state) => new Future.immediate(exec(state));

    return new _HopTask.async(name, futureExec);
  }

  _HopTask.async(this.name, this._exec) {
    requireArgumentNotNullOrEmpty(name, 'name');
    requireArgument(_validNameRegExp.hasMatch(name), 'name',
        '"$name" is not a valid name');
  }

  Future<bool> run(TaskContext state) {
    requireArgumentNotNull(state, 'state');
    return _exec(state);
  }
}
