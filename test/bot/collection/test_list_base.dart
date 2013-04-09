part of test_bot;

class TestListBase extends Sequence<int> {
  static final int _length = 5;
  static final TestListBase instance = const TestListBase();
  static final TestListBase flipped = const TestListBase(true);
  static final Sequence<int> empty = const ReadOnlyCollection.empty();

  final bool flip;

  const TestListBase([this.flip = false]);

  /**
   * Returns the number of elements in this collection.
   */
  int get length => flip ? _length * 2 : _length;

  /**
   * Returns the element at the given [index] in the list or throws
   * an [IndexOutOfRangeException] if [index] is out of bounds.
   */
  int operator [](int index) {
    assert(index >= 0 && index < length);

    if (index < _length) {
      return _length - index;
    }
    index -= _length;
    return index + 1;
  }

  static void run() {
    group('ListBase', (){
      test('indexOf', _testIndexOf);
      test('simple', _testSimple);
      test('last', _testLast);
    });
  }

  static void _testLast() {
    expect(instance.last, 1);
  }

  static void _testSimple() {
    expect(instance.length, equals(_length));
    expect(instance, orderedEquals([5,4,3,2,1]));
  }

  static void _testIndexOf() {
    //
    // All positive, start at 0
    //
    for (var i = 1; i <= _length; i++) {
      expect(flipped.indexOf(i), equals(_length - i));
      expect(flipped.lastIndexOf(i), equals(_length + i - 1));
    }

    //
    // Look at the 2nd half for indexOf
    //
    for (var i = 1; i <= _length; i++) {
      expect(flipped.indexOf(i, _length), equals(_length + i - 1));
    }

    //
    // Look at the 1st half for lastIndexOf
    //
    for (var i = 1; i <= _length; i++) {
      final expected = _length - i;
      expect(flipped.lastIndexOf(i, _length - 1), expected);
    }

    //
    // look for '1' after the last '1'
    //
    expect(flipped.indexOf(1, _length + 1), equals(-1));

    // look for the last '1' before the first '1'
    expect(flipped.lastIndexOf(1, _length - 2), equals(-1));

    //
    // look for '0' which isn't there
    //
    expect(flipped.indexOf(0), equals(-1));
    expect(flipped.lastIndexOf(0), equals(-1));
  }
}
