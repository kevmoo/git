part of bot;

abstract class Sequence<E> extends Enumerable<E> {
  const Sequence();

  E operator [](int index);

  int indexOf(E value, [int start = 0]) {
    for (int i = start; i < length; i++) {
      if (this[i] == value) return i;
    }
    return -1;
  }

  int lastIndexOf(E value, [int start]) {
    if (start == null) start = length - 1;
    for (int i = start; i >= 0; i--) {
      if (this[i] == value) return i;
    }
    return -1;
  }

  @override
  E elementAt(int index) => this[index];

  @override
  Iterator<E> get iterator => new _SequenceIterator(this);

  /**
   * Returns an object wraps [this] and implements [List].
   *
   * All mutation operations on the returned object throw [UnsupportedError].
   *
   * Does __not__ return a copy of the current values. Changes to [this] will
   * be reflected in the returned object.
   */
  List<E> asList() => new _SequenceList(this);
}

class _SequenceList<E> extends Sequence<E> implements List<E> {
  final Sequence _source;

  _SequenceList(this._source);

  @override
  E operator [](int index) => _source[index];

  @override
  int get length => _source.length;

  @override
  @deprecated
  List<E> getRange(int start, int length) => sublist(start, start + length);

  @override
  List<E> sublist(int start, [int end]) {
    if (end == null) end = length;
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (end < start || end > this.length) {
      throw new RangeError.range(end, start, this.length);
    }
    int length = end - start;
    List<E> result = new List<E>()..length = length;
    for (int i = 0; i < length; i++) {
      result[i] = this[start + i];
    }
    return result;
  }

  @override
  Map<int, E> asMap() => IterableMixinWorkaround.asMapList(this);

  @override
  List<E> get reversed => IterableMixinWorkaround.reversedList(this);

  @override
  void insert(int, E item) {
    throw new UnsupportedError(
    "Cannot modify an unmodifiable list");
  }

  @override
  void operator []=(int index, E value) {
    throw new UnsupportedError(
        "Cannot modify an unmodifiable list");
  }

  @override
  void set length(int newLength) {
    throw new UnsupportedError(
        "Cannot change the length of an unmodifiable list");
  }

  @override
  void add(E value) {
    throw new UnsupportedError(
        "Cannot add to an unmodifiable list");
  }

  @override
  void addLast(E value) {
    throw new UnsupportedError(
        "Cannot add to an unmodifiable list");
  }

  @override
  void addAll(Iterable<E> iterable) {
    throw new UnsupportedError(
        "Cannot add to an unmodifiable list");
  }

  @override
  void remove(E element) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  @override
  void removeAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  @override
  void retainAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  @override
  void retainWhere(Func1<E, bool> test) {
    throw new UnsupportedError(
    "Cannot modify an unmodifiable list");
  }

  @override
  void removeWhere(bool test(E element)) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  @override
  void sort([Comparator<E> compare]) {
    throw new UnsupportedError(
        "Cannot modify an unmodifiable list");
  }

  @override
  void clear() {
    throw new UnsupportedError(
        "Cannot clear an unmodifiable list");
  }

  @override
  E removeAt(int index) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  @override
  E removeLast() {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  @override
  void setRange(int start, int length, List<E> from, [int startFrom]) {
    throw new UnsupportedError(
        "Cannot modify an unmodifiable list");
  }

  @override
  void removeRange(int start, int length) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  @override
  void insertRange(int start, int length, [E initialValue]) {
    throw new UnsupportedError(
        "Cannot insert range in an unmodifiable list");
  }
}

