library hop;

import 'dart:async';
import 'dart:io' as io;
import 'package:args/args.dart';
import 'package:bot/bot.dart';
import 'package:bot/bot_io.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:pathos/path.dart' as path;

part 'src/hop/console_context.dart';
part 'src/hop/help.dart';
part 'src/hop/task_registry.dart';
part 'src/hop/root_task_context.dart';
part 'src/hop/run_result.dart';
part 'src/hop/runner.dart';
part 'src/hop/task.dart';
part 'src/hop/task_argument.dart';
part 'src/hop/task_context.dart';
part 'src/hop/task_fail_error.dart';
part 'src/hop/task_logger.dart';

final _sharedConfig = new TaskRegistry();

final _libLogger = new Logger('hop');

typedef Future<bool> TaskDefinition(TaskContext ctx);

/**
 * Designed to enable features in __Hop__. Should be the last method called in
 * `tool/hop_runner.dart`.
 *
 * [runHop] calls [io.exit] which terminates the application.
 *
 * If [paranoid] is `true`, [runHop] will verify the running script is
 * `tool/hop_runner.dart` relative to the working directory. If not, an
 * exception is thrown.
 *
 * If [helpTaskName], defines (surprise!) the name of the help task. If `null`
 * no help task is added. If [helpTaskName] conflicts with an already defined
 * task, an exception is thrown.
 */
void runHop({
  bool paranoid: true,
  String helpTaskName: 'help'
  }) {
  if(paranoid) {
    _paranoidHopCheck();
  }
  Runner._runShell(_sharedConfig, helpTaskName);
}

/**
 * Use [runHop] instead.
 */
@deprecated
void runHopCore() {
  runHop(paranoid: false, helpTaskName: null);
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

void _paranoidHopCheck() {
  var runningScript = new io.Options().script;
  runningScript = path.absolute(runningScript);
  runningScript = path.normalize(runningScript);

  final expectedPath = path.join(path.current, 'tool', 'hop_runner.dart');
  require(runningScript == expectedPath,
      'Running script should be at "$expectedPath" but was at "$runningScript"');
}

const String _colorFlag = 'color';
const String _prefixFlag = 'prefix';
const String _logLevelOption = 'log-level';

ArgParser _getParser(TaskRegistry config, Level defaultLogLevel) {
  assert(config.isFrozen);

  final parser = new ArgParser();

  for(final taskName in config.taskNames) {
    _initParserForTask(parser, taskName, config._getTask(taskName));
  }

  parser.addFlag(_colorFlag, defaultsTo: Console.supportsColor,
      help: 'Specifies if shell output can have color.');

  parser.addFlag(_prefixFlag, defaultsTo: true,
      help: 'Specifies if shell output is prefixed by the task name.');

  final logLevelAllowed = _getLogLevels()
      .map((Level l) => l.name.toLowerCase())
      .toList();

  assert(logLevelAllowed.contains(defaultLogLevel.name.toLowerCase()));

  parser.addOption(_logLevelOption, allowed: logLevelAllowed,
      defaultsTo: defaultLogLevel.name.toLowerCase(),
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
