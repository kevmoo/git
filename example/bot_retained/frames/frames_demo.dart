import 'dart:html';
import 'dart:math' as math;
import 'package:bot/bot.dart';
import 'package:bot/bot_html.dart';
import 'package:bot/bot_retained.dart';

void main() {
  CanvasElement canvas = document.query("#content");
  var demo = new FrameDemo(canvas);
  demo.requestFrame();
}

class FrameDemo extends StageWrapper<CanvasThing> {
  final TxThing _txThing;

  factory FrameDemo(CanvasElement canvas) {
    final canvasThing = new CanvasThing(canvas.width, canvas.height);
    return new FrameDemo._internal(canvas, canvasThing);
  }

  FrameDemo._internal(CanvasElement canvas, CanvasThing canvasThing) :
    _txThing = new TxThing(canvas.width, canvas.height),
    super(canvas, canvasThing) {

    this.rootThing.add(_txThing);

    var cm = new MouseManager(stage);
  }

}

class TxThing extends ParentThing {
  static const num _widgetSize = 20;

  final Size _sourceSize;
  final CanvasThing _canvasThing;
  final ShapeThing _shape, _positionShape, _rotateScaleShape;
  final AffineTransform _tx;
  Coordinate _rotateScaleCoordinate;

  factory TxThing(num width, num height) {
    final box = new Box(width/3, height/3, width/3, height/3);

    final shape = new ShapeThing(box.width, box.height);
    final tx = shape.addTransform();
    tx.setToTranslation(box.left, box.top);

    return new TxThing._internal(width, height, box.size, shape, tx);
  }

  TxThing._internal(num width, num height, this._sourceSize, this._shape, this._tx) :
    _canvasThing = new CanvasThing(width, height),
    _positionShape = new ShapeThing(_widgetSize, _widgetSize, fillStyle: 'gray'),
    _rotateScaleShape = new ShapeThing(_widgetSize, _widgetSize, fillStyle: 'red'),
    super(width, height) {

    _canvasThing.registerParent(this);
    _canvasThing.add(_shape);

    _canvasThing.add(_positionShape);
    MouseManager.setCursor(_positionShape, 'pointer');
    MouseManager.setDraggable(_positionShape, true);
    MouseManager.getDragStream(_positionShape).listen(_dragPosition);

    _canvasThing.add(_rotateScaleShape);
    MouseManager.setCursor(_rotateScaleShape, 'pointer');
    MouseManager.setDraggable(_rotateScaleShape, true);
    MouseManager.getDragStream(_rotateScaleShape).listen(_dragRotateScale);

    _updateRotateScale();
  }

  int get visualChildCount => 1;

  Thing getVisualChild(int index) => _canvasThing;

  Coordinate get _positionCoordinate => _tx.transformCoordinate();

  void _dragPosition(ThingDragEventArgs e) {
    final newValue = _positionCoordinate + e.delta;
    _tx.updateValues(translateX: newValue.x, translateY: newValue.y);
    _updateRotateScale();
  }

  void _updateRotateScale() {
    _rotateScaleCoordinate = _tx.transformCoordinate(new Coordinate(0, _sourceSize.height));
    _updatePoints();
  }

  void _dragRotateScale(ThingDragEventArgs e) {
    // TODO: we're going to get some crazy rounding 'drift' here
    // should track drag start and add up the deltas and apply them together

    _rotateScaleCoordinate = _rotateScaleCoordinate + e.delta;

    final pc = _positionCoordinate;

    final pointDeltaVector = _rotateScaleCoordinate - pc;

    final newScale = pointDeltaVector.length / _sourceSize.height;

    final downVector = const Vector(0, 10);
    final angle = downVector.getAngle(pointDeltaVector);

    _tx.setToTranslation(pc.x, pc.y);
    _tx.rotate(angle, 0, 0);


    _tx.scale(newScale, newScale);

    _updatePoints();
  }

  void _updatePoints() {
    _canvasThing.setCenter(_positionShape, _positionCoordinate);

    _canvasThing.setCenter(_rotateScaleShape, _rotateScaleCoordinate);
  }
}
