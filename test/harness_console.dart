library harness_console;

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'test_console.dart' as console;
import 'test_shared.dart' as shared;
import 'test_dump_render_tree.dart' as drt;

main() {
  final config = new VMConfiguration();
  testCore(config);
}

void testCore(Configuration config) {
  configure(config);
  groupSep = ' - ';

  shared.main();
  console.main();
  drt.main();
}
