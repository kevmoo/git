part of bot_retained;

class SpriteThing extends ImageThing {
  final Coordinate startCoordinate;
  final Vector nextDelta;
  final int count;

  int _frame = 0;

  factory SpriteThing.horizontalFromUrl(String src, num w, num h,
      int count, num xDelta, [Coordinate start = const Coordinate()]) {
    final img = new ImageElement(src: src);

    return new SpriteThing(img, w, h, start, new Vector(xDelta, 0), count);
  }

  SpriteThing(ImageElement image, num width, num height,
                this.startCoordinate, this.nextDelta, this.count) :
    super(width, height, image);

  void nextFrame() {
    setFrame(_frame + 1);
  }

  void previousFrame() {
    setFrame(_frame - 1);
  }

  void setFrame(int frame) {
    _frame = (frame % count);
    invalidateDraw();
  }

  void _doDraw(CanvasRenderingContext2D ctx) {
    final int msPerFrame = 1000 ~/ count;

    // DARTBUG: http://code.google.com/p/dart/issues/detail?id=7322
    // performance.now is not correctly polyfilled for Chrome 23
    // final new currentMS = window.performance.now().toInt();

    final int currentMS = new DateTime.now().millisecondsSinceEpoch;

    final int theFrame = (currentMS ~/ msPerFrame) % count;

    final sourceCoord = startCoordinate + nextDelta * theFrame;

    final rect = new Box.fromCoordSize(sourceCoord, size);

    CanvasUtil.drawImage(ctx, _image, rect);
  }
}
