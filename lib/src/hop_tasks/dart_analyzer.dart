// TODO(adam): document methods and class
// TODO(adam): use verbose

part of hop_tasks;

class _AnalyzerResult {
  final ProcessResult processResult;
  final Path path;

  _AnalyzerResult(this.path, this.processResult);

  String toString() {
    return "${_getPrefix(processResult.exitCode)}: $path";
  }

  String toVerboseString() {
    return '''${toString()}
${processResult.stdout}
${processResult.stderr}''';
  }

  static String _getPrefix(int exitCode) {
    switch(exitCode) {
      case 0:
        return "PASSED";
      case 1:
        return "WARNING";
      case 2:
        return "ERROR";
      default:
        return "Unknown exit code $exitCode";
    }
  }
}

Task createDartAnalyzerTask(Iterable<String> files) {
  return new Task.async((context) {

    final parser = _getDartAnalyzerParser();
    final parseResult = _helpfulParseArgs(context, parser, context.arguments);

    final bool enableTypeChecks = parseResult['enable_type_checks'];
    final bool verbose = parseResult['verbose'];

    final fileList = files.mappedBy((f) => new Path(f)).toList();

    return _processAnalyzerFile(context, fileList, enableTypeChecks, verbose);
  }, 'Running dart analyzer');
}

ArgParser _getDartAnalyzerParser() {
  return new ArgParser()
    ..addFlag('enable_type_checks', help: 'Generate runtime type checks', defaultsTo: false)
    ..addFlag('verbose', help: 'verbose output of all errors', defaultsTo: false);
}

Future<bool> _processAnalyzerFile(TaskContext context, List<Path> analyzerFilePaths,
    bool enableTypeChecks, bool verbose) {
  final results = new List<_AnalyzerResult>();

  return Future.forEach(analyzerFilePaths, (Path path) {
    return _analyzer(context, path, enableTypeChecks)
        .then((_AnalyzerResult ar) {
          if(verbose) {
            context.info(ar.toVerboseString());
          } else {
            context.info(ar.toString());
          }
          results.add(ar);
        });
    }).
    then((_) => _processResults(context, results, verbose));
}

Future<_AnalyzerResult> _analyzer(TaskContext context, Path filePath, bool enableTypeChecks) {
  TempDir tmpDir;

  return TempDir.create()
      .then((TempDir td) {
        tmpDir = td;

        var processArgs = ['--extended-exit-code', '--work', tmpDir.dir.path];

        if (enableTypeChecks) {
          processArgs.add('--enable_type_checks');
        }

        processArgs.addAll([filePath.toNativePath()]);

        return Process.run('dart_analyzer', processArgs);
      })
      .then((ProcessResult processResult) {
        if (processResult.exitCode == 127) {
          // Check for exit code, something went wrong here.
          var sb = new StringBuffer();
          sb.add(processResult.stderr);
          sb.add(processResult.stdout);
          sb.add("Exit Code 127");
          throw sb.toString();
        } else {
          var analyzerResult = new _AnalyzerResult(filePath, processResult);
          return analyzerResult;
        }
      })
      .whenComplete(() {
        if(tmpDir != null) {
          tmpDir.dispose();
        }
      });
}

bool _processResults(TaskContext context, List<_AnalyzerResult> analyzerResults, bool verbose) {
  final finalResults = new StringBuffer();
  int errorsCount = 0;
  int passedCount = 0;
  int warningCount = 0;

  analyzerResults.forEach((_AnalyzerResult result) {
    /*
     *  --extended-exit-code : 0 - clean; 1 - has warnings; 2 - has errors
     */

    switch(result.processResult.exitCode) {
      case 0:
        passedCount++;
        break;
      case 1:
        warningCount++;
        break;
      case 2:
      default:
        errorsCount++;
        break;
    }
  });

  context.info("PASSED: ${passedCount}, WARNING: ${warningCount}, ERROR: ${errorsCount}");

  return errorsCount == 0;
}
