// TODO(adam): test `--enable_type_checks`

part of test_hop_tasks;

class DartAnalyzerTests {

  static void register() {
    group('dart_analyzer', () {
      test('passing file', () {
        final fileTexts = {"main.dart": "void main() => print('hello bot');"};
        TempDir tempDir;

        final future = TempDir.create()
        .then((TempDir value) {
          tempDir = value;
          final populater = new MapDirectoryPopulater(fileTexts);
          return tempDir.populate(populater);
        })
        .then((TempDir value) {
          assert(value == tempDir);

          final task = createDartAnalyzerTask(fileTexts.keys.toList());
          return _runTask(task);
        });
//        .then((RunResult runResult) {
//          expect(runResult, RunResult.SUCCESS);
//        });

        expectFutureComplete(future, (_) {
          print("_ = $_");
          if(tempDir != null) {
            tempDir.dispose();
          }
        });
      });

//      test('warning file', () {
//      });
//
//      test('failed file', () {
//        expect(isTrue, isFalse);
//      });
//
//      test('multiple passing files', () {
//        expect(isTrue, isFalse);
//      });
//
//      test('multiple warning files', () {
//        expect(isTrue, isFalse);
//      });
//
//      test('multiple failed files', () {
//        expect(isTrue, isFalse);
//      });
//
//      test('mixed multiple passing, warning, failed files', () {
//        expect(isTrue, isFalse);
//      });
    });
  }
}