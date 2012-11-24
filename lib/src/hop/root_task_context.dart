part of hop;

class RootTaskContext {
  final bool _enableColor;

  RootTaskContext([bool enableColor=true]) : _enableColor = enableColor;

  TaskContext getSubContext(String name) {
    return new _SubTaskContext(this, name);
  }

  void log(String message, [AnsiColor color = null]) {
    if(!_enableColor) {
      color = null;
    }

    if(color != null) {
      message = color.wrap(message);
    }

    printCore(message);
  }

  void _logCore(_SubTaskContext subTask, String message, Level logLevel) {
    requireArgumentNotNull(message, 'message');

    final color = _getColor(logLevel);

    var indent = '';
    var title = '';
    title = "${subTask._name}: ";

    while(indent.length < title.length) {
      indent =  indent.concat(' ');
    }

    if(color != null) {
      title = color.wrap(title);
    }

    final lines = Util.splitLines(message);
    var first = true;
    for(final l in lines) {
      if(first) {
        first = false;
        printCore(title.concat(l));
      } else {
        printCore(indent.concat(l));
      }
    }
  }

  @protected
  void printCore(String message) {
    print(message);
  }

  AnsiColor _getColor(Level logLevel) {
    if(_enableColor) {
      return getLogColor(logLevel);
    } else {
      return null;
    }
  }

  static AnsiColor getLogColor(Level logLevel) {
    requireArgumentNotNull(logLevel, 'logLevel');
    if(logLevel.value > Level.INFO.value) {
      return AnsiColor.RED;
    } else {
      return AnsiColor.BLUE;
    }
  }
}

class _SubTaskContext extends TaskContext {
  final String _name;
  final RootTaskContext _parent;

  _SubTaskContext(this._parent, this._name);

  @override
  void _logCore(String message, Level logLevel) {
    _parent._logCore(this, message, logLevel);
  }
}
