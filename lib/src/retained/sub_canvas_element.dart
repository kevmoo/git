part of bot_retained;

class SubCanvasElement extends PElement {
  final CanvasElement _canvas;

  SubCanvasElement(num width, num height, this._canvas) :
    super(width, height);

  void drawOverride(CanvasRenderingContext2D ctx) {
    ctx.drawImage(_canvas, 0, 0, width, height);
  }
}
