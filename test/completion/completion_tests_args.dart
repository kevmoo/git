library test_bot_io.completion_args;

import 'package:args/args.dart';

ArgParser getHelloSampleParser() {
  final parser = new ArgParser();

  // not negatable
  parser.addFlag('friendly', abbr: 'f', negatable: false, help: 'should I be friendly?');

  // negatable
  parser.addFlag('loud', help: 'should I be loud in how I say hello?');

  // option with a fixed set of options
  parser.addOption('salutation', abbr: 's', help: 'What salutation should I use?',
    allowed: ['Mr', 'Mrs', 'Dr', 'Ms']);

  // allow multiple
  parser.addOption('middle-name', abbr: 'm', help: 'Do you have one or more middle names?', allowMultiple: true);

  final helpParser = parser.addCommand('help');
  helpParser.addFlag('yell', abbr: 'h', help: 'Happy to yell at you :-)', negatable: true, defaultsTo: false);

  final helpHelpParser = helpParser.addCommand('assistance');

  return parser;

}
