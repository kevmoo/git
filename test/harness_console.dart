library harness_console;

import 'package:unittest/unittest.dart';

import 'parse_test.dart' as parse;
import 'git_dir_test.dart' as git_dir;

void main() {
  groupSep = ' - ';

  group('GitDir', git_dir.main);
  group('parse', parse.main);
}
