part of hop;

const String _hopCmdName = 'hop';

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
  ctx.log('usage: $_hopCmdName [<hop-args>] <task> [<task-args>]');
  ctx.log('');
  ctx.log('Tasks:', AnsiColor.BLUE);
  _printTaskTable(config, ctx);

  final parser = _getParser(config);

  ctx.log('');
  ctx.log('Hop args:', AnsiColor.BLUE);
  ctx.log(_indent(parser.getUsage()));

  ctx.log('');
  ctx.log("See '$_hopCmdName <task>' for more information on a specific command.");
}

String _indent(String input) {
  return Util.splitLines(input)
      .map((String line) => '  '.concat(line))
      .join(('\n'));
}

void _printTaskTable(BaseConfig config, RootTaskContext ctx) {
  config.requireFrozen();
  final columns = [
                   new ColumnDefinition('name', (name) => '  '.concat(name)),
                   new ColumnDefinition('description', (name) {
                     final task = config._getTask(name);
                     return task.description;
                   })
                   ];
  final rows = Console.getTable(config.taskNames, columns);
  for(final r in rows) {
    ctx.log('  '.concat(r));
  }
}
