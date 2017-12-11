library harness_console;

import 'package:scheduled_test/scheduled_test.dart';

import 'git_dir_test.dart' as git_dir;
import 'parse_test.dart' as parse;

void main() {
  group('GitDir', git_dir.main);
  group('parse', parse.main);
}
