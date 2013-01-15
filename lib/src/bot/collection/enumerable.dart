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
   * Returns true if every elements of this collection satisify the
   * predicate [f]. Returns false otherwise.
   */
  bool every(Func1<T, bool> f) {
    requireArgumentNotNull(f, 'f');
    for (final e in this) {
      if(!f(e)) {
        return false;
      }
    }
    return true;
  }

  bool contains(T item) {
    for (final e in this) {
      if(e == item) {
        return true;
      }
    }
    return false;
  }

  bool get isEmpty => !some((e) => true);

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

  String join([String separator = ', ']) {
    final StringBuffer sb = new StringBuffer();
    for(final e in this) {
      if(sb.length > 0) {
        sb.add(separator);
      }
      sb.add(e);
    }
    return sb.toString();
  }

  /**
   * Returns a new collection with the elements [: f(e) :]
   * for each element [:e:] of this collection.
   *
   * Note on typing: the return type of f() could be an arbitrary
   * type and consequently the returned collection's
   * typeis Collection.
   */
  Enumerable mappedBy(Func1<T, Object> f) =>
      $(super.mappedBy(f));

  Enumerable<T> where(Func1<T, bool> f) =>
      $(super.where(f));

  Enumerable<T> exclude(Iterable<T> items) =>
      CollectionUtil.exclude(this, items);

  Enumerable selectMany(Func1<T, Iterable> f) =>
      CollectionUtil.selectMany(this, f);

  Enumerable<T> distinct([Func2<T, T, bool> comparer = null]) =>
      CollectionUtil.distinct(this, comparer);

  Grouping<dynamic, T> group([Func1<T, Object> keyFunc = null]) {
    return new Grouping(this, keyFunc);
  }

  ReadOnlyCollection<T> toReadOnlyCollection() => new ReadOnlyCollection<T>(this);

  void forEach(Action1<T> f) {
    for(final e in this) {
      f(e);
    }
  }

  void forEachWithIndex(Action2<T, int> f) {
    int i = 0;
    for(final e in this) {
      f(e, i++);
    }
  }

  List<T> toList() => new List<T>.from(this);

  HashSet toHashSet([Func1<T, dynamic> f]) =>
      CollectionUtil.toHashSet(this, f);

  HashMap toHashMap(Func1<T, Object> valueFunc, [Func1<T, dynamic> keyFunc]) =>
      CollectionUtil.toHashMap(this, valueFunc, keyFunc);

  NumberEnumerable selectNumbers(Func1<T, num> f) =>
      new NumberEnumerable.from(this.mappedBy(f));

  String toString() => "[${this.join()}]";
}

class _SimpleEnumerable<T> extends Enumerable<T> {
  final Iterable<T> _source;

  const _SimpleEnumerable(this._source) : super();

  Iterator<T> get iterator => _source.iterator;
}

class _FuncEnumerable<TSource, TOutput> extends Enumerable<TOutput> {
  final Iterable<TSource> _source;
  final Func1<Iterator<TSource>, Iterator<TOutput>> _func;

  const _FuncEnumerable(this._source, this._func) : super();

  Iterator<TOutput> get iterator => _func(_source.iterator);
}
