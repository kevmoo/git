part of test_bot;

class TestUtil {
  static void run() {
    group('Util', () {
      test('getHashcode', _testGetHashCode);
      test('split lines', _testSplitLines);
    });
  }

  static void _testSplitLines() {
    expect(() => Util.splitLines(null), throwsNullArgumentError);

    final inputMap = const [const Tuple('test', const ['test']),
                            const Tuple('test\ntest', const ['test','test']),
                            const Tuple('\n', const ['','']),
                            const Tuple('  \n  ', const ['  ','  ']),
                            const Tuple('  \n \n', const ['  ',' ','']),
                            const Tuple('  \n \n', const ['  ',' ',''])
                            ];

    for(final i in inputMap) {
      expect(Util.splitLines(i.item1), equals(i.item2));
    }
  }

  static void _testGetHashCode() {
    expect(() => Util.getHashCode(null), throwsNullArgumentError);

    _hashCodeFun([], 0);
    _hashCodeFun([null], 0);
    _hashCodeFun([null, null], 0);
    _hashCodeFun([1], 307143837);
    _hashCodeFun([1,2], 93096440);
    _hashCodeFun([2,1], 405401106);
    _hashCodeFun([null, 1], 307143837);
    _hashCodeFun([null, null, 1], 307143837);
    _hashCodeFun([1, null], 15319219);
  }

  static void _hashCodeFun(List<int> items, int expectedValue) {
    int hashCode = Util.getHashCode(items.mappedBy((i) => new _SimpleHash(i)));
    expect(hashCode, equals(expectedValue));
  }
}

class _SimpleHash {
  final int hashCode;

  factory _SimpleHash(int hashCode) {
    if(hashCode == null) {
      return null;
    } else {
      return new _SimpleHash._internal(hashCode);
    }
  }

  const _SimpleHash._internal(this.hashCode);
}
