library harness_console;

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'test_console.dart' as console;
import 'test_shared.dart' as shared;
import 'test_dump_render_tree.dart' as drt;

main() {
  testCore(new VMConfiguration());
}

void testCore(Configuration config) {
  unittestConfiguration = config;
  groupSep = ' - ';

  shared.main();
  console.main();
  drt.main();
}
