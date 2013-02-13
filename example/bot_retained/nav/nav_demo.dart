import 'dart:html';
import 'dart:math' as math;
import 'package:bot/bot.dart';
import 'package:bot/bot_html.dart';
import 'package:bot/bot_retained.dart';

void main() {
  CanvasElement canvas = document.query("#content");
  var demo = new NavDemo(canvas);
  demo.requestFrame();
}

class NavDemo extends StageWrapper<NavThing> {
  int _count = 0;

  factory NavDemo(CanvasElement canvas) {

    final nav = new NavThing(300, 300);

    return new NavDemo._internal(canvas, nav);
  }

  NavDemo._internal(CanvasElement canvas, NavThing nav) :
    super(canvas, nav) {
    _forward(new AffineTransform());
    canvas.onMouseDown.listen(_canvas_mouseDown);
  }

  void _forward(AffineTransform tx) {
    if(rootThing.canForward) {
      final element = _getDemoElement(++_count);
      rootThing.forward(element, tx);
    }
  }

  void _canvas_mouseDown(MouseEvent e) {
    final point = getMouseEventCoordinate(e);
    final hits = RetainedUtil.hitTest(stage, point);
    if(hits.length > 0) {
      _itemClick(hits.first);
    }
  }

  void _itemClick(Thing element) {
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

  static Thing _getDemoElement(int count) {
    final canvas = new CanvasThing(300, 300);

    final back = new ShapeThing(300, 300, fillStyle: '#333');
    back.alpha = 0.5;
    canvas.add(back);

    final text = new TextThing("Click here - $count", 100, 100);
    canvas.add(text);
    canvas.setTopLeft(text, new Coordinate(100, 100));

    ShapeThing corner;

    // top left
    corner = new ShapeThing(100, 100, fillStyle: 'red');
    canvas.add(corner);
    canvas.setTopLeft(corner, new Coordinate(0,0));

    // top right
    corner = new ShapeThing(100, 100, fillStyle: 'green');
    canvas.add(corner);
    canvas.setTopLeft(corner, new Coordinate(200,0));

    // bottom left
    corner = new ShapeThing(100, 100, fillStyle: 'blue');
    canvas.add(corner);
    canvas.setTopLeft(corner, new Coordinate(0,200));

    // bottom right
    corner = new ShapeThing(100, 100, fillStyle: 'yellow');
    canvas.add(corner);
    canvas.setTopLeft(corner, new Coordinate(200,200));

    return canvas;
  }
}
