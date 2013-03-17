part of bot_retained;

// TODO: implement dispose. Unregister events from Canvas, etc
// TODO: Remove public ctor. Use ClickManager.enable(stage) or similiar
//       Nothing interesting exists on the instance of CM

class MouseManager {
  static final Property<String> cursorProperty =
      new Property<String>("cursor");

  static final Property<MouseManager> _clickManagerProperty =
      new Property<MouseManager>("_clickManager");

  static final Property<bool> _isClickableProperty =
      new Property<bool>("isClickable", false);

  static final Property<bool> _isDraggableProperty =
      new Property<bool>("isDraggable", false);

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

  static final AttachedEvent<ThingDragStartingEventArgs> _dragStartingEvent =
      new AttachedEvent<ThingDragStartingEventArgs>("_dragStartingEvent");

  static final AttachedEvent<ThingDragEventArgs> _dragEvent =
      new AttachedEvent<ThingDragEventArgs>('_dragStarting');

  final Stage _stage;

  Thing _mouseDownThing, _draggingThing;
  Coordinate _dragCoordinate;

  factory MouseManager(Stage stage) {
    requireArgumentNotNull(stage, 'stage');

    return _clickManagerProperty.get(stage, (s) {
      return new MouseManager._internal(s);
    });
  }

  MouseManager._internal(this._stage) {
    // The value is set in the above factory
    assert(!_clickManagerProperty.isSet(this._stage));
    _stage._canvas.onMouseMove.listen(_mouseMove);
    _stage._canvas.onMouseOut.listen(_mouseOut);
    _stage._canvas.onMouseUp.listen(_mouseUp);
    _stage._canvas.onMouseDown.listen(_mouseDown);

    window.onMouseMove.listen(_windowMouseMove);
    window.onMouseUp.listen(_windowMouseUp);
    window.onBlur.listen(_windowBlur);
  }

  static void setCursor(Thing thing, String value) {
    assert(thing != null);
    if(value == null) {
      cursorProperty.clear(thing);
    } else {
      cursorProperty.set(thing, value);
    }
  }

  static String getCursor(Thing thing) {
    assert(thing != null);
    return cursorProperty.get(thing);
  }

  static void setClickable(Thing thing, bool value) {
    _setBoolProp(thing, _isClickableProperty, value);
  }

  static bool getClickable(Thing thing) {
    assert(thing != null);
    return _isClickableProperty.get(thing);
  }

  static void setDraggable (Thing thing, bool value) {
    _setBoolProp(thing, _isDraggableProperty, value);
  }

  static bool getDraggable(Thing thing) {
    assert(thing != null);
    return _isDraggableProperty.get(thing);
  }

  static void _setBoolProp(Thing thing, Property<bool> prop, bool value) {
    assert(thing != null);
    assert(prop != null);
    assert(value != null);
    assert(prop.defaultValue == false);
    if(value) {
      prop.set(thing, true);
    } else {
      prop.clear(thing);
    }
  }

  bool get _isDragging => _dragCoordinate != null;

  void _mouseMove(MouseEvent e) {
    final items = _updateMouseLocation(getMouseEventCoordinate(e));

    String cursor = null;
    if(_draggingThing != null) {
      cursor = getCursor(_draggingThing);
    }

    if(items.length > 0) {
      final args = new ThingMouseEventArgs(items[0], e);

      for(final e in items) {
        _mouseMoveEvent.fireEvent(e, args);
        if(cursor == null) {
          cursor = getCursor(e);
        }
      }
    }
    _updateStageCursor(cursor);
  }

  void _mouseOut(MouseEvent e) {
    _updateMouseLocation(null);
    _mouseOutEvent.fireEvent(_stage, EventArgs.empty);
    _updateStageCursor(null);
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
    final thing = hits.firstWhere((e) => getClickable(e), orElse: () => null);

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
    assert(_mouseDownThing == null);
    assert(_draggingThing == null);

    final coord = getMouseEventCoordinate(e);
    final hits = _updateMouseLocation(coord);

    for(final t in hits) {
      if(getDraggable(t)) {
        _draggingThing = t;
        _startDrag(_draggingThing, e);
        break;
      } else if(getClickable(t)) {
        _mouseDownThing = t;
        _doMouseDown(_mouseDownThing, e);
        break;
      }
    }
  }

  void _updateStageCursor(String cursor) {
    cursorProperty.set(_stage, cursor);
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

  void _startDrag(Thing thing, MouseEvent e) {
    assert(!_isDragging);
    final args = new ThingDragStartingEventArgs(thing, e);
    _dragStartingEvent.fireEvent(thing, args);
    if(!args.isCanceled) {
      e.preventDefault();
      _dragCoordinate = _p2c(e.client);
    }
  }

  void _windowMouseMove(MouseEvent e) {
    if(_isDragging) {
      final newLoc = _p2c(e.client);

      final delta = newLoc - _dragCoordinate;
      final args = new ThingDragEventArgs(_draggingThing, e, delta);

      _dragEvent.fireEvent(_draggingThing, args);

      _dragCoordinate = newLoc;
    }
  }

  void _windowMouseUp(MouseEvent e) {
    _endDrag();
  }

  void _windowBlur(Event e) {
    _endDrag();
  }

  void _endDrag() {
    assert(_isDragging == (_draggingThing != null));
    if(_isDragging) {
      _dragCoordinate = null;
      _draggingThing = null;
    }
  }

  //
  // Static event logic
  //

  static Stream<ThingMouseEventArgs> getClickStream(Thing thing) {
    return _clickEvent.getStream(thing);
  }

  static Stream<ThingMouseEventArgs> getMouseMoveStream(Thing thing) {
    return _mouseMoveEvent.getStream(thing);
  }

  static Stream<ThingMouseEventArgs> getMouseUpStream(Thing thing) {
    return _mouseUpEvent.getStream(thing);
  }

  static Stream<ThingMouseEventArgs> getMouseDownStream(Thing thing) {
    return _mouseDownEvent.getStream(thing);
  }

  static Stream<ThingMouseEventArgs> getMouseOutStream(Stage stage) {
    return _mouseOutEvent.getStream(stage);
  }

  static Stream<ThingDragStartingEventArgs> addDragStartingStream(Thing thing) {
    return _dragStartingEvent.getStream(thing);
  }

  static Stream<ThingDragEventArgs> getDragStream(Thing thing) {
    return _dragEvent.getStream(thing);
  }
}

class ThingDragStartingEventArgs extends ThingMouseEventArgs implements CancelableEventArgs {
  bool _canceled = false;

  ThingDragStartingEventArgs(Thing thing, MouseEvent source) :
    super(thing, source);

  @override
  bool get isCanceled => _canceled;

  @override
  void cancel() {
    assert(!isCanceled);
    _canceled = true;
  }
}

class ThingDragEventArgs extends ThingMouseEventArgs {
  final Vector delta;
  ThingDragEventArgs(Thing thing, MouseEvent source, this.delta) :
    super(thing, source);
}
