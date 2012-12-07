part of bot_retained;

abstract class ParentThing
  extends Thing
  implements ThingParent {

  ParentThing(num w, num h) :
    super(w, h);

  bool hasVisualChild(Thing thing){
    var length = visualChildCount;
    for(var i=0;i<length;i++){
      if(identical(thing, getVisualChild(i))){
        return true;
      }
    }
    return false;
  }

  void onChildrenChanged(){
    invalidateDraw();
  }

  Thing getVisualChild(int index);

  int get visualChildCount;

  void childInvalidated(Thing child){
    assert(hasVisualChild(child));
    invalidateDraw();
  }

  void update(){
    _forEach((e) => e.update());
    super.update();
  }

  void drawOverride(CanvasRenderingContext2D ctx) {
    _forEach((e) => e.drawCore(ctx));
  }

  void _forEach(Action1<Thing> f) {
    final length = visualChildCount;
    for(int i = 0; i < length; i++) {
      f(getVisualChild(i));
    }
  }
}
