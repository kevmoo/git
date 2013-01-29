part of test_bot;

class TestHslColor {
  static void run() {
    group('HslColor', (){
      test('Equals', _testEquals);
      test('Invalid', _testInvalid);

      test('hue normaliazing', () {
        const values = const [ 0, 0,
                               360, 0,
                               -1, 359,
                               -361, 359,
                               721, 1];

        for(int i = 0; i < values.length; i+=2) {
          final color = new HslColor(values[i], 0, 0);
          expect(color.h, values[i+1]);
        }

      });

    });
  }

  static void _testEquals() {
    var a = new HslColor(123, 1, 0.5);

    expect(a, equals(a));
    expect(a, same(a));

    // 'h' wraps around, so adding or subtracting 360 yields the same value
    var b = new HslColor(123 + 360, 1, 0.5);
    expect(b, equals(a));
    expect(b, isNot(same(a)));

    var c = new HslColor(1,1,0);
    expect(c, isNot(equals(a)));
    expect(c, isNot(same(a)));
  }

  static void _testInvalid() {
    expect(() => new HslColor(0, 0, 0), returnsNormally);

    for(final invalidNumber in const[null, double.INFINITY, double.NEGATIVE_INFINITY, double.NAN]) {
      expect(() => new HslColor(invalidNumber, 0, 0), throwsArgumentError);
      expect(() => new HslColor(0, invalidNumber, 0), throwsArgumentError);
      expect(() => new HslColor(0, 0, invalidNumber), throwsArgumentError);
      expect(() => new HslColor(invalidNumber, invalidNumber, invalidNumber), throwsArgumentError);
    }

    expect(() => new HslColor(0, -1, 0), throwsArgumentError);
    expect(() => new HslColor(0, 0, 256), throwsArgumentError);
  }
}
