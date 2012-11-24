part of hop;

class Task {
  static final _nullFutureResultEx = 'null-future-result-silly';

  final TaskDefinition _exec;
  final String description;

  factory Task.sync(Func1<TaskContext, bool> exec, [String description]) {
    final futureExec = (TaskContext ctx) => new Future.immediate(exec(ctx));

    return new Task.async(futureExec, description);
  }

  Task.async(this._exec, [this.description]) {
    requireArgumentNotNull(_exec, '_exec');
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

  @override
  String toString() => "Task: $description";
}
