part of hop;

class Runner {
  static const String RAW_TASK_LIST_CMD = 'print_raw_task_list';
  static final ArgParser _parser = _getParser();
  final ArgResults _args;
  final BaseConfig _state;

  Runner(this._state, List<String> arguments) :
    // TODO: better error or output for invalid arguments
    _args = _parser.parse(arguments) {
    _state.requireFrozen();
  }

  Future<RunResult> run() {
    _state.requireFrozen();

    final ctx = getContext();

    switch(_args.rest.length) {
      case 0:
        _printHelp(ctx);
        return new Future.immediate(RunResult.SUCCESS);
      case 1:
        final taskName = _args.rest[0];
        if(_state.hasTask(taskName)) {
          var subCtx = ctx.getSubContext(taskName);
          return _runTask(subCtx, taskName)
              .then((RunResult result) => _logExitCode(ctx, result));
        } else if(taskName == RAW_TASK_LIST_CMD) {
          _printRawTasks(ctx);
          return new Future.immediate(RunResult.SUCCESS);
        }
        else {
          ctx.log('No task named "$taskName".');
          return new Future.immediate(RunResult.BAD_USAGE);
        }

        // DARTBUG: http://code.google.com/p/dart/issues/detail?id=6563
        // all paths have a return, this break shouldn't be needed
        break;
      default:
        ctx.log('Too many arguments');
        ctx.log('--options must come before task name');
        return new Future.immediate(RunResult.BAD_USAGE);
    }
  }

  @protected
  RootTaskContext getContext() {
    final bool colorEnabled = _args['color'];
    return new RootTaskContext(colorEnabled);
  }

  Future<RunResult> _runTask(TaskContext context, String taskName) {
    final task = _state._getTask(taskName);
    assert(task != null);

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
        } else if(asyncError.error is TaskFailError) {
          final TaskFailError e = asyncError.error;
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
      }).whenComplete(() => context.dispose());
  }

  void _printHelp(RootTaskContext ctx) {
    ctx.log('Welcome to HOP', AnsiColor.BLUE);
    ctx.log('');
    ctx.log('Tasks:', AnsiColor.BLUE);
    _printTaskTable(ctx);
    ctx.log('');
    ctx.log(_parser.getUsage());
  }

  void _printRawTasks(RootTaskContext ctx) {
    for(final t in _state.taskNames) {
      ctx.log(t);
    }
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

  static RunResult _logExitCode(RootTaskContext ctx, RunResult result) {
    if(result.success) {
      ctx.log('Finished', AnsiColor.GREEN);
    } else {
      ctx.log('Failed', AnsiColor.RED);
    }
    return result;
  }

  static ArgParser _getParser() {
    final parser = new ArgParser();

    parser.addFlag('color', defaultsTo: true);


    // TODO: put help in a const
    // parser.addFlag('help', abbr: '?', help: 'print help text', negatable: false);

    // TODO: other global flag ideas
    // verbose - show a lot of output
    // trace - show stack dump on fail?

    return parser;
  }
}
