part of hop;

abstract class TaskContext extends DisposableImpl {

  void fine(String message) {
    _printCore(message, AnsiColor.BLUE);
  }

  void error(String message) {
    _printCore(message, AnsiColor.RED);
  }

  void success(String message) {
    _printCore(message, AnsiColor.GREEN);
  }

  void _printCore(String message, AnsiColor color);
}

class _SubTaskContext extends TaskContext {
  final String _name;
  final RootTaskContext _parent;

  _SubTaskContext(this._parent, this._name);

  void _printCore(String message, AnsiColor color) {
    _parent.printCore(message, color, _name);
  }
}

class RootTaskContext {
  final bool _enableColor;

  RootTaskContext([bool enableColor=true]) : _enableColor = enableColor;

  TaskContext getSubContext(String name) {
    return new _SubTaskContext(this, name);
  }

  void print(String message) {
    printCore(message);
  }

  @protected
  void printCore(String message, [AnsiColor color = null, String taskName = null]) {
    if(!_enableColor) {
      color = null;
    }
    if(taskName != null) {
      prnt("${taskName}: ", color);
    }
    prntLine(message);
  }
}
