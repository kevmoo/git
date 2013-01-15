library test_hop;

import 'dart:async';
import 'dart:io';
import 'package:bot/bot.dart';
import 'package:bot/bot_io.dart';
import 'package:bot/hop.dart';
import 'package:meta/meta.dart';
import 'package:unittest/unittest.dart';

part 'sync_tests.dart';
part 'task_list_tests.dart';
part 'integration_tests.dart';
part 'async_tests.dart';
part 'test_runner.dart';

void register() {
  group('hop', () {
    group('async tasks', AsyncTests.run);
    group('sync tasks', SyncTests.run);
    group('task list', TaskListTests.run);
    group('integration', IntegrationTests.run);
  });
}
