library hop_tasks;

import 'dart:async';
import 'dart:io';
import 'dart:collection';
import 'package:args/args.dart';
import 'package:bot/bot.dart';
import 'package:bot/bot_git.dart';
import 'package:bot/bot_io.dart';
import 'package:bot/hop.dart';
import 'package:unittest/unittest.dart' as unittest;

part 'src/hop_tasks/unit_test.dart';
part 'src/hop_tasks/process.dart';
part 'src/hop_tasks/dart2js.dart';
part 'src/hop_tasks/git_tasks.dart';
part 'src/hop_tasks/dartdoc.dart';
part 'src/hop_tasks/dart_analyzer.dart';

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
