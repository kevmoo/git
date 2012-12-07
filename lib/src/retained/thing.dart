part of bot_retained;

// TODO: 'alpha' does not compose well. If a parent is 50% and the child is
//       50% the render should be at %25, right? :-/

abstract class Thing extends AttachableObject {
  final List<AffineTransform> _transforms = new List<AffineTransform>();
  final bool cacheEnabled;
  final EventHandle<EventArgs> _invalidatedEventHandle = new EventHandle<EventArgs>();
  CanvasElement _cacheCanvas;

  num _width, _height, _alpha = 1;
  Size _lastDrawSize;
  bool clip = false;
  ThingParent _parent;

  Thing(this._width, this._height, [this.cacheEnabled = false]);

  num get width => _width;

  void set width(num value) {
    assert(isValidNumber(value));
    _width = value;
    invalidateDraw();
  }

  num get height => _height;

  void set height(num value) {
    assert(isValidNumber(value));
    _height = value;
    invalidateDraw();
  }

  Size get size => new Size(_width, _height);

  void set size(Size value) {
    assert(value.isValid);
    _width = value.width;
    _height = value.height;
    invalidateDraw();
  }

  num get alpha => _alpha;

  void set alpha(num value) {
    requireArgument(isValidNumber(value), 'value');
    requireArgument(value >= 0 && value <= 1, 'value');
    _alpha = value;
    if(parent != null) {
      _invalidateParent();
    }
  }

  ThingParent get parent => _parent;

  EventRoot<EventArgs> get invalidated => _invalidatedEventHandle;

  AffineTransform getTransform() {
    var tx = new AffineTransform();
    _transforms.forEach(tx.concatenate);
    return tx;
  }

  AffineTransform getTransformToRoot(){
    var tx = new AffineTransform();
    if(_parent != null){
      tx.concatenate(_parent.getTransformToRoot());
    }
    tx.concatenate(getTransform());
    return tx;
  }

  @protected
  void update(){ }

  @protected
  void drawCore(CanvasRenderingContext2D ctx){
    if(cacheEnabled) {
      _drawCached(ctx);
    } else {
      _drawNormal(ctx);
    }
  }

  AffineTransform addTransform(){
    validateNotDisposed();
    var tx = new AffineTransform();
    _transforms.add(tx);
    return tx;
  }

  bool removeTransform(AffineTransform tx) {
    requireArgumentNotNull(tx, 'tx');
    final index = _transforms.indexOf(tx);
    if(index < 0) {
      return false;
    } else {
      _transforms.removeAt(index);
      return true;
    }
  }

  @protected
  void drawOverride(CanvasRenderingContext2D ctx);

  void invalidateDraw(){
    validateNotDisposed();
    if(_lastDrawSize != null) {
      _lastDrawSize = null;
      _invalidateParent();
    }
  }

  void registerParent(ThingParent parent) {
    require(_parent == null, 'parent already set');
    requireArgumentNotNull(parent, 'parent');
    _parent = parent;
  }

  void unregisterParent(ThingParent parent) {
    requireArgumentNotNull(parent, 'parent');
    requireArgument(parent == _parent, 'parent');
    _parent = null;
  }

  @protected
  void disposeInternal(){
    super.disposeInternal();
    _invalidatedEventHandle.dispose();
  }

  //
  // Privates
  //

  bool _stageDraw(CanvasRenderingContext2D ctx){
    update();
    var dirty = (_lastDrawSize == null);
    drawCore(ctx);
    return dirty;
  }

  void _drawCached(CanvasRenderingContext2D ctx) {
    if (this._cacheCanvas == null) {
      this._cacheCanvas = new CanvasElement();
    }

    final intLastDrawSize = (_lastDrawSize == null) ?
        null : new Size(_lastDrawSize.width.toInt(), _lastDrawSize.height.toInt());

    if (CanvasUtil.getCanvasSize(this._cacheCanvas) != intLastDrawSize) {
      this._cacheCanvas.width = this.width.toInt();
      this._cacheCanvas.height = this.height.toInt();

      var cacheCtx = _cacheCanvas.context2d;

      _drawInternal(cacheCtx);
    }

    ctx.save();
    var tx = this.getTransform();
    CanvasUtil.transform(ctx, tx);

    _setAlpha(ctx);
    ctx.drawImage(this._cacheCanvas, 0, 0);
    ctx.restore();
  }

  void _drawNormal(CanvasRenderingContext2D ctx){
    var tx = this.getTransform();
    if (this._isClipped(tx, ctx)) {
      return;
    }

    ctx.save();

    // Translate to the starting position
    CanvasUtil.transform(ctx, tx);

    // clip to the bounds of the object
    if (this.clip) {
      ctx.beginPath();
      ctx.rect(0, 0, width, height);
      ctx.clip();
    }

    _setAlpha(ctx);

    _drawInternal(ctx);
    ctx.restore();
  }

  void _drawInternal(CanvasRenderingContext2D ctx) {
    // possible for invalidateParent to be called during draw
    // which signals that another frame is wanted for animating content
    // so we're setting _lastDrawSize here
    _lastDrawSize = this.size;

    // call the abstract draw method
    drawOverride(ctx);
  }

  bool _isClipped(AffineTransform tx, CanvasRenderingContext2D ctx){
    if(clip){
      // a lot more impl to do here...
    }
    return false;
  }

  void _invalidateParent(){
    assert(this._parent != null);
    _invalidatedEventHandle.fireEvent(EventArgs.empty);
    _parent.childInvalidated(this);
  }

  void _setAlpha(CanvasRenderingContext2D ctx) {
    assert(_alpha != null);
    assert(_alpha >= 0);
    assert(_alpha <= 1);
    ctx.globalAlpha = _alpha;
  }
}
