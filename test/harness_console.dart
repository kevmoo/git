library harness_console;

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';

import 'bot_git/_bot_git.dart' as bot_git;

void main() {
  testCore(new VMConfiguration());
}

void testCore(Configuration config) {
  unittestConfiguration = config;
  groupSep = ' - ';

  bot_git.main();
}
