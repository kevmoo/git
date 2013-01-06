library test_hop_tasks;

import 'dart:io';
import 'package:bot/bot.dart';
import 'package:bot/hop.dart';
import 'package:bot/hop_tasks.dart';
import 'package:bot/test.dart';
import 'package:unittest/unittest.dart';
import '../hop/_hop.dart';

part 'process_tests.dart';

void register() {
  group('hop_tasks', () {
    ProcessTests.run();
  });
}
