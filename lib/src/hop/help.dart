part of hop;

const String _hopCmdName = 'hop';

class _HelpArgs {
  final TaskRegistry registry;
  ArgParser parser;
  Printer printer = print;

  _HelpArgs(this.registry);
}

Task _getHelpTask(_HelpArgs helpArgs) {
  return new Task.sync((TaskContext ctx) {
    final args = ctx.arguments;

    if(args.command != null) {
      _printHelpForTask(helpArgs.printer, helpArgs.registry, args.command.name, helpArgs.parser);
      return true;
    } else {
      _printHelp(helpArgs.printer, helpArgs.registry, helpArgs.parser);

      if(!args.rest.isEmpty) {
        ctx.severe('Not sure how to give help for: ${args.rest}');
        return false;
      }

      return true;
    }
  },
  description: 'Print help information about available tasks',
  config: (parser) => _helpParserConfig(helpArgs.registry, parser),
  extendedArgs: [new TaskArgument('task-name')]);
}

void _helpParserConfig(TaskRegistry config, ArgParser parser) {
  config._requireFrozen();

  for(final taskName in config.taskNames) {
    parser.addCommand(taskName);
  }
}

void _printHelpForTask(Printer printer, TaskRegistry config, String taskName, ArgParser hopArgParser) {
  final task = config._getTask(taskName);
  assert(task != null);

  final usage = task.getUsage();

  printer(_getUsage(showOptions: !usage.isEmpty, taskName: taskName, extendedArgsUsage: task.getExtendedArgsUsage()));
  printer('');
  if(!task.description.isEmpty) {
    printer(_indent(task.description));
    printer('');
  }

  if(!usage.isEmpty) {
    printer(_getTitle('${taskName} options'));
    printer(_indent(usage));
    printer('');
  }

  _printHopArgsHelp(printer, hopArgParser);
}

void _printHelp(Printer printer, TaskRegistry registry, ArgParser parser) {

  printer(_getUsage());
  printer('');
  printer(_getTitle('Tasks'));
  _printTaskTable(printer, registry);

  printer('');
  _printHopArgsHelp(printer, parser);

  final helpName = registry._helpTaskName;
  if(helpName != null) {
    printer("See '$_hopCmdName $helpName <task>' for more information on a specific command.");
  }
}

String _getUsage({bool showOptions: true, String taskName: '<task>', String extendedArgsUsage: '[--] [<task-args>]'}) {
  final optionsString = (taskName == '<task>') ? 'task' : taskName;

  final taskOptions = showOptions ? '[<$optionsString-options>] ' : '';

  return 'usage: $_hopCmdName [<hop-options>] $taskName $taskOptions$extendedArgsUsage'.trim();
}

void _printHopArgsHelp(Printer printer, ArgParser hopArgParser) {
  printer(_getTitle('Hop options'));
  printer(_indent(hopArgParser.getUsage()));
  printer('');
}

String _indent(String input) {
  return Util.splitLines(input)
      .map((String line) => '  ' + line)
      .join(('\n'));
}

ShellString _getTitle(String input) {
  assert(input != null);
  assert(input.trim() == input);
  assert(!input.endsWith(':'));
  return new ShellString.withAlt(input.toUpperCase(), AnsiColor.BOLD, '$input:');
}

void _printTaskTable(Printer printer, TaskRegistry config) {
  config._requireFrozen();
  final columns = [
                   new ColumnDefinition('name', (name) => '  ' + name),
                   new ColumnDefinition('description', (name) {
                     final task = config._getTask(name);
                     return task.description;
                   })
                   ];
  final rows = Console.getTable(config.taskNames, columns);
  for(final r in rows) {
    printer('  ' + r);
  }
}
