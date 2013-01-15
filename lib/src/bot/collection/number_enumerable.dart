part of bot;

NumberEnumerable n$(Iterable<num> source) {
  return new NumberEnumerable.from(source);
}

abstract class NumberEnumerable<T extends num> extends Iterable<T> {

  const NumberEnumerable() : super();

  factory NumberEnumerable.from(Iterable<T> source) {
    requireArgumentNotNull(source, 'source');
    return new _SimpleNumEnumerable<T>(source);
  }

  factory NumberEnumerable.fromRange(int start, int count) {
    return new _RangeEnumerable(start, count);
  }

  num sum() {
    num theSum = 0;
    for(final n in this) {
      if(n == null) {
        throw const InvalidOperationError('Input contained a null item');
      }
      theSum += n;
    }
    return theSum;
  }

  num average() {
    int theCount = 0;
    num theSum = 0;
    for(final n in this) {
      if(n == null) {
        throw const InvalidOperationError('Input contained a null item');
      }
      theSum += n;
      theCount++;
    }
    return theSum / theCount;
  }
}

class _SimpleNumEnumerable<T extends num> extends NumberEnumerable<T> {
  final Iterable<T> _source;

  const _SimpleNumEnumerable(this._source) : super();

  Iterator<T> get iterator => _source.iterator;
}

class _FuncNumEnumerable<TSource> extends NumberEnumerable {
  final Iterable<TSource> _source;
  final Func1<Iterator<TSource>, Iterator<num>> _func;

  const _FuncNumEnumerable(this._source, this._func) : super();

  Iterator<num> get iterator => _func(_source.iterator);
}

class _RangeEnumerable extends NumberEnumerable<int> {
  final int _start;
  final int _count;

  const _RangeEnumerable(this._start, this._count);

  Iterator<int> get iterator => new _RangeIterator(_start, _count);
}

class _RangeIterator implements Iterator<int> {
  final int _start;
  final int _count;
  int _current = null;

  _RangeIterator(this._start, this._count);

  bool moveNext() {
    if(_current == null) {
      _current = _start - 1;
    }

    if(_current < _start + _count - 1) {
      _current++;
      return true;
    } else {
      return false;
    }
  }

  int get current => _current;
}
