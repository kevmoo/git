part of bot_retained;

class Mouse {
  static final Property<bool> isMouseOverProperty =
      new Property<bool>("IsMouseOver", false);
  static final Property<bool> isMouseDirectlyOverProperty =
      new Property<bool>("IsMouseDirectlyOver", false);
  static final Property<List<Thing>> _stageMouseCacheProperty =
      new Property<List<Thing>>("_stageMouseCacheProperty");

  static bool isMouseOver(Thing thing) => isMouseOverProperty.get(thing);

  static bool isMouseDirectlyOver(Thing thing) =>
      isMouseDirectlyOverProperty.get(thing);

  static List<Thing> markMouseOver(Stage stage,
      [Coordinate coordinate = null]) {
    requireArgumentNotNull(stage, 'stage');
    requireArgument(coordinate == null || coordinate.isValid, 'coordinate');

    final items = _stageMouseCacheProperty.get(stage);
    if (items != null) {
      items.forEach((e) {
        isMouseOverProperty.clear(e);
        isMouseDirectlyOverProperty.clear(e);
      });
      _stageMouseCacheProperty.clear(stage);
    }
    if (coordinate != null) {
      var hits = RetainedUtil.hitTest(stage, coordinate);
      _stageMouseCacheProperty.set(stage, hits);
      hits.forEach((e) {
        isMouseOverProperty.set(e, true);
      });
      if (hits.length > 0) {
        isMouseDirectlyOverProperty.set(hits[0], true);
      }
      return hits;
    }
    return null;
  }
}
