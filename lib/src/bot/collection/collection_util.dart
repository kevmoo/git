part of bot;

class CollectionUtil {
  static bool allUnique(Iterable items) {
    requireArgumentNotNull(items, 'items');

    for(int i = 0; i < items.length; i++) {
      for(int j = i + 1; j < items.length; j++) {
        if(items.elementAt(i) == items.elementAt(j)) {
          return false;
        }
      }
    }
    return true;
  }

  /**
   * Use [source.expand] instead.
   */
  @deprecated
  static Enumerable selectMany(Iterable source, Func1<dynamic, Iterable> func) =>
      $(source.expand(func));

  static int count(Iterable source, Func1<dynamic, bool> test) {
    return source.reduce(0, (int previous, dynamic element) {
      if(test(element)) {
        return previous + 1;
      } else {
        return previous;
      }
    });
  }

  static Iterable exclude(Iterable source, Iterable itemsToExclude) {
    requireArgumentNotNull(itemsToExclude, 'itemsToExclude');
    Func1<dynamic, bool> f = (e) => !itemsToExclude.contains(e);
    return $(IterableMixinWorkaround.where(source, f));
  }

  static Iterable distinct(Iterable source, [Func2<dynamic, dynamic, bool> comparer = null]) {
    if(comparer == null) {
      comparer = (a,b) => a == b;
    }
    return new _FuncEnumerable(source, (Iterable s) =>
        new _DistinctIterator(s.iterator, comparer));
  }

  static void forEachWithIndex(Iterable source, Action2<dynamic, int> f) {
    int i = 0;
    for(final e in source) {
      f(e, i++);
    }
  }

  /**
   * Use [toMap] instead.
   */
  @deprecated
  static Map toHashMap(Iterable source, Func1 valueFunc, [Func1 keyFunc]) =>
      toMap(source, valueFunc, keyFunc);

  static Map toMap(Iterable source, Func1 valueFunc, [Func1 keyFunc]) {
    if(keyFunc == null) {
      keyFunc = (a) => a;
    }

    final map = new Map();
    for(final e in source) {
      final k = keyFunc(e);
      if(map.containsKey(k)) {
        throw new UnsupportedError("The key '$k' is duplicated");
      }
      map[k] = valueFunc(e);
    }
    return map;
  }

  /**
   * Use `Iterable.map(...).toSet()` instead.
   */
  @deprecated
  static Set toHashSet(Iterable source, [Func1 f]) {
    if(f == null) {
      return new Set.from(source);
    } else {
      return new Set.from(source.map(f));
    }
  }
}

class _DistinctIterator<T> implements Iterator<T> {
  final Iterator<T> _source;
  final Func2<T, T, bool> _comparer;

  final List<T> _found;
  T _current;

  _DistinctIterator(this._source, this._comparer) :
    _found = new List<T>();

  T get current => _current;

  bool moveNext() {
    while(_source.moveNext()) {
      final candidate = _source.current;
      if(!_found.any((e) => _comparer(e, candidate))) {
        _current = candidate;
        _found.add(_current);
        return true;
      }
    }
    return false;
  }
}

class _SequenceIterator<E> implements Iterator<E> {
  final Sequence<E> _list;
  final int _length;
  int _position;
  E _current;

  _SequenceIterator(Sequence<E> list)
      : _list = list, _position = -1, _length = list.length;

  bool moveNext() {
    if (_list.length != _length) {
      throw new ConcurrentModificationError(_list);
    }
    int nextPosition = _position + 1;
    if (nextPosition < _length) {
      _position = nextPosition;
      _current = _list[nextPosition];
      return true;
    }
    _current = null;
    return false;
  }

  E get current => _current;
}
