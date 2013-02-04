// TODO(adam): document methods and class
// TODO(adam): use verbose

part of hop_tasks;

class AnalyzerResult {
  final ProcessResult processResult;
  final Path path;

  AnalyzerResult(this.path, this.processResult);
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
  final results = new List<AnalyzerResult>();

  return Future.forEach(analyzerFilePaths, (Path path) {
    return _analyzer(context, path, enableTypeChecks)
        .then((AnalyzerResult ar) {
          results.add(ar);
        });
    }).
    then((_) => _processResults(context, results, verbose));
}

Future<AnalyzerResult> _analyzer(TaskContext context, Path filePath, bool enableTypeChecks) {
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
          var analyzerResult = new AnalyzerResult(filePath, processResult);
          return analyzerResult;
        }
      })
      .whenComplete(() {
        if(tmpDir != null) {
          tmpDir.dispose();
        }
      });
}

bool _processResults(TaskContext context, List<AnalyzerResult> analyzerResults, bool verbose) {
  final finalResults = new StringBuffer();
  int errorsCount = 0;
  int passedCount = 0;
  int warningCount = 0;

  analyzerResults.forEach((AnalyzerResult result) {
    final verboseOutput = new StringBuffer();
    final exitCodeLabels = new StringBuffer();

    /*
     *  --extended-exit-code : 0 - clean; 1 - has warnings; 2 - has errors
     */

    switch(result.processResult.exitCode) {
      case 0:
        passedCount++;
        exitCodeLabels.add("PASSED: ");
        break;
      case 1:
        warningCount++;
        exitCodeLabels.add("WARNING: ");
        break;
      case 2:
        errorsCount++;
        exitCodeLabels.add("ERROR: ");
        break;
      default:
        errorsCount++;
        exitCodeLabels.add("Unknown exit code ${result.processResult.exitCode}: ");
        break;
    }

    finalResults.add(exitCodeLabels);
    finalResults.add("${result.path.directoryPath}/${result.path}\n");

    if (verbose) {
      verboseOutput.add(exitCodeLabels);
      verboseOutput.add("${result.path.directoryPath}/${result.path}\n");
      verboseOutput.add("${result.processResult.stdout}\n");
      verboseOutput.add("${result.processResult.stderr}\n\n");
      context.info(verboseOutput.toString());
    }
  });

  finalResults.add("PASSED: ${passedCount}, WARNING: ${warningCount}, ERROR: ${errorsCount}");
  context.info(finalResults.toString());

  if (errorsCount > 0) {
    context.info("$errorsCount Errors");
    return false;
  } else {
    context.info("Passed");
    return true;
  }
}
