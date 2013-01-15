part of bot;

class CollectionUtil {
  static bool allUnique(List items) {
    requireArgumentNotNull(items, 'items');

    for(int i = 0; i < items.length; i++) {
      for(int j = i + 1; j < items.length; j++) {
        if(items[i] == items[j]) {
          return false;
        }
      }
    }
    return true;
  }

  static Iterable selectMany(Iterable source, Func1<dynamic, Iterable> func) {
    return new _FuncEnumerable(source, (s) => new _SelectManyIterator(s, func));
  }

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
    return $(new WhereIterable(source, f));
  }

  static Iterable distinct(Iterable source, [Func2<dynamic, dynamic, bool> comparer = null]) {
    if(comparer == null) {
      comparer = (a,b) => a == b;
    }
    return new _FuncEnumerable(source, (s) => new _DistinctIterator(s, comparer));
  }

  static void forEachWithIndex(Iterable source, Action2<dynamic, int> f) {
    int i = 0;
    for(final e in source) {
      f(e, i++);
    }
  }

  static HashMap toHashMap(Iterable source, Func1 valueFunc, [Func1 keyFunc]) {
    if(keyFunc == null) {
      keyFunc = (a) => a;
    }

    final map = new HashMap();
    for(final e in source) {
      final k = keyFunc(e);
      if(map.containsKey(k)) {
        throw new UnsupportedError("The key '$k' is duplicated");
      }
      map[k] = valueFunc(e);
    }
    return map;
  }

  static HashSet toHashSet(Iterable source, [Func1 f]) {
    if(f == null) {
      return new HashSet.from(source);
    } else {
      return new HashSet.from(source.mappedBy(f));
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

class _SelectManyIterator<TSource, TOutput>
  implements Iterator<TOutput> {

  final Iterator<TSource> _sourceIterator;
  final Func1<TSource, Iterable<TOutput>> _func;

  Iterator<TOutput> _outputIterator;
  TOutput _current;

  _SelectManyIterator(this._sourceIterator, this._func);

  bool moveNext() {
    do {
      if(_outputIterator != null) {
        if(_outputIterator.moveNext()) {
          _current = _outputIterator.current;
          return true;
        } else {
          _outputIterator = null;
        }
      }

      assert(_outputIterator == null);

      if(_sourceIterator.moveNext()) {
        final item =  _sourceIterator.current;
        _outputIterator = _func(item).iterator;
        if(_outputIterator.moveNext()) {
          _current = _outputIterator.current;
          return true;
        } else {
          _outputIterator = null;
        }
      } else {
        return false;
      }
    } while(_outputIterator == null);
  }

  TOutput get current => _current;
}
