part of bot_retained;

class StageWrapper<T extends Thing> extends DisposableImpl {

  @protected
  final CanvasElement canvas;

  @protected
  final Stage stage;

  @protected
  final T rootThing;

  GlobalId _invalidatedEventId;

  bool _frameRequested = false;

  StageWrapper(CanvasElement canvas, T rootThing) :
    this.canvas = canvas,
    this.rootThing = rootThing,
    this.stage = new Stage(canvas, rootThing) {
    _invalidatedEventId = stage.invalidated.add((_) => requestFrame());
  }

  void requestFrame() {
    if(!_frameRequested) {
      _frameRequested = true;
      window.requestAnimationFrame(drawFrame);
    }
  }

  void disposeInternal() {
    stage.invalidated.remove(_invalidatedEventId);
    _invalidatedEventId = null;
  }

  @protected
  void drawFrame(double highResTime) {
    assert(_frameRequested);
    _frameRequested = false;
    stage.draw();
  }
}
