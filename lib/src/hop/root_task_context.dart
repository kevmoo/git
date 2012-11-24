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

  void _logCore(String message, [AnsiColor color = null, String taskName = null]) {
    requireArgumentNotNull(message, 'message');

    if(!_enableColor) {
      color = null;
    }

    var indent = '';
    var title = '';
    if(taskName != null) {
      title = "${taskName}: ";

      while(indent.length < title.length) {
        indent =  indent.concat(' ');
      }

      if(color != null) {
        title = color.wrap(title);
      }
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
}

class _SubTaskContext extends TaskContext {
  final String _name;
  final RootTaskContext _parent;

  _SubTaskContext(this._parent, this._name);

  void _logCore(String message, AnsiColor color) {
    _parent._logCore(message, color, _name);
  }
}
