library test_shared;

import 'async/_async_runner.dart';
import 'bot/_bot_runner.dart';

void registerTests() {
  runBotTests();
  runAsyncTests();
}
