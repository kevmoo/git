library hop_tasks;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:pathos/path.dart' as path;
import 'package:unittest/unittest.dart' as unittest;

import 'package:bot/bot.dart';
import 'package:bot/bot_async.dart';
import 'package:bot/bot_git.dart';
import 'package:bot/bot_io.dart';
import 'package:bot/hop.dart';

part 'src/hop_tasks/bench_task.dart';
part 'src/hop_tasks/dart_analyzer.dart';
part 'src/hop_tasks/dart2js.dart';
part 'src/hop_tasks/dartdoc.dart';
part 'src/hop_tasks/git_tasks.dart';
part 'src/hop_tasks/process.dart';
part 'src/hop_tasks/unit_test.dart';

ArgResults _helpfulParseArgs(TaskContext ctx, ArgParser parser, List<String> args) {
  try {
    return parser.parse(args);
  } on FormatException catch(ex, stack) {
    ctx.severe('There was a problem parsing the provided arguments');
    ctx.info('Usage:');
    ctx.info(parser.getUsage());
    ctx.fail(ex.message);
  }
}

String _getPlatformBin(String binName) {
  if(Platform.operatingSystem == 'windows') {
    return '${binName}.bat';
  } else {
    return binName;
  }
}
