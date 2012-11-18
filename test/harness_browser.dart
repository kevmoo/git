library harness_browser;

import 'package:unittest/html_enhanced_config.dart';
import 'package:unittest/unittest.dart';
import 'test_browser.dart' as browser;
import 'test_shared.dart' as shared;

main() {
  groupSep = ' - ';
  useHtmlEnhancedConfiguration();

  shared.registerTests();
  browser.registerTests();
}
