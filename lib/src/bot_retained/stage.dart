part of bot_retained;

class Stage extends AttachableObject
  implements ThingParent {
  final EventHandle<EventArgs> _invalidatedEventHandle =
      new EventHandle<EventArgs>();

  final CanvasElement _canvas;
  final Thing rootThing;
  CanvasRenderingContext2D _ctx;

  Stage(this._canvas, this.rootThing) {
    rootThing.registerParent(this);
  }

  Size get size => new Size(_canvas.width, _canvas.height);

  Stream<EventArgs> get invalidated => _invalidatedEventHandle.stream;

  CanvasRenderingContext2D get ctx {
    validateNotDisposed();
    if(_ctx == null) {
      _ctx = _canvas.context2d;
    }
    return _ctx;
  }

  bool draw(){
    validateNotDisposed();
    if (_ctx == null) {
      _ctx = _canvas.context2d;
    } else {
      this._ctx.clearRect(0, 0, this._canvas.width, this._canvas.height);
    }

    return this.rootThing._stageDraw(this._ctx);
  }

  void childInvalidated(Thing child){
    validateNotDisposed();
    assert(child == rootThing);
    _invalidatedEventHandle.add(EventArgs.empty);
  }

  void disposeInternal(){
    super.disposeInternal();
    _invalidatedEventHandle.dispose();
  }

  AffineTransform getTransformToRoot() => new AffineTransform();
}
