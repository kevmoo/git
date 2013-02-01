library test_console;

import 'hop/_hop.dart' as hop;
import 'hop_tasks/_hop_tasks.dart' as hop_tasks;
import 'bot_io/_bot_io.dart' as bot_io;
import 'bot_git/_bot_git.dart' as bot_git;

void main() {
  hop.main();
  hop_tasks.main();
  bot_io.main();
  bot_git.main();
}
