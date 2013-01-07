library test_shared;

import 'bot/_bot.dart' as bot;
import 'bot_async/_bot_async.dart' as bot_async;
import 'bot_test/_bot_test.dart' as bot_test;

void register() {
  bot.register();
  bot_async.register();
  bot_test.register();
}
