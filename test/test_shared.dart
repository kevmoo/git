library test_shared;

import 'async/_async_runner.dart' as async;
import 'bot/_bot_runner.dart' as bot;

void register() {
  bot.register();
  async.register();
}
