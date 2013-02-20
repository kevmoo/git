library bot_async;

import 'dart:async';
import 'dart:isolate';
import 'package:bot/bot.dart';

part 'src/bot_async/future_value.dart';
part 'src/bot_async/future_value_result.dart';
part 'src/bot_async/send_port_value.dart';
part 'src/bot_async/send_value_port.dart';

/**
 * Designed to allow methods to support a variety of "delayed" inputs.
 *
 * If the [input] is a [Future], [getDelayedResult] waits for a result.
 *
 * If the [input] is a [Function], [getDelayedResult] evaluates it for a result.
 *
 * The result in both cases is provided back to [getDelayedResult] evaluated again.
 *
 * If the original [input]--or once a recursive [input]--is neigther a [Future]
 * nor a [Function] that value is returned wrapped in a [Future].
 */
Future<dynamic> getDelayedResult(dynamic input) {
  if(input is Function) {
    input = new Future.of(input);
  }

  if(input is Future) {
    return input.then((value) => getDelayedResult(value));
  } else {
    return new Future.immediate(input);
  }
}
