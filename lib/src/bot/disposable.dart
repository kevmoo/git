part of bot;

abstract class Disposable {
  void dispose();
  bool get isDisposed;
}

class DisposedError implements StateError {
  const DisposedError();

  final String message = 'Invalid operation on disposed object';
}
