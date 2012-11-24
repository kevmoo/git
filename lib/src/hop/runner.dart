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

  Future<int> run() {
    _state.requireFrozen();

    final ctx = getContext();

    switch(_args.rest.length) {
      case 0:
        _printHelp(ctx);
        return new Future.immediate(EXIT_CODE_SUCCESS);
      case 1:
        final taskName = _args.rest[0];
        if(_state.hasTask(taskName)) {
          var subCtx = ctx.getSubContext(taskName);
          return _runTask(subCtx, taskName);
        } else if(taskName == RAW_TASK_LIST_CMD) {
          _printRawTasks(ctx);
          return new Future.immediate(EXIT_CODE_SUCCESS);
        }
        else {
          ctx.log('No task named "$taskName".');
          return new Future.immediate(EXIT_CODE_USAGE);
        }

        // DARTBUG: http://code.google.com/p/dart/issues/detail?id=6563
        // all paths have a return, this break shouldn't be needed
        break;
      default:
        ctx.log('Too many arguments');
        ctx.log('--options must come before task name');
        return new Future.immediate(EXIT_CODE_USAGE);
    }
  }

  @protected
  RootTaskContext getContext() {
    final bool colorEnabled = _args['color'];
    return new RootTaskContext(colorEnabled);
  }

  Future<int> _runTask(TaskContext context, String taskName) {
    final task = _state._getTask(taskName);
    assert(task != null);

    final completer = new Completer<int>();

    final future = task.run(context);

    future.onComplete((f) {
      if(f.hasValue) {
        if(f.value == true) {
          context.success('Finished');
          completer.complete(EXIT_CODE_SUCCESS);
        } else {
          context.error('Failed');
          if(f.value == false) {
            completer.complete(EXIT_CODE_TASK_FAIL);
          } else {
            context.error('${f.value} returned from task');
            context.error('Return value from task must be true or false');
            completer.complete(EXIT_CODE_TASK_ERROR);
          }
        }
      } else {
        // special-case on exception type that represents null returned
        // from the provided future.
        // Hopefully will not be needed with fix of
        // DARTBUG: http://code.google.com/p/dart/issues/detail?id=6405
        if(f.exception == Task._nullFutureResultEx) {
          context.error('The provided task returned null instead of a future');
          completer.complete(EXIT_CODE_TASK_ERROR);
        } else {
          // has as exception, need to test this
          context.error('Exception thrown by task');
          context.error(f.exception.toString());
          context.error(f.stackTrace.toString());
          completer.complete(EXIT_CODE_TASK_EXCEPTION);
        }
      }
      context.dispose();
    });

    return completer.future;
  }

  void _printHelp(RootTaskContext ctx) {
    ctx.log('Welcome to HOP');
    ctx.log('');
    ctx.log('Tasks:');
    _printRawTasks(ctx);
    ctx.log('');
    ctx.log(_parser.getUsage());
  }

  void _printRawTasks(RootTaskContext ctx) {
    for(final t in _state.taskNames) {
      ctx.log(t);
    }
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
