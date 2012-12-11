part of bot_retained;

class NavThing extends ParentThing {
  static final Property<AffineTransform> _navLayerTransformProp =
      new Property<AffineTransform>("navLayerTxProp");

  final VerticalAlignment verticalAlignment = VerticalAlignment.MIDDLE;
  final HorizontalAlignment horizontalAlignment = HorizontalAlignment.CENTER;

  Thing _child;
  _NavLayerTxPanel _txPanel;
  Vector _childOffset;

  NavThing(num width, num height) :
    super(width, height);

  int get visualChildCount {
    if(_txPanel != null) {
      return 1;
    } else if (_child != null) {
      return 1;
    } else {
      return 0;
    }
  }

  Thing getVisualChild(int index) {
    if(index == 0) {
      if(_txPanel != null) {
        return _txPanel;
      } else if(_child != null) {
        return _child;
      }
    }
    throw new ArgumentError();
  }

  bool get canForward => _txPanel == null;

  void forward(Thing thing, AffineTransform tx, [int frameCount = 30]) {
    requireArgumentNotNull(thing, 'thing');
    requireArgumentNotNull(tx, 'tx');
    requireArgumentNotNull(frameCount, 'frameCount');
    require(canForward, 'Forward cannot be called');

    if(_child != null) {
      assert(_txPanel == null); // I guess we don't allow stacked forwards yet
      final ghost = this._child;

      _child.unregisterParent(this);
      final existingTx = _navLayerTransformProp.get(_child);
      assert(existingTx != null);
      _child.removeTransform(existingTx);
      _child = null;

      final tempCanvas = new CanvasElement(
          width: ghost.width.toInt(), height: ghost.height.toInt());

      final tempCtx = tempCanvas.context2d;
      ghost.drawOverride(tempCtx);

      this._txPanel = new _NavLayerTxPanel(this.width, this.height, tempCanvas,
          thing, tx, existingTx, frameCount, horizontalAlignment,
          verticalAlignment, _childOffset);
      this._txPanel.registerParent(this);
    }

    assert(_child == null);
    _child = thing;

    if(_txPanel == null) {
      _claimChild();
    }

    invalidateDraw();
  }

  void update() {
    super.update();
    if(_txPanel != null) {
      assert(_child != null);
      assert(_child.parent == _txPanel);
      if(_txPanel.isDone) {
        _txPanel.unregisterParent(this);
        final removed = _txPanel.remove(_child);
        assert(removed);
        _txPanel = null;
        _claimChild();
      }
    }
  }

  void _claimChild() {
    assert(_txPanel == null);
    assert(_child != null);
    assert(!_navLayerTransformProp.isSet(_child));

    final tx = _child.addTransform();
    _navLayerTransformProp.set(_child, tx);
    _child.registerParent(this);
  }

  void _updateChildLocation() {
    throw 'not impld';
  }
}

class _NavLayerTxPanel extends PanelThing {
  final int _frames;
  final SubCanvasThing _lastImage;
  final Thing _newChild;
  final AffineTransform _startTx, _goalTx;
  AffineTransform _myTx;

  int _i = 0;

  factory _NavLayerTxPanel(num width, num height, CanvasElement lastCanvas,
      Thing newChild, AffineTransform startTx, AffineTransform ghostTx,
      int frameCount, HorizontalAlignment horizontalAlignment,
      VerticalAlignment verticalAlignment, Vector childOffset) {
    if(childOffset == null) {
      childOffset = new Vector();
    }

    final lastImage = new SubCanvasThing(lastCanvas.width, lastCanvas.height,
        lastCanvas);

    final lastTx = lastImage.addTransform();
    lastTx.setFromTransfrom(startTx.createInverse());

    final thisSize = new Size(width, height);

    final Coordinate newChildOffset = RetainedUtil.getOffsetVector(
        thisSize, newChild.size, horizontalAlignment, verticalAlignment, childOffset);
    final goalTx = new AffineTransform.fromTranslat(newChildOffset.x, newChildOffset.y);
    final newStartTx = ghostTx.clone().concatenate(startTx);

    return new _NavLayerTxPanel._internal(width, height, frameCount, lastImage,
        newChild, newStartTx, goalTx);  }

  _NavLayerTxPanel._internal(num width, num height, this._frames, this._lastImage, this._newChild, this._startTx, this._goalTx) : super(width, height) {
    add(_lastImage);
    add(_newChild);
    assert(_frames >= 0);

    _myTx = this.addTransform();
    _myTx.setFromTransfrom(_startTx);
  }

  bool get isDone => _i >= _frames;

  void update() {
    if(_i < _frames) {
      assert(!isDone);
      final ratio = _i / (_frames - 1);
      final newTx = _startTx.lerpTx(_goalTx, ratio);
      _myTx.setFromTransfrom(newTx);

      _lastImage.alpha = 1 - ratio;
      _newChild.alpha = ratio;

      // a private hack to look at super field
      // ensure we are invalidated here...
      assert(_lastDrawTime == null);
      _i++;
    } else {
      assert(isDone);
      assert(_newChild.alpha == 1);
      assert(_lastImage.alpha == 0);
    }
  }

  void drawOverride(CanvasRenderingContext2D ctx) {
    super.drawOverride(ctx);
    if(!isDone) {
      invalidateDraw();
    }
  }
}
