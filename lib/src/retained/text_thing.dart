part of bot_retained;

// TODO: fillStyle + textFillStyle to properties w/ value checks
// TODO: invalidate on prop change
// TODO: settable 'value' + validation
// TODO: text alignment
// TODO: text shadow
// TODO: font styles

class TextThing extends Thing {
  final String _value;

  dynamic fillStyle = 'white';
  dynamic textFillStyle = 'black';

  TextThing(this._value, num width, num height)
      : super(width, height);

  void drawOverride(CanvasRenderingContext2D ctx) {
    if(fillStyle != null) {
      ctx.fillStyle = fillStyle;
      ctx.fillRect(0, 0, this.width, this.height);
    }

    ctx.fillStyle = textFillStyle;
    ctx.textBaseline = 'top';
    ctx.fillText(_value, 0, 0);
  }
}
