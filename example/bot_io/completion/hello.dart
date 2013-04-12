#!/usr/bin/env dart --checked

library bot_io.completion_sample;

import 'dart:io';
import 'package:bot_io/bot_io.dart';
import 'package:args/args.dart';
import 'package:logging/logging.dart' as logging;

import '../../../test/bot_io/completion_tests_args.dart';

void main() {
  /*
   * It's nice to see what the completer is doing, but printing out debug
   * strings during completion isn't...smart
   *
   * Uncomment the below line to set up logging. You'll see output from
   * the bot_io completion logic
   *
   * It's put into `hello.dart.log`
   *
   * enableScriptLogListener();
   *
   */

  final argParser = getHelloSampleParser();

  ArgResults argResult;

  try {
    argResult = tryArgsCompletion(argParser);
  } on FormatException catch (ex, stack) {
    // TODO: print color?
    print(ex.message);
    print(argParser.getUsage());
    /// 64 - C/C++ standard for bad usage.
    exit(64);
  }


  if(argResult.command != null) {
    final subCommand = argResult.command;
    final subCommandParser = argParser.commands[subCommand.name];

    if(subCommand.name == 'help') {
      // so the help command was run.

      // there are args here, too. Super fun.
      if(subCommand.command != null) {
        // we have a sub-sub command. Fun!
        // let's get the sub-sub command parser

        final subSubCommand = subCommand.command;
        if(subSubCommand.name == 'assistance') {
          print("Yes, we have help for help...just calling it assistance");
          // let's print sub help. Very crazy.
          print(subCommandParser.getUsage());
          exit(0);
        } else {
          throw 'no clue what that subCammand is: ${subSubCommand.name}';
        }
      }
      // one sub-sub command: help. Really.

      var usage = argParser.getUsage();

      if(subCommand['yell']) {
        usage = usage.toUpperCase();
        print("I'm yelling, so the case of the available commands will be off");
      }

      print(usage);
      exit(0);
    }
  }

  final name = argResult.rest.isEmpty ? 'World' : argResult.rest.first;

  final greeting = argResult['friendly'] ? 'Hiya' : 'Hello';

  final String salutationVal = argResult['salutation'];
  final salutation = salutationVal == null ? '' : '$salutationVal ';

  var message = '$greeting, ${salutation}${name}';

  if(argResult['loud']) {
    message = message.toUpperCase();
  }

  print(message);
}
