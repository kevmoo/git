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
      test('filter', _testFilter);
      test('forEach', _testForEach);
      test('indexOf', _testIndexOf);
      test('map', _testMap);
      test('reduce', _testReduce);
      test('simple', _testSimple);
      test('last', _testLast);
    });
  }

  static void _testLast() {
    expect(instance.last, 1);
  }

  static void _testReduce() {
    expect(instance.reduce(0, (prev, element) => prev + element), 15);
    expect(instance.reduce(1, (prev, element) => prev * element), 120);
  }

  static void _testSimple() {
    expect(instance.length, equals(_length));
    expect(instance, orderedEquals([5,4,3,2,1]));
  }

  static void _testMap() {
    Func1<int, int> dub = (i) => i * 2;

    var list = instance.map(dub);
    expect(list.length, equals(_length));
    expect(list, orderedEquals([10, 8, 6, 4, 2]));
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

  static void _testForEach() {
    int sum = 0;
    instance.forEach((e) => sum += e);
    expect(sum, equals(15));

    sum = 0;
    flipped.forEach((e) => sum += e);
    expect(sum, equals(30));
  }

  static void _testFilter() {
    var list = new List<int>.from(instance.where(_lt3));
    expect(list, orderedEquals([2, 1]));

    list = new List<int>.from(flipped.where(_lt3));
    expect(list, orderedEquals([2, 1, 1, 2]));

    list = new List<int>.from(flipped.where(_lt0));
    expect(list, orderedEquals([]));
  }

  static bool _lt0(int a) => a < 0;
  static bool _gt0(int a) => a > 0;
  static bool _lt3(int a) => a < 3;

  static ReadOnlyCollection<int> roc(List<int> source) {
    return new ReadOnlyCollection(source);
  }
}
