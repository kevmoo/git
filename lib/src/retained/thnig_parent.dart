part of bot_retained;

abstract class ThingParent {
  void childInvalidated(Thing child);
  AffineTransform getTransformToRoot();
  EventRoot<EventArgs> get invalidated;
}
