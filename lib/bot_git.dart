library bot_git;

import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart' as log;
import 'package:bot/bot.dart';
import 'package:bot/bot_io.dart';

part 'src/bot_git/git.dart';
part 'src/bot_git/git_dir.dart';

final _libLogger = new log.Logger('bot_git');

/*
 * TODO: since this is in two places now (and hop_tasks), it might be nice to generalize
 */
_log(Object value, [log.Level level=log.Level.INFO]) {
  String val;
  try {
    val = value.toString();
  } catch (ex, stack) {
    val = Error.safeToString(value);
  }

  _libLogger.log(level, val);
}
