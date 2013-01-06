library test_console;

import 'hop/_hop.dart';
import 'hop_tasks/_hop_tasks.dart';
import 'test/_test.dart' as test;

void registerTests() {
  registerHopTests();
  registerHopTasksTests();
  test.register();
}
