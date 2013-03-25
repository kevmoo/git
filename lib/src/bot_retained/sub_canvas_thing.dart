part of bot_retained;

class SubCanvasThing extends Thing {
  final CanvasElement _canvas;

  SubCanvasThing(num width, num height, this._canvas) :
    super(width, height);

  @override
  void drawOverride(CanvasRenderingContext2D ctx) {
    final rect = new Rect(0,0,width,height);
    ctx.drawImageToRect(_canvas, rect);
  }
}
