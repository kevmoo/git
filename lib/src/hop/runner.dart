part of hop;

class HopConfig {
  final TaskRegistry taskRegistry;
  final ArgParser parser;
  final ArgResults args;
  final Printer _printer;

  /**
   * This constructor exists for testing Hop.
   *
   * If you're using it in another context, you might be doing something wrong.
   */
  factory HopConfig(TaskRegistry registry, List<String> args, Printer printer) {
    registry._freeze();

    final parser = _getParser(registry, Level.INFO);
    final argResults = parser.parse(args);

    return new HopConfig._internal(registry, parser, argResults, printer);
  }

  HopConfig._internal(this.taskRegistry, this.parser, this.args, this._printer) {
    taskRegistry._freeze();
    requireArgumentNotNull(args, 'args');
    requireArgumentNotNull(parser, 'parser');
    requireArgumentNotNull(_printer, '_printer');
  }

  void doPrint(Object value) => _printer(value);
}

class Runner {
  /**
   * Runs a [Task] with the specificed [TaskContext].
   *
   * [runTask] handles a number of error cases, logs appropriate messages
   * to [context] and returns a corresponding [RunResult] when completed.
   */
  static Future<RunResult> runTask(TaskContext context, Task task) {
    requireArgumentNotNull(context, 'context');
    requireArgumentNotNull(task, 'task');
    requireArgument(!context.isDisposed, 'context', 'cannot be disposed');

    final start = new DateTime.now();
    context.finest('Started at $start');

    return task.run(context)
        .then((bool didComplete) {
          if(didComplete == null) {
            context.severe('${didComplete} returned from task');
            context.severe('Return value from task must be true or false');
            return RunResult.ERROR;
          } else if(didComplete) {
            return RunResult.SUCCESS;
          } else {
            return RunResult.FAIL;
          }
        })
        .catchError((AsyncError asyncError) {
          if(asyncError.error == Task._nullFutureResultEx) {
            context.severe('The provided task returned null instead of a future');
            return RunResult.ERROR;
          } else if(asyncError.error is _TaskFailError) {
            final _TaskFailError e = asyncError.error;
            context.severe(e.message);
            return RunResult.FAIL;
          }
          else {
            // has as exception, need to test this
            context.severe('Exception thrown by task');
            context.severe(asyncError.error.toString());
            if(asyncError.stackTrace != null) {
              context.severe(asyncError.stackTrace.toString());
            }
            return RunResult.EXCEPTION;
          }
        })
        .whenComplete(() {
          final end = new DateTime.now();
          context.finest('Finished at $end');
          final duration = end.difference(start);
          context.finer('Run time: $duration');
        });
  }

  /**
   * [run] exists primarily for testing [Task] implementations.
   *
   * If you want to use Hop in an app, see [runHop].
   *
   * If you want to run a specific [Task] in isolation, see [runTask].
   */
  static Future<RunResult> run(HopConfig config) {
    requireArgumentNotNull(config, 'config');

    final ctx = _getContext(config);

    if(config.args.command != null) {
      // we're executing a command
      final subCommandArgResults = config.args.command;
      final taskName = subCommandArgResults.name;

      var subCtx = ctx.getSubContext(taskName, subCommandArgResults);

      final task = config.taskRegistry._getTask(taskName);
      return runTask(subCtx, task)
          .then((RunResult result) => _logExitCode(ctx, result))
          .whenComplete(() {
            subCtx.dispose();
          });

    } else if(config.args.rest.length == 0) {
      _printHelp(config.doPrint, config.taskRegistry, config.parser);
      return new Future.immediate(RunResult.SUCCESS);
    } else {
      final taskName = config.args.rest[0];
      ctx.log('No task named "$taskName".');
      return new Future.immediate(RunResult.BAD_USAGE);
    }
  }

  static RootTaskContext _getContext(HopConfig config) {
    final bool preFixEnabled = config.args[_prefixFlag];
    final String logLevelOption = config.args[_logLevelOption];

    final Level logLevel = _getLogLevels()
        .singleWhere((Level l) => l.name.toLowerCase() == logLevelOption);

    return new RootTaskContext(config.doPrint,
        prefixEnabled: preFixEnabled, minLogLevel: logLevel);
  }

  static void _runShell(TaskRegistry registry, String helpTaskName) {

    // a bit ugly
    // the help task needs the parser and a print method
    // we can't get those until the help task is created
    // so we use this dummy object which the help task closure holds onto
    // then we update the values before the help task could ever be called
    // sorry. Weird, I know
    final helpArgs = new _HelpArgs(registry);

    // wire up help task
    if(helpTaskName != null) {
      registry.addTask(helpTaskName, _getHelpTask(helpArgs));
    }

    registry._freeze();

    final parser = _getParser(registry, Level.INFO);
    helpArgs.parser = parser;

    ArgResults args;
    try {
      args = tryArgsCompletion(parser);
    } on FormatException catch(ex, stack) {
      // TODO: try to guess if --no-color was passed in here?
      print("There was an error parsing the provided arguments");
      print(ex.message);
      print('');
      _printHelp(print, registry, parser);

      _libLogger.severe(ex.message);
      _libLogger.severe(Error.safeToString(stack));

      io.exit(RunResult.BAD_USAGE.exitCode);
    }

    final bool useColor = args[_colorFlag];
    final Printer printer = useColor ? _colorPrinter : print;

    final config = new HopConfig._internal(registry, parser, args, printer);
    helpArgs.printer = config.doPrint;

    final future = Runner.run(config);

    future.then((RunResult rr) {
      _libLogger.info('Exit with $rr');
      io.exit(rr.exitCode);
    });
  }

  static void _colorPrinter(Object value) {
    if(value is ShellString) {
      value = value.format(true);
    }
    print(value);
  }

  static RunResult _logExitCode(RootTaskContext ctx, RunResult result) {
    if(!result.success) {
      final msg = 'Task did not complete - ${result.name} (${result.exitCode})';
      ctx.log(new ShellString.withColor(msg, AnsiColor.RED));
    }
    return result;
  }
}
