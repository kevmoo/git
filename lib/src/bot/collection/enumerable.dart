part of bot;

Enumerable $(Iterable source) {
  if(source is Enumerable) {
    return source;
  } else {
    return new Enumerable.fromIterable(source);
  }
}

abstract class Enumerable<T> extends Iterable<T> {
  const Enumerable();

  factory Enumerable.fromIterable(Iterable<T> source) {
    requireArgumentNotNull(source, 'source');
    return new _SimpleEnumerable<T>(source);
  }

  /**
   * Returns true if one element of this collection satisfies the
   * predicate [f]. Returns false otherwise.
   */
  bool some(Func1<T, bool> f) {
    requireArgumentNotNull(f, 'f');
    for (final e in this) {
      if(f(e)) {
        return true;
      }
    }
    return false;
  }

  int count(Func1<T, bool> f) =>
      CollectionUtil.count(this, f);

  @deprecated
  Enumerable mappedBy(Func1<T, Object> f) =>
      this.map(f);

  Enumerable map(Func1<T, Object> f) =>
      $(super.map(f));

  Enumerable<T> where(Func1<T, bool> f) =>
      $(super.where(f));

  Enumerable<T> exclude(Iterable<T> items) =>
      CollectionUtil.exclude(this, items);

  /**
   * Use [expand] instead
   */
  @deprecated
  Enumerable selectMany(Func1<T, Iterable> f) =>
      this.expand(f);

  Enumerable expand(Func1<T, Iterable> f) =>
      $(super.expand(f));

  Enumerable<T> distinct([Func2<T, T, bool> comparer = null]) =>
      CollectionUtil.distinct(this, comparer);

  Grouping<dynamic, T> group([Func1<T, Object> keyFunc = null]) {
    return new Grouping(this, keyFunc);
  }

  ReadOnlyCollection<T> toReadOnlyCollection() => new ReadOnlyCollection<T>(this);

  void forEachWithIndex(Action2<T, int> f) {
    int i = 0;
    for(final e in this) {
      f(e, i++);
    }
  }

  /**
   * Use the [map] method then [toSet] instead.
   */
  @deprecated
  Set toHashSet([Func1<T, dynamic> f]) {
    if(f == null) {
      return this.toSet();
    } else {
      return this.map(f).toSet();
    }
  }

  /**
   * Use [toMap] instead.
   */
  @deprecated
  Map toHashMap(Func1<T, Object> valueFunc, [Func1<T, dynamic> keyFunc]) =>
      this.toMap(valueFunc, keyFunc);

  Map toMap(Func1<T, Object> valueFunc, [Func1<T, dynamic> keyFunc]) =>
      CollectionUtil.toMap(this, valueFunc, keyFunc);

  NumberEnumerable selectNumbers(Func1<T, num> f) =>
      new NumberEnumerable.from(this.map(f));

  String toString() => "[${join(', ')}]";
}

class _SimpleEnumerable<T> extends Enumerable<T> {
  final Iterable<T> _source;

  const _SimpleEnumerable(this._source) : super();

  Iterator<T> get iterator => _source.iterator;
}

class _FuncEnumerable<TSource, TOutput> extends Enumerable<TOutput> {
  final TSource _source;
  final Func1<TSource, Iterator<TOutput>> _func;

  const _FuncEnumerable(this._source, this._func) : super();

  Iterator<TOutput> get iterator => _func(_source);
}
