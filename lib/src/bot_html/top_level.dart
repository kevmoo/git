part of bot_html;

Coordinate getMouseEventCoordinate(MouseEvent event) {
  return _p2c(event.offset);
}

/**
 * Get a [Future] that completes after a call to [window.setTimeout] with the
 * provided value. If [milliseconds] is less than or equal to zero, the value of
 * [getImmediateFuture] is returned instead.
 *
 * __DEPRECATED__
 *
 * Use `new Timer()` instead. We might add something similiar that's not
 * html-specific to the `bot` library soon.
 */
@deprecated
Future<int> getTimeoutFuture(int milliseconds) {
  if(milliseconds < 0) {
    return getImmediateFuture();
  } else {
    final completer = new Completer();

    new Timer(new Duration(milliseconds: milliseconds), () => completer.complete(milliseconds));

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
