// TODO(adam): handle future errors
// TODO(adam): document methods and class
// TODO(adam): use verbose

part of hop_tasks;

class AnalyzerResult {
  ProcessResult processResult;
  String fileName;
  Path path;
  AsyncError error;
  AnalyzerResult(this.fileName, this.path, {this.processResult, this.error});
}

Task createDartAnalyzerTask(List<String> files) {
  return new Task.async((context) {
    context.fine("Running dart analyzer task");
    final List<AnalyzerResult> analyzerResults = new List<AnalyzerResult>();
    final Queue<Path> analyzerFilePaths = new Queue<Path>();
    files.forEach((f) => analyzerFilePaths.add(new Path(f)));
    return _processAnalyzerFile(analyzerFilePaths, analyzerResults, context);
  }, 'Running dart analyzer');
}

ArgParser _getDartAnalyzerParser() {
  final parser = new ArgParser();
  parser.addFlag('enable_type_checks', help: 'Generate runtime type checks', defaultsTo: false);
  parser.addFlag('verbose', help: 'verbose output of all errors', defaultsTo: false);
  return parser;
}

Future<bool> _processAnalyzerFile(Queue<Path> analyzerFilePaths, List<AnalyzerResult> analyzerResults, TaskContext context) {
  var completer = new Completer();

  void _local(Queue<Path> analyzerFilePaths, List<AnalyzerResult> analyzerResults, TaskContext context) {
    if (analyzerFilePaths.isEmpty) {
      var result = _processResults(analyzerResults, context);
      completer.complete(result);
    } else {
      var path = analyzerFilePaths.removeFirst();
      _analyzer(path, context)
      ..then((result) {
        analyzerResults.add(result);
        _local(analyzerFilePaths, analyzerResults, context);
      });
    }
  };

  _local(analyzerFilePaths, analyzerResults, context);
  return completer.future;
}

Future<AnalyzerResult> _analyzer(Path filePath, TaskContext context) {
  var completer = new Completer();

  final workLocation = TempDir.create();

  workLocation
  ..catchError((AsyncError error) {
    throw "FAILED ON workLocation";
    // TODO(adam): fill out exception handling
  })
  ..then((TempDir tmpDir) {
    final parser = _getDartAnalyzerParser();
    final parseResult = _helpfulParseArgs(context, parser, context.arguments);
    var processArgs = [];
    if (parseResult['enable_type_checks']) {
      processArgs.add('--enable_type_checks');
    }

    processArgs.addAll(['--extended-exit-code', '--work', tmpDir.dir.path, filePath.toNativePath()]);
    Process.run('dart_analyzer', processArgs)
    ..catchError((AsyncError error) {
      // TODO(adam): fill out exception handling
      throw "FAILED ON Process.run('dart_analyzer', processArgs)";
    })
    ..then((ProcessResult processResult) {
      if (processResult.exitCode == 127) {
        // Check for exit code, something went wrong here.
        var sb = new StringBuffer();
        sb.add(processResult.stderr);
        sb.add(processResult.stdout);
        sb.add("Exit Code 127");
        completer.completeError(sb.toString());
      } else {
        var analyzerResult = new AnalyzerResult(filePath.filename, filePath, processResult: processResult);
        tmpDir.dispose();
        completer.complete(analyzerResult);
      }
    });
  });

  return completer.future;
}

bool _processResults(List<AnalyzerResult> analyzerResults, TaskContext context) {
  final parser = _getDartAnalyzerParser();
  final parseResult = _helpfulParseArgs(context, parser, context.arguments);
  bool verbose = parseResult['verbose'];

  StringBuffer finalResults = new StringBuffer();
  StringBuffer verboseOutput = new StringBuffer();
  StringBuffer exitCodeLabels = new StringBuffer();
  int errorsCount = 0;
  int passedCount = 0;
  int warningCount = 0;
  analyzerResults.forEach((AnalyzerResult result) {
    /*
     *  --extended-exit-code : 0 - clean; 1 - has warnings; 2 - has errors
     */
    exitCodeLabels.clear();

    if (result.processResult.exitCode == 0) {
      passedCount++;
      exitCodeLabels.add("PASSED: ");
    } else if (result.processResult.exitCode == 1) {
      warningCount++;
      exitCodeLabels.add("WARNING: ");
    } else if (result.processResult.exitCode == 2) {
      errorsCount++;
      exitCodeLabels.add("ERROR: ");
    }

    finalResults.add(exitCodeLabels.toString());
    finalResults.add("${result.path.directoryPath.toString()}/${result.fileName}\n");

    if (verbose) {
      verboseOutput.add(exitCodeLabels.toString());
      verboseOutput.add("${result.path.directoryPath.toString()}/${result.fileName}\n");
      verboseOutput.add("${result.processResult.stdout}\n");
      verboseOutput.add("${result.processResult.stderr}\n\n");
      context.info(verboseOutput.toString());
      verboseOutput.clear();
    }
  });

  finalResults.add("PASSED: ${passedCount}, WARNING: ${warningCount}, ERROR: ${errorsCount}\n");
  context.info(finalResults.toString());

  if (errorsCount > 0) {
    context.info("$errorsCount Errors");
    return false;
  } else {
    context.info("Passed");
    return true;
  }
}