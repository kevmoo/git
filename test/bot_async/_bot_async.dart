library test_bot_async;

import 'dart:isolate';
import 'dart:async';
import 'package:bot/bot.dart';
import 'package:bot/bot_async.dart';
import 'package:bot/bot_test.dart';
import 'package:unittest/unittest.dart';

part 'test_send_port_value.dart';
part 'test_future_value_result.dart';

void register() {
  group('bot_async', (){
    TestSendPortValue.run();
    TestFutureValueResult.run();
  });
}
