part of hop;

typedef void ArgParserConfigure(ArgParser);

class Task {
  static const _nullFutureResultEx = 'null-future-result-silly';

  final TaskDefinition _exec;
  final String description;
  final ArgParserConfigure _argParserConfig;

  factory Task.sync(Func1<TaskContext, bool> exec, {String description, ArgParserConfigure config}) {
    final futureExec = (TaskContext ctx) => new Future.delayed(0, () => exec(ctx));

    return new Task.async(futureExec, description: description, config: config);
  }

  Task.async(this._exec, {String description, ArgParserConfigure config}) :
    this.description = (description == null) ? '' : description,
    this._argParserConfig = config {
    requireArgumentNotNull(_exec, '_exec');
  }

  void configureArgParser(ArgParser parser) {
    if(_argParserConfig != null) {
      _argParserConfig(parser);
    }
  }

  Future<bool> run(TaskContext ctx) {
    requireArgumentNotNull(ctx, 'ctx');

    Future<bool> f;

    try {
      f = _exec(ctx);
    } catch(error, stackTrace) {
      return new Future.immediateError(error, stackTrace);
    }
    if(f == null) {
      return new Future.immediateError(_nullFutureResultEx);
    } else {
      return f;
    }
  }

  @override
  String toString() => "Task: $description";
}
