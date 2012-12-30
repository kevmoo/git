part of bot_retained;

// TODO: rename MouseManager or similiar -> doing more than click now
// TODO: implement dispose. Unregister events from Canvas, etc
// TODO: Remove public ctor. Use ClickManager.enable(stage) or similiar
//       Nothing interesting exists on the instance of CM

class ClickManager {
  static const String _autoCursor = 'auto';

  static final Property<ClickManager> _clickManagerProperty =
      new Property<ClickManager>("_clickManager");

  static final Property<bool> _isClickableProperty =
      new Property<bool>("isClickable", false);

  static final AttachedEvent<ThingMouseEventArgs> _clickEvent =
      new AttachedEvent<ThingMouseEventArgs>('clickEvent');

  static final AttachedEvent<ThingMouseEventArgs> _mouseDownEvent =
      new AttachedEvent<ThingMouseEventArgs>('mouseDown');

  static final AttachedEvent<ThingMouseEventArgs> _mouseUpEvent =
      new AttachedEvent<ThingMouseEventArgs>('mouseUp');

  static final AttachedEvent<ThingMouseEventArgs> _mouseMoveEvent =
      new AttachedEvent<ThingMouseEventArgs>('mouseMove');

  static final AttachedEvent _mouseOutEvent =
      new AttachedEvent('mouseOut');

  static final Property<String> _cursorProperty =
      new Property<String>("_cursor");

  final Stage _stage;

  Thing _mouseDownThing;

  factory ClickManager(Stage stage) {
    requireArgumentNotNull(stage, 'stage');

    return _clickManagerProperty.get(stage, (s) {
      return new ClickManager._internal(s);
    });
  }

  ClickManager._internal(this._stage) {
    // The value is set in the above factory
    assert(!_clickManagerProperty.isSet(this._stage));
    _stage._canvas.on.mouseMove.add(_mouseMove);
    _stage._canvas.on.mouseOut.add(_mouseOut);
    _stage._canvas.on.mouseUp.add(_mouseUp);
    _stage._canvas.on.mouseDown.add(_mouseDown);
  }

  static void setCursor(Thing thing, String value) {
    assert(thing != null);
    if(value == null) {
      _cursorProperty.clear(thing);
    } else {
      _cursorProperty.set(thing, value);
    }
  }

  static String getCursor(Thing thing) {
    assert(thing != null);
    return _cursorProperty.get(thing);
  }

  static void setClickable(Thing thing, bool value) {
    assert(thing != null);
    assert(value != null);
    if(value) {
      _isClickableProperty.set(thing, true);
    } else {
      _isClickableProperty.clear(thing);
    }
  }

  static bool getClickable(Thing thing) {
    assert(thing != null);
    return _isClickableProperty.get(thing);
  }

  static GlobalId addHandler(Thing thing,
                             Action1<ThingMouseEventArgs> handler) {
    return _clickEvent.addHandler(thing, handler);
  }

  static bool removeHandler(Thing obj, GlobalId handlerId) {
    return _clickEvent.removeHandler(obj, handlerId);
  }

  static GlobalId addMouseMoveHandler(Thing thing,
                                      Action1<ThingMouseEventArgs> handler) {
    return _mouseMoveEvent.addHandler(thing, handler);
  }

  static bool removeMouseMoveHandler(Thing thing, GlobalId handlerId) {
    return _mouseMoveEvent.removeHandler(thing, handlerId);
  }

  static GlobalId addMouseUpHandler(Thing thing,
                                      Action1<ThingMouseEventArgs> handler) {
    return _mouseUpEvent.addHandler(thing, handler);
  }

  static bool removeMouseUpHandler(Thing thing, GlobalId handlerId) {
    return _mouseUpEvent.removeHandler(thing, handlerId);
  }

  static GlobalId addMouseDownHandler(Thing thing,
                                      Action1<ThingMouseEventArgs> handler) {
    return _mouseDownEvent.addHandler(thing, handler);
  }

  static bool removeMouseDownHandler(Thing thing, GlobalId handlerId) {
    return _mouseDownEvent.removeHandler(thing, handlerId);
  }

  static GlobalId addMouseOutHandler(Stage stage,
                                     Action1<ThingMouseEventArgs> handler) {
    return _mouseOutEvent.addHandler(stage, handler);
  }

  static bool removeMouseOutHandler(Stage stage, GlobalId handlerId) {
    return _mouseOutEvent.removeHandler(stage, handlerId);
  }

  void _mouseMove(MouseEvent e) {
    final items = _updateMouseLocation(getMouseEventCoordinate(e));

    String cursor = null;
    if(items.length > 0) {
      final args = new ThingMouseEventArgs(items[0], e);

      for(final e in items) {
        _mouseMoveEvent.fireEvent(e, args);
        if(cursor == null) {
          cursor = getCursor(e);
        }
      }
    }
    _updateCursor(cursor);
  }

  void _mouseOut(MouseEvent e) {
    _updateMouseLocation(null);
    _mouseOutEvent.fireEvent(_stage, EventArgs.empty);
    _updateCursor(null);
  }

  void _mouseUp(MouseEvent e) {
    // TODO: this does not handle the case where:
    //       1) the mouse left the thing
    //       2) mouse up
    //       3) mouse down (outside the thing)
    //       4) mouse up on the down thing
    //       Weird edge case, but important for comeletness :-/
    //       Mouse capture anyone?

    final hits = _updateMouseLocation(getMouseEventCoordinate(e));
    final thing = $(hits).firstOrDefault((e) => getClickable(e));

    if(thing != null) {
      _doMouseUp(thing, e);

      // handle click
      if(thing == _mouseDownThing) {
        _doClick(thing, e);
      }
      _mouseDownThing = null;
    }
  }

  void _mouseDown(MouseEvent e) {
    final coord = getMouseEventCoordinate(e);
    final hits = _updateMouseLocation(coord);
    _mouseDownThing = $(hits).firstOrDefault((e) => getClickable(e));
    if(_mouseDownThing != null) {
      _doMouseDown(_mouseDownThing, e);
    }
  }

  void _updateCursor(String cursor) {
    if(cursor == null) {
      cursor = _autoCursor;
    }
    final canvas = _stage._canvas;
    canvas.style.cursor = cursor;
  }

  List<Thing> _updateMouseLocation(Coordinate value) {
    return Mouse.markMouseOver(_stage, value);
  }

  void _doMouseDown(Thing thing, MouseEvent e) {
    assert(thing != null);
    final args = new ThingMouseEventArgs(thing, e);
    _mouseDownEvent.fireEvent(thing, args);
  }

  void _doMouseUp(Thing thing, MouseEvent e) {
    assert(thing != null);
    final args = new ThingMouseEventArgs(thing, e);
    _mouseUpEvent.fireEvent(thing, args);
  }

  void _doClick(Thing thing, MouseEvent e) {
    assert(thing != null);
    final args = new ThingMouseEventArgs(thing, e);
    _clickEvent.fireEvent(thing, args);
  }
}
