part of bot_html;

Coordinate getMouseEventCoordinate(MouseEvent event) {
  return new Coordinate(event.offsetX, event.offsetY);
}

Future<int> getTimeoutFuture(int milliseconds) {
  if(milliseconds < 0) {
    return new Future.immediate(0);
  } else {
    final completer = new Completer();

    window.setTimeout(() => completer.complete(milliseconds), milliseconds);

    return completer.future;
  }
}
