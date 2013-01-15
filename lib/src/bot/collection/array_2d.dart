part of bot;

// TODO
// ponder implementing other mutation methods
// implement equals
// toString

class Array2d<T> extends ListBase<T> {
  final int width;
  final int height;
  final List<T> _source;

  factory Array2d.readonlyFrom(int width, Iterable<T> source) {
    requireArgumentNotNull(width, 'width');
    requireArgumentNotNull(source, 'source');
    final list = new List<T>.from(source);
    final s = source == null ? null : new ReadOnlyCollection<T>.wrap(list);
    return new Array2d.wrap(width, s);
  }

  factory Array2d(int width, int height, [T initialValue]) {
    requireArgumentNotNull(width, 'width');
    requireArgumentNotNull(height, 'height');
    requireArgument(width >= 0, 'width');
    requireArgument(height >= 0, 'height');
    final s = new List<T>();
    s.insertRange(0, width * height, initialValue);
    assert(s.length == width * height);
    if(width == 0) {
      return new Array2d._skinny(height);
    }
    return new Array2d.wrap(width, s);
  }

  Array2d._skinny(this.height) : width = 0, _source = [] {
    assert(isValidNumber(height));
    assert(height >= 0);
  }

  Array2d.wrap(int width, List<T> source):
    this.width = width,
    this._source = source,
    this.height = (width != null && width > 0 && source != null) ?
        source.length ~/ width : 0 {
    requireArgumentNotNull(width, 'width');
    requireArgumentNotNull(source, 'source');
    requireArgument(width >= 0, 'width', 'width must be non-zero');

    if(width * height == 0) {
      requireArgument(_source.length == 0, 'width',
        'width must be greater than zero if the source is non-empty');
    } else {
      requireArgument(_source.length > 0, 'source',
          'if width is non-zero, source must be non-empty');
      requireArgument(_source.length % width == 0, 'width',
          'width must evenly divide the source');
    }
  }

  int get length => _source.length;

  T operator [](int index) => _source[index];

  void operator []=(int index, T value) {
    _source[index] = value;
  }

  // TODO: test
  //  - especially equality across instances, rows, etc
  List<List<T>> get rows =>
      new _Array2dRows(this);

  T get(int x, int y) {
    final i = _getIndex(x, y);
    return this[i];
  }

  void set(int x, int y, T value) {
    final i = _getIndex(x, y);
    this[i] = value;
  }

  List<T> getAdjacent(int x, int y) {
    final m = getAdjacentIndices(x, y).mappedBy((i) => this[i]);
    return new List<T>.from(m);
  }

  List<int> getAdjacentIndices(int x, int y) {
    final List<int> adj = new List<int>();

    for(int k = math.max(0, y - 1); k < math.min(height, (y + 2)); k++) {
      for(int j = math.max(0, x - 1); j < math.min(width, (x + 2)); j++) {
        if(j != x || k != y) {
          adj.add(_getIndex(j, k));
        }
      }
    }
    return adj;
  }

  Tuple<int, int> getCoordinate(int index) {
    final x = index % width;
    final y = index ~/ width;
    assert(_getIndex(x, y) == index);
    return new Tuple<int, int>(x, y);
  }

  int _getIndex(int x, int y) {
    assert(x >= 0 && x < width);
    assert(y >= 0 && y < height);
    return x + y * width;
  }
}

class _Array2dRows<T> extends ListBase<List<T>> {
  final Array2d<T> source;

  _Array2dRows(this.source);

  int get length => source.height;

  List<T> operator [](int index) => new _Array2dRow<T>(this.source, index);

  bool operator ==(other) {
    return other is _Array2dRows && other.source == this.source;
  }
}

class _Array2dRow<T> extends ListBase<T> {
  final Array2d<T> source;
  final int row;

  _Array2dRow(this.source, this.row);

  int get length => source.width;

  T operator [](int index) => source.get(index, row);

  bool operator ==(other) {
    return other is _Array2dRow && other.source == this.source &&
        other.row == this.row;
  }
}
