import 'dart:html';
import 'package:bot/bot.dart';
import 'package:bot/bot_retained.dart';

main(){
  CanvasElement canvas = document.query("#content");
  var demo = new ClickDemo(canvas);
  demo.requestFrame();
}

class ClickDemo extends StageWrapper<CanvasThing> {
  static const _blueColor = 'blue';

  factory ClickDemo(CanvasElement canvas){

    CanvasThing pCanvas = new CanvasThing(200, 200);
    pCanvas.background = 'yellow';

    var blue = new ShapeThing(100, 100, fillStyle: _blueColor);
    MouseManager.setClickable(blue, true);
    final clickHandler = (args) {
      blue.fillStyle = (blue.fillStyle == _blueColor) ? 'lightblue' : _blueColor;
    };

    MouseManager.getClickStream(blue).listen(clickHandler);

    pCanvas.add(blue);

    var green = new ShapeThing(70, 70, fillStyle: 'green');
    pCanvas.add(green);
    pCanvas.setTopLeft(green, const Coordinate(110, 15));

    var red = new ShapeThing(40, 40, fillStyle: 'red', shapeType: ShapeType.ellipse);
    pCanvas.add(red);
    pCanvas.setCenter(red, const Coordinate(50, 150));

    MouseManager.setClickable(red, true);
    MouseManager.getMouseUpStream(red).listen((args) => print(['up', args]));
    MouseManager.getMouseDownStream(red).listen((args) => print(['down', args]));

    pCanvas.addTransform().translate(
      (canvas.width - pCanvas.width) / 2,
      (canvas.height - pCanvas.height) / 2);

    var rootPanel = new CanvasThing(500, 500);
    rootPanel.add(pCanvas);

    return new ClickDemo._internal(canvas, rootPanel);
  }

  ClickDemo._internal(CanvasElement canvas, CanvasThing thing) :
    super(canvas, thing) {
    new MouseManager(stage);
  }
}
