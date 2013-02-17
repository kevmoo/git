part of hop;

Task getHelpTask() {
  return new Task.sync((_SubTaskContext ctx) {
    final args = ctx.arguments;

    if(args.command != null) {
      _printHelpForTask(_sharedConfig, ctx._parent, args.command.name);
      return true;
    }

    _printHelp(_sharedConfig, ctx._parent);

    if(!args.rest.isEmpty) {
      ctx.severe('Not sure how to give help for: ${args.rest}');
      return false;
    }

    return true;
  },
  description: 'Print help information about available tasks',
  config: (parser) => _helpParserConfig(_sharedConfig, parser));
}

void _printHelpForTask(BaseConfig config, RootTaskContext ctx, String taskName) {
  final task = config._getTask(taskName);
  assert(task != null);

  ctx.log(taskName, AnsiColor.BLUE);
  ctx.log(task.description);
  ctx.log('');

  final usage = task.getUsage();
  if(!usage.isEmpty) {
    ctx.log(task.getUsage());
    ctx.log('');
  }
}

void _helpParserConfig(BaseConfig config, ArgParser parser) {
  config.requireFrozen();

  for(final taskName in config.taskNames) {
    parser.addCommand(taskName);
  }
}

void _printHelp(BaseConfig config, RootTaskContext ctx) {
  config.requireFrozen();
  ctx.log('Welcome to HOP', AnsiColor.BLUE);
  ctx.log('');
  ctx.log('Tasks:', AnsiColor.BLUE);
  _printTaskTable(config, ctx);
  ctx.log('');

  final parser = _getParser(config);

  ctx.log(parser.getUsage());
}

void _printTaskTable(BaseConfig config, RootTaskContext ctx) {
  config.requireFrozen();
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
