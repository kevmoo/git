part of test_hop_tasks;

class DartAnalyzerTests {

  static void register() {

    group('dart_analyzer', () {
      test('passing file', () {
        expect(isTrue, isFalse);
      });
      test('warning file', () {
        expect(isTrue, isFalse);
      });
      test('failed file', () {
        expect(isTrue, isFalse);
      });

      test('multiple passing files', () {
        expect(isTrue, isFalse);
      });

      test('multiple warning files', () {
        expect(isTrue, isFalse);
      });

      test('multiple failed files', () {
        expect(isTrue, isFalse);
      });

      test('mixed multiple passing, warning, failed files', () {
        expect(isTrue, isFalse);
      });
    });
  }
}