part of bot_retained;

class PanelThing extends ParentThing {
  static final Property<AffineTransform> _containerTransformProperty =
      new Property<AffineTransform>("panelTransform");

  final List<Thing> _children;
  String background;

  PanelThing(num w, num h) :
    _children = new List<Thing>(),
    super(w, h);

  void add(Thing thing){
    insertAt(thing, _children.length);
  }

  void insertAt(Thing thing, [int index=null]){
    requireArgumentNotNull(thing, 'thing');
    requireArgument(thing.parent == null, 'thing',
        'already has a parent');
    requireArgument(!_children.contains(thing), 'thing',
        'Cannot add twice');

    index = (index == null) ? 0 : index;
    thing.registerParent(this);
    _children.insertRange(index, 1, thing);

    assert(!_containerTransformProperty.isSet(thing));
    _containerTransformProperty.set(thing, thing.addTransform());
    onChildrenChanged();
  }

  bool remove(Thing thing) {
    requireArgumentNotNull(thing, 'thing');

    final index = _children.indexOf(thing);
    if(index < 0) {
      return false;
    } else {
      final item = _children.removeAt(index);
      item.unregisterParent(this);
      final containerTx = _containerTransformProperty.get(item);
      assert(containerTx != null);
      var txRemoved = item.removeTransform(containerTx);
      assert(txRemoved);
      _containerTransformProperty.clear(item);
      return true;
    }
  }

  Thing getVisualChild(index) => _children[index];

  int get visualChildCount => _children.length;

  @protected
  AffineTransform getChildTransform(child) {
    assert(hasVisualChild(child));
    var tx = _containerTransformProperty.get(child);
    assert(tx != null);
    return tx;
  }

  void drawOverride(CanvasRenderingContext2D ctx) {
    if(background != null) {
      ctx.fillStyle = background;
      ctx.fillRect(0, 0, width, height);
    }
    super.drawOverride(ctx);
  }
}
