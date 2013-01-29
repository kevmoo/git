library test_hop_tasks;

import 'dart:io';
import 'package:bot/bot.dart';
import 'package:bot/bot_test.dart';
import 'package:bot/hop.dart';
import 'package:bot/hop_tasks.dart';
import 'package:unittest/unittest.dart';
import '../hop/_hop.dart';

part 'process_tests.dart';

void register() {
  group('hop_tasks', () {
    ProcessTests.run();
  });
}

void _testSimpleAsyncTask(Task task, Action1<RunResult> completeHandler) {
  final name = 'task_name';
  final tasks = new BaseConfig();
  tasks.addTask(name, task);
  tasks.freeze();

  final runner = new TestRunner(tasks, [name]);
  final future = runner.run();
  expect(future, isNotNull);

  expectFutureComplete(future, completeHandler);
}
