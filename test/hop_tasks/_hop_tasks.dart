library test_hop_tasks;

import 'dart:io';
import 'package:bot/tasks.dart';
import 'package:unittest/unittest.dart';
import '../hop/_hop.dart';

part 'process_tests.dart';

void registerHopTasksTests() {
  ProcessTests.run();
}
