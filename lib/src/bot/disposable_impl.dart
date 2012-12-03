part of bot;

class DisposableImpl implements Disposable {
  bool _disposed = false;

  void dispose(){
    validateNotDisposed();
    // Set disposed_ to true first, in case during the chain of disposal this
    // gets disposed recursively.
    this._disposed = true;
    this.disposeInternal();
  }

  void validateNotDisposed() {
    if(_disposed) {
      throw const DisposedError();
    }
  }

  bool get isDisposed => _disposed;

  @protected
  /**
   * Do not call this method directly. Call [dispose] instead.
   * Subclasses should override this method to implement [Disposable] behavior.
   */
  void disposeInternal() { }
}
