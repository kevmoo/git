part of hop;

class Runner {
  final ArgParser _parser;
  ArgResults _args;
  final HopConfig _state;

  Runner(HopConfig config, Iterable<String> args) :
    this._state = config,
    this._parser = _getParser(config) {
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
      _printHelp(_state);
      return new Future.immediate(RunResult.SUCCESS);
    } else {
      final taskName = _args.rest[0];
      ctx.log('No task named "$taskName".');
      return new Future.immediate(RunResult.BAD_USAGE);
    }
  }

  @protected
  RootTaskContext getContext() {
    final bool colorEnabled = _args[_colorFlag];
    final bool preFixEnabled = _args[_prefixFlag];
    final String logLevelOption = _args[_logLevelOption];

    final Level logLevel = _getLogLevels()
        .singleMatching((Level l) => l.name.toLowerCase() == logLevelOption);

    return new RootTaskContext(colorEnabled: colorEnabled,
        prefixEnabled: preFixEnabled, minLogLevel: logLevel);
  }

  /**
   * Parses provided command line args
   * Handles command completion with the correct paramaters
   *
   * [runCore] calls [io.exit] which terminates the application.
   *
   * [runCore] should be the last method you call in an application.
   */
  static void runCore(HopConfig config) {
    final options = new Options();

    final parser = _getParser(config);

    ArgResults args;
    try {
      args = tryArgsCompletion(parser);
    } on FormatException catch(ex, stack) {
      config.doPrint("There was an error parsing the provided arguments");
      config.doPrint(ex.message);
      config.doPrint('');
      _printHelp(config);

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

  static RunResult _logExitCode(RootTaskContext ctx, RunResult result) {
    if(!result.success) {
      ctx.log('Task did not complete - ${result.name} (${result.exitCode})', AnsiColor.RED);
    }
    return result;
  }
}
