library test_console;

import 'hop/_hop.dart' as hop;
import 'hop_tasks/_hop_tasks.dart' as hop_tasks;
import 'bot_io/_bot_io.dart' as bot_io;

void register() {
  hop.register();
  hop_tasks.register();
  bot_io.register();
}
