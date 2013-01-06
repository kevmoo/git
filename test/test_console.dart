library test_console;

import 'hop/_hop.dart' as hop;
import 'hop_tasks/_hop_tasks.dart' as hop_tasks;
import 'test/_test.dart' as test;

void register() {
  hop.register();
  hop_tasks.register();
  test.register();
}
