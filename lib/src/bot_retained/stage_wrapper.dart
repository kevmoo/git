part of bot_retained;

class StageWrapper<T extends Thing> extends DisposableImpl {

  @protected
  final CanvasElement canvas;

  @protected
  final Stage stage;

  @protected
  final T rootThing;

  StreamSubscription _invalidatedEventSub;

  bool _frameRequested = false;

  StageWrapper(CanvasElement canvas, T rootThing) :
    this.canvas = canvas,
    this.rootThing = rootThing,
    this.stage = new Stage(canvas, rootThing) {
    _invalidatedEventSub = stage.invalidated.listen((_) => requestFrame());
  }

  void requestFrame() {
    if(!_frameRequested) {
      _frameRequested = true;
      window.requestAnimationFrame(drawFrame);
    }
  }

  void disposeInternal() {
    _invalidatedEventSub.cancel();
    _invalidatedEventSub = null;
  }

  @protected
  void drawFrame(double highResTime) {
    assert(_frameRequested);
    _frameRequested = false;
    stage.draw();
  }
}
