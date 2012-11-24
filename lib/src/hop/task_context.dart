part of hop;

abstract class TaskContext extends DisposableImpl {

  void fine(String message) {
    _logCore(message, AnsiColor.BLUE);
  }

  void error(String message) {
    _logCore(message, AnsiColor.RED);
  }

  void success(String message) {
    _logCore(message, AnsiColor.GREEN);
  }

  void _logCore(String message, AnsiColor color);
}

class _SubTaskContext extends TaskContext {
  final String _name;
  final RootTaskContext _parent;

  _SubTaskContext(this._parent, this._name);

  void _logCore(String message, AnsiColor color) {
    _parent.logCore(message, color, _name);
  }
}

class RootTaskContext {
  final bool _enableColor;

  RootTaskContext([bool enableColor=true]) : _enableColor = enableColor;

  TaskContext getSubContext(String name) {
    return new _SubTaskContext(this, name);
  }

  void log(String message) {
    logCore(message);
  }

  @protected
  void logCore(String message, [AnsiColor color = null, String taskName = null]) {
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
        print(title.concat(l));
      } else {
        print(indent.concat(l));
      }
    }
  }
}
