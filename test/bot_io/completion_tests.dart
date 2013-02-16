part of test_bot_io;

void _registerCompletionTests() {
  group('completion', () {

    group('hello world sample', () {

      final parser = getHelloSampleParser();

      final allOptions = _getAllOptions(parser);

      final pairs = [
                     new _CompletionSet('empty input, just give all the commands',
                         [], parser.commands.keys.toList()
                     ),

                     new _CompletionSet('just a dash: should be empty. Vague', ['-'], []),

                     new _CompletionSet('double-dash, give all the options',
                         ['--'], allOptions
                     ),

                     new _CompletionSet('+flag complete --frie to --friendly',
                         ['--frie'], ['--friendly']
                     ),

                     new _CompletionSet('+flag complete full, final option to itself',
                         ['--friendly'], ['--friendly']
                     ),

                     new _CompletionSet("+command starting to complete 'help' - finish with help",
                         ['he'], ['help']
                     ),

                     new _CompletionSet("+command all of 'help' - finish with help",
                         ['help'], ['help']
                     ),

                     new _CompletionSet("too much", ['helpp'], []),

                     new _CompletionSet("wrong case", ['Help'], []),

                     new _CompletionSet("+command complete 'assistance'",
                         ['help', 'assist'], ['assistance']
                     ),

                     new _CompletionSet("show the yell flag for help",
                         ['help', '--'], ['--yell', '--no-yell']
                     ),

                     new _CompletionSet("+command help - complete '--n' to '--no-yell'",
                         ['help', '--n'], ['--no-yell']
                     ),

                     new _CompletionSet("+command help has sub-command - assistance", ['help', ''], ['assistance']),

                     new _CompletionSet("+flag don't offer --friendly twice",
                         ['--friendly', '--'], ['--loud', '--no-loud', '--salutation', '--middle-name']
                     ),

                     new _CompletionSet("+abbr+flag+no-multiple don't offer --friendly twice, even if the first one is the abbreviation",
                         ['-f', '--'], ['--loud', '--no-loud', '--salutation', '--middle-name']
                     ),

                     new _CompletionSet("+flag+no-multiple don't complete a second --friendly",
                         ['--friendly', '--friend'], []
                     ),

                     new _CompletionSet("+abbr+flag+no-multiple don't complete a second --friendly, even if the first one is the abbreviation",
                         ['-f', '--friend'], []
                     ),

                     new _CompletionSet("+flag+negatable+no-multiple don't complete the opposite of a negatable - 1",
                         ['--no-loud', '--'], ['--friendly', '--salutation', '--middle-name']
                     ),

                     new _CompletionSet("+flag+negatable+no-multiple don't complete the opposite of a negatable - 2",
                         ['--loud', '--'], ['--friendly', '--salutation', '--middle-name']
                     ),


                     new _CompletionSet("+option+no-allowed+multiple okay to have multiple 'multiple' options",
                         ['--middle-name', 'Robert', '--'], allOptions
                     ),

                     new _CompletionSet("+option+no-allowed+multiple okay to have multiple 'multiple' options, even abbreviations",
                         ['-m', 'Robert', '--'], allOptions
                     ),

                     new _CompletionSet("+option+no-allowed don't suggest if an option is waiting for a value",
                         ['--middle-name', ''], []
                     ),

                     new _CompletionSet("+abbr+option+no-allowed don't suggest if an option is waiting for a value",
                         ['-m', ''], []
                     ),

                     new _CompletionSet("+option+allowed suggest completions for an option with allowed defined",
                         ['--salutation', ''], ['Mr', 'Mrs', 'Dr', 'Ms']
                     ),

                     new _CompletionSet("+option+allowed finish a completion for an option (added via abbr) with allowed defined",
                         ['-s', 'M'], ['Mr', 'Mrs', 'Ms']
                     ),

                     new _CompletionSet("+abbr+option+allowed don't finish a bad completion",
                         ['-s', 'W'], []
                     ),

                     new _CompletionSet("+abbr+option+allowed confirm a completion",
                         ['-s', 'Dr'], ['Dr']
                     ),

                     new _CompletionSet("+abbr+option+allowed back to command completion after a completed option",
                         ['-s', 'Dr', ''], ['help']
                     ),

                     new _CompletionSet("+abbr+option+allowed back to option completion after a completed option",
                         ['-s', 'Dr', '--'], ['--friendly', '--loud', '--no-loud', '--middle-name']
                     ),

                     ];

      test('compPoint not at the end', () {
        final compLine = 'help';
        final args = ['help'];

        _testCompletionPair(parser, args, ['help'], compLine, compLine.length);
        _testCompletionPair(parser, args, [], compLine, compLine.length - 1);
      });

      pairs.forEach((_CompletionSet p) {
        final compLine = p.args.join(' ');
        final compPoint = compLine.length;
        final args = p.args.toList();

        if(!args.isEmpty && args.last == '') {
          args.removeLast();
        }

        test(p.description, () {
          _testCompletionPair(parser, args, p.suggestions, compLine, compPoint);
        });
      });
    });
  });
}

List<String> _getAllOptions(ArgParser parser) {
  final list = new List<String>();

  parser.options.forEach((k, v) {
    expect(k, v.name);

    list.add(_optionIze(k));

    if(v.negatable) {
      list.add(_optionIze('no-$k'));
    }

  });

  return list;
}

String _optionIze(String input) => '--$input';

void _testCompletionPair(ArgParser parser, List<String> args, List<String> suggestions, String compLine, int compPoint) {

  final completions = getArgsCompletions(parser, args, compLine, compPoint);

  logMessage('completed with $completions');

  expect(completions, unorderedEquals(suggestions), reason: 'for args: ${args} expected: ${suggestions} but got: $completions');
}

void _doLog(LogRecord record) {
  final msg = '${record.loggerName}\t${record.time}\t${record.message}';
  logMessage(msg);
}

class _CompletionSet {
  final String description;
  final List<String> args;
  final List<String> suggestions;

  _CompletionSet(this.description, this.args, this.suggestions);
}
