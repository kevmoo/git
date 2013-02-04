// TODO(adam): test `--enable_type_checks`

part of test_hop_tasks;

class DartAnalyzerTests {

  static void register() {
    group('dart_analyzer', () {
      test('passing file', () {
        final fileTexts = {"main.dart": "void main() => print('hello bot');"};

        _testAnalyzerTask(fileTexts, RunResult.SUCCESS);
      });

      test('warning file', () {
        final fileTexts = {"main.dart": "void main() { String i = 42; }"};

        _testAnalyzerTask(fileTexts, RunResult.SUCCESS);
      });

      test('failed file', () {
        final fileTexts = {"main.dart": "void main() => asdf { XXXX i = 42; }"};

        _testAnalyzerTask(fileTexts, RunResult.FAIL);
      });

      test('multiple passing files', () {
        final fileTexts = {"main1.dart": "void main() => print('hello bot');",
                           "main2.dart": "void main() => print('hello bot');",
                           "main3.dart": "void main() => print('hello bot');" };

        _testAnalyzerTask(fileTexts, RunResult.SUCCESS);
      });

      test('multiple warning files', () {
        final fileTexts = {"main1.dart": "void main() { String i = 42; }",
                           "main2.dart": "void main() { String i = 42; }",
                           "main3.dart": "void main() { String i = 42; }" };

        _testAnalyzerTask(fileTexts, RunResult.SUCCESS);
      });

      test('multiple failed files', () {
        final fileTexts = {"main1.dart": "void main() asdf { String i = 42; }",
                           "main2.dart": "void main() asdf { String i = 42; }",
                           "main3.dart": "void main() asdf { String i = 42; }" };

        _testAnalyzerTask(fileTexts, RunResult.FAIL);

      });

//      test('mixed multiple passing, warning, failed files', () {
//        expect(isTrue, isFalse);
//      });

    });
  }
}

void _testAnalyzerTask(Map<String, String> inputs, RunResult expectedResult) {
  TempDir tempDir;

  final future = TempDir.create()
      .then((TempDir value) {
        tempDir = value;
        final populater = new MapDirectoryPopulater(inputs);
        return tempDir.populate(populater);
      })
      .then((TempDir value) {
        assert(value == tempDir);

        var fullPaths = inputs.keys.mappedBy((e) =>
            new Path(tempDir.path).join(new Path(e)).toNativePath()).toList();

        final task = createDartAnalyzerTask(fullPaths);
        return _runTask(task);
      })
      .then((RunResult runResult) {
        expect(runResult, expectedResult);
      })
      .whenComplete(() {
        if(tempDir != null) {
          tempDir.dispose();
        }
      });

  expect(future, completes);
}
