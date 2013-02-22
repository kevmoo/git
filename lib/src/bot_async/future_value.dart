part of bot_async;

abstract class FutureValue<TInput, TOutput> {
  FutureValue() :
    _outputChangedHandle = new EventHandle<EventArgs>(),
    _inputChangedHandle = new EventHandle<EventArgs>(),
    _errorHandle = new EventHandle<Object>();

  TInput get input => _input;

  void set input(TInput value) {
    _input = value;
    if(_future == null) {
      _startFuture();
    } else {
      _pending = true;
    }
    _inputChangedHandle.add(EventArgs.empty);
  }

  TOutput get output => _output;

  Stream<EventArgs> get outputChanged => _outputChangedHandle.stream;
  Stream<EventArgs> get inputChanged => _inputChangedHandle.stream;

  // TODO: roll this into outputChanged stream w/ errors? Hmm...
  Stream get error => _errorHandle.stream;

  Future<TOutput> getFuture(TInput value);

  void _startFuture() {
    assert(_future == null);
    assert(!_pending);
    _future = getFuture(_input);
    _future.then(_futureCompleted, onError: _futureException);
  }

  bool _futureException(Object exception) {
    assert(_future != null);
    _future = null;
    _errorHandle.add(exception);
    _cleanup();
    return true;
  }

  void _futureCompleted(TOutput value) {
    assert(_future != null);
    _future = null;
    _output = value;
    _outputChangedHandle.add(EventArgs.empty);
    _cleanup();
  }

  void _cleanup() {
    if(_pending) {
      _pending = false;
      _startFuture();
    }
  }

  TInput _input;
  Future<TOutput> _future;
  TOutput _output;
  bool _pending = false;

  final EventHandle<EventArgs> _outputChangedHandle;
  final EventHandle<EventArgs> _inputChangedHandle;
  final EventHandle<Object> _errorHandle;
}
