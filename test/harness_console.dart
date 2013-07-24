library harness_console;

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';

import 'bot_io/_bot_io.dart' as bot_io;
import 'bot_git/_bot_git.dart' as bot_git;
import 'completion/_completion.dart' as completion;

main() {
  testCore(new VMConfiguration());
}

void testCore(Configuration config) {
  unittestConfiguration = config;
  groupSep = ' - ';

  bot_io.main();
  bot_git.main();
  completion.main();
}
