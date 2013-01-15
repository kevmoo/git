part of hop;

class Task {
  static const _nullFutureResultEx = 'null-future-result-silly';

  final TaskDefinition _exec;
  final String description;

  factory Task.sync(Func1<TaskContext, bool> exec, [String description]) {
    final futureExec = (TaskContext ctx) => new Future.delayed(0, () => exec(ctx));

    return new Task.async(futureExec, description);
  }

  Task.async(this._exec, [String desc = '']) :
    this.description = (desc == null) ? '' : desc {
    requireArgumentNotNull(_exec, '_exec');
  }

  Future<bool> run(TaskContext ctx) {
    requireArgumentNotNull(ctx, 'ctx');
    final f = _exec(ctx);
    if(f == null) {
      return new Future.immediateError(_nullFutureResultEx);
    } else {
      return f;
    }
  }

  @override
  String toString() => "Task: $description";
}
