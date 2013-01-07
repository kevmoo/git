part of bot_retained;

class SubCanvasThing extends Thing {
  final CanvasElement _canvas;

  SubCanvasThing(num width, num height, this._canvas) :
    super(width, height);

  void drawOverride(CanvasRenderingContext2D ctx) {
    ctx.drawImage(_canvas, 0, 0, width, height);
  }
}
