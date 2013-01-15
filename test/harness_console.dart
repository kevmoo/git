library harness_console;

import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'test_console.dart' as console;
import 'test_shared.dart' as shared;

main() {
  final config = new VMConfiguration();
  testCore(config);
}

void testCore(Configuration config) {
  configure(config);
  groupSep = ' - ';

  shared.register();
  console.register();
}
