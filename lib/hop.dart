library hop;

import 'dart:async';
import 'dart:io' as io;
import 'package:args/args.dart';
import 'package:bot/bot.dart';
import 'package:bot/bot_io.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

part 'src/hop/console_context.dart';
part 'src/hop/help.dart';
part 'src/hop/hop_config.dart';
part 'src/hop/root_task_context.dart';
part 'src/hop/run_result.dart';
part 'src/hop/runner.dart';
part 'src/hop/task.dart';
part 'src/hop/task_argument.dart';
part 'src/hop/task_context.dart';
part 'src/hop/task_fail_error.dart';
part 'src/hop/task_logger.dart';

final _sharedConfig = new HopConfig();

final _libLogger = new Logger('hop');

typedef Future<bool> TaskDefinition(TaskContext ctx);

/**
 * [runHopCore] calls [io.exit] which terminates the application.
 *
 * [runHopCore] should be the last method you call in an application.
 */
void runHopCore() {
  _sharedConfig.freeze();
  Runner.runCore(_sharedConfig);
}

void addTask(String name, Task task) {
  _sharedConfig.addTask(name, task);
}

void addSyncTask(String name, Func1<TaskContext, bool> execFunc) {
  _sharedConfig.addSync(name, execFunc);
}

void addAsyncTask(String name, TaskDefinition execFuture) {
  _sharedConfig.addAsync(name, execFuture);
}

const String _colorFlag = 'color';
const String _prefixFlag = 'prefix';
const String _logLevelOption = 'log-level';

ArgParser _getParser(HopConfig config) {
  assert(config.isFrozen);

  final parser = new ArgParser();

  for(final taskName in config.taskNames) {
    _initParserForTask(parser, taskName, config._getTask(taskName));
  }

  parser.addFlag(_colorFlag, defaultsTo: true,
      help: 'Specifies if shell output can have color.');

  parser.addFlag(_prefixFlag, defaultsTo: true,
      help: 'Specifies if shell output is prefixed by the task name.');

  final logLevelAllowed = _getLogLevels()
      .map((Level l) => l.name.toLowerCase())
      .toList();

  final String defaultLogLevel = logLevelAllowed.singleMatching((v) => v == config.logLevel.name.toLowerCase());

  parser.addOption(_logLevelOption, allowed: logLevelAllowed,
      defaultsTo: defaultLogLevel,
      help: 'The log level at which task output is printed to the shell');


  return parser;
}

List<Level> _getLogLevels() {
  return [Level.ALL, Level.CONFIG, Level.FINE, Level.FINER, Level.FINEST,
          Level.INFO, Level.OFF, Level.SEVERE, Level.SHOUT]
    ..sort((a, b) => a.value.compareTo(b.value));
}

void _initParserForTask(ArgParser parser, String taskName, Task task) {
  final subParser = parser.addCommand(taskName);
  task.configureArgParser(subParser);
}
