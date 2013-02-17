part of hop;

Task getHelpTask() {
  return new Task.sync((_SubTaskContext ctx) {
    _printHelp(_sharedConfig, ctx._parent);
    return true;
  }, description: 'Print help information about available tasks');
}

void _printHelp(BaseConfig config, RootTaskContext ctx) {
  ctx.log('Welcome to HOP', AnsiColor.BLUE);
  ctx.log('');
  ctx.log('Tasks:', AnsiColor.BLUE);
  _printTaskTable(config, ctx);
  ctx.log('');

  final parser = _getParser(config);

  ctx.log(parser.getUsage());
}

void _printTaskTable(BaseConfig config, RootTaskContext ctx) {
  final columns = [
                   new ColumnDefinition('name', (name) => name),
                   new ColumnDefinition('description', (name) {
                     final task = config._getTask(name);
                     return task.description;
                   })
                   ];
  final rows = Console.getTable(config.taskNames, columns);
  for(final r in rows) {
    ctx.log(r);
  }
}
