part of bot_retained;

class RetainedUtil {

  static Vector getOffsetVector(Size parentSize, Size childSize,
                         HorizontalAlignment horizontalAlignment,
                         VerticalAlignment verticalAlignment,
                         Vector offset) {
    requireArgumentNotNull(parentSize, 'parentSize');
    requireArgumentNotNull(childSize, 'childSize');
    requireArgumentNotNull(horizontalAlignment, 'horizontalAlignment');
    requireArgumentNotNull(verticalAlignment, 'verticalAlignment');
    requireArgumentNotNull(offset, 'offset');

    num x = offset.x, y = offset.y;


    switch (horizontalAlignment) {
      case HorizontalAlignment.LEFT:
        //no-op
        break;
      case HorizontalAlignment.CENTER:
        x += (parentSize.width - childSize.width) / 2;
        break;
      case HorizontalAlignment.RIGHT:
        x += parentSize.width - childSize.width;
        break;
      default:
        throw new ArgumentError('horizontalAlignment value not expected $horizontalAlignment');
    }

    switch (verticalAlignment) {
      case VerticalAlignment.TOP:
        //no-op
        break;
      case VerticalAlignment.MIDDLE:
        y += (parentSize.height - childSize.height) / 2;
        break;
      case VerticalAlignment.BOTTOM:
        y += parentSize.height - childSize.height;
        break;
      default:
        throw new ArgumentError('verticalAlignment value not expected $verticalAlignment');
    }

    return new Vector(x, y);
  }

  static List<Thing> hitTest(Stage stage, Coordinate point){
    return _hitTest(stage.rootThing, point);
  }

  static List<Thing> _hitTest(Thing thing, Coordinate point){
    point = transformPointGlobalToLocal(thing, point);

    final bounds = new Box(0, 0, thing.width, thing.height);

    var hits = new List<Thing>();
    if (bounds.contains(point)) {
      if(thing is ParentThing) {
        final ParentThing p = thing;

        var length = p.visualChildCount;
        for (var i = 0; i < length; i++) {
          var e = p.getVisualChild(length - 1 - i);
          hits = _hitTest(e, point);
          if (hits.length > 0) {
            break;
          }
        }
      }
      hits.add(thing);
    }
    return hits;
  }

  static Coordinate transformPointLocalToGlobal(Thing thing,
                                                     Coordinate point) {
    var tx = thing.getTransformToRoot();
    return tx.transformCoordinate(point);
  }

  static Coordinate transformPointGlobalToLocal(Thing thing,
                                                     Coordinate point) {
    var tx = thing.getTransform();
    return tx.createInverse().transformCoordinate(point);
  }

  static List<Coordinate> getCorners(Thing thing) {
    final rect = new Box(0,0,thing.width, thing.height);
    final points = rect.getCorners();
    return points.map((p) {
      return transformPointLocalToGlobal(thing, p);
    }).toList();
  }
}
