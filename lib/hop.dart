library hop;

import 'dart:async';
import 'dart:io' as io;
import 'package:args/args.dart';
import 'package:bot/bot.dart';
import 'package:bot/bot_io.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

part 'src/hop/runner.dart';
part 'src/hop/base_config.dart';
part 'src/hop/console_context.dart';
part 'src/hop/root_task_context.dart';
part 'src/hop/run_result.dart';
part 'src/hop/task.dart';
part 'src/hop/task_context.dart';
part 'src/hop/task_fail_error.dart';
part 'src/hop/task_logger.dart';

final _sharedConfig = new BaseConfig();

typedef Future<bool> TaskDefinition(TaskContext ctx);

/**
 * [runHopCore] should be the last method you call in an application.
 *
 * NOTE: [runHopCore] calls [io.exit] which terminates the application.
 */
void runHopCore() {
  _sharedConfig.freeze();
  final options = new Options();

  ArgResults args;
  try {
    args = Runner.parseArgs(options.arguments);
  } on FormatException catch(ex, stack) {
    print("Bad argument");
    print(ex.message);
    print(Runner.getUsage());

    io.exit(RunResult.BAD_USAGE.exitCode);
  }

  final runner = new Runner(_sharedConfig, args);
  final future = runner.run();

  future.then((RunResult rr) {
    io.exit(rr.exitCode);
  });
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
