library test_shared;

import 'async/_async_runner.dart' as async;
import 'bot/_bot_runner.dart' as bot;
import 'test/_test.dart' as test;

void register() {
  async.register();
  bot.register();
  test.register();
}
