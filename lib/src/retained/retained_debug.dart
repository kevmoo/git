part of bot_retained;

class RetainedDebug {
  static void borderThing(Stage stage) {
    final ctx = stage.ctx;
    ctx.save();
    ctx.globalAlpha = 0.5;
    ctx.lineWidth = 5;
    ctx.beginPath();
    _borderThing(ctx, stage.rootThing);
    ctx.stroke();
    ctx.restore();
  }

  static void borderHitTest(Stage stage, Coordinate point){
    final ctx = stage.ctx;

    final hits = RetainedUtil.hitTest(stage, point);

    if(hits.length > 0){
      ctx.save();
      ctx.lineWidth = 2;

      hits.forEach((e) {
        _borderThing(ctx, e, true);
      });
      ctx.restore();
    }
  }

  static void _borderThing(CanvasRenderingContext2D ctx, Thing thing,
                             [bool excludeChildren = false,
                             Func1<Thing, bool> filter = null]) {
    if (filter == null || filter(thing)) {
      _borderThingCore(ctx, thing);
    }

    if (!excludeChildren && thing is ParentThing) {
      final ParentThing p = thing;
      for (var i = 0; i < p.visualChildCount; i++) {
        var e = p.getVisualChild(i);
        _borderThing(ctx, e, false, filter);
      }
    }
  }

  static void _borderThingCore(CanvasRenderingContext2D ctx, Thing thing) {
    if (Mouse.isMouseDirectlyOver(thing)) {
      ctx.strokeStyle = 'red';
    } else if (Mouse.isMouseOver(thing)) {
      ctx.strokeStyle = 'pink';
    } else {
      ctx.strokeStyle = 'orange';
    }

    final corners = RetainedUtil.getCorners(thing);

    ctx.beginPath();
    ctx.moveTo(corners[3].x, corners[3].y);
    for(final p in corners) {
      ctx.lineTo(p.x, p.y);
    }
    ctx.stroke();
  }
}
