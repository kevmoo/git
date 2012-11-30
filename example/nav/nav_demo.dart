import 'dart:html';
import 'dart:math' as math;
import 'package:bot/bot.dart';
import 'package:bot/html.dart';
import 'package:bot/retained.dart';

void main() {
  CanvasElement canvas = document.query("#content");
  var demo = new NavDemo(canvas);
  demo.requestFrame();
}

class NavDemo {
  final CanvasElement _canvas;
  final Stage _stage;
  final NavLayer _nav;
  bool _frameRequested = false;
  int _count = 0;

  factory NavDemo(CanvasElement canvas) {

    final nav = new NavLayer(300, 300);

    final stage = new Stage(canvas, nav);

    return new NavDemo._internal(canvas, stage, nav);
  }

  NavDemo._internal(this._canvas, this._stage, this._nav) {
    _stage.invalidated.add((_) => requestFrame());
    _forward(new AffineTransform());
    _canvas.on.mouseDown.add(_canvas_mouseDown);
  }

  void requestFrame() {
    if(!_frameRequested) {
      _frameRequested = true;
      window.requestAnimationFrame(_onFrame);
    }
  }

  void _forward(AffineTransform tx) {
    if(_nav.canForward) {
      final element = _getDemoElement(++_count);
      _nav.forward(element, tx);
    }
  }

  void _canvas_mouseDown(MouseEvent e) {
    final point = getMouseEventCoordinate(e);
    final hits = RetainedUtil.hitTest(_stage, point);
    if(hits.length > 0) {
      _itemClick(hits.first);
    }
  }

  void _itemClick(PElement element) {
    AffineTransform tx;
    if(element.width == 300) {
      tx = new AffineTransform.fromTranslat(100, 100)
        .scale(1/3, 1/3)
        .createInverse();
    } else {
      final lastTx = element.getTransform();
      tx = new AffineTransform.fromTranslat(lastTx.translateX, lastTx.translateY)
        .scale(1/3, 1/3);
    }
    _forward(tx);
  }

  void _onFrame(double highResTime) {
    assert(_frameRequested);
    _frameRequested = false;
    _stage.draw();
  }

  static PElement _getDemoElement(int count) {
    final canvas = new PCanvas(300, 300, true);

    final back = new Shape(300, 300, fillStyle: '#333', cacheEnabled: false);
    back.alpha = 0.5;
    canvas.addElement(back);

    final text = new TextElement("Click here - $count", 100, 100, false);
    canvas.addElement(text);
    canvas.setTopLeft(text, new Coordinate(100, 100));

    Shape corner;

    // top left
    corner = new Shape(100, 100, fillStyle: 'red', cacheEnabled: false);
    canvas.addElement(corner);
    canvas.setTopLeft(corner, new Coordinate(0,0));

    // top right
    corner = new Shape(100, 100, fillStyle: 'green', cacheEnabled: false);
    canvas.addElement(corner);
    canvas.setTopLeft(corner, new Coordinate(200,0));

    // bottom left
    corner = new Shape(100, 100, fillStyle: 'blue', cacheEnabled: false);
    canvas.addElement(corner);
    canvas.setTopLeft(corner, new Coordinate(0,200));

    // bottom right
    corner = new Shape(100, 100, fillStyle: 'yellow', cacheEnabled: false);
    canvas.addElement(corner);
    canvas.setTopLeft(corner, new Coordinate(200,200));

    return canvas;
  }
}
