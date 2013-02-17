part of hop;

class Runner {
  static const String _colorParam = 'color';
  final ArgParser _parser;
  ArgResults _args;
  final BaseConfig _state;

  Runner(BaseConfig config, Iterable<String> args) :
    this._state = config,
    this._parser = getParser(config) {
    _args = _parser.parse(args);
    _state.requireFrozen();
  }

  Runner._internal(this._state, this._parser, this._args);

  Future<RunResult> run() {
    assert(_state.isFrozen);

    final ctx = getContext();

    if(_args.command != null) {
      // we're executing a command
      final subCommandArgResults = _args.command;
      final taskName = subCommandArgResults.name;

      var subCtx = ctx.getSubContext(taskName, subCommandArgResults);

      final task = _state._getTask(taskName);
      return runTask(subCtx, task)
          .then((RunResult result) => _logExitCode(ctx, result))
          .whenComplete(() => subCtx.dispose());

    } else if(_args.rest.length == 0) {
      _printHelp(ctx);
      return new Future.immediate(RunResult.SUCCESS);
    } else {
      final taskName = _args.rest[0];
      ctx.log('No task named "$taskName".');
      return new Future.immediate(RunResult.BAD_USAGE);
    }
  }

  @protected
  RootTaskContext getContext() {
    final bool colorEnabled = _args[_colorParam];
    return new RootTaskContext(colorEnabled);
  }

  /**
   * Parses provided command line args
   * Handles command completion with the correct paramaters
   * etc...
   */
  static void runCore(BaseConfig config) {
    final options = new Options();

    final parser = getParser(config);

    ArgResults args;
    try {
      args = tryArgsCompletion(parser);
    } on FormatException catch(ex, stack) {
      print("There was an error parsing the provided arguments");
      print(ex.message);
      print(parser.getUsage());

      _libLogger.severe(ex.message);
      _libLogger.severe(Error.safeToString(stack));

      io.exit(RunResult.BAD_USAGE.exitCode);
    }

    final runner = new Runner._internal(config, parser, args);
    final future = runner.run();

    future.then((RunResult rr) {
      _libLogger.info('Exit with $rr');
      io.exit(rr.exitCode);
    });
  }

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

    return task.run(context)
        .then((bool didComplete) {
          if(didComplete == null) {
            context.severe('${didComplete} returned from task');
            context.severe('Return value from task must be true or false');
            return RunResult.ERROR;
          } else if(didComplete) {
            return RunResult.SUCCESS;
          } else {
            context.severe('Failed');
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
        });
  }

  void _printHelp(RootTaskContext ctx) {
    ctx.log('Welcome to HOP', AnsiColor.BLUE);
    ctx.log('');
    ctx.log('Tasks:', AnsiColor.BLUE);
    _printTaskTable(ctx);
    ctx.log('');
    ctx.log(getUsage());
  }

  void _printTaskTable(RootTaskContext ctx) {
    final columns = [
                     new ColumnDefinition('name', (name) => name),
                     new ColumnDefinition('description', (name) {
                       final task = _state._getTask(name);
                       return task.description;
                     })
                     ];
    final rows = Console.getTable(_state.taskNames, columns);
    for(final r in rows) {
      ctx.log(r);
    }
  }

  String getUsage() => _parser.getUsage();

  static RunResult _logExitCode(RootTaskContext ctx, RunResult result) {
    if(!result.success) {
      ctx.log('Task did not complete - ${result.name} (${result.exitCode})', AnsiColor.RED);
    }
    return result;
  }

  static ArgParser getParser(BaseConfig config) {
    assert(config.isFrozen);

    final parser = new ArgParser();

    for(final taskName in config.taskNames) {
      _initParserForTask(parser, taskName, config._getTask(taskName));
    }

    parser.addFlag(_colorParam, defaultsTo: true);

    // TODO: put help in a const
    // parser.addFlag('help', abbr: '?', help: 'print help text', negatable: false);

    // TODO: other global flag ideas
    // verbose - show a lot of output
    // trace - show stack dump on fail?

    return parser;
  }

  static void _initParserForTask(ArgParser parser, String taskName, Task task) {
    final subParser = parser.addCommand(taskName);

    task.configureArgParser(subParser);
  }
}
