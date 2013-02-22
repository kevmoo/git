import 'dart:html';
import 'dart:isolate';
import 'package:bot/bot.dart';
import 'package:bot/bot_async.dart';
import 'package:bot/bot_html.dart';
import 'package:bot/bot_retained.dart';

main(){
  CanvasElement canvas = document.query("#content");
  var demo = new DraggerDemo(canvas);
  demo.requestFrame();
}

class DraggerDemo{
  final CanvasElement _canvas;
  final Stage _stage;
  final AffineTransform _tx;
  final _DemoValue _demoMapper;

  Coordinate _mouseLocation;
  bool _frameRequested = false;
  final Thing _thing;

  factory DraggerDemo(CanvasElement canvas){

    final image =
        new SpriteThing.horizontalFromUrl('disasteroids2_master.png',
            28, 28, 16, 29, new Coordinate(35,354));

    MouseManager.setCursor(image, 'pointer');

    var tx = image.addTransform();

    var rootPanel = new CanvasThing(500, 500);
    rootPanel.add(image);

    var stage = new Stage(canvas, rootPanel);

    return new DraggerDemo._internal(canvas, stage, tx, image);
  }

  DraggerDemo._internal(this._canvas, this._stage, this._tx, this._thing) :
    _demoMapper = new _DemoValue() {

    _demoMapper.outputChanged.listen((e) => requestFrame());

    _stage.invalidated.listen(_onStageInvalidated);

    final cm = new MouseManager(_stage);

    MouseManager.setDraggable(_thing, true);
    MouseManager.getDragStream(_thing).listen(_onDrag);
  }

  void requestFrame(){
    if(!_frameRequested) {
      _frameRequested = true;
      window.requestAnimationFrame(_onFrame);
    }
  }

  void _onStageInvalidated(args) {
    requestFrame();
  }

  void _onDrag(ThingDragEventArgs args) {
    final delta = args.delta;
    _tx.translate(delta.x, delta.y);
    final arrayValue = [_tx.translateX, _tx.translateY];
    _demoMapper.input = arrayValue;
    requestFrame();
  }

  void _onFrame(double highResTime){
    _stage.draw();

    final ctx = _stage.ctx;
    ctx.save();
    ctx.fillStyle = 'black';
    ctx.shadowColor = 'white';
    ctx.shadowBlur = 2;
    ctx.shadowOffsetX = 1;
    ctx.shadowOffsetY = 1;
    ctx.font = '20px Fixed, monospace';

    final inputText = " Input: ${_demoMapper.input}";
    final outputText = "Output: ${_demoMapper.output}";

    final int bottom = _canvas.height;
    final w = _canvas.width;

    ctx.fillText(inputText, 10, bottom - 40);
    ctx.fillText(outputText, 10, bottom - 20);
    ctx.restore();
    _frameRequested = false;
    requestFrame();
  }
}

class _DemoValue extends SendPortValue<List<int>, int> {
  _DemoValue() : super(spawnFunction(_demoIsolate));
}

void _demoIsolate() {
  new SendValuePort<List<int>, int>((input) {
    final start = new DateTime.now();
    Duration delta;
    do {
      delta = (new DateTime.now().difference(start));
    } while(delta.inSeconds < 1);

    assert(input.length == 2);
    final coord = new Coordinate(input[0], input[1]);

    final int output = coord.x * coord.y;
    return output;
  });
}
