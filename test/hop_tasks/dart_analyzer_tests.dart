// TODO(adam): test `--enable_type_checks`
// TODO(kevmoo): figure out a way to validate output...

part of test_hop_tasks;

class DartAnalyzerTests {

  static void register() {
    group('dart_analyzer', () {
      test('1 pass, 1 warn', () {
        final fileTexts = {"main1.dart": "void main() => print('hello bot');",
                           "main2.dart": "void main() { String i = 42; }"};

        return _testAnalyzerTask(fileTexts, RunResult.SUCCESS);
      });

      test('failed file', () {
        final fileTexts = {"main.dart": "void main() => asdf { XXXX i = 42; }"};

        return _testAnalyzerTask(fileTexts, RunResult.FAIL);
      });

      test('1 pass, 1 warn, 1 error', () {
        final fileTexts = {"main1.dart": "void main() asdf { String i = 42; }",
                           "main2.dart": "void main() asdf { String i = 42; }",
                           "main3.dart": "void main() asdf { String i = 42; }" };

        return _testAnalyzerTask(fileTexts, RunResult.FAIL);

      });
    });
  }
}

Future _testAnalyzerTask(Map<String, String> inputs,
                       RunResult expectedResult) {
  TempDir tempDir;

  return TempDir.create()
      .then((TempDir value) {
        tempDir = value;
        final populater = new MapDirectoryPopulater(inputs);
        return tempDir.populate(populater);
      })
      .then((TempDir value) {
        assert(value == tempDir);

        var fullPaths = inputs.keys.map((e) =>
            new Path(tempDir.path).join(new Path(e)).toNativePath()).toList();

        final task = createDartAnalyzerTask(fullPaths);
        return runTaskInTestRunner(task);
      })
      .then((RunResult runResult) {
        expect(runResult, expectedResult);
      })
      .whenComplete(() {
        if(tempDir != null) {
          tempDir.dispose();
        }
      });
}
