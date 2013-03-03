part of hop;

const String _hopCmdName = 'hop';

/**
 * Help is such a core concept, it has been added directly to the call to
 * [runHopCore] with the named argument [helpTaskName].
 *
 * See [runHopCore] for more details.
 */
@deprecated
Task getHelpTask() {
  return _getHelpTask();
}

Task _getHelpTask() {
  return new Task.sync((TaskContext ctx) {
    final args = ctx.arguments;

    if(args.command != null) {
      _printHelpForTask(_sharedConfig, args.command.name);
      return true;
    } else {

      _printHelp(_sharedConfig);

      if(!args.rest.isEmpty) {
        ctx.severe('Not sure how to give help for: ${args.rest}');
        return false;
      }

      return true;
    }
  },
  description: 'Print help information about available tasks',
  config: (parser) => _helpParserConfig(_sharedConfig, parser),
  extendedArgs: [new TaskArgument('task-name')]);
}

void _printHelpForTask(HopConfig config, String taskName) {
  final task = config._getTask(taskName);
  assert(task != null);

  final usage = task.getUsage();

  _printUsage(config, showOptions: !usage.isEmpty, taskName: taskName, extendedArgsUsage: task.getExtendedArgsUsage());
  config.doPrint(_indent(task.description));
  config.doPrint('');

  if(!usage.isEmpty) {
    config.doPrint('${taskName} options:');
    config.doPrint(_indent(task.getUsage()));
    config.doPrint('');
  }

  _printHopArgsHelp(config);
}

void _helpParserConfig(HopConfig config, ArgParser parser) {
  config.requireFrozen();

  for(final taskName in config.taskNames) {
    parser.addCommand(taskName);
  }
}

void _printHelp(HopConfig config) {
  config.requireFrozen();
  _printUsage(config);
  config.doPrint('Tasks:');
  _printTaskTable(config);

  config.doPrint('');
  _printHopArgsHelp(config);

  final helpName = config._helpTaskName;
  if(helpName != null) {
    config.doPrint("See '$_hopCmdName $helpName <task>' for more information on a specific command.");
  }
}

void _printUsage(HopConfig config, {bool showOptions: true, String taskName: '<task>', String extendedArgsUsage: '[--] [<task-args>]'}) {
  final taskOptions = showOptions ? '[<${taskName}-options>] ' : '';

  config.doPrint('usage: $_hopCmdName [<hop-options>] $taskName $taskOptions$extendedArgsUsage'.trim());
  config.doPrint('');
}

void _printHopArgsHelp(HopConfig config) {
  final parser = _getParser(config);

  config.doPrint('Hop options:');
  config.doPrint(_indent(parser.getUsage()));
  config.doPrint('');
}

String _indent(String input) {
  return Util.splitLines(input)
      .map((String line) => '  '.concat(line))
      .join(('\n'));
}

void _printTaskTable(HopConfig config) {
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
    config.doPrint('  '.concat(r));
  }
}
