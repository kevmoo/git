part of hop;

class Task {
  static final RegExp _validNameRegExp = new RegExp(r'^[a-z][a-z0-9_]*$');
  static final _nullFutureResultEx = 'null-future-result-silly';

  final name;
  final TaskDefinition _exec;

  factory Task.sync(String name, Func1<TaskContext, bool> exec) {
    final futureExec = (TaskContext ctx) => new Future.immediate(exec(ctx));

    return new Task.async(name, futureExec);
  }

  Task.async(this.name, this._exec) {
    requireArgumentNotNullOrEmpty(name, 'name');
    requireArgument(_validNameRegExp.hasMatch(name), 'name',
        '"$name" is not a valid name');
  }

  Future<bool> run(TaskContext ctx) {
    requireArgumentNotNull(ctx, 'ctx');

    // DARTBUG: http://code.google.com/p/dart/issues/detail?id=6405
    // Chaning an immediate task here to ensure we capture a call stack on
    // exception.
    return (new Future.immediate(ctx))
        .chain((s) {
          final f = _exec(s);

          if(f == null) {
            throw _nullFutureResultEx;
          }

          return f;
        });
  }
}
