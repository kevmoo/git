library hop;

// TODO: documentation for tasks
// TODO: formalize print/log model

import 'dart:io' as io;
import 'package:args/args.dart';
import 'package:bot/bot.dart';
import 'package:bot/io.dart';

part 'src/hop/runner.dart';
part 'src/hop/base_config.dart';
part 'src/hop/root_task_context.dart';
part 'src/hop/task.dart';
part 'src/hop/task_context.dart';
part 'src/hop/task_fail_error.dart';

final _sharedConfig = new BaseConfig();

typedef Future<bool> TaskDefinition(TaskContext ctx);

// See http://tldp.org/LDP/abs/html/exitcodes.html
// Accessed 2012-11-07

/// Regular unix success code
final EXIT_CODE_SUCCESS = 0;

/// C/C++ standard for bad usage. Hop was called incorrectly
final EXIT_CODE_USAGE = 64;

/// Task was was started and failed gracefully
final EXIT_CODE_TASK_FAIL = 80;

/// Task was was started, but threw an exception
final EXIT_CODE_TASK_EXCEPTION = 81;

/// Task misbehaved. Returned null, used TaskContext incorrectly, etc.
final EXIT_CODE_TASK_ERROR = 82;

void runHopCore() {
  _sharedConfig.freeze();
  final options = new Options();
  final runner = new Runner(_sharedConfig, options.arguments);
  final future = runner.run();

  future.onComplete((Future<int> f) {
    io.exit(f.value);
  });
}

void addTask(String name, Func1<TaskContext, bool> execFunc) {
  _sharedConfig.addTask(name, execFunc);
}

void addAsyncTask(String name, TaskDefinition execFuture) {
  _sharedConfig.addTaskAsync(name, execFuture);
}
