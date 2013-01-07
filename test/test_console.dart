library test_console;

import 'hop/_hop.dart' as hop;
import 'hop_tasks/_hop_tasks.dart' as hop_tasks;
import 'bot_io_test/_bot_io_test.dart' as io_test;

void register() {
  hop.register();
  hop_tasks.register();
  io_test.register();
}
