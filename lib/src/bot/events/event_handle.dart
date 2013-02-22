part of bot;

class EventHandle<T> extends async.StreamController<T> implements Disposable {
  bool _disposed = false;

  EventHandle({void onSubscriptionStateChange()}) :
    super.broadcast(onSubscriptionStateChange: onSubscriptionStateChange);

  void dispose(){
    if(_disposed) {
      throw const DisposedError();
    }
    // Set disposed_ to true first, in case during the chain of disposal this
    // gets disposed recursively.
    this._disposed = true;
    super.close();
  }

  bool get isDisposed => _disposed;
}
