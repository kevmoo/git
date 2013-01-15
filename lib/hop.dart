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
part 'src/hop/root_task_context.dart';
part 'src/hop/run_result.dart';
part 'src/hop/task.dart';
part 'src/hop/task_context.dart';
part 'src/hop/task_fail_error.dart';

final _sharedConfig = new BaseConfig();

typedef Future<bool> TaskDefinition(TaskContext ctx);

void runHopCore() {
  _sharedConfig.freeze();
  final options = new Options();
  final runner = new Runner(_sharedConfig, options.arguments);
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
