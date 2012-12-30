part of bot_retained;

class CanvasThing extends PanelThing {

  CanvasThing(int w, int h) :
    super(w, h);

  void setTopLeft(Thing thing, Coordinate value){
    var tx = getChildTransform(thing);
    tx.setToTranslation(value.x, value.y);
    thing.invalidateDraw();
  }

  Coordinate getTopLeft(Thing thing){
    var tx = getChildTransform(thing);
    return tx.transformCoordinate();
  }

  void setCenter(Thing thing, Coordinate value){
    var sizeOffset = new Vector(thing.width/2, thing.height/2);
    var delta = Coordinate.difference(value, sizeOffset);
    setTopLeft(thing, delta);
  }

  Coordinate getCenter(Thing thing){
    var sizeOffset = new Vector(thing.width/2, thing.height/2);
    return sizeOffset + getTopLeft(thing);
  }
}

