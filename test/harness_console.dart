library harness_console;

import 'package:unittest/unittest.dart';

import 'bot_git/_bot_git.dart' as bot_git;

void main() {
  groupSep = ' - ';

  bot_git.main();
}
