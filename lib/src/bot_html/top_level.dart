part of bot_html;

Coordinate getMouseEventCoordinate(MouseEvent event) {
  return new Coordinate(event.offsetX, event.offsetY);
}

/**
 * Get a [Future] that completes after a call to [window.setTimeout] with the
 * provided value. If [milliseconds] is less than or equal to zero, the value of
 * [getImmediateFuture] is returned instead.
 */
Future<int> getTimeoutFuture(int milliseconds) {
  if(milliseconds < 0) {
    return getImmediateFuture();
  } else {
    final completer = new Completer();

    window.setTimeout(() => completer.complete(milliseconds), milliseconds);

    return completer.future;
  }
}

/**
 * Get a [Future] that completes after a call to [window.setImmediate].
 */
Future getImmediateFuture() {
  final completer = new Completer();

  window.setImmediate(() => completer.complete(null));

  return completer.future;
}
