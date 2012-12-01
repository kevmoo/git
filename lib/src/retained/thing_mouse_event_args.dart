part of bot_retained;

class ThingMouseEventArgs extends EventArgs {
  final Thing thing;
  final bool shiftKey;

  factory ThingMouseEventArgs(Thing thing, MouseEvent mouseEvent) {
    assert(thing != null);
    assert(mouseEvent != null);

    return new ThingMouseEventArgs._internal(thing, mouseEvent.shiftKey);
  }

  ThingMouseEventArgs._internal(this.thing, this.shiftKey);
}
