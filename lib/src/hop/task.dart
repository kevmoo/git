part of hop;

typedef void ArgParserConfigure(ArgParser);

class Task {
  static const _nullFutureResultEx = 'null-future-result-silly';

  final TaskDefinition _exec;
  final String description;
  final ArgParserConfigure _argParserConfig;
  final ReadOnlyCollection<TaskArgument> _extendedArgs;

  factory Task.sync(Func1<TaskContext, bool> exec,
      {String description, ArgParserConfigure config, List<TaskArgument> extendedArgs}) {
    final futureExec = (TaskContext ctx) => new Future.of(() => exec(ctx));

    return new Task.async(futureExec,
        description: description, config: config, extendedArgs: extendedArgs);
  }

  Task.async(this._exec,
      {String description, ArgParserConfigure config, List<TaskArgument> extendedArgs}) :
    this.description = (description == null) ? '' : description,
    this._argParserConfig = config,
    this._extendedArgs = extendedArgs == null ?
        const ReadOnlyCollection<TaskArgument>.empty() :
          new ReadOnlyCollection<TaskArgument>(extendedArgs) {
    requireArgumentNotNull(_exec, '_exec');
    TaskArgument.validateArgs(_extendedArgs);
  }

  void configureArgParser(ArgParser parser) {
    if(_argParserConfig != null) {
      _argParserConfig(parser);
    }
  }

  String getUsage() {
    final parser = new ArgParser();
    configureArgParser(parser);
    return parser.getUsage();
  }

  String getExtendedArgsUsage() {
    return _extendedArgs.map((TaskArgument arg) {
      var value = '<${arg.name}>';
      if(arg.multiple) {
        value = value + '...';
      }
      if(!arg.required) {
        value = '[$value]';
      }
      return value;
    }).join(' ');
  }

  Future<bool> run(TaskContext ctx) {
    requireArgumentNotNull(ctx, 'ctx');
    return new Future<bool>.of(() => _exec(ctx));
  }

  @override
  String toString() => "Task: $description";
}
